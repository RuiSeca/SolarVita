import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import '../../models/templates/workout_template.dart';
import '../exercises/exercise_service.dart';
import '../../screens/search/workout_detail/models/workout_item.dart';

class WorkoutTemplateService {
  static final WorkoutTemplateService _instance = WorkoutTemplateService._internal();
  final Logger _log = Logger('WorkoutTemplateService');
  final ExerciseService _exerciseService = ExerciseService();

  factory WorkoutTemplateService() {
    return _instance;
  }

  WorkoutTemplateService._internal();

  static const String _customTemplatesKey = 'custom_workout_templates';

  // Get all available templates (built-in + custom)
  Future<List<WorkoutTemplate>> getAllTemplates() async {
    try {
      final builtInTemplates = await _getBuiltInTemplates();
      final customTemplates = await getCustomTemplates();
      
      final allTemplates = [...builtInTemplates, ...customTemplates];
      
      // Sort by popularity and category
      allTemplates.sort((a, b) {
        if (a.category != b.category) {
          return a.category.compareTo(b.category);
        }
        return b.popularityScore.compareTo(a.popularityScore);
      });
      
      return allTemplates;
    } catch (e) {
      _log.severe('Error getting all templates: $e');
      return await _getBuiltInTemplates(); // Fallback to built-in only
    }
  }

  // Get templates by category
  Future<List<WorkoutTemplate>> getTemplatesByCategory(String category) async {
    final allTemplates = await getAllTemplates();
    return allTemplates.where((template) => template.category == category).toList();
  }

  // Get templates by difficulty
  Future<List<WorkoutTemplate>> getTemplatesByDifficulty(String difficulty) async {
    final allTemplates = await getAllTemplates();
    return allTemplates.where((template) => template.difficulty == difficulty).toList();
  }

  // Get templates by equipment needed
  Future<List<WorkoutTemplate>> getTemplatesByEquipment(List<String> availableEquipment) async {
    final allTemplates = await getAllTemplates();
    return allTemplates.where((template) {
      return template.equipment.every((equipment) => 
        equipment == 'none' || availableEquipment.contains(equipment)
      );
    }).toList();
  }

  // Get popular/recommended templates
  Future<List<WorkoutTemplate>> getPopularTemplates({int limit = 10}) async {
    final allTemplates = await getAllTemplates();
    allTemplates.sort((a, b) => b.popularityScore.compareTo(a.popularityScore));
    return allTemplates.take(limit).toList();
  }

  // Get template by ID
  Future<WorkoutTemplate?> getTemplateById(String id) async {
    final allTemplates = await getAllTemplates();
    try {
      return allTemplates.firstWhere((template) => template.id == id);
    } catch (e) {
      return null;
    }
  }

  // Save custom template
  Future<bool> saveCustomTemplate(WorkoutTemplate template) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> templates = prefs.getStringList(_customTemplatesKey) ?? [];

      // Convert template to JSON and add to list
      final templateJson = jsonEncode(template.toJson());
      templates.add(templateJson);

      await prefs.setStringList(_customTemplatesKey, templates);
      _log.info('Custom template saved: ${template.name}');
      return true;
    } catch (e) {
      _log.severe('Error saving custom template: $e');
      return false;
    }
  }

  // Update existing custom template
  Future<bool> updateCustomTemplate(WorkoutTemplate template) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> templates = prefs.getStringList(_customTemplatesKey) ?? [];

      // Find and update the template
      bool found = false;
      for (int i = 0; i < templates.length; i++) {
        final json = jsonDecode(templates[i]) as Map<String, dynamic>;
        if (json['id'] == template.id) {
          templates[i] = jsonEncode(template.toJson());
          found = true;
          break;
        }
      }

      if (found) {
        await prefs.setStringList(_customTemplatesKey, templates);
        _log.info('Custom template updated: ${template.name}');
        return true;
      }
      return false;
    } catch (e) {
      _log.severe('Error updating custom template: $e');
      return false;
    }
  }

  // Get custom templates
  Future<List<WorkoutTemplate>> getCustomTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> templates = prefs.getStringList(_customTemplatesKey) ?? [];

      return templates.map((templateJson) {
        final json = jsonDecode(templateJson) as Map<String, dynamic>;
        return WorkoutTemplate.fromJson(json);
      }).toList();
    } catch (e) {
      _log.severe('Error getting custom templates: $e');
      return [];
    }
  }

  // Delete custom template
  Future<bool> deleteCustomTemplate(String templateId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> templates = prefs.getStringList(_customTemplatesKey) ?? [];

      templates.removeWhere((templateJson) {
        final json = jsonDecode(templateJson) as Map<String, dynamic>;
        return json['id'] == templateId;
      });

      await prefs.setStringList(_customTemplatesKey, templates);
      return true;
    } catch (e) {
      _log.severe('Error deleting custom template: $e');
      return false;
    }
  }

  // Increment template usage (for popularity scoring)
  Future<void> incrementTemplateUsage(String templateId) async {
    // For built-in templates, we could track usage locally
    // For now, just log the usage
    _log.info('Template used: $templateId');
  }

  // Built-in templates - using real ExerciseDB API data!
  Future<List<WorkoutTemplate>> _getBuiltInTemplates() async {
    try {
      final templates = <WorkoutTemplate>[];
      
      // Push Day Template (Chest, Shoulders, Triceps)
      templates.add(await _createPushDayTemplate());
      
      // Pull Day Template (Back, Biceps)
      templates.add(await _createPullDayTemplate());
      
      // Leg Day Template (Quads, Hamstrings, Glutes, Calves)
      templates.add(await _createLegDayTemplate());
      
      // Full Body Beginner Template
      templates.add(await _createFullBodyBeginnerTemplate());
      
      // HIIT Cardio Template
      templates.add(await _createHIITCardioTemplate());
      
      return templates;
    } catch (e) {
      _log.severe('Error creating built-in templates: $e');
      return _getFallbackTemplates(); // Return basic templates if API fails
    }
  }

  Future<WorkoutTemplate> _createPushDayTemplate() async {
    final chestExercises = await _exerciseService.getExercisesByTarget('pectorals');
    final shoulderExercises = await _exerciseService.getExercisesByTarget('delts');
    final tricepsExercises = await _exerciseService.getExercisesByTarget('triceps');
    
    final exercises = <TemplateExercise>[];
    
    // Add 2 chest exercises
    if (chestExercises.isNotEmpty) {
      exercises.add(_createTemplateExercise(
        chestExercises.first, // Usually bench press or push-ups
        [
          TemplateSet(setNumber: 1, type: SetType.warmup, targetReps: 15, targetWeight: 40),
          TemplateSet(setNumber: 2, targetReps: 10, targetWeight: 60),
          TemplateSet(setNumber: 3, targetReps: 8, targetWeight: 70),
          TemplateSet(setNumber: 4, targetReps: 8, targetWeight: 70),
        ],
        restSeconds: 180,
      ));
      
      if (chestExercises.length > 1) {
        exercises.add(_createTemplateExercise(
          chestExercises[1], // Secondary chest exercise
          [
            TemplateSet(setNumber: 1, targetReps: 12, targetWeight: 50),
            TemplateSet(setNumber: 2, targetReps: 10, targetWeight: 55),
            TemplateSet(setNumber: 3, targetReps: 8, targetWeight: 60),
          ],
          restSeconds: 120,
        ));
      }
    }
    
    // Add 1 shoulder exercise
    if (shoulderExercises.isNotEmpty) {
      exercises.add(_createTemplateExercise(
        shoulderExercises.first,
        [
          TemplateSet(setNumber: 1, targetReps: 12, targetWeight: 20),
          TemplateSet(setNumber: 2, targetReps: 10, targetWeight: 25),
          TemplateSet(setNumber: 3, targetReps: 8, targetWeight: 30),
        ],
        restSeconds: 90,
      ));
    }
    
    // Add 1 triceps exercise
    if (tricepsExercises.isNotEmpty) {
      exercises.add(_createTemplateExercise(
        tricepsExercises.first,
        [
          TemplateSet(setNumber: 1, targetReps: 15, targetWeight: 15),
          TemplateSet(setNumber: 2, targetReps: 12, targetWeight: 20),
          TemplateSet(setNumber: 3, targetReps: 10, targetWeight: 25),
        ],
        restSeconds: 90,
      ));
    }

    return WorkoutTemplate(
      id: 'push-day-intermediate',
      name: 'Push Day',
      description: 'Target chest, shoulders, and triceps with compound and isolation movements',
      category: 'strength',
      difficulty: 'intermediate',
      estimatedDuration: 60,
      targetMuscles: ['pectorals', 'delts', 'triceps'],
      equipment: ['dumbbells', 'barbell'],
      exercises: exercises,
      popularityScore: 95,
    );
  }

  Future<WorkoutTemplate> _createPullDayTemplate() async {
    final backExercises = await _exerciseService.getExercisesByTarget('lats');
    final bicepsExercises = await _exerciseService.getExercisesByTarget('biceps');
    
    final exercises = <TemplateExercise>[];
    
    // Add 2 back exercises
    if (backExercises.isNotEmpty) {
      exercises.add(_createTemplateExercise(
        backExercises.first, // Usually pull-ups or lat pulldowns
        [
          TemplateSet(setNumber: 1, type: SetType.warmup, targetReps: 8, targetWeight: 40),
          TemplateSet(setNumber: 2, targetReps: 6, targetWeight: 60),
          TemplateSet(setNumber: 3, targetReps: 5, targetWeight: 70),
          TemplateSet(setNumber: 4, targetReps: 5, targetWeight: 70),
        ],
        restSeconds: 180,
      ));
      
      if (backExercises.length > 1) {
        exercises.add(_createTemplateExercise(
          backExercises[1],
          [
            TemplateSet(setNumber: 1, targetReps: 12, targetWeight: 50),
            TemplateSet(setNumber: 2, targetReps: 10, targetWeight: 55),
            TemplateSet(setNumber: 3, targetReps: 8, targetWeight: 60),
          ],
          restSeconds: 120,
        ));
      }
    }
    
    // Add 2 biceps exercises
    if (bicepsExercises.isNotEmpty) {
      exercises.add(_createTemplateExercise(
        bicepsExercises.first,
        [
          TemplateSet(setNumber: 1, targetReps: 12, targetWeight: 15),
          TemplateSet(setNumber: 2, targetReps: 10, targetWeight: 20),
          TemplateSet(setNumber: 3, targetReps: 8, targetWeight: 25),
        ],
        restSeconds: 90,
      ));
      
      if (bicepsExercises.length > 1) {
        exercises.add(_createTemplateExercise(
          bicepsExercises[1],
          [
            TemplateSet(setNumber: 1, targetReps: 15, targetWeight: 10),
            TemplateSet(setNumber: 2, targetReps: 12, targetWeight: 12),
            TemplateSet(setNumber: 3, targetReps: 10, targetWeight: 15),
          ],
          restSeconds: 60,
        ));
      }
    }

    return WorkoutTemplate(
      id: 'pull-day-intermediate',
      name: 'Pull Day',
      description: 'Build a strong back and biceps with pulling movements',
      category: 'strength',
      difficulty: 'intermediate',
      estimatedDuration: 55,
      targetMuscles: ['lats', 'biceps'],
      equipment: ['dumbbells', 'pull_up_bar'],
      exercises: exercises,
      popularityScore: 90,
    );
  }

  Future<WorkoutTemplate> _createLegDayTemplate() async {
    final quadExercises = await _exerciseService.getExercisesByTarget('quads');
    final hamstringExercises = await _exerciseService.getExercisesByTarget('hamstrings');
    final gluteExercises = await _exerciseService.getExercisesByTarget('glutes');
    final calfExercises = await _exerciseService.getExercisesByTarget('calves');
    
    final exercises = <TemplateExercise>[];
    
    // Add compound leg exercise
    if (quadExercises.isNotEmpty) {
      exercises.add(_createTemplateExercise(
        quadExercises.first, // Usually squats
        [
          TemplateSet(setNumber: 1, type: SetType.warmup, targetReps: 12, targetWeight: 40),
          TemplateSet(setNumber: 2, targetReps: 10, targetWeight: 60),
          TemplateSet(setNumber: 3, targetReps: 8, targetWeight: 80),
          TemplateSet(setNumber: 4, targetReps: 6, targetWeight: 90),
        ],
        restSeconds: 180,
      ));
    }
    
    // Add hamstring exercise
    if (hamstringExercises.isNotEmpty) {
      exercises.add(_createTemplateExercise(
        hamstringExercises.first,
        [
          TemplateSet(setNumber: 1, targetReps: 12, targetWeight: 30),
          TemplateSet(setNumber: 2, targetReps: 10, targetWeight: 35),
          TemplateSet(setNumber: 3, targetReps: 8, targetWeight: 40),
        ],
        restSeconds: 120,
      ));
    }
    
    // Add glute exercise
    if (gluteExercises.isNotEmpty) {
      exercises.add(_createTemplateExercise(
        gluteExercises.first,
        [
          TemplateSet(setNumber: 1, targetReps: 15, targetWeight: 20),
          TemplateSet(setNumber: 2, targetReps: 12, targetWeight: 25),
          TemplateSet(setNumber: 3, targetReps: 10, targetWeight: 30),
        ],
        restSeconds: 90,
      ));
    }
    
    // Add calf exercise
    if (calfExercises.isNotEmpty) {
      exercises.add(_createTemplateExercise(
        calfExercises.first,
        [
          TemplateSet(setNumber: 1, targetReps: 20, targetWeight: 20),
          TemplateSet(setNumber: 2, targetReps: 18, targetWeight: 25),
          TemplateSet(setNumber: 3, targetReps: 15, targetWeight: 30),
        ],
        restSeconds: 60,
      ));
    }

    return WorkoutTemplate(
      id: 'leg-day-intermediate',
      name: 'Leg Day',
      description: 'Complete lower body workout targeting all major leg muscles',
      category: 'strength',
      difficulty: 'intermediate',
      estimatedDuration: 65,
      targetMuscles: ['quads', 'hamstrings', 'glutes', 'calves'],
      equipment: ['dumbbells', 'barbell'],
      exercises: exercises,
      popularityScore: 85,
    );
  }

  Future<WorkoutTemplate> _createFullBodyBeginnerTemplate() async {
    final exercises = <TemplateExercise>[];
    
    // Get exercises for different muscle groups
    final chestExercises = await _exerciseService.getExercisesByTarget('pectorals');
    final backExercises = await _exerciseService.getExercisesByTarget('lats');
    final legExercises = await _exerciseService.getExercisesByTarget('quads');
    final shoulderExercises = await _exerciseService.getExercisesByTarget('delts');
    
    // Add one exercise per major muscle group
    if (chestExercises.isNotEmpty) {
      exercises.add(_createTemplateExercise(
        chestExercises.first,
        [
          TemplateSet(setNumber: 1, targetReps: 12, targetWeight: 20),
          TemplateSet(setNumber: 2, targetReps: 10, targetWeight: 25),
        ],
        restSeconds: 90,
      ));
    }
    
    if (backExercises.isNotEmpty) {
      exercises.add(_createTemplateExercise(
        backExercises.first,
        [
          TemplateSet(setNumber: 1, targetReps: 10, targetWeight: 30),
          TemplateSet(setNumber: 2, targetReps: 8, targetWeight: 35),
        ],
        restSeconds: 90,
      ));
    }
    
    if (legExercises.isNotEmpty) {
      exercises.add(_createTemplateExercise(
        legExercises.first,
        [
          TemplateSet(setNumber: 1, targetReps: 15, targetWeight: 20),
          TemplateSet(setNumber: 2, targetReps: 12, targetWeight: 25),
        ],
        restSeconds: 120,
      ));
    }
    
    if (shoulderExercises.isNotEmpty) {
      exercises.add(_createTemplateExercise(
        shoulderExercises.first,
        [
          TemplateSet(setNumber: 1, targetReps: 12, targetWeight: 10),
          TemplateSet(setNumber: 2, targetReps: 10, targetWeight: 12),
        ],
        restSeconds: 60,
      ));
    }

    return WorkoutTemplate(
      id: 'full-body-beginner',
      name: 'Full Body Beginner',
      description: 'Perfect starter workout hitting all major muscle groups',
      category: 'full_body',
      difficulty: 'beginner',
      estimatedDuration: 40,
      targetMuscles: ['pectorals', 'lats', 'quads', 'delts'],
      equipment: ['dumbbells'],
      exercises: exercises,
      popularityScore: 100,
    );
  }

  Future<WorkoutTemplate> _createHIITCardioTemplate() async {
    // For cardio, we'll use bodyweight/cardio exercises
    final cardioExercises = await _exerciseService.getExercisesByTarget('cardiovascular system');
    
    final exercises = <TemplateExercise>[];
    
    if (cardioExercises.isNotEmpty) {
      // Take first 4 cardio exercises and create HIIT structure
      final selectedExercises = cardioExercises.take(4).toList();
      
      for (int i = 0; i < selectedExercises.length; i++) {
        exercises.add(_createTemplateExercise(
          selectedExercises[i],
          [
            TemplateSet(setNumber: 1, targetDuration: 45), // 45 seconds work
            TemplateSet(setNumber: 2, targetDuration: 45),
            TemplateSet(setNumber: 3, targetDuration: 45),
          ],
          restSeconds: 15, // 15 seconds rest between sets
          notes: 'Work for 45 seconds, rest for 15 seconds',
        ));
      }
    }

    return WorkoutTemplate(
      id: 'hiit-cardio-beginner',
      name: 'HIIT Cardio',
      description: 'High-intensity interval training for cardiovascular fitness',
      category: 'cardio',
      difficulty: 'beginner',
      estimatedDuration: 25,
      targetMuscles: ['cardiovascular system'],
      equipment: ['none'],
      exercises: exercises,
      popularityScore: 80,
    );
  }

  TemplateExercise _createTemplateExercise(
    WorkoutItem exercise, 
    List<TemplateSet> sets,
    {int? restSeconds, String? notes}
  ) {
    return TemplateExercise(
      id: exercise.title.hashCode.toString(),
      name: exercise.title,
      description: exercise.description,
      category: _mapEquipmentToCategory(exercise.equipment),
      sets: sets,
      restSeconds: restSeconds,
      notes: notes,
    );
  }

  String _mapEquipmentToCategory(List<String> equipment) {
    final equipmentText = equipment.join(' ').toLowerCase();
    if (equipmentText.contains('cardio') || equipmentText.contains('body weight')) {
      return 'cardio';
    } else if (equipmentText.contains('stretch') || equipmentText.contains('yoga')) {
      return 'flexibility';
    }
    return 'strength';
  }

  // Fallback templates if API fails
  List<WorkoutTemplate> _getFallbackTemplates() {
    return [
      // PUSH DAY TEMPLATE
      WorkoutTemplate(
        id: 'push-day-intermediate',
        name: 'Push Day',
        description: 'Complete push workout targeting chest, shoulders, and triceps with compound and isolation movements.',
        category: 'strength',
        difficulty: 'intermediate',
        estimatedDuration: 60,
        targetMuscles: ['chest', 'shoulders', 'triceps'],
        equipment: ['barbell', 'dumbbells', 'bench'],
        popularityScore: 95,
        exercises: [
          TemplateExercise(
            id: 'bench-press',
            name: 'Barbell Bench Press',
            category: 'strength',
            restSeconds: 180,
            sets: [
              const TemplateSet(setNumber: 1, type: SetType.warmup, targetReps: 12, targetWeight: 60),
              const TemplateSet(setNumber: 2, targetReps: 8, targetWeight: 80),
              const TemplateSet(setNumber: 3, targetReps: 6, targetWeight: 90),
              const TemplateSet(setNumber: 4, targetReps: 6, targetWeight: 90),
              const TemplateSet(setNumber: 5, targetReps: 8, targetWeight: 80),
            ],
          ),
          TemplateExercise(
            id: 'overhead-press',
            name: 'Standing Overhead Press',
            category: 'strength',
            restSeconds: 120,
            sets: [
              const TemplateSet(setNumber: 1, targetReps: 10, targetWeight: 50),
              const TemplateSet(setNumber: 2, targetReps: 8, targetWeight: 60),
              const TemplateSet(setNumber: 3, targetReps: 6, targetWeight: 65),
              const TemplateSet(setNumber: 4, targetReps: 8, targetWeight: 60),
            ],
          ),
          TemplateExercise(
            id: 'incline-dumbbell-press',
            name: 'Incline Dumbbell Press',
            category: 'strength',
            restSeconds: 90,
            sets: [
              const TemplateSet(setNumber: 1, targetReps: 10, targetWeight: 30),
              const TemplateSet(setNumber: 2, targetReps: 8, targetWeight: 35),
              const TemplateSet(setNumber: 3, targetReps: 8, targetWeight: 35),
            ],
          ),
          TemplateExercise(
            id: 'lateral-raises',
            name: 'Lateral Raises',
            category: 'strength',
            restSeconds: 60,
            sets: [
              const TemplateSet(setNumber: 1, targetReps: 12, targetWeight: 12),
              const TemplateSet(setNumber: 2, targetReps: 10, targetWeight: 15),
              const TemplateSet(setNumber: 3, targetReps: 12, targetWeight: 12),
            ],
          ),
          TemplateExercise(
            id: 'tricep-dips',
            name: 'Tricep Dips',
            category: 'strength',
            restSeconds: 90,
            sets: [
              const TemplateSet(setNumber: 1, minReps: 8, maxReps: 12),
              const TemplateSet(setNumber: 2, minReps: 6, maxReps: 10),
              const TemplateSet(setNumber: 3, minReps: 8, maxReps: 12),
            ],
          ),
        ],
      ),

      // PULL DAY TEMPLATE
      WorkoutTemplate(
        id: 'pull-day-intermediate',
        name: 'Pull Day',
        description: 'Complete pull workout for back, rear delts, and biceps with heavy compounds and targeted isolation.',
        category: 'strength',
        difficulty: 'intermediate',
        estimatedDuration: 65,
        targetMuscles: ['back', 'biceps', 'rear_delts'],
        equipment: ['barbell', 'dumbbells', 'pull_up_bar'],
        popularityScore: 90,
        exercises: [
          TemplateExercise(
            id: 'deadlifts',
            name: 'Conventional Deadlift',
            category: 'strength',
            restSeconds: 240,
            sets: [
              const TemplateSet(setNumber: 1, type: SetType.warmup, targetReps: 10, targetWeight: 80),
              const TemplateSet(setNumber: 2, targetReps: 5, targetWeight: 120),
              const TemplateSet(setNumber: 3, targetReps: 3, targetWeight: 140),
              const TemplateSet(setNumber: 4, targetReps: 5, targetWeight: 120),
            ],
          ),
          TemplateExercise(
            id: 'pull-ups',
            name: 'Pull-ups',
            category: 'strength',
            restSeconds: 120,
            sets: [
              const TemplateSet(setNumber: 1, minReps: 6, maxReps: 10),
              const TemplateSet(setNumber: 2, minReps: 5, maxReps: 8),
              const TemplateSet(setNumber: 3, minReps: 4, maxReps: 8),
            ],
          ),
          TemplateExercise(
            id: 'barbell-rows',
            name: 'Barbell Bent-over Rows',
            category: 'strength',
            restSeconds: 120,
            sets: [
              const TemplateSet(setNumber: 1, targetReps: 10, targetWeight: 70),
              const TemplateSet(setNumber: 2, targetReps: 8, targetWeight: 80),
              const TemplateSet(setNumber: 3, targetReps: 8, targetWeight: 80),
            ],
          ),
          TemplateExercise(
            id: 'dumbbell-curls',
            name: 'Dumbbell Bicep Curls',
            category: 'strength',
            restSeconds: 60,
            sets: [
              const TemplateSet(setNumber: 1, targetReps: 12, targetWeight: 15),
              const TemplateSet(setNumber: 2, targetReps: 10, targetWeight: 17.5),
              const TemplateSet(setNumber: 3, targetReps: 12, targetWeight: 15),
            ],
          ),
        ],
      ),

      // LEG DAY TEMPLATE
      WorkoutTemplate(
        id: 'leg-day-intermediate',
        name: 'Leg Day',
        description: 'Comprehensive lower body workout hitting quads, hamstrings, glutes, and calves with proven exercises.',
        category: 'strength',
        difficulty: 'intermediate',
        estimatedDuration: 70,
        targetMuscles: ['quadriceps', 'hamstrings', 'glutes', 'calves'],
        equipment: ['barbell', 'dumbbells', 'leg_press'],
        popularityScore: 85,
        exercises: [
          TemplateExercise(
            id: 'squats',
            name: 'Barbell Back Squats',
            category: 'strength',
            restSeconds: 180,
            sets: [
              const TemplateSet(setNumber: 1, type: SetType.warmup, targetReps: 10, targetWeight: 60),
              const TemplateSet(setNumber: 2, targetReps: 8, targetWeight: 100),
              const TemplateSet(setNumber: 3, targetReps: 6, targetWeight: 120),
              const TemplateSet(setNumber: 4, targetReps: 6, targetWeight: 120),
              const TemplateSet(setNumber: 5, targetReps: 8, targetWeight: 100),
            ],
          ),
          TemplateExercise(
            id: 'romanian-deadlifts',
            name: 'Romanian Deadlifts',
            category: 'strength',
            restSeconds: 120,
            sets: [
              const TemplateSet(setNumber: 1, targetReps: 10, targetWeight: 70),
              const TemplateSet(setNumber: 2, targetReps: 8, targetWeight: 80),
              const TemplateSet(setNumber: 3, targetReps: 8, targetWeight: 80),
            ],
          ),
          TemplateExercise(
            id: 'walking-lunges',
            name: 'Walking Lunges',
            category: 'strength',
            restSeconds: 90,
            sets: [
              const TemplateSet(setNumber: 1, targetReps: 20, notes: '10 each leg'),
              const TemplateSet(setNumber: 2, targetReps: 16, notes: '8 each leg'),
              const TemplateSet(setNumber: 3, targetReps: 20, notes: '10 each leg'),
            ],
          ),
          TemplateExercise(
            id: 'calf-raises',
            name: 'Standing Calf Raises',
            category: 'strength',
            restSeconds: 60,
            sets: [
              const TemplateSet(setNumber: 1, targetReps: 15, targetWeight: 40),
              const TemplateSet(setNumber: 2, targetReps: 12, targetWeight: 50),
              const TemplateSet(setNumber: 3, targetReps: 15, targetWeight: 40),
            ],
          ),
        ],
      ),

      // FULL BODY BEGINNER
      WorkoutTemplate(
        id: 'full-body-beginner',
        name: 'Full Body Beginner',
        description: 'Perfect starter workout hitting all major muscle groups with simple, effective exercises.',
        category: 'full_body',
        difficulty: 'beginner',
        estimatedDuration: 45,
        targetMuscles: ['chest', 'back', 'legs', 'shoulders', 'arms'],
        equipment: ['dumbbells'],
        popularityScore: 80,
        exercises: [
          TemplateExercise(
            id: 'goblet-squats',
            name: 'Goblet Squats',
            category: 'strength',
            restSeconds: 90,
            sets: [
              const TemplateSet(setNumber: 1, targetReps: 12, targetWeight: 15),
              const TemplateSet(setNumber: 2, targetReps: 10, targetWeight: 20),
              const TemplateSet(setNumber: 3, targetReps: 12, targetWeight: 15),
            ],
          ),
          TemplateExercise(
            id: 'push-ups',
            name: 'Push-ups',
            category: 'strength',
            restSeconds: 60,
            sets: [
              const TemplateSet(setNumber: 1, minReps: 8, maxReps: 12),
              const TemplateSet(setNumber: 2, minReps: 6, maxReps: 10),
              const TemplateSet(setNumber: 3, minReps: 8, maxReps: 12),
            ],
          ),
          TemplateExercise(
            id: 'dumbbell-rows',
            name: 'Dumbbell Rows',
            category: 'strength',
            restSeconds: 90,
            sets: [
              const TemplateSet(setNumber: 1, targetReps: 10, targetWeight: 20, notes: 'Each arm'),
              const TemplateSet(setNumber: 2, targetReps: 8, targetWeight: 25, notes: 'Each arm'),
              const TemplateSet(setNumber: 3, targetReps: 10, targetWeight: 20, notes: 'Each arm'),
            ],
          ),
          TemplateExercise(
            id: 'plank',
            name: 'Plank Hold',
            category: 'strength',
            restSeconds: 60,
            sets: [
              const TemplateSet(setNumber: 1, targetDuration: 30),
              const TemplateSet(setNumber: 2, targetDuration: 45),
              const TemplateSet(setNumber: 3, targetDuration: 30),
            ],
          ),
        ],
      ),

      // HIIT CARDIO
      WorkoutTemplate(
        id: 'hiit-cardio-beginner',
        name: 'HIIT Cardio Blast',
        description: 'High-intensity interval training to torch calories and improve cardiovascular fitness.',
        category: 'cardio',
        difficulty: 'beginner',
        estimatedDuration: 20,
        targetMuscles: ['full_body'],
        equipment: ['none'],
        popularityScore: 75,
        exercises: [
          TemplateExercise(
            id: 'jumping-jacks',
            name: 'Jumping Jacks',
            category: 'cardio',
            restSeconds: 30,
            sets: [
              const TemplateSet(setNumber: 1, targetDuration: 30),
              const TemplateSet(setNumber: 2, targetDuration: 30),
              const TemplateSet(setNumber: 3, targetDuration: 30),
            ],
          ),
          TemplateExercise(
            id: 'burpees',
            name: 'Burpees',
            category: 'cardio',
            restSeconds: 45,
            sets: [
              const TemplateSet(setNumber: 1, targetDuration: 20),
              const TemplateSet(setNumber: 2, targetDuration: 20),
              const TemplateSet(setNumber: 3, targetDuration: 20),
            ],
          ),
          TemplateExercise(
            id: 'mountain-climbers',
            name: 'Mountain Climbers',
            category: 'cardio',
            restSeconds: 30,
            sets: [
              const TemplateSet(setNumber: 1, targetDuration: 30),
              const TemplateSet(setNumber: 2, targetDuration: 30),
              const TemplateSet(setNumber: 3, targetDuration: 30),
            ],
          ),
          TemplateExercise(
            id: 'high-knees',
            name: 'High Knees',
            category: 'cardio',
            restSeconds: 30,
            sets: [
              const TemplateSet(setNumber: 1, targetDuration: 30),
              const TemplateSet(setNumber: 2, targetDuration: 30),
            ],
          ),
        ],
      ),
    ];
  }
}