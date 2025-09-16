import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth/auth_service.dart';

part 'auth_provider.g.dart';

// Auth service provider (already defined in user_profile_provider.dart but redefined here for clarity)
@riverpod
AuthService authService(Ref ref) {
  return AuthService();
}

// Auth state provider (stream of auth changes)
@riverpod
Stream<User?> authStateChanges(Ref ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
}

// Auth state class to hold complete auth state
class AuthState {
  final User? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({this.user, this.isLoading = false, this.errorMessage});

  AuthState copyWith({User? user, bool? isLoading, String? errorMessage}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isAuthenticated => user != null;
  bool get hasError => errorMessage != null;
}

// Main auth provider using StateNotifier pattern
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() {
    // Listen to auth state changes and update our state accordingly
    final authStateStream = ref.watch(authStateChangesProvider);

    return authStateStream.when(
      data: (user) => AuthState(user: user),
      loading: () => const AuthState(isLoading: true),
      error: (error, _) => AuthState(errorMessage: error.toString()),
    );
  }

  // Sign up with email and password
  Future<bool> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return _executeAuthOperation(() async {
      final authService = ref.read(authServiceProvider);
      await authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      return true;
    });
  }

  // Sign in with email and password
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return _executeAuthOperation(() async {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    });
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    return _executeAuthOperation(() async {
      final authService = ref.read(authServiceProvider);
      final result = await authService.signInWithGoogle();
      return result != null;
    });
  }

  // Sign in with Apple
  Future<bool> signInWithApple() async {
    return _executeAuthOperation(() async {
      final authService = ref.read(authServiceProvider);
      final result = await authService.signInWithApple();
      return result != null;
    });
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    return _executeAuthOperation(() async {
      final authService = ref.read(authServiceProvider);
      await authService.sendPasswordResetEmail(email);
      return true;
    });
  }

  // Sign out
  Future<void> signOut() async {
    await _executeAuthOperation(() async {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
      return true;
    });
  }

  /// Deletes incomplete user account when exiting onboarding
  Future<void> deleteIncompleteAccount() async {
    await _executeAuthOperation(() async {
      final authService = ref.read(authServiceProvider);

      // Delete the current user's Firebase Auth account
      final user = authService.currentUser;
      if (user != null) {
        debugPrint('🧹 Deleting incomplete account for user: ${user.uid}');

        // Delete any partial Firestore documents for this user
        // (you may need to add this method to your auth service)
        await authService.deleteUserData(user.uid);

        // Delete the Firebase Auth account
        await user.delete();

        debugPrint('✅ Successfully deleted incomplete account');
      }

      return true;
    });
  }

  /// Deletes complete user account and all associated data
  Future<void> deleteAccount() async {
    await _executeAuthOperation(() async {
      final authService = ref.read(authServiceProvider);

      // Get the current user
      final user = authService.currentUser;
      if (user != null) {
        debugPrint('🧹 Deleting account for user: ${user.uid}');

        try {
          // IMPORTANT: Clean up Firestore data FIRST while user is still authenticated
          await authService.deleteUserData(user.uid);
          debugPrint('✅ Firestore data cleanup completed');

          // THEN delete the Firebase Auth account
          await user.delete();
          debugPrint('✅ Firebase Auth account deleted');

        } catch (e) {
          debugPrint('❌ Error during account deletion: $e');

          // If Firestore cleanup fails but auth deletion succeeds,
          // we might have orphaned data, but that's better than a broken state
          rethrow;
        }
      } else {
        debugPrint('⚠️ No user found to delete');
      }

      return true;
    });
  }

  // Send email verification
  Future<bool> sendEmailVerification() async {
    return _executeAuthOperation(() async {
      final authService = ref.read(authServiceProvider);
      await authService.sendEmailVerification();
      return true;
    });
  }

  // Reload current user
  Future<void> reloadUser() async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.reloadCurrentUser();

      // The auth state stream will automatically update our state
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  // Helper method to execute auth operations with loading state
  Future<bool> _executeAuthOperation(Future<bool> Function() operation) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final result = await operation();

      // Clear loading state - the auth state stream will update the user
      state = state.copyWith(isLoading: false);

      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  // Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// Convenience providers for common auth data
@riverpod
User? currentUser(Ref ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.user;
}

@riverpod
bool isAuthenticated(Ref ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.isAuthenticated;
}

@riverpod
bool isAuthLoading(Ref ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.isLoading;
}

@riverpod
String? authErrorMessage(Ref ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.errorMessage;
}

@riverpod
bool hasAuthError(Ref ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.hasError;
}

@riverpod
bool isEmailVerified(Ref ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.isEmailVerified;
}

// User properties convenience providers
@riverpod
String? userEmail(Ref ref) {
  final user = ref.watch(currentUserProvider);
  return user?.email;
}

@riverpod
String? userDisplayName(Ref ref) {
  final user = ref.watch(currentUserProvider);
  return user?.displayName;
}

@riverpod
String? userPhotoURL(Ref ref) {
  final user = ref.watch(currentUserProvider);
  return user?.photoURL;
}

@riverpod
String? userUid(Ref ref) {
  final user = ref.watch(currentUserProvider);
  return user?.uid;
}
