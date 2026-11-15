
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;

  AuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  // Get the currently logged-in user
  User? get currentUser => _firebaseAuth.currentUser;

  // Listen to authentication state changes
  Stream<User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  // Register a new user
  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Login an existing user
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Logout the current user
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  // Send password reset email
  Future<void> resetPassword({
    required String email,
  }) async {
    await _firebaseAuth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }
}
