import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';
import '../models/user_progress.dart';
import '../models/health_data.dart';
import 'data_sync_service.dart';

final log = Logger('StrikeCalculationService');

class StrikeCalculationService {
  static const String _userProgressKey = 'user_progress';
  static const String _lastCheckDateKey = 'last_check_date';
  static const String _yesterdayGoalsKey = 'yesterday_goals_completed';
  
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  Timer? _midnightTimer;
  
  StrikeCalculationService(this._notificationsPlugin);

  // Initialize the service and set up midnight reset
  Future<void> initialize() async {
    log.info('🚀 Initializing Strike Calculation Service');
    
    // Check if we need to process any missed days
    await _checkForMissedDays();
    
    // Set up midnight timer
    _scheduleMidnightReset();
    
    log.info('✅ Strike Calculation Service initialized');
  }

  // Check if we missed any days and reset strikes if needed
  Future<void> _checkForMissedDays() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheckDateStr = prefs.getString(_lastCheckDateKey);
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    
    if (lastCheckDateStr != null) {
      final lastCheckDate = DateTime.parse(lastCheckDateStr);
      final daysDifference = todayDateOnly.difference(lastCheckDate).inDays;
      
      if (daysDifference > 1) {
        log.warning('⚠️ Missed ${daysDifference - 1} days, resetting current strikes only');
        await _resetStrikesKeepLevel();
      } else if (daysDifference == 1) {
        log.info('📅 New day detected, ready for goal checking');
      }
    }
    
    // Update last check date
    await prefs.setString(_lastCheckDateKey, todayDateOnly.toIso8601String());
  }

  // Schedule midnight reset timer
  void _scheduleMidnightReset() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = midnight.difference(now);
    
    log.info('⏰ Scheduling midnight reset in ${timeUntilMidnight.inHours}h ${timeUntilMidnight.inMinutes % 60}m');
    
    _midnightTimer?.cancel();
    _midnightTimer = Timer(timeUntilMidnight, () {
      log.info('🕛 Midnight reset triggered');
      _performMidnightReset();
      _scheduleMidnightReset(); // Schedule next day
    });
  }

  // Perform midnight reset and check previous day completion
  Future<void> _performMidnightReset() async {
    final progress = await getUserProgress();
    final prefs = await SharedPreferences.getInstance();
    
    // Get yesterday's goals from saved state, not current progress
    final yesterdayGoalsJson = prefs.getString(_yesterdayGoalsKey);
    Map<String, bool> yesterdayGoals = {};
    
    if (yesterdayGoalsJson != null) {
      try {
        yesterdayGoals = Map<String, bool>.from(json.decode(yesterdayGoalsJson));
      } catch (e) {
        log.warning('⚠️ Error parsing yesterday goals: $e');
        // Fallback to current progress goals (might be inaccurate but better than nothing)
        yesterdayGoals = progress.todayGoalsCompleted;
      }
    } else {
      // First time running or no saved data - use current progress
      yesterdayGoals = progress.todayGoalsCompleted;
    }
    
    // Check if any goals were completed yesterday
    final completedGoals = yesterdayGoals.values.where((completed) => completed).length;
    
    // IMPORTANT: Only reset strikes if EXACTLY 0 goals were completed
    // If user achieved at least 1 goal, maintain their streak and carry over strikes
    if (completedGoals == 0) {
      log.warning('❌ Zero goals completed yesterday - resetting current strikes only');
      await _resetStrikesKeepLevel();
      await _sendStrikeResetNotification();
    } else {
      log.info('✅ At least $completedGoals goal(s) completed yesterday - streak maintained, strikes carry over');
    }
    
    // Save today's goals as yesterday's goals for tomorrow's check
    await prefs.setString(_yesterdayGoalsKey, json.encode(progress.todayGoalsCompleted));
    
    // Reset daily goals for new day
    await _resetDailyGoals();
    await _sendDailyReminderNotification();
  }

  // Calculate strikes based on current health data
  Future<UserProgress> calculateStrikes(HealthData healthData) async {
    final currentProgress = await getUserProgress();
    final goals = currentProgress.dailyGoals;
    
    
    // Check each goal completion
    final goalsCompleted = <String, bool>{
      GoalType.steps.key: healthData.steps >= goals.stepsGoal,
      GoalType.activeMinutes.key: healthData.activeMinutes >= goals.activeMinutesGoal,
      GoalType.caloriesBurn.key: healthData.caloriesBurned >= goals.caloriesBurnGoal,
      GoalType.waterIntake.key: healthData.waterIntake >= goals.waterIntakeGoal,
      GoalType.sleepQuality.key: _checkSleepQuality(healthData.sleepHours, goals.sleepHoursGoal),
    };
    
    
    // Count completed goals
    final completedCount = goalsCompleted.values.where((completed) => completed).length;
    
    // Calculate multiplier (1x to 5x based on goals completed)
    final multiplier = completedCount > 0 ? completedCount : 1;
    final strikesToAdd = completedCount > 0 ? multiplier : 0;
    
    
    // Update if: more goals completed OR current strikes don't match what they should be for completed goals
    final expectedDailyStrikes = completedCount > 0 ? multiplier : 0;
    final actualStrikes = currentProgress.currentStrikes;
    final strikesCorrect = actualStrikes == expectedDailyStrikes;
    final shouldUpdate = currentProgress.completedGoalsCount < completedCount || !strikesCorrect;
    
    
    if (shouldUpdate) {
      // For daily strikes, set absolute value, not incremental
      final newDailyStrikes = strikesToAdd;
      final strikeDifference = newDailyStrikes - currentProgress.currentStrikes;
      final newTotalStrikes = currentProgress.totalStrikes + strikeDifference;
      final newLevel = _calculateLevel(newTotalStrikes);
      
      
      // Check if user leveled up
      final leveledUp = newLevel > currentProgress.currentLevel;
      
      // CRITICAL: Strikes ALWAYS carry over and accumulate, NEVER reset on level up
      // This ensures users don't lose progress when they reach a new level
      // The current strikes continue building toward the NEXT level
      final finalCurrentStrikes = (currentProgress.currentStrikes + strikeDifference).clamp(0, double.infinity).toInt();
      
      final updatedProgress = currentProgress.copyWith(
        currentStrikes: finalCurrentStrikes,
        totalStrikes: newTotalStrikes.clamp(0, double.infinity).toInt(),
        currentLevel: newLevel,
        lastStrikeDate: DateTime.now(),
        lastActivityDate: DateTime.now(),
        todayGoalsCompleted: goalsCompleted,
        todayMultiplier: multiplier,
      );
      
      await saveProgressTransactionally(updatedProgress);
      
      // Send notifications for achievements
      if (leveledUp) {
        await _sendLevelUpNotification(newLevel);
      }
      
      if (completedCount == 5) {
        await _sendPerfectDayNotification();
      }
      
      log.info('🎯 Progress: $completedCount goals, ${multiplier}x multiplier, $finalCurrentStrikes current strikes, $newTotalStrikes total strikes, Level $newLevel ${leveledUp ? "(🎉 LEVEL UP! Current strikes carried over to next level)" : ""}');
      
      return updatedProgress;
    }
    
    return currentProgress.copyWith(
      todayGoalsCompleted: goalsCompleted,
      lastActivityDate: DateTime.now(),
    );
  }

  // Check sleep quality (7-9 hours is optimal)
  bool _checkSleepQuality(double sleepHours, int goalHours) {
    return sleepHours >= 7.0 && sleepHours <= 9.0;
  }

  // Calculate level based on total strikes
  int _calculateLevel(int totalStrikes) {
    if (totalStrikes < 7) return 1;
    if (totalStrikes < 21) return 2;
    if (totalStrikes < 49) return 3;
    if (totalStrikes < 105) return 4;
    if (totalStrikes < 189) return 5; // 105 + 84
    if (totalStrikes < 315) return 6; // 189 + 126
    if (totalStrikes < 490) return 7; // 315 + 175
    if (totalStrikes < 720) return 8; // 490 + 230
    if (totalStrikes < 1015) return 9; // 720 + 295
    return 10; // Max level
  }

  // Reset strikes only when user achieves ZERO goals 
  // KEEPS: Current level, total strikes (lifetime achievement)
  // RESETS: Only current strikes (daily streak progress) back to 0
  Future<void> _resetStrikesKeepLevel() async {
    final currentProgress = await getUserProgress();
    final resetProgress = currentProgress.copyWith(
      currentStrikes: 0, // Reset current strikes to 0 - start rebuilding streak
      // totalStrikes stays the same! - lifetime achievement preserved
      // currentLevel stays the same! - user keeps their earned level
      todayGoalsCompleted: {},
      todayMultiplier: 1,
    );
    await _saveUserProgress(resetProgress);
    log.info('🔄 Zero goals achieved - current strikes reset to 0, Level ${currentProgress.currentLevel} maintained, ${currentProgress.totalStrikes} total strikes preserved');
  }

  // Reset daily goals for new day
  Future<void> _resetDailyGoals() async {
    final currentProgress = await getUserProgress();
    final resetProgress = currentProgress.copyWith(
      todayGoalsCompleted: {},
      todayMultiplier: 1,
    );
    await _saveUserProgress(resetProgress);
    log.info('🌅 Daily goals reset for new day');
  }

  // Get user progress from storage
  Future<UserProgress> getUserProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getString(_userProgressKey);
    
    UserProgress progress;
    if (progressJson != null) {
      try {
        final progressMap = json.decode(progressJson) as Map<String, dynamic>;
        progress = UserProgress.fromJson(progressMap);
      } catch (e) {
        log.warning('⚠️ Error parsing user progress: $e');
        progress = _createDefaultProgress();
      }
    } else {
      progress = _createDefaultProgress();
    }
    
    // Always sync water goal with user's custom daily limit
    progress = await _updateWaterGoalFromUserPreference(progress);
    
    return progress;
  }
  
  // Update water goal based on user's custom daily limit from SharedPreferences
  Future<UserProgress> _updateWaterGoalFromUserPreference(UserProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    final customWaterLimit = prefs.getDouble('water_daily_limit') ?? 2.0;
    
    // Only update if the water goal differs from user's custom limit
    if (progress.dailyGoals.waterIntakeGoal != customWaterLimit) {
      final updatedGoals = progress.dailyGoals.copyWith(
        waterIntakeGoal: customWaterLimit,
      );
      final updatedProgress = progress.copyWith(dailyGoals: updatedGoals);
      
      // Save the updated progress with the new water goal
      await _saveUserProgress(updatedProgress);
      log.info('💧 Updated water intake goal to ${customWaterLimit}L based on user preference');
      
      return updatedProgress;
    }
    
    return progress;
  }

  // Save user progress to storage
  Future<void> _saveUserProgress(UserProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = json.encode(progress.toJson());
    await prefs.setString(_userProgressKey, progressJson);
    
    // Sync to Firebase for supporters to see
    await DataSyncService().syncUserProgress(progress);
    
    // Also update public profile with current level and strikes
    try {
      await DataSyncService().syncPublicProfile(
        displayName: 'User', // Will be updated from actual profile
        avatarUrl: null,
        currentLevel: progress.currentLevel,
        currentStrikes: progress.currentStrikes,
        ecoScore: 0.0, // Will be calculated separately
        supporterCount: 0, // Will be fetched separately
        supportingCount: 0, // Will be fetched separately
      );
    } catch (e) {
      // Don't block on profile sync failures
    }
  }
  
  // Transactional update - ensures both health data and strikes are saved together
  Future<void> saveProgressTransactionally(UserProgress progress, {String? healthDataKey, String? healthDataValue}) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Start transaction-like operation
    final originalProgress = await getUserProgress();
    String? originalHealthData;
    
    if (healthDataKey != null) {
      originalHealthData = prefs.getString(healthDataKey);
    }
    
    try {
      // Save progress first
      final progressJson = json.encode(progress.toJson());
      await prefs.setString(_userProgressKey, progressJson);
      
      // Save health data if provided
      if (healthDataKey != null && healthDataValue != null) {
        await prefs.setString(healthDataKey, healthDataValue);
      }
      
      // Verify both saves succeeded
      final savedProgress = prefs.getString(_userProgressKey);
      if (savedProgress == null) {
        throw Exception('Progress save failed');
      }
      
      if (healthDataKey != null && healthDataValue != null) {
        final savedHealthData = prefs.getString(healthDataKey);
        if (savedHealthData == null) {
          throw Exception('Health data save failed');
        }
      }
      
      log.info('✅ Transactional save successful');
      
    } catch (e) {
      // Rollback on failure
      log.warning('⚠️ Transactional save failed, rolling back: $e');
      
      try {
        // Restore original progress
        final originalJson = json.encode(originalProgress.toJson());
        await prefs.setString(_userProgressKey, originalJson);
        
        // Restore original health data if it existed
        if (healthDataKey != null && originalHealthData != null) {
          await prefs.setString(healthDataKey, originalHealthData);
        }
        
        log.info('🔄 Rollback completed');
      } catch (rollbackError) {
        log.severe('❌ Rollback failed: $rollbackError');
      }
      
      rethrow;
    }
  }

  // Create default progress for new users
  UserProgress _createDefaultProgress() {
    final now = DateTime.now();
    return UserProgress(
      currentStrikes: 0,
      totalStrikes: 0,
      currentLevel: 1,
      lastStrikeDate: now,
      lastActivityDate: now,
      dailyGoals: const DailyGoals(),
      todayGoalsCompleted: {},
      todayMultiplier: 1,
    );
  }

  // Notification methods
  Future<void> _sendLevelUpNotification(int newLevel) async {
    const androidDetails = AndroidNotificationDetails(
      'level_up_channel',
      'Level Up Notifications',
      channelDescription: 'Notifications for level achievements',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'app_icon',
    );
    
    const notificationDetails = NotificationDetails(android: androidDetails);
    
    await _notificationsPlugin.show(
      1000 + newLevel,
      '🎉 Level Up!',
      'Congratulations! You reached Level $newLevel! 🏆',
      notificationDetails,
    );
  }

  Future<void> _sendPerfectDayNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'perfect_day_channel',
      'Perfect Day Notifications',
      channelDescription: 'Notifications for perfect day achievements',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'app_icon',
    );
    
    const notificationDetails = NotificationDetails(android: androidDetails);
    
    await _notificationsPlugin.show(
      2000,
      '🌟 Perfect Day!',
      'Amazing! You completed ALL daily goals today! 5x multiplier earned! 🎯',
      notificationDetails,
    );
  }

  Future<void> _sendStrikeResetNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'strike_reset_channel',
      'Strike Reset Notifications',
      channelDescription: 'Notifications when strikes are reset',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: 'app_icon',
    );
    
    const notificationDetails = NotificationDetails(android: androidDetails);
    
    await _notificationsPlugin.show(
      3000,
      '💔 Strike Reset',
      'Your streak was reset. Start fresh today! 💪',
      notificationDetails,
    );
  }

  Future<void> _sendDailyReminderNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Reminder Notifications',
      channelDescription: 'Daily reminders to complete goals',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: 'app_icon',
    );
    
    const notificationDetails = NotificationDetails(android: androidDetails);
    
    await _notificationsPlugin.show(
      4000,
      '🌅 New Day, New Goals!',
      'Complete your daily health goals to maintain your streak! 🔥',
      notificationDetails,
    );
  }

  // Manual goal completion (for testing or manual entry)
  Future<UserProgress> completeGoal(GoalType goalType) async {
    final currentProgress = await getUserProgress();
    final updatedGoals = Map<String, bool>.from(currentProgress.todayGoalsCompleted);
    updatedGoals[goalType.key] = true;
    
    final completedCount = updatedGoals.values.where((completed) => completed).length;
    final multiplier = completedCount;
    
    final newStrikes = currentProgress.currentStrikes + (multiplier - currentProgress.todayMultiplier);
    final newTotalStrikes = currentProgress.totalStrikes + (multiplier - currentProgress.todayMultiplier);
    final newLevel = _calculateLevel(newTotalStrikes);
    
    // Check if user leveled up
    final leveledUp = newLevel > currentProgress.currentLevel;
    
    // CRITICAL: Strikes always carry over and accumulate, never reset on level up
    final finalCurrentStrikes = newStrikes.clamp(0, double.infinity).toInt();
    
    final updatedProgress = currentProgress.copyWith(
      currentStrikes: finalCurrentStrikes,
      totalStrikes: newTotalStrikes.clamp(0, double.infinity).toInt(),
      currentLevel: newLevel,
      lastStrikeDate: DateTime.now(),
      lastActivityDate: DateTime.now(),
      todayGoalsCompleted: updatedGoals,
      todayMultiplier: multiplier,
    );
    
    await _saveUserProgress(updatedProgress);
    
    log.info('✅ Goal ${goalType.displayName} completed manually - ${leveledUp ? "🎉 Level up! Current strikes carried over to next level" : "Strikes accumulated"}');
    
    return updatedProgress;
  }

  // Cleanup resources
  void dispose() {
    _midnightTimer?.cancel();
    log.info('🧹 Strike Calculation Service disposed');
  }
}