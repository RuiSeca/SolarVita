import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

final log = Logger('FirebaseInitializationService');

/// Service to handle Firebase initialization and configuration
class FirebaseInitializationService {
  static bool _isInitialized = false;
  static bool _isInitializing = false;

  /// Check if Firebase has been initialized
  static bool get isInitialized => _isInitialized;

  /// Initialize Firebase with all required services
  static Future<void> initialize() async {
    if (_isInitialized || _isInitializing) {
      log.info('🔥 Firebase already initialized or initializing');
      return;
    }

    _isInitializing = true;

    try {
      log.info('🚀 Starting Firebase initialization...');

      // Initialize Firebase Core
      await Firebase.initializeApp(
        options: _getFirebaseOptions(),
      );
      log.info('✅ Firebase Core initialized');

      // Initialize Firebase App Check for security
      await _initializeAppCheck();
      
      // Configure Firestore settings
      await _configureFirestore();
      
      // Configure Firebase Auth
      await _configureFirebaseAuth();
      
      _isInitialized = true;
      log.info('🎉 Firebase initialization completed successfully');

    } catch (e, stackTrace) {
      log.severe('❌ Firebase initialization failed: $e', e, stackTrace);
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// Initialize Firebase App Check for security
  static Future<void> _initializeAppCheck() async {
    try {
      log.info('🔐 Initializing Firebase App Check...');
      
      await FirebaseAppCheck.instance.activate(
        // Use debug provider for development, reCAPTCHA for web
        webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
        androidProvider: kDebugMode
            ? AndroidProvider.debug
            : AndroidProvider.playIntegrity,
        appleProvider: kDebugMode
            ? AppleProvider.debug
            : AppleProvider.appAttest,
      );
      
      log.info('✅ Firebase App Check initialized');
    } catch (e) {
      log.warning('⚠️ Firebase App Check initialization failed: $e');
      // Don't throw - App Check is not critical for basic functionality
    }
  }

  /// Configure Firestore settings
  static Future<void> _configureFirestore() async {
    try {
      log.info('📊 Configuring Firestore...');
      
      final firestore = FirebaseFirestore.instance;
      
      // Configure Firestore settings
      final settings = const Settings(
        persistenceEnabled: true, // Enable offline persistence
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      
      firestore.settings = settings;
      
      // Enable network for Firestore
      await firestore.enableNetwork();
      
      log.info('✅ Firestore configured with offline persistence');
    } catch (e) {
      log.warning('⚠️ Firestore configuration failed: $e');
      // Continue initialization even if Firestore config fails
    }
  }

  /// Configure Firebase Auth
  static Future<void> _configureFirebaseAuth() async {
    try {
      log.info('🔐 Configuring Firebase Auth...');
      
      final auth = FirebaseAuth.instance;
      
      // Set auth persistence
      await auth.setPersistence(Persistence.LOCAL);
      
      // Configure additional auth settings if needed
      await auth.setSettings(
        appVerificationDisabledForTesting: kDebugMode,
      );
      
      log.info('✅ Firebase Auth configured');
    } catch (e) {
      log.warning('⚠️ Firebase Auth configuration failed: $e');
      // Continue initialization even if Auth config fails
    }
  }

  /// Get Firebase options - use the existing firebase_options.dart configuration
  static FirebaseOptions? _getFirebaseOptions() {
    // Return null to use default configuration from firebase_options.dart
    // which is already properly configured for this project
    return null;
  }

  /// Test Firebase connection
  static Future<bool> testConnection() async {
    try {
      log.info('🧪 Testing Firebase connection...');
      
      // Test Firestore connection
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('test').limit(1).get();
      
      // Test Auth connection
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;
      
      log.info('✅ Firebase connection test successful');
      log.info('👤 Current user: ${currentUser?.uid ?? 'Not signed in'}');
      
      return true;
    } catch (e) {
      log.severe('❌ Firebase connection test failed: $e');
      return false;
    }
  }

  /// Sign in user anonymously for avatar system access
  static Future<User?> signInAnonymously() async {
    try {
      log.info('👤 Signing in user anonymously...');
      
      final auth = FirebaseAuth.instance;
      
      // Check if user is already signed in
      if (auth.currentUser != null) {
        log.info('✅ User already signed in: ${auth.currentUser!.uid}');
        return auth.currentUser;
      }
      
      // Sign in anonymously
      final userCredential = await auth.signInAnonymously();
      final user = userCredential.user;
      
      if (user != null) {
        log.info('✅ Anonymous sign-in successful: ${user.uid}');
        return user;
      } else {
        throw Exception('Failed to sign in anonymously');
      }
    } catch (e) {
      log.severe('❌ Anonymous sign-in failed: $e');
      rethrow;
    }
  }

  /// Initialize Firebase and ensure user is signed in
  static Future<User?> initializeAndSignIn() async {
    // Initialize Firebase first
    await initialize();
    
    // Test connection
    final connectionOk = await testConnection();
    if (!connectionOk) {
      throw Exception('Firebase connection failed');
    }
    
    // Sign in user anonymously
    final user = await signInAnonymously();
    
    return user;
  }

  /// Get current Firebase user
  static User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  /// Sign out current user
  static Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      log.info('👋 User signed out successfully');
    } catch (e) {
      log.severe('❌ Sign out failed: $e');
      rethrow;
    }
  }

  /// Reset Firebase (for testing purposes)
  static void reset() {
    _isInitialized = false;
    _isInitializing = false;
    log.info('🔄 Firebase initialization state reset');
  }
}