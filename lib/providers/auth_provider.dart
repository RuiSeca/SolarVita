// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isNotifying = false;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isEmailVerified => _authService.isEmailVerified;

  AuthProvider() {
    // Listen to auth state changes
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      _notifySafely();
    });
  }

  // Sign up with email and password
  Future<bool> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return _executeAuthOperation(() async {
      await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      return true;
    });
  }

  // Sign in with email and password
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return _executeAuthOperation(() async {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    });
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    return _executeAuthOperation(() async {
      final result = await _authService.signInWithGoogle();
      return result != null;
    });
  }

  // Sign in with Facebook
  Future<bool> signInWithFacebook() async {
    return _executeAuthOperation(() async {
      final result = await _authService.signInWithFacebook();
      return result != null;
    });
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    return _executeAuthOperation(() async {
      await _authService.sendPasswordResetEmail(email);
      return true;
    });
  }

  // Sign out
  Future<void> signOut() async {
    await _executeAuthOperation(() async {
      await _authService.signOut();
      return true;
    });
  }

  // Send email verification
  Future<bool> sendEmailVerification() async {
    return _executeAuthOperation(() async {
      await _authService.sendEmailVerification();
      return true;
    });
  }

  // Reload current user
  Future<void> reloadUser() async {
    await _authService.reloadCurrentUser();
    _user = _authService.currentUser;
    _notifySafely();
  }

  // Helper method to execute auth operations with loading state
  Future<bool> _executeAuthOperation(Future<bool> Function() operation) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await operation();
      return result;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    _notifySafely();
  }

  // Set error message
  void _setError(String error) {
    _errorMessage = error;
    _notifySafely();
  }

  // Clear error message
  void _clearError() {
    _errorMessage = null;
  }

  // Safe notification to prevent errors
  void _notifySafely() {
    if (_isNotifying) return;

    _isNotifying = true;
    try {
      notifyListeners();
    } catch (e) {
      // Handle notification errors silently
    } finally {
      _isNotifying = false;
    }
  }
}
