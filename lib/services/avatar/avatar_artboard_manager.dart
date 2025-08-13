import 'package:rive/rive.dart' as rive;
import 'package:logging/logging.dart';
import '../firebase/firebase_avatar_service.dart';
import '../../config/avatar_animations_config.dart';

final log = Logger('AvatarArtboardManager');

/// Centralized manager for avatar artboards to prevent RuntimeArtboard conflicts
/// and ensure consistent customization application across screens
class AvatarArtboardManager {
  static final AvatarArtboardManager _instance = AvatarArtboardManager._internal();
  factory AvatarArtboardManager() => _instance;
  AvatarArtboardManager._internal();

  // Cache of loaded artboards with their customizations applied
  final Map<String, CachedArtboard> _artboardCache = {};
  final Map<String, rive.RiveFile> _riveFileCache = {};

  /// Get an artboard for the specified avatar with customizations applied
  Future<rive.Artboard?> getCustomizedArtboard(String avatarId, String assetPath, FirebaseAvatarService avatarService) async {
    final cacheKey = '${avatarId}_customized';
    
    try {
      // Check if we have a valid cached artboard
      if (_artboardCache.containsKey(cacheKey)) {
        final cached = _artboardCache[cacheKey]!;
        if (cached.isValid) {
          log.info('✅ Using cached customized artboard for $avatarId');
          return cached.artboard;
        } else {
          // Remove invalid cached artboard
          _artboardCache.remove(cacheKey);
          cached.dispose();
        }
      }

      log.info('🔄 Creating new customized artboard for $avatarId');
      
      // Load or get cached RIVE file
      rive.RiveFile rivFile;
      if (_riveFileCache.containsKey(assetPath)) {
        rivFile = _riveFileCache[assetPath]!;
        log.info('📁 Using cached RIVE file for $assetPath');
      } else {
        rivFile = await rive.RiveFile.asset(assetPath);
        _riveFileCache[assetPath] = rivFile;
        log.info('📁 Loaded and cached RIVE file for $assetPath');
      }

      // Create fresh artboard instance
      final artboard = rivFile.mainArtboard.instance();
      
      // Create state machine controller
      final controller = rive.StateMachineController.fromArtboard(artboard, 'State Machine 1');
      if (controller == null) {
        log.warning('⚠️ No state machine found for $avatarId');
        return artboard; // Return basic artboard without customizations
      }

      artboard.addController(controller);

      // Apply customizations if available
      await _applyCustomizations(avatarId, controller, avatarService);

      // Start default idle animation
      _startDefaultAnimation(controller, avatarId);

      // Cache the customized artboard
      _artboardCache[cacheKey] = CachedArtboard(artboard, controller);
      
      log.info('✅ Created and cached customized artboard for $avatarId');
      return artboard;

    } catch (e) {
      log.severe('❌ Error creating customized artboard for $avatarId: $e');
      
      // Fallback: try to return a basic artboard without customizations
      try {
        final rivFile = await rive.RiveFile.asset(assetPath);
        return rivFile.mainArtboard.instance();
      } catch (fallbackError) {
        log.severe('❌ Fallback artboard creation also failed: $fallbackError');
        return null;
      }
    }
  }

  /// Get a basic artboard without customizations (for performance)
  Future<rive.Artboard?> getBasicArtboard(String avatarId, String assetPath) async {
    final cacheKey = '${avatarId}_basic';
    
    try {
      // Check cache first
      if (_artboardCache.containsKey(cacheKey)) {
        final cached = _artboardCache[cacheKey]!;
        if (cached.isValid) {
          log.info('✅ Using cached basic artboard for $avatarId');
          return cached.artboard;
        } else {
          _artboardCache.remove(cacheKey);
          cached.dispose();
        }
      }

      // Load RIVE file (use cache if available)
      rive.RiveFile rivFile;
      if (_riveFileCache.containsKey(assetPath)) {
        rivFile = _riveFileCache[assetPath]!;
      } else {
        rivFile = await rive.RiveFile.asset(assetPath);
        _riveFileCache[assetPath] = rivFile;
      }

      final artboard = rivFile.mainArtboard.instance();
      
      // Create basic controller for animations
      final controller = rive.StateMachineController.fromArtboard(artboard, 'State Machine 1');
      if (controller != null) {
        artboard.addController(controller);
        
        // Start default idle animation
        _startDefaultAnimation(controller, avatarId);
      }

      // Cache the basic artboard
      _artboardCache[cacheKey] = CachedArtboard(artboard, controller);
      
      log.info('✅ Created and cached basic artboard for $avatarId');
      return artboard;

    } catch (e) {
      log.severe('❌ Error creating basic artboard for $avatarId: $e');
      return null;
    }
  }

  /// Start the default animation for an avatar
  void _startDefaultAnimation(rive.StateMachineController controller, String avatarId) {
    try {
      final config = AvatarAnimationsConfig.getConfigWithFallback(avatarId);
      final defaultAnimation = config.defaultAnimation;
      
      log.info('🎬 Starting default animation "$defaultAnimation" for $avatarId');
      
      if (_triggerAnimationOnController(controller, defaultAnimation, avatarId)) {
        log.info('✅ Default animation started for $avatarId');
      } else {
        log.warning('⚠️ Failed to start default animation for $avatarId');
      }
    } catch (e) {
      log.warning('❌ Error starting default animation for $avatarId: $e');
    }
  }

  /// Apply saved customizations to an artboard
  Future<void> _applyCustomizations(String avatarId, rive.StateMachineController controller, FirebaseAvatarService avatarService) async {
    try {
      if (avatarId == 'quantum_coach') {
        final customizations = avatarService.getAvatarCustomizations(avatarId);
        
        if (customizations.isNotEmpty) {
          log.info('🎨 Applying ${customizations.length} customizations to $avatarId');
          
          // Apply number inputs
          _applyNumberInput(controller, 'eye_color', customizations['eye_color']);
          _applyNumberInput(controller, 'face', customizations['face']);
          _applyNumberInput(controller, 'skin_color', customizations['skin_color']);
          _applyNumberInput(controller, 'sit', customizations['sit']);
          _applyNumberInput(controller, 'flower_state', customizations['flower_state']);
          _applyNumberInput(controller, 'stateaction', customizations['stateaction']);

          // Apply boolean inputs
          _applyBoolInput(controller, 'top_check', customizations['top_check']);
          _applyBoolInput(controller, 'bottoms_check', customizations['bottoms_check']);
          _applyBoolInput(controller, 'skirt_check', customizations['skirt_check']);
          _applyBoolInput(controller, 'shoes_check', customizations['shoes_check']);
          _applyBoolInput(controller, 'hat_check', customizations['hat_check']);
          _applyBoolInput(controller, 'earring_check', customizations['earring_check']);
          _applyBoolInput(controller, 'necklace_check', customizations['necklace_check']);
          _applyBoolInput(controller, 'glass_check', customizations['glass_check']);
          _applyBoolInput(controller, 'hair_check', customizations['hair_check']);
          _applyBoolInput(controller, 'back_check', customizations['back_check']);
          _applyBoolInput(controller, 'handobject_check', customizations['handobject_check']);

          log.info('✅ Applied all customizations to $avatarId');
        } else {
          log.info('💡 No customizations found for $avatarId');
        }
      }
    } catch (e) {
      log.warning('⚠️ Error applying customizations to $avatarId: $e');
    }
  }

  void _applyNumberInput(rive.StateMachineController controller, String inputName, dynamic value) {
    if (value == null) return;
    
    try {
      final input = controller.findInput<double>(inputName);
      if (input is rive.SMINumber) {
        final doubleValue = value is double ? value : (value as num).toDouble();
        input.value = doubleValue;
        log.fine('✅ Applied $inputName = $doubleValue');
      }
    } catch (e) {
      log.fine('⚠️ Failed to apply number input $inputName: $e');
    }
  }

  void _applyBoolInput(rive.StateMachineController controller, String inputName, dynamic value) {
    if (value == null) return;
    
    try {
      final input = controller.findInput<bool>(inputName);
      if (input is rive.SMIBool) {
        final boolValue = value is bool ? value : value.toString().toLowerCase() == 'true';
        input.value = boolValue;
        log.fine('✅ Applied $inputName = $boolValue');
      }
    } catch (e) {
      log.fine('⚠️ Failed to apply bool input $inputName: $e');
    }
  }

  /// Trigger an animation on a cached artboard
  bool triggerAnimation(String avatarId, String animationName, {bool useCustomized = true}) {
    try {
      final cacheKey = useCustomized ? '${avatarId}_customized' : '${avatarId}_basic';
      final cached = _artboardCache[cacheKey];
      
      if (cached?.controller != null) {
        return _triggerAnimationOnController(cached!.controller!, animationName, avatarId);
      } else {
        log.warning('⚠️ No cached controller found for $avatarId ($cacheKey)');
        return false;
      }
    } catch (e) {
      log.warning('❌ Error triggering animation $animationName on $avatarId: $e');
      return false;
    }
  }

  /// Set a number input on a cached artboard
  bool setNumberInput(String avatarId, String inputName, double value, {bool useCustomized = true}) {
    try {
      final cacheKey = useCustomized ? '${avatarId}_customized' : '${avatarId}_basic';
      final cached = _artboardCache[cacheKey];
      
      if (cached?.controller != null) {
        _applyNumberInput(cached!.controller!, inputName, value);
        return true;
      } else {
        log.warning('⚠️ No cached controller found for $avatarId ($cacheKey)');
        return false;
      }
    } catch (e) {
      log.warning('❌ Error setting number input $inputName on $avatarId: $e');
      return false;
    }
  }

  /// Set a boolean input on a cached artboard
  bool setBoolInput(String avatarId, String inputName, bool value, {bool useCustomized = true}) {
    try {
      final cacheKey = useCustomized ? '${avatarId}_customized' : '${avatarId}_basic';
      final cached = _artboardCache[cacheKey];
      
      if (cached?.controller != null) {
        _applyBoolInput(cached!.controller!, inputName, value);
        return true;
      } else {
        log.warning('⚠️ No cached controller found for $avatarId ($cacheKey)');
        return false;
      }
    } catch (e) {
      log.warning('❌ Error setting bool input $inputName on $avatarId: $e');
      return false;
    }
  }

  /// Helper method to trigger animation on a controller
  bool _triggerAnimationOnController(rive.StateMachineController controller, String animationName, String context) {
    try {
      // First try to find and fire a trigger input
      for (final input in controller.inputs) {
        if (input.name.toLowerCase() == animationName.toLowerCase()) {
          if (input is rive.SMITrigger) {
            input.fire();
            log.info('🎬 Triggered animation: $animationName for $context');
            return true;
          } else if (input is rive.SMIBool) {
            // For boolean inputs, set to true to activate the animation state
            input.value = true;
            log.info('🎬 Set boolean state: $animationName = true for $context');
            return true;
          } else if (input is rive.SMINumber) {
            // For number inputs, try setting to 1
            input.value = 1.0;
            log.info('🎬 Set number state: $animationName = 1.0 for $context');
            return true;
          }
        }
      }
      
      // If no exact match, try to find any animation that contains "idle" or is the first trigger
      if (animationName.toLowerCase() == 'idle') {
        for (final input in controller.inputs) {
          if (input.name.toLowerCase().contains('idle') && input is rive.SMITrigger) {
            input.fire();
            log.info('🎬 Triggered fallback idle animation: ${input.name} for $context');
            return true;
          }
        }
        
        // If still no luck, just fire the first trigger we find
        for (final input in controller.inputs) {
          if (input is rive.SMITrigger) {
            input.fire();
            log.info('🎬 Triggered first available animation: ${input.name} for $context');
            return true;
          }
        }
      }
      
      log.warning('⚠️ Animation trigger not found: $animationName for $context. Available inputs: ${controller.inputs.map((i) => '${i.name} (${i.runtimeType})').join(', ')}');
      return false;
    } catch (e) {
      log.severe('❌ Error triggering animation $animationName for $context: $e');
      return false;
    }
  }

  /// Update customizations on cached artboards without invalidating them (for smooth real-time updates)
  bool updateCustomizationsInPlace(String avatarId, Map<String, dynamic> customizations) {
    try {
      final customizedKey = '${avatarId}_customized';
      final cached = _artboardCache[customizedKey];
      
      if (cached?.controller != null) {
        log.info('🎨 Updating customizations in place for $avatarId');
        
        // Apply the new customizations to the existing controller
        if (avatarId == 'quantum_coach') {
          // Apply number inputs
          _applyNumberInput(cached!.controller!, 'eye_color', customizations['eye_color']);
          _applyNumberInput(cached.controller!, 'face', customizations['face']);
          _applyNumberInput(cached.controller!, 'skin_color', customizations['skin_color']);
          _applyNumberInput(cached.controller!, 'sit', customizations['sit']);
          _applyNumberInput(cached.controller!, 'flower_state', customizations['flower_state']);
          _applyNumberInput(cached.controller!, 'stateaction', customizations['stateaction']);

          // Apply boolean inputs
          _applyBoolInput(cached.controller!, 'top_check', customizations['top_check']);
          _applyBoolInput(cached.controller!, 'bottoms_check', customizations['bottoms_check']);
        }
        
        return true;
      } else {
        log.warning('⚠️ No cached controller found for in-place update: $avatarId');
        return false;
      }
    } catch (e) {
      log.warning('❌ Error updating customizations in place for $avatarId: $e');
      return false;
    }
  }

  /// Invalidate cached artboard for an avatar (call when customizations change)
  void invalidateArtboard(String avatarId) {
    final customizedKey = '${avatarId}_customized';
    final basicKey = '${avatarId}_basic';
    
    if (_artboardCache.containsKey(customizedKey)) {
      _artboardCache[customizedKey]!.dispose();
      _artboardCache.remove(customizedKey);
      log.info('🗑️ Invalidated customized artboard cache for $avatarId');
    }
    
    if (_artboardCache.containsKey(basicKey)) {
      _artboardCache[basicKey]!.dispose();
      _artboardCache.remove(basicKey);
      log.info('🗑️ Invalidated basic artboard cache for $avatarId');
    }
  }

  /// Clear all cached artboards (call on app shutdown or memory pressure)
  void dispose() {
    log.info('🧹 Disposing all cached artboards');
    
    for (final cached in _artboardCache.values) {
      cached.dispose();
    }
    _artboardCache.clear();
    _riveFileCache.clear();
    
    log.info('✅ All artboard caches cleared');
  }

  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    return {
      'cached_artboards': _artboardCache.length,
      'cached_rive_files': _riveFileCache.length,
      'artboard_keys': _artboardCache.keys.toList(),
      'rive_file_paths': _riveFileCache.keys.toList(),
    };
  }
}

/// Wrapper for cached artboard with lifecycle management
class CachedArtboard {
  final rive.Artboard artboard;
  final rive.StateMachineController? controller;
  final DateTime createdAt;
  bool _disposed = false;

  CachedArtboard(this.artboard, this.controller) : createdAt = DateTime.now();

  bool get isValid => !_disposed && DateTime.now().difference(createdAt).inMinutes < 30; // Cache for 30 minutes

  void dispose() {
    if (!_disposed) {
      controller?.dispose();
      _disposed = true;
    }
  }
}