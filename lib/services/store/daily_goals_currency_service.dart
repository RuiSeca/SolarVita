import 'dart:async';
import 'package:logging/logging.dart';
import '../../models/store/currency_system.dart';
import '../../models/user/user_progress.dart';
import './currency_service.dart';

final log = Logger('DailyGoalsCurrencyService');

/// Service that integrates daily goals completion with currency system
/// Handles both streak tracking and points accumulation
class DailyGoalsCurrencyService {
  final CurrencyService _currencyService;
  
  // Track the last processed date to avoid double-processing
  DateTime? _lastProcessedDate;

  DailyGoalsCurrencyService(this._currencyService);

  /// Initialize the service
  Future<void> initialize() async {
    log.info('🎯 Initializing Daily Goals Currency Service');
    
    // Initial sync with current progress (if available)
    await syncWithUserProgress();
  }

  /// Process daily goal completion and update currency accordingly
  Future<void> _processGoalCompletion(UserProgress progress) async {
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    
    // Avoid double-processing the same day
    if (_lastProcessedDate != null && 
        _lastProcessedDate!.isAtSameMomentAs(todayDateOnly)) {
      return;
    }

    try {
      // Count completed goals for today
      final completedGoalsCount = _countCompletedGoals(progress);
      
      log.info('📊 Processing daily goals: $completedGoalsCount completed');

      if (completedGoalsCount > 0) {
        // Update points (never resets, always accumulates)
        await _updatePoints(completedGoalsCount);
        
        // Update streak (consecutive days)
        await _updateStreak(progress.dayStreak);
        
        _lastProcessedDate = todayDateOnly;
      } else {
        // No goals completed - streak should reset to 0
        // Points remain unchanged
        await _resetStreakIfNeeded();
      }

    } catch (e, stackTrace) {
      log.severe('❌ Error processing goal completion: $e', e, stackTrace);
    }
  }

  /// Count how many daily goals were completed today
  int _countCompletedGoals(UserProgress progress) {
    // Count completed goals from todayGoalsCompleted map
    return progress.todayGoalsCompleted.values.where((completed) => completed).length;
  }

  /// Update points based on completed goals (accumulative, never resets)
  Future<void> _updatePoints(int completedGoals) async {
    try {
      // Add points equal to number of completed goals
      await _currencyService.addCurrency(
        CurrencyType.points, 
        completedGoals,
        'daily_goals_completed',
        metadata: {
          'goals_completed': completedGoals,
          'date': DateTime.now().toIso8601String(),
        },
      );
      
      log.info('✅ Added $completedGoals points for daily goals completion');
    } catch (e) {
      log.warning('⚠️ Failed to update points: $e');
    }
  }

  /// Update streak based on consecutive days (resets on break)
  Future<void> _updateStreak(int currentStreak) async {
    try {
      // Set streak to match the current day streak from user progress
      final currentCurrency = await _currencyService.getCurrentCurrencyAsync();
      final currentStreakBalance = currentCurrency?.getBalance(CurrencyType.streak) ?? 0;
      
      if (currentStreakBalance != currentStreak) {
        // Update streak to match user progress
        await _currencyService.setCurrency(
          CurrencyType.streak, 
          currentStreak,
          'streak_updated',
          metadata: {
            'streak_days': currentStreak,
            'date': DateTime.now().toIso8601String(),
          },
        );
        
        log.info('🔥 Streak updated to $currentStreak days');
      }
    } catch (e) {
      log.warning('⚠️ Failed to update streak: $e');
    }
  }

  /// Reset streak to 0 when no goals completed
  Future<void> _resetStreakIfNeeded() async {
    try {
      final currentCurrency = await _currencyService.getCurrentCurrencyAsync();
      final currentStreakBalance = currentCurrency?.getBalance(CurrencyType.streak) ?? 0;
      
      if (currentStreakBalance > 0) {
        await _currencyService.setCurrency(
          CurrencyType.streak, 
          0,
          'streak_reset',
          metadata: {
            'reason': 'no_goals_completed',
            'date': DateTime.now().toIso8601String(),
          },
        );
        
        log.info('💔 Streak reset to 0 - no goals completed today');
      }
    } catch (e) {
      log.warning('⚠️ Failed to reset streak: $e');
    }
  }

  /// Manually sync currency with current user progress
  /// This method should be called externally with user progress data
  Future<void> syncWithUserProgress([UserProgress? progress]) async {
    try {
      if (progress == null) {
        log.info('⏳ No user progress provided for sync');
        return;
      }
      
      // Sync points with total strikes (accumulated goals over time)
      await _currencyService.setCurrency(
        CurrencyType.points,
        progress.totalStrikes,
        'sync_with_progress',
        metadata: {'source': 'total_strikes_sync'},
      );
      
      // Sync streak with current day streak
      await _updateStreak(progress.dayStreak);
      
      log.info('🔄 Currency synced with user progress');
    } catch (e) {
      log.warning('⚠️ Error during currency sync: $e');
    }
  }

  /// Process daily goal completion (to be called from external progress changes)
  Future<void> processGoalCompletion(UserProgress progress) async {
    await _processGoalCompletion(progress);
  }

  /// Dispose the service and clean up subscriptions
  void dispose() {
    log.info('🧹 Disposing Daily Goals Currency Service');
  }
}