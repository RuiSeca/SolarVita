import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum AchievementCategory {
  carbonSaver,
  streakMaster,
  activityExplorer,
  communityChampion,
  ecoWarrior,
  lifestyleChange,
}

enum AchievementTier {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
}

enum AchievementType {
  milestone,
  streak,
  diversity,
  community,
  challenge,
  seasonal,
}

class EcoAchievement {
  final String id;
  final String nameKey;
  final String descriptionKey;
  final AchievementCategory category;
  final AchievementTier tier;
  final AchievementType type;
  final IconData icon;
  final Color color;
  final int points;
  final Map<String, dynamic> criteria;
  final List<String> rewards;
  final bool isSecret;
  final DateTime? availableFrom;
  final DateTime? availableUntil;

  const EcoAchievement({
    required this.id,
    required this.nameKey,
    required this.descriptionKey,
    required this.category,
    required this.tier,
    required this.type,
    required this.icon,
    required this.color,
    required this.points,
    required this.criteria,
    this.rewards = const [],
    this.isSecret = false,
    this.availableFrom,
    this.availableUntil,
  });

  factory EcoAchievement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EcoAchievement(
      id: doc.id,
      nameKey: data['nameKey'] ?? '',
      descriptionKey: data['descriptionKey'] ?? '',
      category: AchievementCategory.values[data['category'] ?? 0],
      tier: AchievementTier.values[data['tier'] ?? 0],
      type: AchievementType.values[data['type'] ?? 0],
      icon: IconData(data['iconCodePoint'] ?? Icons.eco.codePoint, fontFamily: 'MaterialIcons'),
      color: Color(data['colorValue'] ?? Colors.green.toARGB32()),
      points: data['points'] ?? 0,
      criteria: Map<String, dynamic>.from(data['criteria'] ?? {}),
      rewards: List<String>.from(data['rewards'] ?? []),
      isSecret: data['isSecret'] ?? false,
      availableFrom: data['availableFrom'] != null
          ? (data['availableFrom'] as Timestamp).toDate()
          : null,
      availableUntil: data['availableUntil'] != null
          ? (data['availableUntil'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nameKey': nameKey,
      'descriptionKey': descriptionKey,
      'category': category.index,
      'tier': tier.index,
      'type': type.index,
      'iconCodePoint': icon.codePoint,
      'colorValue': color.toARGB32(),
      'points': points,
      'criteria': criteria,
      'rewards': rewards,
      'isSecret': isSecret,
      'availableFrom': availableFrom != null ? Timestamp.fromDate(availableFrom!) : null,
      'availableUntil': availableUntil != null ? Timestamp.fromDate(availableUntil!) : null,
    };
  }

  bool get isAvailable {
    final now = DateTime.now();
    if (availableFrom != null && now.isBefore(availableFrom!)) return false;
    if (availableUntil != null && now.isAfter(availableUntil!)) return false;
    return true;
  }

  String get tierName {
    switch (tier) {
      case AchievementTier.bronze:
        return 'Bronze';
      case AchievementTier.silver:
        return 'Silver';
      case AchievementTier.gold:
        return 'Gold';
      case AchievementTier.platinum:
        return 'Platinum';
      case AchievementTier.diamond:
        return 'Diamond';
    }
  }

  Color get tierColor {
    switch (tier) {
      case AchievementTier.bronze:
        return const Color(0xFFCD7F32);
      case AchievementTier.silver:
        return const Color(0xFFC0C0C0);
      case AchievementTier.gold:
        return const Color(0xFFFFD700);
      case AchievementTier.platinum:
        return const Color(0xFFE5E4E2);
      case AchievementTier.diamond:
        return const Color(0xFFB9F2FF);
    }
  }
}

class UserAchievement {
  final String id;
  final String userId;
  final String achievementId;
  final DateTime unlockedAt;
  final double progress;
  final bool isCompleted;
  final Map<String, dynamic> progressData;

  const UserAchievement({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.unlockedAt,
    required this.progress,
    required this.isCompleted,
    this.progressData = const {},
  });

  factory UserAchievement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserAchievement(
      id: doc.id,
      userId: data['userId'] ?? '',
      achievementId: data['achievementId'] ?? '',
      unlockedAt: (data['unlockedAt'] as Timestamp).toDate(),
      progress: (data['progress'] ?? 0.0).toDouble(),
      isCompleted: data['isCompleted'] ?? false,
      progressData: Map<String, dynamic>.from(data['progressData'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'achievementId': achievementId,
      'unlockedAt': Timestamp.fromDate(unlockedAt),
      'progress': progress,
      'isCompleted': isCompleted,
      'progressData': progressData,
    };
  }

  UserAchievement copyWith({
    String? id,
    String? userId,
    String? achievementId,
    DateTime? unlockedAt,
    double? progress,
    bool? isCompleted,
    Map<String, dynamic>? progressData,
  }) {
    return UserAchievement(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      achievementId: achievementId ?? this.achievementId,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      progressData: progressData ?? this.progressData,
    );
  }
}

class EcoLevelSystem {
  final int level;
  final int currentXP;
  final int xpForNextLevel;
  final int totalXP;
  final String title;
  final Color levelColor;
  final List<String> unlockedFeatures;

  const EcoLevelSystem({
    required this.level,
    required this.currentXP,
    required this.xpForNextLevel,
    required this.totalXP,
    required this.title,
    required this.levelColor,
    this.unlockedFeatures = const [],
  });

  factory EcoLevelSystem.fromXP(int totalXP) {
    final level = _calculateLevel(totalXP);
    final currentXP = totalXP - _getXPForLevel(level);
    final xpForNextLevel = _getXPForLevel(level + 1) - _getXPForLevel(level);

    return EcoLevelSystem(
      level: level,
      currentXP: currentXP,
      xpForNextLevel: xpForNextLevel,
      totalXP: totalXP,
      title: _getLevelTitle(level),
      levelColor: _getLevelColor(level),
      unlockedFeatures: _getUnlockedFeatures(level),
    );
  }

  static int _calculateLevel(int totalXP) {
    int level = 1;
    while (_getXPForLevel(level + 1) <= totalXP) {
      level++;
    }
    return level;
  }

  static int _getXPForLevel(int level) {
    return (level - 1) * 100 + ((level - 1) * (level - 2)) * 25;
  }

  static String _getLevelTitle(int level) {
    if (level <= 5) return 'Eco Beginner';
    if (level <= 10) return 'Green Explorer';
    if (level <= 15) return 'Sustainability Advocate';
    if (level <= 25) return 'Environmental Warrior';
    if (level <= 35) return 'Planet Guardian';
    if (level <= 50) return 'Eco Master';
    if (level <= 75) return 'Carbon Hero';
    return 'Earth Champion';
  }

  static Color _getLevelColor(int level) {
    if (level <= 5) return Colors.brown;
    if (level <= 10) return Colors.green;
    if (level <= 15) return Colors.blue;
    if (level <= 25) return Colors.purple;
    if (level <= 35) return Colors.orange;
    if (level <= 50) return Colors.red;
    if (level <= 75) return Colors.pink;
    return Colors.amber;
  }

  static List<String> _getUnlockedFeatures(int level) {
    final features = <String>[];
    if (level >= 5) features.add('community_challenges');
    if (level >= 10) features.add('advanced_tracking');
    if (level >= 15) features.add('carbon_predictions');
    if (level >= 20) features.add('eco_mentor_status');
    if (level >= 30) features.add('custom_challenges');
    if (level >= 40) features.add('global_leaderboards');
    if (level >= 50) features.add('eco_expert_badge');
    return features;
  }

  double get progressPercentage => currentXP / xpForNextLevel;

  Map<String, dynamic> toFirestore() {
    return {
      'level': level,
      'currentXP': currentXP,
      'xpForNextLevel': xpForNextLevel,
      'totalXP': totalXP,
      'title': title,
      'levelColorValue': levelColor.toARGB32(),
      'unlockedFeatures': unlockedFeatures,
    };
  }

  factory EcoLevelSystem.fromFirestore(Map<String, dynamic> data) {
    return EcoLevelSystem(
      level: data['level'] ?? 1,
      currentXP: data['currentXP'] ?? 0,
      xpForNextLevel: data['xpForNextLevel'] ?? 100,
      totalXP: data['totalXP'] ?? 0,
      title: data['title'] ?? 'Eco Beginner',
      levelColor: Color(data['levelColorValue'] ?? Colors.brown.toARGB32()),
      unlockedFeatures: List<String>.from(data['unlockedFeatures'] ?? []),
    );
  }
}

class PredefinedAchievements {
  static List<EcoAchievement> get achievements => [
    // Carbon Saver Achievements
    EcoAchievement(
      id: 'first_carbon_save',
      nameKey: 'first_carbon_save_name',
      descriptionKey: 'first_carbon_save_desc',
      category: AchievementCategory.carbonSaver,
      tier: AchievementTier.bronze,
      type: AchievementType.milestone,
      icon: Icons.eco,
      color: Colors.green,
      points: 50,
      criteria: {'carbonSaved': 0.1},
    ),
    EcoAchievement(
      id: 'carbon_saver_1kg',
      nameKey: 'carbon_saver_1kg_name',
      descriptionKey: 'carbon_saver_1kg_desc',
      category: AchievementCategory.carbonSaver,
      tier: AchievementTier.silver,
      type: AchievementType.milestone,
      icon: Icons.cloud_off,
      color: Colors.blue,
      points: 100,
      criteria: {'carbonSaved': 1.0},
    ),
    EcoAchievement(
      id: 'carbon_saver_10kg',
      nameKey: 'carbon_saver_10kg_name',
      descriptionKey: 'carbon_saver_10kg_desc',
      category: AchievementCategory.carbonSaver,
      tier: AchievementTier.gold,
      type: AchievementType.milestone,
      icon: Icons.nature,
      color: Colors.amber,
      points: 250,
      criteria: {'carbonSaved': 10.0},
    ),

    // Streak Achievements
    EcoAchievement(
      id: 'streak_3_days',
      nameKey: 'streak_3_days_name',
      descriptionKey: 'streak_3_days_desc',
      category: AchievementCategory.streakMaster,
      tier: AchievementTier.bronze,
      type: AchievementType.streak,
      icon: Icons.local_fire_department,
      color: Colors.orange,
      points: 75,
      criteria: {'streak': 3},
    ),
    EcoAchievement(
      id: 'streak_7_days',
      nameKey: 'streak_7_days_name',
      descriptionKey: 'streak_7_days_desc',
      category: AchievementCategory.streakMaster,
      tier: AchievementTier.silver,
      type: AchievementType.streak,
      icon: Icons.whatshot,
      color: Colors.deepOrange,
      points: 150,
      criteria: {'streak': 7},
    ),
    EcoAchievement(
      id: 'streak_30_days',
      nameKey: 'streak_30_days_name',
      descriptionKey: 'streak_30_days_desc',
      category: AchievementCategory.streakMaster,
      tier: AchievementTier.gold,
      type: AchievementType.streak,
      icon: Icons.fireplace,
      color: Colors.red,
      points: 500,
      criteria: {'streak': 30},
    ),

    // Activity Explorer Achievements
    EcoAchievement(
      id: 'activity_explorer',
      nameKey: 'activity_explorer_name',
      descriptionKey: 'activity_explorer_desc',
      category: AchievementCategory.activityExplorer,
      tier: AchievementTier.bronze,
      type: AchievementType.diversity,
      icon: Icons.explore,
      color: Colors.purple,
      points: 100,
      criteria: {'uniqueActivities': 5},
    ),
    EcoAchievement(
      id: 'eco_master',
      nameKey: 'eco_master_name',
      descriptionKey: 'eco_master_desc',
      category: AchievementCategory.activityExplorer,
      tier: AchievementTier.platinum,
      type: AchievementType.diversity,
      icon: Icons.emoji_events,
      color: Colors.indigo,
      points: 1000,
      criteria: {'uniqueActivities': 20, 'carbonSaved': 50.0},
    ),

    // Community Achievements
    EcoAchievement(
      id: 'first_circle_join',
      nameKey: 'first_circle_join_name',
      descriptionKey: 'first_circle_join_desc',
      category: AchievementCategory.communityChampion,
      tier: AchievementTier.bronze,
      type: AchievementType.community,
      icon: Icons.group,
      color: Colors.teal,
      points: 100,
      criteria: {'circlesJoined': 1},
    ),
    EcoAchievement(
      id: 'recipe_sharer',
      nameKey: 'recipe_sharer_name',
      descriptionKey: 'recipe_sharer_desc',
      category: AchievementCategory.communityChampion,
      tier: AchievementTier.silver,
      type: AchievementType.community,
      icon: Icons.restaurant_menu,
      color: Colors.green,
      points: 200,
      criteria: {'recipesShared': 5},
    ),

    // Lifestyle Change Achievements
    EcoAchievement(
      id: 'plant_based_week',
      nameKey: 'plant_based_week_name',
      descriptionKey: 'plant_based_week_desc',
      category: AchievementCategory.lifestyleChange,
      tier: AchievementTier.gold,
      type: AchievementType.challenge,
      icon: Icons.eco,
      color: Colors.lightGreen,
      points: 300,
      criteria: {'plantBasedMeals': 7, 'timeframe': 7},
    ),
  ];
}