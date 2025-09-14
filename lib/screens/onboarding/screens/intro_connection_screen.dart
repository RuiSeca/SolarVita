import 'package:flutter/material.dart';
import '../components/audio_reactive_waves.dart';
import '../components/progress_constellation.dart';
import '../services/onboarding_audio_service.dart';
import '../components/animated_waves.dart';
import 'intro_call_to_action_screen.dart';
import 'intro_gateway_screen.dart';

class IntroConnectionScreen extends StatefulWidget {
  const IntroConnectionScreen({super.key});

  @override
  State<IntroConnectionScreen> createState() => _IntroConnectionScreenState();
}

class _IntroConnectionScreenState extends State<IntroConnectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _textController;
  late AnimationController _iconController;
  late Animation<double> _headingAnimation;
  late Animation<double> _subheadingAnimation;
  late Animation<double> _iconAnimation;
  late Animation<double> _iconGlowAnimation;
  
  final OnboardingAudioService _audioService = OnboardingAudioService();

  @override
  void initState() {
    super.initState();
    
    _textController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _iconController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

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

    _iconAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.6, 1.0, curve: Curves.elasticOut),
      ),
    );

    _iconGlowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animations
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _textController.forward();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  void _navigateToNext() {
    // Play progression chime
    _audioService.playChime(ChimeType.progression);
    
    Navigator.of(context).pushReplacement(
      _createCeremonialTransition(const IntroCallToActionScreen()),
    );
  }

  void _navigateBack() {
    // Play progression chime
    _audioService.playChime(ChimeType.progression);
    
    Navigator.of(context).pushReplacement(
      _createCeremonialTransition(const IntroGatewayScreen()),
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
        onTap: _navigateToNext,
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! < 0) {
            // Swipe left to continue
            _navigateToNext();
          } else if (details.primaryVelocity! > 0) {
            // Swipe right to go back
            _navigateBack();
          }
        },
        child: Stack(
          children: [
            // Background Waves (audio-reactive)
            const Positioned.fill(
              child: AudioReactiveWaves(
                intensity: 0.6,
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
                currentStep: 2,
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
                    // Glowing eco icon
                    AnimatedBuilder(
                      animation: Listenable.merge([_iconAnimation, _iconGlowAnimation]),
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _iconAnimation.value,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.1),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha:
                                    0.4 * _iconGlowAnimation.value,
                                  ),
                                  blurRadius: 30 * _iconGlowAnimation.value,
                                  spreadRadius: 10 * _iconGlowAnimation.value,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.eco,
                              size: 50,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // Main Heading
                    AnimatedBuilder(
                      animation: _headingAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 50 * (1 - _headingAnimation.value)),
                          child: Opacity(
                            opacity: _headingAnimation.value,
                            child: const Text(
                              'Connect with the World Around You',
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w200,
                                color: Colors.white,
                                letterSpacing: 1.2,
                                height: 1.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Subheading
                    AnimatedBuilder(
                      animation: _subheadingAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 30 * (1 - _subheadingAnimation.value)),
                          child: Opacity(
                            opacity: _subheadingAnimation.value,
                            child: const Text(
                              'Experience serenity through form and color.',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                                letterSpacing: 0.8,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Navigation indicators
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _subheadingAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _subheadingAnimation.value * 0.7,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 40),
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
                        Padding(
                          padding: const EdgeInsets.only(right: 40),
                          child: Row(
                            children: [
                              const Text(
                                'Continue',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ],
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