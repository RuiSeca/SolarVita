import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../models/user_progress.dart';
import '../models/health_data.dart';
import '../models/privacy_settings.dart';
import 'supporter_profile_service.dart';

/// Service responsible for synchronizing local user data with Firebase
/// for supporter visibility and real-time updates
class DataSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SupporterProfileService _supporterProfileService = SupporterProfileService();
  final Logger _logger = Logger();
  
  static final DataSyncService _instance = DataSyncService._internal();
  factory DataSyncService() => _instance;
  DataSyncService._internal();

  /// Sync current user's progress data to Firebase
  Future<void> syncUserProgress(UserProgress progress) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('user_progress')
          .doc(user.uid)
          .set({
        ...progress.toJson(),
        'lastSyncedAt': Timestamp.now(),
        'isOnline': true,
      });

      _logger.d('User progress synced successfully');
    } catch (e) {
      _logger.e('Failed to sync user progress: $e');
      // Don't throw - sync failures shouldn't block the app
    }
  }

  /// Sync current user's health data to Firebase
  Future<void> syncHealthData(HealthData healthData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Check privacy settings before syncing
      final privacy = await _supporterProfileService.getSupporterPrivacySettings(user.uid);
      if (privacy == null || !privacy.showWorkoutStats) {
        _logger.d('Health data sync skipped due to privacy settings');
        return;
      }

      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await _firestore
          .collection('health_data')
          .doc(user.uid)
          .collection('daily_data')
          .doc(dateKey)
          .set({
        ...healthData.toJson(),
        'syncedAt': Timestamp.now(),
        'date': Timestamp.fromDate(today),
      });

      _logger.d('Health data synced successfully for $dateKey');
    } catch (e) {
      _logger.e('Failed to sync health data: $e');
      // Don't throw - sync failures shouldn't block the app
    }
  }

  /// Sync daily meals to Firebase (bypassing privacy for testing)
  Future<void> syncDailyMealsForce(Map<String, List<Map<String, dynamic>>> dailyMeals) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.w('Daily meals sync skipped - user not authenticated');
        return;
      }

      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      _logger.d('FORCE syncing to collection: daily_meals/${user.uid}/meals/$dateKey');
      _logger.d('Daily meals to force sync: $dailyMeals');

      final dataToWrite = {
        'breakfast': dailyMeals['breakfast'] ?? [],
        'lunch': dailyMeals['lunch'] ?? [],
        'dinner': dailyMeals['dinner'] ?? [],
        'snacks': dailyMeals['snacks'] ?? [],
        'syncedAt': Timestamp.now(),
        'date': Timestamp.fromDate(today),
      };
      
      _logger.d('Writing data to Firebase: $dataToWrite');

      await _firestore
          .collection('daily_meals')
          .doc(user.uid)
          .collection('meals')
          .doc(dateKey)
          .set(dataToWrite);

      _logger.d('✅ Daily meals FORCE synced successfully for $dateKey');
      _logger.d('✅ Firebase collection: daily_meals/${user.uid}/meals/$dateKey should now exist!');
    } catch (e) {
      _logger.e('Failed to FORCE sync daily meals: $e');
      // Don't throw - sync failures shouldn't block the app
    }
  }

  /// Sync daily meals to Firebase
  Future<void> syncDailyMeals(Map<String, List<Map<String, dynamic>>> dailyMeals) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.w('Daily meals sync skipped - user not authenticated');
        return;
      }

      _logger.d('=== DATASYNC DEBUG ===');
      _logger.d('User ID: ${user.uid}');
      _logger.d('Daily meals to sync: $dailyMeals');

      // Check privacy settings before syncing
      final privacy = await _supporterProfileService.getSupporterPrivacySettings(user.uid);
      _logger.d('Privacy settings: $privacy');
      _logger.d('Show nutrition stats: ${privacy?.showNutritionStats}');
      
      // Initialize privacy settings if they don't exist
      if (privacy == null) {
        _logger.w('Privacy settings not found, initializing defaults...');
        await initializePrivacySettings();
        // Try to get privacy settings again
        final newPrivacy = await _supporterProfileService.getSupporterPrivacySettings(user.uid);
        _logger.d('New privacy settings: $newPrivacy');
        if (newPrivacy == null || !newPrivacy.showNutritionStats) {
          _logger.w('Daily meals sync skipped - still no valid privacy settings');
          return;
        }
      } else if (!privacy.showNutritionStats) {
        _logger.w('Daily meals sync skipped due to privacy settings - showNutritionStats: false');
        return;
      }

      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      _logger.d('Syncing to collection: daily_meals/${user.uid}/meals/$dateKey');

      await _firestore
          .collection('daily_meals')
          .doc(user.uid)
          .collection('meals')
          .doc(dateKey)
          .set({
        'breakfast': dailyMeals['breakfast'] ?? [],
        'lunch': dailyMeals['lunch'] ?? [],
        'dinner': dailyMeals['dinner'] ?? [],
        'snacks': dailyMeals['snacks'] ?? [],
        'syncedAt': Timestamp.now(),
        'date': Timestamp.fromDate(today),
      });

      _logger.d('Daily meals synced successfully for $dateKey');
    } catch (e) {
      _logger.e('Failed to sync daily meals: $e');
      // Don't throw - sync failures shouldn't block the app
    }
  }

  /// Sync user's achievements to Firebase
  Future<void> syncAchievements(List<Achievement> achievements) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Check privacy settings before syncing
      final privacy = await _supporterProfileService.getSupporterPrivacySettings(user.uid);
      if (privacy == null || !privacy.showAchievements) {
        _logger.d('Achievements sync skipped due to privacy settings');
        return;
      }

      await _firestore
          .collection('achievements')
          .doc(user.uid)
          .set({
        'unlocked': achievements.map((a) => a.toJson()).toList(),
        'lastUpdated': Timestamp.now(),
        'totalCount': achievements.where((a) => a.isUnlocked).length,
      });

      _logger.d('Achievements synced successfully');
    } catch (e) {
      _logger.e('Failed to sync achievements: $e');
      // Don't throw - sync failures shouldn't block the app
    }
  }

  /// Sync user's profile information for supporters
  Future<void> syncPublicProfile({
    required String displayName,
    required String? avatarUrl,
    required int currentLevel,
    required int currentStrikes,
    required double ecoScore,
    required int supporterCount,
    required int supportingCount,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Check privacy settings
      final privacy = await _supporterProfileService.getSupporterPrivacySettings(user.uid);
      
      await _firestore
          .collection('public_profiles')
          .doc(user.uid)
          .set({
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'currentLevel': currentLevel,
        'currentStrikes': privacy?.showWorkoutStats == true ? currentStrikes : null,
        'ecoScore': privacy?.showEcoScore == true ? ecoScore : null,
        'supporterCount': supporterCount,
        'supportingCount': supportingCount,
        'lastOnlineAt': Timestamp.now(),
        'isOnline': true,
        'lastUpdated': Timestamp.now(),
      });

      _logger.d('Public profile synced successfully');
    } catch (e) {
      _logger.e('Failed to sync public profile: $e');
      // Don't throw - sync failures shouldn't block the app
    }
  }

  /// Initialize default privacy settings for new users
  Future<void> initializePrivacySettings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Check if privacy settings already exist
      final existing = await _firestore
          .collection('privacy_settings')
          .doc(user.uid)
          .get();

      if (!existing.exists) {
        final defaultSettings = PrivacySettings(
          userId: user.uid,
          showWorkoutStats: true,
          showNutritionStats: true,
          showEcoScore: true,
          showAchievements: true,
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection('privacy_settings')
            .doc(user.uid)
            .set(defaultSettings.toFirestore());

        _logger.d('Default privacy settings initialized');
      }
    } catch (e) {
      _logger.e('Failed to initialize privacy settings: $e');
    }
  }

  /// Mark user as offline when app goes to background
  Future<void> markUserOffline() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('public_profiles')
          .doc(user.uid)
          .update({
        'isOnline': false,
        'lastOnlineAt': Timestamp.now(),
      });

      _logger.d('User marked as offline');
    } catch (e) {
      _logger.e('Failed to mark user offline: $e');
    }
  }

  /// Comprehensive sync of all user data (called periodically or when data changes)
  Future<void> syncAllUserData({
    UserProgress? progress,
    HealthData? healthData,
    List<Achievement>? achievements,
    Map<String, List<Map<String, dynamic>>>? dailyMeals,
    String? displayName,
    String? avatarUrl,
    int? currentLevel,
    int? currentStrikes,
    double? ecoScore,
    int? supporterCount,
    int? supportingCount,
  }) async {
    try {
      _logger.d('Starting comprehensive data sync...');

      // Sync in parallel for better performance
      final futures = <Future>[];

      if (progress != null) {
        futures.add(syncUserProgress(progress));
      }

      if (healthData != null) {
        futures.add(syncHealthData(healthData));
      }

      if (achievements != null) {
        futures.add(syncAchievements(achievements));
      }

      if (dailyMeals != null) {
        futures.add(syncDailyMeals(dailyMeals));
      }

      if (displayName != null) {
        futures.add(syncPublicProfile(
          displayName: displayName,
          avatarUrl: avatarUrl,
          currentLevel: currentLevel ?? 1,
          currentStrikes: currentStrikes ?? 0,
          ecoScore: ecoScore ?? 0.0,
          supporterCount: supporterCount ?? 0,
          supportingCount: supportingCount ?? 0,
        ));
      }

      await Future.wait(futures);
      _logger.d('Comprehensive data sync completed');
    } catch (e) {
      _logger.e('Failed during comprehensive sync: $e');
    }
  }

  /// Start periodic sync (called when app starts)
  void startPeriodicSync() {
    // Note: This would typically use a timer or background service
    // For now, we'll rely on manual sync calls when data changes
    _logger.d('Periodic sync service initialized');
  }

  /// Stop periodic sync (called when app closes)
  void stopPeriodicSync() {
    _logger.d('Periodic sync service stopped');
  }
}

/// Extension to make sync calls easier from existing code
extension DataSyncExtensions on UserProgress {
  Future<void> syncToFirebase() async {
    await DataSyncService().syncUserProgress(this);
  }
}

extension HealthDataSyncExtensions on HealthData {
  Future<void> syncToFirebase() async {
    await DataSyncService().syncHealthData(this);
  }
}