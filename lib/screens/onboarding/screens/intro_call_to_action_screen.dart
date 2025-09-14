import 'package:flutter/material.dart';
import '../components/audio_reactive_waves.dart';
import '../components/progress_constellation.dart';
import '../components/glowing_button.dart';
import '../services/onboarding_audio_service.dart';
import '../components/animated_waves.dart';
import 'personal_intent_screen.dart';
import 'intro_connection_screen.dart';

class IntroCallToActionScreen extends StatefulWidget {
  const IntroCallToActionScreen({super.key});

  @override
  State<IntroCallToActionScreen> createState() => _IntroCallToActionScreenState();
}

class _IntroCallToActionScreenState extends State<IntroCallToActionScreen>
    with TickerProviderStateMixin {
  late AnimationController _textController;
  late AnimationController _buttonController;
  late Animation<double> _headingAnimation;
  late Animation<double> _buttonAnimation;
  
  final OnboardingAudioService _audioService = OnboardingAudioService();

  @override
  void initState() {
    super.initState();
    
    _textController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _headingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOut,
      ),
    );

    _buttonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonController,
        curve: Curves.elasticOut,
      ),
    );

    // Start animations
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _textController.forward();
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) _buttonController.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _navigateToNext() {
    // Play commitment chime for this important transition
    _audioService.playChime(ChimeType.commitment);
    
    Navigator.of(context).pushReplacement(
      _createCeremonialTransition(const PersonalIntentScreen()),
    );
  }

  void _navigateBack() {
    // Play progression chime
    _audioService.playChime(ChimeType.progression);
    
    Navigator.of(context).pushReplacement(
      _createCeremonialTransition(const IntroConnectionScreen()),
    );
  }

  PageRouteBuilder _createCeremonialTransition(Widget child) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => child,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            // Swipe right to go back
            _navigateBack();
          }
        },
        child: Stack(
          children: [
            // Background Waves (audio-reactive and alive)
            const Positioned.fill(
              child: AudioReactiveWaves(
                intensity: 0.9,
                personality: WavePersonality.eco,
                enableAudioReactivity: true,
              ),
            ),
            
            // Progress Constellation
            const Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: ProgressConstellation(
                currentStep: 3,
                totalSteps: 7,
              ),
            ),
            
            // Main Content
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Main Heading
                    AnimatedBuilder(
                      animation: _headingAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 50 * (1 - _headingAnimation.value)),
                          child: Opacity(
                            opacity: _headingAnimation.value,
                            child: const Text(
                              'Begin Your Journey',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w200,
                                color: Colors.white,
                                letterSpacing: 1.8,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 80),
                    
                    // Glowing CTA Button
                    AnimatedBuilder(
                      animation: _buttonAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _buttonAnimation.value,
                          child: GlowingButton(
                            text: 'Get Started',
                            onPressed: _navigateToNext,
                            glowIntensity: 1.0,
                            width: 200,
                            height: 60,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Back navigation
            Positioned(
              bottom: 60,
              left: 40,
              child: AnimatedBuilder(
                animation: _headingAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _headingAnimation.value * 0.7,
                    child: GestureDetector(
                      onTap: _navigateBack,
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Back',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}