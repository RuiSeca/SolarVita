import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_provider.g.dart';

@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  @override
  ThemeMode build() {
    // Load theme from SharedPreferences on startup
    _loadTheme();
    return ThemeMode.system;
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('themeMode');
    
    final ThemeMode themeMode;
    if (savedTheme == 'light') {
      themeMode = ThemeMode.light;
    } else if (savedTheme == 'dark') {
      themeMode = ThemeMode.dark;
    } else {
      themeMode = ThemeMode.system;
    }
    
    // Update state if different from default
    if (themeMode != state) {
      state = themeMode;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.toString().split('.').last);
  }
}

// Convenience providers for common theme checks
@riverpod
bool isDarkTheme(Ref ref) {
  return ref.watch(themeNotifierProvider) == ThemeMode.dark;
}

@riverpod
bool isLightTheme(Ref ref) {
  return ref.watch(themeNotifierProvider) == ThemeMode.light;
}

@riverpod
bool isSystemTheme(Ref ref) {
  return ref.watch(themeNotifierProvider) == ThemeMode.system;
}