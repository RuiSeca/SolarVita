// lib/screens/login/login_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_vitas/utils/translation_helper.dart';
import '../../providers/riverpod/auth_provider.dart';
import '../../widgets/common/lottie_loading_widget.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    final authNotifier = ref.read(authNotifierProvider.notifier);
    bool success;

    if (_isSignUp) {
      success = await authNotifier.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      success = await authNotifier.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }

    if (!success && mounted) {
      final errorMessage = ref.read(authNotifierProvider).errorMessage;
      if (errorMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final success = await authNotifier.signInWithGoogle();

    if (!success && mounted) {
      final errorMessage = ref.read(authNotifierProvider).errorMessage;
      if (errorMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final success = await authNotifier.signInWithApple();

    if (!success && mounted) {
      final errorMessage = ref.read(authNotifierProvider).errorMessage;
      if (errorMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'enter_email_for_reset')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authNotifier = ref.read(authNotifierProvider.notifier);
    final success =
        await authNotifier.sendPasswordResetEmail(_emailController.text.trim());

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'password_reset_sent')),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final errorMessage = ref.read(authNotifierProvider).errorMessage;
      if (errorMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          tr(context, _isSignUp ? 'sign_up' : 'sign_in'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final authState = ref.watch(authNotifierProvider);
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Country Selector (keep existing)
                    Text(
                      tr(context, 'select_country'),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(12),
                        color: theme.cardColor,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tr(context, 'united_kingdom'),
                            style: theme.textTheme.bodyLarge,
                          ),
                          Icon(Icons.arrow_drop_down,
                              color: theme.iconTheme.color),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Social Login Buttons
                    OutlinedButton.icon(
                      onPressed:
                          authState.isLoading ? null : _handleGoogleSignIn,
                      icon: const SizedBox(
                        width: 24,
                        height: 24,
                        child: Image(
                            image: AssetImage('assets/images/google_logo.jpg')),
                      ),
                      label: Text(
                        tr(context, 'continue_google'),
                        style: const TextStyle(color: Colors.black),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Apple Sign-In (iOS only)
                    if (Platform.isIOS)
                      OutlinedButton.icon(
                        onPressed:
                            authState.isLoading ? null : _handleAppleSignIn,
                        icon: const SizedBox(
                          width: 24,
                          height: 24,
                          child: Icon(
                            Icons.apple,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        label: Text(
                          tr(context, 'continue_apple'),
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    if (Platform.isIOS) const SizedBox(height: 16),

                    // Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: theme.dividerColor)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            tr(context, 'or'),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Expanded(child: Divider(color: theme.dividerColor)),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Email Input
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        labelText: tr(context, 'email_address'),
                        labelStyle: theme.textTheme.bodyMedium,
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.primaryColor),
                        ),
                        filled: true,
                        fillColor: theme.cardColor,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr(context, 'email_required');
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return tr(context, 'invalid_email');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Input
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        labelText: tr(context, 'password'),
                        labelStyle: theme.textTheme.bodyMedium,
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.primaryColor),
                        ),
                        filled: true,
                        fillColor: theme.cardColor,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr(context, 'password_required');
                        }
                        if (_isSignUp && value.length < 6) {
                          return tr(context, 'password_too_short');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    // Forgot Password Link (only show when signing in)
                    if (!_isSignUp)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: authState.isLoading
                              ? null
                              : _handleForgotPassword,
                          child: Text(
                            tr(context, 'forgot_password'),
                            style: TextStyle(color: theme.primaryColor),
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Continue Button
                    ElevatedButton(
                      onPressed:
                          authState.isLoading ? null : _handleEmailAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: authState.isLoading
                          ? const LottieLoadingWidget(
                              width: 20,
                              height: 20,
                            )
                          : Text(
                              tr(
                                  context,
                                  _isSignUp
                                      ? 'create_account'
                                      : 'continue_email'),
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Toggle between Sign In/Sign Up
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isSignUp
                              ? tr(context, 'already_have_account')
                              : tr(context, 'dont_have_account'),
                          style: theme.textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: authState.isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _isSignUp = !_isSignUp;
                                  });
                                },
                          child: Text(
                            _isSignUp
                                ? tr(context, 'sign_in')
                                : tr(context, 'sign_up'),
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Terms Text
                    Text(
                      tr(context, 'terms_conditions'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}