import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../models/help_request_model.dart';
import '../providers/help_request_provider.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'login_screen.dart';
import 'video_call_screen.dart';

class VisuallyImpairedScreen extends StatelessWidget {
  const VisuallyImpairedScreen({super.key});

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
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-out failed: ${e.toString()}')),
      );
    }
  }

  Future<String> _getRequesterName() async {
    final userDetail = await AuthService().getUserDetails();
    final username = userDetail['username'];

    if (username != null) {
      return username;
    }
    return 'Unknown User';
  }

  Future<bool> _checkAndRequestPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final microphoneStatus = await Permission.microphone.status;

    // If permissions are already granted, return true
    if (cameraStatus.isGranted && microphoneStatus.isGranted) {
      return true;
    }

    // Request permissions only if they're not already granted
    final permissions = [
      Permission.camera,
      Permission.microphone,
    ];

    // Request permissions that aren't granted yet
    final statuses = await permissions.request();
    return statuses.values.every((status) => status.isGranted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Get Live Video Support'),
        actions: [
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
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Center(
              child: FutureBuilder<String>(
                future: _getRequesterName(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return const Text(
                      'Error retrieving user information.',
                      style: TextStyle(color: Colors.red),
                    );
                  }

                  final requesterName = snapshot.data ?? 'Unknown User';

                  return ElevatedButton(
                    onPressed: () async {
                      // Check and request permissions before making the call
                      final hasPermissions =
                          await _checkAndRequestPermissions();
                      if (!context.mounted) return;
                      if (!hasPermissions) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Please grant all required permissions to make a video call.'),
                          ),
                        );
                        return;
                      }

                      // Generate a unique request ID
                      final requestId = DateTime.now().toIso8601String();
                      final helpRequest = HelpRequest(
                        id: requestId,
                        requesterName: requesterName,
                        requesterId: AuthService().getCurrentUser()?.uid ?? '',
                        description: 'Video assistance request',
                        timestamp: DateTime.now(),
                      );

                      // Add the request to the provider
                      if (!context.mounted) return;
                      await context
                          .read<HelpRequestProvider>()
                          .addRequest(helpRequest);

                      // Navigate to video call screen immediately to create the room
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoCallScreen(
                            role: 'requester',
                            requestId: requestId,
                          ),
                        ),
                      );

                      // Send notification
                      final notificationService = NotificationService();
                      await notificationService.sendHelpRequestNotification();

                      // Show success message
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Waiting for a volunteer to join...'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          vertical: 20.0, horizontal: 40.0),
                      textStyle: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                      minimumSize: const Size(300, 200),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: const Text(
                      'Request Help',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Consumer<HelpRequestProvider>(
              builder: (context, provider, child) {
                final userId = AuthService().getCurrentUser()?.uid;
                if (userId == null) {
                  return const Center(
                    child: Text('Please sign in to view your requests'),
                  );
                }

                final userRequests = provider.getRequestsByUser(userId);
                if (userRequests.isEmpty) {
                  return const Center(
                    child: Text(
                      'Make a request to get started.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: userRequests.length,
                  padding: const EdgeInsets.all(16.0),
                  itemBuilder: (context, index) {
                    final request = userRequests[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: ListTile(
                        title: Text(
                          'Help Request',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                request.isAccepted ? Colors.green : Colors.blue,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Status: ${request.isAccepted ? 'Accepted' : 'Pending'}'),
                            Text(
                                'Time: ${request.timestamp.toString().split('.')[0]}'),
                          ],
                        ),
                        trailing: request.isAccepted
                            ? ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => VideoCallScreen(
                                        role: 'requester',
                                        requestId: request.id,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Join Call'),
                              )
                            : const Icon(Icons.pending, color: Colors.orange),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
