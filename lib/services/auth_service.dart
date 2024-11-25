import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      await _firestore.collection('users').doc(result.user!.uid).set({
        'name': name,
        'username': username,
        'phone': phone,
        'role': role,
        'email': email,
      });
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Sign In Method
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      throw Exception('Failed to sign in: ${e.toString()}');
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
          throw Exception('User document not found in Firestore.');
        }
      } catch (e) {
        throw Exception('Failed to fetch user details: ${e.toString()}');
      }
    } else {
      throw Exception('No user is currently signed in.');
    }
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
