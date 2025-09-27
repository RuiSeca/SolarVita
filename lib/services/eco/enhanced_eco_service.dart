import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../models/eco/carbon_activity.dart';
import '../../models/eco/enhanced_eco_metrics.dart';
import '../../models/eco/eco_achievement.dart';

class EnhancedEcoService {
  static final EnhancedEcoService _instance = EnhancedEcoService._internal();
  factory EnhancedEcoService() => _instance;
  EnhancedEcoService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  static const String ecoActivitiesCollection = 'ecoActivities';
  static const String enhancedEcoMetricsCollection = 'enhancedEcoMetrics';
  static const String userAchievementsCollection = 'userAchievements';
  static const String ecoAchievementsCollection = 'ecoAchievements';
  static const String ecoLeaderboardCollection = 'ecoLeaderboard';

  /// Enhanced Metrics Operations

  Stream<EnhancedEcoMetrics> getUserEnhancedMetrics() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value(EnhancedEcoMetrics.empty(''));
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection(enhancedEcoMetricsCollection)
        .doc('current')
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return EnhancedEcoMetrics.fromFirestore(doc);
          } else {
            return EnhancedEcoMetrics.empty(userId);
          }
        });
  }

  Future<void> updateEnhancedMetrics(EcoActivity activity) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final metricsDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection(enhancedEcoMetricsCollection)
          .doc('current')
          .get();

      EnhancedEcoMetrics currentMetrics;
      if (metricsDoc.exists) {
        currentMetrics = EnhancedEcoMetrics.fromFirestore(metricsDoc);
      } else {
        currentMetrics = EnhancedEcoMetrics.empty(userId);
      }

      // Update metrics with new activity
      final updatedMetrics = await _calculateEnhancedMetrics(currentMetrics, activity);

      // Save updated metrics
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(enhancedEcoMetricsCollection)
          .doc('current')
          .set(updatedMetrics.toFirestore());

      // Check for new achievements
      await _checkAndUnlockAchievements(updatedMetrics);

      // Update leaderboard
      await _updateLeaderboard(updatedMetrics);

    } catch (e) {
      debugPrint('Error updating enhanced eco metrics: $e');
    }
  }

  Future<EnhancedEcoMetrics> _calculateEnhancedMetrics(
    EnhancedEcoMetrics current,
    EcoActivity activity,
  ) async {
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    // Update basic metrics
    final newActivityCounts = Map<String, int>.from(current.activityCounts);
    newActivityCounts[activity.activity] = (newActivityCounts[activity.activity] ?? 0) + 1;

    final newMonthlySavings = Map<String, double>.from(current.monthlySavings);
    newMonthlySavings[monthKey] = (newMonthlySavings[monthKey] ?? 0.0) + activity.carbonSaved;

    // Update weekly trends
    final newWeeklyTrends = Map<String, double>.from(current.weeklyTrends);
    newWeeklyTrends['current'] = (newWeeklyTrends['current'] ?? 0.0) + activity.carbonSaved;

    // Update category-specific metrics
    double newMealCarbon = current.mealCarbonSaved;
    double newTransportCarbon = current.transportCarbonSaved;
    double newEnergyCarbon = current.energyCarbonSaved;
    double newWasteCarbon = current.wasteCarbonSaved;

    switch (activity.type) {
      case EcoActivityType.food:
        newMealCarbon += activity.carbonSaved;
        break;
      case EcoActivityType.transport:
        newTransportCarbon += activity.carbonSaved;
        break;
      case EcoActivityType.energy:
        newEnergyCarbon += activity.carbonSaved;
        break;
      case EcoActivityType.waste:
        newWasteCarbon += activity.carbonSaved;
        break;
      case EcoActivityType.consumption:
        // Can be distributed across categories based on metadata
        break;
    }

    // Calculate new totals and XP
    final newTotalCarbon = current.totalCarbonSaved + activity.carbonSaved;
    final newPlasticBottles = _carbonToBottles(newTotalCarbon);
    final newXP = _calculateXP(activity, current);
    final newLevelSystem = EcoLevelSystem.fromXP(current.levelSystem.totalXP + newXP);

    // Update streak calculation
    final newStreak = _calculateStreak(current.currentStreak, current.lastUpdated, now);
    final newLongestStreak = newStreak > current.longestStreak ? newStreak : current.longestStreak;

    // Calculate new eco score
    final newEcoScore = _calculateEcoScore(newTotalCarbon, newActivityCounts.length, newStreak);

    // Update category streaks
    final newCategoryStreaks = Map<String, int>.from(current.categoryStreaks);
    final activityCategory = activity.type.toString().split('.').last;
    newCategoryStreaks[activityCategory] = (newCategoryStreaks[activityCategory] ?? 0) + 1;

    // Update personal bests
    final newPersonalBests = Map<String, double>.from(current.personalBests);
    final dailyKey = 'daily_${now.year}_${now.month}_${now.day}';
    final currentDailySaving = newPersonalBests[dailyKey] ?? 0.0;
    newPersonalBests[dailyKey] = currentDailySaving + activity.carbonSaved;

    if (newPersonalBests[dailyKey]! > (newPersonalBests['daily_best'] ?? 0.0)) {
      newPersonalBests['daily_best'] = newPersonalBests[dailyKey]!;
    }

    // Generate insights and predictions
    final insights = _generateInsights(current, activity);
    final predictions = _generatePredictions(current, activity);

    // Update visualization data with insights
    final visualization = await _updateVisualizationData(current.visualization, activity);
    final updatedVisualization = EcoImpactVisualization(
      dailyData: visualization.dailyData,
      weeklyData: visualization.weeklyData,
      monthlyData: visualization.monthlyData,
      categoryTrends: visualization.categoryTrends,
      comparisons: visualization.comparisons,
      insights: insights,
    );

    // Update milestones
    final milestones = _updateMilestones(current.milestones, newTotalCarbon, newActivityCounts);

    return EnhancedEcoMetrics(
      userId: current.userId,
      totalCarbonSaved: newTotalCarbon,
      plasticBottlesSaved: newPlasticBottles,
      mealCarbonSaved: newMealCarbon,
      transportCarbonSaved: newTransportCarbon,
      energyCarbonSaved: newEnergyCarbon,
      wasteCarbonSaved: newWasteCarbon,
      ecoScore: newEcoScore,
      currentStreak: newStreak,
      longestStreak: newLongestStreak,
      lastUpdated: now,
      activityCounts: newActivityCounts,
      monthlySavings: newMonthlySavings,
      levelSystem: newLevelSystem,
      unlockedAchievements: current.unlockedAchievements,
      weeklyTrends: newWeeklyTrends,
      categoryStreaks: newCategoryStreaks,
      carbonFootprintReduction: _calculateFootprintReduction(newTotalCarbon),
      milestones: milestones,
      personalBests: newPersonalBests,
      visualization: updatedVisualization,
      predictions: predictions,
    );
  }

  /// Achievement System

  Future<void> _checkAndUnlockAchievements(EnhancedEcoMetrics metrics) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final achievements = PredefinedAchievements.achievements;
      final unlockedIds = metrics.unlockedAchievements;

      for (final achievement in achievements) {
        if (unlockedIds.contains(achievement.id)) continue;
        if (!achievement.isAvailable) continue;

        bool shouldUnlock = false;

        switch (achievement.type) {
          case AchievementType.milestone:
            shouldUnlock = _checkMilestoneAchievement(achievement, metrics);
            break;
          case AchievementType.streak:
            shouldUnlock = _checkStreakAchievement(achievement, metrics);
            break;
          case AchievementType.diversity:
            shouldUnlock = _checkDiversityAchievement(achievement, metrics);
            break;
          case AchievementType.community:
            shouldUnlock = await _checkCommunityAchievement(achievement, metrics);
            break;
          case AchievementType.challenge:
            shouldUnlock = _checkChallengeAchievement(achievement, metrics);
            break;
          case AchievementType.seasonal:
            shouldUnlock = _checkSeasonalAchievement(achievement, metrics);
            break;
        }

        if (shouldUnlock) {
          await _unlockAchievement(achievement.id, metrics.userId);
        }
      }
    } catch (e) {
      debugPrint('Error checking achievements: $e');
    }
  }

  bool _checkMilestoneAchievement(EcoAchievement achievement, EnhancedEcoMetrics metrics) {
    final carbonTarget = achievement.criteria['carbonSaved'] as double?;
    if (carbonTarget != null) {
      return metrics.totalCarbonSaved >= carbonTarget;
    }
    return false;
  }

  bool _checkStreakAchievement(EcoAchievement achievement, EnhancedEcoMetrics metrics) {
    final streakTarget = achievement.criteria['streak'] as int?;
    if (streakTarget != null) {
      return metrics.currentStreak >= streakTarget;
    }
    return false;
  }

  bool _checkDiversityAchievement(EcoAchievement achievement, EnhancedEcoMetrics metrics) {
    final uniqueActivitiesTarget = achievement.criteria['uniqueActivities'] as int?;
    final carbonTarget = achievement.criteria['carbonSaved'] as double?;

    bool uniqueActivitiesMet = uniqueActivitiesTarget == null ||
        metrics.activityCounts.length >= uniqueActivitiesTarget;
    bool carbonMet = carbonTarget == null ||
        metrics.totalCarbonSaved >= carbonTarget;

    return uniqueActivitiesMet && carbonMet;
  }

  Future<bool> _checkCommunityAchievement(EcoAchievement achievement, EnhancedEcoMetrics metrics) async {
    final userId = currentUserId;
    if (userId == null) return false;

    // Check circles joined
    final circlesTarget = achievement.criteria['circlesJoined'] as int?;
    if (circlesTarget != null) {
      final circlesSnapshot = await _firestore
          .collection('supporterCircles')
          .where('members', arrayContains: userId)
          .get();
      return circlesSnapshot.docs.length >= circlesTarget;
    }

    // Check recipes shared
    final recipesTarget = achievement.criteria['recipesShared'] as int?;
    if (recipesTarget != null) {
      final recipesSnapshot = await _firestore
          .collection('communityRecipes')
          .where('creatorId', isEqualTo: userId)
          .get();
      return recipesSnapshot.docs.length >= recipesTarget;
    }

    return false;
  }

  bool _checkChallengeAchievement(EcoAchievement achievement, EnhancedEcoMetrics metrics) {
    final plantBasedMeals = achievement.criteria['plantBasedMeals'] as int?;
    final timeframe = achievement.criteria['timeframe'] as int?;

    if (plantBasedMeals != null && timeframe != null) {
      // Check if user had required plant-based meals in the timeframe
      final plantBasedCount = metrics.activityCounts['plantBasedMeal'] ?? 0;
      return plantBasedCount >= plantBasedMeals;
    }

    return false;
  }

  bool _checkSeasonalAchievement(EcoAchievement achievement, EnhancedEcoMetrics metrics) {
    // Implement seasonal achievement logic
    return false;
  }

  Future<void> _unlockAchievement(String achievementId, String userId) async {
    try {
      final userAchievement = UserAchievement(
        id: '',
        userId: userId,
        achievementId: achievementId,
        unlockedAt: DateTime.now(),
        progress: 1.0,
        isCompleted: true,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection(userAchievementsCollection)
          .add(userAchievement.toFirestore());

      // Update user's unlocked achievements list in metrics
      final metricsDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection(enhancedEcoMetricsCollection)
          .doc('current')
          .get();

      if (metricsDoc.exists) {
        final currentMetrics = EnhancedEcoMetrics.fromFirestore(metricsDoc);
        final updatedAchievements = List<String>.from(currentMetrics.unlockedAchievements)
          ..add(achievementId);

        await metricsDoc.reference.update({
          'unlockedAchievements': updatedAchievements,
        });
      }

      debugPrint('Achievement unlocked: $achievementId for user: $userId');
    } catch (e) {
      debugPrint('Error unlocking achievement: $e');
    }
  }

  /// User Achievements

  Stream<List<UserAchievement>> getUserAchievements() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection(userAchievementsCollection)
        .orderBy('unlockedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserAchievement.fromFirestore(doc))
            .toList());
  }

  Future<List<EcoAchievement>> getAvailableAchievements() async {
    return PredefinedAchievements.achievements
        .where((achievement) => achievement.isAvailable)
        .toList();
  }

  /// Leaderboard

  Future<void> _updateLeaderboard(EnhancedEcoMetrics metrics) async {
    try {
      await _firestore
          .collection(ecoLeaderboardCollection)
          .doc(metrics.userId)
          .set({
        'userId': metrics.userId,
        'totalCarbonSaved': metrics.totalCarbonSaved,
        'ecoScore': metrics.ecoScore,
        'level': metrics.levelSystem.level,
        'currentStreak': metrics.currentStreak,
        'achievementCount': metrics.unlockedAchievements.length,
        'lastUpdated': Timestamp.fromDate(metrics.lastUpdated),
      });
    } catch (e) {
      debugPrint('Error updating leaderboard: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getLeaderboard({int limit = 50}) {
    return _firestore
        .collection(ecoLeaderboardCollection)
        .orderBy('ecoScore', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data())
            .toList());
  }

  /// Helper Methods

  int _carbonToBottles(double carbonKg) {
    return (carbonKg / 0.2).round();
  }

  int _calculateXP(EcoActivity activity, EnhancedEcoMetrics current) {
    int baseXP = (activity.carbonSaved * 10).round();

    // Bonus XP for streaks
    if (current.currentStreak > 0) {
      baseXP += (current.currentStreak * 2);
    }

    // Bonus XP for trying new activities
    if (!current.activityCounts.containsKey(activity.activity)) {
      baseXP += 50; // First time bonus
    }

    return baseXP;
  }

  int _calculateStreak(int currentStreak, DateTime lastUpdated, DateTime now) {
    final daysSinceLastUpdate = now.difference(lastUpdated).inDays;

    if (daysSinceLastUpdate == 0) {
      return currentStreak;
    } else if (daysSinceLastUpdate == 1) {
      return currentStreak + 1;
    } else {
      return 1;
    }
  }

  int _calculateEcoScore(double totalCarbon, int activityCount, int streak) {
    final carbonScore = (totalCarbon * 2).clamp(0, 60).toInt();
    final diversityScore = (activityCount * 2).clamp(0, 20).toInt();
    final streakScore = (streak).clamp(0, 20).toInt();
    return (carbonScore + diversityScore + streakScore).clamp(0, 100);
  }


  double _calculateFootprintReduction(double totalCarbonSaved) {
    // Assume average person's annual carbon footprint is 4 tons (4000 kg)
    const averageAnnualFootprint = 4000.0;
    return (totalCarbonSaved / averageAnnualFootprint) * 100;
  }

  List<String> _generateInsights(EnhancedEcoMetrics current, EcoActivity activity) {
    final insights = <String>[];

    if (current.currentStreak >= 7) {
      insights.add('You\'re on a ${current.currentStreak}-day streak! Keep it up!');
    }

    if (activity.carbonSaved > (current.personalBests['daily_best'] ?? 0.0)) {
      insights.add('New personal best for daily carbon savings!');
    }

    final categoryBreakdown = current.categoryBreakdown;
    final topCategory = categoryBreakdown.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    insights.add('Your biggest impact category is ${topCategory.key}');

    return insights;
  }

  Map<String, dynamic> _generatePredictions(EnhancedEcoMetrics current, EcoActivity activity) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysPassed = now.day;
    final daysRemaining = daysInMonth - daysPassed;

    final currentMonthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final currentMonthlySaving = current.monthlySavings[currentMonthKey] ?? 0.0;

    final dailyAverage = daysPassed > 0 ? currentMonthlySaving / daysPassed : 0.0;
    final projectedMonthly = dailyAverage * daysInMonth;

    return {
      'projectedMonthlySavings': projectedMonthly,
      'onTrackForGoal': projectedMonthly >= 5.0, // 5kg monthly goal
      'recommendedDailyTarget': (5.0 - currentMonthlySaving) / daysRemaining.clamp(1, 31),
    };
  }

  Future<EcoImpactVisualization> _updateVisualizationData(
    EcoImpactVisualization current,
    EcoActivity activity,
  ) async {
    final now = DateTime.now();

    // Add new data point
    final newDataPoint = EcoDataPoint(
      date: now,
      value: activity.carbonSaved,
      category: activity.type.toString().split('.').last,
    );

    // Update daily data (keep last 30 days)
    final updatedDailyData = List<EcoDataPoint>.from(current.dailyData)
      ..add(newDataPoint)
      ..sort((a, b) => a.date.compareTo(b.date));

    if (updatedDailyData.length > 30) {
      updatedDailyData.removeRange(0, updatedDailyData.length - 30);
    }

    return EcoImpactVisualization(
      dailyData: updatedDailyData,
      weeklyData: current.weeklyData, // Would aggregate daily data
      monthlyData: current.monthlyData, // Would aggregate weekly data
      categoryTrends: current.categoryTrends,
      comparisons: current.comparisons,
      insights: current.insights, // Keep existing insights for now
    );
  }

  List<EcoMilestone> _updateMilestones(
    List<EcoMilestone> current,
    double totalCarbon,
    Map<String, int> activityCounts,
  ) {
    return current.map((milestone) {
      double newCurrentValue = milestone.currentValue;

      switch (milestone.category) {
        case 'carbon':
          newCurrentValue = totalCarbon;
          break;
        case 'activities':
          newCurrentValue = activityCounts.length.toDouble();
          break;
      }

      final isAchieved = newCurrentValue >= milestone.targetValue;

      return EcoMilestone(
        id: milestone.id,
        name: milestone.name,
        description: milestone.description,
        targetValue: milestone.targetValue,
        currentValue: newCurrentValue,
        isAchieved: isAchieved,
        achievedAt: isAchieved && !milestone.isAchieved ? DateTime.now() : milestone.achievedAt,
        category: milestone.category,
        icon: milestone.icon,
        color: milestone.color,
      );
    }).toList();
  }
}