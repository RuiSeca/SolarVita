import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/profile/profile_layout_config.dart';
import '../../../providers/riverpod/profile_layout_provider.dart';
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
          return ProfileWidgetFactory.buildWidget(type);
        }).toList(),
      );
    }

    // Edit mode - use ReorderableListView for drag and drop
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false, // We'll add custom drag handles
      onReorder: (oldIndex, newIndex) {
        _handleReorder(ref, config, oldIndex, newIndex);
      },
      itemCount: visibleWidgets.length,
      itemBuilder: (context, index) {
        final type = visibleWidgets[index];
        return ProfileWidgetFactory.buildReorderableWidget(
          type,
          isEditMode: isEditMode,
        );
      },
    );
  }

  void _handleReorder(
    WidgetRef ref,
    ProfileLayoutConfig config,
    int oldIndex,
    int newIndex,
  ) {
    final visibleWidgets = List<ProfileWidgetType>.from(config.visibleWidgets);
    
    // Adjust newIndex if moving down
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    
    // Perform the reorder
    final item = visibleWidgets.removeAt(oldIndex);
    visibleWidgets.insert(newIndex, item);
    
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
                Icons.edit,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Edit Mode',
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: FloatingActionButton.extended(
        onPressed: () {
          if (isEditMode) {
            notifier.exitEditMode();
            _showEditCompleteSnackBar(context);
          } else {
            notifier.enterEditMode();
            _showEditModeInstructions(context);
          }
        },
        backgroundColor: isEditMode ? Colors.green : Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            isEditMode ? Icons.check : Icons.edit,
            key: ValueKey(isEditMode),
          ),
        ),
        label: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            isEditMode ? 'Done' : 'Edit Layout',
            key: ValueKey(isEditMode),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  void _showEditModeInstructions(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.drag_handle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Drag widgets to reorder them',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showEditCompleteSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              'Layout saved successfully!',
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