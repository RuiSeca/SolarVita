import 'package:flutter/material.dart';
import 'dart:ui';

/// A scroll-aware floating action button that becomes glassy and hides on scroll
class ScrollAwareFAB extends StatefulWidget {
  final Widget? child;
  final VoidCallback? onPressed;
  final String? heroTag;
  final Color? backgroundColor;
  final String? label;
  final IconData? icon;
  final ScrollController scrollController;
  final bool extended;

  const ScrollAwareFAB({
    super.key,
    this.child,
    required this.scrollController,
    this.onPressed,
    this.heroTag,
    this.backgroundColor,
    this.label,
    this.icon,
    this.extended = false,
  });

  const ScrollAwareFAB.extended({
    super.key,
    required this.scrollController,
    required this.label,
    required this.icon,
    this.onPressed,
    this.heroTag,
    this.backgroundColor,
  }) : child = null, extended = true;

  @override
  State<ScrollAwareFAB> createState() => _ScrollAwareFABState();
}

class _ScrollAwareFABState extends State<ScrollAwareFAB>
    with TickerProviderStateMixin {
  late AnimationController _visibilityController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isVisible = true;
  double _lastScrollPosition = 0;
  static const double _scrollThreshold = 15.0;

  @override
  void initState() {
    super.initState();

    _visibilityController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _visibilityController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 2),
    ).animate(CurvedAnimation(
      parent: _visibilityController,
      curve: Curves.easeInOut,
    ));

    // Listen to scroll changes
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _visibilityController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.scrollController.hasClients) return;

    final currentScrollPosition = widget.scrollController.offset;
    final scrollDelta = currentScrollPosition - _lastScrollPosition;

    // Hide FAB when scrolling down, show when scrolling up or at top
    if (scrollDelta > _scrollThreshold && _isVisible && currentScrollPosition > 100) {
      _hideFAB();
    } else if ((scrollDelta < -_scrollThreshold || currentScrollPosition <= 50) && !_isVisible) {
      _showFAB();
    }

    _lastScrollPosition = currentScrollPosition;
  }

  void _hideFAB() {
    if (!_isVisible) return;

    setState(() {
      _isVisible = false;
    });
    _visibilityController.forward();
  }

  void _showFAB() {
    if (_isVisible) return;

    setState(() {
      _isVisible = true;
    });
    _visibilityController.reverse();
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_visibilityController, _scaleController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: GestureDetector(
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                child: _buildGlassyFAB(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassyFAB() {
    final theme = Theme.of(context);
    final backgroundColor = widget.backgroundColor ?? theme.primaryColor;

    if (widget.extended) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: backgroundColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: backgroundColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    color: backgroundColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.label ?? '',
                    style: TextStyle(
                      color: backgroundColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: backgroundColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: widget.child ?? Icon(
                  widget.icon,
                  color: backgroundColor,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
}