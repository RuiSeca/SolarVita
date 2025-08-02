import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScrollControllerNotifier extends StateNotifier<Map<String, ScrollController>> {
  final Map<String, ScrollController> _controllers = {};

  ScrollControllerNotifier() : super({});

  ScrollController getController(String key) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = ScrollController();
    }
    return _controllers[key]!;
  }

  void scrollToTop(String key) {
    final controller = _controllers[key];
    if (controller != null && controller.hasClients) {
      controller.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
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