import 'package:flutter/material.dart';
import 'package:myapp/screens/visually_impaired_screen.dart' as visually_impaired_screen;
import 'package:myapp/screens/volunteer_screen.dart' as volunteer_screen;
import '../services/auth_service.dart';
import './signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;

  Future<void> _signIn(String email, String password) async {
    try {
      // Login
      await _authService.signInWithEmailAndPassword(email, password);

      // Fetch role and navigate
      final userDetails = await _authService.getUserDetails();
      final role = userDetails['role'];
      if (!mounted) return;
      if (role == 'Volunteer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const volunteer_screen.VolunteerScreen()),
        );
      } else if (role == 'Visually Impaired') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const visually_impaired_screen.VolunteerScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Login',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Call _signIn with the required arguments
                _signIn(
                  _emailController.text.trim(),
                  _passwordController.text.trim(),
                );
              },
              child: const Text('Sign In'),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SignupScreen(),
                  ),
                );
              },
              child: const Text('Don’t have an account? Sign up here!'),
            ),
          ],
        ),
      ),
    );
  }
}
