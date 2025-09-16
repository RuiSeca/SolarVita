import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user/strike_calculation_service.dart';
import '../../services/database/notification_service.dart';
import '../../models/user/user_progress.dart';
import '../../models/health/health_data.dart';
import 'auth_provider.dart';

// Strike calculation service provider
final strikeCalculationServiceProvider = Provider<StrikeCalculationService>((
  ref,
) {
  final notificationService = NotificationService();
  return StrikeCalculationService(notificationService.localNotifications);
});

// User progress state management
class UserProgressNotifier extends AsyncNotifier<UserProgress> {
  late StrikeCalculationService _strikeService;
  Timer? _periodicUpdateTimer;
  String? _lastUserId;

  @override
  Future<UserProgress> build() async {
    _strikeService = ref.read(strikeCalculationServiceProvider);

    // Listen to auth state changes and reset service when user changes
    ref.listen<AsyncValue<User?>>(authStateChangesProvider, (previous, next) {
      next.whenData((user) async {
        final currentUserId = user?.uid;

        if (_lastUserId != null && _lastUserId != currentUserId) {
          // User changed - reset the service
          await _strikeService.resetForNewUser();

          // Refresh the provider state
          ref.invalidateSelf();
        }

        _lastUserId = currentUserId;
      });
    });

    // Initialize the strike service
    await _strikeService.initialize();

    // Set current user ID
    _lastUserId = FirebaseAuth.instance.currentUser?.uid;

    // Set up periodic updates every 5 minutes
    _setupPeriodicUpdates();

    // Get initial progress
    return await _strikeService.getUserProgress();
  }

  // Set up periodic updates to check goals automatically
  void _setupPeriodicUpdates() {
    _periodicUpdateTimer?.cancel();
    _periodicUpdateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      // Refresh progress periodically
      _refreshProgress();
    });
  }

  // Update progress based on current health data with retry logic
  Future<void> updateProgress(HealthData healthData) async {
    await _updateProgressWithRetry(healthData);
  }

  Future<void> _updateProgressWithRetry(HealthData healthData) async {
    const maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        state = const AsyncValue.loading();
        final updatedProgress = await _strikeService.calculateStrikes(
          healthData,
        );
        state = AsyncValue.data(updatedProgress);
        return; // Success - exit retry loop
      } catch (error, stackTrace) {
        retryCount++;

        if (retryCount >= maxRetries) {
          // Final retry failed
          state = AsyncValue.error(error, stackTrace);
          return;
        }

        // Wait before retry with exponential backoff
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      }
    }
  }

  // Complete a specific goal manually
  Future<void> completeGoal(GoalType goalType) async {
    try {
      final updatedProgress = await _strikeService.completeGoal(goalType);
      state = AsyncValue.data(updatedProgress);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Refresh current progress
  Future<void> _refreshProgress() async {
    try {
      final currentProgress = await _strikeService.getUserProgress();
      if (state.hasValue && state.value != currentProgress) {
        state = AsyncValue.data(currentProgress);
      }
    } catch (error) {
      // Silently handle refresh errors to avoid disrupting user experience
    }
  }

  // Manually refresh progress (for pull-to-refresh)
  Future<void> refresh() async {
    try {
      state = const AsyncValue.loading();
      final currentProgress = await _strikeService.getUserProgress();
      state = AsyncValue.data(currentProgress);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void cleanUp() {
    _periodicUpdateTimer?.cancel();
    _strikeService.dispose();
  }
}

// Provider instance
final userProgressNotifierProvider =
    AsyncNotifierProvider<UserProgressNotifier, UserProgress>(
      () => UserProgressNotifier(),
    );

// Convenience providers for common data access
final currentStrikesProvider = Provider<int>((ref) {
  final progressAsync = ref.watch(userProgressNotifierProvider);
  return progressAsync.when(
    data: (progress) => progress.currentStrikes,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final totalStrikesProvider = Provider<int>((ref) {
  final progressAsync = ref.watch(userProgressNotifierProvider);
  return progressAsync.when(
    data: (progress) => progress.totalStrikes,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// NEW: Day streak provider for consecutive days with at least one goal completed
final dayStreakProvider = Provider<int>((ref) {
  final progressAsync = ref.watch(userProgressNotifierProvider);
  return progressAsync.when(
    data: (progress) => progress.dayStreak,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final currentLevelProvider = Provider<int>((ref) {
  final progressAsync = ref.watch(userProgressNotifierProvider);
  return progressAsync.when(
    data: (progress) => progress.currentLevel,
    loading: () => 1,
    error: (_, __) => 1,
  );
});

// Removed levelTitleProvider - use progress.levelTitle(context) directly in widgets

final levelIconProvider = Provider<String>((ref) {
  final progressAsync = ref.watch(userProgressNotifierProvider);
  return progressAsync.when(
    data: (progress) => progress.levelIcon,
    loading: () => '🌱',
    error: (_, __) => '🌱',
  );
});

final levelProgressProvider = Provider<double>((ref) {
  final progressAsync = ref.watch(userProgressNotifierProvider);
  return progressAsync.when(
    data: (progress) => progress.levelProgress,
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

final strikesNeededForNextLevelProvider = Provider<int>((ref) {
  final progressAsync = ref.watch(userProgressNotifierProvider);
  return progressAsync.when(
    data: (progress) => progress.strikesNeededForNextLevel,
    loading: () => 7,
    error: (_, __) => 7,
  );
});

final isMaxLevelProvider = Provider<bool>((ref) {
  final progressAsync = ref.watch(userProgressNotifierProvider);
  return progressAsync.when(
    data: (progress) => progress.isMaxLevel,
    loading: () => false,
    error: (_, __) => false,
  );
});

final todayGoalsCompletedProvider = Provider<Map<String, bool>>((ref) {
  final progressAsync = ref.watch(userProgressNotifierProvider);
  return progressAsync.when(
    data: (progress) => progress.todayGoalsCompleted,
    loading: () => {},
    error: (_, __) => {},
  );
});

final todayMultiplierProvider = Provider<int>((ref) {
  final progressAsync = ref.watch(userProgressNotifierProvider);
  return progressAsync.when(
    data: (progress) => progress.todayMultiplier,
    loading: () => 1,
    error: (_, __) => 1,
  );
});

final completedGoalsCountProvider = Provider<int>((ref) {
  final progressAsync = ref.watch(userProgressNotifierProvider);
  return progressAsync.when(
    data: (progress) => progress.completedGoalsCount,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final isGoalCompletedProvider = Provider.family<bool, GoalType>((
  ref,
  goalType,
) {
  final todayGoals = ref.watch(todayGoalsCompletedProvider);
  return todayGoals[goalType.key] ?? false;
});

// Progress summary for UI display
final progressSummaryProvider = Provider<String>((ref) {
  final progressAsync = ref.watch(userProgressNotifierProvider);
  return progressAsync.when(
    data: (progress) {
      if (progress.completedGoalsCount == 0) {
        return 'Complete daily goals to earn strikes! 🎯';
      } else if (progress.completedGoalsCount == 5) {
        return 'Perfect day! All goals completed! 🌟';
      } else {
        return '${progress.completedGoalsCount}/5 goals completed today 🔥';
      }
    },
    loading: () => 'Loading progress...',
    error: (_, __) => 'Error loading progress',
  );
});

// Streak status for UI display
final streakStatusProvider = Provider<String>((ref) {
  final strikes = ref.watch(currentStrikesProvider);
  final level = ref.watch(currentLevelProvider);

  if (strikes == 0) {
    return 'Start your health journey! 🌱';
  } else if (strikes == 1) {
    return '1 day streak - Keep going! 🔥';
  } else {
    return '$strikes day streak - Level $level! 🏆';
  }
});

// Water daily limit provider - reads from SharedPreferences
final waterDailyLimitProvider = FutureProvider<double>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getDouble('water_daily_limit') ?? 2.0;
});
