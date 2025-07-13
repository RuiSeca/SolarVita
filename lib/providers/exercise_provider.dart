import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'dart:async';
import '../services/exercise_service.dart';
import '../screens/search/workout_detail/models/workout_item.dart';

enum LoadingState { idle, loading, success, error }

class ExerciseProvider with ChangeNotifier {
  final ExerciseService _exerciseService = ExerciseService();
  LoadingState _loadingState = LoadingState.idle;
  String? _currentTarget;
  List<WorkoutItem>? _exercises;
  String? _errorMessage;
  String? _errorDetails;
  final log = Logger('ExerciseProvider');
  bool _isNotifying = false;

  // Cache to store previously loaded data
  final Map<String, List<WorkoutItem>> _cache = {};
  // Track most recently used targets
  final List<String> _recentTargets = [];

  // Maximum number of targets to keep in cache
  static const int _maxCacheSize = 5;

  // Keep track of ongoing loading request
  Completer<void>? _loadingCompleter;

  LoadingState get loadingState => _loadingState;
  bool get isLoading => _loadingState == LoadingState.loading;
  bool get hasError => _loadingState == LoadingState.error;
  bool get hasData =>
      _loadingState == LoadingState.success && _exercises != null;
  List<WorkoutItem>? get exercises => _exercises;
  String? get errorMessage => _errorMessage;
  String? get errorDetails => _errorDetails;
  String? get currentTarget => _currentTarget;

  Future<void> loadExercisesByTarget(String target) async {
    // Normalize the target
    final normalizedTarget = target.trim().toLowerCase();

    // Prevent duplicate loading of the same target
    if (isLoading) {
      log.warning('Skipping loadExercisesByTarget: Already loading');
      return;
    }

    // Check if we have this target in cache
    if (_cache.containsKey(normalizedTarget)) {
      log.info('Using cached data for target: $normalizedTarget');
      _currentTarget = normalizedTarget;
      _exercises = _cache[normalizedTarget];
      _loadingState = LoadingState.success;
      _updateRecentTargets(normalizedTarget);
      _notifySafely();
      return;
    }

    // Skip if we're already loaded for this target
    if (_currentTarget == normalizedTarget && hasData) {
      log.info('Already loaded data for target: $normalizedTarget');
      return;
    }

    log.info('Starting loadExercisesByTarget: $normalizedTarget');
    _setLoading();
    _currentTarget = normalizedTarget;

    // Create a new completer to track this load operation
    _loadingCompleter = Completer<void>();

    try {
      log.fine('Fetching exercises for target: $normalizedTarget');
      final exercises =
          await _exerciseService.getExercisesByTarget(normalizedTarget);

      // Check if loading was cancelled
      if (_loadingState != LoadingState.loading ||
          _loadingCompleter?.isCompleted == true) {
        log.info(
            'Loading operation was cancelled or completed - discarding results');
        return;
      }

      // Check if target changed during async operation
      if (_currentTarget != normalizedTarget) {
        log.info('Target changed during loading - discarding results');
        return;
      }

      if (exercises.isEmpty) {
        _setError(
            'No exercises found', 'No exercises available for this category.');
        return;
      }

      _exercises = exercises;
      _loadingState = LoadingState.success;

      // Update cache with new data
      _cache[normalizedTarget] = exercises;
      _updateRecentTargets(normalizedTarget);

      log.info('Exercises loaded: ${exercises.length}');

      // Complete the loading operation
      if (!_loadingCompleter!.isCompleted) {
        _loadingCompleter!.complete();
      }
    } catch (e) {
      // Handle different types of exceptions with friendly messages
      if (e is ApiException) {
        _setError(
          'Failed to load exercises',
          'API Error: ${e.message}',
        );
      } else if (e is NetworkException) {
        _setError(
          'Network error',
          'Please check your internet connection and try again.',
        );
      } else if (e is TimeoutException) {
        _setError(
          'Connection timeout',
          'The server is taking too long to respond. Please try again later.',
        );
      } else {
        _setError(
          'Unexpected error',
          'Something went wrong while loading exercises. Please try again.',
        );
      }
      log.severe('Error loading exercises: $e');

      // Complete the completer with an error
      if (_loadingCompleter != null && !_loadingCompleter!.isCompleted) {
        _loadingCompleter!.completeError(e);
      }
    } finally {
      _notifySafely();
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

    log.info('Cache cleaned: ${_cache.length} items remaining');
  }

  void _setLoading() {
    _loadingState = LoadingState.loading;
    _errorMessage = null;
    _errorDetails = null;
    _notifySafely();
  }

  void _setError(String message, String details) {
    _loadingState = LoadingState.error;
    _errorMessage = message;
    _errorDetails = details;
    _exercises = null;
  }

  void clearExercises() {
    _exercises = null;
    _errorMessage = null;
    _errorDetails = null;
    _loadingState = LoadingState.idle;
    _currentTarget = null;
    _notifySafely();
  }

  void retryCurrentTarget() {
    if (_currentTarget != null) {
      loadExercisesByTarget(_currentTarget!);
    }
  }

  // New method to cancel an ongoing loading operation
  void cancelLoading() {
    if (_loadingState == LoadingState.loading) {
      log.info('Cancelling loading operation');
      _loadingState = LoadingState.idle;

      // Complete the completer to signal cancellation
      if (_loadingCompleter != null && !_loadingCompleter!.isCompleted) {
        _loadingCompleter!.complete();
      }

      _notifySafely();
    }
  }

  // Method to clear error state
  void clearError() {
    if (_loadingState == LoadingState.error) {
      log.info('Clearing error state');
      _loadingState = LoadingState.idle;
      _errorMessage = null;
      _errorDetails = null;
      _notifySafely();
    }
  }

  void _notifySafely() {
    if (_isNotifying) {
      log.warning('Skipping notifyListeners: Already notifying');
      return;
    }

    _isNotifying = true;
    log.info('Notifying listeners - state: $_loadingState');

    try {
      notifyListeners();
    } catch (e) {
      log.severe('StateError caught in notifyListeners: $e');
    } finally {
      _isNotifying = false;
    }
  }
}
