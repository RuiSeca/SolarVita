import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/animated_waves.dart';
import '../components/glowing_button.dart';
import '../components/onboarding_base_screen.dart';
import '../services/onboarding_audio_service.dart';
import '../models/onboarding_models.dart';
import '../../../utils/translation_helper.dart';
import 'onboarding_completion_screen.dart';

class WorkoutScheduleScreen extends OnboardingBaseScreen {
  final UserProfile userProfile;
  final Map<String, dynamic>? additionalData;

  const WorkoutScheduleScreen({
    super.key,
    required this.userProfile,
    this.additionalData,
  });

  @override
  ConsumerState<WorkoutScheduleScreen> createState() => _WorkoutScheduleScreenState();
}

class _WorkoutScheduleScreenState extends OnboardingBaseScreenState<WorkoutScheduleScreen>
    with SingleTickerProviderStateMixin {
  final OnboardingAudioService _audioService = OnboardingAudioService();

  late AnimationController _textController;
  late Animation<double> _headingAnimation;
  late Animation<double> _subheadingAnimation;

  Set<String> _selectedDays = {}; // ignore: prefer_final_fields

  List<DayOption> get _dayOptions => [
    DayOption(
      value: 'monday',
      label: tr(context, 'day_monday'),
      abbreviation: tr(context, 'day_monday_abbr'),
      color: const Color(0xFFEF4444),
    ),
    DayOption(
      value: 'tuesday',
      label: tr(context, 'day_tuesday'),
      abbreviation: tr(context, 'day_tuesday_abbr'),
      color: const Color(0xFFF97316),
    ),
    DayOption(
      value: 'wednesday',
      label: tr(context, 'day_wednesday'),
      abbreviation: tr(context, 'day_wednesday_abbr'),
      color: const Color(0xFFF59E0B),
    ),
    DayOption(
      value: 'thursday',
      label: tr(context, 'day_thursday'),
      abbreviation: tr(context, 'day_thursday_abbr'),
      color: const Color(0xFF10B981),
    ),
    DayOption(
      value: 'friday',
      label: tr(context, 'day_friday'),
      abbreviation: tr(context, 'day_friday_abbr'),
      color: const Color(0xFF06B6D4),
    ),
    DayOption(
      value: 'saturday',
      label: tr(context, 'day_saturday'),
      abbreviation: tr(context, 'day_saturday_abbr'),
      color: const Color(0xFF8B5CF6),
    ),
    DayOption(
      value: 'sunday',
      label: tr(context, 'day_sunday'),
      abbreviation: tr(context, 'day_sunday_abbr'),
      color: const Color(0xFFEC4899),
    ),
  ];

  @override
  void initState() {
    super.initState();

    _textController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _headingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _subheadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _textController.forward();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onDayToggled(String day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
    HapticFeedback.lightImpact();
    _audioService.playButtonSound();
  }

  void _continue() {
    _audioService.playContinueSound();

    // Create updated profile with selected workout days
    final updatedProfile = widget.userProfile.copyWith(
      // availableWorkoutDays: _selectedDays.toList(), // Will add this field to model
    );

    // Combine additional data with selected workout days
    final finalAdditionalData = {
      ...(widget.additionalData ?? {}),
      'selectedWorkoutDays': _selectedDays.toList(),
    };

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            OnboardingCompletionScreen(
              userProfile: updatedProfile,
              additionalData: finalAdditionalData,
            ),
        transitionDuration: const Duration(milliseconds: 800),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.3, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget buildScreenContent(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Adaptive waves continue from previous screen
          Positioned.fill(
            child: AnimatedWaves(
              intensity: 0.9,
              personality: widget.userProfile.dominantWavePersonality,
            ),
          ),


          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // Title
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - _headingAnimation.value)),
                        child: Opacity(
                          opacity: _headingAnimation.value,
                          child: Text(
                            tr(context, 'workout_schedule_title'),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Subtitle
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - _subheadingAnimation.value)),
                        child: Opacity(
                          opacity: _subheadingAnimation.value,
                          child: Text(
                            tr(context, 'workout_schedule_subtitle'),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              fontWeight: FontWeight.w300,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 80),

                  // Days Selection
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: _dayOptions.map((option) {
                      final isSelected = _selectedDays.contains(option.value);
                      return GestureDetector(
                        onTap: () => _onDayToggled(option.value),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? option.color.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.05),
                            border: Border.all(
                              color: isSelected ? option.color : Colors.white.withValues(alpha: 0.2),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: option.color.withValues(alpha: 0.3),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                option.abbreviation,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? option.color : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 60),

                  // Continue Button
                  AnimatedOpacity(
                    opacity: _selectedDays.isNotEmpty ? 1.0 : 0.3,
                    duration: const Duration(milliseconds: 300),
                    child: GlowingButton(
                      text: tr(context, 'complete_setup_button'),
                      onPressed: _selectedDays.isNotEmpty ? _continue : null,
                      glowIntensity: _selectedDays.length / _dayOptions.length,
                      width: double.infinity,
                      height: 56,
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}

// Day option model
class DayOption {
  final String value;
  final String label;
  final String abbreviation;
  final Color color;

  const DayOption({
    required this.value,
    required this.label,
    required this.abbreviation,
    required this.color,
  });
}