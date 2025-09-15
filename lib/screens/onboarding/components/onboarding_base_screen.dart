import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/translation_helper.dart';
import '../../../providers/riverpod/auth_provider.dart';
import '../../login/login_screen.dart';

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
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When app goes to background or is closed, clean up incomplete onboarding
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      debugPrint('🔄 App lifecycle changed to: $state - Cleaning up incomplete onboarding');
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
              onPressed: () async {
                await _handleOnboardingExit();
                if (context.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
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

  /// Handles cleanup when user exits onboarding
  Future<void> _handleOnboardingExit() async {
    try {
      // Get the current user (if any)
      final authNotifier = ref.read(authNotifierProvider.notifier);

      // Delete the incomplete user account and any partial data
      await authNotifier.deleteIncompleteAccount();

      debugPrint('🧹 Onboarding exit: Cleaned up incomplete account data');

      // Navigate back to login screen
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('❌ Error during onboarding exit cleanup: $e');
      // Still navigate back even if cleanup fails
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  /// Handles silent cleanup when app goes to background (no navigation)
  Future<void> _handleOnboardingExitSilent() async {
    try {
      // Get the current user (if any)
      final authNotifier = ref.read(authNotifierProvider.notifier);

      // Delete the incomplete user account and any partial data
      await authNotifier.deleteIncompleteAccount();

      debugPrint('🧹 App backgrounded: Cleaned up incomplete onboarding data');
    } catch (e) {
      debugPrint('❌ Error during silent onboarding cleanup: $e');
      // Continue silently - no user interaction needed
    }
  }
}