import 'package:flutter/material.dart';
import 'volunteer_screen.dart';
import 'visually_impaired_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Role')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VisuallyImpairedScreen()),
                );
              },
              child: const Text('I am Visually Impaired'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VolunteerScreen()),
                );
              },
              child: const Text('I am a Volunteer'),
            ),
          ],
        ),
      ),
    );
  }
}
