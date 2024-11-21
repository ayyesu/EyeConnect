import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    initializeVideoCall();
  }

  Future<void> initializeVideoCall() async {
    await videoCallService.initializeAgora();
    setState(() {
      isCallStarted = true;
    });
    videoCallService.startCall('help_channel');
  }

  @override
  void dispose() {
    videoCallService.endCall();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Call')),
      body: Center(
        child: isCallStarted
            ? const Text('Call in progress...')
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: const Icon(Icons.call_end),
      ),
    );
  }
}
