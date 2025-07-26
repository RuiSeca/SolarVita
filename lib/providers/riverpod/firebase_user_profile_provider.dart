// lib/providers/riverpod/firebase_user_profile_provider.dart

import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../../services/firebase_user_profile_service.dart';
import '../../models/user_profile.dart';
import '../../models/social_post.dart';
import 'auth_provider.dart';

part 'firebase_user_profile_provider.g.dart';

// FIREBASE SERVICE PROVIDER

@riverpod
FirebaseUserProfileService firebaseUserProfileService(Ref ref) {
  return FirebaseUserProfileService();
}

// USER PROFILE PROVIDERS

@riverpod
Future<UserProfile?> currentUserProfile(Ref ref) async {
  final service = ref.watch(firebaseUserProfileServiceProvider);
  return service.getCurrentUserProfile();
}

@riverpod
Future<UserProfile?> userProfile(Ref ref, String userId) async {
  final service = ref.watch(firebaseUserProfileServiceProvider);
  return service.getUserProfile(userId);
}

@riverpod
Future<Map<String, int>> userSocialStats(Ref ref, String userId) async {
  final service = ref.watch(firebaseUserProfileServiceProvider);
  return service.getUserSocialStats(userId);
}

@riverpod
Future<bool> isFollowingUser(Ref ref, String targetUserId) async {
  final service = ref.watch(firebaseUserProfileServiceProvider);
  return service.isFollowingUser(targetUserId);
}

@riverpod
Future<List<UserProfile>> recommendedUsers(Ref ref, {int limit = 10}) async {
  final service = ref.watch(firebaseUserProfileServiceProvider);
  return service.getRecommendedUsers(limit: limit);
}

@riverpod
Future<List<UserProfile>> searchUsers(Ref ref, String query, {int limit = 20}) async {
  if (query.trim().isEmpty) return [];
  
  final service = ref.watch(firebaseUserProfileServiceProvider);
  return service.searchUsers(query, limit: limit);
}

// STREAM PROVIDERS

@riverpod
Stream<List<UserProfile>> userFollowers(Ref ref, String userId) {
  final service = ref.watch(firebaseUserProfileServiceProvider);
  return service.getUserFollowers(userId);
}

@riverpod
Stream<List<UserProfile>> userFollowing(Ref ref, String userId) {
  final service = ref.watch(firebaseUserProfileServiceProvider);
  return service.getUserFollowing(userId);
}

@riverpod
Stream<List<SocialPost>> userPosts(Ref ref, String userId, {int limit = 20}) {
  final service = ref.watch(firebaseUserProfileServiceProvider);
  return service.getUserPosts(userId, limit: limit);
}

@riverpod
Stream<List<SocialPost>> currentUserPosts(Ref ref, {int limit = 20}) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return Stream.value([]);
  
  final service = ref.watch(firebaseUserProfileServiceProvider);
  return service.getUserPosts(currentUser.uid, limit: limit);
}

@riverpod
Stream<List<SocialPost>> savedPosts(Ref ref, {int limit = 20}) {
  final service = ref.watch(firebaseUserProfileServiceProvider);
  return service.getUserSavedPosts(limit: limit);
}

// STATE MANAGEMENT PROVIDERS

/// User Profile Actions State Notifier
@riverpod
class UserProfileActions extends _$UserProfileActions {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<UserProfile> updateProfile({
    String? displayName,
    String? username,
    String? bio,
    File? profileImage,
    Map<String, dynamic>? preferences,
    List<String>? interests,
    bool? isPublic,
    Map<String, dynamic>? additionalData,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final service = ref.read(firebaseUserProfileServiceProvider);
      final updatedProfile = await service.updateUserProfile(
        displayName: displayName,
        username: username,
        bio: bio,
        profileImage: profileImage,
        preferences: preferences,
        interests: interests,
        isPublic: isPublic,
        additionalData: additionalData,
      );
      
      state = const AsyncValue.data(null);
      
      // Invalidate related providers to trigger refresh
      ref.invalidate(currentUserProfileProvider);
      
      return updatedProfile;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> toggleFollowUser(String targetUserId) async {
    try {
      final service = ref.read(firebaseUserProfileServiceProvider);
      await service.toggleFollowUser(targetUserId);
      
      // Invalidate related providers
      ref.invalidate(isFollowingUserProvider);
      ref.invalidate(userSocialStatsProvider);
      ref.invalidate(userFollowersProvider);
      ref.invalidate(userFollowingProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateLastActive() async {
    try {
      final service = ref.read(firebaseUserProfileServiceProvider);
      await service.updateLastActive();
    } catch (error) {
      // Silently fail for activity updates
      final logger = Logger('ActivityTracker');
      logger.warning('Failed to update last active: $error');
    }
  }

  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();
    
    try {
      final service = ref.read(firebaseUserProfileServiceProvider);
      await service.deleteUserAccount();
      
      state = const AsyncValue.data(null);
      
      // Clear all cached data
      ref.invalidate(currentUserProfileProvider);
      ref.invalidate(currentUserProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<List<UserProfile>> searchUsers(String query, {int limit = 20}) async {
    try {
      final service = ref.read(firebaseUserProfileServiceProvider);
      return await service.searchUsers(query, limit: limit);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  void clearCache() {
    final service = ref.read(firebaseUserProfileServiceProvider);
    service.clearCache();
    ref.invalidate(currentUserProfileProvider);
  }
}

// UTILITY PROVIDERS

/// Current user social stats
@riverpod
Future<Map<String, int>> currentUserSocialStats(Ref ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return {
      'postsCount': 0,
      'followersCount': 0,
      'followingCount': 0,
    };
  }
  
  return ref.watch(userSocialStatsProvider(currentUser.uid).future);
}

/// Check if username is available
@riverpod
Future<bool> isUsernameAvailable(Ref ref, String username) async {
  if (username.trim().isEmpty) return false;
  
  try {
    final results = await ref.read(userProfileActionsProvider.notifier)
        .searchUsers(username, limit: 1);
    
    // Check for exact match
    return !results.any((user) => 
        user.username?.toLowerCase() == username.toLowerCase());
  } catch (e) {
    return false;
  }
}

/// Get user display info (for mentions, etc.)
@riverpod
Future<Map<String, String>> userDisplayInfo(Ref ref, String userId) async {
  try {
    final profile = await ref.watch(userProfileProvider(userId).future);
    if (profile == null) {
      return {
        'displayName': 'Unknown User',
        'username': '@unknown',
        'photoURL': '',
      };
    }
    
    return {
      'displayName': profile.displayName,
      'username': profile.username ?? '@${profile.displayName.toLowerCase()}',
      'photoURL': profile.photoURL ?? '',
    };
  } catch (e) {
    return {
      'displayName': 'Unknown User',
      'username': '@unknown',
      'photoURL': '',
    };
  }
}

/// Profile completion status
@riverpod
Future<ProfileCompletionStatus> profileCompletionStatus(Ref ref) async {
  final profile = await ref.watch(currentUserProfileProvider.future);
  if (profile == null) {
    return ProfileCompletionStatus(
      isComplete: false,
      completionPercentage: 0,
      missingFields: ['Profile not found'],
    );
  }

  final missingFields = <String>[];
  var completedFields = 0;
  const totalFields = 6;

  // Check required fields
  if (profile.displayName.isEmpty) {
    missingFields.add('Display Name');
  } else {
    completedFields++;
  }

  if (profile.username == null || profile.username!.isEmpty) {
    missingFields.add('Username');
  } else {
    completedFields++;
  }

  if (profile.bio == null || profile.bio!.isEmpty) {
    missingFields.add('Bio');
  } else {
    completedFields++;
  }

  if (profile.photoURL == null || profile.photoURL!.isEmpty) {
    missingFields.add('Profile Photo');
  } else {
    completedFields++;
  }

  if (profile.interests.isEmpty) {
    missingFields.add('Interests');
  } else {
    completedFields++;
  }

  if (!profile.isOnboardingComplete) {
    missingFields.add('Complete Onboarding');
  } else {
    completedFields++;
  }

  final percentage = (completedFields / totalFields * 100).round();

  return ProfileCompletionStatus(
    isComplete: missingFields.isEmpty,
    completionPercentage: percentage,
    missingFields: missingFields,
  );
}

/// Helper class for profile completion status
class ProfileCompletionStatus {
  final bool isComplete;
  final int completionPercentage;
  final List<String> missingFields;

  ProfileCompletionStatus({
    required this.isComplete,
    required this.completionPercentage,
    required this.missingFields,
  });
}

/// Auto-refresh user activity
@riverpod
class ActivityTracker extends _$ActivityTracker {
  @override
  void build() {
    // Update activity every 5 minutes when app is active
    ref.listen(currentUserProvider, (previous, next) {
      if (next != null) {
        _startActivityTracking();
      }
    });
  }

  void _startActivityTracking() {
    // Update activity status
    ref.read(userProfileActionsProvider.notifier).updateLastActive();
  }

  void trackActivity() {
    ref.read(userProfileActionsProvider.notifier).updateLastActive();
  }
}