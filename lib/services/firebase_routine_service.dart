// lib/services/firebase_routine_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import '../models/workout_routine.dart';
import '../models/exercise_log.dart';
import '../screens/search/workout_detail/models/workout_item.dart';
import '../screens/search/workout_detail/models/workout_step.dart';

class FirebaseRoutineService {
  static final FirebaseRoutineService _instance = FirebaseRoutineService._internal();
  factory FirebaseRoutineService() => _instance;
  FirebaseRoutineService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger('FirebaseRoutineService');

  // Collection names
  static const String _routinesCollection = 'user_routines';
  static const String _exerciseLogsCollection = 'exercise_logs';

  String? get currentUserId => _auth.currentUser?.uid;


  /// Upload user's active routine to Firebase
  Future<bool> syncUserRoutine(WorkoutRoutine routine) async {
    try {
      if (currentUserId == null) {
        _logger.severe('User not authenticated');
        return false;
      }

      final routineData = {
        'id': routine.id,
        'name': routine.name,
        'description': routine.description,
        'isActive': routine.isActive,
        'createdDate': routine.createdAt.toIso8601String(),
        'lastModified': DateTime.now().toIso8601String(),
        'dailyWorkouts': routine.weeklyPlan.map((day) => {
          'dayName': day.dayName,
          'isRestDay': day.isRestDay,
          'notes': day.notes,
          'exercises': day.exercises.map((exercise) => {
            'title': exercise.title,
            'image': exercise.image,
            'duration': exercise.duration,
            'difficulty': exercise.difficulty,
            'description': exercise.description,
            'rating': exercise.rating,
            'caloriesBurn': exercise.caloriesBurn,
            'equipment': exercise.equipment,
            'tips': exercise.tips,
            'steps': exercise.steps.map((step) => {
              'title': step.title,
              'description': step.description,
              'duration': step.duration,
              'gifUrl': step.gifUrl,
              'instructions': step.instructions,
              'isCompleted': step.isCompleted,
            }).toList(),
          }).toList(),
        }).toList(),
        'userId': currentUserId,
        'syncedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(_routinesCollection)
          .doc(currentUserId)
          .collection('routines')
          .doc(routine.id)
          .set(routineData, SetOptions(merge: true));

      _logger.info('Routine synced successfully: ${routine.name}');
      return true;
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        _logger.severe('Error syncing routine - Permission Denied: Please check Firestore security rules for user_routines collection');
      } else {
        _logger.severe('Error syncing routine: $e');
      }
      return false;
    }
  }

  /// Get user's active routine from Firebase
  Future<WorkoutRoutine?> getUserActiveRoutine(String userId) async {
    try {
      final routinesSnapshot = await _firestore
          .collection(_routinesCollection)
          .doc(userId)
          .collection('routines')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (routinesSnapshot.docs.isEmpty) {
        return null;
      }

      final routineDoc = routinesSnapshot.docs.first;
      final data = routineDoc.data();
      
      return _routineFromFirestore(data);
    } catch (e) {
      _logger.severe('Error getting user active routine: $e');
      return null;
    }
  }

  /// Upload exercise log to Firebase
  Future<bool> syncExerciseLog(ExerciseLog log) async {
    try {
      if (currentUserId == null) {
        _logger.severe('User not authenticated');
        return false;
      }

      final logData = {
        'id': log.id,
        'exerciseId': log.exerciseId,
        'exerciseName': log.exerciseName,
        'date': log.date.toIso8601String(),
        'sets': log.sets.map((set) => {
          'setNumber': set.setNumber,
          'weight': set.weight,
          'reps': set.reps,
          'distance': set.distance,
          'duration': set.duration?.inSeconds,
        }).toList(),
        'notes': log.notes,
        'routineId': log.routineId,
        'dayName': log.dayName,
        'weekOfYear': log.weekOfYear,
        'isPersonalRecord': log.isPersonalRecord,
        'totalVolume': log.totalVolume,
        'maxWeight': log.maxWeight,
        'maxReps': log.maxReps,
        'userId': currentUserId,
        'syncedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(_exerciseLogsCollection)
          .doc(currentUserId)
          .collection('logs')
          .doc(log.id)
          .set(logData, SetOptions(merge: true));

      _logger.info('Exercise log synced successfully: ${log.exerciseName}');
      return true;
    } catch (e) {
      _logger.severe('Error syncing exercise log: $e');
      return false;
    }
  }

  /// Get last logged exercise for a user
  Future<ExerciseLog?> getLastLoggedExercise(String userId) async {
    try {
      final logsSnapshot = await _firestore
          .collection(_exerciseLogsCollection)
          .doc(userId)
          .collection('logs')
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (logsSnapshot.docs.isEmpty) {
        return null;
      }

      final logDoc = logsSnapshot.docs.first;
      final data = logDoc.data();
      
      return _exerciseLogFromFirestore(data);
    } catch (e) {
      _logger.severe('Error getting last logged exercise: $e');
      return null;
    }
  }

  /// Get recent exercise logs for a user
  Future<List<ExerciseLog>> getRecentExerciseLogs(String userId, {int limit = 10}) async {
    try {
      final logsSnapshot = await _firestore
          .collection(_exerciseLogsCollection)
          .doc(userId)
          .collection('logs')
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return logsSnapshot.docs.map((doc) {
        return _exerciseLogFromFirestore(doc.data());
      }).toList();
    } catch (e) {
      _logger.severe('Error getting recent exercise logs: $e');
      return [];
    }
  }

  /// Get weekly progress for a user's routine
  Future<Map<String, dynamic>?> getWeeklyProgress(String userId, String routineId) async {
    try {
      final now = DateTime.now();
      final currentWeek = _calculateWeekOfYear(now);
      
      final progressSnapshot = await _firestore
          .collection('weekly_progress')
          .doc(userId)
          .collection('weeks')
          .where('routineId', isEqualTo: routineId)
          .where('weekOfYear', isEqualTo: currentWeek)
          .where('year', isEqualTo: now.year)
          .limit(1)
          .get();

      if (progressSnapshot.docs.isEmpty) {
        // Generate basic progress based on recent exercise logs
        return await _generateBasicProgress(userId, routineId, currentWeek, now.year);
      }

      return progressSnapshot.docs.first.data();
    } catch (e) {
      _logger.severe('Error getting weekly progress: $e');
      return null;
    }
  }

  /// Generate basic progress data from exercise logs when no weekly progress exists
  Future<Map<String, dynamic>> _generateBasicProgress(String userId, String routineId, int weekOfYear, int year) async {
    try {
      // Get recent logs from this week
      final weekStart = _getWeekStartDate(weekOfYear, year);
      final weekEnd = weekStart.add(const Duration(days: 7));
      
      final recentLogs = await _firestore
          .collection(_exerciseLogsCollection)
          .doc(userId)
          .collection('logs')
          .where('routineId', isEqualTo: routineId)
          .where('date', isGreaterThanOrEqualTo: weekStart.toIso8601String())
          .where('date', isLessThan: weekEnd.toIso8601String())
          .get();

      // Count completed exercises by day
      final dailyProgress = <String, Map<String, dynamic>>{};
      final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      
      // Initialize all days
      for (final day in dayNames) {
        dailyProgress[day] = {
          'dayName': day,
          'plannedExercises': 0, // We don't have this info from logs alone
          'completedExerciseIds': <String>[],
          'isRestDay': false,
          'lastUpdated': DateTime.now().toIso8601String(),
        };
      }
      
      // Fill in completed exercises
      for (final logDoc in recentLogs.docs) {
        final logData = logDoc.data();
        final dayName = logData['dayName'] as String?;
        final exerciseId = logData['exerciseId'] as String?;
        
        if (dayName != null && exerciseId != null && dailyProgress.containsKey(dayName)) {
          final completedIds = List<String>.from(dailyProgress[dayName]!['completedExerciseIds']);
          if (!completedIds.contains(exerciseId)) {
            completedIds.add(exerciseId);
            dailyProgress[dayName]!['completedExerciseIds'] = completedIds;
          }
        }
      }

      return {
        'routineId': routineId,
        'weekOfYear': weekOfYear,
        'year': year,
        'weekStartDate': weekStart.toIso8601String(),
        'dailyProgress': dailyProgress,
        'isGenerated': true, // Flag to indicate this is generated, not stored
      };
    } catch (e) {
      _logger.severe('Error generating basic progress: $e');
      return {
        'routineId': routineId,
        'weekOfYear': weekOfYear,
        'year': year,
        'dailyProgress': <String, dynamic>{},
        'isGenerated': true,
      };
    }
  }

  /// Helper method to calculate week of year
  int _calculateWeekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday - 1) / 7).ceil();
  }

  /// Helper method to get week start date
  DateTime _getWeekStartDate(int weekOfYear, int year) {
    final firstDayOfYear = DateTime(year, 1, 1);
    final daysToAdd = (weekOfYear - 1) * 7 - (firstDayOfYear.weekday - 1);
    return firstDayOfYear.add(Duration(days: daysToAdd));
  }

  /// Sync weekly progress data to Firebase
  Future<bool> syncWeeklyProgress(Map<String, dynamic> progressData) async {
    try {
      if (currentUserId == null) {
        _logger.severe('User not authenticated');
        return false;
      }

      final routineId = progressData['routineId'] as String;
      final weekOfYear = progressData['weekOfYear'] as int;
      final year = progressData['year'] as int;
      
      final docId = '${routineId}_${year}_week$weekOfYear';
      
      final syncData = Map<String, dynamic>.from(progressData);
      syncData['userId'] = currentUserId;
      syncData['syncedAt'] = FieldValue.serverTimestamp();
      
      await _firestore
          .collection('weekly_progress')
          .doc(currentUserId)
          .collection('weeks')
          .doc(docId)
          .set(syncData, SetOptions(merge: true));

      _logger.info('Weekly progress synced successfully for week $weekOfYear');
      return true;
    } catch (e) {
      _logger.severe('Error syncing weekly progress: $e');
      return false;
    }
  }

  /// Copy routine from another user
  Future<bool> copyRoutineFromUser(String sourceUserId, String routineId) async {
    try {
      if (currentUserId == null) {
        _logger.severe('User not authenticated');
        return false;
      }

      // Get the source routine
      final sourceRoutineDoc = await _firestore
          .collection(_routinesCollection)
          .doc(sourceUserId)
          .collection('routines')
          .doc(routineId)
          .get();

      if (!sourceRoutineDoc.exists) {
        _logger.severe('Source routine not found');
        return false;
      }

      final sourceData = sourceRoutineDoc.data()!;
      
      // Create a new routine for current user
      final newRoutineId = _firestore.collection('temp').doc().id;
      final copiedRoutineData = Map<String, dynamic>.from(sourceData);
      
      // Update the routine for the new user
      copiedRoutineData['id'] = newRoutineId;
      copiedRoutineData['userId'] = currentUserId;
      copiedRoutineData['name'] = '${copiedRoutineData['name']} (Copy)';
      copiedRoutineData['isActive'] = false; // Don't make it active by default
      copiedRoutineData['createdDate'] = DateTime.now().toIso8601String();
      copiedRoutineData['lastModified'] = DateTime.now().toIso8601String();
      copiedRoutineData['syncedAt'] = FieldValue.serverTimestamp();
      
      // Reset all exercise completion status
      if (copiedRoutineData['dailyWorkouts'] != null) {
        final dailyWorkouts = List<Map<String, dynamic>>.from(copiedRoutineData['dailyWorkouts']);
        for (var day in dailyWorkouts) {
          if (day['exercises'] != null) {
            final exercises = List<Map<String, dynamic>>.from(day['exercises']);
            for (var exercise in exercises) {
              if (exercise['steps'] != null) {
                final steps = List<Map<String, dynamic>>.from(exercise['steps']);
                for (var step in steps) {
                  step['isCompleted'] = false;
                }
                exercise['steps'] = steps;
              }
            }
            day['exercises'] = exercises;
          }
        }
        copiedRoutineData['dailyWorkouts'] = dailyWorkouts;
      }

      // Save the copied routine
      await _firestore
          .collection(_routinesCollection)
          .doc(currentUserId)
          .collection('routines')
          .doc(newRoutineId)
          .set(copiedRoutineData);

      _logger.info('Routine copied successfully from user $sourceUserId');
      return true;
    } catch (e) {
      _logger.severe('Error copying routine: $e');
      return false;
    }
  }

  /// Helper method to convert Firestore data to WorkoutRoutine
  WorkoutRoutine _routineFromFirestore(Map<String, dynamic> data) {
    return WorkoutRoutine(
      id: data['id'],
      name: data['name'],
      weeklyPlan: (data['dailyWorkouts'] as List).map((dayData) {
        return DailyWorkout(
          dayName: dayData['dayName'],
          isRestDay: dayData['isRestDay'] ?? false,
          notes: dayData['notes'],
          exercises: (dayData['exercises'] as List).map((exerciseData) {
            return WorkoutItem(
              title: exerciseData['title'],
              image: exerciseData['image'],
              duration: exerciseData['duration'],
              difficulty: exerciseData['difficulty'],
              description: exerciseData['description'],
              rating: exerciseData['rating']?.toDouble() ?? 0.0,
              caloriesBurn: exerciseData['caloriesBurn'],
              equipment: List<String>.from(exerciseData['equipment'] ?? []),
              tips: List<String>.from(exerciseData['tips'] ?? []),
              steps: (exerciseData['steps'] as List).map((stepData) {
                return WorkoutStep(
                  title: stepData['title'],
                  description: stepData['description'],
                  duration: stepData['duration'],
                  gifUrl: stepData['gifUrl'],
                  instructions: List<String>.from(stepData['instructions'] ?? []),
                  isCompleted: stepData['isCompleted'] ?? false,
                );
              }).toList(),
            );
          }).toList(),
        );
      }).toList(),
      createdAt: DateTime.parse(data['createdDate']),
      lastModified: DateTime.parse(data['lastModified'] ?? data['createdDate']),
      description: data['description'],
      isActive: data['isActive'] ?? false,
    );
  }

  /// Helper method to convert Firestore data to ExerciseLog
  ExerciseLog _exerciseLogFromFirestore(Map<String, dynamic> data) {
    return ExerciseLog(
      id: data['id'],
      exerciseId: data['exerciseId'],
      exerciseName: data['exerciseName'],
      date: DateTime.parse(data['date']),
      sets: (data['sets'] as List).map((setData) {
        return ExerciseSet(
          setNumber: setData['setNumber'],
          weight: setData['weight']?.toDouble() ?? 0.0,
          reps: setData['reps'] ?? 0,
          distance: setData['distance']?.toDouble(),
          duration: setData['duration'] != null 
              ? Duration(seconds: setData['duration']) 
              : null,
        );
      }).toList(),
      notes: data['notes'] ?? '',
      routineId: data['routineId'],
      dayName: data['dayName'],
      weekOfYear: data['weekOfYear'],
      isPersonalRecord: data['isPersonalRecord'] ?? false,
    );
  }
}