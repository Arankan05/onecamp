import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_constants.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _authService;
  final FirebaseFirestore _firestore;

  AuthRepository({AuthService? authService, FirebaseFirestore? firestore})
    : _authService = authService ?? AuthService(),
      _firestore = firestore ?? FirebaseFirestore.instance;

  // Register a student and create their Firestore profile
  Future<UserCredential> registerStudent({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _authService.register(
      email: email,
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw Exception('User registration failed.');
    }

    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set({
            'uid': user.uid,
            'name': name.trim(),
            'email': email.trim(),
            'role': 'student',
            'onboardingCompleted': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (error) {
      // Remove the newly created account if profile creation fails.
      try {
        await user.delete();
      } catch (_) {
        // Preserve the original Firestore error.
      }

      rethrow;
    }

    return credential;
  }

  // Login an existing user
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _authService.login(email: email, password: password);
  }

  // Logout the current user
  Future<void> logout() async {
    await _authService.logout();
  }

  // Send password reset email
  Future<void> resetPassword({required String email}) async {
    await _authService.resetPassword(email: email);
  }

  // Retrieve a user's Firestore profile
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final document = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();

    if (!document.exists) {
      return null;
    }

    return document.data();
  }
}
