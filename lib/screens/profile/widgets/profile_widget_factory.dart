import 'package:flutter/material.dart';
import '../../../models/profile/profile_layout_config.dart';
import 'optimized_profile_widgets.dart';
import 'user_routine_widget.dart';
import 'eco_impact_widget.dart';
import 'enhanced_profile_meal_widget.dart';

/// Factory for creating profile widgets based on type
class ProfileWidgetFactory {
  /// Build a widget based on its type
  static Widget buildWidget(ProfileWidgetType type) {
    switch (type) {
      case ProfileWidgetType.meals:
        return const EnhancedProfileMealWidget();

      case ProfileWidgetType.userRoutine:
        return const UserRoutineWidget();

      case ProfileWidgetType.dailyGoals:
        return const OptimizedDailyGoals();

      case ProfileWidgetType.weeklySummary:
        return const OptimizedWeeklySummary();

      case ProfileWidgetType.actionGrid:
        return const OptimizedActionGrid();

      case ProfileWidgetType.achievements:
        return const OptimizedAchievements();
        
      case ProfileWidgetType.ecoImpact:
        return const EcoImpactWidget();
    }
  }

  /// Build a reorderable widget with proper key and edit mode styling
  static Widget buildReorderableWidget(
    ProfileWidgetType type, {
    required bool isEditMode,
  }) {
    final widget = buildWidget(type);
    
    return ReorderableDelayedDragStartListener(
      key: ValueKey(type.key),
      index: 0, // Will be set by the ReorderableListView
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: isEditMode 
            ? Matrix4.diagonal3Values(0.98, 0.98, 1.0)
            : Matrix4.identity(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isEditMode 
                ? Border.all(
                    color: Colors.blue.withValues(alpha: 0.3),
                    width: 2,
                  )
                : null,
            boxShadow: isEditMode
                ? [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.1),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              widget,
              if (isEditMode)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _JiggleAnimation(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.drag_handle,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get display info for a widget type (for settings/management)
  static String getWidgetDisplayName(ProfileWidgetType type) {
    return type.displayName;
  }

  /// Get icon for a widget type
  static IconData getWidgetIcon(ProfileWidgetType type) {
    return type.icon;
  }
}

/// Jiggle animation for edit mode
class _JiggleAnimation extends StatefulWidget {
  const _JiggleAnimation({required this.child});

  final Widget child;

  @override
  State<_JiggleAnimation> createState() => _JiggleAnimationState();
}

class _JiggleAnimationState extends State<_JiggleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -0.02,
      end: 0.02,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticInOut,
    ));

    _controller.repeat(reverse: true);
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
      child: widget.child,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value,
          child: child,
        );
      },
    );
  }
}