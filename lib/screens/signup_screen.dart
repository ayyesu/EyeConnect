import 'package:flutter/material.dart';
import 'package:myapp/screens/visually_impaired_screen.dart';
import 'package:myapp/screens/volunteer_screen.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:permission_handler/permission_handler.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  SignupScreenState createState() => SignupScreenState();
}

class SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _errorMessage;
  String? _selectedRole; // Either 'Volunteer' or 'Visually Impaired'
  bool cameraGranted = false;
  bool microphoneGranted = false;

  final AuthService _authService = AuthService(); // Initialize AuthService

  @override
  void initState() {
    super.initState();
    _checkInitialPermissions();
  }

  Future<void> _checkInitialPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final microphoneStatus = await Permission.microphone.status;

    setState(() {
      cameraGranted = cameraStatus.isGranted;
      microphoneGranted = microphoneStatus.isGranted;
    });
  }

  Future<void> _requestPermissions() async {
    if (!cameraGranted) {
      final cameraStatus = await Permission.camera.request();
      setState(() => cameraGranted = cameraStatus.isGranted);
    }
    if (!microphoneGranted) {
      final microphoneStatus = await Permission.microphone.request();
      setState(() => microphoneGranted = microphoneStatus.isGranted);
    }

    if (!cameraGranted || !microphoneGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please grant camera and microphone permissions to proceed.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _signUp() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String name = _nameController.text.trim();
    String username = _usernameController.text.trim();
    String phone = _phoneController.text.trim();

    setState(() {
      _errorMessage = null;
    });

    // Request permissions before proceeding with signup
    await _requestPermissions();

    // Proceed only if permissions are granted
    if (cameraGranted && microphoneGranted) {
      if (_selectedRole == null) {
        setState(() {
          _errorMessage =
              'Please select a role (Volunteer or Visually Impaired).';
        });
        return;
      }

      try {
        // Sign up and store the role
        await _authService.signUpWithEmail(
            email, password, name, username, phone, _selectedRole!);

        // Fetch user role and navigate
        final userDetails = await _authService.getUserDetails();
        final role = userDetails['role'];

        if (!mounted) return;
        if (role == 'Volunteer') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const VolunteerScreen()),
          );
        } else if (role == 'Visually Impaired') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const VisuallyImpairedScreen()),
          );
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sign Up',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
              keyboardType: TextInputType.name,
            ),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
              keyboardType: TextInputType.text,
            ),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            const Text('Select Your Role:'),
            ListTile(
              title: const Text('Volunteer'),
              leading: Radio<String>(
                value: 'Volunteer',
                groupValue: _selectedRole,
                onChanged: (value) {
                  setState(() => _selectedRole = value);
                },
              ),
            ),
            ListTile(
              title: const Text('Visually Impaired'),
              leading: Radio<String>(
                value: 'Visually Impaired',
                groupValue: _selectedRole,
                onChanged: (value) {
                  setState(() => _selectedRole = value);
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _signUp,
              child: const Text('Sign Up'),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
