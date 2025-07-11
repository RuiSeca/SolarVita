// lib/screens/profile/settings/preferences/workout_preferences_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/translation_helper.dart';
import '../../../../providers/user_profile_provider.dart';
import '../../../../models/user_profile.dart';

class WorkoutPreferencesScreen extends StatefulWidget {
  const WorkoutPreferencesScreen({super.key});

  @override
  State<WorkoutPreferencesScreen> createState() =>
      _WorkoutPreferencesScreenState();
}

class _WorkoutPreferencesScreenState extends State<WorkoutPreferencesScreen> {
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
    final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
    final workoutPrefs = userProfileProvider.workoutPreferences;
    
    if (workoutPrefs != null) {
      setState(() {
        _selectedWorkoutTypes = List<String>.from(workoutPrefs.preferredWorkoutTypes);
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
      final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
      
      final updatedWorkoutPrefs = WorkoutPreferences(
        preferredWorkoutTypes: _selectedWorkoutTypes,
        workoutFrequencyPerWeek: _workoutFrequency,
        sessionDurationMinutes: _sessionDuration,
        fitnessLevel: _fitnessLevel,
        fitnessGoals: _selectedGoals,
        availableDays: _availableDays,
        preferredTime: _preferredTime,
      );

      await userProfileProvider.updateWorkoutPreferences(updatedWorkoutPrefs);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout preferences updated successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating preferences: $e'),
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
            ? const Center(child: CircularProgressIndicator())
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
      title: 'Workout Types',
      icon: Icons.fitness_center,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select your preferred workout types:',
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
                  return FilterChip(
                    selected: isSelected,
                    label: Text(type),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppTheme.cardColor(context),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textColor(context),
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
      title: 'Frequency & Duration',
      icon: Icons.schedule,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Workouts per week',
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
                label: '$_workoutFrequency times',
                onChanged: (value) {
                  setState(() {
                    _workoutFrequency = value.round();
                  });
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Session duration (minutes)',
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
                label: '$_sessionDuration min',
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
      title: 'Fitness Level',
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
      title: 'Fitness Goals',
      icon: Icons.emoji_events,
      iconColor: AppColors.gold,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select your fitness goals:',
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
                  return FilterChip(
                    selected: isSelected,
                    label: Text(goal),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppTheme.cardColor(context),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textColor(context),
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
      title: 'Available Days',
      icon: Icons.calendar_today,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select days you are available to workout:',
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
                    entry.key.toUpperCase(),
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
      title: 'Preferred Time',
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
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : const Text(
                  'Save Preferences',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }



}
