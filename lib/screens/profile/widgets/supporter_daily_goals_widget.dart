import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';
import '../../../models/user/privacy_settings.dart';
import '../../../models/user/user_progress.dart';
import '../../../models/health/health_data.dart';
import '../../../widgets/common/rive_emoji_widget.dart';

class SupporterDailyGoalsWidget extends ConsumerWidget {
  final String supporterId;
  final PrivacySettings privacySettings;
  final UserProgress? supporterProgress;
  final HealthData? supporterHealthData;

  const SupporterDailyGoalsWidget({
    super.key,
    required this.supporterId,
    required this.privacySettings,
    this.supporterProgress,
    this.supporterHealthData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
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
              Icon(Icons.emoji_events, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                tr(context, 'daily_goals_progress'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (privacySettings.showWorkoutStats && supporterProgress != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getMultiplierColor(
                          supporterProgress!.todayMultiplier,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${supporterProgress!.todayMultiplier}x',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.lock, color: Colors.grey[600], size: 16),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressSummaryWithEmoji(context),
          const SizedBox(height: 20),
          _buildGoalsList(context),
          const SizedBox(height: 16),
          _buildProgressBar(context),
        ],
      ),
    );
  }

  Widget _buildGoalsList(BuildContext context) {
    if (!privacySettings.showWorkoutStats) {
      return _buildPrivateGoalsView(context);
    }

    if (supporterProgress == null || supporterHealthData == null) {
      return _buildNoDataView(context);
    }

    // Show actual progress data
    final goals = [
      _GoalItem(
        type: GoalType.steps,
        current: supporterHealthData!.steps.toDouble(),
        target: supporterProgress!.dailyGoals.stepsGoal.toDouble(),
        unit: tr(context, 'steps'),
        isCompleted: _isGoalCompleted(GoalType.steps),
      ),
      _GoalItem(
        type: GoalType.activeMinutes,
        current: supporterHealthData!.activeMinutes.toDouble(),
        target: supporterProgress!.dailyGoals.activeMinutesGoal.toDouble(),
        unit: tr(context, 'min'),
        isCompleted: _isGoalCompleted(GoalType.activeMinutes),
      ),
      _GoalItem(
        type: GoalType.caloriesBurn,
        current: supporterHealthData!.caloriesBurned.toDouble(),
        target: supporterProgress!.dailyGoals.caloriesBurnGoal.toDouble(),
        unit: tr(context, 'cal'),
        isCompleted: _isGoalCompleted(GoalType.caloriesBurn),
      ),
      _GoalItem(
        type: GoalType.waterIntake,
        current: supporterHealthData!.waterIntake,
        target: supporterProgress!.dailyGoals.waterIntakeGoal,
        unit: tr(context, 'L'),
        isCompleted: _isGoalCompleted(GoalType.waterIntake),
      ),
      _GoalItem(
        type: GoalType.sleepQuality,
        current: supporterHealthData!.sleepHours,
        target: supporterProgress!.dailyGoals.sleepHoursGoal.toDouble(),
        unit: tr(context, 'hrs'),
        isCompleted: _isGoalCompleted(GoalType.sleepQuality),
      ),
    ];

    return Column(children: goals.map((goal) => _buildGoalRow(context, goal)).toList());
  }

  Widget _buildPrivateGoalsView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_outline, color: Colors.grey[500], size: 48),
          const SizedBox(height: 12),
          Text(
            tr(context, 'daily_goals_shared_privately'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr(context, 'supporter_keeps_daily_progress_private'),
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.data_usage_outlined, color: Colors.orange[600], size: 48),
          const SizedBox(height: 12),
          Text(
            tr(context, 'no_recent_activity'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.orange[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr(context, 'supporter_hasnt_synced_health_data'),
            style: TextStyle(fontSize: 14, color: Colors.orange[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalRow(BuildContext context, _GoalItem goal) {
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
              child: Text(goal.type.icon, style: const TextStyle(fontSize: 16)),
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
                      goal.type.displayName(context),
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
            Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    if (!privacySettings.showWorkoutStats || supporterProgress == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.grey[500], size: 20),
            const SizedBox(width: 8),
            Text(
              tr(context, 'level_progress_shared_privately'),
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr(context, 'level_progress'),
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
                  tr(context, 'level').replaceAll(
                    '{level}',
                    supporterProgress!.currentLevel.toString(),
                  ),
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
          value: supporterProgress!.levelProgress,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
        const SizedBox(height: 4),
        Text(
          supporterProgress!.isMaxLevel
              ? tr(context, 'max_level_reached')
              : tr(context, 'strikes_to_next_level').replaceAll(
                  '{strikes}',
                  supporterProgress!.strikesNeededForNextLevel.toString(),
                ),
          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildProgressSummaryWithEmoji(BuildContext context) {
    if (!privacySettings.showWorkoutStats) {
      return Text(
        tr(context, 'working_towards_goals_privately'),
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    if (supporterProgress == null) {
      return Text(
        tr(context, 'no_recent_activity_data'),
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final completedCount = supporterProgress!.completedGoalsCount;
    String text;
    Widget? emojiWidget;

    if (completedCount == 0) {
      text = tr(context, 'getting_started_with_goals');
      // No emoji for 0 goals
    } else if (completedCount == 5) {
      text = tr(context, 'perfect_day_all_goals');
      emojiWidget = RiveEmojiWidget(
        emojiType: EmojiType.fromGoalCount(completedCount),
        size: 24,
        autoplay: true,
        continuousPlay: true,
      );
    } else {
      text = tr(
        context,
        'goals_completed_today',
      ).replaceAll('{count}', completedCount.toString());
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

  String _formatGoalProgress(_GoalItem goal) {
    if (goal.type == GoalType.waterIntake) {
      return '${goal.current.toStringAsFixed(1)}/${goal.target.toStringAsFixed(1)} ${goal.unit}';
    } else {
      return '${goal.current.toInt()}/${goal.target.toInt()} ${goal.unit}';
    }
  }

  bool _isGoalCompleted(GoalType goalType) {
    if (supporterProgress == null) return false;
    return supporterProgress!.todayGoalsCompleted[goalType.key] ?? false;
  }

  Color _getMultiplierColor(int multiplier) {
    switch (multiplier) {
      case 1:
        return Colors.grey;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.purple;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
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
