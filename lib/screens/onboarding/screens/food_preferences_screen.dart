import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/animated_waves.dart';
import '../components/glowing_button.dart';
import '../components/onboarding_base_screen.dart';
import '../services/onboarding_audio_service.dart';
import '../models/onboarding_models.dart';
import '../../../utils/translation_helper.dart';
import 'bio_interests_screen.dart';

class FoodPreferencesScreen extends OnboardingBaseScreen {
  final UserProfile userProfile;

  const FoodPreferencesScreen({
    super.key,
    required this.userProfile,
  });

  @override
  ConsumerState<FoodPreferencesScreen> createState() => _FoodPreferencesScreenState();
}

class _FoodPreferencesScreenState extends OnboardingBaseScreenState<FoodPreferencesScreen>
    with SingleTickerProviderStateMixin {
  final OnboardingAudioService _audioService = OnboardingAudioService();

  late AnimationController _textController;
  late Animation<double> _headingAnimation;
  late Animation<double> _subheadingAnimation;


  bool _preferOrganic = true;
  bool _preferLocal = true;
  bool _preferSeasonal = true;
  bool _sustainableSeafood = true;
  bool _reduceMeatConsumption = false;
  bool _intermittentFasting = false;

  List<FoodPreferenceOption> get _foodOptions => [
    FoodPreferenceOption(
      key: 'organic',
      icon: Icons.eco,
      title: tr(context, 'food_organic'),
      description: tr(context, 'food_organic_desc'),
      color: const Color(0xFF10B981),
    ),
    FoodPreferenceOption(
      key: 'local',
      icon: Icons.location_on,
      title: tr(context, 'food_local'),
      description: tr(context, 'food_local_desc'),
      color: const Color(0xFF3B82F6),
    ),
    FoodPreferenceOption(
      key: 'seasonal',
      icon: Icons.calendar_today,
      title: tr(context, 'food_seasonal'),
      description: tr(context, 'food_seasonal_desc'),
      color: const Color(0xFF8B5CF6),
    ),
    FoodPreferenceOption(
      key: 'sustainable_seafood',
      icon: Icons.waves,
      title: tr(context, 'food_sustainable_seafood'),
      description: tr(context, 'food_sustainable_seafood_desc'),
      color: const Color(0xFF06B6D4),
    ),
    FoodPreferenceOption(
      key: 'reduce_meat',
      icon: Icons.nature_people,
      title: tr(context, 'food_reduce_meat'),
      description: tr(context, 'food_reduce_meat_desc'),
      color: const Color(0xFFEC4899),
    ),
    FoodPreferenceOption(
      key: 'intermittent_fasting',
      icon: Icons.schedule,
      title: tr(context, 'food_intermittent_fasting'),
      description: tr(context, 'food_intermittent_fasting_desc'),
      color: const Color(0xFFF59E0B),
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Set initial values based on diet type
    if (widget.userProfile.dietType == 'vegetarian' || widget.userProfile.dietType == 'vegan') {
      _reduceMeatConsumption = true;
    }

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

  bool _getPreferenceValue(String key) {
    switch (key) {
      case 'organic':
        return _preferOrganic;
      case 'local':
        return _preferLocal;
      case 'seasonal':
        return _preferSeasonal;
      case 'sustainable_seafood':
        return _sustainableSeafood;
      case 'reduce_meat':
        return _reduceMeatConsumption;
      case 'intermittent_fasting':
        return _intermittentFasting;
      default:
        return false;
    }
  }

  void _togglePreference(String key) {
    setState(() {
      switch (key) {
        case 'organic':
          _preferOrganic = !_preferOrganic;
          break;
        case 'local':
          _preferLocal = !_preferLocal;
          break;
        case 'seasonal':
          _preferSeasonal = !_preferSeasonal;
          break;
        case 'sustainable_seafood':
          _sustainableSeafood = !_sustainableSeafood;
          break;
        case 'reduce_meat':
          _reduceMeatConsumption = !_reduceMeatConsumption;
          break;
        case 'intermittent_fasting':
          _intermittentFasting = !_intermittentFasting;
          break;
      }
    });
    HapticFeedback.lightImpact();
    _audioService.playChime(ChimeType.selection);
  }

  void _continue() {
    _audioService.playChime(ChimeType.progression);

    // Create updated profile with food preferences
    final updatedProfile = widget.userProfile.copyWith(
      // Add these fields to the onboarding model
      // preferOrganic: _preferOrganic,
      // preferLocal: _preferLocal,
      // preferSeasonal: _preferSeasonal,
      // sustainableSeafood: _sustainableSeafood,
      // reduceMeatConsumption: _reduceMeatConsumption,
      // intermittentFasting: _intermittentFasting,
    );

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            BioInterestsScreen(
          userProfile: updatedProfile,
          foodPreferences: {
            'preferOrganic': _preferOrganic,
            'preferLocal': _preferLocal,
            'preferSeasonal': _preferSeasonal,
            'sustainableSeafood': _sustainableSeafood,
            'reduceMeatConsumption': _reduceMeatConsumption,
            'intermittentFasting': _intermittentFasting,
          },
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
                            tr(context, 'food_preferences_title'),
                            style: const TextStyle(
                              fontSize: 30,
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
                            tr(context, 'food_preferences_subtitle'),
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

                  // Food Preferences Grid
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _foodOptions.length,
                    itemBuilder: (context, index) {
                      final option = _foodOptions[index];
                      final isSelected = _getPreferenceValue(option.key);

                      return _buildFoodPreferenceCard(
                        option.icon,
                        option.title,
                        option.description,
                        isSelected,
                        option.color,
                        () => _togglePreference(option.key),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Helpful Tips
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0x14FFFFFF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0x1AFFFFFF),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.lightbulb_outline,
                              color: Color(0xFF00FFC6),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                tr(context, 'food_preferences_tips_title'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          tr(context, 'food_preferences_tips_description'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
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

  Widget _buildFoodPreferenceCard(
    IconData icon,
    String title,
    String description,
    bool isSelected,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? color.withValues(alpha: 0.2) : const Color(0x1AFFFFFF),
          border: Border.all(
            color: isSelected ? color : const Color(0x33FFFFFF),
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? color : Colors.white70,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isSelected && description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w300,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Helper class
class FoodPreferenceOption {
  final String key;
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const FoodPreferenceOption({
    required this.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}