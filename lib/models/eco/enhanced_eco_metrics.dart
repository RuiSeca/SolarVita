import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'eco_achievement.dart';

class EnhancedEcoMetrics {
  final String userId;
  final double totalCarbonSaved;
  final int plasticBottlesSaved;
  final double mealCarbonSaved;
  final double transportCarbonSaved;
  final double energyCarbonSaved;
  final double wasteCarbonSaved;
  final int ecoScore;
  final int currentStreak;
  final int longestStreak;
  final DateTime lastUpdated;
  final Map<String, int> activityCounts;
  final Map<String, double> monthlySavings;

  // Enhanced fields
  final EcoLevelSystem levelSystem;
  final List<String> unlockedAchievements;
  final Map<String, double> weeklyTrends;
  final Map<String, int> categoryStreaks;
  final double carbonFootprintReduction;
  final List<EcoMilestone> milestones;
  final Map<String, double> personalBests;
  final EcoImpactVisualization visualization;
  final Map<String, dynamic> predictions;

  const EnhancedEcoMetrics({
    required this.userId,
    required this.totalCarbonSaved,
    required this.plasticBottlesSaved,
    required this.mealCarbonSaved,
    required this.transportCarbonSaved,
    required this.energyCarbonSaved,
    required this.wasteCarbonSaved,
    required this.ecoScore,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastUpdated,
    required this.activityCounts,
    required this.monthlySavings,
    required this.levelSystem,
    required this.unlockedAchievements,
    required this.weeklyTrends,
    required this.categoryStreaks,
    required this.carbonFootprintReduction,
    required this.milestones,
    required this.personalBests,
    required this.visualization,
    required this.predictions,
  });

  factory EnhancedEcoMetrics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EnhancedEcoMetrics(
      userId: data['userId'] ?? '',
      totalCarbonSaved: (data['totalCarbonSaved'] ?? 0.0).toDouble(),
      plasticBottlesSaved: data['plasticBottlesSaved'] ?? 0,
      mealCarbonSaved: (data['mealCarbonSaved'] ?? 0.0).toDouble(),
      transportCarbonSaved: (data['transportCarbonSaved'] ?? 0.0).toDouble(),
      energyCarbonSaved: (data['energyCarbonSaved'] ?? 0.0).toDouble(),
      wasteCarbonSaved: (data['wasteCarbonSaved'] ?? 0.0).toDouble(),
      ecoScore: data['ecoScore'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      activityCounts: Map<String, int>.from(data['activityCounts'] ?? {}),
      monthlySavings: Map<String, double>.from(data['monthlySavings'] ?? {}),
      levelSystem: EcoLevelSystem.fromFirestore(data['levelSystem'] ?? {}),
      unlockedAchievements: List<String>.from(data['unlockedAchievements'] ?? []),
      weeklyTrends: Map<String, double>.from(data['weeklyTrends'] ?? {}),
      categoryStreaks: Map<String, int>.from(data['categoryStreaks'] ?? {}),
      carbonFootprintReduction: (data['carbonFootprintReduction'] ?? 0.0).toDouble(),
      milestones: (data['milestones'] as List<dynamic>? ?? [])
          .map((m) => EcoMilestone.fromMap(m))
          .toList(),
      personalBests: Map<String, double>.from(data['personalBests'] ?? {}),
      visualization: EcoImpactVisualization.fromMap(data['visualization'] ?? {}),
      predictions: Map<String, dynamic>.from(data['predictions'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'totalCarbonSaved': totalCarbonSaved,
      'plasticBottlesSaved': plasticBottlesSaved,
      'mealCarbonSaved': mealCarbonSaved,
      'transportCarbonSaved': transportCarbonSaved,
      'energyCarbonSaved': energyCarbonSaved,
      'wasteCarbonSaved': wasteCarbonSaved,
      'ecoScore': ecoScore,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'activityCounts': activityCounts,
      'monthlySavings': monthlySavings,
      'levelSystem': levelSystem.toFirestore(),
      'unlockedAchievements': unlockedAchievements,
      'weeklyTrends': weeklyTrends,
      'categoryStreaks': categoryStreaks,
      'carbonFootprintReduction': carbonFootprintReduction,
      'milestones': milestones.map((m) => m.toMap()).toList(),
      'personalBests': personalBests,
      'visualization': visualization.toMap(),
      'predictions': predictions,
    };
  }

  factory EnhancedEcoMetrics.empty(String userId) {
    return EnhancedEcoMetrics(
      userId: userId,
      totalCarbonSaved: 0.0,
      plasticBottlesSaved: 0,
      mealCarbonSaved: 0.0,
      transportCarbonSaved: 0.0,
      energyCarbonSaved: 0.0,
      wasteCarbonSaved: 0.0,
      ecoScore: 0,
      currentStreak: 0,
      longestStreak: 0,
      lastUpdated: DateTime.now(),
      activityCounts: {},
      monthlySavings: {},
      levelSystem: EcoLevelSystem.fromXP(0),
      unlockedAchievements: [],
      weeklyTrends: {},
      categoryStreaks: {},
      carbonFootprintReduction: 0.0,
      milestones: [],
      personalBests: {},
      visualization: EcoImpactVisualization.empty(),
      predictions: {},
    );
  }

  // Calculate trees saved equivalent
  int get treesSaved => (totalCarbonSaved / 21.77).round(); // Average tree absorbs 21.77kg CO2/year

  // Calculate car miles avoided
  double get carMilesAvoided => totalCarbonSaved / 0.404; // 0.404 kg CO2 per mile

  // Calculate renewable energy equivalent (kWh)
  double get renewableEnergyEquivalent => totalCarbonSaved / 0.92; // 0.92 kg CO2 per kWh

  // Get category breakdown for visualization
  Map<String, double> get categoryBreakdown => {
    'Food': mealCarbonSaved,
    'Transport': transportCarbonSaved,
    'Energy': energyCarbonSaved,
    'Waste': wasteCarbonSaved,
  };

  // Get this week's progress vs last week
  double get weeklyGrowth {
    final thisWeek = weeklyTrends['current'] ?? 0.0;
    final lastWeek = weeklyTrends['previous'] ?? 0.0;
    if (lastWeek == 0) return thisWeek > 0 ? 100.0 : 0.0;
    return ((thisWeek - lastWeek) / lastWeek) * 100;
  }

  // Check if on track for monthly goal
  bool get onTrackForMonthlyGoal {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysPassed = now.day;
    final progressRatio = daysPassed / daysInMonth;

    final currentMonthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final currentMonthlySaving = monthlySavings[currentMonthKey] ?? 0.0;

    // Assume monthly goal is 5kg CO2 saved
    const monthlyGoal = 5.0;
    final expectedProgress = monthlyGoal * progressRatio;

    return currentMonthlySaving >= expectedProgress;
  }

  // Get impact rank among all users (would need global data)
  String get globalRank {
    if (totalCarbonSaved >= 100) return 'Top 1%';
    if (totalCarbonSaved >= 50) return 'Top 5%';
    if (totalCarbonSaved >= 25) return 'Top 10%';
    if (totalCarbonSaved >= 10) return 'Top 25%';
    return 'Getting Started';
  }
}

class EcoMilestone {
  final String id;
  final String name;
  final String description;
  final double targetValue;
  final double currentValue;
  final bool isAchieved;
  final DateTime? achievedAt;
  final String category;
  final IconData icon;
  final Color color;

  const EcoMilestone({
    required this.id,
    required this.name,
    required this.description,
    required this.targetValue,
    required this.currentValue,
    required this.isAchieved,
    this.achievedAt,
    required this.category,
    required this.icon,
    required this.color,
  });

  factory EcoMilestone.fromMap(Map<String, dynamic> data) {
    return EcoMilestone(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      targetValue: (data['targetValue'] ?? 0.0).toDouble(),
      currentValue: (data['currentValue'] ?? 0.0).toDouble(),
      isAchieved: data['isAchieved'] ?? false,
      achievedAt: data['achievedAt'] != null
          ? (data['achievedAt'] as Timestamp).toDate()
          : null,
      category: data['category'] ?? '',
      icon: IconData(data['iconCodePoint'] ?? Icons.eco.codePoint, fontFamily: 'MaterialIcons'),
      color: Color(data['colorValue'] ?? Colors.green.toARGB32()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'isAchieved': isAchieved,
      'achievedAt': achievedAt != null ? Timestamp.fromDate(achievedAt!) : null,
      'category': category,
      'iconCodePoint': icon.codePoint,
      'colorValue': color.toARGB32(),
    };
  }

  double get progress => (currentValue / targetValue).clamp(0.0, 1.0);
}

class EcoImpactVisualization {
  final List<EcoDataPoint> dailyData;
  final List<EcoDataPoint> weeklyData;
  final List<EcoDataPoint> monthlyData;
  final Map<String, List<EcoDataPoint>> categoryTrends;
  final List<ComparisonMetric> comparisons;
  final List<String> insights;

  const EcoImpactVisualization({
    required this.dailyData,
    required this.weeklyData,
    required this.monthlyData,
    required this.categoryTrends,
    required this.comparisons,
    required this.insights,
  });

  factory EcoImpactVisualization.fromMap(Map<String, dynamic> data) {
    return EcoImpactVisualization(
      dailyData: (data['dailyData'] as List<dynamic>? ?? [])
          .map((d) => EcoDataPoint.fromMap(d))
          .toList(),
      weeklyData: (data['weeklyData'] as List<dynamic>? ?? [])
          .map((d) => EcoDataPoint.fromMap(d))
          .toList(),
      monthlyData: (data['monthlyData'] as List<dynamic>? ?? [])
          .map((d) => EcoDataPoint.fromMap(d))
          .toList(),
      categoryTrends: (data['categoryTrends'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, (v as List<dynamic>)
              .map((d) => EcoDataPoint.fromMap(d))
              .toList())),
      comparisons: (data['comparisons'] as List<dynamic>? ?? [])
          .map((c) => ComparisonMetric.fromMap(c))
          .toList(),
      insights: List<String>.from(data['insights'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dailyData': dailyData.map((d) => d.toMap()).toList(),
      'weeklyData': weeklyData.map((d) => d.toMap()).toList(),
      'monthlyData': monthlyData.map((d) => d.toMap()).toList(),
      'categoryTrends': categoryTrends.map((k, v) =>
          MapEntry(k, v.map((d) => d.toMap()).toList())),
      'comparisons': comparisons.map((c) => c.toMap()).toList(),
      'insights': insights,
    };
  }

  factory EcoImpactVisualization.empty() {
    return const EcoImpactVisualization(
      dailyData: [],
      weeklyData: [],
      monthlyData: [],
      categoryTrends: {},
      comparisons: [],
      insights: [],
    );
  }
}

class EcoDataPoint {
  final DateTime date;
  final double value;
  final String category;
  final Map<String, dynamic> metadata;

  const EcoDataPoint({
    required this.date,
    required this.value,
    required this.category,
    this.metadata = const {},
  });

  factory EcoDataPoint.fromMap(Map<String, dynamic> data) {
    return EcoDataPoint(
      date: (data['date'] as Timestamp).toDate(),
      value: (data['value'] ?? 0.0).toDouble(),
      category: data['category'] ?? '',
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'value': value,
      'category': category,
      'metadata': metadata,
    };
  }
}

class ComparisonMetric {
  final String name;
  final double userValue;
  final double averageValue;
  final double percentile;
  final String unit;
  final bool isGood;

  const ComparisonMetric({
    required this.name,
    required this.userValue,
    required this.averageValue,
    required this.percentile,
    required this.unit,
    required this.isGood,
  });

  factory ComparisonMetric.fromMap(Map<String, dynamic> data) {
    return ComparisonMetric(
      name: data['name'] ?? '',
      userValue: (data['userValue'] ?? 0.0).toDouble(),
      averageValue: (data['averageValue'] ?? 0.0).toDouble(),
      percentile: (data['percentile'] ?? 0.0).toDouble(),
      unit: data['unit'] ?? '',
      isGood: data['isGood'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'userValue': userValue,
      'averageValue': averageValue,
      'percentile': percentile,
      'unit': unit,
      'isGood': isGood,
    };
  }

  String get comparison {
    if (userValue > averageValue) {
      return isGood ? 'above average' : 'higher than average';
    } else if (userValue < averageValue) {
      return isGood ? 'below average' : 'lower than average';
    }
    return 'average';
  }
}