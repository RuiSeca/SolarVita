import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import '../models/user_profile.dart';

class UserProfileService {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger('UserProfileService');

  static const String _usersCollection = 'users';
  
  // Cache for user profile to reduce Firebase reads
  UserProfile? _cachedProfile;
  String? _cachedUid;

  // Clear the profile cache
  void clearCache() {
    _logger.info('🗑️ Clearing profile cache');
    _cachedProfile = null;
    _cachedUid = null;
  }

  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.warning('No authenticated user found');
        _cachedProfile = null;
        _cachedUid = null;
        return null;
      }

      // Return cached profile if available and valid
      if (_cachedProfile != null && _cachedUid == user.uid) {
        _logger.info('🎯 Using cached profile for uid: ${user.uid}');
        return _cachedProfile;
      }

      _logger.info('🔄 Fetching fresh profile for uid: ${user.uid}');
      final doc = await _firestore.collection(_usersCollection).doc(user.uid).get();
      if (!doc.exists) {
        _logger.info('❌ User profile not found for uid: ${user.uid}');
        _cachedProfile = null;
        _cachedUid = null;
        return null;
      }

      final profile = UserProfile.fromFirestore(doc);
      _cachedProfile = profile;
      _cachedUid = user.uid;
      _logger.info('✅ Profile cached for uid: ${user.uid}, onboarding: ${profile.isOnboardingComplete}');
      return profile;
    } catch (e) {
      _logger.severe('Error fetching current user profile: $e');
      throw Exception('Failed to fetch user profile');
    }
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      if (!doc.exists) {
        _logger.info('User profile not found for uid: $uid');
        return null;
      }

      return UserProfile.fromFirestore(doc);
    } catch (e) {
      _logger.severe('Error fetching user profile for uid $uid: $e');
      throw Exception('Failed to fetch user profile');
    }
  }

  Future<UserProfile> createUserProfile({
    required String uid,
    required String email,
    required String displayName,
    String? photoURL,
  }) async {
    try {
      final now = DateTime.now();
      final userProfile = UserProfile(
        uid: uid,
        email: email,
        displayName: displayName,
        photoURL: photoURL,
        createdAt: now,
        lastUpdated: now,
        isOnboardingComplete: false,
        workoutPreferences: WorkoutPreferences(),
        sustainabilityPreferences: SustainabilityPreferences(),
        diaryPreferences: DiaryPreferences(),
      );

      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .set(userProfile.toFirestore());

      // Cache the new profile
      _cachedProfile = userProfile;
      _cachedUid = uid;
      
      _logger.info('User profile created for uid: $uid');
      return userProfile;
    } catch (e) {
      _logger.severe('Error creating user profile: $e');
      throw Exception('Failed to create user profile');
    }
  }

  Future<UserProfile> updateUserProfile(UserProfile profile) async {
    try {
      final updatedProfile = profile.copyWith(lastUpdated: DateTime.now());
      
      await _firestore
          .collection(_usersCollection)
          .doc(profile.uid)
          .update(updatedProfile.toFirestore());

      // Update cache with new profile
      _cachedProfile = updatedProfile;
      _cachedUid = profile.uid;
      
      _logger.info('User profile updated for uid: ${profile.uid}');
      return updatedProfile;
    } catch (e) {
      _logger.severe('Error updating user profile: $e');
      throw Exception('Failed to update user profile');
    }
  }

  Future<void> deleteUserProfile(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).delete();
      _logger.info('User profile deleted for uid: $uid');
    } catch (e) {
      _logger.severe('Error deleting user profile: $e');
      throw Exception('Failed to delete user profile');
    }
  }

  Future<UserProfile> updateWorkoutPreferences(
    String uid,
    WorkoutPreferences preferences,
  ) async {
    try {
      final profile = await getUserProfile(uid);
      if (profile == null) {
        throw Exception('User profile not found');
      }

      final updatedProfile = profile.copyWith(
        workoutPreferences: preferences,
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .update(updatedProfile.toFirestore());

      _logger.info('Workout preferences updated for uid: $uid');
      return updatedProfile;
    } catch (e) {
      _logger.severe('Error updating workout preferences: $e');
      throw Exception('Failed to update workout preferences');
    }
  }

  Future<UserProfile> updateSustainabilityPreferences(
    String uid,
    SustainabilityPreferences preferences,
  ) async {
    try {
      final profile = await getUserProfile(uid);
      if (profile == null) {
        throw Exception('User profile not found');
      }

      final updatedProfile = profile.copyWith(
        sustainabilityPreferences: preferences,
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .update(updatedProfile.toFirestore());

      _logger.info('Sustainability preferences updated for uid: $uid');
      return updatedProfile;
    } catch (e) {
      _logger.severe('Error updating sustainability preferences: $e');
      throw Exception('Failed to update sustainability preferences');
    }
  }

  Future<UserProfile> updateDiaryPreferences(
    String uid,
    DiaryPreferences preferences,
  ) async {
    try {
      final profile = await getUserProfile(uid);
      if (profile == null) {
        throw Exception('User profile not found');
      }

      final updatedProfile = profile.copyWith(
        diaryPreferences: preferences,
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .update(updatedProfile.toFirestore());

      _logger.info('Diary preferences updated for uid: $uid');
      return updatedProfile;
    } catch (e) {
      _logger.severe('Error updating diary preferences: $e');
      throw Exception('Failed to update diary preferences');
    }
  }

  Future<UserProfile> completeOnboarding(String uid) async {
    try {
      final profile = await getUserProfile(uid);
      if (profile == null) {
        throw Exception('User profile not found');
      }

      final updatedProfile = profile.copyWith(
        isOnboardingComplete: true,
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .update(updatedProfile.toFirestore());

      _logger.info('Onboarding completed for uid: $uid');
      return updatedProfile;
    } catch (e) {
      _logger.severe('Error completing onboarding: $e');
      throw Exception('Failed to complete onboarding');
    }
  }

  Future<UserProfile> getOrCreateUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      // Clear cache if user has changed
      if (_cachedUid != null && _cachedUid != user.uid) {
        _logger.info('User changed, clearing profile cache');
        _cachedProfile = null;
        _cachedUid = null;
      }

      UserProfile? profile = await getCurrentUserProfile();
      
      if (profile == null) {
        _logger.info('Creating new user profile for uid: ${user.uid}');
        profile = await createUserProfile(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? 'User',
          photoURL: user.photoURL,
        );
      } else {
        _logger.info('Found existing profile for uid: ${user.uid}, isOnboardingComplete: ${profile.isOnboardingComplete}');
        
        // Update profile with latest Firebase Auth data if needed
        bool needsUpdate = false;
        String? newEmail;
        String? newDisplayName;
        String? newPhotoURL;
        
        if (profile.email != user.email && user.email != null) {
          newEmail = user.email;
          needsUpdate = true;
        }
        
        if (profile.displayName != user.displayName && user.displayName != null) {
          newDisplayName = user.displayName;
          needsUpdate = true;
        }
        
        if (profile.photoURL != user.photoURL && user.photoURL != null) {
          newPhotoURL = user.photoURL;
          needsUpdate = true;
        }
        
        if (needsUpdate) {
          final updatedProfile = profile.copyWith(
            email: newEmail,
            displayName: newDisplayName,
            photoURL: newPhotoURL,
          );
          profile = await updateUserProfile(updatedProfile);
        }
      }

      return profile;
    } catch (e) {
      _logger.severe('Error getting or creating user profile: $e');
      throw Exception('Failed to get or create user profile');
    }
  }

  Stream<UserProfile?> getUserProfileStream(String uid) {
    return _firestore
        .collection(_usersCollection)
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return UserProfile.fromFirestore(snapshot);
    });
  }

  Stream<UserProfile?> getCurrentUserProfileStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(null);
    }
    return getUserProfileStream(user.uid);
  }

  Future<bool> userProfileExists(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      return doc.exists;
    } catch (e) {
      _logger.severe('Error checking if user profile exists: $e');
      return false;
    }
  }

  Future<void> updateAdditionalData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .update({
        'additionalData': data,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });

      _logger.info('Additional data updated for uid: $uid');
    } catch (e) {
      _logger.severe('Error updating additional data: $e');
      throw Exception('Failed to update additional data');
    }
  }

  Future<void> updateProfileField(String uid, String field, dynamic value) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .update({
        field: value,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });

      _logger.info('Profile field $field updated for uid: $uid');
    } catch (e) {
      _logger.severe('Error updating profile field $field: $e');
      throw Exception('Failed to update profile field');
    }
  }
}