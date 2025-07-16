import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_theme.dart';
import '../../../../models/notification_preferences.dart';
import '../../../../providers/riverpod/user_profile_provider.dart';
import '../../../../services/notification_service.dart';
import '../../../../services/meal_plan_service.dart';
import '../../../../widgets/common/lottie_loading_widget.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
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
      await _notificationService.initialize();
      
      // Load existing preferences or create default
      final existingPrefs = await _notificationService.loadNotificationPreferences();
      _preferences = existingPrefs ?? NotificationPreferences(
        workoutSettings: WorkoutNotificationSettings(),
        mealSettings: MealNotificationSettings(),
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
      await _notificationService.saveNotificationPreferences(_preferences);
      await _scheduleNotifications();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
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
    if (_preferences.workoutSettings.enabled) {
      await _scheduleWorkoutNotifications();
    }
    if (_preferences.mealSettings.enabled) {
      await _scheduleMealNotifications();
    }
  }

  Future<void> _scheduleWorkoutNotifications() async {
    final userProfileProvider = ref.read(userProfileNotifierProvider);
    final workoutPrefs = userProfileProvider.value?.workoutPreferences;
    
    if (workoutPrefs != null) {
      final settings = _preferences.workoutSettings;
      
      for (final day in workoutPrefs.availableDays.entries) {
        if (day.value) {
          DateTime scheduledTime;
          
          if (settings.timingType == NotificationTimingType.specificTime && settings.specificTime != null) {
            scheduledTime = _getNextOccurrenceOfTime(day.key, settings.specificTime!);
          } else {
            scheduledTime = _getRandomTimeInPeriod(day.key, settings.timePeriod);
          }
          
          scheduledTime = scheduledTime.subtract(Duration(minutes: settings.advanceMinutes));
          
          await _notificationService.scheduleWorkoutReminder(
            title: '🏋️ Workout Reminder',
            body: 'Time for your ${workoutPrefs.preferredWorkoutTypes.isNotEmpty ? workoutPrefs.preferredWorkoutTypes.first : "workout"} session!',
            scheduledTime: scheduledTime,
            workoutType: workoutPrefs.preferredWorkoutTypes.isNotEmpty ? workoutPrefs.preferredWorkoutTypes.first : 'general',
          );
        }
      }
    }
  }

  Future<void> _scheduleMealNotifications() async {
    final userProfileProvider = ref.read(userProfileNotifierProvider);
    final dietaryPrefs = userProfileProvider.value?.dietaryPreferences;
    
    for (final meal in _preferences.mealSettings.mealConfigs.entries) {
      if (meal.value.enabled) {
        DateTime scheduledDateTime;
        
        if (meal.value.timingType == NotificationTimingType.specificTime && meal.value.specificTime != null) {
          // Use specific time set in meal config
          scheduledDateTime = _getNextOccurrenceOfTime('today', meal.value.specificTime!);
        } else if (dietaryPrefs != null) {
          // Use meal plan time
          final mealTimes = {
            'breakfast': dietaryPrefs.breakfastTime,
            'lunch': dietaryPrefs.lunchTime,
            'dinner': dietaryPrefs.dinnerTime,
            'snacks': dietaryPrefs.snackTime,
          };
          
          if (mealTimes[meal.key] != null) {
            final timeOfDay = _parseTimeOfDay(mealTimes[meal.key]!);
            scheduledDateTime = _getNextOccurrenceOfTime('today', timeOfDay);
          } else {
            // Fallback to default meal time
            scheduledDateTime = _getNextOccurrenceOfTime('today', _getDefaultMealTime(meal.key));
          }
        } else {
          // No meal plan, use default time
          scheduledDateTime = _getNextOccurrenceOfTime('today', _getDefaultMealTime(meal.key));
        }
        
        // Apply advance notice
        scheduledDateTime = scheduledDateTime.subtract(Duration(minutes: meal.value.advanceMinutes));
        
        await _notificationService.scheduleMealReminder(
          mealType: meal.key,
          scheduledTime: scheduledDateTime,
          customMessage: meal.value.customMealName,
        );
      }
    }
  }

  TimeOfDay _parseTimeOfDay(String timeString) {
    try {
      final parts = timeString.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return const TimeOfDay(hour: 12, minute: 0); // Default to noon
    }
  }

  DateTime _getNextOccurrenceOfTime(String dayName, TimeOfDay time) {
    final now = DateTime.now();
    
    if (dayName.toLowerCase() == 'today') {
      // For meal times, use today or tomorrow if time has passed
      final targetTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      if (targetTime.isBefore(now)) {
        return targetTime.add(const Duration(days: 1));
      }
      return targetTime;
    }
    
    final weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final targetDay = weekdays.indexOf(dayName.toLowerCase());
    
    if (targetDay == -1) return now;
    
    final today = now.weekday - 1;
    int daysUntilTarget = (targetDay - today) % 7;
    if (daysUntilTarget == 0 && TimeOfDay.now().hour * 60 + TimeOfDay.now().minute >= time.hour * 60 + time.minute) {
      daysUntilTarget = 7;
    }
    
    final targetDate = now.add(Duration(days: daysUntilTarget));
    return DateTime(targetDate.year, targetDate.month, targetDate.day, time.hour, time.minute);
  }

  DateTime _getRandomTimeInPeriod(String dayName, String period) {
    final baseTime = _getNextOccurrenceOfTime(dayName, const TimeOfDay(hour: 6, minute: 0));
    
    switch (period) {
      case 'morning':
        return baseTime.add(Duration(minutes: (6 * 60) + (DateTime.now().millisecond % (4 * 60))));
      case 'afternoon':
        return baseTime.add(Duration(minutes: (12 * 60) + (DateTime.now().millisecond % (6 * 60))));
      case 'evening':
        return baseTime.add(Duration(minutes: (18 * 60) + (DateTime.now().millisecond % (4 * 60))));
      case 'night':
        return baseTime.add(Duration(minutes: (20 * 60) + (DateTime.now().millisecond % (2 * 60))));
      default:
        return baseTime.add(Duration(minutes: (9 * 60))); // Default to 9 AM
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
            'Notifications',
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
        body: const Center(child: LottieLoadingWidget()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
        title: Text(
          'Notifications',
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
                child: LottieLoadingWidget(width: 20, height: 20),
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
            _buildWorkoutSection(),
            const SizedBox(height: 16),
            _buildMealSection(),
            const SizedBox(height: 16),
            _buildOtherNotificationsSection(),
            const SizedBox(height: 16),
            _buildTestSection(),
            const SizedBox(height: 16),
            _buildHelpSection(),
            const SizedBox(height: 24),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor(context),
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

  Widget _buildWorkoutSection() {
    return _buildSection(
      title: 'Workout Reminders',
      icon: Icons.fitness_center,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    workoutSettings: _preferences.workoutSettings.copyWith(enabled: value),
                  );
                });
              },
            ),
            if (_preferences.workoutSettings.enabled) ...[
              const Divider(),
              // Timing options
              ListTile(
                title: Text(
                  'Timing Type',
                  style: TextStyle(color: AppTheme.textColor(context)),
                ),
                subtitle: DropdownButton<NotificationTimingType>(
                  value: _preferences.workoutSettings.timingType,
                  items: NotificationTimingType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type == NotificationTimingType.specificTime 
                        ? 'Specific Time' 
                        : 'Random Time'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _preferences = _preferences.copyWith(
                          workoutSettings: _preferences.workoutSettings.copyWith(timingType: value),
                        );
                      });
                    }
                  },
                ),
              ),
              if (_preferences.workoutSettings.timingType == NotificationTimingType.specificTime)
                ListTile(
                  title: Text(
                    'Specific Time',
                    style: TextStyle(color: AppTheme.textColor(context)),
                  ),
                  subtitle: Text(
                    _preferences.workoutSettings.specificTime?.format(context) ?? 'Not set',
                  ),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _preferences.workoutSettings.specificTime ?? const TimeOfDay(hour: 9, minute: 0),
                    );
                    if (time != null) {
                      setState(() {
                        _preferences = _preferences.copyWith(
                          workoutSettings: _preferences.workoutSettings.copyWith(specificTime: time),
                        );
                      });
                    }
                  },
                )
              else
                ListTile(
                  title: Text(
                    'Time Period',
                    style: TextStyle(color: AppTheme.textColor(context)),
                  ),
                  subtitle: DropdownButton<String>(
                    value: _preferences.workoutSettings.timePeriod,
                    items: TimePeriods.allPeriods.map((period) {
                      return DropdownMenuItem(
                        value: period,
                        child: Text(period.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _preferences = _preferences.copyWith(
                            workoutSettings: _preferences.workoutSettings.copyWith(timePeriod: value),
                          );
                        });
                      }
                    },
                  ),
                ),
              ListTile(
                title: Text(
                  'Advance Notice (minutes)',
                  style: TextStyle(color: AppTheme.textColor(context)),
                ),
                subtitle: Slider(
                  value: _preferences.workoutSettings.advanceMinutes.toDouble(),
                  min: 0,
                  max: 120,
                  divisions: 24,
                  label: '${_preferences.workoutSettings.advanceMinutes} min',
                  onChanged: (value) {
                    setState(() {
                      _preferences = _preferences.copyWith(
                        workoutSettings: _preferences.workoutSettings.copyWith(advanceMinutes: value.round()),
                      );
                    });
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMealSection() {
    return _buildSection(
      title: 'Meal Reminders',
      icon: Icons.restaurant,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    mealSettings: _preferences.mealSettings.copyWith(enabled: value),
                  );
                });
              },
            ),
            if (_preferences.mealSettings.enabled) ...[
              const Divider(),
              ..._preferences.mealSettings.mealConfigs.entries.map((meal) {
                return _buildMealConfigTile(meal.key, meal.value);
              }),
              if (_hasMealPlans) ...[
                const Divider(),
                ListTile(
                  title: Text(
                    'Meal Plan Integration',
                    style: TextStyle(color: AppTheme.textColor(context)),
                  ),
                  subtitle: const Text('Notifications will use your meal plan names'),
                  trailing: Icon(Icons.check_circle, color: AppColors.primary),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMealConfigTile(String mealType, MealNotificationConfig config) {
    return ExpansionTile(
      title: Text(
        mealType.toUpperCase(),
        style: TextStyle(
          color: AppTheme.textColor(context),
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        config.enabled ? 'Enabled' : 'Disabled',
        style: TextStyle(
          color: config.enabled ? AppColors.primary : Colors.grey,
        ),
      ),
      trailing: Switch(
        value: config.enabled,
        onChanged: (value) {
          setState(() {
            final updatedConfigs = Map<String, MealNotificationConfig>.from(_preferences.mealSettings.mealConfigs);
            updatedConfigs[mealType] = config.copyWith(enabled: value);
            _preferences = _preferences.copyWith(
              mealSettings: _preferences.mealSettings.copyWith(mealConfigs: updatedConfigs),
            );
          });
        },
      ),
      children: config.enabled ? [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // Timing Type
              ListTile(
                title: Text(
                  'Timing Type',
                  style: TextStyle(color: AppTheme.textColor(context)),
                ),
                subtitle: DropdownButton<NotificationTimingType>(
                  value: config.timingType,
                  items: NotificationTimingType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type == NotificationTimingType.specificTime 
                        ? 'Specific Time' 
                        : 'Use Meal Plan Time'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        final updatedConfigs = Map<String, MealNotificationConfig>.from(_preferences.mealSettings.mealConfigs);
                        updatedConfigs[mealType] = config.copyWith(timingType: value);
                        _preferences = _preferences.copyWith(
                          mealSettings: _preferences.mealSettings.copyWith(mealConfigs: updatedConfigs),
                        );
                      });
                    }
                  },
                ),
              ),
              // Specific Time (if selected)
              if (config.timingType == NotificationTimingType.specificTime)
                ListTile(
                  title: Text(
                    'Specific Time',
                    style: TextStyle(color: AppTheme.textColor(context)),
                  ),
                  subtitle: Text(
                    config.specificTime?.format(context) ?? 'Not set',
                  ),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: config.specificTime ?? _getDefaultMealTime(mealType),
                    );
                    if (time != null) {
                      setState(() {
                        final updatedConfigs = Map<String, MealNotificationConfig>.from(_preferences.mealSettings.mealConfigs);
                        updatedConfigs[mealType] = config.copyWith(specificTime: time);
                        _preferences = _preferences.copyWith(
                          mealSettings: _preferences.mealSettings.copyWith(mealConfigs: updatedConfigs),
                        );
                      });
                    }
                  },
                ),
              // Advance Notice
              ListTile(
                title: Text(
                  'Advance Notice (minutes)',
                  style: TextStyle(color: AppTheme.textColor(context)),
                ),
                subtitle: Slider(
                  value: config.advanceMinutes.toDouble(),
                  min: 0,
                  max: 60,
                  divisions: 12,
                  label: '${config.advanceMinutes} min',
                  onChanged: (value) {
                    setState(() {
                      final updatedConfigs = Map<String, MealNotificationConfig>.from(_preferences.mealSettings.mealConfigs);
                      updatedConfigs[mealType] = config.copyWith(advanceMinutes: value.round());
                      _preferences = _preferences.copyWith(
                        mealSettings: _preferences.mealSettings.copyWith(mealConfigs: updatedConfigs),
                      );
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ] : [],
    );
  }

  TimeOfDay _getDefaultMealTime(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return const TimeOfDay(hour: 8, minute: 0);
      case 'lunch':
        return const TimeOfDay(hour: 12, minute: 30);
      case 'dinner':
        return const TimeOfDay(hour: 19, minute: 0);
      case 'snacks':
        return const TimeOfDay(hour: 15, minute: 30);
      default:
        return const TimeOfDay(hour: 12, minute: 0);
    }
  }

  Widget _buildOtherNotificationsSection() {
    return _buildSection(
      title: 'Other Notifications',
      icon: Icons.notifications,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: Text(
                'Eco Tips',
                style: TextStyle(color: AppTheme.textColor(context)),
              ),
              value: _preferences.ecoTips,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences.copyWith(ecoTips: value);
                });
              },
            ),
            SwitchListTile(
              title: Text(
                'Progress Updates',
                style: TextStyle(color: AppTheme.textColor(context)),
              ),
              value: _preferences.progressUpdates,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences.copyWith(progressUpdates: value);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection() {
    return _buildSection(
      title: 'Notification Status',
      icon: Icons.notifications_active,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Notification settings have been configured. Your personalized reminders will appear based on your preferences above.',
          style: TextStyle(
            color: AppTheme.textColor(context).withValues(alpha: 0.7),
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildHelpSection() {
    return _buildSection(
      title: 'Troubleshooting',
      icon: Icons.help_outline,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'If scheduled notifications don\'t work:',
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildHelpItem('1. Check notification permissions in Android settings'),
            _buildHelpItem('2. Allow "Alarms & reminders" permission for this app'),
            _buildHelpItem('3. Disable battery optimization for SolarVita'),
            _buildHelpItem('4. Make sure "Do Not Disturb" is not blocking notifications'),
            const SizedBox(height: 12),
            Text(
              'Meal Timing Options:',
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildHelpItem('• Specific Time: Set exact time for each meal'),
            _buildHelpItem('• Use Meal Plan Time: Follow your dietary preferences'),
            _buildHelpItem('• Advance Notice: Get notified before meal time'),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          color: AppTheme.textColor(context).withValues(alpha: 0.8),
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _savePreferences,
        icon: _isSaving 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: LottieLoadingWidget(width: 20, height: 20),
            )
          : const Icon(Icons.save),
        label: Text(_isSaving ? 'Saving...' : 'Save Settings'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}