class UserProgress {
  final int currentStrikes;
  final int totalStrikes;
  final int currentLevel;
  final DateTime lastStrikeDate;
  final DateTime lastActivityDate;
  final DailyGoals dailyGoals;
  final Map<String, bool> todayGoalsCompleted;
  final int todayMultiplier;

  const UserProgress({
    this.currentStrikes = 0,
    this.totalStrikes = 0,
    this.currentLevel = 1,
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
      case 5: return 0; // Max level
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
      default: return 0;
    }
  }

  int get strikesForNextLevel {
    switch (currentLevel) {
      case 1: return 7;
      case 2: return 21;
      case 3: return 49;
      case 4: return 105;
      case 5: return 105; // Max level
      default: return 0;
    }
  }

  double get levelProgress {
    if (currentLevel >= 5) return 1.0;
    
    final currentLevelStrikes = strikesForCurrentLevel;
    final nextLevelStrikes = strikesForNextLevel;
    final progressStrikes = totalStrikes - currentLevelStrikes;
    final strikesNeeded = nextLevelStrikes - currentLevelStrikes;
    
    return (progressStrikes / strikesNeeded).clamp(0.0, 1.0);
  }

  String get levelTitle {
    switch (currentLevel) {
      case 1: return 'Health Rookie';
      case 2: return 'Wellness Warrior';
      case 3: return 'Eco Enthusiast';
      case 4: return 'Health Champion';
      case 5: return 'Eco Master';
      default: return 'Health Rookie';
    }
  }

  String get levelIcon {
    switch (currentLevel) {
      case 1: return '🌱';
      case 2: return '⚡';
      case 3: return '🌿';
      case 4: return '🏆';
      case 5: return '👑';
      default: return '🌱';
    }
  }

  bool get isMaxLevel => currentLevel >= 5;

  int get completedGoalsCount => todayGoalsCompleted.values.where((completed) => completed).length;

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      currentStrikes: json['currentStrikes'] as int? ?? 0,
      totalStrikes: json['totalStrikes'] as int? ?? 0,
      currentLevel: json['currentLevel'] as int? ?? 1,
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
  final int waterIntakeGoal; // in glasses
  final int sleepHoursGoal;

  const DailyGoals({
    this.stepsGoal = 8000,
    this.activeMinutesGoal = 30,
    this.caloriesBurnGoal = 2000,
    this.waterIntakeGoal = 8,
    this.sleepHoursGoal = 8,
  });

  DailyGoals copyWith({
    int? stepsGoal,
    int? activeMinutesGoal,
    int? caloriesBurnGoal,
    int? waterIntakeGoal,
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
      activeMinutesGoal: json['activeMinutesGoal'] as int? ?? 30,
      caloriesBurnGoal: json['caloriesBurnGoal'] as int? ?? 2000,
      waterIntakeGoal: json['waterIntakeGoal'] as int? ?? 8,
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
  String get displayName {
    switch (this) {
      case GoalType.steps:
        return 'Steps';
      case GoalType.activeMinutes:
        return 'Active Minutes';
      case GoalType.caloriesBurn:
        return 'Calories Burn';
      case GoalType.waterIntake:
        return 'Water Intake';
      case GoalType.sleepQuality:
        return 'Sleep Quality';
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