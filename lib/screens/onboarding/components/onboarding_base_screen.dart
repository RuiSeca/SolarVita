import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/translation_helper.dart';
import '../../../providers/riverpod/auth_provider.dart';
import '../../login/login_screen.dart';
import '../services/onboarding_audio_service.dart';

/// Base widget for all onboarding screens that provides:
/// - Consistent back button behavior with confirmation dialog
/// - Automatic cleanup of incomplete user data on exit
/// - Proper navigation back to login screen
abstract class OnboardingBaseScreen extends ConsumerStatefulWidget {
  const OnboardingBaseScreen({super.key});

  @override
  ConsumerState<OnboardingBaseScreen> createState();
}

abstract class OnboardingBaseScreenState<T extends OnboardingBaseScreen>
    extends ConsumerState<T> with WidgetsBindingObserver {

  final OnboardingAudioService _audioService = OnboardingAudioService();

  /// Override this method to provide the actual screen content
  Widget buildScreenContent(BuildContext context);

  /// Override this to provide custom back button behavior (optional)
  Future<bool> onCustomBackPressed() async {
    return await _showExitConfirmationDialog();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Don't dispose audio service here - it's managed globally by OnboardingExperience
    debugPrint('🎵 OnboardingBaseScreen disposed - keeping audio service for other screens');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When app goes to background or is closed, clean up incomplete onboarding
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      debugPrint('🔄 App lifecycle changed to: $state - Cleaning up incomplete onboarding and stopping audio');
      _handleAudioCleanupForLifecycle();
      _handleOnboardingExitSilent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent default back behavior
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldExit = await onCustomBackPressed();
          if (shouldExit && context.mounted) {
            await _handleOnboardingExit();
          }
        }
      },
      child: buildScreenContent(context),
    );
  }

  /// Shows confirmation dialog when user tries to exit onboarding
  Future<bool> _showExitConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            tr(context, 'exit_onboarding_title'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            tr(context, 'exit_onboarding_message'),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          actions: [
            // Stay button
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                tr(context, 'exit_onboarding_cancel'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
            // Exit button
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                tr(context, 'exit_onboarding_confirm'),
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  /// Handles audio cleanup when app lifecycle changes
  Future<void> _handleAudioCleanupForLifecycle() async {
    try {
      debugPrint('🎵 Stopping ambient audio due to app lifecycle change');
      await _audioService.fadeOutAmbient();
      await _audioService.dispose();
    } catch (e) {
      debugPrint('❌ Error during audio cleanup: $e');
    }
  }

  /// Handles cleanup when user exits onboarding
  Future<void> _handleOnboardingExit() async {
    try {
      // Stop audio first
      debugPrint('🎵 Stopping ambient audio due to onboarding exit');
      await _audioService.fadeOutAmbient();
      await _audioService.dispose();

      // Get the current user (if any)
      final authNotifier = ref.read(authNotifierProvider.notifier);

      // Clear interrupted flag (user is explicitly exiting)
      await _setOnboardingInterrupted(false);

      // Delete the incomplete user account and any partial data
      await authNotifier.deleteIncompleteAccount();

      debugPrint('🧹 Onboarding exit: Cleaned up incomplete account data');

      // Navigate back to login screen safely
      await _navigateToLoginSafely();
    } catch (e) {
      debugPrint('❌ Error during onboarding exit cleanup: $e');
      // Still navigate back even if cleanup fails
      await _navigateToLoginSafely();
    }
  }

  /// Safely navigates to login screen handling potential navigator stack issues
  Future<void> _navigateToLoginSafely() async {
    if (!mounted) return;

    try {
      // Check if we can safely navigate
      final navigator = Navigator.of(context);
      final canPop = navigator.canPop();

      debugPrint('🧭 Navigator canPop: $canPop');

      if (canPop) {
        // If we can pop, use pushAndRemoveUntil
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } else {
        // If we can't pop (empty stack), use pushReplacement or alternative
        navigator.pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      debugPrint('❌ Navigation error: $e');
      // Fallback: try to use the root navigator
      try {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } catch (e2) {
        debugPrint('❌ Root navigation also failed: $e2');
        // Last resort: force app restart by invalidating providers
        ref.invalidate(authNotifierProvider);
      }
    }
  }

  /// Handles silent cleanup when app goes to background (no navigation)
  Future<void> _handleOnboardingExitSilent() async {
    try {
      // Get the current user (if any)
      final authNotifier = ref.read(authNotifierProvider.notifier);

      // Mark that onboarding was interrupted (to prevent auto-resume)
      await _setOnboardingInterrupted(true);

      // Delete the incomplete user account and any partial data
      await authNotifier.deleteIncompleteAccount();

      debugPrint('🧹 App backgrounded: Cleaned up incomplete onboarding data');
    } catch (e) {
      debugPrint('❌ Error during silent onboarding cleanup: $e');
      // Continue silently - no user interaction needed
    }
  }

  /// Mark onboarding as interrupted to prevent auto-resume
  Future<void> _setOnboardingInterrupted(bool interrupted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_interrupted', interrupted);
      debugPrint('🔄 Onboarding interrupted flag set to: $interrupted');
    } catch (e) {
      debugPrint('❌ Error setting onboarding interrupted flag: $e');
    }
  }

  /// Check if onboarding was interrupted during app lifecycle
  static Future<bool> wasOnboardingInterrupted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('onboarding_interrupted') ?? false;
    } catch (e) {
      debugPrint('❌ Error checking onboarding interrupted flag: $e');
      return false;
    }
  }

  /// Clear the onboarding interrupted flag (call when starting fresh onboarding)
  static Future<void> clearOnboardingInterrupted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('onboarding_interrupted');
      debugPrint('🧹 Cleared onboarding interrupted flag');
    } catch (e) {
      debugPrint('❌ Error clearing onboarding interrupted flag: $e');
    }
  }
}