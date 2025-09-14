import 'package:flutter/material.dart';
import '../components/animated_waves.dart';
import '../components/glowing_text_field.dart';
import '../components/glowing_button.dart';
import 'personal_intent_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _textController;

  bool get _isFormValid =>
      _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    
    _textController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _textController.forward();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    // Simulate login
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                size: 64,
                color: Color(0xFF10B981),
              ),
              const SizedBox(height: 16),
              const Text(
                'Welcome Back!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your journey continues...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              GlowingButton(
                text: 'Continue to Dashboard',
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/dashboard',
                    (route) => false,
                  );
                },
                glowIntensity: 0.8,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createAccount() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const PersonalIntentScreen(),
        transitionDuration: const Duration(milliseconds: 800),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Soft glowing waves
          const Positioned.fill(
            child: AnimatedWaves(
              intensity: 0.5,
              personality: WavePersonality.eco,
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 100),
                  
                  // Welcome back text
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - _textController.value)),
                        child: Opacity(
                          opacity: _textController.value,
                          child: const Text(
                            "Welcome Back",
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w200,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Subtitle
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - _textController.value)),
                        child: Opacity(
                          opacity: _textController.value,
                          child: const Text(
                            "Your journey continues here.",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 80),
                  
                  // Login Form
                  GlowingTextField(
                    label: "Email / Username",
                    hint: "Enter your email or username",
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  
                  GlowingTextField(
                    label: "Password",
                    hint: "Enter your password",
                    controller: _passwordController,
                    obscureText: true,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Login Button
                  GlowingButton(
                    text: "Login",
                    onPressed: _isFormValid ? _login : null,
                    glowIntensity: _isFormValid ? 1.0 : 0.3,
                    width: double.infinity,
                    height: 56,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Create Account Button
                  GestureDetector(
                    onTap: _createAccount,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Center(
                        child: Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}