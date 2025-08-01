import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/riverpod/health_data_provider.dart';
import '../../theme/app_theme.dart';

class FitnessTrackerWidget extends ConsumerStatefulWidget {
  final double height;
  final bool showRoutes;
  final bool enableInteraction;

  const FitnessTrackerWidget({
    super.key,
    this.height = 200,
    this.showRoutes = true,
    this.enableInteraction = false,
  });

  @override
  ConsumerState<FitnessTrackerWidget> createState() =>
      _FitnessTrackerWidgetState();
}

class _FitnessTrackerWidgetState extends ConsumerState<FitnessTrackerWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _routeController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _routeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Start route animation
    _routeController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _routeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = ref.watch(dailyStepsProvider);
    final activeMinutes = ref.watch(activeMinutesProvider);
    final carbonSavings =
        4.2; // Mock value since carbon provider needs to be implemented

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[900]!
                : Colors.grey[50]!,
            Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]!
                : Colors.grey[100]!,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Background route visualization
            if (widget.showRoutes) _buildRouteVisualization(context),

            // Fitness stats overlay
            _buildFitnessStatsOverlay(
              context,
              steps,
              activeMinutes,
              carbonSavings,
            ),

            // Pulse animation for current location
            _buildLocationPulse(context),

            // Bottom action bar (if interactive)
            if (widget.enableInteraction) _buildActionBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteVisualization(BuildContext context) {
    return CustomPaint(
      size: Size(double.infinity, widget.height),
      painter: _RouteVisualizationPainter(
        routeProgress: _routeController.value,
        isDark: Theme.of(context).brightness == Brightness.dark,
      ),
    );
  }

  Widget _buildFitnessStatsOverlay(
    BuildContext context,
    int steps,
    int activeMinutes,
    double carbonSavings,
  ) {
    final walkingKm = (steps * 0.0008);
    final caloriesBurned = (steps * 0.04).round();

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.directions_walk,
                  color: Colors.green[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Today\'s Activity',
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'ECO',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Quick stats row
          Row(
            children: [
              _buildQuickStat(
                context,
                '$steps',
                'Steps',
                Icons.directions_walk,
                Colors.blue[600]!,
              ),
              const SizedBox(width: 16),
              _buildQuickStat(
                context,
                '${walkingKm.toStringAsFixed(1)}km',
                'Distance',
                Icons.straighten,
                Colors.green[600]!,
              ),
              const SizedBox(width: 16),
              _buildQuickStat(
                context,
                '${caloriesBurned}cal',
                'Burned',
                Icons.local_fire_department,
                Colors.orange[600]!,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.textFieldBackground(context).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textColor(context).withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationPulse(BuildContext context) {
    return Positioned(
      bottom: widget.height * 0.3,
      right: widget.height * 0.25,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            width: 20 + (_pulseController.value * 10),
            height: 20 + (_pulseController.value * 10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(
                alpha: 0.3 - (_pulseController.value * 0.2),
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.1)],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(Icons.play_arrow, 'Start', Colors.green),
            _buildActionButton(Icons.pause, 'Pause', Colors.orange),
            _buildActionButton(Icons.stop, 'Stop', Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        // Handle action
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteVisualizationPainter extends CustomPainter {
  final double routeProgress;
  final bool isDark;

  _RouteVisualizationPainter({
    required this.routeProgress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Background grid
    _drawGrid(canvas, size);

    // Main route (walking)
    _drawWalkingRoute(canvas, size, paint);

    // Alternative route (biking) - dotted
    _drawBikingRoute(canvas, size, paint);

    // Route markers
    _drawRouteMarkers(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.grey).withValues(alpha: 0.1)
      ..strokeWidth = 1;

    // Vertical lines
    for (int i = 0; i < size.width; i += 30) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        gridPaint,
      );
    }

    // Horizontal lines
    for (int i = 0; i < size.height; i += 30) {
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(size.width, i.toDouble()),
        gridPaint,
      );
    }
  }

  void _drawWalkingRoute(Canvas canvas, Size size, Paint paint) {
    paint.color = Colors.green;

    final path = Path();

    // Create a realistic walking route
    final points = [
      Offset(size.width * 0.1, size.height * 0.8),
      Offset(size.width * 0.3, size.height * 0.6),
      Offset(size.width * 0.5, size.height * 0.7),
      Offset(size.width * 0.7, size.height * 0.4),
      Offset(size.width * 0.9, size.height * 0.3),
    ];

    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);

      for (int i = 1; i < points.length; i++) {
        final progress = (i / (points.length - 1));
        if (progress <= routeProgress) {
          path.lineTo(points[i].dx, points[i].dy);
        } else {
          // Partial line for animation
          final prevPoint = points[i - 1];
          final currentPoint = points[i];
          final segmentProgress =
              (routeProgress - (i - 1) / (points.length - 1)) *
              (points.length - 1);

          final partialX =
              prevPoint.dx + (currentPoint.dx - prevPoint.dx) * segmentProgress;
          final partialY =
              prevPoint.dy + (currentPoint.dy - prevPoint.dy) * segmentProgress;

          path.lineTo(partialX, partialY);
          break;
        }
      }
    }

    canvas.drawPath(path, paint);
  }

  void _drawBikingRoute(Canvas canvas, Size size, Paint paint) {
    paint.color = Colors.blue;
    // pathEffect not available in Flutter - using strokeWidth instead
    paint.strokeWidth = 2.0;

    final path = Path();

    // Alternative biking route
    final points = [
      Offset(size.width * 0.1, size.height * 0.8),
      Offset(size.width * 0.2, size.height * 0.5),
      Offset(size.width * 0.6, size.height * 0.5),
      Offset(size.width * 0.8, size.height * 0.2),
      Offset(size.width * 0.9, size.height * 0.3),
    ];

    if (points.isNotEmpty && routeProgress > 0.5) {
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }

    canvas.drawPath(path, paint);
    // pathEffect reset not needed in Flutter
  }

  void _drawRouteMarkers(Canvas canvas, Size size) {
    final markerPaint = Paint()..style = PaintingStyle.fill;

    // Start marker (green)
    markerPaint.color = Colors.green;
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.8),
      6,
      markerPaint,
    );

    // End marker (red) - only if route is complete
    if (routeProgress >= 0.8) {
      markerPaint.color = Colors.red;
      canvas.drawCircle(
        Offset(size.width * 0.9, size.height * 0.3),
        6,
        markerPaint,
      );
    }

    // Current position marker (blue pulse)
    if (routeProgress > 0) {
      markerPaint.color = Colors.blue;
      canvas.drawCircle(
        Offset(
          size.width * 0.1 + (size.width * 0.8) * routeProgress,
          size.height * 0.8 - (size.height * 0.5) * routeProgress,
        ),
        4,
        markerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RouteVisualizationPainter oldDelegate) {
    return oldDelegate.routeProgress != routeProgress ||
        oldDelegate.isDark != isDark;
  }
}
