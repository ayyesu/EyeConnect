import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'dart:math' as math;

class VideoCallService {
  RTCPeerConnection? _peerConnection;
  bool _isInitialized = false;
  MediaStream? _localStream;
  String? _currentRoomId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _roomSubscription;
  StreamSubscription<QuerySnapshot>? _candidatesSubscription;
  final Logger _logger = Logger();
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isConnected = false;
  Timer? _reconnectionTimer;
  int _reconnectionAttempts = 0;
  static const int _maxReconnectionAttempts = 5;
  MediaStream? _remoteStream;
  List<String> _processedCandidateIds = [];
  String? _role;
  bool _isDisposing = false;

  // Configuration constants
  static const _connectionTimeout = Duration(seconds: 30);
  static const _operationTimeout = Duration(seconds: 10);

  // Callbacks
  Function(RTCPeerConnectionState)? onConnectionState;
  Function(RTCIceConnectionState)? onIceConnectionState;
  Function(MediaStream)? onRemoteStream;
  Function(bool)? onConnectionStatusChanged;
  Function(bool)? onRoomReady;

  bool get isMuted => _isMuted;
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isConnected => _isConnected;
  MediaStream? get remoteStream => _remoteStream;

  static const _iceServers = [
    {
      'urls': [
        'stun:stun1.l.google.com:19302',
        'stun:stun2.l.google.com:19302',
      ]
    }
  ];

  final _configuration = {
    'iceServers': _iceServers,
    'sdpSemantics': 'unified-plan',
    'offerToReceiveVideo': true,
    'offerToReceiveAudio': true,
  };

  void setRole(String role) {
    _role = role;
  }

  Future<void> initializeWebRTC() async {
    try {
      await _cleanupPeerConnection();
      _logger.i('Initializing WebRTC connection...');

      _peerConnection = await createPeerConnection(_configuration);

      // Add transceivers for audio and video
      await _peerConnection?.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.SendRecv),
      );
      await _peerConnection?.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.SendRecv),
      );

      _setupPeerConnectionListeners();
      _isInitialized = true;
      _logger.i('WebRTC initialized successfully');
    } catch (e) {
      _logger.e('WebRTC initialization failed: $e');
      await _cleanupPeerConnection();
      rethrow;
    }
  }

  void _setupPeerConnectionListeners() {
    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) async {
      _logger.i('New ICE candidate: ${candidate.candidate}');
      if (_currentRoomId != null) {
        await _firestore
            .collection('rooms')
            .doc(_currentRoomId)
            .collection('candidates')
            .add(candidate.toMap());
      }
    };

    _peerConnection?.onIceConnectionState = (state) {
      _logger.i('ICE connection state: $state');
      onIceConnectionState?.call(state);
      _handleIceStateChange(state);
    };

    _peerConnection?.onConnectionState = (state) {
      _logger.i('Peer connection state: $state');
      onConnectionState?.call(state);
      _updateConnectionStatus(state);
    };

    _peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.track.kind == 'video' && event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
        onRemoteStream?.call(_remoteStream!);
      }
    };
  }

  void _updateConnectionStatus(RTCPeerConnectionState state) {
    final newStatus =
        state == RTCPeerConnectionState.RTCPeerConnectionStateConnected;
    if (_isConnected != newStatus) {
      _isConnected = newStatus;
      onConnectionStatusChanged?.call(_isConnected);
      if (_isConnected) _reconnectionAttempts = 0;
    }
  }

  void _handleIceStateChange(RTCIceConnectionState state) {
    if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
        state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
      _handleConnectionFailure();
    }
  }

  Future<MediaStream> getUserMedia() async {
    try {
      final Map<String, dynamic> mediaConstraints = {
        'audio': true,
        'video': {
          'mandatory': {
            'minWidth': '640',
            'minHeight': '480',
            'minFrameRate': '30',
          },
          'facingMode': 'user',
          'optional': [],
        }
      };

      MediaStream stream =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _localStream = stream;
      return stream;
    } catch (e) {
      _logger.e('Error getting user media: $e');
      rethrow;
    }
  }

  Future<void> createRoom(String roomId) async {
    try {
      _currentRoomId = roomId;

      // Create an offer
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      // Create room document with the offer
      await _firestore.collection('rooms').doc(roomId).set({
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _role,
        'status': 'waiting',
        'offer': {
          'type': offer.type,
          'sdp': offer.sdp,
        },
      });

      // Listen for answer and candidates
      _roomSubscription = _firestore
          .collection('rooms')
          .doc(roomId)
          .snapshots()
          .listen(_handleRoomUpdates);

      // Set up ICE candidate collection
      _listenForIceCandidates();

      onRoomReady?.call(true);
    } catch (e) {
      _logger.e('Error creating room: $e');
      rethrow;
    }
  }

  Future<void> joinRoom(String roomId) async {
    try {
      _currentRoomId = roomId;

      // Try to get the room with retries
      DocumentSnapshot? roomDoc;
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        roomDoc = await _firestore.collection('rooms').doc(roomId).get();

        if (roomDoc.exists) {
          final data = roomDoc.data() as Map<String, dynamic>?;
          if (data != null && data['offer'] != null) {
            break; // Room exists with offer, proceed with joining
          }
        }

        // Wait before retrying
        await Future.delayed(Duration(seconds: 1));
        retryCount++;

        if (retryCount == maxRetries) {
          throw Exception(
              'Room not found or not ready after multiple attempts');
        }
      }

      if (!roomDoc!.exists) throw Exception('Room not found');

      final data = roomDoc.data() as Map<String, dynamic>;
      final offer = data['offer'];
      if (offer == null) throw Exception('No offer found in room');

      await _peerConnection?.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );

      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      await _firestore
          .collection('rooms')
          .doc(roomId)
          .update({'answer': answer.toMap(), 'status': 'connected'});

      _listenForIceCandidates();

      // Set up room updates listener
      _roomSubscription = _firestore
          .collection('rooms')
          .doc(roomId)
          .snapshots()
          .listen(_handleRoomUpdates);
    } catch (e) {
      _logger.e('Error joining room: $e');
      rethrow;
    }
  }

  void _handleRoomUpdates(DocumentSnapshot snapshot) async {
    if (!snapshot.exists) {
      _logger.w('Room no longer exists');
      return;
    }

    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) return;

    try {
      // Handle answer if we're the caller
      if (_role == 'requester' && data['answer'] != null && !_isConnected) {
        final answer = data['answer'];
        if (answer != null && _peerConnection != null) {
          await _peerConnection!.setRemoteDescription(
            RTCSessionDescription(answer['sdp'], answer['type']),
          );
          _logger.i('Set remote description from answer');
        }
      }

      // Handle offer if we're the callee
      if (_role == 'volunteer' && data['offer'] != null && !_isConnected) {
        final offer = data['offer'];
        if (offer != null && _peerConnection != null) {
          await _peerConnection!.setRemoteDescription(
            RTCSessionDescription(offer['sdp'], offer['type']),
          );
          _logger.i('Set remote description from offer');

          // Create and set answer
          final answer = await _peerConnection!.createAnswer();
          await _peerConnection!.setLocalDescription(answer);

          // Send answer back
          await _firestore
              .collection('rooms')
              .doc(_currentRoomId)
              .update({'answer': answer.toMap(), 'status': 'connected'});
        }
      }

      // Handle room status changes
      if (data['status'] == 'connected' && !_isConnected) {
        _isConnected = true;
        onConnectionStatusChanged?.call(true);
        _logger.i('Connection established successfully');
      } else if (data['status'] == 'ended') {
        await endCall();
      }
    } catch (e) {
      _logger.e('Error handling room updates: $e');
      _handleConnectionFailure();
    }
  }

  void _listenForIceCandidates() {
    _candidatesSubscription?.cancel();
    _candidatesSubscription = _firestore
        .collection('rooms')
        .doc(_currentRoomId)
        .collection('candidates')
        .snapshots()
        .listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final candidateData = change.doc.data() as Map<String, dynamic>;
          if (!_processedCandidateIds.contains(change.doc.id)) {
            _processedCandidateIds.add(change.doc.id);
            try {
              await _peerConnection?.addCandidate(
                RTCIceCandidate(
                  candidateData['candidate'],
                  candidateData['sdpMid'],
                  candidateData['sdpMLineIndex'],
                ),
              );
              _logger.i('Added ICE candidate');
            } catch (e) {
              _logger.e('Error adding ICE candidate: $e');
            }
          }
        }
      }
    });
  }

  Future<void> startCall(MediaStream localStream) async {
    try {
      _logger.i('Starting call with local stream...');

      // Add local tracks to peer connection
      localStream.getTracks().forEach((track) async {
        await _peerConnection?.addTrack(track, localStream);
      });

      // If we're the requester, create and set the offer
      if (_role == 'requester') {
        final offer = await _peerConnection!.createOffer();
        await _peerConnection!.setLocalDescription(offer);

        // Update the room with the offer
        await _firestore.collection('rooms').doc(_currentRoomId).update({
          'offer': offer.toMap(),
        });
      }

      _logger.i('Call started successfully');
    } catch (e) {
      _logger.e('Error starting call: $e');
      rethrow;
    }
  }

  void _handleConnectionFailure() {
    if (_reconnectionAttempts < _maxReconnectionAttempts && !_isDisposing) {
      _reconnectionAttempts++;
      _logger.w(
          'Connection failed. Attempt $_reconnectionAttempts of $_maxReconnectionAttempts');

      _reconnectionTimer?.cancel();
      final delay =
          Duration(seconds: math.pow(2, _reconnectionAttempts).toInt());

      _reconnectionTimer = Timer(delay, () async {
        try {
          await _cleanupPeerConnection();
          await initializeWebRTC();
          if (_currentRoomId != null) {
            if (_role == 'requester') {
              await createRoom(_currentRoomId!);
            } else {
              await joinRoom(_currentRoomId!);
            }
          }
        } catch (e) {
          _logger.e('Reconnection failed: $e');
          _handleConnectionFailure();
        }
      });
    } else {
      _logger.e('Max reconnection attempts reached or disposing');
      onConnectionStatusChanged?.call(false);
    }
  }

  Future<void> toggleMute() async {
    try {
      _isMuted = !_isMuted;
      final audioTrack = _localStream
          ?.getAudioTracks()
          .firstWhere((track) => track.kind == 'audio');
      if (audioTrack != null) {
        audioTrack.enabled = !_isMuted;
      }
    } catch (e) {
      _logger.e('Error toggling mute: $e');
      rethrow;
    }
  }

  Future<void> toggleVideo() async {
    try {
      _isVideoEnabled = !_isVideoEnabled;
      final videoTrack = _localStream
          ?.getVideoTracks()
          .firstWhere((track) => track.kind == 'video');
      if (videoTrack != null) {
        videoTrack.enabled = _isVideoEnabled;
      }
    } catch (e) {
      _logger.e('Error toggling video: $e');
      rethrow;
    }
  }

  Future<void> endCall() async {
    try {
      _logger.i('Ending call...');
      _isDisposing = true;

      // Stop all tracks
      _localStream?.getTracks().forEach((track) async {
        await track.stop();
      });
      await _localStream?.dispose();

      // Update room status if exists
      if (_currentRoomId != null) {
        await _firestore.collection('rooms').doc(_currentRoomId).update(
            {'status': 'ended', 'endedAt': FieldValue.serverTimestamp()});
      }

      // Clean up resources
      await _cleanupPeerConnection();
      await _roomSubscription?.cancel();
      await _candidatesSubscription?.cancel();
      _reconnectionTimer?.cancel();

      _currentRoomId = null;
      _localStream = null;
      _remoteStream = null;
      _processedCandidateIds.clear();
      _isDisposing = false;
    } catch (e) {
      _logger.e('Error ending call: $e');
    }
  }

  Future<void> _cleanupPeerConnection() async {
    try {
      final senders = await _peerConnection?.getSenders();
      if (senders != null) {
        for (var sender in senders) {
          await _peerConnection?.removeTrack(sender);
        }
      }

      await _peerConnection?.close();
      _peerConnection = null;
      _isInitialized = false;
      _isConnected = false;
    } catch (e) {
      _logger.e('Error during cleanup: $e');
    }
  }

  void dispose() {
    endCall();
  }
}
