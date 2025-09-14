import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

class FloatingGlowingIcon extends StatefulWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const FloatingGlowingIcon({
    super.key,
    required this.icon,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  State<FloatingGlowingIcon> createState() => _FloatingGlowingIconState();
}

class _FloatingGlowingIconState extends State<FloatingGlowingIcon>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _glowController;
  late AnimationController _tapController;

  late Animation<double> _breathingAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _tapAnimation;

  @override
  void initState() {
    super.initState();

    // Breathing pulse for selected state
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Glow intensity controller
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Tap interaction controller
    _tapController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _tapAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeOut),
    );

    // Start animations based on initial state
    if (widget.isSelected) {
      _glowController.forward();
      _breathingController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(FloatingGlowingIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _glowController.forward();
        _breathingController.repeat(reverse: true);
      } else {
        _glowController.reverse();
        _breathingController.stop();
        _breathingController.reset();
      }
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _glowController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  void _handleTap() async {
    HapticFeedback.lightImpact();

    // Quick tap animation
    await _tapController.forward();
    _tapController.reverse();

    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    const glowColor = Color(0xFF00FFC6); // Emerald/teal glow

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _breathingAnimation,
          _glowAnimation,
          _tapAnimation,
        ]),
        builder: (context, child) {
          final currentScale = widget.isSelected
              ? _breathingAnimation.value * _tapAnimation.value
              : _tapAnimation.value;

          return Transform.scale(
            scale: currentScale,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  // Aura glow effect
                  BoxShadow(
                    color: glowColor.withValues(
                      alpha: widget.isSelected ? _glowAnimation.value : 0.3,
                    ),
                    blurRadius: widget.isSelected ? 30.0 : 20.0,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0x14FFFFFF), // rgba(255,255,255,0.08)
                      border: Border.all(
                        color: const Color(0x0DFFFFFF), // Subtle white border
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon at ~60% of circle area
                        Icon(
                          widget.icon,
                          size: 36, // ~60% of 120px circle
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        // Label
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Description for selected items (if space allows)
                        if (widget.isSelected && widget.description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              widget.description,
                              style: const TextStyle(
                                color: Color(0xCCFFFFFF), // Colors.white.withOpacity(0.8)
                                fontSize: 10,
                                fontWeight: FontWeight.w300,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
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