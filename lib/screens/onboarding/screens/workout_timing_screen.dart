import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/animated_waves.dart';
import '../components/floating_glowing_icon.dart';
import '../components/glowing_button.dart';
import '../services/onboarding_audio_service.dart';
import '../models/onboarding_models.dart';
import 'workout_schedule_screen.dart';

class WorkoutTimingScreen extends StatefulWidget {
  final UserProfile userProfile;
  final Map<String, dynamic>? additionalData;

  const WorkoutTimingScreen({
    super.key,
    required this.userProfile,
    this.additionalData,
  });

  @override
  State<WorkoutTimingScreen> createState() => _WorkoutTimingScreenState();
}

class _WorkoutTimingScreenState extends State<WorkoutTimingScreen>
    with SingleTickerProviderStateMixin {
  final OnboardingAudioService _audioService = OnboardingAudioService();

  late AnimationController _textController;
  late Animation<double> _headingAnimation;
  late Animation<double> _subheadingAnimation;

  String _selectedTime = '';

  final List<WorkoutTimeOption> _timeOptions = [
    WorkoutTimeOption(
      value: 'early_morning',
      icon: Icons.wb_sunny_outlined,
      label: 'Early Morning',
      description: '5:00 - 7:00 AM\nStart your day strong',
      color: Color(0xFFF59E0B),
    ),
    WorkoutTimeOption(
      value: 'morning',
      icon: Icons.wb_sunny,
      label: 'Morning',
      description: '7:00 - 10:00 AM\nEnergize your morning',
      color: Color(0xFFEAB308),
    ),
    WorkoutTimeOption(
      value: 'afternoon',
      icon: Icons.wb_cloudy,
      label: 'Afternoon',
      description: '12:00 - 5:00 PM\nMidday boost',
      color: Color(0xFF06B6D4),
    ),
    WorkoutTimeOption(
      value: 'evening',
      icon: Icons.wb_twilight,
      label: 'Evening',
      description: '5:00 - 8:00 PM\nUnwind with fitness',
      color: Color(0xFF8B5CF6),
    ),
    WorkoutTimeOption(
      value: 'night',
      icon: Icons.nights_stay,
      label: 'Night',
      description: '8:00 - 10:00 PM\nEnd the day right',
      color: Color(0xFF6366F1),
    ),
    WorkoutTimeOption(
      value: 'flexible',
      icon: Icons.schedule,
      label: 'Flexible',
      description: 'Whenever I can\nFit it into my schedule',
      color: Color(0xFF10B981),
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

  void _onTimeSelected(String time) {
    setState(() {
      _selectedTime = time;
    });
    HapticFeedback.lightImpact();
    _audioService.playChime(ChimeType.selection);
  }

  void _continue() {
    _audioService.playChime(ChimeType.progression);

    // Create updated profile with workout timing
    final updatedProfile = widget.userProfile.copyWith(
      preferredWorkoutTimeString: _selectedTime,
    );

    // Combine additional data with workout timing
    final combinedAdditionalData = {
      ...(widget.additionalData ?? {}),
      'preferredWorkoutTime': _selectedTime,
    };

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            WorkoutScheduleScreen(
              userProfile: updatedProfile,
              additionalData: combinedAdditionalData,
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
              intensity: 0.7,
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
                            "When Do You Prefer to Workout?",
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
                            "Choose your ideal workout time",
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

                  // Time Options Grid
                  Expanded(
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _timeOptions.length,
                      itemBuilder: (context, index) {
                        final option = _timeOptions[index];
                        final isSelected = _selectedTime == option.value;

                        return FloatingGlowingIcon(
                          icon: option.icon,
                          label: option.label,
                          description: option.description,
                          isSelected: isSelected,
                          color: option.color,
                          onTap: () => _onTimeSelected(option.value),
                        );
                      },
                    ),
                  ),

                  // Continue Button
                  AnimatedOpacity(
                    opacity: _selectedTime.isNotEmpty ? 1.0 : 0.3,
                    duration: const Duration(milliseconds: 300),
                    child: GlowingButton(
                      text: "Continue",
                      onPressed: _selectedTime.isNotEmpty ? _continue : null,
                      glowIntensity: _selectedTime.isNotEmpty ? 1.0 : 0.3,
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

// Workout time option model
class WorkoutTimeOption {
  final String value;
  final IconData icon;
  final String label;
  final String description;
  final Color color;

  const WorkoutTimeOption({
    required this.value,
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
  });
}