import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/riverpod/user_progress_provider.dart';
import '../../../providers/riverpod/health_data_provider.dart';
import '../../../models/user_progress.dart';
import '../../../widgets/common/rive_emoji_widget.dart';
class DailyGoalsProgressWidget extends ConsumerWidget {
  const DailyGoalsProgressWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(userProgressNotifierProvider);
    final healthDataAsync = ref.watch(healthDataNotifierProvider);
    
    return progressAsync.when(
      data: (progress) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.1),
              AppColors.secondary.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Daily Goals Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getMultiplierColor(progress.todayMultiplier),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${progress.todayMultiplier}x',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProgressSummaryWithEmoji(progress),
            const SizedBox(height: 20),
            _buildGoalsList(progress, healthDataAsync.value, ref),
            const SizedBox(height: 16),
            _buildProgressBar(progress),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Text(
          'Error loading progress: $error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildGoalsList(UserProgress progress, dynamic healthData, WidgetRef ref) {
    // Check if we have real health data - no fake data should be shown
    final hasRealData = healthData?.isDataAvailable ?? false;
    
    // If no real data available, show connection status instead of fake numbers
    if (!hasRealData) {
      return _buildHealthDataConnectionPrompt(ref);
    }
    
    // Only show progress with real data - never display zeros as fake progress
    final goals = [
      _GoalItem(
        type: GoalType.steps,
        current: healthData.steps.toDouble(),
        target: progress.dailyGoals.stepsGoal.toDouble(),
        unit: 'steps',
        isCompleted: ref.watch(isGoalCompletedProvider(GoalType.steps)),
      ),
      _GoalItem(
        type: GoalType.activeMinutes,
        current: healthData.activeMinutes.toDouble(),
        target: progress.dailyGoals.activeMinutesGoal.toDouble(),
        unit: 'min',
        isCompleted: ref.watch(isGoalCompletedProvider(GoalType.activeMinutes)),
      ),
      _GoalItem(
        type: GoalType.caloriesBurn,
        current: healthData.caloriesBurned.toDouble(),
        target: progress.dailyGoals.caloriesBurnGoal.toDouble(),
        unit: 'cal',
        isCompleted: ref.watch(isGoalCompletedProvider(GoalType.caloriesBurn)),
      ),
      _GoalItem(
        type: GoalType.waterIntake,
        current: healthData.waterIntake,
        target: progress.dailyGoals.waterIntakeGoal,
        unit: 'L',
        isCompleted: ref.watch(isGoalCompletedProvider(GoalType.waterIntake)),
      ),
      _GoalItem(
        type: GoalType.sleepQuality,
        current: healthData.sleepHours,
        target: progress.dailyGoals.sleepHoursGoal.toDouble(),
        unit: 'hrs',
        isCompleted: ref.watch(isGoalCompletedProvider(GoalType.sleepQuality)),
      ),
    ];

    return Column(
      children: goals.map((goal) => _buildGoalRow(goal)).toList(),
    );
  }
  
  Widget _buildHealthDataConnectionPrompt(WidgetRef ref) {
    final permissionsAsync = ref.watch(healthPermissionsNotifierProvider);
    
    return permissionsAsync.when(
      data: (permissions) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.health_and_safety,
                color: Colors.orange,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                permissions.isGranted 
                  ? 'No health data available'
                  : 'Health permissions needed',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                permissions.isGranted 
                  ? 'Please ensure your health app is recording data and try refreshing.'
                  : 'Grant health permissions to see your real progress.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.orange.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  if (permissions.isGranted) {
                    // Refresh health data
                    await ref.read(healthDataNotifierProvider.notifier).refreshHealthData();
                  } else {
                    // Request permissions
                    await ref.read(healthPermissionsNotifierProvider.notifier).requestPermissions();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: Text(permissions.isGranted ? 'Refresh Data' : 'Grant Permissions'),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('Error: $error'),
    );
  }

  Widget _buildGoalRow(_GoalItem goal) {
    final progressPercent = (goal.current / goal.target).clamp(0.0, 1.0);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: goal.isCompleted 
                  ? Colors.green.withValues(alpha: 0.2)
                  : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                goal.type.icon,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      goal.type.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _formatGoalProgress(goal),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progressPercent,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    goal.isCompleted ? Colors.green : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (goal.isCompleted)
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(UserProgress progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Level Progress',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Level ${progress.currentLevel}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress.levelProgress,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
        const SizedBox(height: 4),
        Text(
          progress.isMaxLevel 
              ? 'Max Level Reached!' 
              : '${progress.strikesNeededForNextLevel} strikes to next level',
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatGoalProgress(_GoalItem goal) {
    // Format numbers based on type - water intake shows 1 decimal, others show whole numbers
    if (goal.type == GoalType.waterIntake) {
      return '${goal.current.toStringAsFixed(1)}/${goal.target.toStringAsFixed(1)} ${goal.unit}';
    } else {
      return '${goal.current.toInt()}/${goal.target.toInt()} ${goal.unit}';
    }
  }

  Color _getMultiplierColor(int multiplier) {
    switch (multiplier) {
      case 1: return Colors.grey;
      case 2: return Colors.blue;
      case 3: return Colors.orange;
      case 4: return Colors.purple;
      case 5: return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildProgressSummaryWithEmoji(UserProgress progress) {
    final completedCount = progress.completedGoalsCount;
    String text;
    Widget? emojiWidget;

    if (completedCount == 0) {
      text = 'Getting started with daily goals!';
      // No emoji for 0 goals
    } else if (completedCount == 5) {
      text = 'Perfect day! All goals completed!';
      emojiWidget = RiveEmojiWidget(
        emojiType: EmojiType.fromGoalCount(completedCount),
        size: 24,
        autoplay: true,
        continuousPlay: true,
      );
    } else {
      text = '$completedCount/5 goals completed today';
      emojiWidget = RiveEmojiWidget(
        emojiType: EmojiType.fromGoalCount(completedCount),
        size: 24,
        autoplay: true,
        continuousPlay: true,
      );
    }

    if (emojiWidget == null) {
      return Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        emojiWidget,
      ],
    );
  }
}

class _GoalItem {
  final GoalType type;
  final double current;
  final double target;
  final String unit;
  final bool isCompleted;

  _GoalItem({
    required this.type,
    required this.current,
    required this.target,
    required this.unit,
    required this.isCompleted,
  });
}