import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_profile.dart';
import '../../services/user_profile_service.dart';
import '../../providers/user_profile_provider.dart';
import 'sustainability_preferences_screen.dart';

class WorkoutPreferencesScreen extends StatefulWidget {
  const WorkoutPreferencesScreen({super.key});

  @override
  State<WorkoutPreferencesScreen> createState() => _WorkoutPreferencesScreenState();
}

class _WorkoutPreferencesScreenState extends State<WorkoutPreferencesScreen> {
  final UserProfileService _userProfileService = UserProfileService();
  bool _isLoading = false;

  final List<String> _selectedWorkoutTypes = [];
  int _workoutFrequency = 3;
  int _sessionDuration = 30;
  String _fitnessLevel = 'beginner';
  final List<String> _selectedGoals = [];
  final Map<String, bool> _availableDays = {
    'monday': true,
    'tuesday': true,
    'wednesday': true,
    'thursday': true,
    'friday': true,
    'saturday': true,
    'sunday': true,
  };
  String _preferredTime = 'morning';

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Preferences'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildWorkoutTypesSection(),
            const SizedBox(height: 24),
            _buildFrequencySection(),
            const SizedBox(height: 24),
            _buildDurationSection(),
            const SizedBox(height: 24),
            _buildFitnessLevelSection(),
            const SizedBox(height: 24),
            _buildGoalsSection(),
            const SizedBox(height: 24),
            _buildAvailableDaysSection(),
            const SizedBox(height: 24),
            _buildPreferredTimeSection(),
            const SizedBox(height: 32),
            _buildContinueButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Let\'s personalize your workout experience',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tell us about your fitness preferences so we can recommend the best workouts for you.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutTypesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What types of workouts do you enjoy?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _workoutTypeOptions.map((type) {
            final isSelected = _selectedWorkoutTypes.contains(type);
            return FilterChip(
              label: Text(type),
              selected: isSelected,
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
    );
  }

  Widget _buildFrequencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How often do you want to work out per week?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Slider(
          value: _workoutFrequency.toDouble(),
          min: 1,
          max: 7,
          divisions: 6,
          label: '$_workoutFrequency days',
          onChanged: (value) {
            setState(() {
              _workoutFrequency = value.round();
            });
          },
        ),
        Text(
          '$_workoutFrequency days per week',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildDurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How long do you prefer each workout session?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Slider(
          value: _sessionDuration.toDouble(),
          min: 15,
          max: 120,
          divisions: 7,
          label: '$_sessionDuration minutes',
          onChanged: (value) {
            setState(() {
              _sessionDuration = value.round();
            });
          },
        ),
        Text(
          '$_sessionDuration minutes',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildFitnessLevelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What\'s your current fitness level?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ..._fitnessLevelOptions.map((level) {
          return RadioListTile<String>(
            title: Text(level.capitalize()),
            value: level,
            groupValue: _fitnessLevel,
            onChanged: (value) {
              setState(() {
                _fitnessLevel = value!;
              });
            },
          );
        }),
      ],
    );
  }

  Widget _buildGoalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What are your fitness goals?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _goalOptions.map((goal) {
            final isSelected = _selectedGoals.contains(goal);
            return FilterChip(
              label: Text(goal),
              selected: isSelected,
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
    );
  }

  Widget _buildAvailableDaysSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Which days are you available to work out?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ..._availableDays.entries.map((entry) {
          return CheckboxListTile(
            title: Text(entry.key.capitalize()),
            value: entry.value,
            onChanged: (bool? value) {
              setState(() {
                _availableDays[entry.key] = value ?? false;
              });
            },
          );
        }),
      ],
    );
  }

  Widget _buildPreferredTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What time of day do you prefer to work out?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ..._timeOptions.map((time) {
          return RadioListTile<String>(
            title: Text(time.capitalize()),
            value: time,
            groupValue: _preferredTime,
            onChanged: (value) {
              setState(() {
                _preferredTime = value!;
              });
            },
          );
        }),
      ],
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveWorkoutPreferences,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const CircularProgressIndicator()
            : const Text('Continue'),
      ),
    );
  }

  Future<void> _saveWorkoutPreferences() async {
    if (_selectedWorkoutTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one workout type'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final workoutPreferences = WorkoutPreferences(
        preferredWorkoutTypes: _selectedWorkoutTypes,
        workoutFrequencyPerWeek: _workoutFrequency,
        sessionDurationMinutes: _sessionDuration,
        fitnessLevel: _fitnessLevel,
        fitnessGoals: _selectedGoals,
        availableDays: _availableDays,
        preferredTime: _preferredTime,
      );

      final profile = await _userProfileService.getOrCreateUserProfile();
      final updatedProfile = profile.copyWith(
        workoutPreferences: workoutPreferences,
      );
      await _userProfileService.updateUserProfile(updatedProfile);

      if (mounted) {
        // Update the provider with the latest profile
        final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
        await userProfileProvider.refreshUserProfile();
        
        // Check mounted again after async operation
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const SustainabilityPreferencesScreen(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: $e'),
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
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}