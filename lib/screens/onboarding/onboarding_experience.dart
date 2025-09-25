import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'services/onboarding_audio_service.dart';

/// Onboarding experience that guides new users through personalized setup
/// Integrates with the main app's authentication and user profile system
class OnboardingExperience extends StatefulWidget {
  const OnboardingExperience({super.key});

  @override
  State<OnboardingExperience> createState() => _OnboardingExperienceState();
}

class _OnboardingExperienceState extends State<OnboardingExperience> {
  final OnboardingAudioService _audioService = OnboardingAudioService();

  @override
  void initState() {
    super.initState();
    _initializeGlobalAudio();
  }

  void _initializeGlobalAudio() async {
    try {
      debugPrint('🎵 Starting personalized onboarding experience with ambient audio...');
      await _audioService.initialize();
      await _audioService.startAmbientTrack(fadeInDuration: const Duration(seconds: 2));
      debugPrint('🎵 Onboarding audio initialized - creating immersive experience');
    } catch (e) {
      debugPrint('🔇 Global audio initialization failed: $e');
    }
  }

  @override
  void dispose() {
    // Don't dispose audio here - this widget gets disposed during navigation
    // Audio should only be disposed when actually exiting onboarding or app lifecycle changes
    debugPrint('🎵 Onboarding experience disposed - keeping audio service running for other screens');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Go directly to the onboarding experience - no launcher screen
    return const SplashScreen();
  }
}