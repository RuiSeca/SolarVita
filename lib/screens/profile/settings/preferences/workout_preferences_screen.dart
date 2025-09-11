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

  // Expansion states
  bool _workoutTypesExpanded = false;
  bool _fitnessGoalsExpanded = false;

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
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: _isLoading
            ? const Center(child: LottieLoadingWidget())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWorkoutTypesSection(),
                  const SizedBox(height: 20),
                  _buildFrequencyAndDurationSection(),
                  const SizedBox(height: 20),
                  _buildFitnessLevelSection(),
                  const SizedBox(height: 20),
                  _buildFitnessGoalsSection(),
                  const SizedBox(height: 20),
                  _buildAvailableDaysSection(),
                  const SizedBox(height: 20),
                  _buildPreferredTimeSection(),
                  const SizedBox(height: 24),
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
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon, 
                    color: iconColor ?? AppColors.primary, 
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.isDarkMode(context) 
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.08),
                spreadRadius: 0,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildWorkoutTypesSection() {
    return _buildSection(
      title: tr(context, 'workout_types'),
      icon: Icons.fitness_center_rounded,
      children: [
        // Preview section when collapsed
        if (!_workoutTypesExpanded) _buildPreviewTile(
          icon: Icons.fitness_center_rounded,
          iconColor: AppColors.primary,
          title: tr(context, 'workout_options'),
          subtitle: tr(context, 'tap_to_view_workout_types'),
          previewItems: _workoutTypeOptions.take(4).map((item) {
            final translationKey = item.toLowerCase().replaceAll(' ', '_').replaceAll('/', '_');
            return tr(context, translationKey);
          }).toList(),
          selectedCount: _selectedWorkoutTypes.length,
          onTap: () => setState(() => _workoutTypesExpanded = true),
        ),
        
        // Full selection section when expanded
        if (_workoutTypesExpanded) Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr(context, 'select_preferred_workout_types'),
                    style: TextStyle(
                      color: AppTheme.textColor(context).withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _workoutTypesExpanded = false),
                    child: Text(
                      tr(context, 'collapse'),
                      style: TextStyle(color: AppColors.primary, fontSize: 12),
                    ),
                  ),
                ],
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppTheme.textColor(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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
      icon: Icons.schedule_rounded,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
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
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.primary.withValues(alpha: 0.3),
                  thumbColor: AppColors.primary,
                  overlayColor: AppColors.primary.withValues(alpha: 0.1),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                ),
                child: Slider(
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
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.primary.withValues(alpha: 0.3),
                  thumbColor: AppColors.primary,
                  overlayColor: AppColors.primary.withValues(alpha: 0.1),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                ),
                child: Slider(
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
      icon: Icons.trending_up_rounded,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RadioGroup<String>(
                groupValue: _fitnessLevel,
                onChanged: (value) {
                  setState(() {
                    _fitnessLevel = value!;
                  });
                },
                child: Column(
                  children: _fitnessLevelOptions.map((level) {
                    return RadioListTile<String>(
                      value: level,
                      title: Text(
                        level.toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      activeColor: AppColors.primary,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFitnessGoalsSection() {
    return _buildSection(
      title: tr(context, 'fitness_goals'),
      icon: Icons.emoji_events_rounded,
      iconColor: AppColors.gold,
      children: [
        // Preview section when collapsed
        if (!_fitnessGoalsExpanded) _buildPreviewTile(
          icon: Icons.emoji_events_rounded,
          iconColor: AppColors.gold,
          title: tr(context, 'goal_options'),
          subtitle: tr(context, 'tap_to_view_fitness_goals'),
          previewItems: _goalOptions.take(4).map((item) {
            final translationKey = item.toLowerCase().replaceAll(' ', '_');
            return tr(context, translationKey);
          }).toList(),
          selectedCount: _selectedGoals.length,
          onTap: () => setState(() => _fitnessGoalsExpanded = true),
        ),
        
        // Full selection section when expanded
        if (_fitnessGoalsExpanded) Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr(context, 'select_fitness_goals'),
                    style: TextStyle(
                      color: AppTheme.textColor(context).withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _fitnessGoalsExpanded = false),
                    child: Text(
                      tr(context, 'collapse'),
                      style: TextStyle(color: AppColors.gold, fontSize: 12),
                    ),
                  ),
                ],
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppTheme.textColor(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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
      icon: Icons.calendar_today_rounded,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(context, 'select_available_days'),
                style: TextStyle(
                  color: AppTheme.textColor(context).withValues(alpha: 179),
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
      icon: Icons.access_time_rounded,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RadioGroup<String>(
                groupValue: _preferredTime,
                onChanged: (value) {
                  setState(() {
                    _preferredTime = value!;
                  });
                },
                child: Column(
                  children: _timeOptions.map((time) {
                    return RadioListTile<String>(
                      value: time,
                      title: Text(
                        time.toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      activeColor: AppColors.primary,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            spreadRadius: 0,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _savePreferences,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: LottieLoadingWidget(width: 20, height: 20),
              )
            : Text(
                tr(context, 'save_preferences'),
                style: const TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildPreviewTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<String> previewItems,
    required int selectedCount,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: AppTheme.textColor(context),
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          if (selectedCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: iconColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$selectedCount',
                                style: TextStyle(
                                  color: iconColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppTheme.textColor(context).withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.expand_more_rounded,
                  color: AppTheme.textColor(context).withValues(alpha: 0.5),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: previewItems.map((item) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
            if (previewItems.length < _workoutTypeOptions.length || previewItems.length < _goalOptions.length)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  tr(context, 'and_more_options_available'),
                  style: TextStyle(
                    color: AppTheme.textColor(context).withValues(alpha: 0.5),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
