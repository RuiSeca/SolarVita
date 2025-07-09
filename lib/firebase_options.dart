// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Web configuration (you'll need to get these from Firebase Console -> Project Settings -> Web App)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'your-web-api-key', // Get from Firebase Console
    appId: 'your-web-app-id', // Get from Firebase Console
    messagingSenderId: '311138668281',
    projectId: 'grooves-app',
    authDomain: 'grooves-app.firebaseapp.com',
    storageBucket: 'grooves-app.firebasestorage.app',
  );

  // Android configuration - extracted from your google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD3xGRM8-rRb8oTL1vm3TdU658Bfjj36a4',
    appId: '1:311138668281:android:384a4a8358b4b8c5011c28',
    messagingSenderId: '311138668281',
    projectId: 'grooves-app',
    storageBucket: 'grooves-app.firebasestorage.app',
  );

  // iOS configuration (you'll need to add iOS app to Firebase and get these values)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'your-ios-api-key', // Get from GoogleService-Info.plist
    appId: 'your-ios-app-id', // Get from GoogleService-Info.plist
    messagingSenderId: '311138668281',
    projectId: 'grooves-app',
    storageBucket: 'grooves-app.firebasestorage.app',
    iosBundleId: 'com.solarvitadev.solarvita',
  );

  // macOS configuration (same as iOS in most cases)
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'your-ios-api-key', // Same as iOS
    appId: 'your-ios-app-id', // Same as iOS
    messagingSenderId: '311138668281',
    projectId: 'grooves-app',
    storageBucket: 'grooves-app.firebasestorage.app',
    iosBundleId: 'com.solarvitadev.solarvita',
  );

  // Windows configuration
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'your-web-api-key', // Get from Firebase Console
    appId: 'your-web-app-id', // Get from Firebase Console
    messagingSenderId: '311138668281',
    projectId: 'grooves-app',
    authDomain: 'grooves-app.firebaseapp.com',
    storageBucket: 'grooves-app.firebasestorage.app',
  );
}
