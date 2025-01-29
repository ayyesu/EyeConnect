import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import '../services/video_call_service.dart';
import '../providers/leaderboard_provider.dart';
import '../providers/help_request_provider.dart';
import '../widgets/rating_dialog.dart';
import 'package:logger/logger.dart';

final Logger _logger = Logger();

class VideoCallScreen extends StatefulWidget {
  final String role;
  final String? volunteerId;
  final String requestId;

  const VideoCallScreen({
    super.key,
    required this.role,
    this.volunteerId,
    required this.requestId,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final VideoCallService _videoCallService = VideoCallService();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  bool _isCallStarted = false;
  bool _isConnected = false;
  bool _isDisposing = false;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  late RTCVideoRenderer _localRenderer;
  late RTCVideoRenderer _remoteRenderer;
  DateTime? _startTime;
  HelpRequestProvider? _helpRequestProvider;
  LeaderboardProvider? _leaderboardProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _helpRequestProvider =
        Provider.of<HelpRequestProvider>(context, listen: false);
    _leaderboardProvider =
        Provider.of<LeaderboardProvider>(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _initializeRenderers();
  }

  Future<void> _initializeRenderers() async {
    try {
      _localRenderer = RTCVideoRenderer();
      _remoteRenderer = RTCVideoRenderer();
      await Future.wait([
        _localRenderer.initialize(),
        _remoteRenderer.initialize(),
      ]);
      _initializeVideoCall();
    } catch (e) {
      _handleError('Failed to initialize video renderers: $e');
    }
  }

  Future<void> _initializeVideoCall() async {
    try {
      // Set the role for the video call service
      _videoCallService.setRole(widget.role);

      // Initialize WebRTC
      await _videoCallService.initializeWebRTC();

      // Get user media and set local stream
      _localStream = await _videoCallService.getUserMedia();
      _localRenderer.srcObject = _localStream;
      setState(() {});

      // Set up callbacks
      _setupCallbacks();

      // Handle role-specific setup
      await _handleRoleSpecificSetup();

      // Start connection timeout
      _startConnectionTimeout();
    } catch (e) {
      _handleError('Failed to initialize video call: $e');
    }
  }

  void _setupCallbacks() {
    _videoCallService
      ..onConnectionState = (state) {
        _logger.i('Connection state changed: $state');
      }
      ..onIceConnectionState = (state) {
        _logger.i('ICE connection state changed: $state');
      }
      ..onRemoteStream = (stream) {
        if (!mounted) return;
        setState(() {
          _remoteStream = stream;
          _remoteRenderer.srcObject = stream;
          _isConnected = true;
        });
      }
      ..onConnectionStatusChanged = (isConnected) {
        if (!mounted) return;
        setState(() => _isConnected = isConnected);
      };
  }

  Future<void> _handleRoleSpecificSetup() async {
    try {
      if (widget.role == 'requester') {
        // Create room and start call
        await _videoCallService.createRoom(widget.requestId);
        await _videoCallService.startCall(_localStream!);
      } else {
        // Join existing room
        await _videoCallService.joinRoom(widget.requestId);
      }
      setState(() => _isCallStarted = true);
    } catch (e) {
      _handleError('Failed to setup call: $e');
    }
  }

  void _startConnectionTimeout() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted && !_isConnected) {
        _handleError('Connection timeout. Please try again.');
        _endCall();
      }
    });
  }

  Future<void> _endCall() async {
    if (_isDisposing) return;

    try {
      // Calculate call duration
      final endTime = DateTime.now();
      final callDuration = endTime.difference(_startTime!);

      // End the call in video service
      await _videoCallService.endCall();

      // Show rating dialog for visually impaired users
      if (widget.role == 'requester') {
        if (!mounted) return;
        final rating = await showDialog<double>(
          context: context,
          barrierDismissible: false,
          builder: (context) => RatingDialog(
            requestId: widget.requestId,
            volunteerId: widget.volunteerId ??
                'test_volunteer', // Use a test volunteer ID if none provided
            callDuration: callDuration.inSeconds,
          ),
        );

        if (rating != null && mounted && widget.volunteerId != null) {
          // Only update stats if there was an actual volunteer
          await _leaderboardProvider?.updateVolunteerStats(
            widget.volunteerId!,
            callDuration: callDuration.inMinutes,
            rating: rating,
          );
        }
      }

      // Delete help request
      await _helpRequestProvider?.deleteHelpRequest(widget.requestId);

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      _handleError('Error ending call: $e');
    }
  }

  void _handleError(String message) {
    if (!mounted) return;
    _logger.e(message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _isDisposing = true;
    _videoCallService.endCall();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  Widget _renderLocalVideo() {
    return RTCVideoView(
      _localRenderer,
      mirror: true,
      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
    );
  }

  Widget _renderRemoteVideo() {
    return RTCVideoView(
      _remoteRenderer,
      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              // Main remote video (only show when we have a remote stream)
              if (_isCallStarted && _remoteStream != null)
                SizedBox.expand(child: _renderRemoteVideo()),

              // Local video preview (always show once call is started)
              if (_isCallStarted)
                Positioned(
                  top: 20,
                  right: 20,
                  child: _LocalPreview(renderer: _renderLocalVideo()),
                ),

              Stack(
                children: [
                  // Connection status overlay
                  if (_isCallStarted)
                    if (!_isConnected)
                      const _ConnectionOverlay(message: 'Connecting...')
                    else if (_remoteStream == null)
                      const _ConnectionOverlay(
                        message: 'Waiting for other participant to join...',
                      ),

                  // Top app bar
                  const _CallAppBar(),

                  // Bottom controls
                  if (_isCallStarted) const _CallControls(),
                ],
              ),

              // Initial loading indicator
              if (!_isCallStarted) const Center(child: _LoadingIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}

// New reusable widgets

class _LocalPreview extends StatelessWidget {
  final Widget renderer;

  const _LocalPreview({required this.renderer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.white54, width: 1),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 179).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: renderer,
      ),
    );
  }
}

class _ConnectionOverlay extends StatelessWidget {
  final String message;
  const _ConnectionOverlay({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CallAppBar extends StatelessWidget {
  const _CallAppBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 179), Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Video Call',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _CallControls extends StatelessWidget {
  const _CallControls();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_VideoCallScreenState>()!;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 179), Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ControlButton(
              icon: state._videoCallService.isMuted ? Icons.mic_off : Icons.mic,
              onPressed: () => state._videoCallService.toggleMute(),
            ),
            _ControlButton(
              icon: state._videoCallService.isVideoEnabled
                  ? Icons.videocam
                  : Icons.videocam_off,
              onPressed: () => state._videoCallService.toggleVideo(),
            ),
            _EndCallButton(onPressed: state._endCall),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ControlButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: Colors.white, size: 32),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black54,
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}

class _EndCallButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _EndCallButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: Colors.red,
      onPressed: onPressed,
      child: const Icon(Icons.call_end, color: Colors.white, size: 32),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const CircularProgressIndicator(
      color: Colors.white,
      strokeWidth: 3,
    );
  }
}
