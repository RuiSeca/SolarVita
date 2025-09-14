import 'package:flutter/material.dart';
import '../components/audio_reactive_waves.dart';
import '../components/progress_constellation.dart';
import '../services/onboarding_audio_service.dart';
import '../components/animated_waves.dart';
import 'intro_connection_screen.dart';

class IntroGatewayScreen extends StatefulWidget {
  const IntroGatewayScreen({super.key});

  @override
  State<IntroGatewayScreen> createState() => _IntroGatewayScreenState();
}

class _IntroGatewayScreenState extends State<IntroGatewayScreen>
    with TickerProviderStateMixin {
  late AnimationController _textController;
  late Animation<double> _headingAnimation;
  late Animation<double> _subheadingAnimation;

  final OnboardingAudioService _audioService = OnboardingAudioService();

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

    // Start text animations immediately (no audio delay)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _textController.forward();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _navigateToNext() {
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

  Future<bool> _onWillPop() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(
              color: Color(0xFF10B981),
              width: 1,
            ),
          ),
          title: const Text(
            'Exit Onboarding Experience?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            'Are you sure you want to return to the login screen? Your onboarding progress will be lost.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Continue Experience',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                // Stop and dispose audio when exiting
                await _audioService.fadeOutAmbient();
                await _audioService.dispose();
                if (mounted) {
                  navigator.pop(true);
                }
              },
              child: const Text(
                'Exit to Login',
                style: TextStyle(
                  color: Colors.white60,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (!didPop && mounted) {
          final navigator = Navigator.of(context);
          final bool shouldExit = await _onWillPop();
          if (shouldExit && mounted) {
            // User chose to exit - navigate to login
            navigator.pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
          }
        }
      },
      child: Scaffold(
      body: GestureDetector(
        onTap: _navigateToNext,
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! < 0) {
            // Swipe left to continue
            _navigateToNext();
          }
        },
        child: Stack(
          children: [
            // Background Waves (subtle, audio-reactive)
            const Positioned.fill(
              child: AudioReactiveWaves(
                intensity: 0.3,
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
                currentStep: 1,
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
                              'Discover a New Way',
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w200,
                                color: Colors.white,
                                letterSpacing: 1.5,
                                height: 1.2,
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
                              'A journey of light and form awaits.',
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
            
            // Swipe indicator
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Swipe to continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 0.5,
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
    ),
    );
  }
}