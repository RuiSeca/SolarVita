// lib/services/exercise_tracking_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:logging/logging.dart';
import '../models/exercise_log.dart';
import '../models/personal_record.dart';
import 'notification_service.dart';

class ExerciseTrackingService {
  static final ExerciseTrackingService _instance =
      ExerciseTrackingService._internal();
  final Logger _log = Logger('ExerciseTrackingService');
  final Uuid _uuid = Uuid();
  final NotificationService _notificationService = NotificationService();

  factory ExerciseTrackingService() {
    return _instance;
  }

  ExerciseTrackingService._internal();

  // Keys for SharedPreferences
  static const String _logsKey = 'exercise_logs';
  static const String _recordsKey = 'personal_records';

  // Save a new exercise log
  Future<bool> saveExerciseLog(ExerciseLog log) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> logs = prefs.getStringList(_logsKey) ?? [];

      // Add the new log
      logs.add(jsonEncode(log.toJson()));

      // Save back to SharedPreferences
      final result = await prefs.setStringList(_logsKey, logs);

      // Check for personal records
      final isNewRecord = await _checkForPersonalRecords(log);

      // Send celebration notification if it's a new record
      if (isNewRecord) {
        await _notificationService.sendProgressCelebration(
          achievement: 'New Personal Record!',
          message: 'You hit a new PR in ${log.exerciseName}! 🎉',
        );
      } else {
        // Send regular progress update
        await _notificationService.sendProgressCelebration(
          achievement: 'Workout Complete!',
          message: 'Great job completing your ${log.exerciseName} workout!',
        );
      }

      return result;
    } catch (e) {
      _log.severe('Error saving exercise log: $e');
      return false;
    }
  }

  // Add method to schedule workout reminders
  Future<void> scheduleWorkoutReminder(
      DateTime scheduledTime, String workoutType) async {
    await _notificationService.scheduleWorkoutReminder(
      title: '💪 Workout Time!',
      body: 'Time for your $workoutType workout. Let\'s get moving!',
      scheduledTime: scheduledTime,
      workoutType: workoutType,
    );
  }

  // Generate a new unique ID for logs
  String generateId() {
    return _uuid.v4();
  }

  // Get all exercise logs
  Future<List<ExerciseLog>> getAllLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> logs = prefs.getStringList(_logsKey) ?? [];

      final parsedLogs = logs.map((log) => ExerciseLog.fromJson(jsonDecode(log))).toList()
        ..sort((a, b) => b.date.compareTo(a.date)); // Sort by date (newest first)
      
      return parsedLogs;
    } catch (e) {
      _log.severe('Error getting exercise logs: $e');
      return [];
    }
  }

  // Get logs for a specific exercise
  Future<List<ExerciseLog>> getLogsForExercise(String exerciseId) async {
    final allLogs = await getAllLogs();
    return allLogs.where((log) => log.exerciseId == exerciseId).toList();
  }

  // Get logs within a date range
  Future<List<ExerciseLog>> getLogsByDateRange(
      DateTime start, DateTime end) async {
    final allLogs = await getAllLogs();
    return allLogs
        .where((log) => log.date.isAfter(start) && log.date.isBefore(end))
        .toList();
  }

  // Update an existing log
  Future<bool> updateLog(ExerciseLog updatedLog) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> logs = prefs.getStringList(_logsKey) ?? [];

      // Convert to list of ExerciseLog objects
      List<ExerciseLog> logObjects =
          logs.map((log) => ExerciseLog.fromJson(jsonDecode(log))).toList();

      // Find and update the log
      int index = logObjects.indexWhere((log) => log.id == updatedLog.id);
      if (index != -1) {
        logObjects[index] = updatedLog;

        // Convert back to list of strings
        List<String> updatedLogs =
            logObjects.map((log) => jsonEncode(log.toJson())).toList();

        // Save back to SharedPreferences
        final result = await prefs.setStringList(_logsKey, updatedLogs);

        // Re-check for personal records
        await _checkForPersonalRecords(updatedLog);

        return result;
      }

      return false;
    } catch (e) {
      _log.severe('Error updating exercise log: $e');
      return false;
    }
  }

  // Delete a log
  Future<bool> deleteLog(String logId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> logs = prefs.getStringList(_logsKey) ?? [];

      // Convert to list of ExerciseLog objects
      List<ExerciseLog> logObjects =
          logs.map((log) => ExerciseLog.fromJson(jsonDecode(log))).toList();

      // Remove the log
      logObjects.removeWhere((log) => log.id == logId);

      // Convert back to list of strings
      List<String> updatedLogs =
          logObjects.map((log) => jsonEncode(log.toJson())).toList();

      // Save back to SharedPreferences
      return await prefs.setStringList(_logsKey, updatedLogs);
    } catch (e) {
      _log.severe('Error deleting exercise log: $e');
      return false;
    }
  }

  // Check if a log contains any personal records
  Future<bool> _checkForPersonalRecords(ExerciseLog log) async {
    try {
      bool hasNewRecord = false;

      // Get existing records for this exercise
      final records = await getPersonalRecordsForExercise(log.exerciseId);

      // Check max weight record
      double maxWeight = log.maxWeight;
      PersonalRecord? existingMaxWeightRecord =
          records.where((r) => r.recordType == 'Max Weight').firstOrNull;

      if (existingMaxWeightRecord == null ||
          maxWeight > existingMaxWeightRecord.value) {
        // New PR for max weight
        await savePersonalRecord(PersonalRecord(
          exerciseId: log.exerciseId,
          exerciseName: log.exerciseName,
          recordType: 'Max Weight',
          value: maxWeight,
          date: log.date,
          logId: log.id,
        ));
        hasNewRecord = true;
      }

      // Check volume record
      double totalVolume = log.totalVolume;
      PersonalRecord? existingVolumeRecord =
          records.where((r) => r.recordType == 'Volume').firstOrNull;

      if (existingVolumeRecord == null ||
          totalVolume > existingVolumeRecord.value) {
        // New PR for volume
        await savePersonalRecord(PersonalRecord(
          exerciseId: log.exerciseId,
          exerciseName: log.exerciseName,
          recordType: 'Volume',
          value: totalVolume,
          date: log.date,
          logId: log.id,
        ));
        hasNewRecord = true;
      }

      return hasNewRecord;
    } catch (e) {
      _log.severe('Error checking for personal records: $e');
      return false;
    }
  }

  // Save a personal record
  Future<bool> savePersonalRecord(PersonalRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> records = prefs.getStringList(_recordsKey) ?? [];

      // Get existing records as objects
      List<PersonalRecord> recordObjects =
          records.map((r) => PersonalRecord.fromJson(jsonDecode(r))).toList();

      // Remove any existing record of the same type for this exercise
      recordObjects.removeWhere((r) =>
          r.exerciseId == record.exerciseId &&
          r.recordType == record.recordType);

      // Add the new record
      recordObjects.add(record);

      // Convert back to strings
      List<String> updatedRecords =
          recordObjects.map((r) => jsonEncode(r.toJson())).toList();

      // Save back to SharedPreferences
      return await prefs.setStringList(_recordsKey, updatedRecords);
    } catch (e) {
      _log.severe('Error saving personal record: $e');
      return false;
    }
  }

  // Get all personal records
  Future<List<PersonalRecord>> getAllPersonalRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> records = prefs.getStringList(_recordsKey) ?? [];

      return records.map((r) => PersonalRecord.fromJson(jsonDecode(r))).toList()
        ..sort(
            (a, b) => b.date.compareTo(a.date)); // Sort by date (newest first)
    } catch (e) {
      _log.severe('Error getting personal records: $e');
      return [];
    }
  }

  // Get personal records for a specific exercise
  Future<List<PersonalRecord>> getPersonalRecordsForExercise(
      String exerciseId) async {
    final allRecords = await getAllPersonalRecords();
    return allRecords.where((r) => r.exerciseId == exerciseId).toList();
  }
}
