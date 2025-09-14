import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/animated_waves.dart';
import '../components/floating_glowing_icon.dart';
import '../components/glowing_button.dart';
import '../services/onboarding_audio_service.dart';
import '../models/onboarding_models.dart';
import 'diet_type_screen.dart';

class FitnessGoalsScreen extends StatefulWidget {
  final UserProfile userProfile;

  const FitnessGoalsScreen({
    super.key,
    required this.userProfile,
  });

  @override
  State<FitnessGoalsScreen> createState() => _FitnessGoalsScreenState();
}

class _FitnessGoalsScreenState extends State<FitnessGoalsScreen>
    with SingleTickerProviderStateMixin {
  final OnboardingAudioService _audioService = OnboardingAudioService();

  late AnimationController _textController;
  late Animation<double> _headingAnimation;
  late Animation<double> _subheadingAnimation;

  Set<String> _selectedGoals = {}; // ignore: prefer_final_fields

  final List<FitnessGoalOption> _goalOptions = [
    FitnessGoalOption(
      value: 'lose_weight',
      icon: Icons.trending_down,
      label: 'Lose Weight',
      description: 'Burn fat & get lean',
      color: Color(0xFFEF4444),
    ),
    FitnessGoalOption(
      value: 'gain_muscle',
      icon: Icons.fitness_center,
      label: 'Gain Muscle',
      description: 'Build strength & size',
      color: Color(0xFF3B82F6),
    ),
    FitnessGoalOption(
      value: 'improve_endurance',
      icon: Icons.directions_run,
      label: 'Improve Endurance',
      description: 'Boost stamina & energy',
      color: Color(0xFF10B981),
    ),
    FitnessGoalOption(
      value: 'flexibility',
      icon: Icons.self_improvement,
      label: 'Flexibility',
      description: 'Increase mobility',
      color: Color(0xFF8B5CF6),
    ),
    FitnessGoalOption(
      value: 'general_health',
      icon: Icons.favorite,
      label: 'General Health',
      description: 'Stay active & healthy',
      color: Color(0xFFEC4899),
    ),
    FitnessGoalOption(
      value: 'stress_relief',
      icon: Icons.spa,
      label: 'Stress Relief',
      description: 'Mental wellness',
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

  void _onGoalToggled(String goal) {
    setState(() {
      if (_selectedGoals.contains(goal)) {
        _selectedGoals.remove(goal);
      } else {
        _selectedGoals.add(goal);
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
            DietTypeScreen(userProfile: widget.userProfile),
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
              intensity: 0.8,
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
                            "What Are Your Fitness Goals?",
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
                            "Select all that motivate you",
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

                  // Goals Grid
                  Expanded(
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.1,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _goalOptions.length,
                      itemBuilder: (context, index) {
                        final option = _goalOptions[index];
                        final isSelected = _selectedGoals.contains(option.value);

                        return FloatingGlowingIcon(
                          icon: option.icon,
                          label: option.label,
                          description: option.description,
                          isSelected: isSelected,
                          color: option.color,
                          onTap: () => _onGoalToggled(option.value),
                        );
                      },
                    ),
                  ),

                  // Continue Button
                  AnimatedOpacity(
                    opacity: _selectedGoals.isNotEmpty ? 1.0 : 0.3,
                    duration: const Duration(milliseconds: 300),
                    child: GlowingButton(
                      text: "Continue",
                      onPressed: _selectedGoals.isNotEmpty ? _continue : null,
                      glowIntensity: _selectedGoals.length / _goalOptions.length,
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

// Fitness goal option model
class FitnessGoalOption {
  final String value;
  final IconData icon;
  final String label;
  final String description;
  final Color color;

  const FitnessGoalOption({
    required this.value,
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
  });
}