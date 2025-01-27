import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:eyeconnect/screens/leaderboard_screen.dart';
import 'package:provider/provider.dart';
import '../providers/help_request_provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'video_call_screen.dart';
import 'volunteer_profile_screen.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VolunteerProfileScreen()),
            ),
          ),
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
      body: Consumer<HelpRequestProvider>(
        builder: (context, provider, child) {
          final availableRequests = provider.requests.where((r) => !r.isAccepted).toList();
          final myAcceptedRequests = provider.acceptedRequests
              .where((r) => r.volunteerId == FirebaseAuth.instance.currentUser?.uid)
              .toList();

          if (availableRequests.isEmpty && myAcceptedRequests.isEmpty) {
            return Column(
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
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              if (myAcceptedRequests.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Your Active Sessions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                ...myAcceptedRequests.map((request) => Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: ListTile(
                        title: Text(
                          'Active Session with ${request.requesterName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        subtitle: Text(
                            'Started at: ${request.timestamp.toString().split('.')[0]}'),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VideoCallScreen(
                                  role: 'volunteer',
                                  volunteerId: FirebaseAuth.instance.currentUser?.uid,
                                  requestId: request.id,
                                ),
                              ),
                            );
                          },
                          child: const Text('Join Call'),
                        ),
                      ),
                    )),
                const Divider(height: 32.0),
              ],
              if (availableRequests.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Available Requests',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                ...availableRequests.map((request) => Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: ListTile(
                        title: Text(
                          'Request from ${request.requesterName}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Time: ${request.timestamp.toString().split('.')[0]}'),
                            Text('Description: ${request.description}'),
                          ],
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          onPressed: () async {
                            // Accept the request
                            await provider.acceptRequest(
                                request.id, FirebaseAuth.instance.currentUser!.uid);

                            if (!context.mounted) return;
                            // Navigate to the video call screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VideoCallScreen(
                                  role: 'volunteer',
                                  volunteerId: FirebaseAuth.instance.currentUser?.uid,
                                  requestId: request.id,
                                ),
                              ),
                            );
                          },
                          child: const Text('Help'),
                        ),
                      ),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }
}
