import 'package:flutter/material.dart';

class SimpleWaterWidget extends StatefulWidget {
  final double? width;
  final double? height;
  final BoxFit? fit;
  final double waterLevel; // 0.0 to 1.0
  final bool isAnimating;
  final VoidCallback? onAnimationComplete;

  const SimpleWaterWidget({
    super.key,
    this.width,
    this.height,
    this.fit,
    required this.waterLevel,
    this.isAnimating = false,
    this.onAnimationComplete,
  });

  @override
  State<SimpleWaterWidget> createState() => _SimpleWaterWidgetState();
}

class _SimpleWaterWidgetState extends State<SimpleWaterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    if (widget.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(SimpleWaterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating != oldWidget.isAnimating) {
      if (widget.isAnimating) {
        _controller.repeat();
      } else {
        _controller.stop();
        widget.onAnimationComplete?.call();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width ?? 48,
      height: widget.height ?? 48,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.cyan, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: WaterPainter(
              waterLevel: widget.waterLevel,
              animationValue: _animation.value,
            ),
            size: Size(widget.width ?? 48, widget.height ?? 48),
          );
        },
      ),
    );
  }
}

class WaterPainter extends CustomPainter {
  final double waterLevel;
  final double animationValue;

  WaterPainter({required this.waterLevel, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final waterHeight = size.height * waterLevel;
    final rect = Rect.fromLTWH(
      0,
      size.height - waterHeight,
      size.width,
      waterHeight,
    );

    canvas.drawRect(rect, paint);

    // Add wave effect if animating
    if (animationValue > 0) {
      final wavePaint = Paint()
        ..color = Colors.cyan
        ..style = PaintingStyle.fill;

      final path = Path();
      path.moveTo(0, size.height - waterHeight);

      for (double i = 0; i <= size.width; i++) {
        final waveHeight = 3 * 
            (1 + 0.5 * (animationValue * 2 - 1).abs()) *
            (i / size.width < 0.5 ? (i / size.width) * 2 : (1 - i / size.width) * 2);
        path.lineTo(i, size.height - waterHeight + waveHeight);
      }

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}