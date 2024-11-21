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
    } catch (e) {
      print('Sign in error: $e');
      return null;
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
    } catch (e) {
      print('Sign up error: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
    }
  }
}
