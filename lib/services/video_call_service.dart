import 'package:flutter_webrtc/flutter_webrtc.dart';

class VideoCallService {
  late RTCPeerConnection _peerConnection;
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
    // Set up ICE candidates and other listeners here if needed
  }

  RTCPeerConnection get peerConnection => _peerConnection;

  Future<void> startCall(MediaStream localStream) async {
    localStream.getTracks().forEach((track) {
      _peerConnection.addTrack(track, localStream);
    });

    RTCSessionDescription offer = await _peerConnection.createOffer(_offerSdpConstraints);
    await _peerConnection.setLocalDescription(offer);

    print('Offer created: ${offer.sdp}');
  }

  Future<void> handleRemoteAnswer(String sdp) async {
    RTCSessionDescription answer = RTCSessionDescription(sdp, 'answer');
    await _peerConnection.setRemoteDescription(answer);
    print('Remote answer set.');
  }

  void endCall() {
    _peerConnection.close();
  }

  Future<MediaStream> getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {
        'facingMode': 'user',
      },
    };
    return await navigator.mediaDevices.getUserMedia(mediaConstraints);
  }
}
