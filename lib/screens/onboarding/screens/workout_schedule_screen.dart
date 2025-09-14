import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/animated_waves.dart';
import '../components/glowing_button.dart';
import '../services/onboarding_audio_service.dart';
import '../models/onboarding_models.dart';
import 'onboarding_completion_screen.dart';

class WorkoutScheduleScreen extends StatefulWidget {
  final UserProfile userProfile;
  final Map<String, dynamic>? additionalData;

  const WorkoutScheduleScreen({
    super.key,
    required this.userProfile,
    this.additionalData,
  });

  @override
  State<WorkoutScheduleScreen> createState() => _WorkoutScheduleScreenState();
}

class _WorkoutScheduleScreenState extends State<WorkoutScheduleScreen>
    with SingleTickerProviderStateMixin {
  final OnboardingAudioService _audioService = OnboardingAudioService();

  late AnimationController _textController;
  late Animation<double> _headingAnimation;
  late Animation<double> _subheadingAnimation;

  Set<String> _selectedDays = {}; // ignore: prefer_final_fields

  final List<DayOption> _dayOptions = [
    DayOption(
      value: 'monday',
      label: 'Monday',
      abbreviation: 'MON',
      color: Color(0xFFEF4444),
    ),
    DayOption(
      value: 'tuesday',
      label: 'Tuesday',
      abbreviation: 'TUE',
      color: Color(0xFFF97316),
    ),
    DayOption(
      value: 'wednesday',
      label: 'Wednesday',
      abbreviation: 'WED',
      color: Color(0xFFF59E0B),
    ),
    DayOption(
      value: 'thursday',
      label: 'Thursday',
      abbreviation: 'THU',
      color: Color(0xFF10B981),
    ),
    DayOption(
      value: 'friday',
      label: 'Friday',
      abbreviation: 'FRI',
      color: Color(0xFF06B6D4),
    ),
    DayOption(
      value: 'saturday',
      label: 'Saturday',
      abbreviation: 'SAT',
      color: Color(0xFF8B5CF6),
    ),
    DayOption(
      value: 'sunday',
      label: 'Sunday',
      abbreviation: 'SUN',
      color: Color(0xFFEC4899),
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
    _audioService.playChime(ChimeType.selection);
  }

  void _continue() {
    _audioService.playChime(ChimeType.commitment);

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
  Widget build(BuildContext context) {
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
                          child: const Text(
                            "Which Days Can You Workout?",
                            style: TextStyle(
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
                          child: const Text(
                            "Select all days you're available",
                            style: TextStyle(
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
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // First row - Mon to Wed
                        Row(
                          children: _dayOptions.take(3).map((option) {
                            final isSelected = _selectedDays.contains(option.value);
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: SizedBox(
                                  height: 100,
                                  child: _buildDayCard(option, isSelected),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 16),

                        // Second row - Thu to Fri
                        Row(
                          children: [
                            const Expanded(child: SizedBox()),
                            ..._dayOptions.skip(3).take(2).map((option) {
                              final isSelected = _selectedDays.contains(option.value);
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: SizedBox(
                                    height: 100,
                                    child: _buildDayCard(option, isSelected),
                                  ),
                                ),
                              );
                            }),
                            const Expanded(child: SizedBox()),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Third row - Weekend
                        Row(
                          children: _dayOptions.skip(5).map((option) {
                            final isSelected = _selectedDays.contains(option.value);
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: SizedBox(
                                  height: 100,
                                  child: _buildDayCard(option, isSelected),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  // Continue Button
                  AnimatedOpacity(
                    opacity: _selectedDays.isNotEmpty ? 1.0 : 0.3,
                    duration: const Duration(milliseconds: 300),
                    child: GlowingButton(
                      text: "Complete Setup",
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

  Widget _buildDayCard(DayOption option, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onDayToggled(option.value),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? option.color.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? option.color : Colors.white.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: option.color.withValues(alpha: 0.3),
                      blurRadius: 20,
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? option.color : Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                option.label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? option.color : Colors.white70,
                ),
              ),
            ],
          ),
        ),
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