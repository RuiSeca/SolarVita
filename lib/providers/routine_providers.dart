// lib/providers/routine_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise/workout_routine.dart';
import '../models/user/weekly_progress.dart';
import '../services/database/routine_service.dart';
import '../services/exercises/exercise_routine_sync_service.dart';
import '../services/exercises/dynamic_duration_service.dart';

// Service providers
final routineServiceProvider = Provider<RoutineService>(
  (ref) => RoutineService(),
);
final exerciseRoutineSyncServiceProvider = Provider<ExerciseRoutineSyncService>(
  (ref) => ExerciseRoutineSyncService(),
);
final dynamicDurationServiceProvider = Provider<DynamicDurationService>(
  (ref) => DynamicDurationService(),
);

// Routine manager provider
final routineManagerProvider = FutureProvider<RoutineManager>((ref) async {
  final service = ref.watch(routineServiceProvider);
  return await service.loadRoutineManager();
});

// Weekly progress provider
final weeklyProgressProvider = FutureProvider.family<WeeklyProgress?, String>((
  ref,
  routineId,
) async {
  final service = ref.watch(exerciseRoutineSyncServiceProvider);
  return await service.getWeeklyProgress(routineId);
});

// Routine stats provider
final routineStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, routineId) async {
      final service = ref.watch(exerciseRoutineSyncServiceProvider);
      return await service.getRoutineCompletionStats(routineId);
    });
