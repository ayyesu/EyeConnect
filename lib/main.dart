import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:myapp/providers/help_request_provider.dart';
import 'package:myapp/screens/login_screen.dart';
import 'package:myapp/screens/volunteer_screen.dart';
import 'package:myapp/screens/visually_impaired_screen.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:provider/provider.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(ChangeNotifierProvider(
      create: (_) => HelpRequestProvider(), child: const BeMyEyesApp()));
}

class BeMyEyesApp extends StatelessWidget {
  const BeMyEyesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Be My Eyes',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder<User?>(
        future: FirebaseAuth.instance.authStateChanges().first,
        builder: (context, snapshot) {
          // Show a loading indicator while checking auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // If the user is signed in, fetch their role
          if (snapshot.hasData) {
            return FutureBuilder<Map<String, String?>>(
              future: AuthService().getUserDetails(), // Fetch user details
              builder: (context, userDetailsSnapshot) {
                if (userDetailsSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (userDetailsSnapshot.hasData) {
                  final userDetails = userDetailsSnapshot.data!;
                  final role = userDetails['role'];

                  if (role == 'Volunteer') {
                    return const VolunteerScreen();
                  } else if (role == 'Visually Impaired') {
                    return const VisuallyImpairedScreen();
                  } else {
                    return const LoginScreen(); // Default for unknown roles
                  }
                } else {
                  return const LoginScreen();
                }
              },
            );
          }

          // If no user is signed in, show the LoginScreen
          return const LoginScreen();
        },
      ),
    );
  }
}
