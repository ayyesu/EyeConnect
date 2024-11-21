import 'package:flutter/material.dart';
import 'video_call_screen.dart';

class VolunteerScreen extends StatelessWidget {
  const VolunteerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help Requests')),
      body: ListView.builder(
        itemCount: 5, // Placeholder for actual requests
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Request #$index'),
            trailing: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VideoCallScreen(role: 'volunteer')),
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
