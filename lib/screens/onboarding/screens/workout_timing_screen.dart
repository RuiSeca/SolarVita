import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/animated_waves.dart';
import '../components/glowing_button.dart';
import '../components/onboarding_base_screen.dart';
import '../services/onboarding_audio_service.dart';
import '../models/onboarding_models.dart';
import '../../../utils/translation_helper.dart';
import 'workout_schedule_screen.dart';

class WorkoutTimingScreen extends OnboardingBaseScreen {
  final UserProfile userProfile;
  final Map<String, dynamic>? additionalData;

  const WorkoutTimingScreen({
    super.key,
    required this.userProfile,
    this.additionalData,
  });

  @override
  ConsumerState<WorkoutTimingScreen> createState() => _WorkoutTimingScreenState();
}

class _WorkoutTimingScreenState extends OnboardingBaseScreenState<WorkoutTimingScreen>
    with SingleTickerProviderStateMixin {
  final OnboardingAudioService _audioService = OnboardingAudioService();

  late AnimationController _textController;
  late Animation<double> _headingAnimation;
  late Animation<double> _subheadingAnimation;

  String _selectedTime = '';

  List<WorkoutTimeOption> get _timeOptions => [
    WorkoutTimeOption(
      value: 'early_morning',
      icon: Icons.wb_sunny_outlined,
      label: tr(context, 'workout_time_early_morning'),
      description: tr(context, 'workout_time_early_morning_desc'),
      color: const Color(0xFFF59E0B),
    ),
    WorkoutTimeOption(
      value: 'morning',
      icon: Icons.wb_sunny,
      label: tr(context, 'workout_time_morning'),
      description: tr(context, 'workout_time_morning_desc'),
      color: const Color(0xFFEAB308),
    ),
    WorkoutTimeOption(
      value: 'afternoon',
      icon: Icons.wb_cloudy,
      label: tr(context, 'workout_time_afternoon'),
      description: tr(context, 'workout_time_afternoon_desc'),
      color: const Color(0xFF06B6D4),
    ),
    WorkoutTimeOption(
      value: 'evening',
      icon: Icons.wb_twilight,
      label: tr(context, 'workout_time_evening'),
      description: tr(context, 'workout_time_evening_desc'),
      color: const Color(0xFF8B5CF6),
    ),
    WorkoutTimeOption(
      value: 'night',
      icon: Icons.nights_stay,
      label: tr(context, 'workout_time_night'),
      description: tr(context, 'workout_time_night_desc'),
      color: const Color(0xFF6366F1),
    ),
    WorkoutTimeOption(
      value: 'flexible',
      icon: Icons.schedule,
      label: tr(context, 'workout_time_flexible'),
      description: tr(context, 'workout_time_flexible_desc'),
      color: const Color(0xFF10B981),
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
  Widget buildScreenContent(BuildContext context) {
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
                            tr(context, 'workout_timing_title'),
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
                            tr(context, 'workout_timing_subtitle'),
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

                  // Timeline UI
                  _buildTimelineUI(),

                  const SizedBox(height: 40),

                  // Continue Button
                  AnimatedOpacity(
                    opacity: _selectedTime.isNotEmpty ? 1.0 : 0.3,
                    duration: const Duration(milliseconds: 300),
                    child: GlowingButton(
                      text: tr(context, 'continue_button'),
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

  Widget _buildTimelineUI() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        children: _timeOptions.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final isSelected = _selectedTime == option.value;
          final isLast = index == _timeOptions.length - 1;

          return _buildTimelineItem(
            option,
            isSelected,
            isLast,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimelineItem(
    WorkoutTimeOption option,
    bool isSelected,
    bool isLast,
  ) {
    return GestureDetector(
      onTap: () => _onTimeSelected(option.value),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Timeline indicator
            Column(
              children: [
                // Timeline dot
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? option.color : Colors.white.withValues(alpha: 0.3),
                    border: Border.all(
                      color: isSelected ? option.color : Colors.white.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: option.color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ] : null,
                  ),
                  child: isSelected ? Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  ) : null,
                ),
                // Timeline line
                if (!isLast)
                  Container(
                    width: 2,
                    height: 60,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
              ],
            ),
            const SizedBox(width: 20),
            // Content
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(bottom: isLast ? 0 : 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected ? option.color.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.08),
                  border: Border.all(
                    color: isSelected ? option.color.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      option.icon,
                      size: 24,
                      color: isSelected ? option.color : Colors.white70,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.label,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                          if (option.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              option.description,
                              style: TextStyle(
                                color: isSelected ? Colors.white.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.6),
                                fontSize: 13,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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