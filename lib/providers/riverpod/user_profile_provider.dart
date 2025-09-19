import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import '../../screens/onboarding/models/onboarding_models.dart' show IntentType;
import '../../screens/onboarding/components/onboarding_base_screen.dart';
import '../../services/dashboard/dashboard_image_service.dart';

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
      // Clear dashboard image cache when switching accounts
      await DashboardImageService.clearCacheOnPreferenceChange();
      return await _loadUserProfile();
    } else {
      // Clear cache when user logs out
      ref.read(userProfileServiceProvider).clearCache();
      // Clear dashboard image cache on logout
      await DashboardImageService.clearCacheOnPreferenceChange();
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

      // Check for Firebase/SharedPreferences mismatch and clean up if needed
      await _handleDataMismatch(newProfile);

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

  Future<void> updatePersonalIntents(Set<IntentType> intents) async {
    final currentProfile = state.value;
    if (currentProfile == null) return;

    state = const AsyncLoading();

    try {
      final userProfileService = ref.read(userProfileServiceProvider);
      final updatedProfile = await userProfileService.updatePersonalIntents(
        currentProfile.uid,
        intents,
      );

      state = AsyncValue.data(updatedProfile);
    } catch (e) {
      state = AsyncValue.error(
        'Failed to update personal intents: $e',
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

    // Create sustainability preferences from onboarding data
    final sustainabilityGoals = additionalData?['sustainability_goals'] as List<dynamic>? ?? [];
    final ecoActivities = additionalData?['eco_activities'] as List<dynamic>? ?? [];
    final transportMode = additionalData?['transport_mode'] as String? ?? 'walking';

    final sustainabilityPreferences = SustainabilityPreferences(
      carbonFootprintTarget: 'moderate',
      preferredTransportMode: transportMode,
      receiveEcoTips: true,
      ecoTipFrequency: 3,
      trackEnergyUsage: true,
      trackTransportation: true,
      trackWasteReduction: true,
      trackWaterUsage: true,
      sustainabilityGoals: sustainabilityGoals.cast<String>(),
      ecoFriendlyActivities: ecoActivities.cast<String>(),
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
      selectedIntents: onboardingUserProfile.selectedIntents ?? currentProfile.selectedIntents,
      age: onboardingUserProfile.age ?? currentProfile.age,
      gender: additionalData?['gender'] ?? currentProfile.gender,

      // Additional onboarding fields
      preferredName: onboardingUserProfile.preferredName ?? currentProfile.preferredName,
      pronouns: onboardingUserProfile.pronouns ?? currentProfile.pronouns,
      location: onboardingUserProfile.location ?? currentProfile.location,
      profileImagePath: onboardingUserProfile.profileImagePath ?? currentProfile.profileImagePath,
      fitnessLevel: onboardingUserProfile.fitnessLevel?.toString().split('.').last ?? currentProfile.fitnessLevel,
      currentEcoHabits: onboardingUserProfile.currentEcoHabits?.map((e) => e.toString().split('.').last).toSet().cast<String>() ?? currentProfile.currentEcoHabits,
      preferredWorkoutTime: onboardingUserProfile.preferredWorkoutTime ?? currentProfile.preferredWorkoutTime,
      preferredWorkoutTimeString: onboardingUserProfile.preferredWorkoutTimeString ?? currentProfile.preferredWorkoutTimeString,
      height: additionalData?['height']?.toString() ?? currentProfile.height,
      weight: additionalData?['weight']?.toString() ?? currentProfile.weight,
      bio: additionalData?['bio']?.toString() ?? currentProfile.bio,
    );

    debugPrint('🎯 Completing onboarding - setting isOnboardingComplete to true');
    debugPrint('🎯 Onboarding data: age=${onboardingUserProfile.age}, fitnessLevel=${onboardingUserProfile.fitnessLevel}');
    debugPrint('🎯 Additional data: gender=${additionalData?['gender']}, height=${additionalData?['height']}, weight=${additionalData?['weight']}');
    debugPrint('🎯 Updated profile: ${updatedProfile.email}, onboardingComplete: ${updatedProfile.isOnboardingComplete}');
    debugPrint('🎯 Final profile data: age=${updatedProfile.age}, gender=${updatedProfile.gender}, height=${updatedProfile.height}, weight=${updatedProfile.weight}');

    await updateUserProfile(updatedProfile);

    debugPrint('🎯 Onboarding completion saved to Firebase successfully');
  }

  /// Detects and fixes Firebase/SharedPreferences mismatch that can cause infinite loops
  Future<void> _handleDataMismatch(UserProfile profile) async {
    try {
      // Only handle data mismatch for very specific conditions:
      // 1. Profile was created within the last 2 minutes (not 5 minutes)
      // 2. User account is older than 1 hour (indicating they should have completed onboarding)
      // 3. Onboarding is incomplete

      final now = DateTime.now();
      final profileCreatedVeryRecently = profile.createdAt.isAfter(now.subtract(const Duration(minutes: 2)));

      // Get Firebase Auth user creation time to check account age
      final authUser = FirebaseAuth.instance.currentUser;
      bool isOldAccount = false;
      if (authUser?.metadata.creationTime != null) {
        final accountAge = now.difference(authUser!.metadata.creationTime!);
        isOldAccount = accountAge.inHours >= 1;
      }

      // Only trigger cleanup for very specific mismatch conditions
      if (profileCreatedVeryRecently && isOldAccount && !profile.isOnboardingComplete) {
        debugPrint('🔍 Detected genuine Firebase/SharedPreferences mismatch');
        debugPrint('🧹 Old account (${isOldAccount ? "yes" : "no"}) with fresh profile - cleaning up cached data');

        // Clear all potentially stale SharedPreferences
        await _clearStalePreferences();

        // Clear onboarding interrupted flag
        await OnboardingBaseScreenState.clearOnboardingInterrupted();

        debugPrint('✅ Data mismatch cleanup completed');
      } else {
        debugPrint('🔍 No data mismatch detected - profile age: ${now.difference(profile.createdAt).inMinutes}min, account age: ${isOldAccount ? "old" : "new"}');
      }
    } catch (e) {
      debugPrint('⚠️ Error during data mismatch handling: $e');
      // Continue silently - this is a safety mechanism
    }
  }

  /// Clears stale SharedPreferences that might cause conflicts
  Future<void> _clearStalePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear specific keys that might conflict
      await prefs.remove('onboarding_interrupted');
      await prefs.remove('user_has_account');
      await prefs.remove('first_launch_complete');

      debugPrint('🧹 Cleared potentially stale SharedPreferences');
    } catch (e) {
      debugPrint('⚠️ Error clearing stale preferences: $e');
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
