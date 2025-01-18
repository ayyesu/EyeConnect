import 'package:flutter_webrtc/flutter_webrtc.dart';

class VideoCallService {
  late RTCPeerConnection _peerConnection;
  final List<RTCIceCandidate> _pendingCandidates = [];
  bool _isInitialized = false;
  MediaStream? _localStream;
  String? _currentCameraType;

  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
    ],
  };

  final Map<String, dynamic> _offerSdpConstraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };

  Future<void> initializeWebRTC() async {
    _peerConnection = await createPeerConnection(_configuration);
    _setupPeerConnectionListeners();
    _isInitialized = true;

    // Add any pending candidates that were received before initialization
    for (var candidate in _pendingCandidates) {
      await _peerConnection.addCandidate(candidate);
    }
    _pendingCandidates.clear();
  }

  void _setupPeerConnectionListeners() {
    _peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
      // Handle new ICE candidate - this should be sent to the remote peer
      onIceCandidate?.call(candidate);
    };

    _peerConnection.onIceConnectionState = (RTCIceConnectionState state) {
      // Handle ICE connection state changes
      onIceConnectionState?.call(state);
    };

    _peerConnection.onConnectionState = (RTCPeerConnectionState state) {
      // Handle peer connection state changes
      onConnectionState?.call(state);
    };
  }

  // Callback functions that can be set by the UI layer
  Function(RTCIceCandidate candidate)? onIceCandidate;
  Function(RTCIceConnectionState state)? onIceConnectionState;
  Function(RTCPeerConnectionState state)? onConnectionState;

  RTCPeerConnection get peerConnection => _peerConnection;

  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    if (_isInitialized) {
      await _peerConnection.addCandidate(candidate);
    } else {
      _pendingCandidates.add(candidate);
    }
  }

  Future<void> startCall(MediaStream localStream) async {
    _localStream = localStream;
    localStream.getTracks().forEach((track) {
      _peerConnection.addTrack(track, localStream);
    });

    RTCSessionDescription offer =
        await _peerConnection.createOffer(_offerSdpConstraints);
    await _peerConnection.setLocalDescription(offer);
  }

  Future<void> handleRemoteAnswer(String sdp) async {
    RTCSessionDescription answer = RTCSessionDescription(sdp, 'answer');
    await _peerConnection.setRemoteDescription(answer);
  }

  Future<void> switchCamera() async {
    if (_localStream == null) return;

    final videoTrack = _localStream!.getVideoTracks().firstOrNull;
    if (videoTrack == null) return;

    // Switch camera type
    _currentCameraType = _currentCameraType == 'user' ? 'environment' : 'user';

    final newConstraints = {
      'audio': true,
      'video': {
        'facingMode': _currentCameraType,
      },
    };

    // Get new stream with switched camera
    final newStream = await navigator.mediaDevices.getUserMedia(newConstraints);
    final newVideoTrack = newStream.getVideoTracks().first;

    // Stop and remove old track
    await videoTrack.stop();
    await _localStream!.removeTrack(videoTrack);
    await _localStream!.addTrack(newVideoTrack);

    // Replace track in peer connection
    final senders = await _peerConnection.getSenders();
    final videoSender =
        senders.where((sender) => sender.track?.kind == 'video').firstOrNull;

    if (videoSender != null) {
      await videoSender.replaceTrack(newVideoTrack);
    }
  }

  void endCall() {
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _peerConnection.close();
    _isInitialized = false;
    _pendingCandidates.clear();
  }

  Future<MediaStream> getUserMedia() async {
    _currentCameraType = 'user';
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {
        'facingMode': _currentCameraType,
      },
    };
    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    return _localStream!;
  }
}
