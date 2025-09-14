import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/animated_waves.dart';
import '../components/glowing_button.dart';
import '../services/onboarding_audio_service.dart';
import '../models/onboarding_models.dart';
import '../../../providers/riverpod/user_profile_provider.dart';

class OnboardingCompletionScreen extends ConsumerStatefulWidget {
  final UserProfile userProfile;

  const OnboardingCompletionScreen({
    super.key,
    required this.userProfile,
  });

  @override
  ConsumerState<OnboardingCompletionScreen> createState() => _OnboardingCompletionScreenState();
}

class _OnboardingCompletionScreenState extends ConsumerState<OnboardingCompletionScreen>
    with TickerProviderStateMixin {
  final OnboardingAudioService _audioService = OnboardingAudioService();

  late AnimationController _celebrationController;
  late AnimationController _textController;
  late AnimationController _buttonController;

  late Animation<double> _logoAnimation;
  late Animation<double> _titleAnimation;
  late Animation<double> _subtitleAnimation;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();

    _celebrationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );

    _titleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _subtitleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );

    _buttonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonController,
        curve: Curves.elasticOut,
      ),
    );

    _startCelebrationSequence();
  }

  void _startCelebrationSequence() async {
    // Start logo animation
    _celebrationController.forward();

    // Wait a bit, then start text animations
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      _textController.forward();
      HapticFeedback.mediumImpact();
    }

    // Wait for text, then show button
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      _buttonController.forward();
    }
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _textController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _completeOnboarding() async {
    _audioService.playChime(ChimeType.commitment);
    HapticFeedback.heavyImpact();

    // Mark onboarding as completed in the user profile
    final userProfileNotifier = ref.read(userProfileNotifierProvider.notifier);
    await userProfileNotifier.completeOnboarding();

    // Stop and dispose audio before leaving onboarding
    await _audioService.fadeOutAmbient();
    await _audioService.dispose();

    // Navigate to main app - remove all onboarding routes
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Maximum intensity celebratory waves
          Positioned.fill(
            child: AnimatedWaves(
              intensity: 1.0,
              personality: widget.userProfile.dominantWavePersonality,
            ),
          ),

          // Celebration Particles Effect Overlay
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _celebrationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: CelebrationParticlesPainter(
                    animation: _celebrationController.value,
                  ),
                );
              },
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Success Icon
                  AnimatedBuilder(
                    animation: _logoAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF10B981),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.5),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 60),

                  // Title
                  AnimatedBuilder(
                    animation: _titleAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - _titleAnimation.value)),
                        child: Opacity(
                          opacity: _titleAnimation.value,
                          child: const Text(
                            "Welcome to Your\nFitness Journey!",
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                              letterSpacing: 1.2,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Subtitle
                  AnimatedBuilder(
                    animation: _subtitleAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - _subtitleAnimation.value)),
                        child: Opacity(
                          opacity: _subtitleAnimation.value,
                          child: const Text(
                            "Your personalized fitness experience is ready.\nLet's start building healthy habits together!",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              fontWeight: FontWeight.w300,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),

                  const Spacer(flex: 3),

                  // Start Journey Button
                  AnimatedBuilder(
                    animation: _buttonAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _buttonAnimation.value,
                        child: GlowingButton(
                          text: "Start Your Journey",
                          onPressed: _completeOnboarding,
                          glowIntensity: 1.0,
                          width: double.infinity,
                          height: 64,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Small encouragement text
                  AnimatedBuilder(
                    animation: _subtitleAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _subtitleAnimation.value * 0.7,
                        child: const Text(
                          "Every journey begins with a single step",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white60,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for celebration particles
class CelebrationParticlesPainter extends CustomPainter {
  final double animation;

  CelebrationParticlesPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.screen;

    // Create floating celebration particles
    for (int i = 0; i < 20; i++) {
      final progress = (animation + i * 0.1) % 1.0;
      final x = size.width * 0.1 + (size.width * 0.8) * (i % 5) / 4;
      final y = size.height * (1 - progress);

      final opacity = (1 - progress) * 0.6;
      final particleSize = 4.0 + progress * 8;

      paint.color = [
        const Color(0xFF10B981),
        const Color(0xFF3B82F6),
        const Color(0xFF8B5CF6),
        const Color(0xFFF59E0B),
        const Color(0xFFEC4899),
      ][i % 5].withValues(alpha: opacity);

      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}