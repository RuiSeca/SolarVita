import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/animated_waves.dart';
import '../components/glowing_button.dart';
import '../components/onboarding_base_screen.dart';
import '../models/onboarding_models.dart';
import '../../../utils/translation_helper.dart';
import '../../../theme/app_theme.dart';
import 'bio_interests_screen.dart';

class SustainabilityGoalsOnboardingScreen extends OnboardingBaseScreen {
  final UserProfile userProfile;
  final Map<String, dynamic>? foodPreferences;

  const SustainabilityGoalsOnboardingScreen({
    super.key,
    required this.userProfile,
    this.foodPreferences,
  });

  @override
  ConsumerState<SustainabilityGoalsOnboardingScreen> createState() => _SustainabilityGoalsOnboardingScreenState();
}

class _SustainabilityGoalsOnboardingScreenState extends OnboardingBaseScreenState<SustainabilityGoalsOnboardingScreen>
    with TickerProviderStateMixin {

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Current values - same structure as settings
  final List<String> _selectedSustainabilityGoals = [];
  final List<String> _ecoFriendlyActivities = [];
  String _transportMode = 'walking';

  // Options - matching settings exactly
  final List<String> _sustainabilityGoalOptions = [
    'Reduce Carbon Footprint',
    'Minimize Waste',
    'Use Renewable Energy',
    'Support Local Business',
    'Eco-Friendly Transportation',
    'Sustainable Diet',
    'Water Conservation',
    'Plastic-Free Living',
    'Energy Efficiency',
    'Green Exercise',
  ];

  final List<String> _ecoActivityOptions = [
    'Outdoor Workouts',
    'Cycling',
    'Walking/Hiking',
    'Gardening',
    'Beach Cleanup',
    'Tree Planting',
    'Community Gardens',
    'Eco-Tours',
    'Nature Photography',
    'Wildlife Observation',
  ];

  final List<String> _transportOptions = [
    'walking',
    'cycling',
    'public_transport',
    'carpooling',
    'electric_vehicle',
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(seconds: 20), // Longer duration for continuous animation
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _fadeController.forward();
    // Start continuous particle animation
    _fadeController.repeat();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onContinue() async {
    // Validate selection
    if (_selectedSustainabilityGoals.isEmpty) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'select_at_least_one_goal')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();

    // Prepare sustainability data for passing to next screen
    final sustainabilityData = {
      'sustainability_goals': _selectedSustainabilityGoals,
      'eco_activities': _ecoFriendlyActivities,
      'transport_mode': _transportMode,
    };

    // Merge with existing food preferences
    final combinedData = {
      ...?widget.foodPreferences,
      ...sustainabilityData,
    };

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BioInterestsScreen(
            userProfile: widget.userProfile,
            sustainabilityGoals: combinedData,
          ),
        ),
      );
    }
  }

  @override
  Widget buildScreenContent(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Subtle background waves
          Positioned.fill(
            child: AnimatedWaves(
              intensity: 0.3,
              personality: widget.userProfile.dominantWavePersonality,
            ),
          ),

          // Subtle nature particles
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _fadeController,
              builder: (context, child) {
                return CustomPaint(
                  painter: NatureParticlesPainter(
                    animation: _fadeController.value,
                  ),
                );
              },
            ),
          ),

          SafeArea(
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: 1.0, // Always visible, no fade needed for content
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),

                        // Header (now scrollable)
                        Column(
                          children: [
                            Text(
                              tr(context, 'protect_our_planet'),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              tr(context, 'choose_sustainability_goals'),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                                fontWeight: FontWeight.w300,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Content sections
                        _buildSustainabilityGoalsSection(),
                        const SizedBox(height: 24),
                        _buildEcoActivitiesSection(),
                        const SizedBox(height: 24),
                        _buildTransportModeSection(),
                        const SizedBox(height: 32),

                        // Continue Button (now scrollable)
                        GlowingButton(
                          text: tr(context, 'continue_to_bio'),
                          onPressed: _onContinue,
                          glowIntensity: 0.8,
                          width: double.infinity,
                          height: 56,
                        ),

                        const SizedBox(height: 40), // Bottom padding
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    IconData? icon,
    Color? iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor ?? AppColors.primary, size: 24),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(25),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withAlpha(51),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSustainabilityGoalsSection() {
    return _buildSection(
      title: tr(context, 'sustainability_goals'),
      icon: Icons.eco,
      iconColor: Colors.green[300],
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(context, 'select_sustainability_goals'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _sustainabilityGoalOptions.map((goal) {
                  final isSelected = _selectedSustainabilityGoals.contains(goal);
                  final translationKey = goal.toLowerCase().replaceAll(' ', '_');
                  return FilterChip(
                    selected: isSelected,
                    label: Text(tr(context, translationKey)),
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white.withAlpha(25),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : Colors.white.withAlpha(76),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSustainabilityGoals.add(goal);
                        } else {
                          _selectedSustainabilityGoals.remove(goal);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEcoActivitiesSection() {
    return _buildSection(
      title: tr(context, 'eco_friendly_activities'),
      icon: Icons.nature_people,
      iconColor: Colors.green[400],
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(context, 'select_activities_enjoy'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _ecoActivityOptions.map((activity) {
                  final isSelected = _ecoFriendlyActivities.contains(activity);
                  final translationKey = activity.toLowerCase().replaceAll(' ', '_').replaceAll('/', '_');
                  return FilterChip(
                    selected: isSelected,
                    label: Text(tr(context, translationKey)),
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white.withAlpha(25),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : Colors.white.withAlpha(76),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _ecoFriendlyActivities.add(activity);
                        } else {
                          _ecoFriendlyActivities.remove(activity);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransportModeSection() {
    return _buildSection(
      title: tr(context, 'preferred_transport_mode'),
      icon: Icons.directions_bike,
      iconColor: Colors.blue[300],
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: _transportOptions.map((mode) {
                  final isSelected = _transportMode == mode;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _transportMode = mode;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withAlpha(51) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.white.withAlpha(76),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: isSelected ? AppColors.primary : Colors.white70,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tr(context, mode),
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Custom painter for continuous nature particles
class NatureParticlesPainter extends CustomPainter {
  final double animation;

  NatureParticlesPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.screen;

    // Create more particles for richer effect
    for (int i = 0; i < 20; i++) {
      // Create continuous flowing animation
      final timeOffset = (i * 0.1) % 1.0;
      final progress = (animation + timeOffset) % 1.0;

      // Multiple columns of particles
      final column = i % 5;
      final x = size.width * 0.05 + (size.width * 0.9) * column / 4;

      // Particles flow from bottom to top continuously
      final y = size.height * (1.2 - progress * 1.4); // Start below screen, end above

      // Fade in and out smoothly
      final fadeProgress = progress;
      final opacity = (fadeProgress < 0.1)
          ? fadeProgress * 10 * 0.4 // Fade in
          : (fadeProgress > 0.9)
              ? (1.0 - fadeProgress) * 10 * 0.4 // Fade out
              : 0.4; // Full opacity in middle

      // Varying particle sizes
      final baseSize = 1.5 + (i % 3) * 0.5;
      final sizeVariation = (1.0 + 0.3 * (progress * 2 - 1).abs());
      final particleSize = baseSize * sizeVariation;

      // Color variety with nature theme
      final colors = [
        Colors.green[200]!,
        Colors.green[300]!,
        Colors.blue[200]!,
        Colors.blue[300]!,
        Colors.white.withAlpha(180),
        Colors.teal[200]!,
      ];

      paint.color = colors[i % colors.length].withAlpha((opacity * 255).round());

      // Only draw if particle is visible on screen
      if (y >= -10 && y <= size.height + 10 && opacity > 0.05) {
        canvas.drawCircle(Offset(x, y), particleSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}