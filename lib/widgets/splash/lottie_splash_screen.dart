import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../utils/translation_helper.dart';

class LottieSplashScreen extends StatefulWidget {
  final VoidCallback? onAnimationEnd;

  const LottieSplashScreen({
    super.key,
    this.onAnimationEnd,
  });

  @override
  State<LottieSplashScreen> createState() => _LottieSplashScreenState();
}

class _LottieSplashScreenState extends State<LottieSplashScreen> {
  bool _hasAnimationEnded = false;

  void _onAnimationComplete() {
    if (!_hasAnimationEnded && mounted) {
      _hasAnimationEnded = true;
      if (widget.onAnimationEnd != null) {
        widget.onAnimationEnd!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1117), // Your splash background color
      body: Stack(
        children: [
          // Lottie animation - always visible, starts immediately
          Center(
            child: Lottie.asset(
              'assets/videos/animation.json',
              fit: BoxFit.contain, // Fit entire animation without cropping
              repeat: false, // Play once
              onLoaded: (composition) {
                if (mounted) {
                  // Schedule completion callback after animation duration
                  Future.delayed(composition.duration, () {
                    _onAnimationComplete();
                  });
                }
              },
            ),
          ),

          // Skip button
          Positioned(
            bottom: 50,
            right: 20,
            child: GestureDetector(
              onTap: _onAnimationComplete,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tr(context, 'skip_button'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
