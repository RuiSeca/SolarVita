import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user/privacy_settings.dart';
import '../../models/user/user_progress.dart';
import '../../models/health/health_data.dart';

class SupporterProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get supporter's privacy settings
  Future<PrivacySettings?> getSupporterPrivacySettings(
    String supporterId,
  ) async {
    try {
      final doc = await _firestore
          .collection('privacy_settings')
          .doc(supporterId)
          .get();

      if (doc.exists) {
        return PrivacySettings.fromFirestore(doc);
      }

      // Return default privacy settings if none exist
      return PrivacySettings(userId: supporterId, updatedAt: DateTime.now());
    } catch (e) {
      throw Exception('Failed to load privacy settings: $e');
    }
  }

  /// Get supporter's progress data (if privacy allows)
  Future<UserProgress?> getSupporterProgress(
    String supporterId,
    PrivacySettings privacy,
  ) async {
    try {
      if (!privacy.showWorkoutStats) {
        return null; // Privacy doesn't allow sharing workout stats
      }

      final doc = await _firestore
          .collection('user_progress')
          .doc(supporterId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return UserProgress.fromJson(data);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to load supporter progress: $e');
    }
  }

  /// Get supporter's health data (if privacy allows)
  Future<HealthData?> getSupporterHealthData(
    String supporterId,
    PrivacySettings privacy,
  ) async {
    try {
      if (!privacy.showWorkoutStats) {
        return null; // Privacy doesn't allow sharing health data
      }

      // Get today's health data
      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final doc = await _firestore
          .collection('health_data')
          .doc(supporterId)
          .collection('daily_data')
          .doc(dateKey)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return HealthData.fromJson(data);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to load supporter health data: $e');
    }
  }

  /// Get supporter's daily meals
  Future<Map<String, List<Map<String, dynamic>>>?> getSupporterDailyMeals(
    String supporterId,
    PrivacySettings privacy,
  ) async {
    try {
      if (!privacy.showNutritionStats) {
        return null;
      }

      // Get today's meals
      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final doc = await _firestore
          .collection('daily_meals')
          .doc(supporterId)
          .collection('meals')
          .doc(dateKey)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        // Convert the data to the expected format
        final mealsData = <String, List<Map<String, dynamic>>>{
          'breakfast': [],
          'lunch': [],
          'dinner': [],
          'snacks': [],
        };

        for (final mealType in mealsData.keys) {
          final meals = data[mealType] as List<dynamic>?;
          if (meals != null) {
            mealsData[mealType] = meals
                .map((meal) => meal as Map<String, dynamic>)
                .toList();
          }
        }

        return mealsData;
      }

      return null;
    } catch (e) {
      throw Exception('Failed to load supporter daily meals: $e');
    }
  }

  /// Get supporter's weekly summary data
  Future<Map<String, dynamic>?> getSupporterWeeklyData(
    String supporterId,
    PrivacySettings privacy,
  ) async {
    try {
      if (!privacy.showWorkoutStats) {
        return null;
      }

      // Calculate week range
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));

      // Query health data for the week
      final query = await _firestore
          .collection('health_data')
          .doc(supporterId)
          .collection('daily_data')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(weekEnd))
          .get();

      int totalSteps = 0;
      int totalActiveMinutes = 0;
      int totalCalories = 0;
      int activeDays = 0;

      for (final doc in query.docs) {
        final data = doc.data();
        totalSteps += (data['steps'] as int? ?? 0);
        totalActiveMinutes += (data['activeMinutes'] as int? ?? 0);
        totalCalories += (data['caloriesBurned'] as int? ?? 0);

        // Count as active day if user had any meaningful activity
        if ((data['steps'] as int? ?? 0) > 1000) {
          activeDays++;
        }
      }

      return {
        'steps': totalSteps,
        'activeMinutes': totalActiveMinutes,
        'calories': totalCalories,
        'streak': activeDays,
      };
    } catch (e) {
      throw Exception('Failed to load weekly data: $e');
    }
  }

  /// Get supporter's achievements
  Future<List<Achievement>?> getSupporterAchievements(
    String supporterId,
    PrivacySettings privacy,
  ) async {
    try {
      if (!privacy.showAchievements) {
        return null;
      }

      final doc = await _firestore
          .collection('achievements')
          .doc(supporterId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final achievementsList = data['unlocked'] as List<dynamic>? ?? [];

        return achievementsList.map((achievement) {
          return Achievement.fromJson(achievement as Map<String, dynamic>);
        }).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to load achievements: $e');
    }
  }

  /// Save/update user's privacy settings
  Future<void> updatePrivacySettings(PrivacySettings settings) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('privacy_settings')
          .doc(currentUser.uid)
          .set(settings.toFirestore());
    } catch (e) {
      throw Exception('Failed to update privacy settings: $e');
    }
  }

  /// Update user's public profile data that supporters can see
  Future<void> updatePublicProfile(Map<String, dynamic> profileData) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('public_profiles')
          .doc(currentUser.uid)
          .set(profileData);
    } catch (e) {
      throw Exception('Failed to update public profile: $e');
    }
  }

  /// Share health data with supporters (called after daily sync)
  Future<void> shareHealthDataWithSupporters(
    HealthData healthData,
    UserProgress progress,
  ) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Get user's privacy settings
      final privacy = await getSupporterPrivacySettings(currentUser.uid);
      if (privacy == null || !privacy.showWorkoutStats) {
        return; // User doesn't want to share workout stats
      }

      // Save to shared health data collection
      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await _firestore
          .collection('health_data')
          .doc(currentUser.uid)
          .collection('daily_data')
          .doc(dateKey)
          .set({...healthData.toJson(), 'sharedAt': Timestamp.now()});

      // Update progress data
      await _firestore
          .collection('user_progress')
          .doc(currentUser.uid)
          .set(progress.toJson());
    } catch (e) {
      // Don't throw error for sharing failures - it's not critical
      // Silently continue as this is not critical functionality
    }
  }

  /// Get comprehensive supporter profile data
  Future<SupporterProfileData> getSupporterProfileData(
    String supporterId,
  ) async {
    try {
      // Load privacy settings first
      final privacy = await getSupporterPrivacySettings(supporterId);
      if (privacy == null) {
        throw Exception('Unable to load supporter privacy settings');
      }

      // Load data based on privacy settings
      final progress = await getSupporterProgress(supporterId, privacy);
      final healthData = await getSupporterHealthData(supporterId, privacy);
      final weeklyData = await getSupporterWeeklyData(supporterId, privacy);
      final achievements = await getSupporterAchievements(supporterId, privacy);
      final dailyMeals = await getSupporterDailyMeals(supporterId, privacy);

      return SupporterProfileData(
        privacySettings: privacy,
        progress: progress,
        healthData: healthData,
        weeklyData: weeklyData,
        achievements: achievements,
        dailyMeals: dailyMeals,
      );
    } catch (e) {
      throw Exception('Failed to load supporter profile data: $e');
    }
  }
}

/// Comprehensive supporter profile data
class SupporterProfileData {
  final PrivacySettings privacySettings;
  final UserProgress? progress;
  final HealthData? healthData;
  final Map<String, dynamic>? weeklyData;
  final List<Achievement>? achievements;
  final Map<String, List<Map<String, dynamic>>>? dailyMeals;

  SupporterProfileData({
    required this.privacySettings,
    this.progress,
    this.healthData,
    this.weeklyData,
    this.achievements,
    this.dailyMeals,
  });
}

/// Achievement model for supporter profiles
class Achievement {
  final String id;
  final String title;
  final String? subtitle;
  final String iconName;
  final String colorName;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    this.subtitle,
    required this.iconName,
    required this.colorName,
    required this.isUnlocked,
    this.unlockedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      iconName: json['iconName'] as String,
      colorName: json['colorName'] as String,
      isUnlocked: json['isUnlocked'] as bool,
      unlockedAt: json['unlockedAt'] != null
          ? (json['unlockedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'iconName': iconName,
      'colorName': colorName,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
    };
  }
}
