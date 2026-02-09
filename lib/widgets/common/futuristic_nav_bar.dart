import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

/// Futuristic navigation bar with PULSE AI mascot
class FuturisticNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String? userId; // For loading user's avatar

  const FuturisticNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.userId,
  });

  @override
  State<FuturisticNavBar> createState() => _FuturisticNavBarState();
}

class _FuturisticNavBarState extends State<FuturisticNavBar>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _borderRotationController;
  late Animation<double> _pulseAnimation;
  
  final List<AnimationController> _tapControllers = [];
  final List<Animation<double>> _tapAnimations = [];

  @override
  void initState() {
    super.initState();
    
    // PULSE mascot breathing animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Gradient border rotation (slow, continuous)
    _borderRotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    // Create tap animation controllers for each nav item (5 items)
    for (int i = 0; i < 5; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      );
      _tapControllers.add(controller);
      
      _tapAnimations.add(
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 0.95)
                .chain(CurveTween(curve: Curves.easeOut)),
            weight: 50,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.95, end: 1.05)
                .chain(CurveTween(curve: Curves.easeOut)),
            weight: 50,
          ),
        ]).animate(controller),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _borderRotationController.dispose();
    for (var controller in _tapControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleTap(int index) {
    HapticFeedback.lightImpact();
    
    // Animate the tapped item
    _tapControllers[index].forward().then((_) {
      _tapControllers[index].reverse();
    });
    
    // Special bounce for PULSE mascot (center item, index 2)
    if (index == 2) {
      _pulseController.forward(from: 0.0);
    }
    
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);
    
    return SizedBox(
      height: 100, // Increased to accommodate elevated mascot
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Bottom nav bar with curved notch
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              painter: NavBarCurvePainter(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                shadowColor: Colors.black.withOpacity(0.1),
              ),
              child: ClipPath(
                clipper: NavBarCurveClipper(),
                child: Container(
                  height: 100, // Increased height to allow icons to sit lower
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 40, 16, 0), // Push icons down below the curve
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNavItem(
                            index: 0,
                            icon: Icons.dashboard_outlined,
                            activeIcon: Icons.dashboard,
                            label: 'Dashboard',
                          ),
                          _buildNavItem(
                            index: 1,
                            icon: Icons.search,
                            activeIcon: Icons.search,
                            label: 'Search',
                          ),
                          // Spacer for center mascot
                          const SizedBox(width: 80),
                          _buildNavItem(
                            index: 3,
                            icon: Icons.favorite_outline,
                            activeIcon: Icons.favorite,
                            label: 'Health',
                          ),
                          _buildNavItem(
                            index: 4,
                            icon: Icons.person_outline,
                            activeIcon: Icons.person,
                            label: 'Profile',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Elevated PULSE mascot (positioned above the nav bar)
          Positioned(
            bottom: 15, // Position for the mascot
            child: _buildPulseMascot(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = widget.currentIndex == index;
    
    return GestureDetector(
      onTap: () => _handleTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _tapAnimations[index],
        builder: (context, child) {
          return Transform.scale(
            scale: _tapAnimations[index].value,
            child: Container(
              width: 60,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: Icon(
                      isActive ? activeIcon : icon,
                      size: 24,
                      color: isActive
                          ? AppColors.navIconActive
                          : AppColors.navIconInactive,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? AppColors.navIconActive
                          : AppColors.navIconInactive,
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

  Widget _buildPulseMascot() {
    return GestureDetector(
      onTap: () => _handleTap(2), // Index 2 is PULSE
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _tapAnimations[2]]),
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value * _tapAnimations[2].value,
            child: SizedBox(
              width: 60,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // PULSE mascot with gradient border
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: AnimatedBuilder(
                      animation: _borderRotationController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: PulseMascotPainter(
                            rotationAngle: _borderRotationController.value * 2 * math.pi,
                            eyeGlowOpacity: 0.8 + (_pulseAnimation.value - 1.0) * 10,
                          ),
                          child: Center(
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.asset(
                                'assets/images/pulse_mascot.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback to icon if image not found
                                  return Container(
                                    color: AppColors.pulseMascotBg,
                                    child: Icon(
                                      Icons.psychology_outlined,
                                      color: AppColors.pulseGradientStart,
                                      size: 28,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PULSE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: widget.currentIndex == 2
                          ? AppColors.navIconActive
                          : AppColors.navIconInactive,
                      letterSpacing: 0.5,
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

/// Custom painter for PULSE mascot with gradient border and glowing eyes
class PulseMascotPainter extends CustomPainter {
  final double rotationAngle;
  final double eyeGlowOpacity;

  PulseMascotPainter({
    required this.rotationAngle,
    required this.eyeGlowOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw gradient border
    final rect = Rect.fromCircle(center: center, radius: radius);
    
    final gradientPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          AppColors.pulseGradientStart,
          AppColors.pulseGradientEnd,
          AppColors.pulseGradientStart,
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(rotationAngle),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(center, radius - 2, gradientPaint);
    
    // Note: Eye glow removed since the mascot image has its own glowing eyes
  }

  @override
  bool shouldRepaint(PulseMascotPainter oldDelegate) {
    return oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.eyeGlowOpacity != eyeGlowOpacity;
  }
}

/// Custom clipper for the curved notch in the navigation bar
class NavBarCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    // Mountain effect parameters
    final top = 0.0; // Back to full peak
    final curveStartTop = 35.0;
    final curveDistance = 65.0; // Slightly wider than 55 for smoothness, safe with padding
    
    // Start from top-left of flat part
    path.moveTo(0, curveStartTop);
    
    // Line to start of mountain slope
    path.lineTo(centerX - curveDistance, curveStartTop);
    
    // Left slope (smooth S-curve up)
    path.cubicTo(
      centerX - curveDistance * 0.5, curveStartTop, // Control 1: flat departure
      centerX - curveDistance * 0.4, top,           // Control 2: steep rise
      centerX, top                                  // Peak
    );
    
    // Right slope (smooth S-curve down)
    path.cubicTo(
      centerX + curveDistance * 0.4, top,           // Control 1: steep descent
      centerX + curveDistance * 0.5, curveStartTop, // Control 2: flat arrival
      centerX + curveDistance, curveStartTop        // End
    );
    
    // Line to top-right
    path.lineTo(size.width, curveStartTop);
    
    // Box corners
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Custom painter to draw the shadow for the curved nav bar
class NavBarCurvePainter extends CustomPainter {
  final Color color;
  final Color shadowColor;

  NavBarCurvePainter({
    required this.color,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    // Mountain effect parameters (MUST match Clipper)
    final top = 0.0;
    final curveStartTop = 35.0;
    final curveDistance = 65.0;
    
    final path = Path();
    path.moveTo(0, curveStartTop);
    path.lineTo(centerX - curveDistance, curveStartTop);
    
    path.cubicTo(
      centerX - curveDistance * 0.5, curveStartTop,
      centerX - curveDistance * 0.4, top,
      centerX, top
    );
    
    path.cubicTo(
      centerX + curveDistance * 0.4, top,
      centerX + curveDistance * 0.5, curveStartTop,
      centerX + curveDistance, curveStartTop
    );
    
    path.lineTo(size.width, curveStartTop);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Draw shadow
    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path.shift(const Offset(0, -2)), shadowPaint);

    // Draw fill
    final fillPaint = Paint()..color = color;
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(NavBarCurvePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.shadowColor != shadowColor;
  }
}
