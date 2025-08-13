import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/avatar_animations_config.dart';
import '../providers/avatar/avatar_artboard_provider.dart';
import 'avatar_display.dart';

/// A wrapper around AvatarDisplay that provides easy external control methods
/// This solves the "we can't directly control animations" limitation
class ControllableAvatarDisplay extends ConsumerWidget {
  final String? avatarId;
  final AnimationStage initialStage;
  final double width;
  final double height;
  final bool autoPlaySequence;
  final Duration sequenceDelay;
  final VoidCallback? onSequenceComplete;
  final BoxFit fit;
  final bool useCustomizations;
  final bool preferEquipped;
  final GlobalKey<AvatarDisplayState>? controllerKey;

  const ControllableAvatarDisplay({
    super.key,
    this.avatarId,
    this.initialStage = AnimationStage.idle,
    this.width = 200,
    this.height = 200,
    this.autoPlaySequence = false,
    this.sequenceDelay = const Duration(seconds: 2),
    this.onSequenceComplete,
    this.fit = BoxFit.contain,
    this.useCustomizations = true,
    this.preferEquipped = false,
    this.controllerKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AvatarDisplay(
      key: controllerKey,
      avatarId: avatarId,
      initialStage: initialStage,
      width: width,
      height: height,
      autoPlaySequence: autoPlaySequence,
      sequenceDelay: sequenceDelay,
      onSequenceComplete: onSequenceComplete,
      fit: fit,
      useCustomizations: useCustomizations,
      preferEquipped: preferEquipped,
    );
  }

  /// Control methods that work with the new architecture
  /// These methods use the Riverpod provider system internally

  /// Trigger a specific animation stage
  static void playStage(WidgetRef ref, String avatarId, AnimationStage stage, {bool useCustomized = true}) {
    try {
      final config = AvatarAnimationsConfig.getConfigWithFallback(avatarId);
      final animationName = config.getAnimation(stage) ?? config.defaultAnimation;
      
      final cacheNotifier = ref.read(artboardCacheNotifierProvider);
      final success = cacheNotifier.triggerAnimation(avatarId, animationName, useCustomized: useCustomized);
      
      if (!success) {
        debugPrint('⚠️ Failed to play stage $stage on $avatarId');
      }
    } catch (e) {
      debugPrint('❌ Error playing stage $stage on $avatarId: $e');
    }
  }

  /// Trigger a specific animation by name
  static void triggerAnimation(WidgetRef ref, String avatarId, String animationName, {bool useCustomized = true}) {
    try {
      final cacheNotifier = ref.read(artboardCacheNotifierProvider);
      final success = cacheNotifier.triggerAnimation(avatarId, animationName, useCustomized: useCustomized);
      
      if (!success) {
        debugPrint('⚠️ Failed to trigger animation $animationName on $avatarId');
      }
    } catch (e) {
      debugPrint('❌ Error triggering animation $animationName on $avatarId: $e');
    }
  }

  /// Set a number input (like eye_color, face, skin_color)
  static void setNumberInput(WidgetRef ref, String avatarId, String inputName, double value, {bool useCustomized = true}) {
    try {
      final cacheNotifier = ref.read(artboardCacheNotifierProvider);
      final success = cacheNotifier.setNumberInput(avatarId, inputName, value, useCustomized: useCustomized);
      
      if (!success) {
        debugPrint('⚠️ Failed to set number input $inputName = $value on $avatarId');
      }
    } catch (e) {
      debugPrint('❌ Error setting number input $inputName on $avatarId: $e');
    }
  }

  /// Set a boolean input (like clothing visibility)
  static void setBoolInput(WidgetRef ref, String avatarId, String inputName, bool value, {bool useCustomized = true}) {
    try {
      final cacheNotifier = ref.read(artboardCacheNotifierProvider);
      final success = cacheNotifier.setBoolInput(avatarId, inputName, value, useCustomized: useCustomized);
      
      if (!success) {
        debugPrint('⚠️ Failed to set bool input $inputName = $value on $avatarId');
      }
    } catch (e) {
      debugPrint('❌ Error setting bool input $inputName on $avatarId: $e');
    }
  }

  /// Invalidate the artboard cache (call when customizations change)
  static void invalidateCache(WidgetRef ref, String avatarId) {
    try {
      final cacheNotifier = ref.read(artboardCacheNotifierProvider);
      cacheNotifier.onCustomizationsChanged(avatarId);
    } catch (e) {
      debugPrint('❌ Error invalidating cache for $avatarId: $e');
    }
  }

  /// Get cache statistics (for debugging)
  static Map<String, dynamic> getCacheStats(WidgetRef ref) {
    try {
      final cacheNotifier = ref.read(artboardCacheNotifierProvider);
      return cacheNotifier.getCacheStats();
    } catch (e) {
      debugPrint('❌ Error getting cache stats: $e');
      return {};
    }
  }
}

/// Extension to make it easier to control avatars from any ConsumerWidget
extension AvatarControl on WidgetRef {
  /// Quick access to avatar control methods
  void playAvatarStage(String avatarId, AnimationStage stage, {bool useCustomized = true}) {
    ControllableAvatarDisplay.playStage(this, avatarId, stage, useCustomized: useCustomized);
  }

  void triggerAvatarAnimation(String avatarId, String animationName, {bool useCustomized = true}) {
    ControllableAvatarDisplay.triggerAnimation(this, avatarId, animationName, useCustomized: useCustomized);
  }

  void setAvatarNumberInput(String avatarId, String inputName, double value, {bool useCustomized = true}) {
    ControllableAvatarDisplay.setNumberInput(this, avatarId, inputName, value, useCustomized: useCustomized);
  }

  void setAvatarBoolInput(String avatarId, String inputName, bool value, {bool useCustomized = true}) {
    ControllableAvatarDisplay.setBoolInput(this, avatarId, inputName, value, useCustomized: useCustomized);
  }

  void invalidateAvatarCache(String avatarId) {
    ControllableAvatarDisplay.invalidateCache(this, avatarId);
  }

  Map<String, dynamic> getAvatarCacheStats() {
    return ControllableAvatarDisplay.getCacheStats(this);
  }
}