import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_theme.dart';
import '../../../models/privacy_settings.dart';

class SupporterWeeklySummary extends ConsumerWidget {
  final String supporterId;
  final PrivacySettings privacySettings;
  final Map<String, dynamic>? weeklyData;

  const SupporterWeeklySummary({
    super.key,
    required this.supporterId,
    required this.privacySettings,
    this.weeklyData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week\'s Journey',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildWeeklyCard(
                context,
                title: 'Steps',
                icon: Icons.directions_walk,
                value: _getStepsValue(),
                unit: _getStepsUnit(),
                color: Colors.blue,
                isVisible: privacySettings.showWorkoutStats,
              ),
              _buildWeeklyCard(
                context,
                title: 'Active Minutes',
                icon: Icons.fitness_center,
                value: _getActiveMinutesValue(),
                unit: _getActiveMinutesUnit(),
                color: Colors.orange,
                isVisible: privacySettings.showWorkoutStats,
              ),
              _buildWeeklyCard(
                context,
                title: 'Calories',
                icon: Icons.local_fire_department,
                value: _getCaloriesValue(),
                unit: _getCaloriesUnit(),
                color: Colors.red,
                isVisible: privacySettings.showNutritionStats,
              ),
              _buildWeeklyCard(
                context,
                title: 'Streak',
                icon: Icons.local_fire_department_outlined,
                value: _getStreakValue(),
                unit: _getStreakUnit(),
                color: Colors.purple,
                isVisible: privacySettings.showWorkoutStats,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String value,
    required String unit,
    required Color color,
    required bool isVisible,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isVisible
              ? [
                  color.withValues(alpha: 0.1),
                  color.withValues(alpha: 0.05),
                ]
              : [
                  Colors.grey.withValues(alpha: 0.1),
                  Colors.grey.withValues(alpha: 0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isVisible 
              ? color.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.3),
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
                  color: isVisible 
                      ? color.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isVisible ? icon : Icons.lock_outline,
                  color: isVisible ? color : Colors.grey[600],
                  size: 20,
                ),
              ),
              const Spacer(),
              if (!isVisible)
                Icon(
                  Icons.visibility_off,
                  color: Colors.grey[500],
                  size: 16,
                ),
            ],
          ),
          const Spacer(),
          if (isVisible) ...[
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else ...[
            Text(
              'Private',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Shared privately',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor(context),
            ),
          ),
        ],
      ),
    );
  }

  // Data getters - would be replaced with actual data from Firebase
  String _getStepsValue() {
    if (!privacySettings.showWorkoutStats) return 'Private';
    return weeklyData?['steps']?.toString() ?? '42,500';
  }

  String _getStepsUnit() {
    if (!privacySettings.showWorkoutStats) return '';
    return 'steps this week';
  }

  String _getActiveMinutesValue() {
    if (!privacySettings.showWorkoutStats) return 'Private';
    return weeklyData?['activeMinutes']?.toString() ?? '180';
  }

  String _getActiveMinutesUnit() {
    if (!privacySettings.showWorkoutStats) return '';
    return 'active minutes';
  }

  String _getCaloriesValue() {
    if (!privacySettings.showNutritionStats) return 'Private';
    return weeklyData?['calories']?.toString() ?? '12,400';
  }

  String _getCaloriesUnit() {
    if (!privacySettings.showNutritionStats) return '';
    return 'calories burned';
  }

  String _getStreakValue() {
    if (!privacySettings.showWorkoutStats) return 'Private';
    return weeklyData?['streak']?.toString() ?? '5';
  }

  String _getStreakUnit() {
    if (!privacySettings.showWorkoutStats) return '';
    return 'day streak';
  }
}