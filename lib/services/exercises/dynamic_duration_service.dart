// lib/services/dynamic_duration_service.dart
import 'dart:math';
import 'package:logging/logging.dart';
import '../../models/exercise/exercise_log.dart';
import '../../models/exercise/workout_routine.dart';
import '../../screens/search/workout_detail/models/workout_item.dart';
import 'exercise_tracking_service.dart';

class DynamicDurationService {
  static final DynamicDurationService _instance =
      DynamicDurationService._internal();
  final Logger _log = Logger('DynamicDurationService');
  final ExerciseTrackingService _exerciseService = ExerciseTrackingService();

  factory DynamicDurationService() {
    return _instance;
  }

  DynamicDurationService._internal();

  /// Calculate dynamic duration for a specific exercise based on planned sets/reps
  /// Returns duration in minutes
  Future<double> calculateDynamicDuration({
    required String exerciseId,
    required String exerciseName,
    required String staticDuration,
    int? plannedSets,
    int? plannedReps,
    double? plannedWeight,
  }) async {
    try {
      // Get historical logs for this exercise
      final logs = await _exerciseService.getLogsForExercise(exerciseId);
      _log.info(
        'Found ${logs.length} logs for $exerciseName (ID: $exerciseId)',
      );

      if (logs.isEmpty) {
        // No historical data, use static duration with planned multiplier
        final result = _calculateStaticWithMultiplier(
          staticDuration,
          plannedSets,
          plannedReps,
        );
        _log.info(
          'No logs for $exerciseName, using static multiplier: ${result.toStringAsFixed(1)} min (static: $staticDuration, sets: $plannedSets)',
        );
        return result;
      }

      // Get recent logs (last 10 workouts for this exercise)
      final recentLogs = logs.take(10).toList();

      // Calculate average time per set based on historical data
      final avgTimePerSet = _calculateAverageTimePerSet(recentLogs);

      // Calculate planned total sets
      final totalPlannedSets =
          plannedSets ?? _getAverageSetsFromHistory(recentLogs);

      // Base dynamic duration calculation
      double dynamicDuration = avgTimePerSet * totalPlannedSets;

      // Apply rep-based multiplier if planned reps differ from historical average
      if (plannedReps != null) {
        final avgHistoricalReps = _getAverageRepsFromHistory(recentLogs);
        final repMultiplier = plannedReps / avgHistoricalReps;
        dynamicDuration *= _clampMultiplier(repMultiplier);
      }

      // Apply weight-based multiplier for strength exercises
      if (plannedWeight != null && plannedWeight > 0) {
        final avgHistoricalWeight = _getAverageWeightFromHistory(recentLogs);
        if (avgHistoricalWeight > 0) {
          final weightMultiplier = (plannedWeight / avgHistoricalWeight);
          // Higher weight = longer rest between sets (small multiplier)
          dynamicDuration *=
              (1 + (weightMultiplier - 1) * 0.3); // Max 30% increase
        }
      }

      // Apply exercise type multiplier
      dynamicDuration *= _getExerciseTypeMultiplier(exerciseName);

      // Ensure reasonable bounds (min 0.5 minutes, max 20 minutes per exercise)
      final clampedDuration = dynamicDuration.clamp(0.5, 20.0);

      _log.info(
        'Dynamic duration for $exerciseName: ${clampedDuration.toStringAsFixed(1)} min (static: $staticDuration, before clamp: ${dynamicDuration.toStringAsFixed(1)})',
      );

      // Safety check - never return 0
      return clampedDuration == 0.0 ? 2.0 : clampedDuration;
    } catch (e) {
      final fallback = _parseStaticDuration(staticDuration);
      final safeFallback = fallback == 0.0 ? 2.0 : fallback;
      _log.warning(
        'Error calculating dynamic duration for $exerciseName: $e, falling back to ${safeFallback.toStringAsFixed(1)} min',
      );
      return safeFallback;
    }
  }

  /// Calculate total dynamic duration for a day's workout
  Future<DynamicWorkoutDuration> calculateDayDynamicDuration(
    DailyWorkout day,
  ) async {
    double totalStaticMinutes = 0;
    double totalDynamicMinutes = 0;
    final List<ExerciseDurationComparison> exerciseComparisons = [];

    for (final exercise in day.exercises) {
      final staticMinutes = _parseStaticDuration(exercise.duration);
      final plannedSets = _getPlannedSetsForExercise(exercise);
      _log.info(
        'Processing ${exercise.title}: ${exercise.steps.length} steps (instructions), using $plannedSets sets',
      );

      final dynamicMinutes = await calculateDynamicDuration(
        exerciseId: exercise.title.hashCode.toString(),
        exerciseName: exercise.title,
        staticDuration: exercise.duration,
        plannedSets: plannedSets,
      );

      totalStaticMinutes += staticMinutes;
      totalDynamicMinutes += dynamicMinutes;

      exerciseComparisons.add(
        ExerciseDurationComparison(
          exerciseName: exercise.title,
          staticDuration: staticMinutes,
          dynamicDuration: dynamicMinutes,
          improvement: dynamicMinutes - staticMinutes,
        ),
      );
    }

    return DynamicWorkoutDuration(
      totalStaticMinutes: totalStaticMinutes,
      totalDynamicMinutes: totalDynamicMinutes,
      exerciseComparisons: exerciseComparisons,
      timeSavings: totalStaticMinutes - totalDynamicMinutes,
    );
  }

  /// Get personalized duration recommendation for exercise logging
  Future<Map<String, dynamic>> getDurationRecommendation({
    required String exerciseId,
    required String exerciseName,
    required List<ExerciseSet> plannedSets,
  }) async {
    try {
      final logs = await _exerciseService.getLogsForExercise(exerciseId);

      if (logs.isEmpty) {
        return {
          'recommendedDuration': '2m', // Default fallback
          'confidence': 'low',
          'reason': 'No historical data available',
        };
      }

      // Calculate expected duration based on planned sets
      final avgTimePerSet = _calculateAverageTimePerSet(logs.take(5).toList());
      final estimatedMinutes = avgTimePerSet * plannedSets.length;

      // Calculate confidence based on data availability
      String confidence;
      if (logs.length >= 5) {
        confidence = 'high';
      } else if (logs.length >= 2) {
        confidence = 'medium';
      } else {
        confidence = 'low';
      }

      return {
        'recommendedDuration': '${estimatedMinutes.ceil()}m',
        'confidence': confidence,
        'reason': 'Based on your last ${logs.length} workouts',
        'averageTimePerSet': '${(avgTimePerSet * 60).round()}s',
      };
    } catch (e) {
      _log.warning('Error getting duration recommendation: $e');
      return {
        'recommendedDuration': '2m',
        'confidence': 'low',
        'reason': 'Error calculating recommendation',
      };
    }
  }

  // Private helper methods

  double _calculateAverageTimePerSet(List<ExerciseLog> logs) {
    if (logs.isEmpty) return 2.0; // Default 2 minutes per set

    double totalTime = 0;
    int totalSets = 0;

    for (final log in logs) {
      if (log.sets.isNotEmpty) {
        // Calculate time based on actual sets duration or estimate
        double logTime = 0;

        // If sets have duration, use actual time
        final setsWithDuration = log.sets.where((set) => set.duration != null);
        if (setsWithDuration.isNotEmpty) {
          logTime = setsWithDuration
              .map((set) => set.duration!.inSeconds / 60.0)
              .reduce((a, b) => a + b);
        } else {
          // Estimate based on reps and weight
          logTime = _estimateTimeFromSets(log.sets);
        }

        totalTime += logTime;
        totalSets += log.sets.length;
      }
    }

    if (totalSets == 0) return 2.0;

    final avgTimePerSet = totalTime / totalSets;
    return avgTimePerSet.clamp(
      0.5,
      5.0,
    ); // Between 30 seconds and 5 minutes per set
  }

  double _estimateTimeFromSets(List<ExerciseSet> sets) {
    // Estimate time based on reps and weight
    double totalTime = 0;

    for (final set in sets) {
      // Base time: 1 second per rep
      double setTime = set.reps / 60.0; // Convert to minutes

      // Add rest time based on intensity (heavier weight = longer rest)
      double restTime = 1.0; // Default 1 minute rest
      if (set.weight > 50) {
        restTime = 2.0; // 2 minutes for heavy weights
      } else if (set.weight > 20) {
        restTime = 1.5; // 1.5 minutes for moderate weights
      }

      totalTime += setTime + restTime;
    }

    // Remove last rest period
    if (sets.isNotEmpty) {
      totalTime -= (sets.last.weight > 50 ? 2.0 : 1.0);
    }

    return totalTime;
  }

  int _getAverageSetsFromHistory(List<ExerciseLog> logs) {
    if (logs.isEmpty) return 3; // Default 3 sets

    final avgSets =
        logs.map((log) => log.sets.length).reduce((a, b) => a + b) /
        logs.length;

    return avgSets.round().clamp(1, 8);
  }

  double _getAverageRepsFromHistory(List<ExerciseLog> logs) {
    if (logs.isEmpty) return 10.0; // Default 10 reps

    double totalReps = 0;
    int setCount = 0;

    for (final log in logs) {
      for (final set in log.sets) {
        totalReps += set.reps;
        setCount++;
      }
    }

    if (setCount == 0) return 10.0;

    return (totalReps / setCount).clamp(1.0, 50.0);
  }

  double _getAverageWeightFromHistory(List<ExerciseLog> logs) {
    if (logs.isEmpty) return 0.0;

    double totalWeight = 0;
    int setCount = 0;

    for (final log in logs) {
      for (final set in log.sets) {
        totalWeight += set.weight;
        setCount++;
      }
    }

    if (setCount == 0) return 0.0;

    return totalWeight / setCount;
  }

  double _getExerciseTypeMultiplier(String exerciseName) {
    final name = exerciseName.toLowerCase();

    // Compound exercises typically take longer
    if (name.contains('squat') ||
        name.contains('deadlift') ||
        name.contains('bench')) {
      return 1.3; // 30% longer
    }

    // Cardio exercises
    if (name.contains('run') ||
        name.contains('cycle') ||
        name.contains('cardio')) {
      return 1.0; // Use calculated time as-is
    }

    // Isolation exercises are typically faster
    if (name.contains('curl') ||
        name.contains('extension') ||
        name.contains('raise')) {
      return 0.8; // 20% faster
    }

    return 1.0; // Default multiplier
  }

  double _clampMultiplier(double multiplier) {
    return multiplier.clamp(0.5, 2.0); // Between 50% and 200%
  }

  double _calculateStaticWithMultiplier(
    String staticDuration,
    int? plannedSets,
    int? plannedReps,
  ) {
    final baseDuration = _parseStaticDuration(staticDuration);
    _log.info(
      'Parsed static duration "$staticDuration" as ${baseDuration.toStringAsFixed(1)} min',
    );

    // Apply set multiplier if provided (assume static duration is for 1 set)
    if (plannedSets != null && plannedSets > 0) {
      final clampedSets = plannedSets.clamp(1, 8); // Allow up to 8 sets max
      final result = baseDuration * clampedSets.toDouble();
      _log.info(
        'Applied sets multiplier: ${baseDuration.toStringAsFixed(1)} * $clampedSets = ${result.toStringAsFixed(1)} min',
      );
      return result;
    }

    _log.info(
      'No sets multiplier applied, returning base duration: ${baseDuration.toStringAsFixed(1)} min',
    );
    return baseDuration == 0.0 ? 2.0 : baseDuration;
  }

  double _parseStaticDuration(String duration) {
    final lowerDuration = duration.toLowerCase().trim();

    // Handle ranges like "60-90" - use average
    if (lowerDuration.contains('-')) {
      final parts = lowerDuration.split('-');
      if (parts.length == 2) {
        final first = _parseSingleDuration(parts[0].trim());
        final second = _parseSingleDuration(parts[1].trim());
        return (first + second) / 2;
      }
    }

    return _parseSingleDuration(lowerDuration);
  }

  double _parseSingleDuration(String duration) {
    final lowerDuration = duration.toLowerCase().trim();

    // If it contains 's' (seconds)
    if (lowerDuration.contains('s')) {
      final seconds =
          int.tryParse(lowerDuration.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
      return seconds / 60.0; // Convert seconds to minutes
    }

    // If it contains 'm' (minutes)
    if (lowerDuration.contains('m')) {
      final minutes =
          double.tryParse(lowerDuration.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
      return minutes;
    }

    // If it contains ':' (mm:ss format)
    if (lowerDuration.contains(':')) {
      final parts = lowerDuration.split(':');
      if (parts.length == 2) {
        final minutes = int.tryParse(parts[0]) ?? 0;
        final seconds = int.tryParse(parts[1]) ?? 0;
        return minutes + (seconds / 60.0);
      }
    }

    // Default: assume it's seconds if just a number > 10, otherwise minutes
    final number = int.tryParse(lowerDuration.replaceAll(RegExp(r'[^\d]'), ''));
    if (number != null) {
      if (number > 10) {
        return number / 60.0; // Convert seconds to minutes
      } else {
        return number.toDouble(); // Assume minutes
      }
    }

    return 2.0; // Default 2 minutes
  }

  /// Get the planned number of sets for an exercise
  /// For strength exercises, default to 3 sets
  /// For cardio/time-based exercises, default to 1 set
  int _getPlannedSetsForExercise(WorkoutItem exercise) {
    final lowerTitle = exercise.title.toLowerCase();
    final lowerDifficulty = exercise.difficulty.toLowerCase();

    // If it's a cardio or time-based exercise, use 1 set
    if (lowerTitle.contains('run') ||
        lowerTitle.contains('cycle') ||
        lowerTitle.contains('cardio') ||
        lowerTitle.contains('plank') ||
        exercise.duration.contains('min')) {
      return 1;
    }

    // For most strength exercises, use 3 sets as standard
    if (lowerDifficulty.contains('beginner')) {
      return 2; // Beginners start with fewer sets
    } else if (lowerDifficulty.contains('advanced') ||
        lowerDifficulty.contains('expert')) {
      return 4; // Advanced users may do more sets
    }

    return 3; // Default for intermediate and most exercises
  }
}

/// Data class for dynamic workout duration analysis
class DynamicWorkoutDuration {
  final double totalStaticMinutes;
  final double totalDynamicMinutes;
  final List<ExerciseDurationComparison> exerciseComparisons;
  final double timeSavings;

  DynamicWorkoutDuration({
    required this.totalStaticMinutes,
    required this.totalDynamicMinutes,
    required this.exerciseComparisons,
    required this.timeSavings,
  });

  String get formattedStaticDuration => '${totalStaticMinutes.round()}min';
  String get formattedDynamicDuration => '${totalDynamicMinutes.round()}min';
  String get formattedTimeSavings {
    if (timeSavings > 0) {
      return '${timeSavings.round()}min saved';
    } else {
      return '${(-timeSavings).round()}min longer';
    }
  }

  bool get isFasterThanStatic => timeSavings > 0;
}

/// Data class for individual exercise duration comparison
class ExerciseDurationComparison {
  final String exerciseName;
  final double staticDuration;
  final double dynamicDuration;
  final double improvement;

  ExerciseDurationComparison({
    required this.exerciseName,
    required this.staticDuration,
    required this.dynamicDuration,
    required this.improvement,
  });

  String get formattedStaticDuration => '${staticDuration.round()}min';
  String get formattedDynamicDuration => '${dynamicDuration.round()}min';
  String get formattedImprovement {
    if (improvement.abs() < 0.1) return 'Same';
    if (improvement > 0) {
      return '+${improvement.round()}min';
    } else {
      return '${improvement.round()}min';
    }
  }

  bool get isFaster => improvement < 0;
}
