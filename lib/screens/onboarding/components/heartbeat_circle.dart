import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HeartbeatCircle extends StatefulWidget {
  final VoidCallback onComplete;
  final String text;
  final Color? color;

  const HeartbeatCircle({
    super.key,
    required this.onComplete,
    this.text = "Let's Go",
    this.color,
  });

  @override
  State<HeartbeatCircle> createState() => _HeartbeatCircleState();
}

class _HeartbeatCircleState extends State<HeartbeatCircle>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _expandController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _expandAnimation;
  late Animation<double> _opacityAnimation;

  bool _isExpanding = false;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _expandController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _expandAnimation = Tween<double>(begin: 1.0, end: 15.0).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _expandController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  void _startExpansion() {
    if (_isExpanding) return;
    
    setState(() => _isExpanding = true);
    _pulseController.stop();
    HapticFeedback.mediumImpact();
    
    _expandController.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    final circleColor = widget.color ?? const Color(0xFF10B981);

    return GestureDetector(
      onTap: _isExpanding ? null : _startExpansion,
      child: AnimatedBuilder(
        animation: _isExpanding 
            ? Listenable.merge([_expandAnimation, _opacityAnimation])
            : _pulseAnimation,
        builder: (context, child) {
          final scale = _isExpanding ? _expandAnimation.value : _pulseAnimation.value;
          final opacity = _isExpanding ? _opacityAnimation.value : 1.0;

          return Transform.scale(
            scale: scale,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    circleColor.withValues(alpha: opacity),
                    circleColor.withValues(alpha: opacity * 0.3),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: circleColor.withValues(alpha: 0.5 * opacity),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                  BoxShadow(
                    color: circleColor.withValues(alpha: 0.3 * opacity),
                    blurRadius: 60,
                    spreadRadius: 20,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: opacity),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}