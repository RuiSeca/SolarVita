import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/animated_waves.dart';
import '../components/floating_glowing_icon.dart';
import '../components/glowing_button.dart';
import '../components/onboarding_base_screen.dart';
import '../services/onboarding_audio_service.dart';
import '../models/onboarding_models.dart';
import '../../../utils/translation_helper.dart';
import 'diet_type_screen.dart';

class FitnessGoalsScreen extends OnboardingBaseScreen {
  final UserProfile userProfile;

  const FitnessGoalsScreen({
    super.key,
    required this.userProfile,
  });

  @override
  ConsumerState<FitnessGoalsScreen> createState() => _FitnessGoalsScreenState();
}

class _FitnessGoalsScreenState extends OnboardingBaseScreenState<FitnessGoalsScreen>
    with SingleTickerProviderStateMixin {
  final OnboardingAudioService _audioService = OnboardingAudioService();

  late AnimationController _textController;
  late Animation<double> _headingAnimation;
  late Animation<double> _subheadingAnimation;

  Set<String> _selectedGoals = {}; // ignore: prefer_final_fields

  List<FitnessGoalOption> get _goalOptions => [
    FitnessGoalOption(
      value: 'lose_weight',
      icon: Icons.trending_down,
      label: tr(context, 'fitness_goal_lose_weight_label'),
      description: tr(context, 'fitness_goal_lose_weight_description'),
      color: Color(0xFFEF4444),
    ),
    FitnessGoalOption(
      value: 'gain_muscle',
      icon: Icons.fitness_center,
      label: tr(context, 'fitness_goal_gain_muscle_label'),
      description: tr(context, 'fitness_goal_gain_muscle_description'),
      color: Color(0xFF3B82F6),
    ),
    FitnessGoalOption(
      value: 'improve_endurance',
      icon: Icons.directions_run,
      label: tr(context, 'fitness_goal_improve_endurance_label'),
      description: tr(context, 'fitness_goal_improve_endurance_description'),
      color: Color(0xFF10B981),
    ),
    FitnessGoalOption(
      value: 'flexibility',
      icon: Icons.self_improvement,
      label: tr(context, 'fitness_goal_flexibility_label'),
      description: tr(context, 'fitness_goal_flexibility_description'),
      color: Color(0xFF8B5CF6),
    ),
    FitnessGoalOption(
      value: 'general_health',
      icon: Icons.favorite,
      label: tr(context, 'fitness_goal_general_health_label'),
      description: tr(context, 'fitness_goal_general_health_description'),
      color: Color(0xFFEC4899),
    ),
    FitnessGoalOption(
      value: 'stress_relief',
      icon: Icons.spa,
      label: tr(context, 'fitness_goal_stress_relief_label'),
      description: tr(context, 'fitness_goal_stress_relief_description'),
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
    _audioService.playButtonSound();
  }

  void _continue() {
    _audioService.playContinueSound();

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
  Widget buildScreenContent(BuildContext context) {
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
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
                            tr(context, 'fitness_goals_title'),
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
                            tr(context, 'fitness_goals_subtitle'),
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

                  const SizedBox(height: 60),

                  // Goals Grid
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
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

                  const SizedBox(height: 60),

                  // Continue Button
                  AnimatedOpacity(
                    opacity: _selectedGoals.isNotEmpty ? 1.0 : 0.3,
                    duration: const Duration(milliseconds: 300),
                    child: GlowingButton(
                      text: tr(context, 'continue_button'),
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