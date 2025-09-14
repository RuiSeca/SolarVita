import 'package:flutter/material.dart';

class GlowingButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final double glowIntensity;
  final Color? color;
  final double? width;
  final double? height;

  const GlowingButton({
    super.key,
    required this.text,
    this.onPressed,
    this.glowIntensity = 1.0,
    this.color,
    this.width,
    this.height,
  });

  @override
  State<GlowingButton> createState() => _GlowingButtonState();
}

class _GlowingButtonState extends State<GlowingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ?? const Color(0xFF10B981);
    final isEnabled = widget.onPressed != null;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: buttonColor.withValues(alpha: 0.6),
                      blurRadius: 20 * _pulseAnimation.value * widget.glowIntensity,
                      spreadRadius: 5 * _pulseAnimation.value * widget.glowIntensity,
                    ),
                    BoxShadow(
                      color: buttonColor.withValues(alpha: 0.3),
                      blurRadius: 40 * _pulseAnimation.value * widget.glowIntensity,
                      spreadRadius: 10 * _pulseAnimation.value * widget.glowIntensity,
                    ),
                  ]
                : null,
          ),
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isEnabled ? buttonColor : Colors.grey[400],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            child: Text(
              widget.text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      },
    );
  }
}