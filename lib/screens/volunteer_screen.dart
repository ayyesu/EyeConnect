import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/help_request_provider.dart';
import 'video_call_screen.dart';

class VolunteerScreen extends StatelessWidget {
  const VolunteerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final requests = context.watch<HelpRequestProvider>().requests;

    return Scaffold(
      appBar: AppBar(title: const Text('Help Requests')),
      body: requests.isEmpty
          ? const Center(
              child: Text(
                'No active help requests.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                return ListTile(
                  title: Text('Request from ${request.requesterName}'),
                  subtitle: Text('Request ID: ${request.id}'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // Accept the request and remove it from the list
                      context
                          .read<HelpRequestProvider>()
                          .acceptRequest(request.id);
                      context
                          .read<HelpRequestProvider>()
                          .removeRequest(request.id);

                      // Navigate to the video call screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const VideoCallScreen(role: 'volunteer'),
                        ),
                      );
                    },
                    child: const Text('Help'),
                  ),
                );
              },
            ),
    );
  }
}
