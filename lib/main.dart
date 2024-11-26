import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:myapp/providers/help_request_provider.dart';
import 'package:myapp/screens/login_screen.dart';
import 'package:myapp/screens/onboarding_screen.dart'; // Add this import
import 'package:myapp/screens/volunteer_screen.dart' as volunteer_screen;
import 'package:myapp/screens/visually_impaired_screen.dart'
    as visually_impaired_screen;
import 'package:myapp/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

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
      home: const MainScreen(), // Update to use the new MainScreen widget
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
    setState(() {
      _showOnboarding = !seenOnboarding; // Show onboarding if not seen
    });
  }

  Future<void> _setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding) {
      return OnboardingScreen(
        onDone: () async {
          await _setOnboardingSeen();
          setState(() => _showOnboarding = false);
        },
      );
    }

    return FutureBuilder<User?>(
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
                  return const volunteer_screen.VolunteerScreen();
                } else if (role == 'Visually Impaired') {
                  return const visually_impaired_screen.VolunteerScreen();
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
    );
  }
}
