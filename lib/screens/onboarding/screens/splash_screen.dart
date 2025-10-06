import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';
import '../models/audio_preference.dart';
import 'audio_preference_screen.dart';
import 'intro_gateway_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    _startSplashSequence();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startSplashSequence() async {
    // Start the logo animation
    _controller.forward();

    // Wait for animation to complete, then check user status
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      await _checkUserStatus();
    }
  }

  Future<void> _checkUserStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final firstLaunch = prefs.getBool('firstLaunch') ?? true;

    if (mounted) {
      if (firstLaunch) {
        // First time user - check if audio preference has been set
        final hasAudioPreference = await AudioPreferences.hasSetPreference();

        if (!hasAudioPreference) {
          // New user, no audio preference set - go to audio preference screen
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AudioPreferenceScreen()),
            );
          }
        } else {
          // Audio preference already set - go to intro ceremony
          if (mounted) {
            Navigator.of(context).pushReplacement(
              _createCeremonialTransition(const IntroGatewayScreen()),
            );
          }
        }
      } else {
        // Returning user - check if they're in an onboarding context
        // If this SplashScreen is being shown, it's likely because onboarding is incomplete
        // Check if audio preference needs to be set
        final hasAudioPreference = await AudioPreferences.hasSetPreference();

        if (!hasAudioPreference) {
          // Returning user but no audio preference - show audio preference screen
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AudioPreferenceScreen()),
            );
          }
        } else {
          // Returning user with audio preference - continue to onboarding
          if (mounted) {
            Navigator.of(context).pushReplacement(
              _createCeremonialTransition(const IntroGatewayScreen()),
            );
          }
        }
      }
    }
  }

  PageRouteBuilder _createCeremonialTransition(Widget child) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: const Duration(milliseconds: 1200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1117),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  const Color(0xFF1a2433).withValues(alpha: 0.3 * _glowAnimation.value),
                  const Color(0xFF0d1117),
                  const Color(0xFF0d1117),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with glow effect
                  AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha:
                                0.3 * _glowAnimation.value,
                              ),
                              blurRadius: 40 * _glowAnimation.value,
                              spreadRadius: 10 * _glowAnimation.value,
                            ),
                          ],
                        ),
                        child: Transform.scale(
                          scale: _logoAnimation.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryColor,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.wb_sunny,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // App name with fade-in
                  Opacity(
                    opacity: _logoAnimation.value,
                    child: Text(
                      'SolarVita',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.primaryColor,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Tagline with delayed fade-in
                  Opacity(
                    opacity: _glowAnimation.value,
                    child: Text(
                      tr(context, 'app_tagline'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}