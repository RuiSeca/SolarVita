// lib/services/auth_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger('AuthService');
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    signInOption: SignInOption.standard,
  );
  static const Duration _signInTimeout = Duration(seconds: 30);
  
  // Helper method to handle App Check related errors
  bool _isAppCheckError(String errorMessage) {
    return errorMessage.toLowerCase().contains('app check') ||
           errorMessage.toLowerCase().contains('too many attempts') ||
           errorMessage.toLowerCase().contains('recaptcha');
  }

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
      final result = await _auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(_signInTimeout);

      if (displayName != null && result.user != null) {
        await result.user!.updateDisplayName(displayName);
        await result.user!.reload();
      }

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } on TimeoutException {
      throw Exception(
          'Sign up timed out. Check your connection and try again.');
    } catch (e) {
      final errorMessage = e.toString();
      if (_isAppCheckError(errorMessage)) {
        throw Exception('Security verification failed. Please wait a few minutes and try again, or restart the app.');
      }
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // Email signin
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(_signInTimeout);

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } on TimeoutException {
      throw Exception(
          'Sign in timed out. Check your connection and try again.');
    } catch (e) {
      final errorMessage = e.toString();
      if (_isAppCheckError(errorMessage)) {
        throw Exception('Security verification failed. Please wait a few minutes and try again, or restart the app.');
      }
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // Google signin
  Future<UserCredential?> signInWithGoogle() async {
    GoogleSignInAccount? googleUser;
    try {
      await _googleSignIn.signOut();
      await Future.delayed(const Duration(milliseconds: 500));

      googleUser = await _googleSignIn.signIn().timeout(
        _signInTimeout,
        onTimeout: () {
          throw TimeoutException('Google sign in timed out', _signInTimeout);
        },
      );

      if (googleUser == null) {
        return null;
      }

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

      return result;
    } on FirebaseAuthException catch (e) {
      await _cleanupGoogleSignIn();
      throw _handleAuthException(e);
    } on TimeoutException {
      await _cleanupGoogleSignIn();
      throw Exception('Google sign-in timed out. Please try again.');
    } catch (e) {
      await _cleanupGoogleSignIn();

      final msg = e.toString();
      if (msg.contains('PigeonUserDetails') || msg.contains('List<Object?>')) {
        throw Exception('Google Sign-In plugin error. Please restart the app.');
      }
      if (msg.contains('network')) {
        throw Exception(
            'Network error during Google sign-in. Please check your connection.');
      }
      if (msg.contains('cancelled') || msg.contains('canceled')) {
        return null;
      }
      throw Exception('Google sign-in failed. Please try again.');
    }
  }

  Future<void> _cleanupGoogleSignIn() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  // Apple signin (iOS only)
  Future<UserCredential?> signInWithApple() async {
    if (!Platform.isIOS) {
      throw Exception('Apple Sign-In is only available on iOS');
    }

    try {
      // Check if Apple Sign-In is available
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw Exception('Apple Sign-In is not available on this device');
      }

      // Generate a random nonce for security
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Request Apple Sign-In
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      ).timeout(
        _signInTimeout,
        onTimeout: () => throw TimeoutException(
            'Apple sign in timed out', _signInTimeout),
      );

      // Create Firebase credential
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      // Sign in to Firebase
      final result = await _auth.signInWithCredential(oauthCredential).timeout(
            _signInTimeout,
            onTimeout: () => throw TimeoutException(
                'Firebase credential sign in timed out', _signInTimeout),
          );

      // Update display name if provided and not already set
      if (result.user != null && 
          result.user!.displayName == null && 
          appleCredential.givenName != null) {
        final displayName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
        if (displayName.isNotEmpty) {
          await result.user!.updateDisplayName(displayName);
          await result.user!.reload();
        }
      }

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return null; // User canceled
      }
      throw Exception('Apple Sign-In failed: ${e.code}');
    } on TimeoutException {
      throw Exception('Apple sign-in timed out. Please try again.');
    } catch (e) {
      if (e.toString().contains('cancelled') ||
          e.toString().contains('canceled')) {
        return null;
      }
      throw Exception('Apple sign-in failed. Please try again.');
    }
  }

  // Generate a cryptographically secure random nonce
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  // Generate SHA256 hash of input string
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Password reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email).timeout(
            _signInTimeout,
            onTimeout: () => throw TimeoutException(
                'Password reset email timeout', _signInTimeout),
          );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } catch (e) {
      throw Exception('Failed to send password reset email. Please try again.');
    }
  }

  // Sign out (fixed)
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      // Ignore sign out errors
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete().timeout(
              _signInTimeout,
              onTimeout: () => throw TimeoutException(
                  'Account deletion timeout', _signInTimeout),
            );
        await _cleanupGoogleSignIn();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } on TimeoutException {
      throw Exception('Account deletion timed out. Please try again.');
    } catch (e) {
      throw Exception('Failed to delete account. Please try again.');
    }
  }

  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return Exception('Password is too weak. Please use at least 6 characters with a mix of letters and numbers.');
      case 'email-already-in-use':
        return Exception('An account with this email already exists. Try signing in instead.');
      case 'user-not-found':
        return Exception('No account found with this email address. Please check your email or create a new account.');
      case 'wrong-password':
        return Exception('Incorrect password. Please try again or use "Forgot Password" to reset it.');
      case 'invalid-email':
        return Exception('Please enter a valid email address.');
      case 'user-disabled':
        return Exception('This account has been temporarily disabled. Please contact support.');
      case 'too-many-requests':
        return Exception('Too many failed attempts. Please wait a few minutes before trying again.');
      case 'operation-not-allowed':
        return Exception('Email/password sign-in is currently disabled. Please try a different method.');
      case 'requires-recent-login':
        return Exception('For security reasons, please sign in again to continue.');
      case 'invalid-credential':
        return Exception('Your login credentials are invalid or have expired. Please try signing in again.');
      case 'account-exists-with-different-credential':
        return Exception('An account with this email exists but uses a different sign-in method (Google/Apple). Try signing in with that method.');
      case 'network-request-failed':
        return Exception('Network connection failed. Please check your internet and try again.');
      case 'invalid-action-code':
        return Exception('The action code is invalid. This may happen if the code is malformed or expired.');
      case 'expired-action-code':
        return Exception('The action code has expired. Please request a new one.');
      case 'missing-android-pkg-name':
        return Exception('An Android package name must be provided.');
      case 'missing-continue-uri':
        return Exception('A continue URL must be provided in the request.');
      case 'missing-ios-bundle-id':
        return Exception('An iOS bundle ID must be provided.');
      case 'unauthorized-continue-uri':
        return Exception('The continue URL provided is not authorized.');
      case 'invalid-continue-uri':
        return Exception('The continue URL provided is invalid.');
      case 'quota-exceeded':
        return Exception('SMS quota exceeded. Please try again later.');
      case 'credential-already-in-use':
        return Exception('This credential is already associated with a different user account.');
      case 'custom-token-mismatch':
        return Exception('The custom token corresponds to a different audience.');
      case 'invalid-custom-token':
        return Exception('The custom token format is incorrect.');
      case 'invalid-user-token':
        return Exception('The user\'s credential is no longer valid. Please sign in again.');
      case 'user-token-expired':
        return Exception('Your session has expired. Please sign in again.');
      case 'null-user':
        return Exception('User session is invalid. Please sign in again.');
      case 'app-deleted':
        return Exception('This Firebase app instance has been deleted.');
      case 'captcha-check-failed':
        return Exception('reCAPTCHA verification failed. Please try again.');
      case 'invalid-app-credential':
        return Exception('Invalid app credential. Please contact support.');
      case 'app-not-authorized':
        return Exception('This app is not authorized to use Firebase Authentication.');
      case 'keychain-error':
        return Exception('Keychain access error. Please try again.');
      case 'internal-error':
        return Exception('An internal error occurred. Please try again later.');
      case 'invalid-api-key':
        return Exception('Invalid API key. Please contact support.');
      case 'web-storage-unsupported':
        return Exception('Web storage is not supported on this device.');
      default:
        // Log the unknown error for debugging
        _logger.warning('Unknown Firebase Auth error: ${e.code} - ${e.message}');
        return Exception('Sign-in failed. Please check your credentials and try again.');
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
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } catch (e) {
      throw Exception('Failed to send verification email.');
    }
  }

  Future<void> reloadCurrentUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      // Ignore reload errors
    }
  }

  bool get isSignedIn => _auth.currentUser != null;
  String? get userDisplayName => _auth.currentUser?.displayName;
  String? get userEmail => _auth.currentUser?.email;
  String? get userPhotoURL => _auth.currentUser?.photoURL;

  /// Deletes user data from Firestore when account is incomplete or deleted
  Future<void> deleteUserData(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;

      _logger.info('Starting user data cleanup for uid: $uid');

      // Delete supporter requests (both sent and received)
      final supporterRequestsQuery1 = await firestore
          .collection('supporterRequests')
          .where('requesterId', isEqualTo: uid)
          .get();

      final supporterRequestsQuery2 = await firestore
          .collection('supporterRequests')
          .where('receiverId', isEqualTo: uid)
          .get();

      // Delete all supporter requests
      final batch = firestore.batch();
      for (final doc in [...supporterRequestsQuery1.docs, ...supporterRequestsQuery2.docs]) {
        batch.delete(doc.reference);
      }

      // Delete user profile data
      batch.delete(firestore.collection('users').doc(uid));
      batch.delete(firestore.collection('user_profiles').doc(uid));

      // Delete any activities by this user
      final activitiesQuery = await firestore
          .collection('activities')
          .where('userId', isEqualTo: uid)
          .get();

      for (final doc in activitiesQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete any chat messages
      final chatMessagesQuery1 = await firestore
          .collection('chatMessages')
          .where('senderId', isEqualTo: uid)
          .get();

      final chatMessagesQuery2 = await firestore
          .collection('chatMessages')
          .where('receiverId', isEqualTo: uid)
          .get();

      for (final doc in [...chatMessagesQuery1.docs, ...chatMessagesQuery2.docs]) {
        batch.delete(doc.reference);
      }

      // Commit all deletions
      await batch.commit();

      _logger.info('User data cleanup completed for uid: $uid');
    } catch (e) {
      _logger.warning('Failed to delete user data for uid: $uid, error: $e');
      // Don't throw error - account deletion should still proceed
    }
  }
}
