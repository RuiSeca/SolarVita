import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../../services/exercises/exercise_service.dart';
import '../../services/exercises/optimized_exercise_service.dart';
import '../../screens/search/workout_detail/models/workout_item.dart';

part 'exercise_provider.g.dart';

final log = Logger('ExerciseProvider');

// Optimized service provider
@riverpod
OptimizedExerciseService exerciseService(Ref ref) {
  return OptimizedExerciseService();
}

// Note: Analytics are accessed directly from the service in widgets

// Exercise state class to hold the complete state
class ExerciseState {
  final List<WorkoutItem>? exercises;
  final String? currentTarget;
  final String? errorMessage;
  final String? errorDetails;
  final bool isLoading;

  const ExerciseState({
    this.exercises,
    this.currentTarget,
    this.errorMessage,
    this.errorDetails,
    this.isLoading = false,
  });

  ExerciseState copyWith({
    List<WorkoutItem>? exercises,
    String? currentTarget,
    String? errorMessage,
    String? errorDetails,
    bool? isLoading,
  }) {
    return ExerciseState(
      exercises: exercises ?? this.exercises,
      currentTarget: currentTarget ?? this.currentTarget,
      errorMessage: errorMessage ?? this.errorMessage,
      errorDetails: errorDetails ?? this.errorDetails,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get hasError => errorMessage != null;
  bool get hasData => exercises != null && exercises!.isNotEmpty;
}

// Main exercise provider using StateNotifier pattern
@Riverpod(keepAlive: true)
class ExerciseNotifier extends _$ExerciseNotifier {
  // Cache to store previously loaded data
  final Map<String, List<WorkoutItem>> _cache = {};
  // Track most recently used targets
  final List<String> _recentTargets = [];
  // Maximum number of targets to keep in cache
  static const int _maxCacheSize = 5;
  // Track total requests for analytics
  int _totalRequestCount = 0;

  @override
  ExerciseState build() {
    return const ExerciseState();
  }

  Future<void> loadExercisesByTarget(String target) async {
    // Normalize the target
    final normalizedTarget = target.trim().toLowerCase();

    // Prevent duplicate loading of the same target
    if (state.isLoading && state.currentTarget == normalizedTarget) {
      log.info('🔄 Request already in progress for $normalizedTarget');
      return;
    }

    // Check if we have this target in cache
    if (_cache.containsKey(normalizedTarget)) {
      state = state.copyWith(
        currentTarget: normalizedTarget,
        exercises: _cache[normalizedTarget],
        isLoading: false,
        errorMessage: null,
        errorDetails: null,
      );
      _updateRecentTargets(normalizedTarget);
      log.info('💾 Provider cache hit for $normalizedTarget');
      return;
    }

    // Skip if we're already loaded for this target
    if (state.currentTarget == normalizedTarget && state.hasData) {
      log.info('📋 Already loaded data for $normalizedTarget');
      return;
    }

    // Set loading state
    state = state.copyWith(
      isLoading: true,
      currentTarget: normalizedTarget,
      errorMessage: null,
      errorDetails: null,
    );

    final startTime = DateTime.now();
    _totalRequestCount++;
    
    try {
      final exerciseService = ref.read(exerciseServiceProvider);
      final exercises = await exerciseService.getExercisesByTarget(
        normalizedTarget,
      );

      final loadTime = DateTime.now().difference(startTime);
      log.info('⚡ Loaded $normalizedTarget in ${loadTime.inMilliseconds}ms');

      if (exercises.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No exercises found',
          errorDetails: 'No exercises available for this category.',
        );
        return;
      }

      // Update cache with new data
      _cache[normalizedTarget] = exercises;
      _updateRecentTargets(normalizedTarget);

      // Always update state with exercises, regardless of current target
      state = state.copyWith(
        currentTarget: normalizedTarget,
        exercises: exercises,
        isLoading: false,
        errorMessage: null,
        errorDetails: null,
      );

      // Log optimization status periodically
      if (_totalRequestCount % 5 == 0) {
        (exerciseService as OptimizedExerciseService).logOptimizationStatus();
      }
      
    } catch (e) {
      final loadTime = DateTime.now().difference(startTime);
      log.warning('❌ Failed to load $normalizedTarget after ${loadTime.inMilliseconds}ms: $e');
      
      String errorMessage;
      String errorDetails;

      // Handle different types of exceptions with friendly messages
      if (e is ApiException) {
        errorMessage = 'Failed to load exercises';
        errorDetails = 'API Error: ${e.message}';
      } else if (e is NetworkException) {
        errorMessage = 'Network error';
        errorDetails = 'Please check your internet connection and try again.';
      } else if (e is TimeoutException) {
        errorMessage = 'Connection timeout';
        errorDetails =
            'The server is taking too long to respond. Please try again later.';
      } else {
        errorMessage = 'Unexpected error';
        errorDetails =
            'Something went wrong while loading exercises. Please try again.';
      }

      state = state.copyWith(
        isLoading: false,
        exercises: null,
        errorMessage: errorMessage,
        errorDetails: errorDetails,
      );
    }
  }

  // Update the list of recently used targets
  void _updateRecentTargets(String target) {
    // Remove target if it already exists
    _recentTargets.remove(target);
    // Add target to start of list
    _recentTargets.insert(0, target);
    // Trim list if needed
    if (_recentTargets.length > _maxCacheSize) {
      _recentTargets.removeLast();
    }
  }

  // Manage the cache size by removing least recently used targets
  void manageCache() {
    if (_cache.length <= _maxCacheSize) return;

    // Create a set of targets to keep
    final targetsToKeep = Set<String>.from(_recentTargets);

    // Remove targets not in the recent list
    _cache.removeWhere((key, _) => !targetsToKeep.contains(key));
  }

  void clearExercises() {
    state = const ExerciseState();
  }

  void retryCurrentTarget() {
    if (state.currentTarget != null) {
      loadExercisesByTarget(state.currentTarget!);
    }
  }

  void clearError() {
    if (state.hasError) {
      state = state.copyWith(errorMessage: null, errorDetails: null);
    }
  }

  // Get cache info for debugging
  Map<String, int> getCacheInfo() {
    return {
      'cacheSize': _cache.length,
      'recentTargetsCount': _recentTargets.length,
    };
  }
}

// Convenience providers for common exercise data
@riverpod
List<WorkoutItem> exercises(Ref ref) {
  final exerciseState = ref.watch(exerciseNotifierProvider);
  return exerciseState.exercises ?? [];
}

@riverpod
bool isExercisesLoading(Ref ref) {
  final exerciseState = ref.watch(exerciseNotifierProvider);
  return exerciseState.isLoading;
}

@riverpod
bool hasExercisesError(Ref ref) {
  final exerciseState = ref.watch(exerciseNotifierProvider);
  return exerciseState.hasError;
}

@riverpod
String? exercisesErrorMessage(Ref ref) {
  final exerciseState = ref.watch(exerciseNotifierProvider);
  return exerciseState.errorMessage;
}

@riverpod
String? exercisesErrorDetails(Ref ref) {
  final exerciseState = ref.watch(exerciseNotifierProvider);
  return exerciseState.errorDetails;
}

@riverpod
String? currentExerciseTarget(Ref ref) {
  final exerciseState = ref.watch(exerciseNotifierProvider);
  return exerciseState.currentTarget;
}

@riverpod
bool hasExercisesData(Ref ref) {
  final exerciseState = ref.watch(exerciseNotifierProvider);
  return exerciseState.hasData;
}
