import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const BeMyEyesApp());
}

class BeMyEyesApp extends StatelessWidget {
  const BeMyEyesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Be My Eyes Clone',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginScreen(),
    );
  }
}
