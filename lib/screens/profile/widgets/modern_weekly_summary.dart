import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/riverpod/user_progress_provider.dart';
import '../../../providers/riverpod/health_data_provider.dart';
import 'dart:ui';

class ModernWeeklySummary extends ConsumerWidget {
  const ModernWeeklySummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProgressAsync = ref.watch(userProgressNotifierProvider);
    final healthDataAsync = ref.watch(healthDataNotifierProvider);
    
    return userProgressAsync.when(
      data: (userProgress) {
        // Calculate real progress based on actual goals and data
        final currentStrikes = userProgress.currentStrikes;
        final levelProgress = userProgress.levelProgress;
        
        // Get actual health data for calculations
        final healthData = healthDataAsync.value;
        final dailyStepsGoal = userProgress.dailyGoals.stepsGoal;
        final dailyActiveGoal = userProgress.dailyGoals.activeMinutesGoal;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This Week',
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildProgressCard(
                      context,
                      title: 'Daily Steps',
                      value: '${healthData?.steps ?? 0}',
                      target: '$dailyStepsGoal',
                      progress: healthData != null && dailyStepsGoal > 0 
                          ? (healthData.steps / dailyStepsGoal).clamp(0.0, 1.0)
                          : 0.0,
                      icon: Icons.directions_walk_outlined,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildProgressCard(
                      context,
                      title: 'Active Minutes',
                      value: '${healthData?.activeMinutes ?? 0}',
                      target: '$dailyActiveGoal',
                      progress: healthData != null && dailyActiveGoal > 0 
                          ? (healthData.activeMinutes / dailyActiveGoal).clamp(0.0, 1.0)
                          : 0.0,
                      icon: Icons.fitness_center_outlined,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildProgressCard(
                      context,
                      title: 'Calories Burned',
                      value: '${healthData?.caloriesBurned ?? 0}',
                      target: '${userProgress.dailyGoals.caloriesBurnGoal}',
                      progress: healthData != null && userProgress.dailyGoals.caloriesBurnGoal > 0 
                          ? (healthData.caloriesBurned / userProgress.dailyGoals.caloriesBurnGoal).clamp(0.0, 1.0)
                          : 0.0,
                      icon: Icons.local_fire_department_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildProgressCard(
                      context,
                      title: 'Streak',
                      value: '$currentStrikes',
                      target: '∞',
                      progress: levelProgress,
                      icon: Icons.emoji_events_outlined,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('Error loading weekly summary: $error'),
      ),
    );
  }

  Widget _buildProgressCard(
    BuildContext context, {
    required String title,
    required String value,
    required String target,
    required double progress,
    required IconData icon,
    required Color color,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withAlpha(26),
                color.withAlpha(13),
                Colors.white.withAlpha(13),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withAlpha(51),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(26),
                spreadRadius: 0,
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withAlpha(38),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                  ),
                  Text(
                    '$value/$target',
                    style: TextStyle(
                      color: AppTheme.textColor(context).withAlpha(153),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.textColor(context).withAlpha(179),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              // Progress Bar
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: color.withAlpha(51),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color,
                          color.withAlpha(204),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: color.withAlpha(102),
                          spreadRadius: 0,
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(progress * 100).toInt()}% complete',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}