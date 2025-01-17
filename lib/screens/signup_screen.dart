import 'package:flutter/material.dart';
import 'package:eyeconnect/screens/visually_impaired_screen.dart';
import 'package:eyeconnect/screens/volunteer_screen.dart';
import 'package:eyeconnect/services/auth_service.dart';
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
  String? _selectedRole;
  bool cameraGranted = false;
  bool microphoneGranted = false;
  int _currentStep = 0;
  final PageController _pageController = PageController();

  final AuthService _authService = AuthService();

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
    await _requestPermissions();

    if (cameraGranted && microphoneGranted) {
      try {
        await _authService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
          _usernameController.text.trim(),
          _phoneController.text.trim(),
          _selectedRole!,
        );

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

  bool _validateStep(int step) {
    setState(() => _errorMessage = null);

    switch (step) {
      case 0:
        if (_nameController.text.isEmpty || _usernameController.text.isEmpty) {
          setState(() => _errorMessage = 'Please fill in all fields');
          return false;
        }
        return true;
      case 1:
        if (_phoneController.text.isEmpty || _emailController.text.isEmpty) {
          setState(() => _errorMessage = 'Please fill in all fields');
          return false;
        }
        return true;
      case 2:
        if (_passwordController.text.isEmpty) {
          setState(() => _errorMessage = 'Please enter a password');
          return false;
        }
        return true;
      case 3:
        if (_selectedRole == null) {
          setState(() => _errorMessage = 'Please select a role');
          return false;
        }
        return true;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_validateStep(_currentStep)) {
      if (_currentStep < 3) {
        setState(() => _currentStep++);
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _signUp();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentStep >= index ? Colors.blue : Colors.grey,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Basic Information',
              style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.name,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildContactStep() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Contact Details',
              style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 24,
                  fontWeight: FontWeight.bold
                ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordStep() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create Password',
              style: TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleStep() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select Role',
              style: TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 24, 
                fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 20),
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
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
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
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildBasicInfoStep(),
                _buildContactStep(),
                _buildPasswordStep(),
                _buildRoleStep(),
              ],
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  ElevatedButton(
                    onPressed: _previousStep,
                    child: const Text('Previous'),
                  )
                else
                  const SizedBox.shrink(),
                ElevatedButton(
                  onPressed: _nextStep,
                  child: Text(_currentStep < 3 ? 'Next' : 'Submit'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
