import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myapp/screens/leaderboard_screen.dart';
import 'package:provider/provider.dart';
import '../providers/help_request_provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'video_call_screen.dart';

class VolunteerScreen extends StatelessWidget {
  const VolunteerScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    final authService = AuthService();
    try {
      await authService.signOut();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed out successfully')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-out failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final requests = context.watch<HelpRequestProvider>().requests;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
            ),
          ),
          IconButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all<Color>(Colors.red),
              foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
            ),
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: requests.isEmpty
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/no-request.png'),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'No active help requests.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ),
              ],
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
                      context.read<HelpRequestProvider>().acceptRequest(
                          request.id, FirebaseAuth.instance.currentUser!.uid);
                      context
                          .read<HelpRequestProvider>()
                          .removeRequest(request.id);

                      // Navigate to the video call screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoCallScreen(
                            role: 'volunteer',
                            volunteerId: FirebaseAuth.instance.currentUser?.uid,
                          ),
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
