// lib/screens/profile/settings/account/notifications_screen.dart
import 'package:flutter/material.dart';
import '../../../../services/notification_service.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/translation_helper.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();

  bool _workoutReminders = true;
  bool _ecoTips = true;
  bool _progressUpdates = true;
  bool _waterReminders = true;
  bool _mealReminders = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final workoutReminders = await _notificationService.workoutRemindersEnabled;
    final ecoTips = await _notificationService.ecoTipsEnabled;
    final progressUpdates = await _notificationService.progressUpdatesEnabled;
    final waterReminders = await _notificationService.waterRemindersEnabled;
    final mealReminders = await _notificationService.mealRemindersEnabled;

    if (mounted) {
      setState(() {
        _workoutReminders = workoutReminders;
        _ecoTips = ecoTips;
        _progressUpdates = progressUpdates;
        _waterReminders = waterReminders;
        _mealReminders = mealReminders;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor(context),
        title: Text(
          tr(context, 'notifications'),
          style: TextStyle(color: AppTheme.textColor(context)),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            title: tr(context, 'fitness_notifications'),
            children: [
              _buildSwitchTile(
                context,
                title: tr(context, 'workout_reminders'),
                subtitle: tr(context, 'workout_reminders_desc'),
                value: _workoutReminders,
                onChanged: (value) async {
                  setState(() => _workoutReminders = value);
                  await _notificationService.setNotificationPreference(
                      'workout_reminders', value);
                },
                icon: Icons.fitness_center,
              ),
              _buildSwitchTile(
                context,
                title: tr(context, 'progress_updates'),
                subtitle: tr(context, 'progress_updates_desc'),
                value: _progressUpdates,
                onChanged: (value) async {
                  setState(() => _progressUpdates = value);
                  await _notificationService.setNotificationPreference(
                      'progress_updates', value);
                },
                icon: Icons.trending_up,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: tr(context, 'health_reminders'),
            children: [
              _buildSwitchTile(
                context,
                title: tr(context, 'water_reminders'),
                subtitle: tr(context, 'water_reminders_desc'),
                value: _waterReminders,
                onChanged: (value) async {
                  setState(() => _waterReminders = value);
                  await _notificationService.setNotificationPreference(
                      'water_reminders', value);

                  if (value) {
                    await _notificationService.scheduleWaterReminder();
                  }
                },
                icon: Icons.water_drop,
              ),
              _buildSwitchTile(
                context,
                title: tr(context, 'meal_reminders'),
                subtitle: tr(context, 'meal_reminders_desc'),
                value: _mealReminders,
                onChanged: (value) async {
                  setState(() => _mealReminders = value);
                  await _notificationService.setNotificationPreference(
                      'meal_reminders', value);
                },
                icon: Icons.restaurant,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: tr(context, 'eco_notifications'),
            children: [
              _buildSwitchTile(
                context,
                title: tr(context, 'eco_tips'),
                subtitle: tr(context, 'eco_tips_desc'),
                value: _ecoTips,
                onChanged: (value) async {
                  // Capture the translated string before async operation
                  final sampleEcoTip = tr(context, 'sample_eco_tip');

                  setState(() => _ecoTips = value);
                  await _notificationService.setNotificationPreference(
                      'eco_tips', value);

                  if (value) {
                    await _notificationService.scheduleEcoTip(
                      tip: sampleEcoTip,
                    );
                  }
                },
                icon: Icons.eco,
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildTestSection(context),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context,
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: TextStyle(
          color: AppTheme.textColor(context),
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppTheme.textColor(context).withAlpha(179),
          fontSize: 14,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }

  Widget _buildTestSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'test_notifications'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              // Capture all context-dependent values before async operations
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final testAchievement = tr(context, 'test_achievement');
              final testMessage = tr(context, 'test_message');
              final testNotificationSent =
                  tr(context, 'test_notification_sent');

              await _notificationService.sendProgressCelebration(
                achievement: testAchievement,
                message: testMessage,
              );

              // Use the captured ScaffoldMessenger instead of context
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text(testNotificationSent)),
                );
              }
            },
            icon: const Icon(Icons.notification_important),
            label: Text(tr(context, 'send_test_notification')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
