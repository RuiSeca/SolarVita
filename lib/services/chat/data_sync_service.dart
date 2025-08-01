import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';
import 'dart:io';
import '../../models/user/user_progress.dart';
import '../../models/health/health_data.dart';
import '../../models/user/privacy_settings.dart';
import '../database/supporter_profile_service.dart';

/// Service responsible for synchronizing local user data with Firebase
/// for supporter visibility and real-time updates
class DataSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final SupporterProfileService _supporterProfileService =
      SupporterProfileService();
  final Logger _logger = Logger();

  static final DataSyncService _instance = DataSyncService._internal();
  factory DataSyncService() => _instance;
  DataSyncService._internal();

  /// Sync current user's progress data to Firebase
  Future<void> syncUserProgress(UserProgress progress) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('user_progress').doc(user.uid).set({
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
      final privacy = await _supporterProfileService
          .getSupporterPrivacySettings(user.uid);
      if (privacy == null || !privacy.showWorkoutStats) {
        _logger.d('Health data sync skipped due to privacy settings');
        return;
      }

      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

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

  /// Upload image to Firebase Storage and return the download URL
  Future<String?> uploadMealImage(String? localImagePath) async {
    try {
      final user = _auth.currentUser;
      if (user == null || localImagePath == null || localImagePath.isEmpty) {
        return null;
      }

      final file = File(localImagePath);
      if (!file.existsSync()) return null;

      // Create a unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'meal_${user.uid}_$timestamp.jpg';
      final storageRef = _storage.ref().child('meal_images').child(fileName);

      // Upload the file
      final uploadTask = await storageRef.putFile(file);

      // Get the download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      _logger.e('Failed to upload image: $e');
      return null;
    }
  }

  /// Process meals to upload images and replace local paths with Firebase URLs
  Future<Map<String, List<Map<String, dynamic>>>> _processMealsForSync(
    Map<String, List<Map<String, dynamic>>> dailyMeals,
  ) async {
    final processedMeals = <String, List<Map<String, dynamic>>>{};

    for (final mealTimeEntry in dailyMeals.entries) {
      final mealTime = mealTimeEntry.key;
      final meals = mealTimeEntry.value;

      final processedMealsList = <Map<String, dynamic>>[];

      for (final meal in meals) {
        final processedMeal = Map<String, dynamic>.from(meal);

        // Check if meal has a local image path
        final imagePath = meal['imagePath'] ?? meal['image'];
        if (imagePath != null && _isLocalPath(imagePath)) {
          // Upload image and replace path with Firebase URL
          final downloadUrl = await uploadMealImage(imagePath);
          if (downloadUrl != null) {
            processedMeal['imagePath'] = downloadUrl;
            processedMeal['image'] = downloadUrl;
          } else {
            // Remove image path if upload failed
            processedMeal.remove('imagePath');
            processedMeal.remove('image');
          }
        }

        processedMealsList.add(processedMeal);
      }

      processedMeals[mealTime] = processedMealsList;
    }

    return processedMeals;
  }

  /// Helper method to check if a path is local
  bool _isLocalPath(String? path) {
    if (path == null || path.isEmpty) return false;
    return path.startsWith('/') || path.startsWith('file://');
  }

  /// Sync daily meals to Firebase and return processed meals with Firebase URLs
  Future<Map<String, List<Map<String, dynamic>>>?> syncDailyMealsWithReturn(
    Map<String, List<Map<String, dynamic>>> dailyMeals,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Check privacy settings before syncing
      final privacy = await _supporterProfileService
          .getSupporterPrivacySettings(user.uid);

      // Initialize privacy settings if they don't exist
      if (privacy == null) {
        await initializePrivacySettings();
        // Try to get privacy settings again
        final newPrivacy = await _supporterProfileService
            .getSupporterPrivacySettings(user.uid);
        if (newPrivacy == null || !newPrivacy.showNutritionStats) {
          return null;
        }
      } else if (!privacy.showNutritionStats) {
        return null;
      }

      // Process meals to upload images before syncing
      final processedMeals = await _processMealsForSync(dailyMeals);

      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await _firestore
          .collection('daily_meals')
          .doc(user.uid)
          .collection('meals')
          .doc(dateKey)
          .set({
            'breakfast': processedMeals['breakfast'] ?? [],
            'lunch': processedMeals['lunch'] ?? [],
            'dinner': processedMeals['dinner'] ?? [],
            'snacks': processedMeals['snacks'] ?? [],
            'syncedAt': Timestamp.now(),
            'date': Timestamp.fromDate(today),
          });

      return processedMeals;
    } catch (e) {
      _logger.e('Failed to sync daily meals: $e');
      return null;
    }
  }

  /// Sync daily meals to Firebase
  Future<void> syncDailyMeals(
    Map<String, List<Map<String, dynamic>>> dailyMeals,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Check privacy settings before syncing
      final privacy = await _supporterProfileService
          .getSupporterPrivacySettings(user.uid);

      // Initialize privacy settings if they don't exist
      if (privacy == null) {
        await initializePrivacySettings();
        // Try to get privacy settings again
        final newPrivacy = await _supporterProfileService
            .getSupporterPrivacySettings(user.uid);
        if (newPrivacy == null || !newPrivacy.showNutritionStats) {
          return;
        }
      } else if (!privacy.showNutritionStats) {
        return;
      }

      // Process meals to upload images before syncing
      final processedMeals = await _processMealsForSync(dailyMeals);

      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await _firestore
          .collection('daily_meals')
          .doc(user.uid)
          .collection('meals')
          .doc(dateKey)
          .set({
            'breakfast': processedMeals['breakfast'] ?? [],
            'lunch': processedMeals['lunch'] ?? [],
            'dinner': processedMeals['dinner'] ?? [],
            'snacks': processedMeals['snacks'] ?? [],
            'syncedAt': Timestamp.now(),
            'date': Timestamp.fromDate(today),
          });

      _logger.d('Daily meals synced successfully with images uploaded');
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
      final privacy = await _supporterProfileService
          .getSupporterPrivacySettings(user.uid);
      if (privacy == null || !privacy.showAchievements) {
        _logger.d('Achievements sync skipped due to privacy settings');
        return;
      }

      await _firestore.collection('achievements').doc(user.uid).set({
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
      final privacy = await _supporterProfileService
          .getSupporterPrivacySettings(user.uid);

      await _firestore.collection('public_profiles').doc(user.uid).set({
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'currentLevel': currentLevel,
        'currentStrikes': privacy?.showWorkoutStats == true
            ? currentStrikes
            : null,
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

      await _firestore.collection('public_profiles').doc(user.uid).update({
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
        futures.add(
          syncPublicProfile(
            displayName: displayName,
            avatarUrl: avatarUrl,
            currentLevel: currentLevel ?? 1,
            currentStrikes: currentStrikes ?? 0,
            ecoScore: ecoScore ?? 0.0,
            supporterCount: supporterCount ?? 0,
            supportingCount: supportingCount ?? 0,
          ),
        );
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
