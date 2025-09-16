import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service to manage user-specific caching and cleanup when users switch accounts
class UserCacheManager {
  static final UserCacheManager _instance = UserCacheManager._internal();
  factory UserCacheManager() => _instance;
  UserCacheManager._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _lastUserId;

  /// Initialize and listen to auth state changes
  void initialize() {
    _lastUserId = _auth.currentUser?.uid;

    _auth.authStateChanges().listen((user) async {
      final currentUserId = user?.uid;

      if (_lastUserId != null && _lastUserId != currentUserId) {
        debugPrint('🔄 User changed from $_lastUserId to $currentUserId - clearing cache');
        await clearCacheForPreviousUser(_lastUserId!);
      }

      _lastUserId = currentUserId;
    });
  }

  /// Clear all user-specific cached data for a specific user
  Future<void> clearCacheForPreviousUser(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get all keys that contain the user ID
      final allKeys = prefs.getKeys();
      final userSpecificKeys = allKeys.where((key) => key.endsWith('_$userId')).toList();

      // Remove all user-specific keys
      for (final key in userSpecificKeys) {
        await prefs.remove(key);
        debugPrint('🧹 Removed cache key: $key');
      }

      // Also clear some common global keys that might contain user data
      final globalKeysToCheck = [
        'water_daily_limit',
        'meal_plan_cache',
        'exercise_cache',
        'health_data_cache',
        'profile_layout_order',
      ];

      for (final key in globalKeysToCheck) {
        if (prefs.containsKey(key)) {
          await prefs.remove(key);
          debugPrint('🧹 Removed global cache key: $key');
        }
      }

      debugPrint('✅ Cache cleared for user: $userId');
    } catch (e) {
      debugPrint('❌ Failed to clear cache for user $userId: $e');
    }
  }

  /// Get user-specific key for caching
  static String getUserSpecificKey(String baseKey, {String? userId}) {
    final currentUserId = userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return baseKey; // Fallback to non-user-specific key if no user
    }
    return '${baseKey}_$currentUserId';
  }

  /// Clear all cached data (useful for complete reset)
  Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('🧹 All cache cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear all cache: $e');
    }
  }
}