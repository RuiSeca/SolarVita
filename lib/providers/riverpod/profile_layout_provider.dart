import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/profile/profile_layout_config.dart';
import '../../services/profile/profile_layout_service.dart';

/// State notifier for profile layout management
class ProfileLayoutNotifier extends StateNotifier<AsyncValue<ProfileLayoutConfig>> {
  ProfileLayoutNotifier(this._service) : super(const AsyncValue.loading()) {
    loadLayout();
  }

  final ProfileLayoutService _service;
  bool _isEditMode = false;

  /// Whether the profile is currently in edit mode
  bool get isEditMode => _isEditMode;

  /// Load layout configuration
  Future<void> loadLayout() async {
    try {
      state = const AsyncValue.loading();
      final config = await _service.smartSync();
      state = AsyncValue.data(config);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Update widget order (during drag and drop)
  Future<void> updateWidgetOrder(List<ProfileWidgetType> newOrder) async {
    final currentConfig = state.value;
    if (currentConfig == null) return;

    try {
      final newConfig = currentConfig.copyWithOrder(newOrder);
      
      // Update state immediately for smooth UI
      state = AsyncValue.data(newConfig);
      
      // Save to local storage immediately
      await _service.saveLayoutLocally(newConfig);
      
      // Background sync to Firebase
      _service.syncLayoutToFirebase(newConfig);
    } catch (e) {
      // Revert state if save fails
      loadLayout();
    }
  }

  /// Toggle widget visibility
  Future<void> toggleWidgetVisibility(ProfileWidgetType type, bool visible) async {
    final currentConfig = state.value;
    if (currentConfig == null) return;

    try {
      final newConfig = currentConfig.copyWithVisibility(type, visible);
      
      // Update state immediately
      state = AsyncValue.data(newConfig);
      
      // Save to local storage
      await _service.saveLayoutLocally(newConfig);
      
      // Background sync to Firebase
      _service.syncLayoutToFirebase(newConfig);
    } catch (e) {
      // Revert state if save fails
      loadLayout();
    }
  }

  /// Enter edit mode
  void enterEditMode() {
    _isEditMode = true;
    // Notify listeners that edit mode changed (for UI updates)
    state = state; // Trigger rebuild
  }

  /// Exit edit mode
  void exitEditMode() {
    _isEditMode = false;
    // Notify listeners that edit mode changed
    state = state; // Trigger rebuild
  }

  /// Reset to default layout
  Future<void> resetToDefaultLayout() async {
    try {
      final defaultConfig = ProfileLayoutConfig.defaultLayout();
      
      state = AsyncValue.data(defaultConfig);
      
      await _service.saveLayoutLocally(defaultConfig);
      _service.syncLayoutToFirebase(defaultConfig);
    } catch (e) {
      loadLayout();
    }
  }

  /// Force sync with Firebase (manual refresh)
  Future<void> forceSyncWithFirebase() async {
    try {
      state = const AsyncValue.loading();
      final remoteConfig = await _service.loadLayoutFromFirebase();
      
      if (remoteConfig != null) {
        await _service.saveLayoutLocally(remoteConfig);
        state = AsyncValue.data(remoteConfig);
      } else {
        // No remote config, use local
        loadLayout();
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

/// Provider for profile layout state
final profileLayoutNotifierProvider = 
    StateNotifierProvider<ProfileLayoutNotifier, AsyncValue<ProfileLayoutConfig>>((ref) {
  final service = ProfileLayoutService();
  return ProfileLayoutNotifier(service);
});

/// Convenience provider for current layout config
final currentProfileLayoutProvider = Provider<ProfileLayoutConfig?>((ref) {
  return ref.watch(profileLayoutNotifierProvider).value;
});

/// Convenience provider for visible widgets in order
final visibleProfileWidgetsProvider = Provider<List<ProfileWidgetType>>((ref) {
  final config = ref.watch(currentProfileLayoutProvider);
  return config?.visibleWidgets ?? ProfileLayoutConfig.defaultLayout().visibleWidgets;
});

/// Convenience provider for edit mode state
final profileEditModeProvider = Provider<bool>((ref) {
  final notifier = ref.read(profileLayoutNotifierProvider.notifier);
  ref.watch(profileLayoutNotifierProvider); // Listen for changes
  return notifier.isEditMode;
});