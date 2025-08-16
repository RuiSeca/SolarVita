import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../screens/search/workout_detail/models/workout_item.dart';
import '../../screens/search/workout_detail/models/workout_step.dart';
import 'package:logging/logging.dart';
import 'exercise_service.dart';

final log = Logger('OptimizedExerciseService');

/// Optimized Exercise Service that reduces API calls while respecting ExerciseDB terms
/// 
/// Optimizations:
/// 1. Session-based request deduplication
/// 2. Smart batching within single requests  
/// 3. Intelligent endpoint selection
/// 4. Request timing optimization
/// 5. In-memory session cache (cleared on app restart - compliant with terms)
class OptimizedExerciseService extends ExerciseService {
  // Session-based request tracking (cleared on app restart)
  final Map<String, DateTime> _lastRequestTime = {};
  final Set<String> _activeRequests = {};
  final Duration _requestCooldown = const Duration(seconds: 5);
  
  // Session cache (automatically cleared when app restarts - terms compliant)
  final Map<String, _SessionCacheEntry> _sessionCache = {};
  final Duration _sessionCacheTimeout = const Duration(minutes: 10);
  
  // API usage analytics
  int _totalApiCalls = 0;
  int _deduplicatedCalls = 0;
  int _cacheHits = 0;
  
  OptimizedExerciseService({super.timeout});

  @override
  Future<List<WorkoutItem>> getExercisesByTarget(String target) async {
    final normalizedTarget = target.trim().toLowerCase();
    
    // 1. Check if request is already in progress (prevents duplicate concurrent calls)
    if (_activeRequests.contains(normalizedTarget)) {
      log.info('🔄 Duplicate request detected for $normalizedTarget, waiting...');
      // Wait for existing request to complete
      await _waitForActiveRequest(normalizedTarget);
    }
    
    // 2. Check session cache (terms compliant - cleared on app restart)
    final cacheEntry = _sessionCache[normalizedTarget];
    if (cacheEntry != null && !cacheEntry.isExpired) {
      _cacheHits++;
      log.info('💾 Cache hit for $normalizedTarget ($_cacheHits total hits)');
      return cacheEntry.exercises;
    }
    
    // 3. Check request cooldown to prevent rapid-fire requests
    final lastRequest = _lastRequestTime[normalizedTarget];
    if (lastRequest != null) {
      final timeSinceLastRequest = DateTime.now().difference(lastRequest);
      if (timeSinceLastRequest < _requestCooldown) {
        final remainingCooldown = _requestCooldown - timeSinceLastRequest;
        log.info('⏳ Request cooldown for $normalizedTarget: ${remainingCooldown.inSeconds}s remaining');
        await Future.delayed(remainingCooldown);
      }
    }
    
    // 4. Mark request as active
    _activeRequests.add(normalizedTarget);
    _lastRequestTime[normalizedTarget] = DateTime.now();
    
    try {
      log.info('🌐 Making API call for $normalizedTarget (Call #${++_totalApiCalls})');
      
      // Use optimized endpoint selection
      final exercises = await _makeOptimizedApiCall(normalizedTarget);
      
      // Store in session cache
      _sessionCache[normalizedTarget] = _SessionCacheEntry(
        exercises: exercises,
        timestamp: DateTime.now(),
      );
      
      // Clean up old cache entries
      _cleanupExpiredCache();
      
      return exercises;
      
    } finally {
      // Always remove from active requests
      _activeRequests.remove(normalizedTarget);
    }
  }

  /// Optimized API call with intelligent endpoint selection
  Future<List<WorkoutItem>> _makeOptimizedApiCall(String target) async {
    // Enhanced target mapping for better first-try success
    final optimizedTarget = _getOptimizedApiTarget(target);
    
    // Try the most likely successful endpoint first
    final primaryEndpoint = _selectPrimaryEndpoint(optimizedTarget);
    
    try {
      return await _makeApiRequest(primaryEndpoint, target);
    } catch (e) {
      log.warning('Primary endpoint failed: $e');
      // Fallback to parent class logic with all endpoints
      return await super.getExercisesByTarget(target);
    }
  }

  /// Select the most appropriate primary endpoint based on target
  String _selectPrimaryEndpoint(String target) {
    // Popular targets that usually have good data
    final popularTargets = ['pectorals', 'biceps', 'triceps', 'quads', 'abs', 'lats'];
    
    if (popularTargets.contains(target)) {
      // Direct target endpoint for popular muscles
      return '${ApiConfig.baseUrl}/exercises/target/$target?limit=12';
    } else {
      // Body part endpoint for less common targets
      final bodyPart = _mapTargetToBodyPart(target);
      return '${ApiConfig.baseUrl}/exercises/bodyPart/$bodyPart?limit=12';
    }
  }

  /// Enhanced target mapping with common user terms
  String _getOptimizedApiTarget(String target) {
    // Extended mapping for common user search terms
    const targetMapping = {
      // Common user terms -> API terms
      'chest': 'pectorals',
      'back': 'lats',
      'shoulders': 'delts', 
      'arms': 'biceps',
      'legs': 'quads',
      'core': 'abs',
      'abs': 'abs',
      'biceps': 'biceps',
      'triceps': 'triceps',
      'glutes': 'glutes',
      'calves': 'calves',
      'cardio': 'cardiovascular system',
      
      // Less common but valid
      'forearms': 'forearms',
      'traps': 'traps',
      'hamstrings': 'hamstrings',
      'quads': 'quads',
      'delts': 'delts',
      'lats': 'lats',
      'pectorals': 'pectorals',
    };
    
    return targetMapping[target] ?? _mapTargetToValidApiTarget(target);
  }

  /// Make single API request with enhanced error handling
  Future<List<WorkoutItem>> _makeApiRequest(String endpoint, String originalTarget) async {
    final url = Uri.parse(endpoint);
    
    final response = await http
        .get(url, headers: ApiConfig.headers)
        .timeout(timeout);
    
    if (response.statusCode == 200) {
      return await _processSuccessResponse(response.body, originalTarget);
    } else {
      throw ApiException(
        'API request failed: ${response.statusCode}',
        statusCode: response.statusCode,
        endpoint: endpoint,
      );
    }
  }

  /// Process success response (override to avoid calling super methods incorrectly)
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

  /// Convert API exercise to WorkoutItem (copied from parent)
  Future<WorkoutItem> _convertToWorkoutItem(
    Map<String, dynamic> exercise,
  ) async {
    try {
      final name = exercise['name'] ?? 'Unknown Exercise';
      final equipment = exercise['equipment'] ?? 'body weight';

      final exerciseId = exercise['id']?.toString() ?? '';
      String gifUrl = exerciseId.isNotEmpty
          ? 'https://exercisedb.p.rapidapi.com/image?exerciseId=$exerciseId&resolution=180&rapidapi-key=${ApiConfig.rapidApiKey}'
          : '';

      final instructions = exercise['instructions'] is List
          ? List<String>.from(exercise['instructions'])
          : <String>[];
      final bodyPart = exercise['bodyPart'] ?? '';
      final target = exercise['target'] ?? '';

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

      // Use parent class calculation methods
      final duration = _calculateDuration(name, bodyPart, equipment);
      final difficulty = _calculateDifficulty(name, equipment, bodyPart, target);
      final caloriesBurn = _calculateCalories(name, bodyPart, target, equipment);
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

  /// Create fallback workout item (copied from parent)
  WorkoutItem _createFallbackWorkoutItem(String target) {
    final targetName = _capitalizeEachWord(target);
    return WorkoutItem(
      title: 'Basic $targetName Exercise',
      image: '',
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

  // Helper methods from parent class
  String _calculateDuration(String name, String bodyPart, String equipment) {
    if (name.toLowerCase().contains('cardio') ||
        name.toLowerCase().contains('hiit') ||
        bodyPart.toLowerCase() == 'cardio') {
      return '30 seconds';
    }

    if ((equipment.contains('barbell') || equipment.contains('machine')) &&
        (name.toLowerCase().contains('squat') ||
            name.toLowerCase().contains('dead') ||
            name.toLowerCase().contains('press'))) {
      return '60-90 seconds';
    }

    if (bodyPart.toLowerCase() == 'waist' ||
        name.toLowerCase().contains('plank') ||
        name.toLowerCase().contains('crunch')) {
      return '30-45 seconds';
    }

    return '45 seconds';
  }

  String _calculateDifficulty(
    String name,
    String equipment,
    String bodyPart,
    String target,
  ) {
    int difficultyScore = 0;

    if (equipment.contains('barbell') || equipment.contains('olympic')) {
      difficultyScore += 3;
    } else if (equipment.contains('dumbbell') ||
        equipment.contains('kettlebell')) {
      difficultyScore += 2;
    } else if (equipment.contains('band') || equipment.contains('cable')) {
      difficultyScore += 1;
    }

    final nameLower = name.toLowerCase();
    if (nameLower.contains('advanced') || nameLower.contains('complex')) {
      difficultyScore += 2;
    }
    if (nameLower.contains('beginner') || nameLower.contains('simple')) {
      difficultyScore -= 1;
    }

    if (nameLower.contains('deadlift') ||
        nameLower.contains('squat') ||
        nameLower.contains('press') ||
        nameLower.contains('clean') ||
        nameLower.contains('snatch')) {
      difficultyScore += 2;
    }

    if (target == 'glutes' ||
        target == 'quads' ||
        target == 'lats' ||
        target == 'pectorals') {
      difficultyScore += 1;
    }

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

    if (bodyPart.toLowerCase() == 'cardio' ||
        target == 'cardiovascular system') {
      baseCalories = 12;
    } else if (bodyPart == 'upper legs' ||
        bodyPart == 'back' ||
        target == 'glutes' ||
        target == 'quads') {
      baseCalories = 10;
    } else if (bodyPart == 'chest' || target == 'pectorals' || target == 'lats') {
      baseCalories = 8;
    } else {
      baseCalories = 5;
    }

    double equipmentFactor = 1.0;
    if (equipment.contains('barbell') || equipment.contains('machine')) {
      equipmentFactor = 1.3;
    } else if (equipment.contains('dumbbell') ||
        equipment.contains('kettlebell')) {
      equipmentFactor = 1.2;
    }

    int minCalories = (baseCalories * equipmentFactor * 0.8).round();
    int maxCalories = (baseCalories * equipmentFactor * 1.2).round();

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

    tips.add('Maintain proper form throughout the exercise.');
    tips.add(
      'Remember to breathe: exhale during exertion, inhale during relaxation.',
    );

    if (equipment.contains('barbell')) {
      tips.add('Ensure the barbell is balanced and secure before lifting.');
    } else if (equipment.contains('dumbbell')) {
      tips.add('Keep your wrists straight when working with dumbbells.');
    } else if (equipment.contains('body weight')) {
      tips.add('Focus on controlled movements rather than speed.');
    }

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

  /// Map target to body part for API calls
  String _mapTargetToBodyPart(String target) {
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
        return 'chest';
    }
  }

  /// Map user target to valid API target
  String _mapTargetToValidApiTarget(String target) {
    switch (target) {
      case 'chest':
        return 'pectorals';
      case 'back':
        return 'upper back';
      case 'shoulders':
        return 'delts';
      case 'arms':
        return 'biceps';
      case 'legs':
        return 'quads';
      case 'core':
        return 'abs';
      case 'cardio':
        return 'cardiovascular system';
      case 'full body':
        return 'pectorals';
      default:
        return 'pectorals';
    }
  }

  /// Wait for active request to complete
  Future<void> _waitForActiveRequest(String target) async {
    int attempts = 0;
    const maxAttempts = 20; // 10 seconds max wait
    
    while (_activeRequests.contains(target) && attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 500));
      attempts++;
    }
  }

  /// Clean up expired cache entries to prevent memory bloat
  void _cleanupExpiredCache() {
    final now = DateTime.now();
    _sessionCache.removeWhere((key, entry) => 
        now.difference(entry.timestamp) > _sessionCacheTimeout);
  }

  /// Get API usage analytics
  Map<String, dynamic> getUsageAnalytics() {
    final cacheHitRate = _totalApiCalls > 0 
        ? (_cacheHits / (_cacheHits + _totalApiCalls) * 100).toStringAsFixed(1)
        : '0.0';
        
    return {
      'totalApiCalls': _totalApiCalls,
      'cacheHits': _cacheHits,
      'deduplicatedCalls': _deduplicatedCalls,
      'cacheHitRate': '$cacheHitRate%',
      'activeCacheEntries': _sessionCache.length,
      'activeRequests': _activeRequests.length,
    };
  }

  /// Reset usage analytics
  void resetAnalytics() {
    _totalApiCalls = 0;
    _deduplicatedCalls = 0;
    _cacheHits = 0;
  }

  /// Clear session cache manually (useful for memory management)
  void clearSessionCache() {
    _sessionCache.clear();
    _activeRequests.clear();
    _lastRequestTime.clear();
    log.info('🧹 Session cache cleared');
  }

  /// Log current optimization status
  void logOptimizationStatus() {
    final analytics = getUsageAnalytics();
    log.info('📊 Optimization Status:');
    log.info('   API Calls: ${analytics['totalApiCalls']}');
    log.info('   Cache Hits: ${analytics['cacheHits']}');
    log.info('   Hit Rate: ${analytics['cacheHitRate']}');
    log.info('   Active Cache: ${analytics['activeCacheEntries']} entries');
  }
}

/// Session cache entry that expires after timeout
class _SessionCacheEntry {
  final List<WorkoutItem> exercises;
  final DateTime timestamp;
  
  _SessionCacheEntry({
    required this.exercises,
    required this.timestamp,
  });
  
  bool get isExpired {
    const timeout = Duration(minutes: 10);
    return DateTime.now().difference(timestamp) > timeout;
  }
}