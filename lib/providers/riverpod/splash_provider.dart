import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashNotifier extends StateNotifier<bool> {
  SplashNotifier() : super(true);

  void completeSplash() {
    state = false;
  }
}

final splashNotifierProvider = StateNotifierProvider<SplashNotifier, bool>((ref) {
  return SplashNotifier();
});