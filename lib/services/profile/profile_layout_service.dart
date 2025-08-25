import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/profile/profile_layout_config.dart';

/// Service for managing profile layout persistence
class ProfileLayoutService {
  static const String _layoutKey = 'profile_layout_config';
  static const String _firestoreCollection = 'userProfileLayouts';

  /// Save layout configuration locally (immediate)
  Future<void> saveLayoutLocally(ProfileLayoutConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(config.toJson());
      await prefs.setString(_layoutKey, jsonString);
    } catch (e) {
      throw Exception('Failed to save layout locally: $e');
    }
  }

  /// Load layout configuration from local storage
  Future<ProfileLayoutConfig> loadLayoutLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_layoutKey);
      
      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return ProfileLayoutConfig.fromJson(json);
      }
      
      // Return default layout if nothing saved locally
      return ProfileLayoutConfig.defaultLayout();
    } catch (e) {
      // Return default layout if loading fails
      return ProfileLayoutConfig.defaultLayout();
    }
  }

  /// Sync layout to Firebase (background operation)
  Future<bool> syncLayoutToFirebase(ProfileLayoutConfig config) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final docRef = FirebaseFirestore.instance
          .collection(_firestoreCollection)
          .doc(user.uid);

      await docRef.set({
        ...config.toJson(),
        'syncedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      // Silent fail for background sync
      return false;
    }
  }

  /// Load layout from Firebase
  Future<ProfileLayoutConfig?> loadLayoutFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final docRef = FirebaseFirestore.instance
          .collection(_firestoreCollection)
          .doc(user.uid);

      final doc = await docRef.get();
      
      if (doc.exists && doc.data() != null) {
        return ProfileLayoutConfig.fromJson(doc.data()!);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Smart sync: merge local and remote configs
  Future<ProfileLayoutConfig> smartSync() async {
    try {
      final localConfig = await loadLayoutLocally();
      final remoteConfig = await loadLayoutFromFirebase();

      // If no remote config, use local and sync to Firebase
      if (remoteConfig == null) {
        syncLayoutToFirebase(localConfig); // Fire and forget
        return localConfig;
      }

      // If remote is newer, use it and save locally
      if (remoteConfig.lastModified.isAfter(localConfig.lastModified)) {
        await saveLayoutLocally(remoteConfig);
        return remoteConfig;
      }

      // If local is newer, use it and sync to Firebase
      if (localConfig.lastModified.isAfter(remoteConfig.lastModified)) {
        syncLayoutToFirebase(localConfig); // Fire and forget
        return localConfig;
      }

      // If same timestamp, prefer local (current device preference)
      return localConfig;
    } catch (e) {
      // Fallback to local config if smart sync fails
      return loadLayoutLocally();
    }
  }

  /// Clear all layout data (for testing/reset purposes)
  Future<void> clearLayoutData() async {
    try {
      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_layoutKey);

      // Clear Firebase (optional)
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final docRef = FirebaseFirestore.instance
            .collection(_firestoreCollection)
            .doc(user.uid);
        await docRef.delete();
      }
    } catch (e) {
      // Silent fail
    }
  }
}