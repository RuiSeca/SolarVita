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
    // Prevent duplicate loading of the same target
    if (isLoading) {
      log.warning('Skipping loadExercisesByTarget: Already loading');
      return;
    }

    // Skip if we're already loaded for this target
    if (_currentTarget == target && hasData) {
      log.info('Already loaded data for target: $target');
      return;
    }

    log.info('Starting loadExercisesByTarget: $target');
    _setLoading();
    _currentTarget = target;

    try {
      log.fine('Fetching exercises for target: $target');
      final exercises = await _exerciseService.getExercisesByTarget(target);

      // Check if target changed during async operation
      if (_currentTarget != target) {
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
      log.info('Exercises loaded: ${exercises.length}');
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
    } finally {
      _notifySafely();
    }
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
