import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/animated_waves.dart';
import '../components/glowing_text_field.dart';
import '../components/glowing_button.dart';
import '../components/onboarding_base_screen.dart';
import '../services/onboarding_audio_service.dart';
import '../models/onboarding_models.dart';
import '../../../utils/translation_helper.dart';
import 'food_preferences_screen.dart';

class NutritionGoalsScreen extends OnboardingBaseScreen {
  final UserProfile userProfile;

  const NutritionGoalsScreen({
    super.key,
    required this.userProfile,
  });

  @override
  ConsumerState<NutritionGoalsScreen> createState() => _NutritionGoalsScreenState();
}

class _NutritionGoalsScreenState extends OnboardingBaseScreenState<NutritionGoalsScreen>
    with SingleTickerProviderStateMixin {
  final OnboardingAudioService _audioService = OnboardingAudioService();

  late AnimationController _textController;
  late Animation<double> _headingAnimation;
  late Animation<double> _subheadingAnimation;


  final TextEditingController _calorieController = TextEditingController(text: '2000');
  int _proteinPercentage = 20;
  int _carbsPercentage = 50;
  int _fatPercentage = 30;

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
    _calorieController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _updateMacros(String type, int value) {
    setState(() {
      switch (type) {
        case 'protein':
          _proteinPercentage = value;
          break;
        case 'carbs':
          _carbsPercentage = value;
          break;
        case 'fat':
          _fatPercentage = value;
          break;
      }

      // Ensure total doesn't exceed 100%
      final total = _proteinPercentage + _carbsPercentage + _fatPercentage;
      if (total != 100) {
        final diff = 100 - total;
        if (type == 'protein') {
          _carbsPercentage = (_carbsPercentage + diff).clamp(0, 100);
        } else if (type == 'carbs') {
          _fatPercentage = (_fatPercentage + diff).clamp(0, 100);
        } else {
          _proteinPercentage = (_proteinPercentage + diff).clamp(0, 100);
        }
      }
    });
    HapticFeedback.lightImpact();
    _audioService.playButtonSound();
  }

  void _continue() {
    _audioService.playContinueSound();

    // Create updated profile with nutrition goals
    final updatedProfile = widget.userProfile.copyWith(
      dailyCalorieGoal: int.tryParse(_calorieController.text) ?? 2000,
      proteinPercentage: _proteinPercentage,
      carbsPercentage: _carbsPercentage,
      fatPercentage: _fatPercentage,
    );

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            FoodPreferencesScreen(userProfile: updatedProfile),
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
                            tr(context, 'nutrition_goals_title'),
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
                            tr(context, 'nutrition_goals_subtitle'),
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

                  // Daily Calorie Goal
                  GlowingTextField(
                    label: tr(context, 'daily_calorie_goal_label'),
                    hint: tr(context, 'daily_calorie_goal_hint'),
                    controller: _calorieController,
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 40),

                  // Macro Distribution
                  Text(
                    tr(context, 'macro_distribution_label'),
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 30),

                  // Protein Slider
                  _buildMacroSlider(
                    tr(context, 'protein_label'),
                    _proteinPercentage,
                    const Color(0xFF3B82F6),
                    Icons.fitness_center,
                    (value) => _updateMacros('protein', value),
                  ),

                  // Carbs Slider
                  _buildMacroSlider(
                    tr(context, 'carbs_label'),
                    _carbsPercentage,
                    const Color(0xFF10B981),
                    Icons.eco,
                    (value) => _updateMacros('carbs', value),
                  ),

                  // Fat Slider
                  _buildMacroSlider(
                    tr(context, 'fat_label'),
                    _fatPercentage,
                    const Color(0xFFF59E0B),
                    Icons.opacity,
                    (value) => _updateMacros('fat', value),
                  ),

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

  Widget _buildMacroSlider(
    String label,
    int value,
    Color color,
    IconData icon,
    Function(int) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
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
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "$value%",
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: color,
                inactiveTrackColor: color.withValues(alpha: 0.3),
                thumbColor: color,
                overlayColor: color.withValues(alpha: 0.2),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                trackHeight: 4,
              ),
              child: Slider(
                value: value.toDouble().clamp(10.0, 60.0),
                min: 10,
                max: 60,
                divisions: 50,
                onChanged: (newValue) => onChanged(newValue.round()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}