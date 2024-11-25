import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/video_call_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String role; // 'requester' or 'volunteer'

  const VideoCallScreen({super.key, required this.role});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final VideoCallService videoCallService = VideoCallService();
  bool isCallStarted = false;
  MediaStream? localStream;
  MediaStream? remoteStream;
  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    initializeVideoCall();
  }

  Future<void> initializeVideoCall() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();

    // Get user media (camera and microphone)
    localStream = await videoCallService.getUserMedia();
    localRenderer.srcObject = localStream;

    // Initialize WebRTC connection
    await videoCallService.initializeWebRTC();

    // Handle remote tracks
    videoCallService.peerConnection.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        setState(() {
          remoteStream = event.streams.first;
          remoteRenderer.srcObject = remoteStream;
        });
      }
    };

    // Start call logic
    await videoCallService.startCall(localStream!);

    setState(() {
      isCallStarted = true;
    });
  }

  @override
  void dispose() {
    videoCallService.endCall();
    localRenderer.dispose();
    remoteRenderer.dispose();
    super.dispose();
  }

  Widget _renderLocalVideo() {
    return RTCVideoView(
      localRenderer,
      mirror: true,
      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
    );
  }

  Widget _renderRemoteVideo() {
    if (remoteStream != null) {
      return RTCVideoView(
        remoteRenderer,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
      );
    } else {
      return const Center(
        child: Text(
          'Waiting for remote user to join...',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Call')),
      body: isCallStarted
          ? Stack(
              children: [
                _renderRemoteVideo(),
                Positioned(
                  top: 16,
                  left: 16,
                  width: 100,
                  height: 150,
                  child: _renderLocalVideo(),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.pop(context);
        },
        child: const Icon(Icons.call_end),
      ),
    );
  }
}
