import 'package:flutter/material.dart';
import 'dart:math';
import 'animated_waves.dart';

/// Enhanced waves that react to the ambient audio track
/// Creates a more immersive, synchronized experience
class AudioReactiveWaves extends StatefulWidget {
  final double intensity;
  final WavePersonality personality;
  final bool enableAudioReactivity;

  const AudioReactiveWaves({
    super.key,
    required this.intensity,
    this.personality = WavePersonality.eco,
    this.enableAudioReactivity = true,
  });

  @override
  State<AudioReactiveWaves> createState() => _AudioReactiveWavesState();
}

class _AudioReactiveWavesState extends State<AudioReactiveWaves>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear)
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: SimplifiedAudioWavePainter(
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

class SimplifiedAudioWavePainter extends CustomPainter {
  final double animationValue;
  final double intensity;
  final WavePersonality personality;

  SimplifiedAudioWavePainter({
    required this.animationValue,
    required this.intensity,
    required this.personality,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final waveLayers = [
      SimpleWaveLayer(frequency: 0.015, amplitude: 40, phase: 0, speed: 1.0),
      SimpleWaveLayer(frequency: 0.022, amplitude: 25, phase: pi / 3, speed: 0.7),
      SimpleWaveLayer(frequency: 0.008, amplitude: 60, phase: pi / 2, speed: 1.3),
      SimpleWaveLayer(frequency: 0.035, amplitude: 15, phase: pi, speed: 0.5),
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
  bool shouldRepaint(covariant SimplifiedAudioWavePainter oldDelegate) {
    return animationValue != oldDelegate.animationValue ||
           intensity != oldDelegate.intensity ||
           personality != oldDelegate.personality;
  }
}

class SimpleWaveLayer {
  final double frequency;
  final double amplitude;
  final double phase;
  final double speed;

  SimpleWaveLayer({
    required this.frequency,
    required this.amplitude,
    required this.phase,
    required this.speed,
  });
}