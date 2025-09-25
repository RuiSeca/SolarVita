import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScrollControllerNotifier extends StateNotifier<Map<String, ScrollController>> {
  final Map<String, ScrollController> _controllers = {};
  final Map<String, double> _savedPositions = {};
  SharedPreferences? _prefs;

  ScrollControllerNotifier() : super({}) {
    _initializePreferences();
  }

  Future<void> _initializePreferences() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadSavedPositions();
    } catch (e) {
      debugPrint('Failed to initialize scroll position preferences: $e');
    }
  }

  Future<void> _loadSavedPositions() async {
    if (_prefs == null) return;

    final keys = ['dashboard', 'search', 'health', 'profile'];
    for (final key in keys) {
      final position = _prefs!.getDouble('scroll_position_$key') ?? 0.0;
      _savedPositions[key] = position;
    }
    debugPrint('📜 Loaded saved scroll positions: $_savedPositions');
  }

  ScrollController getController(String key) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = ScrollController();

      // Restore saved position when controller is first created and has clients
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _restoreScrollPosition(key);
      });
    }
    return _controllers[key]!;
  }

  void _restoreScrollPosition(String key) {
    final controller = _controllers[key];
    final savedPosition = _savedPositions[key];

    if (controller != null && controller.hasClients && savedPosition != null && savedPosition > 0) {
      try {
        controller.jumpTo(savedPosition);
        debugPrint('📜 Restored scroll position for $key: $savedPosition');
      } catch (e) {
        debugPrint('📜 Failed to restore scroll position for $key: $e');
      }
    }
  }

  Future<void> saveScrollPosition(String key) async {
    final controller = _controllers[key];
    if (controller != null && controller.hasClients && _prefs != null) {
      final position = controller.offset;
      _savedPositions[key] = position;
      await _prefs!.setDouble('scroll_position_$key', position);
      debugPrint('📜 Saved scroll position for $key: $position');
    }
  }

  void scrollToTop(String key) {
    final controller = _controllers[key];
    if (controller != null && controller.hasClients) {
      controller.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      // Save the top position
      _saveScrollPositionImmediate(key, 0.0);
    }
  }

  Future<void> _saveScrollPositionImmediate(String key, double position) async {
    if (_prefs != null) {
      _savedPositions[key] = position;
      await _prefs!.setDouble('scroll_position_$key', position);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }
}

final scrollControllerNotifierProvider = StateNotifierProvider<ScrollControllerNotifier, Map<String, ScrollController>>((ref) {
  return ScrollControllerNotifier();
});