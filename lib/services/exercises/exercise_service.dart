import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../screens/search/workout_detail/models/workout_item.dart';
import '../../screens/search/workout_detail/models/workout_step.dart';
import 'package:logging/logging.dart';

final log = Logger('ExerciseService');

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String endpoint;

  ApiException(this.message, {this.statusCode, required this.endpoint});

  @override
  String toString() =>
      'API Error: $message (Status: $statusCode, Endpoint: $endpoint)';
}

class NetworkException implements Exception {
  final String message;
  final String? endpoint;

  NetworkException(this.message, {this.endpoint});

  @override
  String toString() =>
      'Network Error: $message${endpoint != null ? ' (Endpoint: $endpoint)' : ''}';
}

class ExerciseService {
  final Map<String, List<WorkoutItem>> _cache = {};
  final Duration timeout;

  ExerciseService({this.timeout = const Duration(seconds: 15)});

  // Test API connection using the status endpoint
  Future<bool> testApiConnection() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/status');
      final response = await http
          .get(url, headers: ApiConfig.headers)
          .timeout(timeout);

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<List<WorkoutItem>> getExercisesByTarget(String target) async {
    // Normalize the target name to lowercase
    final normalizedTarget = target.trim().toLowerCase();

    // Check cache first
    if (_cache.containsKey(normalizedTarget)) {
      return _cache[normalizedTarget]!;
    }

    // Validate target against API's valid target muscles
    final validTargets = [
      'abductors',
      'abs',
      'adductors',
      'biceps',
      'calves',
      'cardiovascular system',
      'delts',
      'forearms',
      'glutes',
      'hamstrings',
      'lats',
      'levator scapulae',
      'pectorals',
      'quads',
      'serratus anterior',
      'spine',
      'traps',
      'triceps',
      'upper back',
    ];

    // If the target is not in our valid list, map it to the closest one
    String apiTarget = normalizedTarget;
    if (!validTargets.contains(normalizedTarget)) {
      apiTarget = _mapTargetToValidApiTarget(normalizedTarget);
    }

    // Validate API configuration
    if (ApiConfig.rapidApiKey.isEmpty) {
      throw ApiException(
        'API key not configured. Check .env file.',
        endpoint: '${ApiConfig.baseUrl}/exercises/target/$apiTarget',
      );
    }

    // Try different endpoint patterns based on ExerciseDB documentation
    final endpoints = [
      '${ApiConfig.baseUrl}/exercises/target/$apiTarget?limit=10', // Standard target endpoint with limit and full data
      '${ApiConfig.baseUrl}/exercises/bodyPart/${_mapTargetToBodyPart(apiTarget)}?limit=10', // Body part endpoint
      '${ApiConfig.baseUrl}/exercises?limit=10', // Fallback to all exercises
    ];

    Exception? lastException;

    for (int i = 0; i < endpoints.length; i++) {
      final url = Uri.parse(endpoints[i]);

      try {
        final response = await http
            .get(url, headers: ApiConfig.headers)
            .timeout(timeout);

        // Handle HTTP status codes
        if (response.statusCode == 200) {
          final result = await _processSuccessResponse(
            response.body,
            normalizedTarget,
          );

          // If we're using the fallback endpoint (all exercises), filter by target
          if (i == 2 && result.isNotEmpty) {
            final filteredExercises = result.where((exercise) {
              final target = exercise.description.toLowerCase();
              return target.contains(apiTarget) ||
                  target.contains(normalizedTarget);
            }).toList();

            if (filteredExercises.isNotEmpty) {
              return filteredExercises
                  .take(10)
                  .toList(); // Limit to 10 exercises
            }
          }

          return result;
        } else if (response.statusCode == 403) {
          _parseErrorResponse(response.body);
          lastException = ApiException(
            'API access denied. Please check your RapidAPI subscription for ExerciseDB.',
            statusCode: response.statusCode,
            endpoint: url.toString(),
          );
          continue; // Try next endpoint
        } else if (response.statusCode == 404) {
          lastException = ApiException(
            'No exercises found for the selected muscle group.',
            statusCode: response.statusCode,
            endpoint: url.toString(),
          );
          continue; // Try next endpoint
        } else if (response.statusCode == 429) {
          throw ApiException(
            'API rate limit exceeded. Please try again later.',
            statusCode: response.statusCode,
            endpoint: url.toString(),
          );
        } else {
          lastException = ApiException(
            'Failed to load exercises: ${response.statusCode}',
            statusCode: response.statusCode,
            endpoint: url.toString(),
          );
          continue; // Try next endpoint
        }
      } on SocketException catch (_) {
        throw NetworkException(
          'No internet connection. Please check your network settings.',
          endpoint: url.toString(),
        );
      } on http.ClientException catch (_) {
        throw NetworkException(
          'Failed to connect to the server.',
          endpoint: url.toString(),
        );
      } on TimeoutException catch (_) {
        throw NetworkException(
          'Connection timed out. Please try again.',
          endpoint: url.toString(),
        );
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        continue; // Try next endpoint
      }
    }

    // If we get here, all endpoints failed
    if (lastException != null) {
      throw lastException;
    } else {
      throw ApiException(
        'All API endpoints failed',
        endpoint: 'Multiple endpoints tried',
      );
    }
  }

  String _mapTargetToValidApiTarget(String target) {
    // Map our app's muscle targets to API's valid target muscles
    switch (target) {
      case 'chest':
        return 'pectorals';
      case 'back':
        return 'upper back';
      case 'shoulders':
        return 'delts';
      case 'arms':
        return 'biceps'; // or triceps
      case 'legs':
        return 'quads'; // or hamstrings
      case 'core':
        return 'abs';
      case 'cardio':
        return 'cardiovascular system';
      case 'full body':
        return 'pectorals'; // Default to a common muscle
      default:
        // If no specific mapping, use a common target
        return 'pectorals';
    }
  }

  String _mapTargetToBodyPart(String target) {
    // Map target muscles to body parts based on ExerciseDB documentation
    // Body parts: "waist", "upper legs", "back", "lower legs", "chest", "upper arms", "cardio", "shoulders", "lower arms", "neck"
    switch (target) {
      case 'pectorals':
        return 'chest';
      case 'abs':
      case 'core':
        return 'waist';
      case 'quads':
      case 'hamstrings':
      case 'glutes':
      case 'adductors':
      case 'abductors':
        return 'upper legs';
      case 'calves':
        return 'lower legs';
      case 'lats':
      case 'upper back':
      case 'traps':
      case 'spine':
        return 'back';
      case 'biceps':
      case 'triceps':
        return 'upper arms';
      case 'forearms':
        return 'lower arms';
      case 'delts':
        return 'shoulders';
      case 'cardiovascular system':
        return 'cardio';
      case 'levator scapulae':
      case 'serratus anterior':
        return 'neck';
      default:
        return 'chest'; // Default fallback
    }
  }

  Future<List<WorkoutItem>> _processSuccessResponse(
    String responseBody,
    String target,
  ) async {
    try {
      final data = json.decode(responseBody);
      if (data is List) {
        if (data.isEmpty) {
          return [_createFallbackWorkoutItem(target)];
        }

        final exerciseFutures = data.map((exercise) async {
          if (exercise is Map<String, dynamic>) {
            return await _convertToWorkoutItem(exercise);
          } else {
            return _createFallbackWorkoutItem(target);
          }
        }).toList();

        final exercises = await Future.wait(exerciseFutures);

        _cache[target] = exercises;
        return exercises;
      } else {
        throw ApiException(
          'Unexpected response format (not a list).',
          endpoint: '${ApiConfig.baseUrl}/exercises/target/$target',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Error processing exercise data: ${e.toString()}',
        endpoint: '${ApiConfig.baseUrl}/exercises/target/$target',
      );
    }
  }

  String _parseErrorResponse(String body) {
    try {
      final decoded = json.decode(body);
      return decoded['message'] ?? body;
    } catch (_) {
      return body;
    }
  }

  Future<WorkoutItem> _convertToWorkoutItem(
    Map<String, dynamic> exercise,
  ) async {
    try {
      final name = exercise['name'] ?? 'Unknown Exercise';
      final equipment = exercise['equipment'] ?? 'body weight';

      // Check if exercise has gifUrl field, if not fetch individual exercise data
      final exerciseId = exercise['id']?.toString() ?? '';
      // Build GIF URL using ExerciseDB image endpoint (180 resolution for BASIC plan)
      String gifUrl = exerciseId.isNotEmpty
          ? 'https://exercisedb.p.rapidapi.com/image?exerciseId=$exerciseId&resolution=180&rapidapi-key=${ApiConfig.rapidApiKey}'
          : '';

      final instructions = exercise['instructions'] is List
          ? List<String>.from(exercise['instructions'])
          : <String>[];
      final bodyPart = exercise['bodyPart'] ?? '';
      final target = exercise['target'] ?? '';

      // Create a good description from instructions if available
      String description = exercise['description'] ?? '';
      if (description.isEmpty && instructions.isNotEmpty) {
        description =
            'This exercise targets the ${exercise['target'] ?? 'muscles'} using $equipment. ';
        if (instructions.length > 1) {
          description += instructions.take(2).join(' ');
        } else if (instructions.isNotEmpty) {
          description += instructions.first;
        }
      } else if (description.isEmpty) {
        description =
            'A ${exercise['target'] ?? 'muscle'} exercise that uses $equipment.';
      }

      // DYNAMIC DURATION: Based on exercise type and equipment
      final duration = _calculateDuration(name, bodyPart, equipment);

      // DYNAMIC DIFFICULTY: Analyze exercise complexity
      final difficulty = _calculateDifficulty(
        name,
        equipment,
        bodyPart,
        target,
      );

      // DYNAMIC CALORIES: Estimate based on exercise intensity
      final caloriesBurn = _calculateCalories(
        name,
        bodyPart,
        target,
        equipment,
      );

      final rating = (exercise['rating'] ?? 4.5).toDouble();

      final steps = [
        WorkoutStep(
          title: name,
          duration: duration,
          description: description,
          instructions: instructions,
          gifUrl: gifUrl,
          isCompleted: false,
        ),
      ];

      return WorkoutItem(
        title: _capitalizeEachWord(name),
        image: gifUrl,
        duration: duration,
        difficulty: difficulty,
        description: description,
        rating: rating,
        steps: steps,
        equipment: [equipment],
        caloriesBurn: caloriesBurn,
        tips: _generateTips(name, target, equipment),
      );
    } catch (e) {
      return _createFallbackWorkoutItem('Unknown');
    }
  }

  String _calculateDuration(String name, String bodyPart, String equipment) {
    // HIIT or cardio exercises typically have shorter durations
    if (name.toLowerCase().contains('cardio') ||
        name.toLowerCase().contains('hiit') ||
        bodyPart.toLowerCase() == 'cardio') {
      return '30 seconds';
    }

    // Compound exercises with heavy equipment need more time
    if ((equipment.contains('barbell') || equipment.contains('machine')) &&
        (name.toLowerCase().contains('squat') ||
            name.toLowerCase().contains('dead') ||
            name.toLowerCase().contains('press'))) {
      return '60-90 seconds';
    }

    // Core exercises often have shorter hold times
    if (bodyPart.toLowerCase() == 'waist' ||
        name.toLowerCase().contains('plank') ||
        name.toLowerCase().contains('crunch')) {
      return '30-45 seconds';
    }

    // Default duration for most exercises
    return '45 seconds';
  }

  String _calculateDifficulty(
    String name,
    String equipment,
    String bodyPart,
    String target,
  ) {
    int difficultyScore = 0;

    // Equipment-based difficulty
    if (equipment.contains('barbell') || equipment.contains('olympic')) {
      difficultyScore += 3;
    } else if (equipment.contains('dumbbell') ||
        equipment.contains('kettlebell')) {
      difficultyScore += 2;
    } else if (equipment.contains('band') || equipment.contains('cable')) {
      difficultyScore += 1;
    }

    // Exercise complexity based on name
    final nameLower = name.toLowerCase();
    if (nameLower.contains('advanced') || nameLower.contains('complex')) {
      difficultyScore += 2;
    }
    if (nameLower.contains('beginner') || nameLower.contains('simple')) {
      difficultyScore -= 1;
    }

    // Compound movements are generally harder
    if (nameLower.contains('deadlift') ||
        nameLower.contains('squat') ||
        nameLower.contains('press') ||
        nameLower.contains('clean') ||
        nameLower.contains('snatch')) {
      difficultyScore += 2;
    }

    // Large muscle groups or compound movements are more challenging
    if (target == 'glutes' ||
        target == 'quads' ||
        target == 'lats' ||
        target == 'pectorals') {
      difficultyScore += 1;
    }

    // Convert score to difficulty level
    if (difficultyScore <= 0) {
      return 'Beginner';
    } else if (difficultyScore <= 2) {
      return 'Easy';
    } else if (difficultyScore <= 4) {
      return 'Medium';
    } else {
      return 'Hard';
    }
  }

  String _calculateCalories(
    String name,
    String bodyPart,
    String target,
    String equipment,
  ) {
    int baseCalories = 0;

    // Cardio exercises burn more calories
    if (bodyPart.toLowerCase() == 'cardio' ||
        target == 'cardiovascular system') {
      baseCalories = 12; // Per minute
    }
    // Large muscle groups burn more calories
    else if (bodyPart == 'upper legs' ||
        bodyPart == 'back' ||
        target == 'glutes' ||
        target == 'quads') {
      baseCalories = 10;
    }
    // Medium muscle groups
    else if (bodyPart == 'chest' || target == 'pectorals' || target == 'lats') {
      baseCalories = 8;
    }
    // Smaller muscle groups
    else {
      baseCalories = 5;
    }

    // Equipment factor
    double equipmentFactor = 1.0;
    if (equipment.contains('barbell') || equipment.contains('machine')) {
      equipmentFactor = 1.3;
    } else if (equipment.contains('dumbbell') ||
        equipment.contains('kettlebell')) {
      equipmentFactor = 1.2;
    }

    // Calculate range (per minute burn rate)
    int minCalories = (baseCalories * equipmentFactor * 0.8).round();
    int maxCalories = (baseCalories * equipmentFactor * 1.2).round();

    // For a typical 5-minute exercise set
    return '${(minCalories * 5)}-${(maxCalories * 5)}';
  }

  String _capitalizeEachWord(String text) {
    if (text.isEmpty) return '';
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  List<String> _generateTips(String name, String target, String equipment) {
    final tips = <String>[];

    // Generic form tip
    tips.add('Maintain proper form throughout the exercise.');

    // Breathing tip
    tips.add(
      'Remember to breathe: exhale during exertion, inhale during relaxation.',
    );

    // Equipment-specific tip
    if (equipment.contains('barbell')) {
      tips.add('Ensure the barbell is balanced and secure before lifting.');
    } else if (equipment.contains('dumbbell')) {
      tips.add('Keep your wrists straight when working with dumbbells.');
    } else if (equipment.contains('body weight')) {
      tips.add('Focus on controlled movements rather than speed.');
    }

    // Target-specific tip
    if (target.contains('abs')) {
      tips.add('Engage your core by pulling your navel toward your spine.');
    } else if (target.contains('back') || target.contains('lats')) {
      tips.add(
        'Keep your shoulders pulled back and down to engage the back muscles.',
      );
    } else if (target.contains('chest') || target.contains('pectorals')) {
      tips.add(
        'Focus on squeezing your chest muscles at the peak of the movement.',
      );
    }

    return tips;
  }

  WorkoutItem _createFallbackWorkoutItem(String target) {
    // Make the fallback more specific to the target
    final targetName = _capitalizeEachWord(target);
    return WorkoutItem(
      title: 'Basic $targetName Exercise',
      image: '', // No image available
      duration: '45 seconds',
      difficulty: 'Medium',
      description:
          'A basic exercise targeting the $target muscle group. This fallback is shown when no specific exercises are available from our database.',
      rating: 4.0,
      steps: [
        WorkoutStep(
          title: 'Basic $targetName Exercise',
          duration: '45 seconds',
          description:
              'Focus on the $target muscle group with controlled movements.',
          instructions: [
            'Start in a comfortable position',
            'Perform the exercise with controlled movements',
            'Focus on engaging the $target muscles',
            'Breathe regularly throughout the exercise',
          ],
          gifUrl: '',
          isCompleted: false,
        ),
      ],
      equipment: ['body weight'],
      caloriesBurn: '100-150',
      tips: [
        'Maintain proper form throughout the exercise',
        'Focus on the mind-muscle connection',
        'If you feel pain (not muscle fatigue), stop immediately',
        'Drink water before and after your workout',
      ],
    );
  }

  void clearCache() {
    _cache.clear();
  }

  void clearCacheForTarget(String target) {
    final normalizedTarget = target.trim().toLowerCase();
    _cache.remove(normalizedTarget);
  }
}
