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

class _LottieSplashScreenState extends State<LottieSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _hasAnimationEnded = false;
  bool _isLottieLoaded = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
  }

  void _onAnimationComplete() {
    if (!_hasAnimationEnded && mounted) {
      _hasAnimationEnded = true;
      _fadeController.reverse().then((_) {
        if (mounted && widget.onAnimationEnd != null) {
          widget.onAnimationEnd!();
        }
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161f25), // Your splash background color
      body: Stack(
        children: [
          // Show logo immediately while Lottie loads
          if (!_isLottieLoaded)
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                width: 150,
                height: 150,
              ),
            ),

          // Lottie animation - cover entire screen
          if (_isLottieLoaded)
            FadeTransition(
              opacity: _fadeAnimation,
              child: SizedBox.expand(
                child: Lottie.asset(
                  'assets/videos/animation.json',
                  fit: BoxFit.cover, // Cover entire screen
                  repeat: false, // Play once
                  onLoaded: (composition) {
                    if (mounted) {
                      setState(() {
                        _isLottieLoaded = true;
                      });
                      _fadeController.forward();

                      // Schedule completion callback after animation duration
                      Future.delayed(composition.duration, () {
                        _onAnimationComplete();
                      });
                    }
                  },
                ),
              ),
            )
          else
            // Invisible Lottie to start loading immediately
            Opacity(
              opacity: 0.0,
              child: Lottie.asset(
                'assets/videos/animation.json',
                onLoaded: (composition) {
                  if (mounted) {
                    setState(() {
                      _isLottieLoaded = true;
                    });
                    _fadeController.forward();

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
