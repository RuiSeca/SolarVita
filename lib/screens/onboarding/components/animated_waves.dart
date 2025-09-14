import 'package:flutter/material.dart';
import 'dart:math';

enum WavePersonality { eco, fitness, wellness, community, mindfulness, adventure }

class AnimatedWaves extends StatefulWidget {
  final double intensity;
  final WavePersonality personality;
  final AnimationController? animationController;

  const AnimatedWaves({
    super.key,
    required this.intensity,
    this.personality = WavePersonality.eco,
    this.animationController,
  });

  @override
  State<AnimatedWaves> createState() => _AnimatedWavesState();
}

class _AnimatedWavesState extends State<AnimatedWaves>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = widget.animationController ??
        AnimationController(
          duration: const Duration(seconds: 4),
          vsync: this,
        );
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear)
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    if (widget.animationController == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: OrganicWavePainter(
            animationValue: _animation.value,
            intensity: widget.intensity,
            personality: widget.personality,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class OrganicWavePainter extends CustomPainter {
  final double animationValue;
  final double intensity;
  final WavePersonality personality;

  OrganicWavePainter({
    required this.animationValue,
    required this.intensity,
    required this.personality,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final waveLayers = [
      WaveLayer(frequency: 0.015, amplitude: 40, phase: 0, speed: 1.0),
      WaveLayer(frequency: 0.022, amplitude: 25, phase: pi / 3, speed: 0.7),
      WaveLayer(frequency: 0.008, amplitude: 60, phase: pi / 2, speed: 1.3),
      WaveLayer(frequency: 0.035, amplitude: 15, phase: pi, speed: 0.5),
    ];

    for (int layerIndex = 0; layerIndex < waveLayers.length; layerIndex++) {
      final layer = waveLayers[layerIndex];
      final gradient = _createPersonalizedGradient(layerIndex, size);
      final paint = Paint()
        ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      final path = Path();
      final baseHeight = size.height - (30 * intensity);

      path.moveTo(0, size.height);

      for (double x = 0; x <= size.width; x += 3) {
        // Use time-based continuous wave calculation for seamless looping
        final time = DateTime.now().millisecondsSinceEpoch / 1000.0;

        final primaryWave = sin((time * layer.speed) + (x * layer.frequency) + layer.phase) *
            layer.amplitude;

        final secondaryWave = sin((time * layer.speed * 1.5) + (x * layer.frequency * 1.5) + layer.phase + pi/6) *
            (layer.amplitude * 0.3);

        final tertiaryWave = sin((time * layer.speed * 0.8) + (x * layer.frequency * 0.7) + layer.phase + pi/3) *
            (layer.amplitude * 0.5);

        final y = baseHeight + primaryWave + secondaryWave + tertiaryWave;
        path.lineTo(x, y * intensity + ((1 - intensity) * size.height));
      }

      path.lineTo(size.width, size.height);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  LinearGradient _createPersonalizedGradient(int layerIndex, Size size) {
    final opacity1 = 0.6 - layerIndex * 0.15;
    final opacity2 = 0.4 - layerIndex * 0.1;
    final opacity3 = 0.2 - layerIndex * 0.05;

    switch (personality) {
      case WavePersonality.eco:
        return LinearGradient(
          colors: [
            const Color(0xFF34D399).withValues(alpha: opacity1),
            const Color(0xFF10B981).withValues(alpha: opacity2),
            const Color(0xFF059669).withValues(alpha: opacity3),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case WavePersonality.fitness:
        return LinearGradient(
          colors: [
            const Color(0xFF3B82F6).withValues(alpha: opacity1),
            const Color(0xFF1D4ED8).withValues(alpha: opacity2),
            const Color(0xFF1E40AF).withValues(alpha: opacity3),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case WavePersonality.wellness:
        return LinearGradient(
          colors: [
            const Color(0xFF14B8A6).withValues(alpha: opacity1),
            const Color(0xFF0F766E).withValues(alpha: opacity2),
            const Color(0xFF134E4A).withValues(alpha: opacity3),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case WavePersonality.community:
        return LinearGradient(
          colors: [
            const Color(0xFFEC4899).withValues(alpha: opacity1),
            const Color(0xFFDB2777).withValues(alpha: opacity2),
            const Color(0xFFBE185D).withValues(alpha: opacity3),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case WavePersonality.mindfulness:
        return LinearGradient(
          colors: [
            const Color(0xFF8B5CF6).withValues(alpha: opacity1),
            const Color(0xFF7C3AED).withValues(alpha: opacity2),
            const Color(0xFF6D28D9).withValues(alpha: opacity3),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case WavePersonality.adventure:
        return LinearGradient(
          colors: [
            const Color(0xFFF59E0B).withValues(alpha: opacity1),
            const Color(0xFFD97706).withValues(alpha: opacity2),
            const Color(0xFFB45309).withValues(alpha: opacity3),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class WaveLayer {
  final double frequency;
  final double amplitude;
  final double phase;
  final double speed;

  WaveLayer({
    required this.frequency,
    required this.amplitude,
    required this.phase,
    required this.speed,
  });
}