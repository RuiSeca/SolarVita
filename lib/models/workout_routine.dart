import '../screens/search/workout_detail/models/workout_item.dart';
import '../screens/search/workout_detail/models/workout_step.dart';

/// Represents a single day's workout in a routine
class DailyWorkout {
  final String dayName; // "Monday", "Tuesday", etc.
  final List<WorkoutItem> exercises;
  final bool isRestDay;
  final String? notes;

  DailyWorkout({
    required this.dayName,
    required this.exercises,
    this.isRestDay = false,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'dayName': dayName,
      'exercises': exercises.map((e) => _workoutItemToJson(e)).toList(),
      'isRestDay': isRestDay,
      'notes': notes,
    };
  }

  static DailyWorkout fromJson(Map<String, dynamic> json) {
    return DailyWorkout(
      dayName: json['dayName'],
      exercises: (json['exercises'] as List)
          .map((e) => _workoutItemFromJson(e))
          .toList(),
      isRestDay: json['isRestDay'] ?? false,
      notes: json['notes'],
    );
  }

  // Helper methods for WorkoutItem serialization
  static Map<String, dynamic> _workoutItemToJson(WorkoutItem item) {
    return {
      'title': item.title,
      'image': item.image,
      'duration': item.duration,
      'difficulty': item.difficulty,
      'description': item.description,
      'rating': item.rating,
      'caloriesBurn': item.caloriesBurn,
      'equipment': item.equipment,
      'tips': item.tips,
      'steps': item.steps.map((step) => {
        'title': step.title,
        'duration': step.duration,
        'description': step.description,
        'instructions': step.instructions,
        'gifUrl': step.gifUrl,
        'isCompleted': step.isCompleted,
      }).toList(),
    };
  }

  static WorkoutItem _workoutItemFromJson(Map<String, dynamic> json) {
    return WorkoutItem(
      title: json['title'],
      image: json['image'],
      duration: json['duration'],
      difficulty: json['difficulty'],
      description: json['description'],
      rating: json['rating']?.toDouble() ?? 0.0,
      caloriesBurn: json['caloriesBurn'],
      equipment: List<String>.from(json['equipment'] ?? []),
      tips: List<String>.from(json['tips'] ?? []),
      steps: (json['steps'] as List).map((step) => WorkoutStep(
        title: step['title'],
        duration: step['duration'],
        description: step['description'],
        instructions: List<String>.from(step['instructions']),
        gifUrl: step['gifUrl'],
        isCompleted: step['isCompleted'] ?? false,
      )).toList(),
    );
  }
}

/// Represents a complete workout routine with 7 days
class WorkoutRoutine {
  final String id;
  final String name; // User-defined name like "Strength Week", "Cardio Blast"
  final List<DailyWorkout> weeklyPlan; // Always 7 days
  final DateTime createdAt;
  final DateTime lastModified;
  final String? description;
  final String? category; // "Strength", "Cardio", "Mixed", etc.
  final bool isActive; // Currently selected routine

  WorkoutRoutine({
    required this.id,
    required this.name,
    required this.weeklyPlan,
    required this.createdAt,
    required this.lastModified,
    this.description,
    this.category,
    this.isActive = false,
  });

  /// Creates an empty routine with 7 days
  factory WorkoutRoutine.empty(String name) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final weeklyPlan = days.map((day) => DailyWorkout(
      dayName: day,
      exercises: [],
    )).toList();

    return WorkoutRoutine(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      weeklyPlan: weeklyPlan,
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
    );
  }

  /// Gets exercises for a specific day
  DailyWorkout getDayWorkout(String dayName) {
    return weeklyPlan.firstWhere(
      (day) => day.dayName.toLowerCase() == dayName.toLowerCase(),
      orElse: () => DailyWorkout(dayName: dayName, exercises: []),
    );
  }

  /// Updates exercises for a specific day
  WorkoutRoutine updateDay(String dayName, List<WorkoutItem> exercises, {String? notes, bool? isRestDay}) {
    final updatedWeeklyPlan = weeklyPlan.map((day) {
      if (day.dayName.toLowerCase() == dayName.toLowerCase()) {
        return DailyWorkout(
          dayName: day.dayName,
          exercises: exercises,
          notes: notes ?? day.notes,
          isRestDay: isRestDay ?? day.isRestDay,
        );
      }
      return day;
    }).toList();

    return WorkoutRoutine(
      id: id,
      name: name,
      weeklyPlan: updatedWeeklyPlan,
      createdAt: createdAt,
      lastModified: DateTime.now(),
      description: description,
      category: category,
      isActive: isActive,
    );
  }

  /// Gets total weekly workout count
  int get totalWorkouts => weeklyPlan.fold(0, (sum, day) => sum + day.exercises.length);

  /// Gets total weekly duration in minutes
  int get totalWeeklyMinutes {
    return weeklyPlan.fold(0, (sum, day) {
      return sum + day.exercises.fold(0, (daySum, exercise) {
        return daySum + _parseDurationToMinutes(exercise.duration);
      });
    });
  }
  
  int _parseDurationToMinutes(String duration) {
    // Handle different duration formats: "30s", "2m", "90", "1:30", "1.5m", "60-90"
    final lowerDuration = duration.toLowerCase().trim();
    
    // Handle ranges like "60-90" or "60-90s" - use the lowest value
    if (lowerDuration.contains('-')) {
      final parts = lowerDuration.split('-');
      if (parts.length == 2) {
        final firstPart = parts[0].trim();
        // Use the first (lowest) value from the range
        return _parseSingleDuration(firstPart);
      }
    }
    
    return _parseSingleDuration(lowerDuration);
  }
  
  int _parseSingleDuration(String duration) {
    final lowerDuration = duration.toLowerCase().trim();
    
    // If it contains 's' (seconds)
    if (lowerDuration.contains('s')) {
      final seconds = int.tryParse(lowerDuration.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
      return (seconds / 60).ceil(); // Convert seconds to minutes (round up)
    }
    
    // If it contains 'm' (minutes)
    if (lowerDuration.contains('m')) {
      final minutes = double.tryParse(lowerDuration.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
      return minutes.round();
    }
    
    // If it contains ':' (mm:ss format)
    if (lowerDuration.contains(':')) {
      final parts = lowerDuration.split(':');
      if (parts.length == 2) {
        final minutes = int.tryParse(parts[0]) ?? 0;
        final seconds = int.tryParse(parts[1]) ?? 0;
        return minutes + (seconds / 60).ceil();
      }
    }
    
    // Default: assume it's seconds if just a number
    final number = int.tryParse(lowerDuration.replaceAll(RegExp(r'[^\d]'), ''));
    if (number != null) {
      // If the number is > 10, assume it's seconds, otherwise minutes
      if (number > 10) {
        return (number / 60).ceil(); // Convert seconds to minutes
      } else {
        return number; // Assume minutes
      }
    }
    
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'weeklyPlan': weeklyPlan.map((day) => day.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'description': description,
      'category': category,
      'isActive': isActive,
    };
  }

  static WorkoutRoutine fromJson(Map<String, dynamic> json) {
    return WorkoutRoutine(
      id: json['id'],
      name: json['name'],
      weeklyPlan: (json['weeklyPlan'] as List)
          .map((day) => DailyWorkout.fromJson(day))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      lastModified: DateTime.parse(json['lastModified']),
      description: json['description'],
      category: json['category'],
      isActive: json['isActive'] ?? false,
    );
  }
}

/// Manages multiple workout routines (max 5 slots)
class RoutineManager {
  final List<WorkoutRoutine> routines;
  static const int maxRoutines = 5;

  RoutineManager({required this.routines});

  factory RoutineManager.empty() {
    return RoutineManager(routines: []);
  }

  /// Gets currently active routine
  WorkoutRoutine? get activeRoutine {
    try {
      return routines.firstWhere((routine) => routine.isActive);
    } catch (e) {
      return null;
    }
  }

  /// Creates a new routine if slots available
  RoutineManager addRoutine(String name) {
    if (routines.length >= maxRoutines) {
      throw Exception('Maximum $maxRoutines routines allowed');
    }

    final newRoutine = WorkoutRoutine.empty(name);
    return RoutineManager(routines: [...routines, newRoutine]);
  }

  /// Sets a routine as active (deactivates others)
  RoutineManager setActiveRoutine(String routineId) {
    final updatedRoutines = routines.map((routine) {
      return WorkoutRoutine(
        id: routine.id,
        name: routine.name,
        weeklyPlan: routine.weeklyPlan,
        createdAt: routine.createdAt,
        lastModified: routine.lastModified,
        description: routine.description,
        category: routine.category,
        isActive: routine.id == routineId,
      );
    }).toList();

    return RoutineManager(routines: updatedRoutines);
  }

  /// Updates a specific routine
  RoutineManager updateRoutine(WorkoutRoutine updatedRoutine) {
    final updatedRoutines = routines.map((routine) {
      return routine.id == updatedRoutine.id ? updatedRoutine : routine;
    }).toList();

    return RoutineManager(routines: updatedRoutines);
  }

  /// Deletes a routine
  RoutineManager deleteRoutine(String routineId) {
    final updatedRoutines = routines.where((routine) => routine.id != routineId).toList();
    return RoutineManager(routines: updatedRoutines);
  }

  /// Gets available slots count
  int get availableSlots => maxRoutines - routines.length;

  Map<String, dynamic> toJson() {
    return {
      'routines': routines.map((routine) => routine.toJson()).toList(),
    };
  }

  static RoutineManager fromJson(Map<String, dynamic> json) {
    return RoutineManager(
      routines: (json['routines'] as List)
          .map((routine) => WorkoutRoutine.fromJson(routine))
          .toList(),
    );
  }
}