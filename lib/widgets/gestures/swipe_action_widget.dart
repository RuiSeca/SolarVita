import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget that adds swipe gestures to its child for common actions
class SwipeActionWidget extends StatefulWidget {
  final Widget child;
  final SwipeAction? leftAction;
  final SwipeAction? rightAction;
  final double threshold;
  final Duration animationDuration;
  final bool enabled;

  const SwipeActionWidget({
    super.key,
    required this.child,
    this.leftAction,
    this.rightAction,
    this.threshold = 0.3,
    this.animationDuration = const Duration(milliseconds: 200),
    this.enabled = true,
  });

  @override
  State<SwipeActionWidget> createState() => _SwipeActionWidgetState();
}

class _SwipeActionWidgetState extends State<SwipeActionWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  double _dragDistance = 0;
  bool _isDragging = false;
  SwipeAction? _activeAction;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.enabled) return;

    _isDragging = true;
    _dragDistance = 0;
    _activeAction = null;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.enabled || !_isDragging) return;

    final screenWidth = MediaQuery.of(context).size.width;
    _dragDistance += details.delta.dx;

    // Determine which action is active based on swipe direction
    if (_dragDistance > 0 && widget.rightAction != null) {
      _activeAction = widget.rightAction;
    } else if (_dragDistance < 0 && widget.leftAction != null) {
      _activeAction = widget.leftAction;
    } else {
      _activeAction = null;
    }

    // Update animation based on drag distance
    final progress = (_dragDistance.abs() / screenWidth).clamp(0.0, 1.0);

    if (progress > widget.threshold && _activeAction != null) {
      // Start haptic feedback when threshold is reached
      if (!_animationController.isAnimating) {
        HapticFeedback.lightImpact();
      }
    }

    // Update slide animation
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(_dragDistance / screenWidth * 0.1, 0),
    ).animate(_animationController);

    setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.enabled || !_isDragging) return;

    _isDragging = false;
    final screenWidth = MediaQuery.of(context).size.width;
    final dragRatio = _dragDistance.abs() / screenWidth;

    if (dragRatio > widget.threshold && _activeAction != null) {
      // Execute the action
      _executeAction(_activeAction!);
    } else {
      // Reset position
      _resetPosition();
    }
  }

  void _executeAction(SwipeAction action) {
    HapticFeedback.mediumImpact();

    // Animate the action execution
    _animationController.forward().then((_) {
      action.onExecute();
      _resetPosition();
    });
  }

  void _resetPosition() {
    _animationController.reverse();
    setState(() {
      _dragDistance = 0;
      _activeAction = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Stack(
            children: [
              // Background action indicators
              if (_activeAction != null) _buildActionIndicator(),

              // Main content
              Transform.translate(
                offset: _slideAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: widget.child,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionIndicator() {
    if (_activeAction == null) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final progress = (_dragDistance.abs() / screenWidth).clamp(0.0, 1.0);
    final isActive = progress > widget.threshold;

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: (_activeAction!.backgroundColor ?? Colors.green)
              .withValues(alpha: progress * 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: _dragDistance > 0
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AnimatedScale(
                scale: isActive ? 1.2 : 1.0,
                duration: const Duration(milliseconds: 100),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _activeAction!.icon,
                      color: _activeAction!.iconColor ?? Colors.white,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _activeAction!.label,
                      style: TextStyle(
                        color: _activeAction!.iconColor ?? Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Represents a swipe action that can be performed
class SwipeAction {
  final IconData icon;
  final String label;
  final VoidCallback onExecute;
  final Color? backgroundColor;
  final Color? iconColor;

  const SwipeAction({
    required this.icon,
    required this.label,
    required this.onExecute,
    this.backgroundColor,
    this.iconColor,
  });
}

/// Predefined common swipe actions
class CommonSwipeActions {
  static SwipeAction complete({
    required VoidCallback onComplete,
    String label = 'Complete',
  }) {
    return SwipeAction(
      icon: Icons.check_circle,
      label: label,
      onExecute: onComplete,
      backgroundColor: Colors.green,
      iconColor: Colors.white,
    );
  }

  static SwipeAction delete({
    required VoidCallback onDelete,
    String label = 'Delete',
  }) {
    return SwipeAction(
      icon: Icons.delete,
      label: label,
      onExecute: onDelete,
      backgroundColor: Colors.red,
      iconColor: Colors.white,
    );
  }

  static SwipeAction favorite({
    required VoidCallback onFavorite,
    String label = 'Favorite',
  }) {
    return SwipeAction(
      icon: Icons.favorite,
      label: label,
      onExecute: onFavorite,
      backgroundColor: Colors.pink,
      iconColor: Colors.white,
    );
  }

  static SwipeAction share({
    required VoidCallback onShare,
    String label = 'Share',
  }) {
    return SwipeAction(
      icon: Icons.share,
      label: label,
      onExecute: onShare,
      backgroundColor: Colors.blue,
      iconColor: Colors.white,
    );
  }

  static SwipeAction edit({
    required VoidCallback onEdit,
    String label = 'Edit',
  }) {
    return SwipeAction(
      icon: Icons.edit,
      label: label,
      onExecute: onEdit,
      backgroundColor: Colors.orange,
      iconColor: Colors.white,
    );
  }

  static SwipeAction archive({
    required VoidCallback onArchive,
    String label = 'Archive',
  }) {
    return SwipeAction(
      icon: Icons.archive,
      label: label,
      onExecute: onArchive,
      backgroundColor: Colors.grey,
      iconColor: Colors.white,
    );
  }
}

