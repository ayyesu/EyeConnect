import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Convert Firebase User to UserModel
  UserModel? _userFromFirebase(User? user) {
    if (user == null) return null;
    return UserModel(
      id: user.uid,
      name: user.displayName ?? 'Anonymous',
      email: user.email ?? '',
      role: 'unknown', // Default role, update after registration if needed
    );
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _userFromFirebase(result.user);
    } on FirebaseAuthException catch (e) {
      // Handle specific FirebaseAuth exceptions
      switch (e.code) {
        case 'user-not-found':
          throw Exception('User not found.');
        case 'wrong-password':
          throw Exception('Wrong password provided.');
        case 'user-disabled':
          throw Exception('User account is disabled.');
        case 'too-many-requests':
          throw Exception('Too many requests. Please try again later.');
        default:
          throw Exception('An unexpected error occurred.');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred.');
    }
  }

  // Sign up with email and password
  Future<UserModel?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _userFromFirebase(result.user);
    } on FirebaseAuthException catch (e) {
      // Handle specific FirebaseAuth exceptions
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception('The email is already in use by another account.');
        case 'invalid-email':
          throw Exception('The email address is not valid.');
        case 'weak-password':
          throw Exception('The password is too weak.');
        default:
          throw Exception('An unexpected error occurred.');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred.');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out.');
    }
  }
}
