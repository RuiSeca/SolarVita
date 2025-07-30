// lib/models/weekly_progress.dart

class WeeklyProgress {
  final String routineId;
  final int weekOfYear;
  final int year;
  final Map<String, DayProgress> dailyProgress;
  final DateTime weekStartDate;

  WeeklyProgress({
    required this.routineId,
    required this.weekOfYear,
    required this.year,
    required this.dailyProgress,
    required this.weekStartDate,
  });

  // Calculate overall completion percentage
  double get completionPercentage {
    if (dailyProgress.isEmpty) return 0.0;
    final completedDays = dailyProgress.values.where((day) => day.isCompleted).length;
    return (completedDays / dailyProgress.length) * 100;
  }

  // Get total exercises completed this week
  int get totalExercisesCompleted {
    return dailyProgress.values.fold(0, (sum, day) => sum + day.completedExercises);
  }

  // Get total planned exercises for this week
  int get totalPlannedExercises {
    return dailyProgress.values.fold(0, (sum, day) => sum + day.plannedExercises);
  }

  // Check if the entire week is completed
  bool get isWeekCompleted {
    return dailyProgress.values.every((day) => day.isCompleted || day.isRestDay);
  }

  // Get the current streak of completed days
  int get currentStreak {
    int streak = 0;
    final sortedDays = dailyProgress.entries.toList()
      ..sort((a, b) => _dayOrder(a.key).compareTo(_dayOrder(b.key)));
    
    for (final entry in sortedDays.reversed) {
      if (entry.value.isCompleted || entry.value.isRestDay) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  int _dayOrder(String dayName) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days.indexOf(dayName);
  }

  Map<String, dynamic> toJson() {
    return {
      'routineId': routineId,
      'weekOfYear': weekOfYear,
      'year': year,
      'dailyProgress': dailyProgress.map((key, value) => MapEntry(key, value.toJson())),
      'weekStartDate': weekStartDate.toIso8601String(),
    };
  }

  factory WeeklyProgress.fromJson(Map<String, dynamic> json) {
    return WeeklyProgress(
      routineId: json['routineId'],
      weekOfYear: json['weekOfYear'],
      year: json['year'],
      dailyProgress: (json['dailyProgress'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, DayProgress.fromJson(value))),
      weekStartDate: DateTime.parse(json['weekStartDate']),
    );
  }

  WeeklyProgress copyWith({
    String? routineId,
    int? weekOfYear,
    int? year,
    Map<String, DayProgress>? dailyProgress,
    DateTime? weekStartDate,
  }) {
    return WeeklyProgress(
      routineId: routineId ?? this.routineId,
      weekOfYear: weekOfYear ?? this.weekOfYear,
      year: year ?? this.year,
      dailyProgress: dailyProgress ?? Map.from(this.dailyProgress),
      weekStartDate: weekStartDate ?? this.weekStartDate,
    );
  }
}

class DayProgress {
  final String dayName;
  final int plannedExercises;
  final List<String> completedExerciseIds;
  final bool isRestDay;
  final DateTime? lastUpdated;

  DayProgress({
    required this.dayName,
    required this.plannedExercises,
    required this.completedExerciseIds,
    this.isRestDay = false,
    this.lastUpdated,
  });

  // Calculate completion percentage for this day
  double get completionPercentage {
    if (isRestDay) return 100.0;
    if (plannedExercises == 0) return 0.0;
    return (completedExercises / plannedExercises) * 100;
  }

  // Get count of completed exercises
  int get completedExercises => completedExerciseIds.length;

  // Check if this day is fully completed
  bool get isCompleted {
    if (isRestDay) return true;
    return completedExercises >= plannedExercises;
  }

  // Check if a specific exercise is completed
  bool isExerciseCompleted(String exerciseId) {
    return completedExerciseIds.contains(exerciseId);
  }

  Map<String, dynamic> toJson() {
    return {
      'dayName': dayName,
      'plannedExercises': plannedExercises,
      'completedExerciseIds': completedExerciseIds,
      'isRestDay': isRestDay,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  factory DayProgress.fromJson(Map<String, dynamic> json) {
    return DayProgress(
      dayName: json['dayName'],
      plannedExercises: json['plannedExercises'],
      completedExerciseIds: List<String>.from(json['completedExerciseIds'] ?? []),
      isRestDay: json['isRestDay'] ?? false,
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated']) 
          : null,
    );
  }

  DayProgress copyWith({
    String? dayName,
    int? plannedExercises,
    List<String>? completedExerciseIds,
    bool? isRestDay,
    DateTime? lastUpdated,
  }) {
    return DayProgress(
      dayName: dayName ?? this.dayName,
      plannedExercises: plannedExercises ?? this.plannedExercises,
      completedExerciseIds: completedExerciseIds ?? List.from(this.completedExerciseIds),
      isRestDay: isRestDay ?? this.isRestDay,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}