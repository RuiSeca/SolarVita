import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/animated_waves.dart';
import '../components/progress_constellation.dart';
import '../components/floating_glowing_icon.dart';
import '../components/glowing_button.dart';
import '../services/onboarding_audio_service.dart';
import '../models/onboarding_models.dart';
import 'workout_preferences_screen.dart';

class ActivityLevelScreen extends StatefulWidget {
  final UserProfile userProfile;

  const ActivityLevelScreen({
    super.key,
    required this.userProfile,
  });

  @override
  State<ActivityLevelScreen> createState() => _ActivityLevelScreenState();
}

class _ActivityLevelScreenState extends State<ActivityLevelScreen>
    with SingleTickerProviderStateMixin {
  final OnboardingAudioService _audioService = OnboardingAudioService();

  late AnimationController _textController;
  late Animation<double> _headingAnimation;
  late Animation<double> _subheadingAnimation;

  String _selectedActivityLevel = '';

  final List<ActivityOption> _activityOptions = const [
    ActivityOption(
      value: 'beginner',
      icon: Icons.directions_walk,
      label: 'Beginner',
      description: 'Just starting out\n1-2 times per week',
      color: Color(0xFF3B82F6),
    ),
    ActivityOption(
      value: 'intermediate',
      icon: Icons.directions_run,
      label: 'Intermediate',
      description: 'Some experience\n3-4 times per week',
      color: Color(0xFF10B981),
    ),
    ActivityOption(
      value: 'advanced',
      icon: Icons.fitness_center,
      label: 'Advanced',
      description: 'Very experienced\n5+ times per week',
      color: Color(0xFFF59E0B),
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

  void _onActivityLevelSelected(String level) {
    setState(() {
      _selectedActivityLevel = level;
    });
    HapticFeedback.lightImpact();
    _audioService.playChime(ChimeType.selection);
  }

  void _continue() {
    _audioService.playChime(ChimeType.progression);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            WorkoutPreferencesScreen(userProfile: widget.userProfile),
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
              intensity: 0.6,
              personality: widget.userProfile.dominantWavePersonality,
            ),
          ),

          // Progress Constellation
          const Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: ProgressConstellation(currentStep: 6, totalSteps: 10),
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
                            "What's Your Activity Level?",
                            style: TextStyle(
                              fontSize: 32,
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
                            "Help us tailor your fitness experience",
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

                  // Activity Level Options
                  Expanded(
                    child: Column(
                      children: _activityOptions.map((option) {
                        final isSelected = _selectedActivityLevel == option.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: SizedBox(
                            width: double.infinity,
                            height: 100,
                            child: FloatingGlowingIcon(
                              icon: option.icon,
                              label: option.label,
                              description: option.description,
                              isSelected: isSelected,
                              color: option.color,
                              onTap: () => _onActivityLevelSelected(option.value),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Continue Button
                  AnimatedOpacity(
                    opacity: _selectedActivityLevel.isNotEmpty ? 1.0 : 0.3,
                    duration: const Duration(milliseconds: 300),
                    child: GlowingButton(
                      text: "Continue",
                      onPressed: _selectedActivityLevel.isNotEmpty ? _continue : null,
                      glowIntensity: _selectedActivityLevel.isNotEmpty ? 1.0 : 0.3,
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

// Activity option model
class ActivityOption {
  final String value;
  final IconData icon;
  final String label;
  final String description;
  final Color color;

  const ActivityOption({
    required this.value,
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
  });
}