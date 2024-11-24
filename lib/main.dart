import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:myapp/providers/help_request_provider.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';

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
      home: const LoginScreen(),
    );
  }
}
