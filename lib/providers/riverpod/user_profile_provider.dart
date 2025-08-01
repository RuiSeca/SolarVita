import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user/user_profile.dart';
import '../../services/database/user_profile_service.dart';
import '../../services/auth/auth_service.dart';
import '../../services/database/social_service.dart';
import '../../services/chat/data_sync_service.dart';
import 'user_progress_provider.dart';
import 'health_data_provider.dart';
import '../../models/user/user_progress.dart';
import '../../models/health/health_data.dart';

part 'user_profile_provider.g.dart';

// Combined profile data model for performance optimization
class ProfileData {
  final UserProfile? profile;
  final UserProgress? progress;
  final HealthData? healthData;

  const ProfileData(this.profile, this.progress, this.healthData);

  bool get isLoading => profile == null || progress == null;
  bool get hasHealthData => healthData != null;
}

// Service providers
@riverpod
UserProfileService userProfileService(Ref ref) {
  return UserProfileService();
}

@riverpod
AuthService authService(Ref ref) {
  return AuthService();
}

@riverpod
SocialService socialService(Ref ref) {
  return SocialService();
}

// Auth state provider
@riverpod
Stream<User?> authStateChanges(Ref ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
}

// Main user profile provider
@riverpod
class UserProfileNotifier extends _$UserProfileNotifier {
  @override
  Future<UserProfile?> build() async {
    // Register callback for supporter count changes
    SocialService.setSupporterCountChangeCallback(() async {
      await silentRefreshSupporterCount();
    });

    // Listen to auth state changes
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) async {
        if (user != null) {
          // Clear cache for new user sessions
          ref.read(userProfileServiceProvider).clearCache();
          return await _loadUserProfile();
        } else {
          // Clear cache when user logs out
          ref.read(userProfileServiceProvider).clearCache();
          return null;
        }
      },
      loading: () => null,
      error: (error, stackTrace) {
        return null;
      },
    );
  }

  Future<UserProfile?> _loadUserProfile({bool forceRefresh = false}) async {
    try {
      final userProfileService = ref.read(userProfileServiceProvider);
      final newProfile = await userProfileService.getOrCreateUserProfile(
        forceRefresh: forceRefresh,
      );

      // Sync public profile data for new/existing profiles to ensure chat data is current
      await _syncPublicProfileData(newProfile);

      return newProfile;
    } catch (e) {
      throw Exception('Failed to load user profile: $e');
    }
  }

  Future<void> refreshUserProfile() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadUserProfile(forceRefresh: true));
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    state = const AsyncLoading();

    try {
      final userProfileService = ref.read(userProfileServiceProvider);
      final updatedProfile = await userProfileService.updateUserProfile(
        profile,
      );

      // Sync public profile data to Firebase for supporters
      await _syncPublicProfileData(updatedProfile);

      state = AsyncValue.data(updatedProfile);
    } catch (e) {
      state = AsyncValue.error(
        'Failed to update user profile: $e',
        StackTrace.current,
      );
    }
  }

  Future<void> _syncPublicProfileData(UserProfile profile) async {
    try {
      await DataSyncService().syncPublicProfile(
        displayName: profile.displayName,
        avatarUrl: profile.photoURL,
        currentLevel:
            1, // Default level - will be updated from UserProgress separately
        currentStrikes:
            0, // Default strikes - will be updated from UserProgress separately
        ecoScore: 0.0, // Default eco score - will be calculated separately
        supporterCount: profile.supportersCount,
        supportingCount: 0, // Will be fetched from social service separately
      );
    } catch (e) {
      // Don't throw - sync failures shouldn't block profile updates
    }
  }

  void setUserProfile(UserProfile profile) {
    state = AsyncValue.data(profile);
  }

  Future<void> updateWorkoutPreferences(WorkoutPreferences preferences) async {
    final currentProfile = state.value;
    if (currentProfile == null) return;

    state = const AsyncLoading();

    try {
      final userProfileService = ref.read(userProfileServiceProvider);
      final updatedProfile = await userProfileService.updateWorkoutPreferences(
        currentProfile.uid,
        preferences,
      );

      state = AsyncValue.data(updatedProfile);
    } catch (e) {
      state = AsyncValue.error(
        'Failed to update workout preferences: $e',
        StackTrace.current,
      );
    }
  }

  Future<void> updateSustainabilityPreferences(
    SustainabilityPreferences preferences,
  ) async {
    final currentProfile = state.value;
    if (currentProfile == null) return;

    state = const AsyncLoading();

    try {
      final userProfileService = ref.read(userProfileServiceProvider);
      final updatedProfile = await userProfileService
          .updateSustainabilityPreferences(currentProfile.uid, preferences);

      state = AsyncValue.data(updatedProfile);
    } catch (e) {
      state = AsyncValue.error(
        'Failed to update sustainability preferences: $e',
        StackTrace.current,
      );
    }
  }

  Future<void> updateDiaryPreferences(DiaryPreferences preferences) async {
    final currentProfile = state.value;
    if (currentProfile == null) return;

    state = const AsyncLoading();

    try {
      final userProfileService = ref.read(userProfileServiceProvider);
      final updatedProfile = await userProfileService.updateDiaryPreferences(
        currentProfile.uid,
        preferences,
      );

      state = AsyncValue.data(updatedProfile);
    } catch (e) {
      state = AsyncValue.error(
        'Failed to update diary preferences: $e',
        StackTrace.current,
      );
    }
  }

  Future<void> updateDietaryPreferences(DietaryPreferences preferences) async {
    final currentProfile = state.value;
    if (currentProfile == null) return;

    state = const AsyncLoading();

    try {
      final userProfileService = ref.read(userProfileServiceProvider);
      final updatedProfile = await userProfileService.updateDietaryPreferences(
        currentProfile.uid,
        preferences,
      );

      state = AsyncValue.data(updatedProfile);
    } catch (e) {
      state = AsyncValue.error(
        'Failed to update dietary preferences: $e',
        StackTrace.current,
      );
    }
  }

  Future<void> refreshSupporterCount() async {
    final currentProfile = state.value;
    if (currentProfile == null) return;

    try {
      // Clear cache to force fresh data
      ref.read(userProfileServiceProvider).clearCache();
      await refreshUserProfile(); // This now uses forceRefresh: true
    } catch (e) {
      // Ignore refresh errors
    }
  }

  // Silent refresh that doesn't trigger loading state
  Future<void> silentRefreshSupporterCount() async {
    final currentProfile = state.value;
    if (currentProfile == null) return;

    try {
      // Clear cache and get fresh data
      ref.read(userProfileServiceProvider).clearCache();
      final freshProfile = await ref
          .read(userProfileServiceProvider)
          .getCurrentUserProfile(forceRefresh: true);

      if (freshProfile != null) {
        // Update state directly without loading state
        state = AsyncValue.data(freshProfile);
      }
    } catch (e) {
      // Ignore refresh errors silently
    }
  }

  Future<void> initializeSupportersCount() async {
    try {
      final socialService = ref.read(socialServiceProvider);
      await socialService.initializeSupportersCount();

      // Refresh current user profile after migration
      await refreshSupporterCount();
    } catch (e) {
      rethrow;
    }
  }
}

// Combined profile data provider - simple function-based approach
@riverpod
Future<ProfileData> profileData(Ref ref) async {
  // Import the other providers
  final profileFuture = ref.watch(userProfileNotifierProvider.future);
  final progressFuture = ref.watch(userProgressNotifierProvider.future);
  final healthDataFuture = ref.watch(healthDataNotifierProvider.future);

  // Get profile and progress data
  final profile = await profileFuture;
  final progress = await progressFuture;

  // Handle health data separately to allow null values
  HealthData? healthData;
  try {
    healthData = await healthDataFuture;
  } catch (e) {
    // Health data can fail gracefully
    healthData = null;
  }

  return ProfileData(profile, progress, healthData);
}

// Convenience providers for common profile data
@riverpod
bool isOnboardingComplete(Ref ref) {
  final profileAsync = ref.watch(userProfileNotifierProvider);
  return profileAsync.value?.isOnboardingComplete ?? false;
}

@riverpod
WorkoutPreferences? workoutPreferences(Ref ref) {
  final profileAsync = ref.watch(userProfileNotifierProvider);
  return profileAsync.value?.workoutPreferences;
}

@riverpod
SustainabilityPreferences? sustainabilityPreferences(Ref ref) {
  final profileAsync = ref.watch(userProfileNotifierProvider);
  return profileAsync.value?.sustainabilityPreferences;
}

@riverpod
DiaryPreferences? diaryPreferences(Ref ref) {
  final profileAsync = ref.watch(userProfileNotifierProvider);
  return profileAsync.value?.diaryPreferences;
}

@riverpod
DietaryPreferences? dietaryPreferences(Ref ref) {
  final profileAsync = ref.watch(userProfileNotifierProvider);
  return profileAsync.value?.dietaryPreferences;
}

@riverpod
String? displayName(Ref ref) {
  final profileAsync = ref.watch(userProfileNotifierProvider);
  return profileAsync.value?.displayName;
}

@riverpod
String? email(Ref ref) {
  final profileAsync = ref.watch(userProfileNotifierProvider);
  return profileAsync.value?.email;
}

@riverpod
String? photoURL(Ref ref) {
  final profileAsync = ref.watch(userProfileNotifierProvider);
  return profileAsync.value?.photoURL;
}

@riverpod
DateTime? createdAt(Ref ref) {
  final profileAsync = ref.watch(userProfileNotifierProvider);
  return profileAsync.value?.createdAt;
}

@riverpod
DateTime? lastUpdated(Ref ref) {
  final profileAsync = ref.watch(userProfileNotifierProvider);
  return profileAsync.value?.lastUpdated;
}

// User profile stream provider
@riverpod
Stream<UserProfile?> userProfileStream(Ref ref) {
  final userProfileService = ref.watch(userProfileServiceProvider);
  return userProfileService.getCurrentUserProfileStream();
}

// Real-time supporter count listener
@riverpod
Stream<int> supporterCountStream(Ref ref) {
  final auth = FirebaseAuth.instance;
  final user = auth.currentUser;

  if (user == null) {
    return Stream.value(0);
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();
          return data?['supportersCount'] ?? 0;
        }
        return 0;
      });
}
