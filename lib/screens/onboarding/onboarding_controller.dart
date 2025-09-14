import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/onboarding_models.dart';
import 'components/animated_waves.dart';

class OnboardingController {
  static const String _firstLaunchKey = 'firstLaunch';
  static const String _hasAccountKey = 'hasAccount';
  static const String _userProfileKey = 'userProfile';

  /// Check if this is the first launch of the app
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstLaunchKey) ?? true;
  }

  /// Mark the first launch as completed
  static Future<void> completeFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, false);
  }

  /// Check if user has an account
  static Future<bool> hasAccount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasAccountKey) ?? false;
  }

  /// Mark that user has created an account
  static Future<void> setHasAccount(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasAccountKey, value);
  }

  /// Save user profile (simplified for demo)
  static Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    // In a real app, you'd serialize the UserProfile to JSON
    await prefs.setString(_userProfileKey, profile.name);
    await setHasAccount(true);
    await completeFirstLaunch();
  }

  /// Get the appropriate starting route based on user state
  static Future<String> getStartingRoute() async {
    final isFirst = await isFirstLaunch();
    final hasAcc = await hasAccount();

    if (isFirst) {
      return '/onboarding/gateway';
    } else if (hasAcc) {
      return '/dashboard';
    } else {
      return '/onboarding/login';
    }
  }

  /// Create a ceremonial page transition
  static PageRouteBuilder createCeremonialTransition(Widget child, {
    Duration duration = const Duration(milliseconds: 800),
    Curve curve = Curves.easeInOut,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: curve,
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.1, 0),
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

  /// Generate a personalized goal based on user's intents
  static String generatePersonalizedGoal(UserProfile profile) {
    final intents = profile.selectedIntents;
    final name = profile.displayName;

    if (intents.contains(IntentType.eco) && intents.contains(IntentType.fitness)) {
      return "Hi $name! Let's start with 10 minutes of outdoor exercise daily while tracking your carbon footprint.";
    } else if (intents.contains(IntentType.mindfulness)) {
      return "Welcome $name! Your journey begins with 5 minutes of mindful breathing each morning.";
    } else if (intents.contains(IntentType.community)) {
      return "Ready $name? Let's connect you with like-minded individuals on your wellness journey.";
    } else if (intents.contains(IntentType.adventure)) {
      return "Hey $name! Time to explore the great outdoors and discover new adventures.";
    } else {
      return "Ready $name? Let's take the first step toward your wellness goals together.";
    }
  }

  /// Get the dominant color for wave personality
  static Color getDominantColor(WavePersonality personality) {
    switch (personality) {
      case WavePersonality.eco:
        return const Color(0xFF10B981);
      case WavePersonality.fitness:
        return const Color(0xFF3B82F6);
      case WavePersonality.wellness:
        return const Color(0xFF14B8A6);
      case WavePersonality.community:
        return const Color(0xFFEC4899);
      case WavePersonality.mindfulness:
        return const Color(0xFF8B5CF6);
      case WavePersonality.adventure:
        return const Color(0xFFF59E0B);
    }
  }
}