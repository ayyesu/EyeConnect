import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:eyeconnect/providers/help_request_provider.dart';
import 'package:eyeconnect/providers/leaderboard_provider.dart';
import 'package:eyeconnect/screens/login_screen.dart';
import 'package:eyeconnect/screens/onboarding_screen.dart';
import 'package:eyeconnect/screens/visually_impaired_screen.dart';
import 'package:eyeconnect/screens/volunteer_screen.dart';
import 'package:eyeconnect/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HelpRequestProvider()),
        ChangeNotifierProvider(create: (_) => LeaderboardProvider()),
      ],
      child: const EyeConnectApp(),
    ),
  );
}

class EyeConnectApp extends StatelessWidget {
  const EyeConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EyeConnect',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainScreen(),
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
      _showOnboarding = !seenOnboarding;
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
            future: AuthService().getUserDetails(),
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
                  return const LoginScreen();
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
