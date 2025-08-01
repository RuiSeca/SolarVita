import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';
import '../../../models/user/privacy_settings.dart';

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
            tr(context, 'this_weeks_journey'),
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
                title: tr(context, 'steps'),
                icon: Icons.directions_walk,
                value: _getStepsValue(context),
                unit: _getStepsUnit(context),
                color: Colors.blue,
                isVisible: privacySettings.showWorkoutStats,
              ),
              _buildWeeklyCard(
                context,
                title: tr(context, 'active_minutes'),
                icon: Icons.fitness_center,
                value: _getActiveMinutesValue(context),
                unit: _getActiveMinutesUnit(context),
                color: Colors.orange,
                isVisible: privacySettings.showWorkoutStats,
              ),
              _buildWeeklyCard(
                context,
                title: tr(context, 'calories'),
                icon: Icons.local_fire_department,
                value: _getCaloriesValue(context),
                unit: _getCaloriesUnit(context),
                color: Colors.red,
                isVisible: privacySettings.showNutritionStats,
              ),
              _buildWeeklyCard(
                context,
                title: tr(context, 'streak'),
                icon: Icons.local_fire_department_outlined,
                value: _getStreakValue(context),
                unit: _getStreakUnit(context),
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
              ? [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)]
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
                Icon(Icons.visibility_off, color: Colors.grey[500], size: 16),
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
              tr(context, 'private'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            Text(
              tr(context, 'shared_privately'),
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
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
  String _getStepsValue(BuildContext context) {
    if (!privacySettings.showWorkoutStats) return tr(context, 'private');
    return weeklyData?['steps']?.toString() ?? '42,500';
  }

  String _getStepsUnit(BuildContext context) {
    if (!privacySettings.showWorkoutStats) return '';
    return tr(context, 'steps_this_week');
  }

  String _getActiveMinutesValue(BuildContext context) {
    if (!privacySettings.showWorkoutStats) return tr(context, 'private');
    return weeklyData?['activeMinutes']?.toString() ?? '180';
  }

  String _getActiveMinutesUnit(BuildContext context) {
    if (!privacySettings.showWorkoutStats) return '';
    return tr(context, 'active_minutes_text');
  }

  String _getCaloriesValue(BuildContext context) {
    if (!privacySettings.showNutritionStats) return tr(context, 'private');
    return weeklyData?['calories']?.toString() ?? '12,400';
  }

  String _getCaloriesUnit(BuildContext context) {
    if (!privacySettings.showNutritionStats) return '';
    return tr(context, 'calories_burned');
  }

  String _getStreakValue(BuildContext context) {
    if (!privacySettings.showWorkoutStats) return tr(context, 'private');
    return weeklyData?['streak']?.toString() ?? '5';
  }

  String _getStreakUnit(BuildContext context) {
    if (!privacySettings.showWorkoutStats) return '';
    return tr(context, 'day_streak');
  }
}
