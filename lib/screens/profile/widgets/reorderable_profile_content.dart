import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/profile/profile_layout_config.dart';
import '../../../providers/riverpod/profile_layout_provider.dart';
import '../../../utils/translation_helper.dart';
import 'profile_widget_factory.dart';

/// The main reorderable content section of the profile
class ReorderableProfileContent extends ConsumerWidget {
  const ReorderableProfileContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutAsync = ref.watch(profileLayoutNotifierProvider);
    final isEditMode = ref.watch(profileEditModeProvider);

    return layoutAsync.when(
      data: (config) => _buildReorderableContent(
        context,
        ref,
        config,
        isEditMode,
      ),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load layout',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  ref.read(profileLayoutNotifierProvider.notifier).loadLayout();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReorderableContent(
    BuildContext context,
    WidgetRef ref,
    ProfileLayoutConfig config,
    bool isEditMode,
  ) {
    final visibleWidgets = config.visibleWidgets;

    if (!isEditMode) {
      // Normal mode - just display widgets in order
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: visibleWidgets.map((type) {
          return _SafeProfileWidget(
            child: ProfileWidgetFactory.buildWidget(type),
          );
        }).toList(),
      );
    }

    // Edit mode - use Column with custom drag detection to avoid scroll conflicts
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: visibleWidgets.asMap().entries.map((entry) {
        final index = entry.key;
        final type = entry.value;
        
        // Wrap in a safe container that handles Expanded/Flexible widgets
        final baseWidget = _SafeProfileWidget(
          child: ProfileWidgetFactory.buildWidget(type),
        );
        
        return LongPressDraggable<int>(
          data: index,
          feedback: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: MediaQuery.of(context).size.width - 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.6),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: baseWidget,
            ),
          ),
          childWhenDragging: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            height: 100, // Placeholder height
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.3),
                width: 2,
                style: BorderStyle.solid,
              ),
              color: Colors.grey.withValues(alpha: 0.1),
            ),
            child: Center(
              child: Text(
                tr(context, 'drop_zone'),
                style: TextStyle(
                  color: Colors.grey.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
          child: DragTarget<int>(
            onWillAcceptWithDetails: (details) => details.data != index,
            onAcceptWithDetails: (details) {
              if (context.mounted) {
                _handleReorder(ref, config, details.data, index);
              }
            },
            builder: (context, candidateData, rejectedData) {
              final isAccepting = candidateData.isNotEmpty;
              
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isAccepting 
                        ? Colors.green.withValues(alpha: 0.6)
                        : Colors.blue.withValues(alpha: 0.3),
                    width: isAccepting ? 3 : 2,
                  ),
                  color: isAccepting 
                      ? Colors.green.withValues(alpha: 0.1)
                      : null,
                ),
                child: Stack(
                  children: [
                    baseWidget,
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isAccepting ? Colors.green : Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isAccepting ? Icons.add : Icons.drag_handle,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }


  void _handleReorder(
    WidgetRef ref,
    ProfileLayoutConfig config,
    int draggedIndex,
    int targetIndex,
  ) {
    final visibleWidgets = List<ProfileWidgetType>.from(config.visibleWidgets);
    
    // Don't reorder if indices are the same or invalid
    if (draggedIndex == targetIndex || 
        draggedIndex >= visibleWidgets.length || 
        targetIndex >= visibleWidgets.length) {
      return;
    }
    
    // Perform the reorder
    final item = visibleWidgets.removeAt(draggedIndex);
    visibleWidgets.insert(targetIndex, item);
    
    // Update the full widget order (including hidden widgets)
    final newFullOrder = <ProfileWidgetType>[];
    int visibleIndex = 0;
    
    // Rebuild the complete order preserving hidden widgets
    for (final originalType in config.widgetOrder) {
      if (config.widgetVisibility[originalType] ?? true) {
        // This is a visible widget, use the new order
        if (visibleIndex < visibleWidgets.length) {
          newFullOrder.add(visibleWidgets[visibleIndex]);
          visibleIndex++;
        }
      } else {
        // Hidden widget, keep in original position
        newFullOrder.add(originalType);
      }
    }
    
    // Update the layout
    ref.read(profileLayoutNotifierProvider.notifier)
        .updateWidgetOrder(newFullOrder);
  }
}

/// Safe wrapper for profile widgets that handles Expanded/Flexible properly
class _SafeProfileWidget extends StatelessWidget {
  const _SafeProfileWidget({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Wrap in a Column with MainAxisSize.min to provide proper flex context
    // This allows any Expanded/Flexible widgets inside to work properly
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        child,
      ],
    );
  }
}

/// Edit mode overlay with smooth transitions
class EditModeOverlay extends ConsumerWidget {
  const EditModeOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEditMode = ref.watch(profileEditModeProvider);
    
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: isEditMode ? 16 : -100,
      right: 16,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isEditMode ? 1.0 : 0.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.touch_app,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                tr(context, 'press_drag_reorder'),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating action button for toggling edit mode
class EditModeFAB extends ConsumerWidget {
  const EditModeFAB({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEditMode = ref.watch(profileEditModeProvider);
    final notifier = ref.read(profileLayoutNotifierProvider.notifier);

    // Only show the FAB when in edit mode
    if (!isEditMode) {
      return const SizedBox.shrink();
    }

    return AnimatedScale(
      duration: const Duration(milliseconds: 300),
      scale: isEditMode ? 1.0 : 0.0,
      child: FloatingActionButton.extended(
        onPressed: () {
          notifier.exitEditMode();
          // Use post-frame callback to ensure context is still valid
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              _showEditCompleteSnackBar(context);
            }
          });
        },
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: const Icon(
          Icons.check,
          size: 24,
        ),
        label: Text(
          tr(context, 'done'),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }


  void _showEditCompleteSnackBar(BuildContext context) {
    // Check if the context is still valid before accessing ScaffoldMessenger
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              tr(context, 'layout_saved'),
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

