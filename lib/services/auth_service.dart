// lib/services/auth_service.dart

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:logging/logging.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    signInOption: SignInOption.standard,
  );
  final Logger _logger = Logger('AuthService');
  static const Duration _signInTimeout = Duration(seconds: 30);

  // Current user info
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Email signup
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      _logger.info('Starting email sign up for: $email');
      final result = await _auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(_signInTimeout);

      if (displayName != null && result.user != null) {
        await result.user!.updateDisplayName(displayName);
        await result.user!.reload();
      }

      _logger.info('User signed up successfully: ${result.user?.email}');
      return result;
    } on FirebaseAuthException catch (e) {
      _logger.severe('Sign up failed: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } on TimeoutException catch (e) {
      _logger.severe('Sign up timeout: $e');
      throw Exception(
          'Sign up timed out. Check your connection and try again.');
    } catch (e) {
      _logger.severe('Unexpected sign up error: $e');
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // Email signin
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _logger.info('Starting email sign in for: $email');
      final result = await _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(_signInTimeout);

      _logger.info('User signed in successfully: ${result.user?.email}');
      return result;
    } on FirebaseAuthException catch (e) {
      _logger.severe('Sign in failed: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } on TimeoutException catch (e) {
      _logger.severe('Sign in timeout: $e');
      throw Exception(
          'Sign in timed out. Check your connection and try again.');
    } catch (e) {
      _logger.severe('Unexpected sign in error: $e');
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // Google signin
  Future<UserCredential?> signInWithGoogle() async {
    GoogleSignInAccount? googleUser;
    try {
      _logger.info('Starting Google sign in');
      await _googleSignIn.signOut();
      await Future.delayed(const Duration(milliseconds: 500));

      googleUser = await _googleSignIn.signIn().timeout(
        _signInTimeout,
        onTimeout: () {
          _logger.severe('Google sign in timed out');
          throw TimeoutException('Google sign in timed out', _signInTimeout);
        },
      );

      if (googleUser == null) {
        _logger.info('Google sign in aborted by user');
        return null;
      }

      _logger.info('Google user obtained: ${googleUser.email}');
      final auth = await googleUser.authentication;
      if (auth.accessToken == null || auth.idToken == null) {
        throw Exception('Missing Google authentication tokens');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      final result = await _auth.signInWithCredential(credential).timeout(
            _signInTimeout,
            onTimeout: () => throw TimeoutException(
                'Firebase credential sign in timed out', _signInTimeout),
          );

      _logger.info('Google sign in successful: ${result.user?.email}');
      return result;
    } on FirebaseAuthException catch (e) {
      _logger.severe(
          'Firebase auth error during Google sign in: ${e.code} - ${e.message}');
      await _cleanupGoogleSignIn();
      throw _handleAuthException(e);
    } on TimeoutException catch (e) {
      _logger.severe('Google sign in timeout: $e');
      await _cleanupGoogleSignIn();
      throw Exception('Google sign-in timed out. Please try again.');
    } catch (e) {
      _logger.severe('Unexpected Google sign in error: $e');
      await _cleanupGoogleSignIn();

      final msg = e.toString();
      if (msg.contains('PigeonUserDetails') || msg.contains('List<Object?>')) {
        _logger.severe('Plugin compatibility issue detected');
        throw Exception('Google Sign-In plugin error. Please restart the app.');
      }
      if (msg.contains('network')) {
        throw Exception(
            'Network error during Google sign-in. Please check your connection.');
      }
      if (msg.contains('cancelled') || msg.contains('canceled')) {
        _logger.info('Google sign in cancelled by user');
        return null;
      }
      throw Exception('Google sign-in failed. Please try again.');
    }
  }

  Future<void> _cleanupGoogleSignIn() async {
    try {
      await _googleSignIn.signOut();
      _logger.info('Google sign-in state cleaned up');
    } catch (e) {
      _logger.warning('Failed to cleanup Google sign-in: $e');
    }
  }

  // Facebook signin
  Future<UserCredential?> signInWithFacebook() async {
    try {
      _logger.info('Starting Facebook sign in');
      await FacebookAuth.instance.logOut();

      final loginResult = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      ).timeout(
        _signInTimeout,
        onTimeout: () => throw TimeoutException(
            'Facebook sign in timed out', _signInTimeout),
      );

      if (loginResult.status == LoginStatus.cancelled) {
        _logger.info('Facebook sign in cancelled by user');
        return null;
      }

      if (loginResult.status != LoginStatus.success ||
          loginResult.accessToken == null) {
        throw Exception('Facebook sign-in failed: ${loginResult.status}');
      }

      final credential =
          FacebookAuthProvider.credential(loginResult.accessToken!.token);
      final result = await _auth.signInWithCredential(credential).timeout(
            _signInTimeout,
            onTimeout: () => throw TimeoutException(
                'Firebase credential sign in timed out', _signInTimeout),
          );

      _logger.info('Facebook sign in successful: ${result.user?.email}');
      return result;
    } on FirebaseAuthException catch (e) {
      _logger.severe(
          'Firebase auth error during Facebook sign in: ${e.code} - ${e.message}');
      await FacebookAuth.instance.logOut();
      throw _handleAuthException(e);
    } on TimeoutException catch (e) {
      _logger.severe('Facebook sign in timeout: $e');
      await FacebookAuth.instance.logOut();
      throw Exception('Facebook sign-in timed out. Please try again.');
    } catch (e) {
      _logger.severe('Unexpected Facebook sign in error: $e');
      await FacebookAuth.instance.logOut();

      if (e.toString().contains('cancelled') ||
          e.toString().contains('canceled')) {
        _logger.info('Facebook sign in cancelled by user');
        return null;
      }
      throw Exception('Facebook sign-in failed. Please try again.');
    }
  }

  // Password reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      _logger.info('Sending password reset email to: $email');
      await _auth.sendPasswordResetEmail(email: email).timeout(
            _signInTimeout,
            onTimeout: () => throw TimeoutException(
                'Password reset email timeout', _signInTimeout),
          );
      _logger.info('Password reset email sent successfully');
    } on FirebaseAuthException catch (e) {
      _logger.severe('Password reset failed: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } on TimeoutException catch (e) {
      _logger.severe('Password reset timeout: $e');
      throw Exception('Request timed out. Please try again.');
    } catch (e) {
      _logger.severe('Unexpected password reset error: $e');
      throw Exception('Failed to send password reset email. Please try again.');
    }
  }

  // Sign out (fixed)
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
        FacebookAuth.instance.logOut(),
      ]);
      _logger.info('User signed out successfully from all services');
    } catch (e) {
      _logger.severe('Error during sign out: $e');
      _logger.warning(
          'Sign out completed with errors, but user should be signed out');
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        _logger.info('Deleting user account: ${user.email}');
        await user.delete().timeout(
              _signInTimeout,
              onTimeout: () => throw TimeoutException(
                  'Account deletion timeout', _signInTimeout),
            );
        _logger.info('User account deleted successfully');
        await _cleanupGoogleSignIn();
        await FacebookAuth.instance.logOut();
      }
    } on FirebaseAuthException catch (e) {
      _logger.severe('Account deletion failed: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } on TimeoutException catch (e) {
      _logger.severe('Account deletion timeout: $e');
      throw Exception('Account deletion timed out. Please try again.');
    } catch (e) {
      _logger.severe('Unexpected account deletion error: $e');
      throw Exception('Failed to delete account. Please try again.');
    }
  }

  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return Exception('The password provided is too weak.');
      case 'email-already-in-use':
        return Exception('An account already exists for that email.');
      case 'user-not-found':
        return Exception('No user found for that email.');
      case 'wrong-password':
        return Exception('Wrong password provided.');
      case 'invalid-email':
        return Exception('The email address is not valid.');
      case 'user-disabled':
        return Exception('This account has been disabled.');
      case 'too-many-requests':
        return Exception('Too many requests. Try again later.');
      case 'operation-not-allowed':
        return Exception('This sign-in method is not allowed.');
      case 'requires-recent-login':
        return Exception('Please sign in again to continue.');
      case 'invalid-credential':
        return Exception('The credential is malformed or has expired.');
      case 'account-exists-with-different-credential':
        return Exception(
            'An account already exists with a different sign-in method.');
      case 'network-request-failed':
        return Exception(
            'Network error. Please check your connection and try again.');
      default:
        return Exception(
            'Authentication failed: ${e.message ?? 'Unknown error'}');
    }
  }

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user is currently signed in');
    try {
      await user.sendEmailVerification().timeout(
            _signInTimeout,
            onTimeout: () => throw TimeoutException(
                'Email verification timeout', _signInTimeout),
          );
      _logger.info('Email verification sent to: ${user.email}');
    } on FirebaseAuthException catch (e) {
      _logger.severe(
          'Failed to send verification email: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } on TimeoutException catch (e) {
      _logger.severe('Email verification timeout: $e');
      throw Exception('Request timed out. Please try again.');
    } catch (e) {
      _logger.severe('Unexpected error sending verification email: $e');
      throw Exception('Failed to send verification email.');
    }
  }

  Future<void> reloadCurrentUser() async {
    try {
      await _auth.currentUser?.reload();
      _logger.info('User data reloaded successfully');
    } catch (e) {
      _logger.warning('Failed to reload user: $e');
    }
  }

  bool get isSignedIn => _auth.currentUser != null;
  String? get userDisplayName => _auth.currentUser?.displayName;
  String? get userEmail => _auth.currentUser?.email;
  String? get userPhotoURL => _auth.currentUser?.photoURL;
}
