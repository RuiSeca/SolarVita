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
import 'workout_preferences_screen.dart';

class ActivityLevelScreen extends OnboardingBaseScreen {
  final UserProfile userProfile;

  const ActivityLevelScreen({
    super.key,
    required this.userProfile,
  });

  @override
  ConsumerState<ActivityLevelScreen> createState() => _ActivityLevelScreenState();
}

class _ActivityLevelScreenState extends OnboardingBaseScreenState<ActivityLevelScreen>
    with SingleTickerProviderStateMixin {
  final OnboardingAudioService _audioService = OnboardingAudioService();

  late AnimationController _textController;
  late Animation<double> _headingAnimation;
  late Animation<double> _subheadingAnimation;

  String _selectedActivityLevel = '';

  List<ActivityOption> get _activityOptions => [
    ActivityOption(
      value: 'beginner',
      icon: Icons.directions_walk,
      label: tr(context, 'activity_beginner_label'),
      description: tr(context, 'activity_beginner_description'),
      color: const Color(0xFF3B82F6),
    ),
    ActivityOption(
      value: 'intermediate',
      icon: Icons.directions_run,
      label: tr(context, 'activity_intermediate_label'),
      description: tr(context, 'activity_intermediate_description'),
      color: const Color(0xFF10B981),
    ),
    ActivityOption(
      value: 'advanced',
      icon: Icons.fitness_center,
      label: tr(context, 'activity_advanced_label'),
      description: tr(context, 'activity_advanced_description'),
      color: const Color(0xFFF59E0B),
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
    _audioService.playButtonSound();
  }

  void _continue() {
    _audioService.playContinueSound();

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
  Widget buildScreenContent(BuildContext context) {
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
                            widget.userProfile.name.isNotEmpty
                              ? trWithParams(context, 'activity_greeting_with_name', {'name': widget.userProfile.name})
                              : tr(context, 'activity_level_title'),
                            style: const TextStyle(
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
                          child: Text(
                            widget.userProfile.name.isNotEmpty
                              ? tr(context, 'activity_level_subtitle_with_name')
                              : tr(context, 'activity_level_subtitle'),
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

                  // Activity Level Options
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      childAspectRatio: 3.5,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _activityOptions.length,
                    itemBuilder: (context, index) {
                      final option = _activityOptions[index];
                      final isSelected = _selectedActivityLevel == option.value;

                      return FloatingGlowingIcon(
                        icon: option.icon,
                        label: option.label,
                        description: option.description,
                        isSelected: isSelected,
                        color: option.color,
                        onTap: () => _onActivityLevelSelected(option.value),
                      );
                    },
                  ),

                  // Continue Button
                  AnimatedOpacity(
                    opacity: _selectedActivityLevel.isNotEmpty ? 1.0 : 0.3,
                    duration: const Duration(milliseconds: 300),
                    child: GlowingButton(
                      text: tr(context, 'continue_button'),
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