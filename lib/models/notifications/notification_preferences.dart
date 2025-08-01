import 'package:flutter/material.dart';

class NotificationPreferences {
  final WorkoutNotificationSettings workoutSettings;
  final MealNotificationSettings mealSettings;
  final DiaryNotificationSettings diarySettings;
  final bool ecoTips;
  final bool progressUpdates;

  NotificationPreferences({
    required this.workoutSettings,
    required this.mealSettings,
    required this.diarySettings,
    this.ecoTips = true,
    this.progressUpdates = true,
  });

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      workoutSettings: WorkoutNotificationSettings.fromMap(map['workoutSettings'] ?? {}),
      mealSettings: MealNotificationSettings.fromMap(map['mealSettings'] ?? {}),
      diarySettings: DiaryNotificationSettings.fromMap(map['diarySettings'] ?? {}),
      ecoTips: map['ecoTips'] ?? true,
      progressUpdates: map['progressUpdates'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'workoutSettings': workoutSettings.toMap(),
      'mealSettings': mealSettings.toMap(),
      'diarySettings': diarySettings.toMap(),
      'ecoTips': ecoTips,
      'progressUpdates': progressUpdates,
    };
  }

  NotificationPreferences copyWith({
    WorkoutNotificationSettings? workoutSettings,
    MealNotificationSettings? mealSettings,
    DiaryNotificationSettings? diarySettings,
    bool? ecoTips,
    bool? progressUpdates,
  }) {
    return NotificationPreferences(
      workoutSettings: workoutSettings ?? this.workoutSettings,
      mealSettings: mealSettings ?? this.mealSettings,
      diarySettings: diarySettings ?? this.diarySettings,
      ecoTips: ecoTips ?? this.ecoTips,
      progressUpdates: progressUpdates ?? this.progressUpdates,
    );
  }
}

class WorkoutNotificationSettings {
  final bool enabled;
  final NotificationTimingType timingType; // random_period or specific_time
  final String timePeriod; // morning, afternoon, evening, night
  final TimeOfDay? specificTime; // exact time if specific_time is selected
  final int advanceMinutes; // how many minutes before workout to notify

  WorkoutNotificationSettings({
    this.enabled = true,
    this.timingType = NotificationTimingType.randomPeriod,
    this.timePeriod = 'morning',
    this.specificTime,
    this.advanceMinutes = 30,
  });

  factory WorkoutNotificationSettings.fromMap(Map<String, dynamic> map) {
    TimeOfDay? specificTime;
    if (map['specificTime'] != null) {
      final timeStr = map['specificTime'] as String;
      final parts = timeStr.split(':');
      specificTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    return WorkoutNotificationSettings(
      enabled: map['enabled'] ?? true,
      timingType: NotificationTimingType.values.firstWhere(
        (e) => e.toString() == map['timingType'],
        orElse: () => NotificationTimingType.randomPeriod,
      ),
      timePeriod: map['timePeriod'] ?? 'morning',
      specificTime: specificTime,
      advanceMinutes: map['advanceMinutes'] ?? 30,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'timingType': timingType.toString(),
      'timePeriod': timePeriod,
      'specificTime': specificTime != null 
          ? '${specificTime!.hour.toString().padLeft(2, '0')}:${specificTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'advanceMinutes': advanceMinutes,
    };
  }

  WorkoutNotificationSettings copyWith({
    bool? enabled,
    NotificationTimingType? timingType,
    String? timePeriod,
    TimeOfDay? specificTime,
    int? advanceMinutes,
  }) {
    return WorkoutNotificationSettings(
      enabled: enabled ?? this.enabled,
      timingType: timingType ?? this.timingType,
      timePeriod: timePeriod ?? this.timePeriod,
      specificTime: specificTime ?? this.specificTime,
      advanceMinutes: advanceMinutes ?? this.advanceMinutes,
    );
  }
}

class MealNotificationSettings {
  final bool enabled;
  final Map<String, MealNotificationConfig> mealConfigs;

  MealNotificationSettings({
    this.enabled = true,
    Map<String, MealNotificationConfig>? mealConfigs,
  }) : mealConfigs = mealConfigs ?? {
    'breakfast': MealNotificationConfig(enabled: true, timingType: NotificationTimingType.randomPeriod),
    'lunch': MealNotificationConfig(enabled: true, timingType: NotificationTimingType.randomPeriod),
    'dinner': MealNotificationConfig(enabled: true, timingType: NotificationTimingType.randomPeriod),
    'snacks': MealNotificationConfig(enabled: true, timingType: NotificationTimingType.randomPeriod),
  };

  factory MealNotificationSettings.fromMap(Map<String, dynamic> map) {
    final mealConfigs = <String, MealNotificationConfig>{};
    final mealConfigsData = map['mealConfigs'] as Map<String, dynamic>? ?? {};
    
    for (final entry in mealConfigsData.entries) {
      mealConfigs[entry.key] = MealNotificationConfig.fromMap(entry.value as Map<String, dynamic>);
    }

    // Ensure all meal types exist
    final defaultMeals = ['breakfast', 'lunch', 'dinner', 'snacks'];
    for (final meal in defaultMeals) {
      if (!mealConfigs.containsKey(meal)) {
        mealConfigs[meal] = MealNotificationConfig(enabled: true, timingType: NotificationTimingType.randomPeriod);
      }
    }

    return MealNotificationSettings(
      enabled: map['enabled'] ?? true,
      mealConfigs: mealConfigs,
    );
  }

  Map<String, dynamic> toMap() {
    final mealConfigsData = <String, dynamic>{};
    for (final entry in mealConfigs.entries) {
      mealConfigsData[entry.key] = entry.value.toMap();
    }

    return {
      'enabled': enabled,
      'mealConfigs': mealConfigsData,
    };
  }

  MealNotificationSettings copyWith({
    bool? enabled,
    Map<String, MealNotificationConfig>? mealConfigs,
  }) {
    return MealNotificationSettings(
      enabled: enabled ?? this.enabled,
      mealConfigs: mealConfigs ?? this.mealConfigs,
    );
  }
}

class MealNotificationConfig {
  final bool enabled;
  final NotificationTimingType timingType;
  final TimeOfDay? specificTime;
  final int advanceMinutes; // how many minutes before meal time to notify
  final String? customMealName; // from meal plan

  MealNotificationConfig({
    this.enabled = true,
    this.timingType = NotificationTimingType.randomPeriod,
    this.specificTime,
    this.advanceMinutes = 15,
    this.customMealName,
  });

  factory MealNotificationConfig.fromMap(Map<String, dynamic> map) {
    TimeOfDay? specificTime;
    if (map['specificTime'] != null) {
      final timeStr = map['specificTime'] as String;
      final parts = timeStr.split(':');
      specificTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    return MealNotificationConfig(
      enabled: map['enabled'] ?? true,
      timingType: NotificationTimingType.values.firstWhere(
        (e) => e.toString() == map['timingType'],
        orElse: () => NotificationTimingType.randomPeriod,
      ),
      specificTime: specificTime,
      advanceMinutes: map['advanceMinutes'] ?? 15,
      customMealName: map['customMealName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'timingType': timingType.toString(),
      'specificTime': specificTime != null 
          ? '${specificTime!.hour.toString().padLeft(2, '0')}:${specificTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'advanceMinutes': advanceMinutes,
      'customMealName': customMealName,
    };
  }

  MealNotificationConfig copyWith({
    bool? enabled,
    NotificationTimingType? timingType,
    TimeOfDay? specificTime,
    int? advanceMinutes,
    String? customMealName,
  }) {
    return MealNotificationConfig(
      enabled: enabled ?? this.enabled,
      timingType: timingType ?? this.timingType,
      specificTime: specificTime ?? this.specificTime,
      advanceMinutes: advanceMinutes ?? this.advanceMinutes,
      customMealName: customMealName ?? this.customMealName,
    );
  }
}

class DiaryNotificationSettings {
  final bool enabled;
  final NotificationTimingType timingType;
  final String timePeriod; // evening, night for diary entries
  final TimeOfDay? specificTime;
  final int advanceMinutes; // reminder before preferred time

  DiaryNotificationSettings({
    this.enabled = true,
    this.timingType = NotificationTimingType.randomPeriod,
    this.timePeriod = 'evening',
    this.specificTime,
    this.advanceMinutes = 0, // No advance for diary, remind at the time
  });

  factory DiaryNotificationSettings.fromMap(Map<String, dynamic> map) {
    TimeOfDay? specificTime;
    if (map['specificTime'] != null) {
      final timeStr = map['specificTime'] as String;
      final parts = timeStr.split(':');
      specificTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    return DiaryNotificationSettings(
      enabled: map['enabled'] ?? true,
      timingType: NotificationTimingType.values.firstWhere(
        (e) => e.toString() == map['timingType'],
        orElse: () => NotificationTimingType.randomPeriod,
      ),
      timePeriod: map['timePeriod'] ?? 'evening',
      specificTime: specificTime,
      advanceMinutes: map['advanceMinutes'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'timingType': timingType.toString(),
      'timePeriod': timePeriod,
      'specificTime': specificTime != null 
          ? '${specificTime!.hour.toString().padLeft(2, '0')}:${specificTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'advanceMinutes': advanceMinutes,
    };
  }

  DiaryNotificationSettings copyWith({
    bool? enabled,
    NotificationTimingType? timingType,
    String? timePeriod,
    TimeOfDay? specificTime,
    int? advanceMinutes,
  }) {
    return DiaryNotificationSettings(
      enabled: enabled ?? this.enabled,
      timingType: timingType ?? this.timingType,
      timePeriod: timePeriod ?? this.timePeriod,
      specificTime: specificTime ?? this.specificTime,
      advanceMinutes: advanceMinutes ?? this.advanceMinutes,
    );
  }
}

enum NotificationTimingType {
  randomPeriod, // Random time within the period (morning, afternoon, etc.)
  specificTime, // Exact time specified by user
}

// Time period definitions for random notifications
class TimePeriods {
  static const Map<String, Map<String, int>> periods = {
    'morning': {'start': 6, 'end': 12},
    'afternoon': {'start': 12, 'end': 17},
    'evening': {'start': 17, 'end': 21},
    'night': {'start': 21, 'end': 23},
  };
  
  static List<String> get allPeriods => periods.keys.toList();
  
  static Map<String, int>? getPeriod(String period) => periods[period];
}