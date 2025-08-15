import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart' as rive;
import 'package:logging/logging.dart';
import '../../services/avatar/avatar_artboard_manager.dart';
import '../../config/avatar_animations_config.dart';
import '../firebase/firebase_avatar_provider.dart';

final log = Logger('AvatarArtboardProvider');

/// Provider for the singleton artboard manager
final avatarArtboardManagerProvider = Provider<AvatarArtboardManager>((ref) {
  final manager = AvatarArtboardManager();
  
  // Dispose manager when provider is disposed (app exit/screen reset)
  ref.onDispose(() {
    log.info('🧹 Avatar artboard manager provider disposed - clearing all caches');
    manager.dispose();
  });
  
  return manager;
});

/// Provider for getting a customized artboard for a specific avatar
final customizedArtboardProvider = FutureProvider.family<rive.Artboard?, String>((ref, avatarId) async {
  try {
    log.info('🎨 Requesting customized artboard for: $avatarId');
    
    final manager = ref.read(avatarArtboardManagerProvider);
    final avatarService = ref.read(firebaseAvatarServiceProvider);
    
    
    // Get avatar config to find asset path
    final config = AvatarAnimationsConfig.getConfigWithFallback(avatarId);
    
    log.info('🔧 Using config for $avatarId: ${config.rivAssetPath}');
    log.info('🔧 Has customization: ${config.customProperties?['hasCustomization']}');
    
    final artboard = await manager.getCustomizedArtboard(avatarId, config.rivAssetPath, avatarService);
    
    if (artboard != null) {
      log.info('✅ Successfully got customized artboard for: $avatarId');
    } else {
      log.warning('⚠️ Failed to get customized artboard for: $avatarId');
    }
    
    return artboard;
  } catch (e) {
    log.severe('❌ Error getting customized artboard for $avatarId: $e');
    return null;
  }
});

/// Provider for getting a basic artboard (no customizations) for performance
final basicArtboardProvider = FutureProvider.family<rive.Artboard?, String>((ref, avatarId) async {
  try {
    log.info('🎪 Requesting basic artboard for: $avatarId');
    
    final manager = ref.read(avatarArtboardManagerProvider);
    
    // Get avatar config to find asset path
    final config = AvatarAnimationsConfig.getConfigWithFallback(avatarId);
    
    log.info('🔧 Using basic config for $avatarId: ${config.rivAssetPath}');
    log.info('🔧 Has customization: ${config.customProperties?['hasCustomization']}');
    
    final artboard = await manager.getBasicArtboard(avatarId, config.rivAssetPath);
    
    if (artboard != null) {
      log.info('✅ Successfully got basic artboard for: $avatarId');
    } else {
      log.warning('⚠️ Failed to get basic artboard for: $avatarId');
    }
    
    return artboard;
  } catch (e) {
    log.severe('❌ Error getting basic artboard for $avatarId: $e');
    return null;
  }
});

/// Provider for invalidating artboard cache when customizations change
final artboardCacheNotifierProvider = Provider<ArtboardCacheNotifier>((ref) {
  final notifier = ArtboardCacheNotifier(ref.read(avatarArtboardManagerProvider));
  
  // Dispose timers when provider is disposed
  ref.onDispose(() {
    notifier.dispose();
  });
  
  return notifier;
});


/// Notifier for managing artboard cache invalidation and animation control
class ArtboardCacheNotifier {
  final AvatarArtboardManager _manager;
  final Map<String, Timer> _debounceTimers = {};
  
  ArtboardCacheNotifier(this._manager);
  
  /// Call this when customizations change to invalidate cached artboards (debounced)
  void onCustomizationsChanged(String avatarId) {
    // Cancel any existing timer for this avatar
    _debounceTimers[avatarId]?.cancel();
    
    // Create new timer with 500ms delay
    _debounceTimers[avatarId] = Timer(const Duration(milliseconds: 500), () {
      log.info('🔄 Debounced cache invalidation for $avatarId');
      _manager.invalidateArtboard(avatarId);
      _debounceTimers.remove(avatarId);
    });
    
    log.info('🔄 Scheduled debounced cache invalidation for $avatarId');
  }
  
  /// Update customizations on cached artboards without invalidating (for smooth real-time updates)
  void updateCustomizationsLive(String avatarId, Map<String, dynamic> customizations) {
    try {
      final updated = _manager.updateCustomizationsInPlace(avatarId, customizations);
      if (updated) {
        log.info('✅ Live customization update applied to $avatarId');
      } else {
        log.info('! Live customization update failed for $avatarId');
      }
    } catch (e) {
      log.warning('❌ Error updating live customizations for $avatarId: $e');
    }
  }
  
  /// Call this for immediate cache invalidation (bypass debouncing)
  void onCustomizationsChangedImmediate(String avatarId) {
    log.info('🔄 Immediate cache invalidation for $avatarId');
    _debounceTimers[avatarId]?.cancel();
    _debounceTimers.remove(avatarId);
    _manager.invalidateArtboard(avatarId);
    
  }
  
  
  /// Trigger an animation on a cached artboard
  bool triggerAnimation(String avatarId, String animationName, {bool useCustomized = true}) {
    log.info('🎬 Triggering animation $animationName on $avatarId (customized: $useCustomized)');
    return _manager.triggerAnimation(avatarId, animationName, useCustomized: useCustomized);
  }
  
  /// Set a number input on a cached artboard
  bool setNumberInput(String avatarId, String inputName, double value, {bool useCustomized = true}) {
    log.fine('🔢 Setting number input $inputName = $value on $avatarId');
    return _manager.setNumberInput(avatarId, inputName, value, useCustomized: useCustomized);
  }
  
  /// Set a boolean input on a cached artboard
  bool setBoolInput(String avatarId, String inputName, bool value, {bool useCustomized = true}) {
    log.fine('🔘 Setting bool input $inputName = $value on $avatarId');
    return _manager.setBoolInput(avatarId, inputName, value, useCustomized: useCustomized);
  }
  
  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    return _manager.getCacheStats();
  }
  
  /// Clear all caches (for debugging or memory pressure)
  void clearAllCaches() {
    log.info('🧹 Clearing all artboard caches');
    _manager.dispose();
  }
  
  /// Clean up debounce timers
  void dispose() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    log.info('🧹 Disposed artboard cache notifier timers');
  }
}