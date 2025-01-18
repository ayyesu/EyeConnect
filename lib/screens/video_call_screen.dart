import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import '../services/video_call_service.dart';
import '../providers/leaderboard_provider.dart';
import '../widgets/rating_dialog.dart';

class VideoCallScreen extends StatefulWidget {
  final String role; // 'requester' or 'volunteer'
  final String? volunteerId; // Add this field

  const VideoCallScreen({
    super.key,
    required this.role,
    this.volunteerId, // Add this parameter
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final VideoCallService videoCallService = VideoCallService();
  String? volunteerId; // Add this line
  bool isCallStarted = false;
  MediaStream? localStream;
  MediaStream? remoteStream;
  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    volunteerId = widget.volunteerId; // Initialize volunteerId
    _startTime = DateTime.now();
    initializeVideoCall();
  }

  Future<void> initializeVideoCall() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();

    localStream = await videoCallService.getUserMedia();
    localRenderer.srcObject = localStream;

    await videoCallService.initializeWebRTC();

    videoCallService.peerConnection.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        setState(() {
          remoteStream = event.streams.first;
          remoteRenderer.srcObject = remoteStream;
        });
      }
    };

    await videoCallService.startCall(localStream!);

    setState(() {
      isCallStarted = true;
    });
  }

  Future<void> _showRatingDialog() async {
    if (widget.role == 'requester' && mounted) {
      final rating = await showDialog<double>(
        context: context,
        barrierDismissible: false, // Prevent dismissing by tapping outside
        builder: (_) => const RatingDialog(),
      );

      if (rating != null && widget.volunteerId != null && _startTime != null) {
        final duration = DateTime.now().difference(_startTime!);
        if (mounted) {
          await context.read<LeaderboardProvider>().updateVolunteerStats(
                widget.volunteerId!,
                callDuration: duration,
                rating: rating,
              );
        }
      }
    }
  }

  @override
  void dispose() {
    _showRatingDialog(); // Show rating dialog before disposing
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
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            heroTag: 'switchCamera',
            onPressed: () => videoCallService.switchCamera(),
            child: const Icon(Icons.switch_camera),
          ),
          FloatingActionButton(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            heroTag: 'endCall',
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Icon(Icons.call_end),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
    );
  }
}
