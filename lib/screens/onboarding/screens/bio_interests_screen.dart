import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/animated_waves.dart';
import '../components/glowing_text_field.dart';
import '../components/glowing_button.dart';
import '../services/onboarding_audio_service.dart';
import '../models/onboarding_models.dart';
import 'workout_timing_screen.dart';

class BioInterestsScreen extends StatefulWidget {
  final UserProfile userProfile;
  final Map<String, bool>? foodPreferences;

  const BioInterestsScreen({
    super.key,
    required this.userProfile,
    this.foodPreferences,
  });

  @override
  State<BioInterestsScreen> createState() => _BioInterestsScreenState();
}

class _BioInterestsScreenState extends State<BioInterestsScreen>
    with SingleTickerProviderStateMixin {
  final OnboardingAudioService _audioService = OnboardingAudioService();

  late AnimationController _textController;
  late Animation<double> _headingAnimation;
  late Animation<double> _subheadingAnimation;

  final TextEditingController _bioController = TextEditingController();
  final Set<String> _selectedInterests = {};

  final List<InterestOption> _interestOptions = [
    InterestOption('fitness', 'Fitness', Icons.fitness_center, Color(0xFF3B82F6)),
    InterestOption('nutrition', 'Nutrition', Icons.restaurant, Color(0xFF10B981)),
    InterestOption('sustainability', 'Sustainability', Icons.eco, Color(0xFF8B5CF6)),
    InterestOption('mindfulness', 'Mindfulness', Icons.self_improvement, Color(0xFF06B6D4)),
    InterestOption('outdoor_activities', 'Outdoor Activities', Icons.terrain, Color(0xFFF59E0B)),
    InterestOption('cooking', 'Cooking', Icons.kitchen, Color(0xFFEC4899)),
    InterestOption('technology', 'Technology', Icons.computer, Color(0xFF6366F1)),
    InterestOption('travel', 'Travel', Icons.flight, Color(0xFFEF4444)),
    InterestOption('music', 'Music', Icons.music_note, Color(0xFF14B8A6)),
    InterestOption('reading', 'Reading', Icons.book, Color(0xFFA855F7)),
    InterestOption('photography', 'Photography', Icons.camera_alt, Color(0xFFE11D48)),
    InterestOption('art', 'Art', Icons.palette, Color(0xFFDC2626)),
    InterestOption('gaming', 'Gaming', Icons.sports_esports, Color(0xFF7C3AED)),
    InterestOption('movies', 'Movies', Icons.movie, Color(0xFF059669)),
    InterestOption('sports', 'Sports', Icons.sports_soccer, Color(0xFFEA580C)),
    InterestOption('meditation', 'Meditation', Icons.spa, Color(0xFF0891B2)),
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
    _bioController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onInterestToggled(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        if (_selectedInterests.length < 8) { // Limit to 8 interests
          _selectedInterests.add(interest);
        }
      }
    });
    HapticFeedback.lightImpact();
    _audioService.playChime(ChimeType.selection);
  }

  void _continue() {
    _audioService.playChime(ChimeType.progression);

    // Create updated profile with bio and interests
    final updatedProfile = widget.userProfile.copyWith(
      // Add these fields to onboarding model
      // bio: _bioController.text.trim(),
      // interests: _selectedInterests.toList(),
    );

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            WorkoutTimingScreen(
          userProfile: updatedProfile,
          // Pass additional data for final completion
          additionalData: {
            'bio': _bioController.text.trim(),
            'interests': _selectedInterests.toList(),
            'foodPreferences': widget.foodPreferences ?? {},
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
                          child: const Text(
                            "Tell Us About Yourself",
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
                            "Help others connect with you",
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

                  // Bio Section
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Bio (Optional)",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Write a short description about yourself",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white60,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  GlowingTextField(
                    label: "About me",
                    hint: "I'm passionate about health, sustainability, and living my best life! 🌱",
                    controller: _bioController,
                    maxLines: 3,
                  ),

                  const SizedBox(height: 50),

                  // Interests Section
                  Row(
                    children: [
                      const Text(
                        "Interests",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0x33FFFFFF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${_selectedInterests.length}/8",
                          style: const TextStyle(
                            color: Color(0xFF00FFC6),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Select up to 8 things you're interested in",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white60,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Interests Grid
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _interestOptions.map((option) {
                      final isSelected = _selectedInterests.contains(option.value);
                      final isDisabled = !isSelected && _selectedInterests.length >= 8;

                      return GestureDetector(
                        onTap: isDisabled ? null : () => _onInterestToggled(option.value),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? option.color.withValues(alpha: 0.3)
                                : isDisabled
                                  ? const Color(0x0AFFFFFF)
                                  : const Color(0x1AFFFFFF),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: isSelected
                                  ? option.color
                                  : isDisabled
                                    ? const Color(0x1AFFFFFF)
                                    : const Color(0x33FFFFFF),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                option.icon,
                                size: 16,
                                color: isSelected
                                    ? option.color
                                    : isDisabled
                                      ? Colors.white30
                                      : Colors.white70,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                option.label,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : isDisabled
                                        ? Colors.white30
                                        : Colors.white70,
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w300,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
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
class InterestOption {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const InterestOption(this.value, this.label, this.icon, this.color);
}