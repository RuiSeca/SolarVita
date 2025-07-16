import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_profile.dart';
import '../../services/user_profile_service.dart';
import '../../services/auth_service.dart';
import '../../services/social_service.dart';

part 'user_profile_provider.g.dart';

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

  Future<UserProfile?> _loadUserProfile() async {
    try {
      final userProfileService = ref.read(userProfileServiceProvider);
      final newProfile = await userProfileService.getOrCreateUserProfile();
      
      return newProfile;
    } catch (e) {
      throw Exception('Failed to load user profile: $e');
    }
  }

  Future<void> refreshUserProfile() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadUserProfile());
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    state = const AsyncLoading();
    
    try {
      final userProfileService = ref.read(userProfileServiceProvider);
      final updatedProfile = await userProfileService.updateUserProfile(profile);
      
      state = AsyncValue.data(updatedProfile);
    } catch (e) {
      state = AsyncValue.error('Failed to update user profile: $e', StackTrace.current);
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
      state = AsyncValue.error('Failed to update workout preferences: $e', StackTrace.current);
    }
  }

  Future<void> updateSustainabilityPreferences(SustainabilityPreferences preferences) async {
    final currentProfile = state.value;
    if (currentProfile == null) return;

    state = const AsyncLoading();
    
    try {
      final userProfileService = ref.read(userProfileServiceProvider);
      final updatedProfile = await userProfileService.updateSustainabilityPreferences(
        currentProfile.uid,
        preferences,
      );
      
      state = AsyncValue.data(updatedProfile);
    } catch (e) {
      state = AsyncValue.error('Failed to update sustainability preferences: $e', StackTrace.current);
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
      state = AsyncValue.error('Failed to update diary preferences: $e', StackTrace.current);
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
      state = AsyncValue.error('Failed to update dietary preferences: $e', StackTrace.current);
    }
  }

  Future<void> refreshSupporterCount() async {
    final currentProfile = state.value;
    if (currentProfile == null) return;
    
    try {
      // Clear cache to force fresh data
      ref.read(userProfileServiceProvider).clearCache();
      await refreshUserProfile();
    } catch (e) {
      // Ignore refresh errors
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