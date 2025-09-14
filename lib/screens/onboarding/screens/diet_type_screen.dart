import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/animated_waves.dart';
import '../components/floating_glowing_icon.dart';
import '../components/glowing_button.dart';
import '../services/onboarding_audio_service.dart';
import '../models/onboarding_models.dart';
import 'meal_timing_screen.dart';

class DietTypeScreen extends StatefulWidget {
  final UserProfile userProfile;

  const DietTypeScreen({
    super.key,
    required this.userProfile,
  });

  @override
  State<DietTypeScreen> createState() => _DietTypeScreenState();
}

class _DietTypeScreenState extends State<DietTypeScreen>
    with SingleTickerProviderStateMixin {
  final OnboardingAudioService _audioService = OnboardingAudioService();

  late AnimationController _textController;
  late Animation<double> _headingAnimation;
  late Animation<double> _subheadingAnimation;


  String _selectedDietType = '';
  final Set<String> _selectedRestrictions = {};
  final Set<String> _selectedAllergies = {};

  final List<DietTypeOption> _dietOptions = [
    DietTypeOption(
      value: 'omnivore',
      icon: Icons.restaurant,
      label: 'Omnivore',
      description: 'I eat everything',
      color: Color(0xFF10B981),
    ),
    DietTypeOption(
      value: 'vegetarian',
      icon: Icons.eco,
      label: 'Vegetarian',
      description: 'No meat or fish',
      color: Color(0xFF8B5CF6),
    ),
    DietTypeOption(
      value: 'vegan',
      icon: Icons.spa,
      label: 'Vegan',
      description: 'Plant-based only',
      color: Color(0xFF06B6D4),
    ),
    DietTypeOption(
      value: 'pescatarian',
      icon: Icons.set_meal,
      label: 'Pescatarian',
      description: 'Fish but no meat',
      color: Color(0xFF3B82F6),
    ),
    DietTypeOption(
      value: 'keto',
      icon: Icons.local_fire_department,
      label: 'Keto',
      description: 'Low carb, high fat',
      color: Color(0xFFEF4444),
    ),
    DietTypeOption(
      value: 'paleo',
      icon: Icons.nature,
      label: 'Paleo',
      description: 'Whole foods only',
      color: Color(0xFFF59E0B),
    ),
  ];

  final List<RestrictionOption> _restrictionOptions = [
    RestrictionOption('gluten_free', 'Gluten-Free', Icons.grain),
    RestrictionOption('dairy_free', 'Dairy-Free', Icons.no_drinks),
    RestrictionOption('sugar_free', 'Sugar-Free', Icons.block),
    RestrictionOption('low_sodium', 'Low Sodium', Icons.opacity),
    RestrictionOption('halal', 'Halal', Icons.verified),
    RestrictionOption('kosher', 'Kosher', Icons.star),
  ];

  final List<AllergyOption> _allergyOptions = [
    AllergyOption('nuts', 'Nuts', Icons.eco_rounded),
    AllergyOption('shellfish', 'Shellfish', Icons.set_meal),
    AllergyOption('eggs', 'Eggs', Icons.egg),
    AllergyOption('soy', 'Soy', Icons.grass),
    AllergyOption('fish', 'Fish', Icons.phishing),
    AllergyOption('sesame', 'Sesame', Icons.circle),
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

  void _onDietTypeSelected(String dietType) {
    setState(() {
      _selectedDietType = dietType;
    });
    HapticFeedback.lightImpact();
    _audioService.playChime(ChimeType.selection);
  }

  void _onRestrictionToggled(String restriction) {
    setState(() {
      if (_selectedRestrictions.contains(restriction)) {
        _selectedRestrictions.remove(restriction);
      } else {
        _selectedRestrictions.add(restriction);
      }
    });
    HapticFeedback.lightImpact();
    _audioService.playChime(ChimeType.selection);
  }

  void _onAllergyToggled(String allergy) {
    setState(() {
      if (_selectedAllergies.contains(allergy)) {
        _selectedAllergies.remove(allergy);
      } else {
        _selectedAllergies.add(allergy);
      }
    });
    HapticFeedback.lightImpact();
    _audioService.playChime(ChimeType.selection);
  }

  void _continue() {
    _audioService.playChime(ChimeType.progression);

    // Create updated profile with dietary information
    final updatedProfile = widget.userProfile.copyWith(
      dietType: _selectedDietType,
      restrictions: _selectedRestrictions.toList(),
      allergies: _selectedAllergies.toList(),
    );

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            MealTimingScreen(userProfile: updatedProfile),
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
                            "What's Your Diet Style?",
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
                            "Choose your dietary approach",
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

                  const SizedBox(height: 40),

                  // Diet Type Grid
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _dietOptions.length,
                    itemBuilder: (context, index) {
                      final option = _dietOptions[index];
                      final isSelected = _selectedDietType == option.value;

                      return FloatingGlowingIcon(
                        icon: option.icon,
                        label: option.label,
                        description: option.description,
                        isSelected: isSelected,
                        color: option.color,
                        onTap: () => _onDietTypeSelected(option.value),
                      );
                    },
                  ),

                  const SizedBox(height: 50),

                  // Dietary Restrictions Section
                  const Text(
                    "Dietary Restrictions",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Select any that apply (optional)",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white60,
                      fontWeight: FontWeight.w300,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  // Restrictions Wrap
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _restrictionOptions.map((option) {
                      final isSelected = _selectedRestrictions.contains(option.value);
                      return _buildChip(
                        option.label,
                        option.icon,
                        isSelected,
                        () => _onRestrictionToggled(option.value),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 40),

                  // Allergies Section
                  const Text(
                    "Food Allergies",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Help us keep you safe (optional)",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white60,
                      fontWeight: FontWeight.w300,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  // Allergies Wrap
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _allergyOptions.map((option) {
                      final isSelected = _selectedAllergies.contains(option.value);
                      return _buildChip(
                        option.label,
                        option.icon,
                        isSelected,
                        () => _onAllergyToggled(option.value),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 60),

                  // Continue Button
                  AnimatedOpacity(
                    opacity: _selectedDietType.isNotEmpty ? 1.0 : 0.3,
                    duration: const Duration(milliseconds: 300),
                    child: GlowingButton(
                      text: "Continue",
                      onPressed: _selectedDietType.isNotEmpty ? _continue : null,
                      glowIntensity: _selectedDietType.isNotEmpty ? 1.0 : 0.3,
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

  Widget _buildChip(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0x33FFFFFF) : const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? const Color(0xFF00FFC6) : const Color(0x33FFFFFF),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? const Color(0xFF00FFC6) : Colors.white70,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper classes
class DietTypeOption {
  final String value;
  final IconData icon;
  final String label;
  final String description;
  final Color color;

  const DietTypeOption({
    required this.value,
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
  });
}

class RestrictionOption {
  final String value;
  final String label;
  final IconData icon;

  const RestrictionOption(this.value, this.label, this.icon);
}

class AllergyOption {
  final String value;
  final String label;
  final IconData icon;

  const AllergyOption(this.value, this.label, this.icon);
}