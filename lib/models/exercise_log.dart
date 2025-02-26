// lib/models/exercise_log.dart

class ExerciseLog {
  final String id;
  final String exerciseId;
  final String exerciseName;
  final DateTime date;
  final List<ExerciseSet> sets;
  final String notes;

  ExerciseLog({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.date,
    required this.sets,
    this.notes = '',
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

  // Check if this workout contains a personal record
  bool get isPersonalRecord {
    // Logic to determine if this workout contains a PR
    // Could be based on maxWeight, totalVolume, or other metrics
    return false; // Placeholder
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
