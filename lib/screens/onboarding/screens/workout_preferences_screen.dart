import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/animated_waves.dart';
import '../components/progress_constellation.dart';
import '../components/floating_glowing_icon.dart';
import '../components/glowing_button.dart';
import '../services/onboarding_audio_service.dart';
import '../models/onboarding_models.dart';
import 'fitness_goals_screen.dart';

class WorkoutPreferencesScreen extends StatefulWidget {
  final UserProfile userProfile;

  const WorkoutPreferencesScreen({
    super.key,
    required this.userProfile,
  });

  @override
  State<WorkoutPreferencesScreen> createState() => _WorkoutPreferencesScreenState();
}

class _WorkoutPreferencesScreenState extends State<WorkoutPreferencesScreen>
    with SingleTickerProviderStateMixin {
  final OnboardingAudioService _audioService = OnboardingAudioService();

  late AnimationController _textController;
  late Animation<double> _headingAnimation;
  late Animation<double> _subheadingAnimation;

  Set<String> _selectedWorkoutTypes = {}; // ignore: prefer_final_fields

  final List<WorkoutTypeOption> _workoutTypeOptions = [
    WorkoutTypeOption(
      value: 'cardio',
      icon: Icons.favorite,
      label: 'Cardio',
      color: Color(0xFFEF4444),
    ),
    WorkoutTypeOption(
      value: 'strength',
      icon: Icons.fitness_center,
      label: 'Strength',
      color: Color(0xFF3B82F6),
    ),
    WorkoutTypeOption(
      value: 'yoga',
      icon: Icons.self_improvement,
      label: 'Yoga',
      color: Color(0xFF8B5CF6),
    ),
    WorkoutTypeOption(
      value: 'running',
      icon: Icons.directions_run,
      label: 'Running',
      color: Color(0xFF10B981),
    ),
    WorkoutTypeOption(
      value: 'cycling',
      icon: Icons.directions_bike,
      label: 'Cycling',
      color: Color(0xFFF59E0B),
    ),
    WorkoutTypeOption(
      value: 'swimming',
      icon: Icons.pool,
      label: 'Swimming',
      color: Color(0xFF06B6D4),
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

  void _onWorkoutTypeToggled(String type) {
    setState(() {
      if (_selectedWorkoutTypes.contains(type)) {
        _selectedWorkoutTypes.remove(type);
      } else {
        _selectedWorkoutTypes.add(type);
      }
    });
    HapticFeedback.lightImpact();
    _audioService.playChime(ChimeType.selection);
  }

  void _continue() {
    _audioService.playChime(ChimeType.progression);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            FitnessGoalsScreen(userProfile: widget.userProfile),
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
              intensity: 0.7,
              personality: widget.userProfile.dominantWavePersonality,
            ),
          ),

          // Progress Constellation
          const Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: ProgressConstellation(currentStep: 7, totalSteps: 10),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 100),

                  // Title
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - _headingAnimation.value)),
                        child: Opacity(
                          opacity: _headingAnimation.value,
                          child: const Text(
                            "What Workouts Do You Enjoy?",
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
                            "Select all that interest you (choose at least one)",
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

                  const SizedBox(height: 60),

                  // Workout Type Grid
                  Expanded(
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _workoutTypeOptions.length,
                      itemBuilder: (context, index) {
                        final option = _workoutTypeOptions[index];
                        final isSelected = _selectedWorkoutTypes.contains(option.value);

                        return FloatingGlowingIcon(
                          icon: option.icon,
                          label: option.label,
                          description: "",
                          isSelected: isSelected,
                          color: option.color,
                          onTap: () => _onWorkoutTypeToggled(option.value),
                        );
                      },
                    ),
                  ),

                  // Continue Button
                  AnimatedOpacity(
                    opacity: _selectedWorkoutTypes.isNotEmpty ? 1.0 : 0.3,
                    duration: const Duration(milliseconds: 300),
                    child: GlowingButton(
                      text: "Continue",
                      onPressed: _selectedWorkoutTypes.isNotEmpty ? _continue : null,
                      glowIntensity: _selectedWorkoutTypes.length / _workoutTypeOptions.length,
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

// Workout type option model
class WorkoutTypeOption {
  final String value;
  final IconData icon;
  final String label;
  final Color color;

  const WorkoutTypeOption({
    required this.value,
    required this.icon,
    required this.label,
    required this.color,
  });
}