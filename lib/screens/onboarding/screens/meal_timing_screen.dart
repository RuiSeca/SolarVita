import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/animated_waves.dart';
import '../components/glowing_button.dart';
import '../components/onboarding_base_screen.dart';
import '../services/onboarding_audio_service.dart';
import '../models/onboarding_models.dart';
import '../../../utils/translation_helper.dart';
import 'nutrition_goals_screen.dart';

class MealTimingScreen extends OnboardingBaseScreen {
  final UserProfile userProfile;

  const MealTimingScreen({
    super.key,
    required this.userProfile,
  });

  @override
  ConsumerState<MealTimingScreen> createState() => _MealTimingScreenState();
}

class _MealTimingScreenState extends OnboardingBaseScreenState<MealTimingScreen>
    with SingleTickerProviderStateMixin {
  final OnboardingAudioService _audioService = OnboardingAudioService();

  late AnimationController _textController;
  late Animation<double> _headingAnimation;
  late Animation<double> _subheadingAnimation;


  final TextEditingController _breakfastController = TextEditingController(text: '08:00');
  final TextEditingController _lunchController = TextEditingController(text: '12:30');
  final TextEditingController _dinnerController = TextEditingController(text: '19:00');
  final TextEditingController _snackController = TextEditingController(text: '15:30');

  bool _enableSnacks = true;

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
    _breakfastController.dispose();
    _lunchController.dispose();
    _dinnerController.dispose();
    _snackController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _selectTime(TextEditingController controller) async {
    // Parse current time
    final parts = controller.text.split(':');
    final currentTime = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 12,
      minute: int.tryParse(parts[1]) ?? 0,
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: const TimePickerThemeData(
              backgroundColor: Color(0xFF1A1A2E),
              dialHandColor: Color(0xFF00FFC6),
              dialTextColor: Colors.white,
              hourMinuteTextColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      HapticFeedback.lightImpact();
      _audioService.playButtonSound();
    }
  }

  void _continue() {
    _audioService.playContinueSound();

    // Create updated profile with meal timing
    final updatedProfile = widget.userProfile.copyWith(
      breakfastTime: _breakfastController.text,
      lunchTime: _lunchController.text,
      dinnerTime: _dinnerController.text,
      snackTime: _enableSnacks ? _snackController.text : null,
    );

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            NutritionGoalsScreen(userProfile: updatedProfile),
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
          // Adaptive waves
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
                            tr(context, 'meal_timing_title'),
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
                            tr(context, 'meal_timing_subtitle'),
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

                  // Meal Timing Fields
                  _buildTimeField(
                    tr(context, 'meal_breakfast_label'),
                    Icons.wb_sunny_outlined,
                    _breakfastController,
                  ),

                  _buildTimeField(
                    tr(context, 'meal_lunch_label'),
                    Icons.wb_cloudy,
                    _lunchController,
                  ),

                  _buildTimeField(
                    tr(context, 'meal_dinner_label'),
                    Icons.wb_twilight,
                    _dinnerController,
                  ),

                  const SizedBox(height: 30),

                  // Snacks toggle
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0x14FFFFFF),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20), // Slick top corner cut
                        topRight: Radius.circular(4),  // Sharp top right
                        bottomLeft: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      ),
                      border: Border.fromBorderSide(BorderSide(
                        color: Color(0x1AFFFFFF),
                        width: 1,
                      )),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cookie,
                          color: _enableSnacks ? const Color(0xFF00FFC6) : Colors.white54,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr(context, 'enable_snacks_label'),
                                style: TextStyle(
                                  color: _enableSnacks ? Colors.white : Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tr(context, 'enable_snacks_description'),
                                style: TextStyle(
                                  color: _enableSnacks ? Colors.white70 : Colors.white54,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _enableSnacks,
                          onChanged: (value) {
                            setState(() {
                              _enableSnacks = value;
                            });
                            HapticFeedback.lightImpact();
                            _audioService.playButtonSound();
                          },
                          activeThumbColor: const Color(0xFF00FFC6),
                          activeTrackColor: const Color(0x3300FFC6),
                          inactiveThumbColor: Colors.white54,
                          inactiveTrackColor: const Color(0x33FFFFFF),
                        ),
                      ],
                    ),
                  ),

                  // Snack time field (if enabled)
                  if (_enableSnacks) ...[
                    const SizedBox(height: 20),
                    _buildTimeField(
                      tr(context, 'meal_snack_label'),
                      Icons.cookie_outlined,
                      _snackController,
                    ),
                  ],

                  const SizedBox(height: 60),

                  // Continue Button
                  GlowingButton(
                    text: tr(context, 'continue_button'),
                    onPressed: _continue,
                    glowIntensity: 1.0,
                    width: double.infinity,
                    height: 56,
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

  Widget _buildTimeField(String label, IconData icon, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        onTap: () => _selectTime(controller),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0x14FFFFFF),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20), // Slick top corner cut
              topRight: Radius.circular(4),  // Sharp top right
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
            border: Border.fromBorderSide(BorderSide(
              color: Color(0x1AFFFFFF),
              width: 1,
            )),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF00FFC6),
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.access_time,
                color: Colors.white54,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}