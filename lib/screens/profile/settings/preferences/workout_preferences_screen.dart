// lib/screens/profile/settings/preferences/workout_preferences_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/translation_helper.dart';
import '../../../../providers/riverpod/user_profile_provider.dart';
import '../../../../models/user/user_profile.dart';
import '../../../../widgets/common/lottie_loading_widget.dart';

class WorkoutPreferencesScreen extends ConsumerStatefulWidget {
  const WorkoutPreferencesScreen({super.key});

  @override
  ConsumerState<WorkoutPreferencesScreen> createState() =>
      _WorkoutPreferencesScreenState();
}

class _WorkoutPreferencesScreenState
    extends ConsumerState<WorkoutPreferencesScreen> {
  bool _isLoading = false;

  // Current values - will be populated from UserProfile
  List<String> _selectedWorkoutTypes = [];
  int _workoutFrequency = 3;
  int _sessionDuration = 30;
  String _fitnessLevel = 'intermediate';
  List<String> _selectedGoals = [];
  Map<String, bool> _availableDays = {
    'monday': true,
    'tuesday': true,
    'wednesday': true,
    'thursday': true,
    'friday': true,
    'saturday': true,
    'sunday': true,
  };
  String _preferredTime = 'morning';

  // Options
  final List<String> _workoutTypeOptions = [
    'Cardio',
    'Strength Training',
    'Yoga',
    'Pilates',
    'HIIT',
    'Running',
    'Cycling',
    'Swimming',
    'Dance',
    'Martial Arts',
    'Calisthenics',
    'Outdoor Activities',
  ];

  final List<String> _fitnessLevelOptions = [
    'beginner',
    'intermediate',
    'advanced',
  ];

  final List<String> _goalOptions = [
    'Weight Loss',
    'Muscle Gain',
    'Endurance',
    'Flexibility',
    'Strength',
    'General Health',
    'Stress Relief',
    'Better Sleep',
  ];

  final List<String> _timeOptions = [
    'morning',
    'afternoon',
    'evening',
    'night',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserPreferences();
    });
  }

  void _loadUserPreferences() {
    final userProfileProvider = ref.read(userProfileNotifierProvider);
    final workoutPrefs = userProfileProvider.value?.workoutPreferences;

    if (workoutPrefs != null) {
      setState(() {
        _selectedWorkoutTypes = List<String>.from(
          workoutPrefs.preferredWorkoutTypes,
        );
        _workoutFrequency = workoutPrefs.workoutFrequencyPerWeek;
        _sessionDuration = workoutPrefs.sessionDurationMinutes;
        _fitnessLevel = workoutPrefs.fitnessLevel;
        _selectedGoals = List<String>.from(workoutPrefs.fitnessGoals);
        _availableDays = Map<String, bool>.from(workoutPrefs.availableDays);
        _preferredTime = workoutPrefs.preferredTime;
      });
    }
  }

  Future<void> _savePreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedWorkoutPrefs = WorkoutPreferences(
        preferredWorkoutTypes: _selectedWorkoutTypes,
        workoutFrequencyPerWeek: _workoutFrequency,
        sessionDurationMinutes: _sessionDuration,
        fitnessLevel: _fitnessLevel,
        fitnessGoals: _selectedGoals,
        availableDays: _availableDays,
        preferredTime: _preferredTime,
      );

      await ref
          .read(userProfileNotifierProvider.notifier)
          .updateWorkoutPreferences(updatedWorkoutPrefs);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'workout_preferences_updated')),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'error_updating_preferences').replaceAll('{error}', '$e')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
        child: _isLoading
            ? const Center(child: LottieLoadingWidget())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWorkoutTypesSection(),
                  const SizedBox(height: 24),
                  _buildFrequencyAndDurationSection(),
                  const SizedBox(height: 24),
                  _buildFitnessLevelSection(),
                  const SizedBox(height: 24),
                  _buildFitnessGoalsSection(),
                  const SizedBox(height: 24),
                  _buildAvailableDaysSection(),
                  const SizedBox(height: 24),
                  _buildPreferredTimeSection(),
                  const SizedBox(height: 32),
                  _buildSaveButton(),
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

  Widget _buildWorkoutTypesSection() {
    return _buildSection(
      title: tr(context, 'workout_types'),
      icon: Icons.fitness_center,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(context, 'select_preferred_workout_types'),
                style: TextStyle(
                  color: AppTheme.textColor(context).withAlpha(179),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _workoutTypeOptions.map((type) {
                  final isSelected = _selectedWorkoutTypes.contains(type);
                  final translationKey = type.toLowerCase().replaceAll(' ', '_').replaceAll('/', '_');
                  return FilterChip(
                    selected: isSelected,
                    label: Text(tr(context, translationKey)),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppTheme.cardColor(context),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppTheme.textColor(context),
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedWorkoutTypes.add(type);
                        } else {
                          _selectedWorkoutTypes.remove(type);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencyAndDurationSection() {
    return _buildSection(
      title: tr(context, 'frequency_duration'),
      icon: Icons.schedule,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(context, 'workouts_per_week'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Slider(
                value: _workoutFrequency.toDouble(),
                min: 1,
                max: 7,
                divisions: 6,
                label: tr(context, 'times_label').replaceAll('{count}', '$_workoutFrequency'),
                onChanged: (value) {
                  setState(() {
                    _workoutFrequency = value.round();
                  });
                },
              ),
              const SizedBox(height: 20),
              Text(
                tr(context, 'session_duration_minutes'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Slider(
                value: _sessionDuration.toDouble(),
                min: 15,
                max: 120,
                divisions: 21,
                label: tr(context, 'min_label').replaceAll('{count}', '$_sessionDuration'),
                onChanged: (value) {
                  setState(() {
                    _sessionDuration = value.round();
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFitnessLevelSection() {
    return _buildSection(
      title: tr(context, 'fitness_level'),
      icon: Icons.trending_up,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._fitnessLevelOptions.map((level) {
                return RadioListTile<String>(
                  value: level,
                  groupValue: _fitnessLevel,
                  onChanged: (value) {
                    setState(() {
                      _fitnessLevel = value!;
                    });
                  },
                  title: Text(
                    level.toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  activeColor: AppColors.primary,
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFitnessGoalsSection() {
    return _buildSection(
      title: tr(context, 'fitness_goals'),
      icon: Icons.emoji_events,
      iconColor: AppColors.gold,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(context, 'select_fitness_goals'),
                style: TextStyle(
                  color: AppTheme.textColor(context).withAlpha(179),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _goalOptions.map((goal) {
                  final isSelected = _selectedGoals.contains(goal);
                  final translationKey = goal.toLowerCase().replaceAll(' ', '_');
                  return FilterChip(
                    selected: isSelected,
                    label: Text(tr(context, translationKey)),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppTheme.cardColor(context),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppTheme.textColor(context),
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedGoals.add(goal);
                        } else {
                          _selectedGoals.remove(goal);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableDaysSection() {
    return _buildSection(
      title: tr(context, 'available_days'),
      icon: Icons.calendar_today,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(context, 'select_available_days'),
                style: TextStyle(
                  color: AppTheme.textColor(context).withAlpha(179),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              ..._availableDays.entries.map((entry) {
                return CheckboxListTile(
                  value: entry.value,
                  onChanged: (value) {
                    setState(() {
                      _availableDays[entry.key] = value!;
                    });
                  },
                  title: Text(
                    tr(context, entry.key),
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  activeColor: AppColors.primary,
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferredTimeSection() {
    return _buildSection(
      title: tr(context, 'preferred_time'),
      icon: Icons.access_time,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._timeOptions.map((time) {
                return RadioListTile<String>(
                  value: time,
                  groupValue: _preferredTime,
                  onChanged: (value) {
                    setState(() {
                      _preferredTime = value!;
                    });
                  },
                  title: Text(
                    time.toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  activeColor: AppColors.primary,
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _savePreferences,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: LottieLoadingWidget(width: 20, height: 20),
                )
              : Text(
                  tr(context, 'save_preferences'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}
