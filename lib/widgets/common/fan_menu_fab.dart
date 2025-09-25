import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

/// A fan-style expandable FAB that opens like a Chinese fan with multiple action options
class FanMenuFAB extends StatefulWidget {
  final ScrollController scrollController;
  final List<FanMenuItem> menuItems;
  final Color? backgroundColor;
  final String? heroTag;

  const FanMenuFAB({
    super.key,
    required this.scrollController,
    required this.menuItems,
    this.backgroundColor,
    this.heroTag,
  });

  @override
  State<FanMenuFAB> createState() => _FanMenuFABState();
}

class _FanMenuFABState extends State<FanMenuFAB>
    with TickerProviderStateMixin {
  late AnimationController _visibilityController;
  late AnimationController _fanController;
  late AnimationController _scaleController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fanAnimation;
  late Animation<double> _rotationAnimation;

  bool _isVisible = true;
  bool _isExpanded = false;
  double _lastScrollPosition = 0;
  static const double _scrollThreshold = 15.0;

  // Long press and drag state
  bool _isLongPressing = false;
  FanMenuItem? _hoveredItem;

  @override
  void initState() {
    super.initState();

    _visibilityController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fanController = AnimationController(
      duration: const Duration(milliseconds: 800), // Longer for staggered animation
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

    _fanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fanController,
      curve: Curves.easeOutCubic, // Smoother for choreographed animation
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.125, // 45 degrees in turns
    ).animate(CurvedAnimation(
      parent: _fanController,
      curve: Curves.easeInOut,
    ));

    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _visibilityController.dispose();
    _fanController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.scrollController.hasClients) return;

    final currentScrollPosition = widget.scrollController.offset;
    final scrollDelta = currentScrollPosition - _lastScrollPosition;

    if (scrollDelta > _scrollThreshold && _isVisible && currentScrollPosition > 100) {
      _hideFAB();
    } else if ((scrollDelta < -_scrollThreshold || currentScrollPosition <= 50) && !_isVisible) {
      _showFAB();
    }

    _lastScrollPosition = currentScrollPosition;
  }

  void _hideFAB() {
    if (!_isVisible) return;
    if (_isExpanded) _collapseFan();

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

  void _toggleFan() {
    HapticFeedback.lightImpact();

    if (_isExpanded) {
      _collapseFan();
    } else {
      _expandFan();
    }
  }

  void _expandFan() {
    setState(() {
      _isExpanded = true;
    });
    _fanController.forward();
    HapticFeedback.mediumImpact();
    debugPrint('Fan expanded - items count: ${widget.menuItems.length}');
  }

  void _collapseFan() {
    setState(() {
      _isExpanded = false;
      _isLongPressing = false;
      _hoveredItem = null;
    });
    _fanController.reverse();
  }

  void _onLongPressStart(LongPressStartDetails details) {
    if (!_isExpanded) {
      _expandFan();
      setState(() {
        _isLongPressing = true;
      });
      HapticFeedback.heavyImpact();
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isLongPressing || !_isExpanded) return;

    // Check which item is being hovered
    final hoveredItem = _getHoveredItem(details.localPosition);
    if (hoveredItem != _hoveredItem) {
      setState(() {
        _hoveredItem = hoveredItem;
      });
      if (hoveredItem != null) {
        HapticFeedback.selectionClick();
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_hoveredItem != null && _isLongPressing) {
      _hoveredItem!.onTap();
      HapticFeedback.mediumImpact();
    }
    _collapseFan();
  }

  FanMenuItem? _getHoveredItem(Offset position) {
    // Calculate which menu item is being hovered based on position
    // This is a simplified implementation - in production you'd want more precise hit testing
    const fanRadius = 120.0;
    final fabCenterX = 250.0 - 20.0 - 28.0; // Container width - right offset - half FAB width
    final fabCenterY = 250.0 - 20.0 - 28.0; // Container height - bottom offset - half FAB height
    final center = Offset(fabCenterX, fabCenterY);
    final distance = (position - center).distance;

    if (distance > fanRadius || distance < 40) return null;

    final angle = math.atan2(position.dy - center.dy, position.dx - center.dx);
    final normalizedAngle = (angle + math.pi) / (2 * math.pi); // 0-1

    // Map angle to menu items (fan spans roughly 90 degrees in upper-left quadrant)
    final itemIndex = ((1 - normalizedAngle) * widget.menuItems.length).floor();

    if (itemIndex >= 0 && itemIndex < widget.menuItems.length) {
      return widget.menuItems[itemIndex];
    }

    return null;
  }

  void _onTap() {
    if (_isExpanded) {
      _collapseFan();
    } else {
      _toggleFan();
    }
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_visibilityController, _fanController, _scaleController]),
      builder: (context, child) {
        final opacity = _fadeAnimation.value.clamp(0.0, 1.0);
        final scale = _scaleAnimation.value.clamp(0.1, 2.0);

        if (opacity == 0.0) {
          return const SizedBox.shrink();
        }

        return Transform.scale(
          scale: scale,
          child: SlideTransition(
            position: _slideAnimation,
            child: Opacity(
              opacity: opacity,
              child: SizedBox(
                width: 250,
                height: 250,
                child: Stack(
                  clipBehavior: Clip.none, // Allow items to extend beyond bounds
                  children: [
                    // Fan menu items
                    if (_isExpanded) ..._buildFanItems(),

                    // Main FAB
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: GestureDetector(
                        onTap: _onTap,
                        onTapDown: _onTapDown,
                        onTapUp: _onTapUp,
                        onTapCancel: _onTapCancel,
                        onLongPressStart: _onLongPressStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: Transform.rotate(
                          angle: (_rotationAnimation.value * 2 * math.pi).clamp(-math.pi, math.pi),
                          child: _buildMainFAB(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildFanItems() {
    final List<Widget> items = [];
    const fanRadius = 90.0;
    const startAngle = math.pi * 0.75; // Start from upper left (135 degrees)
    const sweepAngle = math.pi * 0.6; // 108 degree fan spread for more natural opening

    debugPrint('Building fan items: ${widget.menuItems.length} items, progress: ${_fanAnimation.value}');

    for (int i = 0; i < widget.menuItems.length; i++) {
      final item = widget.menuItems[i];
      final progress = _fanAnimation.value;

      // Create smooth arc distribution
      final normalizedIndex = widget.menuItems.length == 1
          ? 0.0
          : i / (widget.menuItems.length - 1);
      final angle = startAngle + sweepAngle * normalizedIndex;

      // Staggered dance-like animation with multiple phases
      final baseDelay = i * 0.15; // Increased delay for more dramatic effect
      final itemProgress = (progress - baseDelay).clamp(0.0, 1.0);

      // Multi-phase animation for realistic movement
      final slideProgress = (itemProgress * 2.5).clamp(0.0, 1.0);
      final scaleProgress = (itemProgress * 3.0 - 0.5).clamp(0.0, 1.0);
      final rotateProgress = (itemProgress * 2.0 - 0.3).clamp(0.0, 1.0);

      // Dynamic radius with elastic bounce and overshoot
      final elasticCurve = Curves.elasticOut.transform(slideProgress);
      final animatedRadius = fanRadius * elasticCurve;

      // Add rotation and spiral effect for more dynamic movement
      final spiralOffset = (1.0 - itemProgress) * 0.3; // Spiral inward effect
      final dynamicAngle = angle + (spiralOffset * math.pi * 0.2);

      // Position relative to the FAB center (which is at bottom-right of container)
      final fabCenterX = 250.0 - 20.0 - 28.0; // Container width - right offset - half FAB width
      final fabCenterY = 250.0 - 20.0 - 28.0; // Container height - bottom offset - half FAB height

      final x = fabCenterX + animatedRadius * math.cos(dynamicAngle);
      final y = fabCenterY + animatedRadius * math.sin(dynamicAngle);

      debugPrint('Item $i: x=$x, y=$y, progress=$itemProgress, radius=$animatedRadius');

      final isHovered = _hoveredItem == item;

      // Dynamic scale with bounce effect
      final baseScale = Curves.elasticOut.transform(scaleProgress);
      final hoverScale = isHovered ? 1.3 : 1.0;
      final finalScale = (baseScale * hoverScale).clamp(0.0, 2.5);

      // Dynamic opacity with fade-in choreography
      final opacityProgress = (itemProgress * 2.0 - 0.2).clamp(0.0, 1.0);
      final dynamicOpacity = Curves.easeOut.transform(opacityProgress);

      // Rotation effect for each item
      final itemRotation = rotateProgress * 0.5 - 0.25; // Subtle rotation

      items.add(
        Positioned(
          left: x - 24, // Half of item size
          top: y - 24,
          child: Transform.scale(
            scale: finalScale,
            child: Transform.rotate(
              angle: itemRotation,
              child: AnimatedOpacity(
                opacity: dynamicOpacity,
                duration: const Duration(milliseconds: 100),
                child: GestureDetector(
                  onTap: () {
                    item.onTap();
                    _collapseFan();
                  },
                  child: _buildFanItem(item, isHovered),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return items;
  }

  Widget _buildFanItem(FanMenuItem item, bool isHovered) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Theme-adaptive colors
    final glassBase = isDarkMode ? Colors.white : Colors.black;
    final iconColor = isDarkMode ? Colors.white : Colors.black;
    final shadowColor = isDarkMode ? Colors.black : Colors.grey.shade300;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        // Theme-adaptive glass morphism
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            // More glass effect in dark mode, subtle in light mode
            glassBase.withValues(alpha: isDarkMode
              ? (isHovered ? 0.25 : 0.15)
              : (isHovered ? 0.08 : 0.05)),
            glassBase.withValues(alpha: isDarkMode
              ? (isHovered ? 0.1 : 0.05)
              : (isHovered ? 0.04 : 0.02)),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: glassBase.withValues(alpha: isDarkMode
            ? (isHovered ? 0.4 : 0.2)
            : (isHovered ? 0.15 : 0.08)),
          width: isHovered ? 1.5 : 1,
        ),
        boxShadow: [
          // Main shadow - stronger in light mode for definition
          BoxShadow(
            color: shadowColor.withValues(alpha: isDarkMode ? 0.6 : 0.3),
            blurRadius: isHovered ? 16 : 12,
            offset: Offset(0, isDarkMode ? 4 : 6),
          ),
          // Inner glow - more prominent in dark mode
          if (isDarkMode) BoxShadow(
            color: Colors.white.withValues(alpha: isHovered ? 0.15 : 0.08),
            blurRadius: isHovered ? 8 : 4,
            offset: const Offset(0, -2),
          ),
          // Subtle colored accent
          BoxShadow(
            color: item.color.withValues(alpha: isDarkMode ? 0.1 : 0.05),
            blurRadius: isHovered ? 20 : 15,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Subtle inner highlight
          gradient: RadialGradient(
            colors: [
              glassBase.withValues(alpha: isDarkMode ? 0.2 : 0.08),
              Colors.transparent,
            ],
            stops: const [0.0, 0.8],
          ),
        ),
        child: Center(
          child: Icon(
            item.icon,
            color: iconColor.withValues(alpha: 0.85),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildMainFAB() {
    final theme = Theme.of(context);
    final backgroundColor = widget.backgroundColor ?? theme.primaryColor;
    final isDarkMode = theme.brightness == Brightness.dark;

    // Theme-adaptive colors
    final glassBase = isDarkMode ? Colors.white : Colors.black;
    final iconColor = isDarkMode ? Colors.white : Colors.black;
    final shadowColor = isDarkMode ? Colors.black : Colors.grey.shade400;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        // Theme-adaptive glass morphism for main FAB
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            // Glass effect with subtle color blend
            glassBase.withValues(alpha: isDarkMode ? 0.2 : 0.06),
            glassBase.withValues(alpha: isDarkMode ? 0.08 : 0.03),
            backgroundColor.withValues(alpha: isDarkMode ? 0.4 : 0.6),
            backgroundColor.withValues(alpha: isDarkMode ? 0.6 : 0.8),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: glassBase.withValues(alpha: isDarkMode ? 0.3 : 0.1),
          width: 1.5,
        ),
        boxShadow: [
          // Main shadow - adaptive to theme
          BoxShadow(
            color: shadowColor.withValues(alpha: isDarkMode ? 0.8 : 0.4),
            blurRadius: 20,
            offset: Offset(0, isDarkMode ? 6 : 8),
          ),
          // Inner glow - more prominent in dark mode
          if (isDarkMode) BoxShadow(
            color: glassBase.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
          // Colored glow
          BoxShadow(
            color: backgroundColor.withValues(alpha: isDarkMode ? 0.2 : 0.15),
            blurRadius: 28,
            offset: const Offset(0, 10),
            spreadRadius: -6,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Subtle inner highlight
          gradient: RadialGradient(
            colors: [
              glassBase.withValues(alpha: isDarkMode ? 0.25 : 0.08),
              Colors.transparent,
            ],
            stops: const [0.0, 0.85],
          ),
        ),
        child: Center(
          child: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0, // 45 degree rotation when expanded
            duration: const Duration(milliseconds: 300),
            child: Icon(
              _isExpanded ? Icons.close : Icons.add,
              color: iconColor.withValues(alpha: 0.9),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

/// Represents a menu item in the fan menu
class FanMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const FanMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });
}