// lib/screens/profile/settings/preferences/workout_preferences_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/translation_helper.dart';
import '../account/notifications_screen.dart';
import '../../../../services/notification_service.dart'; // ADD THIS LINE

class WorkoutPreferencesScreen extends StatefulWidget {
  const WorkoutPreferencesScreen({super.key});

  @override
  State<WorkoutPreferencesScreen> createState() =>
      _WorkoutPreferencesScreenState();
}

class _WorkoutPreferencesScreenState extends State<WorkoutPreferencesScreen> {
  final NotificationService _notificationService =
      NotificationService(); // ADD THIS LINE

  // Preference keys
  static const String _workoutDurationKey = 'workout_duration';
  static const String _preferredTimeKey = 'preferred_workout_time';
  static const String _fitnessGoalKey = 'fitness_goal';
  static const String _workoutLocationKey = 'workout_location';
  static const String _equipmentKey = 'available_equipment';
  static const String _workoutTypesKey = 'preferred_workout_types';
  static const String _restDaysKey = 'rest_days_per_week';
  static const String _ecoOptionsKey = 'eco_options_enabled';
  static const String _intensityKey = 'preferred_intensity';
  static const String _experienceLevelKey = 'experience_level';

  // Current values
  int _workoutDuration = 45;
  String _preferredTime = 'morning';
  String _fitnessGoal = 'general_fitness';
  String _workoutLocation = 'flexible';
  Set<String> _availableEquipment = {'body_weight'};
  Set<String> _preferredWorkoutTypes = {'strength', 'cardio'};
  int _restDaysPerWeek = 2;
  bool _ecoOptionsEnabled = false;
  String _preferredIntensity = 'moderate';
  String _experienceLevel = 'intermediate';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _workoutDuration = prefs.getInt(_workoutDurationKey) ?? 45;
      _preferredTime = prefs.getString(_preferredTimeKey) ?? 'morning';
      _fitnessGoal = prefs.getString(_fitnessGoalKey) ?? 'general_fitness';
      _workoutLocation = prefs.getString(_workoutLocationKey) ?? 'flexible';
      _availableEquipment =
          (prefs.getStringList(_equipmentKey) ?? ['body_weight']).toSet();
      _preferredWorkoutTypes =
          (prefs.getStringList(_workoutTypesKey) ?? ['strength', 'cardio'])
              .toSet();
      _restDaysPerWeek = prefs.getInt(_restDaysKey) ?? 2;
      _ecoOptionsEnabled = prefs.getBool(_ecoOptionsKey) ?? false;
      _preferredIntensity = prefs.getString(_intensityKey) ?? 'moderate';
      _experienceLevel = prefs.getString(_experienceLevelKey) ?? 'intermediate';
    });
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();

    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is List<String>) {
      await prefs.setStringList(key, value);
    }

    // Reschedule workout notifications when preferences change
    if (key == _preferredTimeKey || key == _restDaysKey) {
      await _scheduleWorkoutNotifications();
    }
  }

  Future<void> _scheduleWorkoutNotifications() async {
    if (await _notificationService.workoutRemindersEnabled) {
      final now = DateTime.now();

      // Calculate workout days based on rest days
      final workoutDaysPerWeek = 7 - _restDaysPerWeek;

      // Schedule workout reminders for the next 7 days
      for (int i = 1; i <= 7; i++) {
        final futureDate = now.add(Duration(days: i));

        // Skip weekends or adjust based on your workout schedule logic
        if (i <= workoutDaysPerWeek) {
          final workoutTime = _getWorkoutTimeForDate(futureDate);

          await _notificationService.scheduleWorkoutReminder(
            title: '🏋️ Workout Reminder',
            body:
                'Time for your ${_getDurationText()} ${_getIntensityText()} workout!',
            scheduledTime: workoutTime,
            workoutType: _preferredWorkoutTypes.isNotEmpty
                ? _preferredWorkoutTypes.first
                : 'general',
          );
        }
      }
    }
  }

  DateTime _getWorkoutTimeForDate(DateTime date) {
    // Convert preferred time to actual time
    int hour;
    switch (_preferredTime) {
      case 'early_morning':
        hour = 6;
        break;
      case 'morning':
        hour = 8;
        break;
      case 'late_morning':
        hour = 10;
        break;
      case 'afternoon':
        hour = 14;
        break;
      case 'evening':
        hour = 18;
        break;
      case 'night':
        hour = 20;
        break;
      default:
        hour = 9; // Default morning time
    }

    return DateTime(date.year, date.month, date.day, hour, 0);
  }

  String _getDurationText() {
    if (_workoutDuration <= 30) return 'quick';
    if (_workoutDuration <= 60) return 'standard';
    return 'extended';
  }

  String _getIntensityText() {
    return _preferredIntensity;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
        title: Text(
          tr(context, 'workout_preferences'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWorkoutBasicsSection(),
            const SizedBox(height: 24),
            _buildFitnessGoalsSection(),
            const SizedBox(height: 24),
            _buildLocationAndEquipmentSection(),
            const SizedBox(height: 24),
            _buildWorkoutTypesSection(),
            const SizedBox(height: 24),
            _buildScheduleSection(),
            const SizedBox(height: 24),
            _buildAdvancedOptionsSection(),
            const SizedBox(height: 24),
            _buildNotificationNavigationSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    IconData? icon,
    Color? iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor ?? AppColors.primary, size: 24),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.textColor(context).withAlpha(26),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildWorkoutBasicsSection() {
    return _buildSection(
      title: tr(context, 'workout_basics'),
      icon: Icons.fitness_center,
      children: [
        _buildDurationSlider(),
        _buildDivider(),
        _buildPreferredTimeDropdown(),
        _buildDivider(),
        _buildIntensityDropdown(),
        _buildDivider(),
        _buildExperienceLevelDropdown(),
      ],
    );
  }

  Widget _buildFitnessGoalsSection() {
    return _buildSection(
      title: tr(context, 'fitness_goals'),
      icon: Icons.emoji_events,
      iconColor: AppColors.gold,
      children: [
        _buildFitnessGoalDropdown(),
      ],
    );
  }

  Widget _buildLocationAndEquipmentSection() {
    return _buildSection(
      title: tr(context, 'location_equipment'),
      icon: Icons.location_on,
      children: [
        _buildWorkoutLocationDropdown(),
        _buildDivider(),
        _buildEquipmentSelection(),
      ],
    );
  }

  Widget _buildWorkoutTypesSection() {
    return _buildSection(
      title: tr(context, 'workout_types'),
      icon: Icons.sports,
      iconColor: Colors.orange,
      children: [
        _buildWorkoutTypesSelection(),
      ],
    );
  }

  Widget _buildScheduleSection() {
    return _buildSection(
      title: tr(context, 'schedule_preferences'),
      icon: Icons.schedule,
      iconColor: Colors.blue,
      children: [
        _buildRestDaysSlider(),
      ],
    );
  }

  Widget _buildAdvancedOptionsSection() {
    return _buildSection(
      title: tr(context, 'advanced_options'),
      icon: Icons.tune,
      iconColor: Colors.purple,
      children: [
        _buildEcoOptionsSwitch(),
      ],
    );
  }

  Widget _buildNotificationNavigationSection() {
    return _buildSection(
      title: tr(context, 'notifications'),
      icon: Icons.notifications,
      iconColor: Colors.red,
      children: [
        _buildNavigationTile(
          title: tr(context, 'manage_notifications'),
          subtitle: tr(context, 'notification_settings_description'),
          icon: Icons.notifications_active,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotificationsScreen(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSlider() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr(context, 'workout_duration'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$_workoutDuration ${tr(context, 'minutes')}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withAlpha(77),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withAlpha(51),
            ),
            child: Slider(
              value: _workoutDuration.toDouble(),
              min: 15,
              max: 180,
              divisions: 33,
              onChanged: (value) {
                setState(() {
                  _workoutDuration = value.round();
                });
                _savePreference(_workoutDurationKey, _workoutDuration);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '15 ${tr(context, 'min')}',
                style: TextStyle(
                  color: AppTheme.textColor(context).withAlpha(179),
                  fontSize: 12,
                ),
              ),
              Text(
                '3 ${tr(context, 'hours')}',
                style: TextStyle(
                  color: AppTheme.textColor(context).withAlpha(179),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreferredTimeDropdown() {
    final timeOptions = [
      'early_morning',
      'morning',
      'late_morning',
      'afternoon',
      'evening',
      'night',
      'flexible'
    ];

    return _buildDropdownTile(
      title: tr(context, 'preferred_workout_time'),
      value: _preferredTime,
      options: timeOptions
          .map((time) => DropdownMenuItem(
                value: time,
                child: Row(
                  children: [
                    Icon(_getTimeIcon(time),
                        size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(tr(context, time)),
                  ],
                ),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _preferredTime = value!;
        });
        _savePreference(_preferredTimeKey, _preferredTime);
      },
    );
  }

  Widget _buildIntensityDropdown() {
    final intensityOptions = ['light', 'moderate', 'vigorous', 'extreme'];

    return _buildDropdownTile(
      title: tr(context, 'preferred_intensity'),
      value: _preferredIntensity,
      options: intensityOptions
          .map((intensity) => DropdownMenuItem(
                value: intensity,
                child: Row(
                  children: [
                    Icon(_getIntensityIcon(intensity),
                        size: 20, color: _getIntensityColor(intensity)),
                    const SizedBox(width: 8),
                    Text(tr(context, intensity)),
                  ],
                ),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _preferredIntensity = value!;
        });
        _savePreference(_intensityKey, _preferredIntensity);
      },
    );
  }

  Widget _buildExperienceLevelDropdown() {
    final experienceOptions = [
      'beginner',
      'intermediate',
      'advanced',
      'expert',
      'professional'
    ];

    return _buildDropdownTile(
      title: tr(context, 'experience_level'),
      value: _experienceLevel,
      options: experienceOptions
          .map((level) => DropdownMenuItem(
                value: level,
                child: Row(
                  children: [
                    Icon(_getExperienceIcon(level),
                        size: 20, color: _getExperienceColor(level)),
                    const SizedBox(width: 8),
                    Text(tr(context, level)),
                  ],
                ),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _experienceLevel = value!;
        });
        _savePreference(_experienceLevelKey, _experienceLevel);
      },
    );
  }

  Widget _buildFitnessGoalDropdown() {
    final goalOptions = [
      'weight_loss',
      'muscle_gain',
      'strength_building',
      'endurance_improvement',
      'athletic_performance',
      'general_fitness',
      'flexibility_mobility',
      'rehabilitation',
      'stress_relief',
      'competition_prep',
      'maintenance'
    ];

    return _buildDropdownTile(
      title: tr(context, 'primary_fitness_goal'),
      value: _fitnessGoal,
      options: goalOptions
          .map((goal) => DropdownMenuItem(
                value: goal,
                child: Row(
                  children: [
                    Icon(_getGoalIcon(goal),
                        size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(tr(context, goal))),
                  ],
                ),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _fitnessGoal = value!;
        });
        _savePreference(_fitnessGoalKey, _fitnessGoal);
      },
    );
  }

  Widget _buildWorkoutLocationDropdown() {
    final locationOptions = [
      'home',
      'gym',
      'outdoor',
      'studio',
      'office',
      'hotel',
      'flexible'
    ];

    return _buildDropdownTile(
      title: tr(context, 'preferred_workout_location'),
      value: _workoutLocation,
      options: locationOptions
          .map((location) => DropdownMenuItem(
                value: location,
                child: Row(
                  children: [
                    Icon(_getLocationIcon(location),
                        size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(tr(context, location)),
                  ],
                ),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _workoutLocation = value!;
        });
        _savePreference(_workoutLocationKey, _workoutLocation);
      },
    );
  }

  Widget _buildEquipmentSelection() {
    final equipmentOptions = [
      'body_weight',
      'dumbbells',
      'barbells',
      'resistance_bands',
      'kettlebells',
      'pull_up_bar',
      'yoga_mat',
      'foam_roller',
      'gym_machines',
      'cardio_machines',
      'suspension_trainer',
      'medicine_ball',
      'battle_ropes',
      'olympic_plates',
      'cable_machine',
      'smith_machine',
      'power_rack',
      'bench',
      'stability_ball'
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'available_equipment'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr(context, 'select_equipment_description'),
            style: TextStyle(
              color: AppTheme.textColor(context).withAlpha(179),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: equipmentOptions.map((equipment) {
              final isSelected = _availableEquipment.contains(equipment);
              return FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getEquipmentIcon(equipment),
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(tr(context, equipment)),
                  ],
                ),
                selectedColor: AppColors.primary,
                backgroundColor: AppTheme.cardColor(context),
                labelStyle: TextStyle(
                  color:
                      isSelected ? Colors.white : AppTheme.textColor(context),
                  fontSize: 12,
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _availableEquipment.add(equipment);
                    } else {
                      _availableEquipment.remove(equipment);
                    }
                  });
                  _savePreference(_equipmentKey, _availableEquipment.toList());
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutTypesSelection() {
    final workoutTypes = [
      'strength_training',
      'cardio',
      'hiit',
      'yoga',
      'pilates',
      'calisthenics',
      'powerlifting',
      'olympic_lifting',
      'crossfit',
      'bodybuilding',
      'stretching',
      'martial_arts',
      'boxing',
      'dance',
      'swimming',
      'running',
      'cycling',
      'rock_climbing',
      'sports_specific',
      'functional_training',
      'circuit_training',
      'plyometrics'
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'preferred_workout_types'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr(context, 'select_workout_types_description'),
            style: TextStyle(
              color: AppTheme.textColor(context).withAlpha(179),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: workoutTypes.map((type) {
              final isSelected = _preferredWorkoutTypes.contains(type);
              return FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getWorkoutTypeIcon(type),
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(tr(context, type)),
                  ],
                ),
                selectedColor: AppColors.primary,
                backgroundColor: AppTheme.cardColor(context),
                labelStyle: TextStyle(
                  color:
                      isSelected ? Colors.white : AppTheme.textColor(context),
                  fontSize: 12,
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _preferredWorkoutTypes.add(type);
                    } else {
                      _preferredWorkoutTypes.remove(type);
                    }
                  });
                  _savePreference(
                      _workoutTypesKey, _preferredWorkoutTypes.toList());
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRestDaysSlider() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr(context, 'rest_days_per_week'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(26),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$_restDaysPerWeek ${tr(context, 'days')}',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.blue,
              inactiveTrackColor: Colors.blue.withAlpha(77),
              thumbColor: Colors.blue,
              overlayColor: Colors.blue.withAlpha(51),
            ),
            child: Slider(
              value: _restDaysPerWeek.toDouble(),
              min: 0,
              max: 5,
              divisions: 5,
              onChanged: (value) {
                setState(() {
                  _restDaysPerWeek = value.round();
                });
                _savePreference(_restDaysKey, _restDaysPerWeek);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr(context, 'daily_training'),
                style: TextStyle(
                  color: AppTheme.textColor(context).withAlpha(179),
                  fontSize: 12,
                ),
              ),
              Text(
                tr(context, 'light_schedule'),
                style: TextStyle(
                  color: AppTheme.textColor(context).withAlpha(179),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEcoOptionsSwitch() {
    return _buildSwitchTile(
      title: tr(context, 'eco_friendly_options'),
      subtitle: tr(context, 'eco_options_description'),
      value: _ecoOptionsEnabled,
      icon: Icons.eco,
      iconColor: Colors.green,
      onChanged: (value) {
        setState(() {
          _ecoOptionsEnabled = value;
        });
        _savePreference(_ecoOptionsKey, _ecoOptionsEnabled);
      },
    );
  }

  Widget _buildNavigationTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.textColor(context).withAlpha(179),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.textColor(context).withAlpha(179),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String value,
    required List<DropdownMenuItem<String>> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTheme.textColor(context).withAlpha(51),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                items: options,
                onChanged: onChanged,
                style: TextStyle(color: AppTheme.textColor(context)),
                dropdownColor: AppTheme.cardColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    Color? iconColor,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: iconColor ?? AppColors.primary),
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

  Widget _buildDivider() {
    return Divider(
      color: AppTheme.textColor(context).withAlpha(26),
      height: 1,
    );
  }

  // Icon helper methods
  IconData _getTimeIcon(String time) {
    switch (time) {
      case 'early_morning':
        return Icons.wb_twilight;
      case 'morning':
        return Icons.wb_sunny;
      case 'late_morning':
        return Icons.wb_sunny_outlined;
      case 'afternoon':
        return Icons.wb_sunny;
      case 'evening':
        return Icons.wb_twilight;
      case 'night':
        return Icons.nights_stay;
      case 'flexible':
        return Icons.schedule;
      default:
        return Icons.access_time;
    }
  }

  IconData _getIntensityIcon(String intensity) {
    switch (intensity) {
      case 'light':
        return Icons.sentiment_satisfied;
      case 'moderate':
        return Icons.trending_up;
      case 'vigorous':
        return Icons.local_fire_department;
      case 'extreme':
        return Icons.whatshot;
      default:
        return Icons.trending_up;
    }
  }

  Color _getIntensityColor(String intensity) {
    switch (intensity) {
      case 'light':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'vigorous':
        return Colors.red;
      case 'extreme':
        return Colors.purple;
      default:
        return AppColors.primary;
    }
  }

  IconData _getExperienceIcon(String level) {
    switch (level) {
      case 'beginner':
        return Icons.child_care;
      case 'intermediate':
        return Icons.person;
      case 'advanced':
        return Icons.sports;
      case 'expert':
        return Icons.military_tech;
      case 'professional':
        return Icons.emoji_events;
      default:
        return Icons.person;
    }
  }

  Color _getExperienceColor(String level) {
    switch (level) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.blue;
      case 'advanced':
        return Colors.orange;
      case 'expert':
        return Colors.purple;
      case 'professional':
        return AppColors.gold;
      default:
        return AppColors.primary;
    }
  }

  IconData _getGoalIcon(String goal) {
    switch (goal) {
      case 'weight_loss':
        return Icons.trending_down;
      case 'muscle_gain':
        return Icons.fitness_center;
      case 'strength_building':
        return Icons.sports_gymnastics;
      case 'endurance_improvement':
        return Icons.directions_run;
      case 'athletic_performance':
        return Icons.sports;
      case 'general_fitness':
        return Icons.favorite;
      case 'flexibility_mobility':
        return Icons.accessibility_new;
      case 'rehabilitation':
        return Icons.healing;
      case 'stress_relief':
        return Icons.spa;
      case 'competition_prep':
        return Icons.emoji_events;
      case 'maintenance':
        return Icons.balance;
      default:
        return Icons.fitness_center;
    }
  }

  IconData _getLocationIcon(String location) {
    switch (location) {
      case 'home':
        return Icons.home;
      case 'gym':
        return Icons.fitness_center;
      case 'outdoor':
        return Icons.nature;
      case 'studio':
        return Icons.business;
      case 'office':
        return Icons.work;
      case 'hotel':
        return Icons.hotel;
      case 'flexible':
        return Icons.place;
      default:
        return Icons.location_on;
    }
  }

  IconData _getEquipmentIcon(String equipment) {
    switch (equipment) {
      case 'body_weight':
        return Icons.accessibility_new;
      case 'dumbbells':
        return Icons.fitness_center;
      case 'barbells':
        return Icons.sports_gymnastics;
      case 'resistance_bands':
        return Icons.linear_scale;
      case 'kettlebells':
        return Icons.sports_handball;
      case 'pull_up_bar':
        return Icons.height;
      case 'yoga_mat':
        return Icons.self_improvement;
      case 'foam_roller':
        return Icons.roller_skating;
      case 'gym_machines':
        return Icons.precision_manufacturing;
      case 'cardio_machines':
        return Icons.directions_run;
      case 'suspension_trainer':
        return Icons.anchor;
      case 'medicine_ball':
        return Icons.sports_volleyball;
      case 'battle_ropes':
        return Icons.waves;
      case 'olympic_plates':
        return Icons.album;
      case 'cable_machine':
        return Icons.cable;
      case 'smith_machine':
        return Icons.construction;
      case 'power_rack':
        return Icons.view_module;
      case 'bench':
        return Icons.weekend;
      case 'stability_ball':
        return Icons.circle;
      default:
        return Icons.sports;
    }
  }

  IconData _getWorkoutTypeIcon(String type) {
    switch (type) {
      case 'strength_training':
        return Icons.fitness_center;
      case 'cardio':
        return Icons.favorite;
      case 'hiit':
        return Icons.flash_on;
      case 'yoga':
        return Icons.self_improvement;
      case 'pilates':
        return Icons.accessibility_new;
      case 'calisthenics':
        return Icons.sports_gymnastics;
      case 'powerlifting':
        return Icons.sports_kabaddi;
      case 'olympic_lifting':
        return Icons.emoji_events;
      case 'crossfit':
        return Icons.sports;
      case 'bodybuilding':
        return Icons.sports_handball;
      case 'stretching':
        return Icons.accessibility;
      case 'martial_arts':
        return Icons.sports_martial_arts;
      case 'boxing':
        return Icons.sports_mma;
      case 'dance':
        return Icons.music_note;
      case 'swimming':
        return Icons.pool;
      case 'running':
        return Icons.directions_run;
      case 'cycling':
        return Icons.directions_bike;
      case 'rock_climbing':
        return Icons.terrain;
      case 'sports_specific':
        return Icons.sports_soccer;
      case 'functional_training':
        return Icons.psychology;
      case 'circuit_training':
        return Icons.repeat;
      case 'plyometrics':
        return Icons
            .trending_up; // Fixed: replaced Icons.bounce_rate with Icons.trending_up
      default:
        return Icons.sports;
    }
  }
}
