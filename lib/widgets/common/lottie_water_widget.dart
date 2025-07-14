import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

class LottieWaterWidget extends StatefulWidget {
  final double? width;
  final double? height;
  final BoxFit? fit;
  final double waterLevel; // 0.0 to 1.0
  final bool isAnimating;
  final VoidCallback? onAnimationComplete;

  const LottieWaterWidget({
    super.key,
    this.width,
    this.height,
    this.fit,
    required this.waterLevel,
    this.isAnimating = false,
    this.onAnimationComplete,
  });

  @override
  State<LottieWaterWidget> createState() => _LottieWaterWidgetState();
}

class _LottieWaterWidgetState extends State<LottieWaterWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;
  late AnimationController _controller4;
  late AnimationController _fillController;
  
  late Animation<double> _animation1;
  late Animation<double> _animation2;
  late Animation<double> _animation3;
  late Animation<double> _animation4;
  late Animation<double> _fillAnimation;
  
  Timer? _timer1;
  Timer? _timer2;
  Timer? _timer3;

  @override
  void initState() {
    super.initState();
    
    // Water level fill animation
    _fillController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fillAnimation = Tween<double>(
      begin: 0.0,
      end: widget.waterLevel,
    ).animate(CurvedAnimation(
      parent: _fillController,
      curve: Curves.easeInOut,
    ));

    // Wave animation controllers - precise rhythmic left-to-right movement
    _controller1 = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1000)
    );
    _animation1 = Tween<double>(begin: 1.0, end: 3.0)
        .animate(CurvedAnimation(parent: _controller1, curve: Curves.easeInOutSine))
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller1.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _controller1.forward();
        }
      });

    _controller2 = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1000)
    );
    _animation2 = Tween<double>(begin: 2.0, end: 4.0)
        .animate(CurvedAnimation(parent: _controller2, curve: Curves.easeInOutSine))
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller2.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _controller2.forward();
        }
      });

    _controller3 = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1000)
    );
    _animation3 = Tween<double>(begin: 3.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller3, curve: Curves.easeInOutSine))
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller3.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _controller3.forward();
        }
      });

    _controller4 = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1000)
    );
    _animation4 = Tween<double>(begin: 4.0, end: 2.0)
        .animate(CurvedAnimation(parent: _controller4, curve: Curves.easeInOutSine))
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller4.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _controller4.forward();
        }
      });

    // Start animations with precise rhythmic timing for left-to-right flow
    _controller1.forward();
    
    _timer1 = Timer(const Duration(milliseconds: 250), () {
      _controller2.forward();
    });
    
    _timer2 = Timer(const Duration(milliseconds: 500), () {
      _controller3.forward();
    });
    
    _timer3 = Timer(const Duration(milliseconds: 750), () {
      _controller4.forward();
    });

    // Set initial water level
    _fillController.value = widget.waterLevel;
  }

  @override
  void didUpdateWidget(LottieWaterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Trigger animation when water level changes
    if (oldWidget.waterLevel != widget.waterLevel) {
      _animateWaterFill(oldWidget.waterLevel, widget.waterLevel);
    }
    
    // Control wave animation speed based on isAnimating
    if (widget.isAnimating && !oldWidget.isAnimating) {
      // Speed up all animations when adding water (faster rhythmic movement)
      _controller1.duration = const Duration(milliseconds: 500);
      _controller2.duration = const Duration(milliseconds: 500);
      _controller3.duration = const Duration(milliseconds: 500);
      _controller4.duration = const Duration(milliseconds: 500);
      
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          // Back to normal rhythmic timing
          _controller1.duration = const Duration(milliseconds: 1000);
          _controller2.duration = const Duration(milliseconds: 1000);
          _controller3.duration = const Duration(milliseconds: 1000);
          _controller4.duration = const Duration(milliseconds: 1000);
          widget.onAnimationComplete?.call();
        }
      });
    }
  }

  void _animateWaterFill(double from, double to) {
    _fillAnimation = Tween<double>(
      begin: from,
      end: to,
    ).animate(CurvedAnimation(
      parent: _fillController,
      curve: Curves.easeInOut,
    ));
    
    _fillController.reset();
    _fillController.forward();
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    _controller4.dispose();
    _fillController.dispose();
    _timer1?.cancel();
    _timer2?.cancel();
    _timer3?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCircular = widget.width == widget.height;
    
    return Container(
      width: widget.width ?? 48,
      height: widget.height ?? 48,
      decoration: BoxDecoration(
        color: Colors.cyan.withValues(alpha: 0.1),
        shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircular ? null : BorderRadius.circular(8),
        border: Border.all(
          color: Colors.cyan.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // Water wave animation
          AnimatedBuilder(
            animation: _fillAnimation,
            builder: (context, child) {
              return ClipRRect(
                borderRadius: isCircular 
                    ? BorderRadius.circular((widget.width ?? 48) / 2)
                    : BorderRadius.circular(6),
                child: RepaintBoundary(
                  child: CustomPaint(
                    size: Size(widget.width ?? 48, widget.height ?? 48),
                    painter: FlowingWaterPainter(
                      waterHeight: _fillAnimation.value,
                      waterColor: Colors.cyan,
                      h1: _animation1.value,
                      h2: _animation2.value,
                      h3: _animation3.value,
                      h4: _animation4.value,
                    ),
                  ),
                ),
              );
            },
          ),
          
        ],
      ),
    );
  }
}

class FlowingWaterPainter extends CustomPainter {
  final double waterHeight;
  final Color waterColor;
  final double h1;
  final double h2;
  final double h3;
  final double h4;

  FlowingWaterPainter({
    required this.waterHeight,
    required this.waterColor,
    required this.h1,
    required this.h2,
    required this.h3,
    required this.h4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waterHeight <= 0) return;
    
    final height = size.height;
    final width = size.width;

    final wavePaint = Paint()
      ..color = waterColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Calculate the water level from bottom (fills upward)
    final waterLevel = height - (height * waterHeight);
    
    // Start from bottom left
    path.moveTo(0, height);
    path.lineTo(0, waterLevel);

    // Create precise rhythmic wave movement across the surface
    final waveAmplitude = 8.0; // Controlled amplitude for smooth waves
    
    // Multiple wave points for smooth left-to-right flow
    final segments = 20;
    for (int i = 0; i <= segments; i++) {
      final x = (width / segments) * i;
      final progress = i / segments;
      
      // Create wave pattern that flows left to right
      double waveOffset = 0;
      
      // Layer multiple wave effects for complex movement
      waveOffset += sin(progress * pi * 2 + h1) * (waveAmplitude / h1);
      waveOffset += sin(progress * pi * 4 + h2) * (waveAmplitude / h2);
      waveOffset += cos(progress * pi * 3 + h3) * (waveAmplitude / h3);
      waveOffset += sin(progress * pi * 6 + h4) * (waveAmplitude / h4);
      
      path.lineTo(x, waterLevel + waveOffset);
    }

    // Complete the path to fill water area
    path.lineTo(width, height);
    path.lineTo(0, height);
    path.close();

    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant FlowingWaterPainter oldDelegate) {
    return oldDelegate.waterHeight != waterHeight ||
        oldDelegate.h1 != h1 ||
        oldDelegate.h2 != h2 ||
        oldDelegate.h3 != h3 ||
        oldDelegate.h4 != h4 ||
        oldDelegate.waterColor != waterColor;
  }
}