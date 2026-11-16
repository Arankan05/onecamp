
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/auth_state.dart';
import '../repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthState _state = AuthState.initial();

  AuthController({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  AuthState get state => _state;

  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  String _getErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'network-request-failed':
        return 'Please check your internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setState(AuthState.loading());

    try {
      await _authRepository.registerStudent(
        name: name,
        email: email,
        password: password,
      );

      _setState(AuthState.success());
      return true;
    } on FirebaseAuthException catch (error) {
      _setState(AuthState.error(_getErrorMessage(error)));
      return false;
    } catch (_) {
      _setState(
        AuthState.error('Registration failed. Please try again.'),
      );
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setState(AuthState.loading());

    try {
      await _authRepository.login(
        email: email,
        password: password,
      );

      _setState(AuthState.success());
      return true;
    } on FirebaseAuthException catch (error) {
      _setState(AuthState.error(_getErrorMessage(error)));
      return false;
    } catch (_) {
      _setState(
        AuthState.error('Login failed. Please try again.'),
      );
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _authRepository.logout();
      _setState(AuthState.initial());
    } catch (_) {
      _setState(AuthState.error('Logout failed. Please try again.'));
    }
  }

  Future<bool> resetPassword({
    required String email,
  }) async {
    _setState(AuthState.loading());

    try {
      await _authRepository.resetPassword(email: email);
      _setState(AuthState.success());
      return true;
    } on FirebaseAuthException catch (error) {
      _setState(AuthState.error(_getErrorMessage(error)));
      return false;
    } catch (_) {
      _setState(
        AuthState.error('Password reset failed. Please try again.'),
      );
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    return await _authRepository.getUserProfile(uid);
  }
}
