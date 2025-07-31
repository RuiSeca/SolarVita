// lib/services/exercise_routine_sync_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:logging/logging.dart';
import '../models/exercise_log.dart';
import '../models/weekly_progress.dart';
import '../models/personal_record.dart';
import 'exercise_tracking_service.dart';
import 'routine_service.dart';
import 'firebase_routine_service.dart';

class ExerciseRoutineSyncService {
  static final ExerciseRoutineSyncService _instance = ExerciseRoutineSyncService._internal();
  final Logger _log = Logger('ExerciseRoutineSyncService');
  final Uuid _uuid = Uuid();
  final ExerciseTrackingService _exerciseService = ExerciseTrackingService();
  final RoutineService _routineService = RoutineService();
  final FirebaseRoutineService _firebaseService = FirebaseRoutineService();
  
  // In-memory cache for faster access
  final Map<String, WeeklyProgress> _weeklyProgressCache = {};
  final Map<String, Map<String, dynamic>> _routineStatsCache = {};

  factory ExerciseRoutineSyncService() {
    return _instance;
  }

  ExerciseRoutineSyncService._internal();

  // Keys for SharedPreferences
  static const String _weeklyProgressKey = 'weekly_progress';
  static const String _personalRecordsKey = 'personal_records_enhanced';
  static const String _exerciseHistoryKey = 'exercise_history_for_firestore';

  // 🔄 Main sync function: Log exercise to routine
  Future<bool> logExerciseToRoutine({
    required String exerciseId,
    required String exerciseName,
    required List<ExerciseSet> sets,
    required String notes,
    String? routineId,
    String? dayName,
  }) async {
    try {
      final now = DateTime.now();
      final weekOfYear = _calculateWeekOfYear(now);
      
      // Create the exercise log with routine linking
      final log = ExerciseLog(
        id: _uuid.v4(),
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        date: now,
        sets: sets,
        notes: notes,
        routineId: routineId,
        dayName: dayName ?? _getCurrentDayName(),
        weekOfYear: weekOfYear,
        isPersonalRecord: false, // Will be updated after PR check
      );

      // Save the log using existing service
      final saved = await _exerciseService.saveExerciseLog(log);
      _log.info('Exercise log saved: $saved for ${log.exerciseName} (ID: ${log.exerciseId})');
      if (!saved) return false;

      // Sync exercise log to Firebase (non-blocking)
      _firebaseService.syncExerciseLog(log).catchError((error) {
        _log.warning('Failed to sync exercise log to Firebase: $error');
        return false;
      });

      // Check for personal records and update log if needed
      final isNewRecord = await _checkAndUpdatePersonalRecords(log);
      if (isNewRecord) {
        final updatedLog = log.copyWith(isPersonalRecord: true);
        await _exerciseService.updateLog(updatedLog);
      }

      // Update weekly progress if linked to routine
      if (routineId != null) {
        await _updateWeeklyProgress(routineId, exerciseId, dayName ?? _getCurrentDayName(), weekOfYear);
      }
      
      // Save to exercise history for Firestore migration
      await _saveExerciseHistory(log);

      return true;
    } catch (e) {
      _log.severe('Error logging exercise to routine: $e');
      return false;
    }
  }

  // 📊 Get weekly progress for a routine
  Future<WeeklyProgress?> getWeeklyProgress(String routineId, {int? weekOfYear}) async {
    try {
      final targetWeek = weekOfYear ?? _calculateWeekOfYear(DateTime.now());
      final cacheKey = '${routineId}_$targetWeek';
      
      // Check in-memory cache first
      if (_weeklyProgressCache.containsKey(cacheKey)) {
        return _weeklyProgressCache[cacheKey];
      }
      
      final prefs = await SharedPreferences.getInstance();
      final progressData = prefs.getStringList(_weeklyProgressKey) ?? [];
      
      for (final data in progressData) {
        final progress = WeeklyProgress.fromJson(jsonDecode(data));
        if (progress.routineId == routineId && progress.weekOfYear == targetWeek) {
          // Cache the result immediately for fast UI response
          _weeklyProgressCache[cacheKey] = progress;
          
          // Sync in background without blocking UI (fire and forget)
          _syncInBackground(routineId, targetWeek, cacheKey);
          
          return progress;
        }
      }
      
      // Create new weekly progress if not found
      final newProgress = await _createWeeklyProgress(routineId, targetWeek);
      _weeklyProgressCache[cacheKey] = newProgress;
      return newProgress;
    } catch (e) {
      _log.severe('Error getting weekly progress: $e');
      return null;
    }
  }

  // 🧠 Get smart auto-fill data for exercise
  Future<Map<String, dynamic>> getAutoFillData(String exerciseId, {String? routineId}) async {
    try {
      final logs = await _exerciseService.getLogsForExercise(exerciseId);
      if (logs.isEmpty) return {};

      // Get most recent log from current week
      final currentWeek = _calculateWeekOfYear(DateTime.now());
      final currentWeekLogs = logs.where((log) => log.weekNumber == currentWeek).toList();
      
      ExerciseLog? recentLog;
      if (currentWeekLogs.isNotEmpty) {
        recentLog = currentWeekLogs.first;
      } else if (logs.isNotEmpty) {
        recentLog = logs.first;
      }

      if (recentLog == null) return {};

      // Get personal records for this exercise
      final records = await getPersonalRecordsForExercise(exerciseId);

      return {
        'lastLog': {
          'sets': recentLog.sets.map((set) => set.toJson()).toList(),
          'notes': recentLog.notes,
          'date': recentLog.date.toIso8601String(),
          'wasThisWeek': recentLog.isCurrentWeek,
        },
        'personalRecords': records.map((r) => r.toJson()).toList(),
        'suggestions': _generateSuggestions(recentLog, records),
      };
    } catch (e) {
      _log.severe('Error getting auto-fill data: $e');
      return {};
    }
  }

  // 🏅 Get personal records for exercise with enhanced tracking
  Future<List<PersonalRecord>> getPersonalRecordsForExercise(String exerciseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recordsData = prefs.getStringList(_personalRecordsKey) ?? [];
      
      final records = recordsData
          .map((data) => PersonalRecord.fromJson(jsonDecode(data)))
          .where((record) => record.exerciseId == exerciseId)
          .toList();
          
      return records..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      _log.severe('Error getting personal records: $e');
      return [];
    }
  }

  // 📈 Check if exercise is completed for a specific day
  Future<bool> isExerciseCompletedForDay(String routineId, String dayName, String exerciseId) async {
    try {
      final progress = await getWeeklyProgress(routineId);
      if (progress == null) return false;
      
      final dayProgress = progress.dailyProgress[dayName];
      return dayProgress?.isExerciseCompleted(exerciseId) ?? false;
    } catch (e) {
      _log.severe('Error checking exercise completion: $e');
      return false;
    }
  }

  // 🗓️ Get logs for current week by routine and day
  Future<List<ExerciseLog>> getWeeklyLogsByRoutineAndDay(String routineId, String dayName) async {
    try {
      final currentWeek = _calculateWeekOfYear(DateTime.now());
      final allLogs = await _exerciseService.getAllLogs();
      
      return allLogs
          .where((log) => 
              log.routineId == routineId && 
              log.dayName == dayName && 
              log.weekNumber == currentWeek)
          .toList();
    } catch (e) {
      _log.severe('Error getting weekly logs: $e');
      return [];
    }
  }

  // 🎯 Get completion statistics for routine
  Future<Map<String, dynamic>> getRoutineCompletionStats(String routineId, {int? weekOfYear}) async {
    try {
      // Check cache first for faster response
      if (_routineStatsCache.containsKey(routineId)) {
        return _routineStatsCache[routineId]!;
      }
      
      final progress = await getWeeklyProgress(routineId, weekOfYear: weekOfYear);
      if (progress == null) {
        final stats = {
          'completionPercentage': 0.0,
          'totalExercisesCompleted': 0,
          'totalPlannedExercises': 0,
          'currentStreak': await _calculateCurrentStreak(routineId),
          'isWeekCompleted': false,
        };
        _routineStatsCache[routineId] = stats;
        return stats;
      }

      // Calculate exercise-based completion percentage (not day-based)
      final totalPlanned = progress.totalPlannedExercises;
      final totalCompleted = progress.totalExercisesCompleted;
      final exerciseCompletionPercentage = totalPlanned > 0 
          ? (totalCompleted / totalPlanned) * 100 
          : 0.0;

      final stats = {
        'completionPercentage': exerciseCompletionPercentage,
        'totalExercisesCompleted': totalCompleted,
        'totalPlannedExercises': totalPlanned,
        'currentStreak': await _calculateCurrentStreak(routineId),
        'isWeekCompleted': progress.isWeekCompleted,
        'dailyBreakdown': progress.dailyProgress.map((day, progress) => 
            MapEntry(day, {
              'completed': progress.completedExercises,
              'planned': progress.plannedExercises,
              'percentage': progress.completionPercentage,
              'isCompleted': progress.isCompleted,
              'isRestDay': progress.isRestDay,
            })
        ),
      };
      
      // Cache the results for faster subsequent access
      _routineStatsCache[routineId] = stats;
      return stats;
    } catch (e) {
      _log.severe('Error getting completion stats: $e');
      return {};
    }
  }
  
  // 🔥 Calculate current workout streak
  Future<int> _calculateCurrentStreak(String routineId) async {
    try {
      final allLogs = await _exerciseService.getAllLogs();
      final routineLogs = allLogs
          .where((log) => log.routineId == routineId)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date)); // Sort by date descending
      
      if (routineLogs.isEmpty) return 0;
      
      int streak = 0;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Group logs by day
      final logsByDay = <DateTime, List<ExerciseLog>>{};
      for (final log in routineLogs) {
        final logDay = DateTime(log.date.year, log.date.month, log.date.day);
        logsByDay[logDay] = (logsByDay[logDay] ?? [])..add(log);
      }
      
      // Get sorted workout days (most recent first)
      final workoutDays = logsByDay.keys.toList()
        ..sort((a, b) => b.compareTo(a));
      
      if (workoutDays.isEmpty) return 0;
      
      // Check if streak is broken (no workout today and more than 24 hours since last workout)
      final mostRecentWorkout = workoutDays.first;
      final hoursSinceLastWorkout = today.difference(mostRecentWorkout).inHours;
      
      // If more than 48 hours since last workout, streak is broken
      if (hoursSinceLastWorkout > 48) return 0;
      
      // If last workout was today, start counting streak
      if (mostRecentWorkout == today) {
        streak = 1;
      } else if (hoursSinceLastWorkout <= 24) {
        // If within 24 hours, count it
        streak = 1;
      } else {
        return 0; // Streak broken
      }
      
      // Count consecutive days going backwards
      for (int i = 1; i < workoutDays.length; i++) {
        final currentDay = workoutDays[i];
        final previousDay = workoutDays[i - 1];
        
        // Check if days are consecutive (within 1-2 days to account for rest days)
        final daysBetween = previousDay.difference(currentDay).inDays;
        
        if (daysBetween <= 2 && daysBetween >= 1) {
          streak++;
        } else {
          break; // Streak broken
        }
      }
      
      return streak;
    } catch (e) {
      _log.severe('Error calculating streak: $e');
      return 0;
    }
  }

  // Private helper methods

  Future<WeeklyProgress> _createWeeklyProgress(String routineId, int weekOfYear) async {
    try {
      final manager = await _routineService.loadRoutineManager();
      final routine = manager.routines.firstWhere((r) => r.id == routineId);
      
      final weekStartDate = _getWeekStartDate(weekOfYear, DateTime.now().year);
      final dailyProgress = <String, DayProgress>{};
      
      // Create daily progress for each day
      for (final day in routine.weeklyPlan) {
        dailyProgress[day.dayName] = DayProgress(
          dayName: day.dayName,
          plannedExercises: day.exercises.length,
          completedExerciseIds: [],
          isRestDay: day.isRestDay,
        );
      }
      
      final progress = WeeklyProgress(
        routineId: routineId,
        weekOfYear: weekOfYear,
        year: DateTime.now().year,
        dailyProgress: dailyProgress,
        weekStartDate: weekStartDate,
      );
      
      await _saveWeeklyProgress(progress);
      return progress;
    } catch (e) {
      _log.severe('Error creating weekly progress: $e');
      rethrow;
    }
  }

  Future<void> _updateWeeklyProgress(String routineId, String exerciseId, String dayName, int weekOfYear) async {
    try {
      var progress = await getWeeklyProgress(routineId, weekOfYear: weekOfYear);
      if (progress == null) return;
      
      final dayProgress = progress.dailyProgress[dayName];
      if (dayProgress == null) return;
      
      // Add exercise to completed list if not already there
      if (!dayProgress.completedExerciseIds.contains(exerciseId)) {
        final updatedDayProgress = dayProgress.copyWith(
          completedExerciseIds: [...dayProgress.completedExerciseIds, exerciseId],
          lastUpdated: DateTime.now(),
        );
        
        final updatedDailyProgress = Map<String, DayProgress>.from(progress.dailyProgress);
        updatedDailyProgress[dayName] = updatedDayProgress;
        
        progress = progress.copyWith(dailyProgress: updatedDailyProgress);
        
        // Update cache immediately for instant UI response
        final cacheKey = '${routineId}_$weekOfYear';
        _weeklyProgressCache[cacheKey] = progress;
        
        // Save to persistent storage (async - doesn't block UI)
        _saveWeeklyProgress(progress);
      }
    } catch (e) {
      _log.severe('Error updating weekly progress: $e');
    }
  }

  Future<void> _saveWeeklyProgress(WeeklyProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var progressData = prefs.getStringList(_weeklyProgressKey) ?? [];
      
      // Remove existing progress for same routine and week
      progressData.removeWhere((data) {
        final existing = WeeklyProgress.fromJson(jsonDecode(data));
        return existing.routineId == progress.routineId && 
               existing.weekOfYear == progress.weekOfYear;
      });
      
      // Add updated progress
      progressData.add(jsonEncode(progress.toJson()));
      await prefs.setStringList(_weeklyProgressKey, progressData);
    } catch (e) {
      _log.severe('Error saving weekly progress: $e');
    }
  }

  Future<bool> _checkAndUpdatePersonalRecords(ExerciseLog log) async {
    try {
      bool hasNewRecord = false;
      final existingRecords = await getPersonalRecordsForExercise(log.exerciseId);
      
      // Check different types of records
      final recordChecks = [
        {'type': 'Max Weight', 'value': log.maxWeight},
        {'type': 'Max Reps', 'value': log.maxReps.toDouble()},
        {'type': 'Total Volume', 'value': log.totalVolume},
      ];
      
      // Add duration and distance checks if applicable
      if (log.maxDuration != null) {
        recordChecks.add({'type': 'Max Duration', 'value': log.maxDuration!.inSeconds.toDouble()});
      }
      if (log.maxDistance != null) {
        recordChecks.add({'type': 'Max Distance', 'value': log.maxDistance!});
      }
      
      for (final check in recordChecks) {
        final existingRecord = existingRecords
            .where((r) => r.recordType == check['type'])
            .firstOrNull;
            
        if (existingRecord == null || (check['value'] as double) > existingRecord.value) {
          await _savePersonalRecord(PersonalRecord(
            exerciseId: log.exerciseId,
            exerciseName: log.exerciseName,
            recordType: check['type'] as String,
            value: check['value'] as double,
            date: log.date,
            logId: log.id,
          ));
          hasNewRecord = true;
        }
      }
      
      return hasNewRecord;
    } catch (e) {
      _log.severe('Error checking personal records: $e');
      return false;
    }
  }

  Future<void> _savePersonalRecord(PersonalRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var recordsData = prefs.getStringList(_personalRecordsKey) ?? [];
      
      // Remove existing record of same type for this exercise
      recordsData.removeWhere((data) {
        final existing = PersonalRecord.fromJson(jsonDecode(data));
        return existing.exerciseId == record.exerciseId && 
               existing.recordType == record.recordType;
      });
      
      // Add new record
      recordsData.add(jsonEncode(record.toJson()));
      await prefs.setStringList(_personalRecordsKey, recordsData);
    } catch (e) {
      _log.severe('Error saving personal record: $e');
    }
  }

  Map<String, dynamic> _generateSuggestions(ExerciseLog lastLog, List<PersonalRecord> records) {
    final suggestions = <String, dynamic>{};
    
    // Weight progression suggestion
    if (lastLog.sets.isNotEmpty) {
      final avgWeight = lastLog.sets.map((s) => s.weight).reduce((a, b) => a + b) / lastLog.sets.length;
      suggestions['recommendedWeight'] = (avgWeight * 1.025).round(); // 2.5% increase
    }
    
    // Rep progression suggestion
    if (lastLog.sets.isNotEmpty) {
      final avgReps = lastLog.sets.map((s) => s.reps).reduce((a, b) => a + b) / lastLog.sets.length;
      suggestions['recommendedReps'] = (avgReps + 1).round();
    }
    
    // Personal record context
    final maxWeightRecord = records.where((r) => r.recordType == 'Max Weight').firstOrNull;
    if (maxWeightRecord != null) {
      suggestions['personalBest'] = {
        'weight': maxWeightRecord.value,
        'date': maxWeightRecord.date.toIso8601String(),
      };
    }
    
    return suggestions;
  }

  String _getCurrentDayName() {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[DateTime.now().weekday - 1];
  }

  DateTime _getWeekStartDate(int weekOfYear, int year) {
    final firstDayOfYear = DateTime(year, 1, 1);
    final daysToAdd = (weekOfYear - 1) * 7 - (firstDayOfYear.weekday - 1);
    return firstDayOfYear.add(Duration(days: daysToAdd));
  }

  int _calculateWeekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday - 1) / 7).ceil();
  }
  
  // 💾 Save exercise history for Firestore migration
  Future<void> _saveExerciseHistory(ExerciseLog log) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var historyData = prefs.getStringList(_exerciseHistoryKey) ?? [];
      
      // Create history entry with additional metadata for Firestore
      final historyEntry = {
        'id': log.id,
        'exerciseId': log.exerciseId,
        'exerciseName': log.exerciseName,
        'date': log.date.toIso8601String(),
        'sets': log.sets.map((set) => set.toJson()).toList(),
        'notes': log.notes,
        'routineId': log.routineId,
        'dayName': log.dayName,
        'weekOfYear': log.weekOfYear,
        'isPersonalRecord': log.isPersonalRecord,
        'totalVolume': log.totalVolume,
        'maxWeight': log.maxWeight,
        'maxReps': log.maxReps,
        'maxDuration': log.maxDuration?.inSeconds,
        'maxDistance': log.maxDistance,
        'createdAt': DateTime.now().toIso8601String(),
        'syncedToFirestore': false, // Flag for Firestore migration
      };
      
      // Add to history
      historyData.add(jsonEncode(historyEntry));
      
      // Keep only last 1000 entries to prevent storage bloat
      if (historyData.length > 1000) {
        historyData = historyData.sublist(historyData.length - 1000);
      }
      
      await prefs.setStringList(_exerciseHistoryKey, historyData);
      _log.info('Exercise history saved for Firestore migration: ${log.exerciseName}');
    } catch (e) {
      _log.severe('Error saving exercise history: $e');
    }
  }
  
  // 📋 Get exercise history for Firestore migration
  Future<List<Map<String, dynamic>>> getExerciseHistoryForMigration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyData = prefs.getStringList(_exerciseHistoryKey) ?? [];
      
      return historyData
          .map((data) => jsonDecode(data) as Map<String, dynamic>)
          .where((entry) => entry['syncedToFirestore'] != true)
          .toList();
    } catch (e) {
      _log.severe('Error getting exercise history for migration: $e');
      return [];
    }
  }
  
  // ✅ Mark exercise history as synced to Firestore
  Future<void> markHistoryAsSynced(List<String> historyIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var historyData = prefs.getStringList(_exerciseHistoryKey) ?? [];
      
      // Update synced status
      historyData = historyData.map((data) {
        final entry = jsonDecode(data) as Map<String, dynamic>;
        if (historyIds.contains(entry['id'])) {
          entry['syncedToFirestore'] = true;
        }
        return jsonEncode(entry);
      }).toList();
      
      await prefs.setStringList(_exerciseHistoryKey, historyData);
      _log.info('Marked ${historyIds.length} history entries as synced to Firestore');
    } catch (e) {
      _log.severe('Error marking history as synced: $e');
    }
  }
  
  // 🧹 Cache management methods
  void clearCache() {
    _weeklyProgressCache.clear();
    _routineStatsCache.clear();
  }
  
  void clearProgressCache(String routineId, {int? weekOfYear}) {
    final targetWeek = weekOfYear ?? _calculateWeekOfYear(DateTime.now());
    final cacheKey = '${routineId}_$targetWeek';
    _weeklyProgressCache.remove(cacheKey);
    _routineStatsCache.remove(routineId);
  }
  
  // 🚀 Background sync to avoid blocking UI
  void _syncInBackground(String routineId, int targetWeek, String cacheKey) {
    // Run sync in background without awaiting
    Future.microtask(() async {
      try {
        await syncPlannedExercisesWithRoutine(routineId, weekOfYear: targetWeek);
      } catch (e) {
        // Silently handle errors in background sync
        _log.warning('Background sync failed for routine $routineId: $e');
      }
    });
  }

  // 🔄 Sync planned exercises count with current routine structure
  Future<void> syncPlannedExercisesWithRoutine(String routineId, {int? weekOfYear}) async {
    try {
      final targetWeek = weekOfYear ?? _calculateWeekOfYear(DateTime.now());
      
      // Get progress directly without triggering sync (to avoid circular calls)
      final prefs = await SharedPreferences.getInstance();
      final progressData = prefs.getStringList(_weeklyProgressKey) ?? [];
      
      WeeklyProgress? progress;
      for (final data in progressData) {
        final candidate = WeeklyProgress.fromJson(jsonDecode(data));
        if (candidate.routineId == routineId && candidate.weekOfYear == targetWeek) {
          progress = candidate;
          break;
        }
      }
      
      if (progress == null) return;
      
      // Get current routine structure
      final manager = await _routineService.loadRoutineManager();
      final routine = manager.routines.firstWhere((r) => r.id == routineId);
      
      // Quick check: if routine has same number of total exercises, likely no sync needed
      final currentTotalExercises = routine.weeklyPlan.fold(0, (sum, day) => sum + day.exercises.length);
      final cachedTotalExercises = progress.dailyProgress.values.fold(0, (sum, day) => sum + day.plannedExercises);
      
      if (currentTotalExercises == cachedTotalExercises) {
        // Likely no changes, skip detailed check for performance
        return;
      }
      
      // Check if any day's planned exercises count has changed
      bool needsUpdate = false;
      final updatedDailyProgress = <String, DayProgress>{};
      
      for (final day in routine.weeklyPlan) {
        final existingDayProgress = progress.dailyProgress[day.dayName];
        if (existingDayProgress != null) {
          final currentPlannedCount = day.exercises.length;
          if (existingDayProgress.plannedExercises != currentPlannedCount) {
            // Update planned exercises count while preserving completed exercises
            updatedDailyProgress[day.dayName] = existingDayProgress.copyWith(
              plannedExercises: currentPlannedCount,
            );
            needsUpdate = true;
          } else {
            updatedDailyProgress[day.dayName] = existingDayProgress;
          }
        } else {
          // Create new day progress if it doesn't exist
          updatedDailyProgress[day.dayName] = DayProgress(
            dayName: day.dayName,
            plannedExercises: day.exercises.length,
            completedExerciseIds: [],
            isRestDay: day.isRestDay,
          );
          needsUpdate = true;
        }
      }
      
      if (needsUpdate) {
        final updatedProgress = progress.copyWith(dailyProgress: updatedDailyProgress);
        await _saveWeeklyProgress(updatedProgress);
        
        // Update cache immediately
        final cacheKey = '${routineId}_$targetWeek';
        _weeklyProgressCache[cacheKey] = updatedProgress;
        
        _log.info('Synced planned exercises count for routine: $routineId');
      }
    } catch (e) {
      _log.severe('Error syncing planned exercises with routine: $e');
    }
  }
}