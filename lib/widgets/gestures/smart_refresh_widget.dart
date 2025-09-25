import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A smart refresh widget that provides pull-to-refresh with custom styling
class SmartRefreshWidget extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final bool enabled;
  final Color? indicatorColor;
  final Color? backgroundColor;
  final String? refreshText;
  final double displacement;

  const SmartRefreshWidget({
    super.key,
    required this.child,
    required this.onRefresh,
    this.enabled = true,
    this.indicatorColor,
    this.backgroundColor,
    this.refreshText,
    this.displacement = 40.0,
  });

  @override
  State<SmartRefreshWidget> createState() => _SmartRefreshWidgetState();
}

class _SmartRefreshWidgetState extends State<SmartRefreshWidget>
    with TickerProviderStateMixin {
  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOutBack,
    ));
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    _rippleController.forward();

    try {
      await widget.onRefresh();
    } finally {
      _rippleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      displacement: widget.displacement,
      color: widget.indicatorColor ?? Theme.of(context).primaryColor,
      backgroundColor: widget.backgroundColor ?? Theme.of(context).cardColor,
      strokeWidth: 3.0,
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      child: Stack(
        children: [
          widget.child,
          // Ripple effect overlay
          AnimatedBuilder(
            animation: _rippleAnimation,
            builder: (context, child) {
              if (_rippleAnimation.value == 0.0) {
                return const SizedBox.shrink();
              }

              return Positioned.fill(
                child: CustomPaint(
                  painter: RipplePainter(
                    progress: _rippleAnimation.value,
                    color: (widget.indicatorColor ?? Theme.of(context).primaryColor)
                        .withValues(alpha: 0.1),
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

/// Custom painter for the ripple effect
class RipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  RipplePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.1);
    final maxRadius = size.width * 0.7;

    final paint = Paint()
      ..color = color.withValues(alpha: (1 - progress) * 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, maxRadius * progress, paint);
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// A list tile wrapper that adds swipe actions and can be used in refreshable lists
class SwipeableListTile extends StatelessWidget {
  final Widget child;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;
  final VoidCallback? onFavorite;
  final VoidCallback? onShare;
  final VoidCallback? onEdit;
  final bool enabled;

  const SwipeableListTile({
    super.key,
    required this.child,
    this.onComplete,
    this.onDelete,
    this.onFavorite,
    this.onShare,
    this.onEdit,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    return Dismissible(
      key: ValueKey(child.hashCode),
      direction: _getDismissDirection(),
      background: _buildLeftBackground(),
      secondaryBackground: _buildRightBackground(),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd && onComplete != null) {
          onComplete!();
          return false; // Don't actually dismiss
        } else if (direction == DismissDirection.endToStart && onDelete != null) {
          // Show confirmation dialog for delete
          return await _showDeleteConfirmation(context);
        }
        return false;
      },
      child: child,
    );
  }

  DismissDirection _getDismissDirection() {
    if (onComplete != null && onDelete != null) {
      return DismissDirection.horizontal;
    } else if (onComplete != null) {
      return DismissDirection.startToEnd;
    } else if (onDelete != null) {
      return DismissDirection.endToStart;
    } else {
      return DismissDirection.none;
    }
  }

  Widget _buildLeftBackground() {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.white, size: 28),
          SizedBox(height: 4),
          Text('Complete', style: TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRightBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete, color: Colors.white, size: 28),
          SizedBox(height: 4),
          Text('Delete', style: TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }
}

/// A wrapper that adds pull-to-refresh to any scrollable widget
class PullToRefreshWrapper extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final bool enabled;
  final String? refreshMessage;

  const PullToRefreshWrapper({
    super.key,
    required this.child,
    required this.onRefresh,
    this.enabled = true,
    this.refreshMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    // Wrap the child in a SingleChildScrollView if it's not already scrollable
    Widget scrollableChild = child;

    if (child is! ScrollView && child is! CustomScrollView) {
      scrollableChild = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: child,
      );
    }

    return SmartRefreshWidget(
      onRefresh: onRefresh,
      enabled: enabled,
      child: scrollableChild,
    );
  }
}