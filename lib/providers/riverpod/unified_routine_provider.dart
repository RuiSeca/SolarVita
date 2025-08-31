import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../../models/exercise/workout_routine.dart';
import '../../services/database/routine_service.dart';
import 'dart:convert';

final logger = Logger();

/// State class to hold unified routine data
class UnifiedRoutineState {
  final WorkoutRoutine? activeRoutine;
  final DailyWorkout? todaysWorkout;
  final Map<String, DailyWorkout>? weeklyWorkouts;
  final Map<String, String>? exerciseStatuses; // exerciseId -> status (pending, completed, in_progress)
  final bool isLoading;
  final String? error;
  final DateTime lastSynced;

  static final DateTime _defaultDateTime = DateTime(2000);

  UnifiedRoutineState({
    this.activeRoutine,
    this.todaysWorkout,
    this.weeklyWorkouts,
    this.exerciseStatuses,
    this.isLoading = false,
    this.error,
    DateTime? lastSynced,
  }) : lastSynced = lastSynced ?? _defaultDateTime;

  UnifiedRoutineState copyWith({
    WorkoutRoutine? activeRoutine,
    DailyWorkout? todaysWorkout,
    Map<String, DailyWorkout>? weeklyWorkouts,
    Map<String, String>? exerciseStatuses,
    bool? isLoading,
    String? error,
    DateTime? lastSynced,
  }) {
    return UnifiedRoutineState(
      activeRoutine: activeRoutine ?? this.activeRoutine,
      todaysWorkout: todaysWorkout ?? this.todaysWorkout,
      weeklyWorkouts: weeklyWorkouts ?? this.weeklyWorkouts,
      exerciseStatuses: exerciseStatuses ?? this.exerciseStatuses,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastSynced: lastSynced ?? this.lastSynced,
    );
  }

  bool get hasData => activeRoutine != null;
  bool get hasError => error != null;
  bool get hasTodaysWorkout => todaysWorkout != null && todaysWorkout!.exercises.isNotEmpty && !todaysWorkout!.isRestDay;
}

/// Unified routine provider that manages active routine and exercise statuses
class UnifiedRoutineNotifier extends StateNotifier<UnifiedRoutineState> {
  UnifiedRoutineNotifier() : super(UnifiedRoutineState()) {
    loadRoutineData();
  }

  final RoutineService _routineService = RoutineService();
  static const String _exerciseStatusesKey = 'exercise_statuses';

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Unknown';
    }
  }

  /// Load routine data and exercise statuses
  Future<void> loadRoutineData() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Load active routine
      final manager = await _routineService.loadRoutineManager();
      final activeRoutine = manager.activeRoutine;
      
      logger.d('Active routine loaded: ${activeRoutine?.name}');
      
      if (activeRoutine == null) {
        state = state.copyWith(
          isLoading: false,
          lastSynced: DateTime.now(),
        );
        return;
      }

      // Get today's workout
      final today = DateTime.now();
      final todayName = _getDayName(today.weekday);
      final todaysWorkout = activeRoutine.getDayWorkout(todayName);
      
      logger.d('Today is $todayName, exercises: ${todaysWorkout.exercises.length}, rest day: ${todaysWorkout.isRestDay}');

      // Build weekly workouts map
      final weeklyWorkouts = <String, DailyWorkout>{};
      for (final dayWorkout in activeRoutine.weeklyPlan) {
        weeklyWorkouts[dayWorkout.dayName.toLowerCase()] = dayWorkout;
      }

      // Load exercise statuses from SharedPreferences
      final exerciseStatuses = await _loadExerciseStatuses();
      
      state = state.copyWith(
        activeRoutine: activeRoutine,
        todaysWorkout: todaysWorkout,
        weeklyWorkouts: weeklyWorkouts,
        exerciseStatuses: exerciseStatuses,
        isLoading: false,
        lastSynced: DateTime.now(),
      );
      
      logger.d('Routine data loaded successfully. Today\'s exercises: ${todaysWorkout.exercises.length}');
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load routine data: $e',
      );
      logger.e('Error loading routine data: $e');
    }
  }

  /// Load exercise statuses from SharedPreferences
  Future<Map<String, String>> _loadExerciseStatuses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusesJson = prefs.getString(_exerciseStatusesKey);
      if (statusesJson != null) {
        final Map<String, dynamic> decoded = json.decode(statusesJson);
        return decoded.map((key, value) => MapEntry(key, value.toString()));
      }
    } catch (e) {
      logger.e('Error loading exercise statuses: $e');
    }
    return {};
  }

  /// Save exercise statuses to SharedPreferences
  Future<void> _saveExerciseStatuses(Map<String, String> statuses) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusesJson = json.encode(statuses);
      await prefs.setString(_exerciseStatusesKey, statusesJson);
    } catch (e) {
      logger.e('Error saving exercise statuses: $e');
    }
  }

  /// Update exercise status (pending, in_progress, completed)
  Future<void> updateExerciseStatus(String exerciseTitle, String status) async {
    if (state.exerciseStatuses == null) return;
    
    final updatedStatuses = Map<String, String>.from(state.exerciseStatuses!);
    updatedStatuses[exerciseTitle] = status;
    
    state = state.copyWith(exerciseStatuses: updatedStatuses);
    await _saveExerciseStatuses(updatedStatuses);
    
    logger.d('Updated exercise status: $exerciseTitle -> $status');
  }

  /// Get exercise status for a specific exercise
  String getExerciseStatus(String exerciseTitle) {
    return state.exerciseStatuses?[exerciseTitle] ?? 'pending';
  }

  /// Get today's exercise count by status
  Map<String, int> getTodaysExerciseStatusCounts() {
    if (state.todaysWorkout == null) {
      return {'pending': 0, 'in_progress': 0, 'completed': 0};
    }

    int pending = 0, inProgress = 0, completed = 0;
    
    for (final exercise in state.todaysWorkout!.exercises) {
      final status = getExerciseStatus(exercise.title);
      switch (status) {
        case 'pending':
          pending++;
          break;
        case 'in_progress':
          inProgress++;
          break;
        case 'completed':
          completed++;
          break;
      }
    }
    
    return {
      'pending': pending,
      'in_progress': inProgress,
      'completed': completed,
    };
  }

  /// Get workout for a specific day
  DailyWorkout? getWorkoutForDay(String dayName) {
    return state.weeklyWorkouts?[dayName.toLowerCase()];
  }

  /// Refresh routine data
  Future<void> refreshRoutineData() async {
    await loadRoutineData();
  }

  /// Get today's exercises as a list with status information
  List<Map<String, dynamic>> getTodaysExercisesWithStatus() {
    if (state.todaysWorkout == null || state.todaysWorkout!.isRestDay) {
      return [];
    }

    return state.todaysWorkout!.exercises.map((exercise) {
      return {
        'exercise': exercise,
        'status': getExerciseStatus(exercise.title),
        'dayName': _getDayName(DateTime.now().weekday),
      };
    }).toList();
  }

  /// Calculate today's progress percentage
  double getTodaysProgressPercentage() {
    final statusCounts = getTodaysExerciseStatusCounts();
    final total = statusCounts['pending']! + statusCounts['in_progress']! + statusCounts['completed']!;
    
    if (total == 0) return 0.0;
    
    return statusCounts['completed']! / total;
  }
}

/// Provider for unified routine data
final unifiedRoutineProvider = StateNotifierProvider<UnifiedRoutineNotifier, UnifiedRoutineState>((ref) {
  return UnifiedRoutineNotifier();
});

/// Convenience providers
final todaysWorkoutProvider = Provider<DailyWorkout?>((ref) {
  ref.watch(unifiedRoutineProvider); // Ensure dependency on state changes
  final routineState = ref.watch(unifiedRoutineProvider);
  return routineState.todaysWorkout;
});

final todaysExercisesWithStatusProvider = Provider<List<Map<String, dynamic>>>((ref) {
  ref.watch(unifiedRoutineProvider); // Ensure dependency on state changes
  final notifier = ref.watch(unifiedRoutineProvider.notifier);
  return notifier.getTodaysExercisesWithStatus();
});

final todaysExerciseCountProvider = Provider<int>((ref) {
  ref.watch(unifiedRoutineProvider); // Ensure dependency on state changes
  final routineState = ref.watch(unifiedRoutineProvider);
  return routineState.todaysWorkout?.exercises.length ?? 0;
});

final todaysProgressProvider = Provider<double>((ref) {
  ref.watch(unifiedRoutineProvider); // Ensure dependency on state changes
  final notifier = ref.watch(unifiedRoutineProvider.notifier);
  return notifier.getTodaysProgressPercentage();
});

final todaysStatusCountsProvider = Provider<Map<String, int>>((ref) {
  ref.watch(unifiedRoutineProvider); // Ensure dependency on state changes
  final notifier = ref.watch(unifiedRoutineProvider.notifier);
  return notifier.getTodaysExerciseStatusCounts();
});

final routineDataLoadingProvider = Provider<bool>((ref) {
  final routineState = ref.watch(unifiedRoutineProvider);
  return routineState.isLoading;
});

final routineDataErrorProvider = Provider<String?>((ref) {
  final routineState = ref.watch(unifiedRoutineProvider);
  return routineState.error;
});

final hasActiveRoutineProvider = Provider<bool>((ref) {
  final routineState = ref.watch(unifiedRoutineProvider);
  return routineState.hasData;
});

final isRestDayProvider = Provider<bool>((ref) {
  final routineState = ref.watch(unifiedRoutineProvider);
  return routineState.todaysWorkout?.isRestDay ?? false;
});