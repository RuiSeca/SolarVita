import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_theme.dart';
import '../../../../models/notification_preferences.dart';
import '../../../../providers/user_profile_provider.dart';
import '../../../../services/notification_service.dart';
import '../../../../services/meal_plan_service.dart';

class ModernNotificationsScreen extends StatefulWidget {
  const ModernNotificationsScreen({super.key});

  @override
  State<ModernNotificationsScreen> createState() =>
      _ModernNotificationsScreenState();
}

class _ModernNotificationsScreenState extends State<ModernNotificationsScreen>
    with TickerProviderStateMixin {
  late NotificationPreferences _preferences;
  final NotificationService _notificationService = NotificationService();
  final MealPlanService _mealPlanService = MealPlanService();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasMealPlans = false;

  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadPreferences();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    try {
      await Future.delayed(
          const Duration(milliseconds: 500)); // Smooth loading animation

      final existingPrefs =
          await _notificationService.loadNotificationPreferences();
      _preferences = existingPrefs ??
          NotificationPreferences(
            workoutSettings: WorkoutNotificationSettings(),
            mealSettings: MealNotificationSettings(),
            diarySettings: DiaryNotificationSettings(),
          );

      _hasMealPlans = await _mealPlanService.hasMealPlans();

      setState(() {
        _isLoading = false;
      });

      _animationController.forward();
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
      await _scheduleAllNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Notification preferences saved successfully'),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Text('Error saving preferences: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _scheduleAllNotifications() async {
    final userProfileProvider =
        Provider.of<UserProfileProvider>(context, listen: false);

    // Schedule workout notifications
    if (_preferences.workoutSettings.enabled) {
      final workoutPrefs = userProfileProvider.workoutPreferences;
      if (workoutPrefs != null) {
        await _notificationService.schedulePersonalizedWorkoutReminder(
          settings: _preferences.workoutSettings,
          availableDays: workoutPrefs.availableDays,
          workoutTypes: workoutPrefs.preferredWorkoutTypes,
          preferredTime: workoutPrefs.preferredTime,
        );
      }
    }

    // Schedule meal notifications
    if (_preferences.mealSettings.enabled) {
      final dietaryPrefs = userProfileProvider.dietaryPreferences;
      if (dietaryPrefs != null) {
        final mealTimes = {
          'breakfast': dietaryPrefs.breakfastTime,
          'lunch': dietaryPrefs.lunchTime,
          'dinner': dietaryPrefs.dinnerTime,
          'snacks': dietaryPrefs.snackTime,
        };

        Map<String, String>? customMealNames;
        if (_hasMealPlans) {
          customMealNames = await _mealPlanService.getTodaysMealNames();
        }

        await _notificationService.schedulePersonalizedMealReminders(
          settings: _preferences.mealSettings,
          mealTimes: mealTimes,
          customMealNames: customMealNames,
        );
      }
    }

    // Schedule diary notifications
    if (_preferences.diarySettings.enabled) {
      await _notificationService.schedulePersonalizedDiaryReminders(
        settings: _preferences.diarySettings,
      );
    }
  }

  DateTime _getNextOccurrenceOfTime(String day, TimeOfDay time) {
    final now = DateTime.now();
    DateTime scheduled =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);

    if (scheduled.isBefore(now)) {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.surfaceColor(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Setting up your notifications...',
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: _buildModernAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildWorkoutTab(),
                  _buildMealTab(),
                  _buildDiaryTab(),
                  _buildGeneralTab(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildSaveFAB(),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surfaceColor(context),
      elevation: 0,
      centerTitle: true,
      title: Column(
        children: [
          Text(
            'Notifications',
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Personalized reminders for your wellness journey',
            style: TextStyle(
              color: AppTheme.textColor(context).withValues(alpha: 153),
              fontSize: 12,
            ),
          ),
        ],
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.arrow_back,
              color: AppTheme.textColor(context), size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textColor(context).withValues(alpha: 26),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor:
            AppTheme.textColor(context).withValues(alpha: 153),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fitness_center, size: 16),
                const SizedBox(width: 4),
                Text('Workouts'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.restaurant_menu, size: 16),
                const SizedBox(width: 4),
                Text('Meals'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.book, size: 16),
                const SizedBox(width: 4),
                Text('Diary'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.more_horiz, size: 16),
                const SizedBox(width: 4),
                Text('Other'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildModernCard(
            title: 'Workout Reminders',
            subtitle: 'Stay motivated with personalized workout notifications',
            icon: Icons.fitness_center,
            iconColor: Colors.orange,
            child: _buildWorkoutSettings(),
          ),
        ],
      ),
    );
  }

  Widget _buildMealTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildModernCard(
            title: 'Meal Reminders',
            subtitle: 'Never miss a meal with smart notifications',
            icon: Icons.restaurant_menu,
            iconColor: Colors.green,
            child: _buildMealSettings(),
          ),
          const SizedBox(height: 16),
          _buildMealPlanIntegrationCard(),
        ],
      ),
    );
  }

  Widget _buildDiaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildModernCard(
            title: 'Diary Reminders',
            subtitle: 'Reflect on your day with gentle reminders',
            icon: Icons.book,
            iconColor: Colors.purple,
            child: _buildDiarySettings(),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildModernCard(
            title: 'General Notifications',
            subtitle: 'Stay updated with your wellness journey',
            icon: Icons.notifications_active,
            iconColor: Colors.blue,
            child: _buildGeneralSettings(),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.textColor(context).withValues(alpha: 26),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textColor(context).withValues(alpha: 13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
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
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppTheme.textColor(context)
                              .withValues(alpha: 153),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: AppTheme.textColor(context).withValues(alpha: 26),
            height: 1,
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildWorkoutSettings() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildModernSwitch(
            title: 'Enable Workout Reminders',
            subtitle: 'Get notified about your workout schedule',
            value: _preferences.workoutSettings.enabled,
            onChanged: (value) {
              setState(() {
                _preferences = _preferences.copyWith(
                  workoutSettings:
                      _preferences.workoutSettings.copyWith(enabled: value),
                );
              });
            },
          ),
          if (_preferences.workoutSettings.enabled) ...[
            const SizedBox(height: 20),
            _buildTimingSelector(
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
            const SizedBox(height: 16),
            if (_preferences.workoutSettings.timingType ==
                NotificationTimingType.randomPeriod)
              _buildPeriodSelector(
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
              _buildTimeSelector(
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
            const SizedBox(height: 16),
            _buildAdvanceSelector(
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

  Widget _buildMealSettings() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildModernSwitch(
            title: 'Enable Meal Reminders',
            subtitle: 'Get notified about your meal times',
            value: _preferences.mealSettings.enabled,
            onChanged: (value) {
              setState(() {
                _preferences = _preferences.copyWith(
                  mealSettings:
                      _preferences.mealSettings.copyWith(enabled: value),
                );
              });
            },
          ),
          if (_preferences.mealSettings.enabled) ...[
            const SizedBox(height: 20),
            ..._preferences.mealSettings.mealConfigs.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildMealConfigTile(entry.key, entry.value),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildDiarySettings() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildModernSwitch(
            title: 'Enable Diary Reminders',
            subtitle: 'Get reminded to reflect on your day',
            value: _preferences.diarySettings.enabled,
            onChanged: (value) {
              setState(() {
                _preferences = _preferences.copyWith(
                  diarySettings:
                      _preferences.diarySettings.copyWith(enabled: value),
                );
              });
            },
          ),
          if (_preferences.diarySettings.enabled) ...[
            const SizedBox(height: 20),
            _buildTimingSelector(
              title: 'Notification Timing',
              value: _preferences.diarySettings.timingType,
              onChanged: (value) {
                setState(() {
                  _preferences = _preferences.copyWith(
                    diarySettings:
                        _preferences.diarySettings.copyWith(timingType: value),
                  );
                });
              },
            ),
            const SizedBox(height: 16),
            if (_preferences.diarySettings.timingType ==
                NotificationTimingType.randomPeriod)
              _buildPeriodSelector(
                title: 'Preferred Time Period',
                value: _preferences.diarySettings.timePeriod,
                periods: [
                  'evening',
                  'night'
                ], // Only evening and night for diary
                onChanged: (value) {
                  setState(() {
                    _preferences = _preferences.copyWith(
                      diarySettings: _preferences.diarySettings
                          .copyWith(timePeriod: value),
                    );
                  });
                },
              )
            else
              _buildTimeSelector(
                title: 'Specific Time',
                time: _preferences.diarySettings.specificTime ??
                    const TimeOfDay(hour: 20, minute: 0),
                onChanged: (time) {
                  setState(() {
                    _preferences = _preferences.copyWith(
                      diarySettings: _preferences.diarySettings
                          .copyWith(specificTime: time),
                    );
                  });
                },
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildModernSwitch(
            title: 'Water Reminders',
            subtitle: 'Stay hydrated throughout the day',
            value: _preferences.waterReminders,
            onChanged: (value) {
              setState(() {
                _preferences = _preferences.copyWith(waterReminders: value);
              });
            },
          ),
          const SizedBox(height: 16),
          _buildModernSwitch(
            title: 'Eco Tips',
            subtitle: 'Daily sustainable living tips',
            value: _preferences.ecoTips,
            onChanged: (value) {
              setState(() {
                _preferences = _preferences.copyWith(ecoTips: value);
              });
            },
          ),
          const SizedBox(height: 16),
          _buildModernSwitch(
            title: 'Progress Updates',
            subtitle: 'Celebrate your achievements',
            value: _preferences.progressUpdates,
            onChanged: (value) {
              setState(() {
                _preferences = _preferences.copyWith(progressUpdates: value);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMealPlanIntegrationCard() {
    return Container(
      decoration: BoxDecoration(
        color: _hasMealPlans
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _hasMealPlans
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _hasMealPlans ? Icons.check_circle : Icons.info,
                color: _hasMealPlans ? Colors.green : Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Meal Plan Integration',
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _hasMealPlans
                ? 'Great! Your meal plans are connected. Notifications will include your custom meal names.'
                : 'No meal plans found. Create meal plans to get personalized meal notifications.',
            style: TextStyle(
              color: AppTheme.textColor(context).withValues(alpha: 179),
              fontSize: 14,
            ),
          ),
          if (!_hasMealPlans) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/meal-plan');
                },
                icon: Icon(Icons.add, size: 20),
                label: Text('Create Meal Plan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMealConfigTile(String mealType, MealNotificationConfig config) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.textFieldBackground(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getMealColor(mealType).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_getMealIcon(mealType),
              color: _getMealColor(mealType), size: 20),
        ),
        title: Text(
          _getMealDisplayName(mealType),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.w600,
          ),
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
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTimingSelector(
                        title: 'Timing Type',
                        value: config.timingType,
                        onChanged: (value) {
                          setState(() {
                            final newConfigs =
                                Map<String, MealNotificationConfig>.from(
                                    _preferences.mealSettings.mealConfigs);
                            newConfigs[mealType] =
                                config.copyWith(timingType: value);
                            _preferences = _preferences.copyWith(
                              mealSettings: _preferences.mealSettings
                                  .copyWith(mealConfigs: newConfigs),
                            );
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      if (config.timingType ==
                          NotificationTimingType.specificTime)
                        _buildTimeSelector(
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
                      const SizedBox(height: 16),
                      _buildAdvanceSelector(
                        title: 'Notify Before Meal',
                        value: config.advanceMinutes,
                        onChanged: (value) {
                          setState(() {
                            final newConfigs =
                                Map<String, MealNotificationConfig>.from(
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
                    ],
                  ),
                ),
              ]
            : [],
      ),
    );
  }

  Widget _buildModernSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppTheme.textColor(context).withValues(alpha: 153),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Transform.scale(
          scale: 1.1,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _buildTimingSelector({
    required String title,
    required NotificationTimingType value,
    required ValueChanged<NotificationTimingType> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.textFieldBackground(context),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButton<NotificationTimingType>(
            value: value,
            onChanged: (newValue) => onChanged(newValue!),
            dropdownColor: AppTheme.cardColor(context),
            style: TextStyle(color: AppTheme.textColor(context)),
            underline: const SizedBox(),
            isExpanded: true,
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
        ),
      ],
    );
  }

  Widget _buildPeriodSelector({
    required String title,
    required String value,
    required ValueChanged<String> onChanged,
    List<String>? periods,
  }) {
    final availablePeriods = periods ?? TimePeriods.allPeriods;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.textFieldBackground(context),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButton<String>(
            value: value,
            onChanged: (newValue) => onChanged(newValue!),
            dropdownColor: AppTheme.cardColor(context),
            style: TextStyle(color: AppTheme.textColor(context)),
            underline: const SizedBox(),
            isExpanded: true,
            items: availablePeriods.map((period) {
              return DropdownMenuItem(
                value: period,
                child: Text(period.toUpperCase()),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector({
    required String title,
    required TimeOfDay time,
    required ValueChanged<TimeOfDay> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final newTime = await showTimePicker(
              context: context,
              initialTime: time,
            );
            if (newTime != null) {
              onChanged(newTime);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.textFieldBackground(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Text(
                  time.format(context),
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvanceSelector({
    required String title,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.textFieldBackground(context),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButton<int>(
            value: value,
            onChanged: (newValue) => onChanged(newValue!),
            dropdownColor: AppTheme.cardColor(context),
            style: TextStyle(color: AppTheme.textColor(context)),
            underline: const SizedBox(),
            isExpanded: true,
            items: [0, 5, 10, 15, 30, 45, 60, 90, 120].map((minutes) {
              return DropdownMenuItem(
                value: minutes,
                child: Text(
                    minutes == 0 ? 'At the time' : '$minutes minutes before'),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveFAB() {
    return Container(
      width: 140,
      height: 56,
      child: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _savePreferences,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        icon: _isSaving
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(Icons.save, size: 20),
        label: Text(
          _isSaving ? 'Saving...' : 'Save',
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

  Color _getMealColor(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.purple;
      case 'snacks':
        return Colors.blue;
      default:
        return AppColors.primary;
    }
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
        return 'Snacks';
      default:
        return mealType;
    }
  }
}
