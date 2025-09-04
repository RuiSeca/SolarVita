import 'package:flutter_riverpod/flutter_riverpod.dart';

enum InitializationStatus {
  initializing,
  completed,
  error,
}

class InitializationState {
  final InitializationStatus status;
  final String? errorMessage;
  final double progress;

  const InitializationState({
    required this.status,
    this.errorMessage,
    this.progress = 0.0,
  });

  InitializationState copyWith({
    InitializationStatus? status,
    String? errorMessage,
    double? progress,
  }) {
    return InitializationState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      progress: progress ?? this.progress,
    );
  }
}

class InitializationNotifier extends StateNotifier<InitializationState> {
  InitializationNotifier() : super(const InitializationState(
    status: InitializationStatus.initializing,
  )) {
    // Start listening to initialization progress
    _startInitializationTracking();
  }

  void _startInitializationTracking() {
    // Set a minimum splash duration to ensure video plays
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // Check if main initialization is done
        // For now, we'll assume it's completed after 2 seconds minimum
        state = state.copyWith(
          status: InitializationStatus.completed,
          progress: 1.0,
        );
      }
    });
  }

  void updateProgress(double progress) {
    if (mounted) {
      state = state.copyWith(progress: progress);
    }
  }

  void markCompleted() {
    if (mounted) {
      state = state.copyWith(
        status: InitializationStatus.completed,
        progress: 1.0,
      );
    }
  }

  void markError(String errorMessage) {
    if (mounted) {
      state = state.copyWith(
        status: InitializationStatus.error,
        errorMessage: errorMessage,
      );
    }
  }
}

final initializationNotifierProvider = StateNotifierProvider<InitializationNotifier, InitializationState>((ref) {
  return InitializationNotifier();
});