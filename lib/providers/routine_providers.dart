// lib/providers/routine_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_routine.dart';
import '../models/weekly_progress.dart';
import '../services/routine_service.dart';
import '../services/exercise_routine_sync_service.dart';

// Service providers
final routineServiceProvider = Provider<RoutineService>((ref) => RoutineService());
final exerciseRoutineSyncServiceProvider = Provider<ExerciseRoutineSyncService>((ref) => ExerciseRoutineSyncService());

// Routine manager provider
final routineManagerProvider = FutureProvider<RoutineManager>((ref) async {
  final service = ref.watch(routineServiceProvider);
  return await service.loadRoutineManager();
});

// Weekly progress provider
final weeklyProgressProvider = FutureProvider.family<WeeklyProgress?, String>((ref, routineId) async {
  final service = ref.watch(exerciseRoutineSyncServiceProvider);
  return await service.getWeeklyProgress(routineId);
});

// Routine stats provider
final routineStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, routineId) async {
  final service = ref.watch(exerciseRoutineSyncServiceProvider);
  return await service.getRoutineCompletionStats(routineId);
});