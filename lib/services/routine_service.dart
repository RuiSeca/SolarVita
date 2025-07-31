import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_routine.dart';
import '../screens/search/workout_detail/models/workout_item.dart';
import 'firebase_routine_service.dart';

class RoutineService {
  static const String _routineManagerKey = 'workout_routine_manager';
  static const String _activeRoutineKey = 'active_routine_id';
  
  final FirebaseRoutineService _firebaseService = FirebaseRoutineService();

  /// Loads routine manager from storage
  Future<RoutineManager> loadRoutineManager() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final routineData = prefs.getString(_routineManagerKey);
      
      if (routineData != null) {
        final Map<String, dynamic> json = jsonDecode(routineData);
        return RoutineManager.fromJson(json);
      }
      
      return RoutineManager.empty();
    } catch (e) {
      // Return empty manager if loading fails
      return RoutineManager.empty();
    }
  }

  /// Saves routine manager to storage
  Future<void> saveRoutineManager(RoutineManager manager) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final routineData = jsonEncode(manager.toJson());
      await prefs.setString(_routineManagerKey, routineData);
      
      // Also save active routine ID for quick access
      final activeRoutine = manager.activeRoutine;
      if (activeRoutine != null) {
        await prefs.setString(_activeRoutineKey, activeRoutine.id);
        
        // Sync active routine to Firebase (non-blocking)
        _firebaseService.syncUserRoutine(activeRoutine).catchError((error) {
          // Log error but don't fail the local save
          return false;
        });
      }
    } catch (e) {
      throw Exception('Failed to save routine: $e');
    }
  }

  /// Creates a new routine
  Future<RoutineManager> createRoutine(String name) async {
    final manager = await loadRoutineManager();
    
    if (manager.routines.length >= RoutineManager.maxRoutines) {
      throw Exception('Maximum ${RoutineManager.maxRoutines} routines allowed');
    }
    
    final updatedManager = manager.addRoutine(name);
    await saveRoutineManager(updatedManager);
    return updatedManager;
  }

  /// Updates an existing routine
  Future<RoutineManager> updateRoutine(WorkoutRoutine routine) async {
    final manager = await loadRoutineManager();
    final updatedManager = manager.updateRoutine(routine);
    await saveRoutineManager(updatedManager);
    return updatedManager;
  }

  /// Sets a routine as active
  Future<RoutineManager> setActiveRoutine(String routineId) async {
    final manager = await loadRoutineManager();
    final updatedManager = manager.setActiveRoutine(routineId);
    await saveRoutineManager(updatedManager);
    return updatedManager;
  }

  /// Deletes a routine
  Future<RoutineManager> deleteRoutine(String routineId) async {
    final manager = await loadRoutineManager();
    final updatedManager = manager.deleteRoutine(routineId);
    await saveRoutineManager(updatedManager);
    return updatedManager;
  }

  /// Adds exercise to a specific day in a routine
  Future<RoutineManager> addExerciseToDay(
    String routineId, 
    String dayName, 
    WorkoutItem exercise
  ) async {
    final manager = await loadRoutineManager();
    final routine = manager.routines.firstWhere((r) => r.id == routineId);
    
    final dayWorkout = routine.getDayWorkout(dayName);
    final updatedExercises = [...dayWorkout.exercises, exercise];
    
    final updatedRoutine = routine.updateDay(dayName, updatedExercises);
    final updatedManager = manager.updateRoutine(updatedRoutine);
    
    await saveRoutineManager(updatedManager);
    return updatedManager;
  }

  /// Removes exercise from a specific day
  Future<RoutineManager> removeExerciseFromDay(
    String routineId, 
    String dayName, 
    int exerciseIndex
  ) async {
    final manager = await loadRoutineManager();
    final routine = manager.routines.firstWhere((r) => r.id == routineId);
    
    final dayWorkout = routine.getDayWorkout(dayName);
    final updatedExercises = List<WorkoutItem>.from(dayWorkout.exercises);
    
    if (exerciseIndex >= 0 && exerciseIndex < updatedExercises.length) {
      updatedExercises.removeAt(exerciseIndex);
    }
    
    final updatedRoutine = routine.updateDay(dayName, updatedExercises);
    final updatedManager = manager.updateRoutine(updatedRoutine);
    
    await saveRoutineManager(updatedManager);
    return updatedManager;
  }

  /// Reorders exercises within a day
  Future<RoutineManager> reorderExercises(
    String routineId, 
    String dayName, 
    int oldIndex, 
    int newIndex
  ) async {
    final manager = await loadRoutineManager();
    final routine = manager.routines.firstWhere((r) => r.id == routineId);
    
    final dayWorkout = routine.getDayWorkout(dayName);
    final updatedExercises = List<WorkoutItem>.from(dayWorkout.exercises);
    
    if (oldIndex >= 0 && oldIndex < updatedExercises.length &&
        newIndex >= 0 && newIndex < updatedExercises.length) {
      final exercise = updatedExercises.removeAt(oldIndex);
      updatedExercises.insert(newIndex, exercise);
    }
    
    final updatedRoutine = routine.updateDay(dayName, updatedExercises);
    final updatedManager = manager.updateRoutine(updatedRoutine);
    
    await saveRoutineManager(updatedManager);
    return updatedManager;
  }

  /// Sets a day as rest day
  Future<RoutineManager> setRestDay(
    String routineId, 
    String dayName, 
    bool isRestDay,
    {String? notes}
  ) async {
    final manager = await loadRoutineManager();
    final routine = manager.routines.firstWhere((r) => r.id == routineId);
    
    final updatedRoutine = routine.updateDay(
      dayName, 
      isRestDay ? [] : routine.getDayWorkout(dayName).exercises,
      isRestDay: isRestDay,
      notes: notes,
    );
    
    final updatedManager = manager.updateRoutine(updatedRoutine);
    await saveRoutineManager(updatedManager);
    return updatedManager;
  }

  /// Gets routine statistics
  Map<String, dynamic> getRoutineStats(WorkoutRoutine routine) {
    final totalExercises = routine.totalWorkouts;
    final totalMinutes = routine.totalWeeklyMinutes;
    final restDays = routine.weeklyPlan.where((day) => day.isRestDay).length;
    final workoutDays = 7 - restDays;
    
    // Calculate difficulty distribution
    final difficulties = <String, int>{};
    for (final day in routine.weeklyPlan) {
      for (final exercise in day.exercises) {
        difficulties[exercise.difficulty] = (difficulties[exercise.difficulty] ?? 0) + 1;
      }
    }
    
    return {
      'totalExercises': totalExercises,
      'totalMinutes': totalMinutes,
      'workoutDays': workoutDays,
      'restDays': restDays,
      'averageWorkoutTime': workoutDays > 0 ? (totalMinutes / workoutDays).round() : 0,
      'difficultyDistribution': difficulties,
    };
  }

  /// Duplicates a routine with a new name
  Future<RoutineManager> duplicateRoutine(String routineId, String newName) async {
    final manager = await loadRoutineManager();
    
    if (manager.routines.length >= RoutineManager.maxRoutines) {
      throw Exception('Maximum ${RoutineManager.maxRoutines} routines allowed');
    }
    
    final originalRoutine = manager.routines.firstWhere((r) => r.id == routineId);
    
    final duplicatedRoutine = WorkoutRoutine(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: newName,
      weeklyPlan: originalRoutine.weeklyPlan,
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      description: originalRoutine.description,
      category: originalRoutine.category,
      isActive: false,
    );
    
    final updatedManager = RoutineManager(
      routines: [...manager.routines, duplicatedRoutine]
    );
    
    await saveRoutineManager(updatedManager);
    return updatedManager;
  }

  /// Gets quick routine templates
  List<WorkoutRoutine> getRoutineTemplates() {
    return [
      _createStrengthTemplate(),
      _createCardioTemplate(),
      _createFullBodyTemplate(),
      _createUpperLowerTemplate(),
    ];
  }

  WorkoutRoutine _createStrengthTemplate() {
    return WorkoutRoutine(
      id: 'template_strength',
      name: 'Strength Training',
      weeklyPlan: [
        DailyWorkout(dayName: 'Monday', exercises: []), // Chest & Triceps
        DailyWorkout(dayName: 'Tuesday', exercises: []), // Back & Biceps
        DailyWorkout(dayName: 'Wednesday', exercises: [], isRestDay: true),
        DailyWorkout(dayName: 'Thursday', exercises: []), // Legs
        DailyWorkout(dayName: 'Friday', exercises: []), // Shoulders
        DailyWorkout(dayName: 'Saturday', exercises: [], isRestDay: true),
        DailyWorkout(dayName: 'Sunday', exercises: [], isRestDay: true),
      ],
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      category: 'Strength',
      description: 'Classic strength training split with adequate rest',
    );
  }

  WorkoutRoutine _createCardioTemplate() {
    return WorkoutRoutine(
      id: 'template_cardio',
      name: 'Cardio Blast',
      weeklyPlan: [
        DailyWorkout(dayName: 'Monday', exercises: []), // HIIT
        DailyWorkout(dayName: 'Tuesday', exercises: []), // Steady State
        DailyWorkout(dayName: 'Wednesday', exercises: []), // Active Recovery
        DailyWorkout(dayName: 'Thursday', exercises: []), // Intervals
        DailyWorkout(dayName: 'Friday', exercises: []), // Mixed Cardio
        DailyWorkout(dayName: 'Saturday', exercises: []), // Long Session
        DailyWorkout(dayName: 'Sunday', exercises: [], isRestDay: true),
      ],
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      category: 'Cardio',
      description: 'High-intensity cardio focused routine',
    );
  }

  WorkoutRoutine _createFullBodyTemplate() {
    return WorkoutRoutine(
      id: 'template_fullbody',
      name: 'Full Body',
      weeklyPlan: [
        DailyWorkout(dayName: 'Monday', exercises: []), // Full Body A
        DailyWorkout(dayName: 'Tuesday', exercises: [], isRestDay: true),
        DailyWorkout(dayName: 'Wednesday', exercises: []), // Full Body B
        DailyWorkout(dayName: 'Thursday', exercises: [], isRestDay: true),
        DailyWorkout(dayName: 'Friday', exercises: []), // Full Body C
        DailyWorkout(dayName: 'Saturday', exercises: [], isRestDay: true),
        DailyWorkout(dayName: 'Sunday', exercises: [], isRestDay: true),
      ],
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      category: 'Full Body',
      description: 'Complete full body workouts with rest days',
    );
  }

  WorkoutRoutine _createUpperLowerTemplate() {
    return WorkoutRoutine(
      id: 'template_upperlower',
      name: 'Upper/Lower Split',
      weeklyPlan: [
        DailyWorkout(dayName: 'Monday', exercises: []), // Upper
        DailyWorkout(dayName: 'Tuesday', exercises: []), // Lower
        DailyWorkout(dayName: 'Wednesday', exercises: [], isRestDay: true),
        DailyWorkout(dayName: 'Thursday', exercises: []), // Upper
        DailyWorkout(dayName: 'Friday', exercises: []), // Lower
        DailyWorkout(dayName: 'Saturday', exercises: [], isRestDay: true),
        DailyWorkout(dayName: 'Sunday', exercises: [], isRestDay: true),
      ],
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      category: 'Split',
      description: 'Upper/Lower body split routine',
    );
  }
}