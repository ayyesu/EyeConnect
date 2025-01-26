import 'package:eyeconnect/services/stats_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyeconnect/services/notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign Up Method
  Future<void> signUpWithEmail(
    String email,
    String password,
    String name,
    String username,
    String phone,
    String role,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store additional user data in Firestore
      final userId = result.user!.uid;
      await _firestore.collection('users').doc(userId).set({
        'name': name,
        'username': username,
        'phone': phone,
        'role': role,
        'email': email,
      });

      // Initialize stats for new volunteer
      if (role == 'Volunteer') {
        final statsService = StatsService();
        await statsService.initializeVolunteerStats(userId);
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Sign In Method
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password must not be empty.');
      }
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Add this after successful sign-in
      final notificationService = NotificationService();
      await notificationService.initializeNotifications();
    } on FirebaseAuthException catch (e) {
      // Handle Firebase-specific errors
      if (e.code == 'user-not-found') {
        throw Exception('No user found with this email.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Incorrect password. Please try again.');
      } else if (e.code == 'invalid-email') {
        throw Exception('The email address is not valid.');
      } else if (e.code == 'user-disabled') {
        throw Exception('This user account has been disabled.');
      } else {
        throw Exception('${e.message}');
      }
    } catch (e) {
      // Handle general errors
      throw Exception(
          'Failed to sign in, ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  // Function to get role and username
  Future<Map<String, String?>> getUserDetails() async {
    final user = _auth.currentUser;

    if (user != null) {
      try {
        // Fetch user details from Firestore
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data();
          final role = data?['role'] as String?;
          final username = data?['username'] as String?;
          return {'role': role, 'username': username};
        } else {
          throw Exception('User details not found.');
        }
      } catch (e) {
        throw Exception('Failed to fetch user details: ${e.toString()}');
      }
    } else {
      throw Exception('No user is currently signed in.');
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Sign Out Method
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }
}
