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
  String? _role; // Added to store the role (requester/volunteer)
  bool _isDisposing = false;

  // Configuration constants
  static const _connectionTimeout = Duration(seconds: 30);
  static const _operationTimeout = Duration(seconds: 10);
  // Update ICE server configuration for better connectivity
  static const _iceServers = [
    {
      'urls': [
        'stun:stun.l.google.com:19302',
        'stun:stun1.l.google.com:19302',
        'stun:stun2.l.google.com:19302'
      ]
    },
    {
      'urls': 'turn:relay1.expressturn.com:3478',
      'username': 'ef3FDGMHG341PHR3OY',
      'credential': 'TRh5BfDm6om6eOsc'
    }
  ];

  // Add reliable connection config
  final _configuration = {
    'iceServers': _iceServers,
    'sdpSemantics': 'unified-plan',
    'iceTransportPolicy':
        'all', // Change from 'relay' to 'all' for better connectivity
    'bundlePolicy': 'max-bundle',
    'rtcpMuxPolicy': 'require'
  };

  // State callbacks
  Function(RTCPeerConnectionState)? onConnectionState;
  Function(RTCIceConnectionState)? onIceConnectionState;
  Function(MediaStream)? onRemoteStream;
  Function(bool)? onRoomReady;
  Function(bool)? onConnectionStatusChanged;

  bool get isMuted => _isMuted;
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isConnected => _isConnected;

  // Set the role (requester/volunteer)
  void setRole(String role) {
    _role = role;
  }

  Future<void> toggleMute() async {
    try {
      _isMuted = !_isMuted;
      if (_localStream != null) {
        for (var track in _localStream!.getAudioTracks()) {
          track.enabled = !_isMuted;
        }
        _logger.i('Audio ${_isMuted ? 'muted' : 'unmuted'}');
      }
    } catch (e) {
      _isMuted = !_isMuted;
      _logger.e('Error toggling mute: $e');
      rethrow;
    }
  }

  Future<void> toggleVideo() async {
    try {
      if (_localStream == null) return;

      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isEmpty) return;

      _isVideoEnabled = !_isVideoEnabled;
      for (var track in videoTracks) {
        track.enabled = _isVideoEnabled;
      }
      _logger.i('Video ${_isVideoEnabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      _isVideoEnabled = !_isVideoEnabled;
      _logger.e('Error toggling video: $e');
      rethrow;
    }
  }

  Future<void> initializeWebRTC() async {
    try {
      await _cleanupPeerConnection();
      _logger.i('Initializing WebRTC connection...');

      _peerConnection =
          await createPeerConnection(_configuration).timeout(_operationTimeout);

      _setupPeerConnectionListeners();
      _isInitialized = true;
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

  Future<void> _cleanupPeerConnection() async {
    _logger.i('Cleaning up peer connection...');
    try {
      // Close data channels if any
      final senders = await _peerConnection?.getSenders();
      if (senders != null) {
        for (var sender in senders) {
          await _peerConnection?.removeTrack(sender);
        }
      }

      // Close the peer connection
      await _peerConnection?.close();
      _peerConnection = null;
      _isInitialized = false;
      _isConnected = false;
    } catch (e) {
      _logger.e('Error during cleanup: $e');
      // Continue with cleanup even if there's an error
    }
  }

  Future<MediaStream> getUserMedia() async {
    try {
      // Check if permissions are granted first
      final permissions = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false // Just to check permissions
      });
      await permissions.dispose();

      // Now get the actual media stream with desired constraints
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {
          'mandatory': {
            'minWidth': '640',
            'minHeight': '480',
            'minFrameRate': '24',
          },
          'facingMode': 'user',
          'optional': []
        }
      }).timeout(_operationTimeout);

      return _localStream!;
    } catch (e) {
      if (e.toString().contains('PermissionDeniedError')) {
        throw Exception(
            'Camera and microphone permissions are required for video calls');
      }
      _logger.e('Error getting user media: $e');
      rethrow;
    }
  }

  Future<void> startCall(MediaStream localStream) async {
    if (!_isInitialized) throw Exception('WebRTC not initialized');

    try {
      for (var track in localStream.getTracks()) {
        await _peerConnection?.addTrack(track, localStream);
      }

      final offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      }).timeout(_operationTimeout);

      await _peerConnection!.setLocalDescription(offer);
      await _saveOfferToFirestore(offer);
    } catch (e) {
      _logger.e('Error starting call: $e');
      await _cleanupPeerConnection();
      rethrow;
    }
  }

  Future<void> _saveOfferToFirestore(RTCSessionDescription offer) async {
    if (_currentRoomId == null) return;

    await _firestore.collection('rooms').doc(_currentRoomId).set({
      'offer': offer.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active'
    }).timeout(_operationTimeout);
  }

  Future<void> createRoom(String roomId) async {
    try {
      _currentRoomId = roomId;
      await _firestore.collection('rooms').doc(roomId).set({
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'initializing'
      });
      onRoomReady?.call(true);
    } catch (e) {
      _logger.e('Error creating room: $e');
      rethrow;
    }
  }

  Future<void> joinRoom(String roomId) async {
    try {
      _currentRoomId = roomId;
      final roomDoc = await _firestore
          .collection('rooms')
          .doc(roomId)
          .get()
          .timeout(_operationTimeout);

      if (!roomDoc.exists) throw Exception('Room not found');

      final offer = roomDoc.data()?['offer'];
      if (offer == null) throw Exception('No offer found in room');

      await _peerConnection?.setRemoteDescription(
          RTCSessionDescription(offer['sdp'], offer['type']));
      await _createAndSendAnswer();
      _listenForIceCandidates();
    } catch (e) {
      _logger.e('Error joining room: $e');
      rethrow;
    }
  }

  Future<void> _createAndSendAnswer() async {
    final answer = await _peerConnection!.createAnswer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': true,
    }).timeout(_operationTimeout);

    await _peerConnection!.setLocalDescription(answer);

    await _firestore.collection('rooms').doc(_currentRoomId).update({
      'answer': answer.toMap(),
      'status': 'connected',
      'connectedAt': FieldValue.serverTimestamp()
    }).timeout(_operationTimeout);
  }

  void _listenForIceCandidates() {
    _candidatesSubscription = _firestore
        .collection('rooms')
        .doc(_currentRoomId)
        .collection('candidates')
        .snapshots()
        .listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added &&
            !_processedCandidateIds.contains(change.doc.id)) {
          final candidate = RTCIceCandidate(
            change.doc['candidate'],
            change.doc['sdpMid'],
            change.doc['sdpMLineIndex'],
          );
          await _peerConnection?.addCandidate(candidate);
          _processedCandidateIds.add(change.doc.id);
        }
      }
    });
  }

  void _handleConnectionFailure() {
    if (_reconnectionAttempts < _maxReconnectionAttempts && !_isDisposing) {
      _reconnectionAttempts++;
      _logger.w(
          'Connection failed. Attempt $_reconnectionAttempts of $_maxReconnectionAttempts');

      // Cancel existing timer if any
      _reconnectionTimer?.cancel();

      // Exponential backoff for reconnection
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
          _handleConnectionFailure(); // Try again if failed
        }
      });
    } else {
      _logger.e('Max reconnection attempts reached or disposing');
      onConnectionStatusChanged?.call(false);
    }
  }

  Future<void> endCall() async {
    try {
      _logger.i('Ending call...');
      // Cancel all subscriptions
      await _roomSubscription?.cancel();
      await _candidatesSubscription?.cancel();
      _reconnectionTimer?.cancel();

      // Clean up streams
      _localStream?.getTracks().forEach((track) async {
        await track.stop();
      });
      await _localStream?.dispose();
      _remoteStream?.getTracks().forEach((track) async {
        await track.stop();
      });
      await _remoteStream?.dispose();

      // Update room status
      if (_currentRoomId != null) {
        await _firestore.collection('rooms').doc(_currentRoomId).update({
          'status': 'ended',
          'endedAt': FieldValue.serverTimestamp()
        }).timeout(_operationTimeout);
      }

      // Reset state
      _localStream = null;
      _remoteStream = null;
      _currentRoomId = null;
      _processedCandidateIds.clear();
      _reconnectionAttempts = 0;

      await _cleanupPeerConnection();
    } catch (e) {
      _logger.e('Error ending call: $e');
      // Continue with cleanup even if there's an error
    }
  }
}
