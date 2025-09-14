import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/animated_waves.dart';
import '../components/glowing_button.dart';
import '../services/onboarding_audio_service.dart';
import '../models/onboarding_models.dart';
import 'bio_interests_screen.dart';

class FoodPreferencesScreen extends StatefulWidget {
  final UserProfile userProfile;

  const FoodPreferencesScreen({
    super.key,
    required this.userProfile,
  });

  @override
  State<FoodPreferencesScreen> createState() => _FoodPreferencesScreenState();
}

class _FoodPreferencesScreenState extends State<FoodPreferencesScreen>
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

  final List<FoodPreferenceOption> _foodOptions = [
    FoodPreferenceOption(
      key: 'organic',
      icon: Icons.eco,
      title: 'Organic Foods',
      description: 'Prefer organic ingredients',
      color: Color(0xFF10B981),
    ),
    FoodPreferenceOption(
      key: 'local',
      icon: Icons.location_on,
      title: 'Local Produce',
      description: 'Support local farmers',
      color: Color(0xFF3B82F6),
    ),
    FoodPreferenceOption(
      key: 'seasonal',
      icon: Icons.calendar_today,
      title: 'Seasonal Foods',
      description: 'Eat with the seasons',
      color: Color(0xFF8B5CF6),
    ),
    FoodPreferenceOption(
      key: 'sustainable_seafood',
      icon: Icons.waves,
      title: 'Sustainable Seafood',
      description: 'Ocean-friendly choices',
      color: Color(0xFF06B6D4),
    ),
    FoodPreferenceOption(
      key: 'reduce_meat',
      icon: Icons.nature_people,
      title: 'Reduce Meat',
      description: 'Lower environmental impact',
      color: Color(0xFFEC4899),
    ),
    FoodPreferenceOption(
      key: 'intermittent_fasting',
      icon: Icons.schedule,
      title: 'Intermittent Fasting',
      description: 'Time-restricted eating',
      color: Color(0xFFF59E0B),
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
  Widget build(BuildContext context) {
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
                          child: const Text(
                            "Food Values & Preferences",
                            style: TextStyle(
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
                          child: const Text(
                            "What matters to you when choosing food?",
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

                  // Food Preferences Grid
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: _foodOptions.map((option) {
                      final isSelected = _getPreferenceValue(option.key);

                      return SizedBox(
                        width: (MediaQuery.of(context).size.width - 80) / 2,
                        height: 140,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _togglePreference(option.key),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? option.color.withValues(alpha: 0.2)
                                    : const Color(0x1AFFFFFF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? option.color : const Color(0x33FFFFFF),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    option.icon,
                                    size: 32,
                                    color: isSelected ? option.color : Colors.white70,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    option.title,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    option.description,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white70 : Colors.white54,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w300,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
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
                                "💡 Helpful Tips",
                                style: TextStyle(
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
                          "These preferences help us recommend meals that align with your values. You can always change them later in settings.",
                          style: TextStyle(
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
                    text: "Continue",
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