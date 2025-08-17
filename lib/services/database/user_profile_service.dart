import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user/user_profile.dart';

class UserProfileService {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _usersCollection = 'users';

  // Cache for user profile to reduce Firebase reads
  UserProfile? _cachedProfile;
  String? _cachedUid;

  // Clear the profile cache
  void clearCache() {
    _cachedProfile = null;
    _cachedUid = null;
  }

  Future<UserProfile?> getCurrentUserProfile({
    bool forceRefresh = false,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _cachedProfile = null;
        _cachedUid = null;
        return null;
      }

      // Return cached profile if available and valid (unless force refresh)
      if (!forceRefresh && _cachedProfile != null && _cachedUid == user.uid) {
        return _cachedProfile;
      }

      final doc = await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .get();
      if (!doc.exists) {
        _cachedProfile = null;
        _cachedUid = null;
        return null;
      }

      final profile = UserProfile.fromFirestore(doc);
      _cachedProfile = profile;
      _cachedUid = user.uid;
      return profile;
    } catch (e) {
      throw Exception('Failed to fetch user profile');
    }
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      if (!doc.exists) {
        return null;
      }

      return UserProfile.fromFirestore(doc);
    } catch (e) {
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
        isOnboardingComplete: false, // New users should go through onboarding
        workoutPreferences: WorkoutPreferences(),
        sustainabilityPreferences: SustainabilityPreferences(),
        diaryPreferences: DiaryPreferences(),
        dietaryPreferences: DietaryPreferences(),
      );

      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .set(userProfile.toFirestore());

      // Cache the new profile
      _cachedProfile = userProfile;
      _cachedUid = uid;

      return userProfile;
    } catch (e) {
      throw Exception('Failed to create user profile');
    }
  }

  Future<UserProfile> updateUserProfile(UserProfile profile) async {
    try {
      final updatedProfile = profile.copyWith(lastUpdated: DateTime.now());
      final firestoreData = updatedProfile.toFirestore();
      
      await _firestore
          .collection(_usersCollection)
          .doc(profile.uid)
          .update(firestoreData);

      // Update cache with new profile
      _cachedProfile = updatedProfile;
      _cachedUid = profile.uid;

      return updatedProfile;
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  Future<void> deleteUserProfile(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).delete();
    } catch (e) {
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

      return updatedProfile;
    } catch (e) {
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

      return updatedProfile;
    } catch (e) {
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

      return updatedProfile;
    } catch (e) {
      throw Exception('Failed to update diary preferences');
    }
  }

  Future<UserProfile> updateDietaryPreferences(
    String uid,
    DietaryPreferences preferences,
  ) async {
    try {
      final profile = await getUserProfile(uid);
      if (profile == null) {
        throw Exception('User profile not found');
      }

      final updatedProfile = profile.copyWith(
        dietaryPreferences: preferences,
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .update(updatedProfile.toFirestore());

      return updatedProfile;
    } catch (e) {
      throw Exception('Failed to update dietary preferences');
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

      return updatedProfile;
    } catch (e) {
      throw Exception('Failed to complete onboarding');
    }
  }

  Future<UserProfile> getOrCreateUserProfile({
    bool forceRefresh = false,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      // Clear cache if user has changed or force refresh requested
      if (forceRefresh || (_cachedUid != null && _cachedUid != user.uid)) {
        _cachedProfile = null;
        _cachedUid = null;
      }

      UserProfile? profile = await getCurrentUserProfile(
        forceRefresh: forceRefresh,
      );

      if (profile == null) {
        profile = await createUserProfile(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? 'User',
          photoURL: user.photoURL,
        );
      } else {
        // Update profile with latest Firebase Auth data if needed
        bool needsUpdate = false;
        String? newEmail;
        String? newDisplayName;
        String? newPhotoURL;

        if (profile.email != user.email && user.email != null) {
          newEmail = user.email;
          needsUpdate = true;
        }

        if (profile.displayName != user.displayName &&
            user.displayName != null) {
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
      throw Exception('Failed to get or create user profile');
    }
  }

  Stream<UserProfile?> getUserProfileStream(String uid) {
    return _firestore.collection(_usersCollection).doc(uid).snapshots().map((
      snapshot,
    ) {
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
      return false;
    }
  }

  Future<void> updateAdditionalData(
    String uid,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'additionalData': data,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update additional data');
    }
  }

  Future<void> updateProfileField(
    String uid,
    String field,
    dynamic value,
  ) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        field: value,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update profile field');
    }
  }

  Future<bool> isUsernameAvailable(String username) async {
    try {
      final query = await _firestore
          .collection(_usersCollection)
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      final isAvailable = query.docs.isEmpty;
      return isAvailable;
    } catch (e) {
      return false;
    }
  }
}
