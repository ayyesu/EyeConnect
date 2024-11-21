import 'package:flutter/material.dart';
import 'video_call_screen.dart';

class VisuallyImpairedScreen extends StatelessWidget {
  const VisuallyImpairedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Help')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VideoCallScreen(role: 'requester')),
            );
          },
          child: const Text('Request Help'),
        ),
      ),
    );
  }
}
