import 'package:flutter/material.dart';
import '../../utils/translation_helper.dart';

class UserProgress {
  final int currentStrikes;
  final int totalStrikes;
  final int currentLevel;
  final int dayStreak;  // NEW: Consecutive days with at least one goal completed
  final DateTime lastStrikeDate;
  final DateTime lastActivityDate;
  final DailyGoals dailyGoals;
  final Map<String, bool> todayGoalsCompleted;
  final int todayMultiplier;

  const UserProgress({
    this.currentStrikes = 0,
    this.totalStrikes = 0,
    this.currentLevel = 1,
    this.dayStreak = 0,  // NEW: Default to 0 days
    required this.lastStrikeDate,
    required this.lastActivityDate,
    required this.dailyGoals,
    this.todayGoalsCompleted = const {},
    this.todayMultiplier = 1,
  });

  UserProgress copyWith({
    int? currentStrikes,
    int? totalStrikes,
    int? currentLevel,
    int? dayStreak,  // NEW: Add dayStreak parameter
    DateTime? lastStrikeDate,
    DateTime? lastActivityDate,
    DailyGoals? dailyGoals,
    Map<String, bool>? todayGoalsCompleted,
    int? todayMultiplier,
  }) {
    return UserProgress(
      currentStrikes: currentStrikes ?? this.currentStrikes,
      totalStrikes: totalStrikes ?? this.totalStrikes,
      currentLevel: currentLevel ?? this.currentLevel,
      dayStreak: dayStreak ?? this.dayStreak,  // NEW: Include dayStreak
      lastStrikeDate: lastStrikeDate ?? this.lastStrikeDate,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      dailyGoals: dailyGoals ?? this.dailyGoals,
      todayGoalsCompleted: todayGoalsCompleted ?? this.todayGoalsCompleted,
      todayMultiplier: todayMultiplier ?? this.todayMultiplier,
    );
  }

  // Level progression calculations
  int get strikesNeededForNextLevel {
    switch (currentLevel) {
      case 1: return 7 - totalStrikes;
      case 2: return 21 - totalStrikes;
      case 3: return 49 - totalStrikes;
      case 4: return 105 - totalStrikes;
      case 5: return 189 - totalStrikes;
      case 6: return 315 - totalStrikes;
      case 7: return 490 - totalStrikes;
      case 8: return 720 - totalStrikes;
      case 9: return 1015 - totalStrikes;
      case 10: return 0; // Max level
      default: return 0;
    }
  }

  int get strikesForCurrentLevel {
    switch (currentLevel) {
      case 1: return 0;
      case 2: return 7;
      case 3: return 21;
      case 4: return 49;
      case 5: return 105;
      case 6: return 189;
      case 7: return 315;
      case 8: return 490;
      case 9: return 720;
      case 10: return 1015;
      default: return 0;
    }
  }

  int get strikesForNextLevel {
    switch (currentLevel) {
      case 1: return 7;
      case 2: return 21;
      case 3: return 49;
      case 4: return 105;
      case 5: return 189;
      case 6: return 315;
      case 7: return 490;
      case 8: return 720;
      case 9: return 1015;
      case 10: return 1015; // Max level
      default: return 0;
    }
  }

  double get levelProgress {
    if (currentLevel >= 10) return 1.0;
    
    final currentLevelStrikes = strikesForCurrentLevel;
    final nextLevelStrikes = strikesForNextLevel;
    final progressStrikes = totalStrikes - currentLevelStrikes;
    final strikesNeeded = nextLevelStrikes - currentLevelStrikes;
    
    return (progressStrikes / strikesNeeded).clamp(0.0, 1.0);
  }

  String levelTitle(BuildContext context) {
    switch (currentLevel) {
      case 1: return tr(context, 'level_health_rookie');
      case 2: return tr(context, 'level_wellness_warrior');
      case 3: return tr(context, 'level_eco_enthusiast');
      case 4: return tr(context, 'level_health_champion');
      case 5: return tr(context, 'level_eco_master');
      case 6: return tr(context, 'level_solar_guardian');
      case 7: return tr(context, 'level_vitality_legend');
      case 8: return tr(context, 'level_eco_sage');
      case 9: return tr(context, 'level_solar_titan');
      case 10: return tr(context, 'level_ultimate_eco_warrior');
      default: return tr(context, 'level_health_rookie');
    }
  }

  String get levelIcon {
    switch (currentLevel) {
      case 1: return '🌱';
      case 2: return '⚡';
      case 3: return '🌿';
      case 4: return '🏆';
      case 5: return '👑';
      case 6: return '🌞';
      case 7: return '💫';
      case 8: return '🔮';
      case 9: return '⭐';
      case 10: return '🏅';
      default: return '🌱';
    }
  }

  bool get isMaxLevel => currentLevel >= 10;

  int get completedGoalsCount => todayGoalsCompleted.values.where((completed) => completed).length;

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      currentStrikes: json['currentStrikes'] as int? ?? 0,
      totalStrikes: json['totalStrikes'] as int? ?? 0,
      currentLevel: json['currentLevel'] as int? ?? 1,
      dayStreak: json['dayStreak'] as int? ?? 0,  // NEW: Parse dayStreak with default 0
      lastStrikeDate: DateTime.parse(json['lastStrikeDate'] as String),
      lastActivityDate: DateTime.parse(json['lastActivityDate'] as String),
      dailyGoals: DailyGoals.fromJson(json['dailyGoals'] as Map<String, dynamic>),
      todayGoalsCompleted: Map<String, bool>.from(json['todayGoalsCompleted'] as Map? ?? {}),
      todayMultiplier: json['todayMultiplier'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStrikes': currentStrikes,
      'totalStrikes': totalStrikes,
      'currentLevel': currentLevel,
      'dayStreak': dayStreak,  // NEW: Include dayStreak in JSON
      'lastStrikeDate': lastStrikeDate.toIso8601String(),
      'lastActivityDate': lastActivityDate.toIso8601String(),
      'dailyGoals': dailyGoals.toJson(),
      'todayGoalsCompleted': todayGoalsCompleted,
      'todayMultiplier': todayMultiplier,
    };
  }
}

class DailyGoals {
  final int stepsGoal;
  final int activeMinutesGoal;
  final int caloriesBurnGoal;
  final double waterIntakeGoal; // in liters
  final int sleepHoursGoal;

  const DailyGoals({
    this.stepsGoal = 8000,
    this.activeMinutesGoal = 45,
    this.caloriesBurnGoal = 800,
    this.waterIntakeGoal = 2.0, // 8 glasses = 2 liters (250ml per glass)
    this.sleepHoursGoal = 8,
  });

  DailyGoals copyWith({
    int? stepsGoal,
    int? activeMinutesGoal,
    int? caloriesBurnGoal,
    double? waterIntakeGoal,
    int? sleepHoursGoal,
  }) {
    return DailyGoals(
      stepsGoal: stepsGoal ?? this.stepsGoal,
      activeMinutesGoal: activeMinutesGoal ?? this.activeMinutesGoal,
      caloriesBurnGoal: caloriesBurnGoal ?? this.caloriesBurnGoal,
      waterIntakeGoal: waterIntakeGoal ?? this.waterIntakeGoal,
      sleepHoursGoal: sleepHoursGoal ?? this.sleepHoursGoal,
    );
  }

  factory DailyGoals.fromJson(Map<String, dynamic> json) {
    return DailyGoals(
      stepsGoal: json['stepsGoal'] as int? ?? 8000,
      activeMinutesGoal: json['activeMinutesGoal'] as int? ?? 45,
      caloriesBurnGoal: json['caloriesBurnGoal'] as int? ?? 800,
      waterIntakeGoal: (json['waterIntakeGoal'] as num?)?.toDouble() ?? 2.0,
      sleepHoursGoal: json['sleepHoursGoal'] as int? ?? 8,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stepsGoal': stepsGoal,
      'activeMinutesGoal': activeMinutesGoal,
      'caloriesBurnGoal': caloriesBurnGoal,
      'waterIntakeGoal': waterIntakeGoal,
      'sleepHoursGoal': sleepHoursGoal,
    };
  }
}

enum GoalType {
  steps,
  activeMinutes,
  caloriesBurn,
  waterIntake,
  sleepQuality,
}

extension GoalTypeExtension on GoalType {
  String displayName(BuildContext context) {
    switch (this) {
      case GoalType.steps:
        return tr(context, 'goal_steps');
      case GoalType.activeMinutes:
        return tr(context, 'goal_active_minutes');
      case GoalType.caloriesBurn:
        return tr(context, 'goal_calories_burn');
      case GoalType.waterIntake:
        return tr(context, 'goal_water_intake');
      case GoalType.sleepQuality:
        return tr(context, 'goal_sleep_quality');
    }
  }

  String get key {
    switch (this) {
      case GoalType.steps:
        return 'steps';
      case GoalType.activeMinutes:
        return 'activeMinutes';
      case GoalType.caloriesBurn:
        return 'caloriesBurn';
      case GoalType.waterIntake:
        return 'waterIntake';
      case GoalType.sleepQuality:
        return 'sleepQuality';
    }
  }

  String get icon {
    switch (this) {
      case GoalType.steps:
        return '👟';
      case GoalType.activeMinutes:
        return '⏱️';
      case GoalType.caloriesBurn:
        return '🔥';
      case GoalType.waterIntake:
        return '💧';
      case GoalType.sleepQuality:
        return '😴';
    }
  }
}