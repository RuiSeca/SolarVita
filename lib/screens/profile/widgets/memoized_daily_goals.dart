import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/riverpod/user_progress_provider.dart';
import '../../../providers/riverpod/health_data_provider.dart';
import '../../../models/user/user_progress.dart';
import '../../../utils/translation_helper.dart';

class MemoizedDailyGoals extends ConsumerWidget {
  const MemoizedDailyGoals({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch only essential data to reduce rebuilds
    final progressValue = ref.watch(userProgressNotifierProvider.select(
      (async) => async.valueOrNull,
    ));
    
    final healthDataValue = ref.watch(healthDataNotifierProvider.select(
      (async) => async.valueOrNull,
    ));

    if (progressValue == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        height: 120,
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
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _MemoizedGoalsContent(
      progress: progressValue,
      healthData: healthDataValue,
    );
  }
}

class _MemoizedGoalsContent extends StatelessWidget {
  final UserProgress progress;
  final dynamic healthData;

  const _MemoizedGoalsContent({
    required this.progress,
    this.healthData,
  });

  @override
  Widget build(BuildContext context) {
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
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.track_changes,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(context, 'daily_goals'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                    Text(
                      _getGoalsSummary(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textColor(context).withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              _buildProgressRing(),
            ],
          ),
          const SizedBox(height: 16),
          _buildGoalsGrid(context),
          const SizedBox(height: 12),
          _buildSecondaryGoalsRow(context),
          const SizedBox(height: 16),
          _buildLevelProgress(context),
        ],
      ),
    );
  }

  String _getGoalsSummary() {
    final completedGoals = _getCompletedGoalsCount();
    return '$completedGoals/5 completed';
  }

  int _getCompletedGoalsCount() {
    int completed = 0;
    
    if (healthData == null) return 0;
    
    // Steps goal
    if (healthData.steps >= progress.dailyGoals.stepsGoal) completed++;
    
    // Active minutes goal  
    if (healthData.activeMinutes >= progress.dailyGoals.activeMinutesGoal) completed++;
    
    // Calories goal
    if (healthData.caloriesBurned >= progress.dailyGoals.caloriesBurnGoal) completed++;
    
    // Water intake goal
    if (healthData.waterIntake >= progress.dailyGoals.waterIntakeGoal) completed++;
    
    // Sleep quality goal (simplified check)
    if (healthData.sleepHours >= progress.dailyGoals.sleepHoursGoal) completed++;
    
    return completed;
  }

  Widget _buildProgressRing() {
    final completedGoals = _getCompletedGoalsCount();
    final progressPercent = completedGoals / 5.0;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            value: progressPercent,
            strokeWidth: 4,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        Text(
          '$completedGoals',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalsGrid(BuildContext context) {
    if (healthData != null) {
      return Row(
        children: [
          _buildGoalItem(
            context,
            icon: Icons.directions_walk,
            value: healthData!.steps.toString(),
            target: progress.dailyGoals.stepsGoal.toString(),
            isCompleted: healthData!.steps >= progress.dailyGoals.stepsGoal,
          ),
          const SizedBox(width: 12),
          _buildGoalItem(
            context,
            icon: Icons.timer,
            value: healthData!.activeMinutes.toString(),
            target: progress.dailyGoals.activeMinutesGoal.toString(),
            isCompleted: healthData!.activeMinutes >= progress.dailyGoals.activeMinutesGoal,
          ),
          const SizedBox(width: 12),
          _buildGoalItem(
            context,
            icon: Icons.local_fire_department,
            value: healthData!.caloriesBurned.toString(),
            target: progress.dailyGoals.caloriesBurnGoal.toString(),
            isCompleted: healthData!.caloriesBurned >= progress.dailyGoals.caloriesBurnGoal,
          ),
        ],
      );
    } else {
      return Row(
        children: [
          _buildGoalItem(
            context,
            icon: Icons.directions_walk,
            value: "0",
            target: progress.dailyGoals.stepsGoal.toString(),
            isCompleted: false,
          ),
          const SizedBox(width: 12),
          _buildGoalItem(
            context,
            icon: Icons.timer,
            value: "0",
            target: progress.dailyGoals.activeMinutesGoal.toString(),
            isCompleted: false,
          ),
          const SizedBox(width: 12),
          _buildGoalItem(
            context,
            icon: Icons.local_fire_department,
            value: "0",
            target: progress.dailyGoals.caloriesBurnGoal.toString(),
            isCompleted: false,
          ),
        ],
      );
    }
  }

  Widget _buildSecondaryGoalsRow(BuildContext context) {
    if (healthData != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: _buildGoalItem(
              context,
              icon: Icons.water_drop,
              value: healthData!.waterIntake.toStringAsFixed(1),
              target: progress.dailyGoals.waterIntakeGoal.toStringAsFixed(1),
              isCompleted: healthData!.waterIntake >= progress.dailyGoals.waterIntakeGoal,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildGoalItem(
              context,
              icon: Icons.bedtime,
              value: healthData!.sleepHours.toStringAsFixed(1),
              target: progress.dailyGoals.sleepHoursGoal.toString(),
              isCompleted: healthData!.sleepHours >= progress.dailyGoals.sleepHoursGoal,
            ),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: _buildGoalItem(
              context,
              icon: Icons.water_drop,
              value: "0.0",
              target: progress.dailyGoals.waterIntakeGoal.toStringAsFixed(1),
              isCompleted: false,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildGoalItem(
              context,
              icon: Icons.bedtime,
              value: "0.0",
              target: progress.dailyGoals.sleepHoursGoal.toString(),
              isCompleted: false,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildLevelProgress(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr(context, 'level_progress'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor(context),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tr(context, 'level_number').replaceAll('{level}', progress.currentLevel.toString()),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textColor(context).withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress.levelProgress,
          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
        const SizedBox(height: 4),
        Text(
          progress.isMaxLevel
              ? tr(context, 'max_level_reached')
              : tr(context, 'strikes_to_next_level').replaceAll(
                  '{strikes}',
                  progress.strikesNeededForNextLevel.toString(),
                ),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textColor(context).withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String target,
    required bool isCompleted,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCompleted 
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCompleted 
                ? AppColors.primary.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isCompleted ? AppColors.primary : AppTheme.textColor(context).withValues(alpha: 0.6),
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isCompleted ? AppColors.primary : AppTheme.textColor(context),
              ),
            ),
            Text(
              '/$target',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textColor(context).withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}