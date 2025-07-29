import 'package:flutter/material.dart';
import 'fitness_tracker_widget.dart';

class OptimizedMapFactory {
  static Widget createMap({
    required double height,
    bool showRoutes = true,
    bool enableInteraction = false,
  }) {
    // For very small maps, use a static image placeholder to save memory
    if (height <= 100) {
      return _buildMapPlaceholder(height);
    }
    
    // Use lightweight fitness tracker instead of Google Maps
    return FitnessTrackerWidget(
      height: height,
      showRoutes: showRoutes,
      enableInteraction: enableInteraction,
    );
  }
  
  static Widget _buildMapPlaceholder(double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Stack(
        children: [
          // Simple grid pattern to simulate map
          CustomPaint(
            size: Size.infinite,
            painter: _MapPlaceholderPainter(),
          ),
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.green,
                  size: 24,
                ),
                SizedBox(height: 4),
                Text(
                  'Location',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    // Draw grid lines
    for (int i = 0; i < size.width; i += 20) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        paint,
      );
    }

    for (int i = 0; i < size.height; i += 20) {
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(size.width, i.toDouble()),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}