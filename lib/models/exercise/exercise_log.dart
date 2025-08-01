// lib/models/exercise_log.dart

class ExerciseLog {
  final String id;
  final String exerciseId;
  final String exerciseName;
  final DateTime date;
  final List<ExerciseSet> sets;
  final String notes;
  final String? routineId;
  final String? dayName;
  final int? weekOfYear;
  final bool isPersonalRecord;

  ExerciseLog({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.date,
    required this.sets,
    this.notes = '',
    this.routineId,
    this.dayName,
    this.weekOfYear,
    this.isPersonalRecord = false,
  });

  // Calculate total volume (weight × reps across all sets)
  double get totalVolume {
    return sets.fold(0, (total, set) => total + (set.weight * set.reps));
  }

  // Get the maximum weight used in any set
  double get maxWeight {
    if (sets.isEmpty) return 0;
    return sets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
  }

  // Get the maximum reps used in any set
  int get maxReps {
    if (sets.isEmpty) return 0;
    return sets.map((s) => s.reps).reduce((a, b) => a > b ? a : b);
  }

  // Get the maximum duration used in any set
  Duration? get maxDuration {
    final durationsOnly = sets.where((s) => s.duration != null).map((s) => s.duration!);
    if (durationsOnly.isEmpty) return null;
    return durationsOnly.reduce((a, b) => a > b ? a : b);
  }

  // Get the maximum distance used in any set
  double? get maxDistance {
    final distancesOnly = sets.where((s) => s.distance != null).map((s) => s.distance!);
    if (distancesOnly.isEmpty) return null;
    return distancesOnly.reduce((a, b) => a > b ? a : b);
  }

  // Helper to get the week of year for this log
  int get weekNumber {
    return weekOfYear ?? _calculateWeekOfYear(date);
  }

  // Calculate which day of the week this log is from
  String get dayOfWeek {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  // Check if this log is from the current week
  bool get isCurrentWeek {
    return weekNumber == _calculateWeekOfYear(DateTime.now());
  }

  // Calculate week of year for a given date
  static int _calculateWeekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday - 1) / 7).ceil();
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'date': date.toIso8601String(),
      'sets': sets.map((s) => s.toJson()).toList(),
      'notes': notes,
      'routineId': routineId,
      'dayName': dayName,
      'weekOfYear': weekOfYear,
      'isPersonalRecord': isPersonalRecord,
    };
  }

  // Create from JSON for retrieval
  factory ExerciseLog.fromJson(Map<String, dynamic> json) {
    return ExerciseLog(
      id: json['id'],
      exerciseId: json['exerciseId'],
      exerciseName: json['exerciseName'],
      date: DateTime.parse(json['date']),
      sets: (json['sets'] as List).map((s) => ExerciseSet.fromJson(s)).toList(),
      notes: json['notes'] ?? '',
      routineId: json['routineId'],
      dayName: json['dayName'],
      weekOfYear: json['weekOfYear'],
      isPersonalRecord: json['isPersonalRecord'] ?? false,
    );
  }

  // Create a copy with updated fields
  ExerciseLog copyWith({
    String? id,
    String? exerciseId,
    String? exerciseName,
    DateTime? date,
    List<ExerciseSet>? sets,
    String? notes,
    String? routineId,
    String? dayName,
    int? weekOfYear,
    bool? isPersonalRecord,
  }) {
    return ExerciseLog(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      date: date ?? this.date,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
      routineId: routineId ?? this.routineId,
      dayName: dayName ?? this.dayName,
      weekOfYear: weekOfYear ?? this.weekOfYear,
      isPersonalRecord: isPersonalRecord ?? this.isPersonalRecord,
    );
  }
}

class ExerciseSet {
  final int setNumber;
  final double weight;
  final int reps;
  final double? distance; // For cardio exercises (in km)
  final Duration? duration; // For timed exercises

  ExerciseSet({
    required this.setNumber,
    required this.weight,
    required this.reps,
    this.distance,
    this.duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'setNumber': setNumber,
      'weight': weight,
      'reps': reps,
      'distance': distance,
      'duration': duration?.inSeconds,
    };
  }

  factory ExerciseSet.fromJson(Map<String, dynamic> json) {
    return ExerciseSet(
      setNumber: json['setNumber'],
      weight: json['weight'].toDouble(),
      reps: json['reps'],
      distance: json['distance']?.toDouble(),
      duration:
          json['duration'] != null ? Duration(seconds: json['duration']) : null,
    );
  }
}
