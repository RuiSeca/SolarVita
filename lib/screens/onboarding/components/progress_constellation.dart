import 'package:flutter/material.dart';

class ProgressConstellation extends StatefulWidget {
  final int currentStep;
  final int totalSteps;

  const ProgressConstellation({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  State<ProgressConstellation> createState() => _ProgressConstellationState();
}

class _ProgressConstellationState extends State<ProgressConstellation>
    with TickerProviderStateMixin {
  late List<AnimationController> _starControllers;
  late List<Animation<double>> _starAnimations;

  @override
  void initState() {
    super.initState();
    _starControllers = List.generate(
      widget.totalSteps,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _starAnimations = _starControllers
        .map((controller) => Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: controller, curve: Curves.elasticOut),
            ))
        .toList();

    // Animate stars up to current step
    _animateStars();
  }

  @override
  void didUpdateWidget(ProgressConstellation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentStep != oldWidget.currentStep) {
      _animateStars();
    }
  }

  void _animateStars() {
    for (int i = 0; i < widget.currentStep && i < _starControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _starControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _starControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.totalSteps, (index) {
          return AnimatedBuilder(
            animation: _starAnimations[index],
            builder: (context, child) {
              final isActive = index < widget.currentStep;
              final scale = isActive ? _starAnimations[index].value : 0.3;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.8),
                                blurRadius: 15 * _starAnimations[index].value,
                                spreadRadius: 3 * _starAnimations[index].value,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}