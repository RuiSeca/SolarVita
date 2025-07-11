import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_theme.dart';
import '../../../../models/notification_preferences.dart';
import '../../../../providers/user_profile_provider.dart';
import '../../../../services/notification_service.dart';
import '../../../../services/meal_plan_service.dart';

class EnhancedNotificationsScreen extends StatefulWidget {
  const EnhancedNotificationsScreen({super.key});

  @override
  State<EnhancedNotificationsScreen> createState() =>
      _EnhancedNotificationsScreenState();
}

class _EnhancedNotificationsScreenState
    extends State<EnhancedNotificationsScreen> {
  late NotificationPreferences _preferences;
  final NotificationService _notificationService = NotificationService();
  final MealPlanService _mealPlanService = MealPlanService();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasMealPlans = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      // Load existing preferences or create default
      final existingPrefs =
          await _notificationService.loadNotificationPreferences();
      _preferences = existingPrefs ??
          NotificationPreferences(
            workoutSettings: WorkoutNotificationSettings(),
            diarySettings: DiaryNotificationSettings(),
          );

      // Check if user has meal plans
      _hasMealPlans = await _mealPlanService.hasMealPlans();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Save to SharedPreferences
      await _notificationService.saveNotificationPreferences(_preferences);

      // Schedule notifications based on preferences
      await _scheduleNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification preferences saved successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _scheduleNotifications() async {
    // Schedule workout notifications
    if (_preferences.workoutSettings.enabled) {
      await _scheduleWorkoutNotifications();
    }

    // Schedule meal notifications
    if (_preferences.mealSettings.enabled) {
      await _scheduleMealNotifications();
    }
  }

  Future<void> _scheduleWorkoutNotifications() async {
    final userProfileProvider =
        Provider.of<UserProfileProvider>(context, listen: false);
    final workoutPrefs = userProfileProvider.workoutPreferences;

    if (workoutPrefs != null) {
      // Schedule based on user's workout preferences and notification settings
      final settings = _preferences.workoutSettings;

      for (final day in workoutPrefs.availableDays.entries) {
        if (day.value) {
          // If this day is available for workouts
          DateTime scheduledTime;

          if (settings.timingType == NotificationTimingType.specificTime &&
              settings.specificTime != null) {
            // Use specific time
            scheduledTime =
                _getNextOccurrenceOfTime(day.key, settings.specificTime!);
          } else {
            // Use random time within period
            scheduledTime =
                _getRandomTimeInPeriod(day.key, settings.timePeriod);
          }

          // Subtract advance minutes
          scheduledTime = scheduledTime
              .subtract(Duration(minutes: settings.advanceMinutes));

          await _notificationService.scheduleWorkoutReminder(
            title: '🏋️ Workout Reminder',
            body:
                'Time for your ${workoutPrefs.preferredWorkoutTypes.isNotEmpty ? workoutPrefs.preferredWorkoutTypes.first : "workout"} session!',
            scheduledTime: scheduledTime,
            workoutType: workoutPrefs.preferredWorkoutTypes.isNotEmpty
                ? workoutPrefs.preferredWorkoutTypes.first
                : 'general',
          );
        }
      }
    }
  }

  Future<void> _scheduleMealNotifications() async {
    final userProfileProvider =
        Provider.of<UserProfileProvider>(context, listen: false);
    final dietaryPrefs = userProfileProvider.dietaryPreferences;

    if (dietaryPrefs != null) {
      final mealTimes = {
        'breakfast': dietaryPrefs.breakfastTime,
        'lunch': dietaryPrefs.lunchTime,
        'dinner': dietaryPrefs.dinnerTime,
        'snacks': dietaryPrefs.snackTime,
      };

      // Get custom meal names from meal plan if available
      Map<String, String>? customMealNames;
      if (_hasMealPlans) {
        customMealNames = await _mealPlanService.getTodaysMealNames();
      }

      // Use the enhanced notification service
      await _notificationService.schedulePersonalizedMealReminders(
        settings: _preferences.mealSettings,
        mealTimes: mealTimes,
        customMealNames: customMealNames,
      );
    }
  }

  DateTime _getNextOccurrenceOfTime(String day, TimeOfDay time) {
    final now = DateTime.now();
    DateTime scheduled =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);

    if (day != 'today') {
      // Calculate next occurrence of specific day
      final dayIndex = [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday'
      ].indexOf(day);
      final currentDayIndex = now.weekday - 1;
      int daysToAdd = dayIndex - currentDayIndex;
      if (daysToAdd <= 0) daysToAdd += 7;
      scheduled = scheduled.add(Duration(days: daysToAdd));
    } else if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  DateTime _getRandomTimeInPeriod(String day, String period) {
    final periodData = TimePeriods.getPeriod(period);
    if (periodData == null) return DateTime.now().add(const Duration(hours: 1));

    final startHour = periodData['start']!;
    final endHour = periodData['end']!;
    final randomHour =
        startHour + (DateTime.now().millisecond % (endHour - startHour));
    final randomMinute = DateTime.now().microsecond % 60;

    return _getNextOccurrenceOfTime(
        day, TimeOfDay(hour: randomHour, minute: randomMinute));
  }

  String _getMealDisplayName(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      case 'snacks':
        return 'Snack Time';
      default:
        return mealType;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.surfaceColor(context),
        appBar: AppBar(
          backgroundColor: AppTheme.surfaceColor(context),
          elevation: 0,
          title: Text(
            'Notification Settings',
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
        title: Text(
          'Notification Settings',
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.save, color: AppColors.primary),
              onPressed: _savePreferences,
              tooltip: 'Save Settings',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWorkoutNotificationsSection(),
            const SizedBox(height: 24),
            _buildMealNotificationsSection(),
            const SizedBox(height: 24),
            _buildMealPlanIntegrationSection(),
            const SizedBox(height: 24),
            _buildOtherNotificationsSection(),
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutNotificationsSection() {
    return _buildSection(
      title: 'Workout Reminders',
      icon: Icons.fitness_center,
      child: Column(
        children: [
          SwitchListTile(
            title: Text(
              'Enable Workout Reminders',
              style: TextStyle(color: AppTheme.textColor(context)),
            ),
            value: _preferences.workoutSettings.enabled,
            onChanged: (value) {
              setState(() {
                _preferences = _preferences.copyWith(
                  workoutSettings:
                      _preferences.workoutSettings.copyWith(enabled: value),
                );
              });
            },
            activeColor: AppColors.primary,
          ),
          if (_preferences.workoutSettings.enabled) ...[
            const Divider(height: 1),
            _buildTimingTypeSelector(
              title: 'Notification Timing',
              value: _preferences.workoutSettings.timingType,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences.copyWith(
                    workoutSettings: _preferences.workoutSettings
                        .copyWith(timingType: value),
                  );
                });
              },
            ),
            if (_preferences.workoutSettings.timingType ==
                NotificationTimingType.randomPeriod)
              _buildTimePeriodSelector(
                title: 'Preferred Time Period',
                value: _preferences.workoutSettings.timePeriod,
                onChanged: (value) {
                  setState(() {
                    _preferences = _preferences.copyWith(
                      workoutSettings: _preferences.workoutSettings
                          .copyWith(timePeriod: value),
                    );
                  });
                },
              )
            else
              _buildTimePickerTile(
                title: 'Specific Time',
                time: _preferences.workoutSettings.specificTime ??
                    const TimeOfDay(hour: 9, minute: 0),
                onChanged: (time) {
                  setState(() {
                    _preferences = _preferences.copyWith(
                      workoutSettings: _preferences.workoutSettings
                          .copyWith(specificTime: time),
                    );
                  });
                },
              ),
            _buildAdvanceMinutesSelector(
              title: 'Notify Before Workout',
              value: _preferences.workoutSettings.advanceMinutes,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences.copyWith(
                    workoutSettings: _preferences.workoutSettings
                        .copyWith(advanceMinutes: value),
                  );
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMealNotificationsSection() {
    return _buildSection(
      title: 'Meal Reminders',
      icon: Icons.restaurant_menu,
      child: Column(
        children: [
          SwitchListTile(
            title: Text(
              'Enable Meal Reminders',
              style: TextStyle(color: AppTheme.textColor(context)),
            ),
            value: _preferences.mealSettings.enabled,
            onChanged: (value) {
              setState(() {
                _preferences = _preferences.copyWith(
                  mealSettings:
                      _preferences.mealSettings.copyWith(enabled: value),
                );
              });
            },
            activeColor: AppColors.primary,
          ),
          if (_preferences.mealSettings.enabled) ...[
            const Divider(height: 1),
            ..._preferences.mealSettings.mealConfigs.entries.map((entry) {
              return _buildMealConfigTile(entry.key, entry.value);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildMealConfigTile(String mealType, MealNotificationConfig config) {
    return ExpansionTile(
      leading: Icon(_getMealIcon(mealType), color: AppColors.primary),
      title: Text(
        _getMealDisplayName(mealType),
        style: TextStyle(color: AppTheme.textColor(context)),
      ),
      trailing: Switch(
        value: config.enabled,
        onChanged: (value) {
          setState(() {
            final newConfigs = Map<String, MealNotificationConfig>.from(
                _preferences.mealSettings.mealConfigs);
            newConfigs[mealType] = config.copyWith(enabled: value);
            _preferences = _preferences.copyWith(
              mealSettings:
                  _preferences.mealSettings.copyWith(mealConfigs: newConfigs),
            );
          });
        },
        activeColor: AppColors.primary,
      ),
      children: config.enabled
          ? [
              _buildTimingTypeSelector(
                title: 'Timing Type',
                value: config.timingType,
                onChanged: (value) {
                  setState(() {
                    final newConfigs = Map<String, MealNotificationConfig>.from(
                        _preferences.mealSettings.mealConfigs);
                    newConfigs[mealType] = config.copyWith(timingType: value);
                    _preferences = _preferences.copyWith(
                      mealSettings: _preferences.mealSettings
                          .copyWith(mealConfigs: newConfigs),
                    );
                  });
                },
              ),
              if (config.timingType == NotificationTimingType.specificTime)
                _buildTimePickerTile(
                  title: 'Notification Time',
                  time: config.specificTime ??
                      const TimeOfDay(hour: 12, minute: 0),
                  onChanged: (time) {
                    setState(() {
                      final newConfigs =
                          Map<String, MealNotificationConfig>.from(
                              _preferences.mealSettings.mealConfigs);
                      newConfigs[mealType] =
                          config.copyWith(specificTime: time);
                      _preferences = _preferences.copyWith(
                        mealSettings: _preferences.mealSettings
                            .copyWith(mealConfigs: newConfigs),
                      );
                    });
                  },
                ),
              _buildAdvanceMinutesSelector(
                title: 'Notify Before Meal',
                value: config.advanceMinutes,
                onChanged: (value) {
                  setState(() {
                    final newConfigs = Map<String, MealNotificationConfig>.from(
                        _preferences.mealSettings.mealConfigs);
                    newConfigs[mealType] =
                        config.copyWith(advanceMinutes: value);
                    _preferences = _preferences.copyWith(
                      mealSettings: _preferences.mealSettings
                          .copyWith(mealConfigs: newConfigs),
                    );
                  });
                },
              ),
            ]
          : [],
    );
  }

  Widget _buildMealPlanIntegrationSection() {
    return _buildSection(
      title: 'Meal Plan Integration',
      icon: Icons.restaurant_menu,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _hasMealPlans ? Icons.check_circle : Icons.info,
                  color: _hasMealPlans ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _hasMealPlans
                        ? 'Meal plans detected! Notifications will include your custom meal names.'
                        : 'No meal plans found. Notifications will use default meal names.',
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'When you create meal plans in the Health section, your notifications will automatically include the specific meal names you\'ve planned.',
              style: TextStyle(
                color: AppTheme.textColor(context).withValues(alpha: 153),
                fontSize: 12,
              ),
            ),
            if (!_hasMealPlans) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  // Navigate to meal plan screen
                  Navigator.pushNamed(context, '/meal-plan');
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
                child: const Text('Create Meal Plan'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOtherNotificationsSection() {
    return _buildSection(
      title: 'Other Notifications',
      icon: Icons.notifications,
      child: Column(
        children: [
          SwitchListTile(
            title: Text('Water Reminders',
                style: TextStyle(color: AppTheme.textColor(context))),
            subtitle: Text('Stay hydrated throughout the day',
                style: TextStyle(
                    color: AppTheme.textColor(context).withValues(alpha: 153))),
            value: _preferences.waterReminders,
            onChanged: (value) {
              setState(() {
                _preferences = _preferences.copyWith(waterReminders: value);
              });
            },
            activeColor: AppColors.primary,
          ),
          SwitchListTile(
            title: Text('Eco Tips',
                style: TextStyle(color: AppTheme.textColor(context))),
            subtitle: Text('Daily sustainable living tips',
                style: TextStyle(
                    color: AppTheme.textColor(context).withValues(alpha: 153))),
            value: _preferences.ecoTips,
            onChanged: (value) {
              setState(() {
                _preferences = _preferences.copyWith(ecoTips: value);
              });
            },
            activeColor: AppColors.primary,
          ),
          SwitchListTile(
            title: Text('Progress Updates',
                style: TextStyle(color: AppTheme.textColor(context))),
            subtitle: Text('Celebrate your achievements',
                style: TextStyle(
                    color: AppTheme.textColor(context).withValues(alpha: 153))),
            value: _preferences.progressUpdates,
            onChanged: (value) {
              setState(() {
                _preferences = _preferences.copyWith(progressUpdates: value);
              });
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
      {required String title, required IconData icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildTimingTypeSelector({
    required String title,
    required NotificationTimingType value,
    required ValueChanged<NotificationTimingType> onChanged,
  }) {
    return ListTile(
      title: Text(title, style: TextStyle(color: AppTheme.textColor(context))),
      subtitle: DropdownButton<NotificationTimingType>(
        value: value,
        onChanged: (newValue) => onChanged(newValue!),
        dropdownColor: AppTheme.cardColor(context),
        style: TextStyle(color: AppTheme.textColor(context)),
        items: [
          DropdownMenuItem(
            value: NotificationTimingType.randomPeriod,
            child: Text('Random time in period'),
          ),
          DropdownMenuItem(
            value: NotificationTimingType.specificTime,
            child: Text('Specific time'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePeriodSelector({
    required String title,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return ListTile(
      title: Text(title, style: TextStyle(color: AppTheme.textColor(context))),
      subtitle: DropdownButton<String>(
        value: value,
        onChanged: (newValue) => onChanged(newValue!),
        dropdownColor: AppTheme.cardColor(context),
        style: TextStyle(color: AppTheme.textColor(context)),
        items: TimePeriods.allPeriods.map((period) {
          return DropdownMenuItem(
            value: period,
            child: Text(period.toUpperCase()),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimePickerTile({
    required String title,
    required TimeOfDay time,
    required ValueChanged<TimeOfDay> onChanged,
  }) {
    return ListTile(
      title: Text(title, style: TextStyle(color: AppTheme.textColor(context))),
      trailing: TextButton(
        onPressed: () async {
          final newTime = await showTimePicker(
            context: context,
            initialTime: time,
          );
          if (newTime != null) {
            onChanged(newTime);
          }
        },
        child: Text(time.format(context)),
      ),
    );
  }

  Widget _buildAdvanceMinutesSelector({
    required String title,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return ListTile(
      title: Text(title, style: TextStyle(color: AppTheme.textColor(context))),
      subtitle: DropdownButton<int>(
        value: value,
        onChanged: (newValue) => onChanged(newValue!),
        dropdownColor: AppTheme.cardColor(context),
        style: TextStyle(color: AppTheme.textColor(context)),
        items: [5, 10, 15, 30, 45, 60, 90, 120].map((minutes) {
          return DropdownMenuItem(
            value: minutes,
            child: Text('$minutes minutes before'),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _savePreferences,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white),
              )
            : const Text(
                'Save Notification Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  IconData _getMealIcon(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Icons.breakfast_dining;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snacks':
        return Icons.cookie;
      default:
        return Icons.restaurant;
    }
  }
}
