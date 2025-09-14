import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
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

    // Listen to auth state changes and await the result
    final authState = await ref.watch(authStateChangesProvider.future);

    if (authState != null) {
      // Clear cache for new user sessions
      ref.read(userProfileServiceProvider).clearCache();
      return await _loadUserProfile();
    } else {
      // Clear cache when user logs out
      ref.read(userProfileServiceProvider).clearCache();
      return null;
    }
  }

  Future<UserProfile?> _loadUserProfile({bool forceRefresh = false}) async {
    try {
      debugPrint('🔄 Loading user profile...');
      final userProfileService = ref.read(userProfileServiceProvider);

      // Add timeout to prevent hanging
      final newProfile = await userProfileService.getOrCreateUserProfile(
        forceRefresh: forceRefresh,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⏰ User profile loading timed out - creating default profile');
          throw TimeoutException('Profile loading timed out', const Duration(seconds: 10));
        },
      );

      debugPrint('✅ User profile loaded successfully');

      // Sync public profile data for new/existing profiles to ensure chat data is current
      try {
        await _syncPublicProfileData(newProfile);
      } catch (e) {
        debugPrint('⚠️ Failed to sync public profile data: $e');
        // Continue anyway - this isn't critical
      }

      return newProfile;
    } catch (e) {
      debugPrint('❌ Failed to load user profile: $e');

      // For timeout or other errors, try to create a minimal default profile
      if (e is TimeoutException) {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            debugPrint('🔧 Creating fallback minimal profile...');
            final fallbackProfile = UserProfile(
              uid: user.uid,
              email: user.email ?? '',
              displayName: user.displayName ?? 'User',
              photoURL: user.photoURL,
              isOnboardingComplete: false,
              createdAt: DateTime.now(),
              lastUpdated: DateTime.now(),
              workoutPreferences: WorkoutPreferences(),
              sustainabilityPreferences: SustainabilityPreferences(),
              diaryPreferences: DiaryPreferences(),
              dietaryPreferences: DietaryPreferences(),
            );
            return fallbackProfile;
          }
        } catch (fallbackError) {
          debugPrint('❌ Fallback profile creation failed: $fallbackError');
        }
      }

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

  Future<void> completeOnboarding() async {
    final currentProfile = state.value;
    if (currentProfile == null) return;

    // Create updated profile with onboarding marked as complete
    final updatedProfile = currentProfile.copyWith(
      isOnboardingComplete: true,
      lastUpdated: DateTime.now(),
    );

    await updateUserProfile(updatedProfile);
  }

  Future<void> completeOnboardingWithData(dynamic onboardingUserProfile, [Map<String, dynamic>? additionalData]) async {
    final currentProfile = state.value;
    if (currentProfile == null) return;

    // Get food preferences from additional data
    final foodPrefs = additionalData?['foodPreferences'] as Map<String, dynamic>? ?? {};

    // Create comprehensive dietary preferences from onboarding data
    final dietaryPreferences = DietaryPreferences(
      dietType: onboardingUserProfile.dietType ?? 'omnivore',
      restrictions: onboardingUserProfile.restrictions ?? [],
      allergies: onboardingUserProfile.allergies ?? [],
      breakfastTime: onboardingUserProfile.breakfastTime ?? '08:00',
      lunchTime: onboardingUserProfile.lunchTime ?? '12:30',
      dinnerTime: onboardingUserProfile.dinnerTime ?? '19:00',
      snackTime: onboardingUserProfile.snackTime ?? '15:30',
      enableSnacks: onboardingUserProfile.snackTime != null,
      dailyCalorieGoal: onboardingUserProfile.dailyCalorieGoal ?? 2000,
      proteinPercentage: onboardingUserProfile.proteinPercentage ?? 20,
      carbsPercentage: onboardingUserProfile.carbsPercentage ?? 50,
      fatPercentage: onboardingUserProfile.fatPercentage ?? 30,
      mealsPerDay: onboardingUserProfile.snackTime != null ? 4 : 3,
      // Use food preferences from the additional data
      preferOrganic: foodPrefs['preferOrganic'] ?? true,
      preferLocal: foodPrefs['preferLocal'] ?? true,
      preferSeasonal: foodPrefs['preferSeasonal'] ?? true,
      sustainableSeafood: foodPrefs['sustainableSeafood'] ?? true,
      reduceMeatConsumption: foodPrefs['reduceMeatConsumption'] ??
                            (onboardingUserProfile.dietType == 'vegetarian' || onboardingUserProfile.dietType == 'vegan'),
      intermittentFasting: foodPrefs['intermittentFasting'] ?? false,
    );

    // Get selected workout days from additional data
    final selectedWorkoutDays = additionalData?['selectedWorkoutDays'] as List<dynamic>? ?? [];
    final workoutDaysMap = {
      'monday': selectedWorkoutDays.contains('monday'),
      'tuesday': selectedWorkoutDays.contains('tuesday'),
      'wednesday': selectedWorkoutDays.contains('wednesday'),
      'thursday': selectedWorkoutDays.contains('thursday'),
      'friday': selectedWorkoutDays.contains('friday'),
      'saturday': selectedWorkoutDays.contains('saturday'),
      'sunday': selectedWorkoutDays.contains('sunday'),
    };

    // Create comprehensive workout preferences from onboarding data
    final workoutPreferences = WorkoutPreferences(
      fitnessLevel: onboardingUserProfile.fitnessLevel?.toString().split('.').last ?? 'beginner',
      preferredWorkoutTypes: [], // Will be set from workout preferences screen
      fitnessGoals: [], // Will be set from fitness goals screen
      preferredTime: onboardingUserProfile.preferredWorkoutTimeString ?? additionalData?['preferredWorkoutTime'] ?? 'morning',
      sessionDurationMinutes: 30, // Default
      workoutFrequencyPerWeek: selectedWorkoutDays.isNotEmpty ? selectedWorkoutDays.length : 3, // Use selected days count
      availableDays: workoutDaysMap,
    );

    // Create sustainability preferences with defaults
    final sustainabilityPreferences = SustainabilityPreferences(
      carbonFootprintTarget: 'moderate',
      preferredTransportMode: 'walking',
      receiveEcoTips: true,
      ecoTipFrequency: 3,
      trackEnergyUsage: true,
      trackTransportation: true,
      trackWasteReduction: true,
      trackWaterUsage: true,
      sustainabilityGoals: [],
      ecoFriendlyActivities: [],
      interestedCategories: [],
    );

    // Create diary preferences with defaults
    final diaryPreferences = DiaryPreferences(
      defaultTemplate: 'daily_summary',
      enableDailyReminders: true,
      reminderTime: '20:00',
      enableGoalTracking: true,
      enableMoodTracking: true,
      enableProgressPhotos: false,
      privateByDefault: true,
      trackingCategories: ['workout', 'nutrition', 'mood', 'sustainability'],
    );

    // Transfer all onboarding data to main UserProfile
    final updatedProfile = currentProfile.copyWith(
      displayName: onboardingUserProfile.name ?? currentProfile.displayName,
      username: onboardingUserProfile.username ?? currentProfile.username,
      workoutPreferences: workoutPreferences,
      sustainabilityPreferences: sustainabilityPreferences,
      diaryPreferences: diaryPreferences,
      dietaryPreferences: dietaryPreferences,
      isOnboardingComplete: true,
      lastUpdated: DateTime.now(),
    );

    await updateUserProfile(updatedProfile);
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
