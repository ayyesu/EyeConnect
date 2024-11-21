import 'package:flutter/material.dart';
import 'role_selection_screen.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                AuthService authService = AuthService();
                var user = await authService.signUpWithEmail(
                  emailController.text,
                  passwordController.text,
                );
                if (user != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                  );
                }
              },
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
