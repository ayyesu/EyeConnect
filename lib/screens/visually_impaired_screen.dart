import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/help_request_model.dart';
import '../providers/help_request_provider.dart';
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
            // Generate a unique request ID
            final requestId = DateTime.now().toIso8601String();
            final helpRequest =
                HelpRequest(id: requestId, requesterName: 'User123');

            // Add the request to the provider
            context.read<HelpRequestProvider>().addRequest(helpRequest);

            // Navigate to the video call screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const VideoCallScreen(role: 'requester'),
              ),
            );
          },
          child: const Text('Request Help'),
        ),
      ),
    );
  }
}
