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

  // Isolated cache for each avatar - no shared state
  final Map<String, CachedArtboard> _artboardCache = {};
  final Map<String, rive.RiveFile> _riveFileCache = {};
  
  // Per-avatar isolation keys to prevent conflicts
  final Map<String, int> _avatarInstanceIds = {};
  
  // Loading queue to prevent simultaneous loading conflicts
  final Map<String, Future<rive.Artboard?>> _loadingQueue = {};

  /// Get an artboard for the specified avatar with customizations applied
  Future<rive.Artboard?> getCustomizedArtboard(String avatarId, String assetPath, FirebaseAvatarService avatarService) async {
    // Generate unique instance ID for complete isolation
    if (!_avatarInstanceIds.containsKey(avatarId)) {
      _avatarInstanceIds[avatarId] = DateTime.now().millisecondsSinceEpoch;
    }
    final instanceId = _avatarInstanceIds[avatarId]!;
    final cacheKey = '${avatarId}_${instanceId}_customized';
    
    // EMERGENCY BYPASS: solar_coach gets completely separate handling
    if (avatarId == 'solar_coach') {
      log.info('🌞 EMERGENCY BYPASS: Using isolated solar_coach handler');
      return await _getSolarCoachIsolatedArtboard(assetPath);
    }
    
    // Check if already loading to prevent conflicts
    if (_loadingQueue.containsKey(cacheKey)) {
      log.info('⏳ Avatar $avatarId already loading, waiting for existing request...');
      return await _loadingQueue[cacheKey];
    }
    
    // Start loading and add to queue
    final loadingFuture = _loadAvatarWithQueue(avatarId, assetPath, avatarService);
    _loadingQueue[cacheKey] = loadingFuture;
    
    try {
      final result = await loadingFuture;
      return result;
    } finally {
      // Remove from queue when done
      _loadingQueue.remove(cacheKey);
    }
  }
  
  /// Internal loading method that handles the actual loading process
  Future<rive.Artboard?> _loadAvatarWithQueue(String avatarId, String assetPath, FirebaseAvatarService avatarService) async {
    // Use same instance ID for consistency
    final instanceId = _avatarInstanceIds[avatarId] ?? DateTime.now().millisecondsSinceEpoch;
    final cacheKey = '${avatarId}_${instanceId}_customized';
    
    try {
      // Each avatar gets completely isolated caching - no cross-avatar interference
      log.info('🔧 Loading isolated artboard for $avatarId (no cross-avatar conflicts)');
      
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
      
      // Special logging for customizable avatars to help debug app exit/return issues
      if (avatarId == 'quantum_coach' || avatarId == 'director_coach') {
        log.info('🎮 Creating fresh $avatarId artboard (likely after app exit/screen reset)');
      }
      
      // Load or get cached RIVE file
      rive.RiveFile rivFile;
      try {
        if (_riveFileCache.containsKey(assetPath)) {
          rivFile = _riveFileCache[assetPath]!;
          log.info('📁 Using cached RIVE file for $assetPath');
        } else {
          log.info('📁 Loading RIVE file from asset: $assetPath for $avatarId');
          rivFile = await rive.RiveFile.asset(assetPath);
          _riveFileCache[assetPath] = rivFile;
          log.info('📁 Loaded and cached RIVE file for $assetPath');
        }
      } catch (e) {
        log.severe('❌ Error loading RIVE file $assetPath for $avatarId: $e');
        if (e.toString().contains('RangeError')) {
          log.severe('🔍 RangeError during RIVE file loading!');
        }
        rethrow;
      }

      // Create fresh artboard instance
      rive.Artboard artboard;
      try {
        log.info('🎨 Creating artboard instance for $avatarId from $assetPath');
        artboard = rivFile.mainArtboard.instance();
        log.info('✅ Artboard instance created for $avatarId');
      } catch (e) {
        log.severe('❌ Error creating artboard instance for $avatarId: $e');
        if (e.toString().contains('RangeError')) {
          log.severe('🔍 RangeError during artboard instance creation!');
          log.severe('🔍 This is likely the source of the RangeError!');
        }
        rethrow;
      }
      
      // Check if avatar has customization enabled before creating state machine controller
      final config = AvatarAnimationsConfig.getConfig(avatarId);
      final hasCustomization = config?.customProperties?['hasCustomization'] ?? false;
      
      rive.StateMachineController? controller;
      if (hasCustomization) {
        // Create state machine controller only for avatars that support customization
        try {
          controller = rive.StateMachineController.fromArtboard(artboard, 'State Machine 1');
          if (controller == null) {
            log.warning('⚠️ No state machine found for customizable avatar $avatarId');
            return artboard; // Return basic artboard without customizations
          }
          
          artboard.addController(controller);
        } catch (e) {
          log.severe('❌ Error creating state machine controller for $avatarId: $e');
          if (e.toString().contains('RangeError') || e.toString().contains('range')) {
            log.severe('🔍 RangeError detected during state machine creation for $avatarId');
            log.severe('🔍 This may indicate a mismatch between expected and actual state machine count');
          }
          return artboard; // Return basic artboard without controller
        }
        
        // Apply customizations if available
        await _applyCustomizations(avatarId, controller, avatarService);
      } else {
        log.info('ℹ️ Avatar $avatarId has customization disabled, skipping state machine creation');
      }

      // Start default idle animation (works with or without controller)
      if (controller != null) {
        _startDefaultAnimation(controller, avatarId);
      }

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
    // EMERGENCY BYPASS: solar_coach gets isolated handling
    if (avatarId == 'solar_coach') {
      log.info('🌞 EMERGENCY BYPASS: Basic artboard using isolated solar_coach handler');
      return await _getSolarCoachIsolatedArtboard(assetPath);
    }
    
    // Generate unique instance ID for complete isolation
    if (!_avatarInstanceIds.containsKey(avatarId)) {
      _avatarInstanceIds[avatarId] = DateTime.now().millisecondsSinceEpoch;
    }
    final instanceId = _avatarInstanceIds[avatarId]!;
    final cacheKey = '${avatarId}_${instanceId}_basic';
    
    // Check if already loading to prevent conflicts
    if (_loadingQueue.containsKey(cacheKey)) {
      log.info('⏳ Basic avatar $avatarId already loading, waiting for existing request...');
      return await _loadingQueue[cacheKey];
    }
    
    // Start loading and add to queue
    final loadingFuture = _loadBasicAvatarWithQueue(avatarId, assetPath);
    _loadingQueue[cacheKey] = loadingFuture;
    
    try {
      final result = await loadingFuture;
      return result;
    } finally {
      // Remove from queue when done
      _loadingQueue.remove(cacheKey);
    }
  }
  
  /// Internal basic loading method
  Future<rive.Artboard?> _loadBasicAvatarWithQueue(String avatarId, String assetPath) async {
    // Use same instance ID for consistency
    final instanceId = _avatarInstanceIds[avatarId] ?? DateTime.now().millisecondsSinceEpoch;
    final cacheKey = '${avatarId}_${instanceId}_basic';
    
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
      try {
        if (_riveFileCache.containsKey(assetPath)) {
          rivFile = _riveFileCache[assetPath]!;
          log.info('📁 Using cached RIVE file for basic artboard: $assetPath');
        } else {
          log.info('📁 Loading RIVE file for basic artboard: $assetPath for $avatarId');
          rivFile = await rive.RiveFile.asset(assetPath);
          _riveFileCache[assetPath] = rivFile;
          log.info('📁 Loaded and cached RIVE file for basic artboard: $assetPath');
        }
      } catch (e) {
        log.severe('❌ Error loading RIVE file for basic artboard $assetPath for $avatarId: $e');
        if (e.toString().contains('RangeError')) {
          log.severe('🔍 RangeError during RIVE file loading for basic artboard!');
        }
        rethrow;
      }

      rive.Artboard artboard;
      try {
        log.info('🎨 Creating basic artboard instance for $avatarId from $assetPath');
        artboard = rivFile.mainArtboard.instance();
        log.info('✅ Basic artboard instance created for $avatarId');
      } catch (e) {
        log.severe('❌ Error creating basic artboard instance for $avatarId: $e');
        if (e.toString().contains('RangeError')) {
          log.severe('🔍 RangeError during basic artboard instance creation!');
          log.severe('🔍 This is likely the source of the RangeError!');
        }
        rethrow;
      }
      
      // Check if avatar has customization enabled before creating state machine controller
      final config = AvatarAnimationsConfig.getConfig(avatarId);
      final hasCustomization = config?.customProperties?['hasCustomization'] ?? false;
      
      rive.StateMachineController? controller;
      if (hasCustomization) {
        // Create basic controller for animations only for avatars that support customization
        try {
          controller = rive.StateMachineController.fromArtboard(artboard, 'State Machine 1');
          if (controller != null) {
            artboard.addController(controller);
            
            // Start default idle animation
            _startDefaultAnimation(controller, avatarId);
          }
        } catch (e) {
          log.severe('❌ Error creating basic state machine controller for $avatarId: $e');
          if (e.toString().contains('RangeError') || e.toString().contains('range')) {
            log.severe('🔍 RangeError detected during basic state machine creation for $avatarId');
            log.severe('🔍 This may indicate a mismatch between expected and actual state machine count');
          }
        }
      } else {
        log.info('ℹ️ Avatar $avatarId has customization disabled, using simple animation approach');
        
        // For avatars without state machines, use simple animations
        try {
          final config = AvatarAnimationsConfig.getConfigWithFallback(avatarId);
          final defaultAnimationName = config.defaultAnimation;
          
          // Try to play the default animation directly
          final animations = artboard.animations;
          if (animations.isNotEmpty) {
            // Find animation by name or use first available
            rive.LinearAnimationInstance? animationToPlay;
            
            for (final animation in animations) {
              if (animation.name.toLowerCase() == defaultAnimationName.toLowerCase() ||
                  animation.name.toLowerCase().contains('fly') ||
                  animation.name.toLowerCase().contains('idle')) {
                animationToPlay = rive.LinearAnimationInstance(animation);
                break;
              }
            }
            
            // Fallback to first animation
            animationToPlay ??= rive.LinearAnimationInstance(animations.first);
            
            // animationToPlay is guaranteed to be non-null here due to the ??= operator above
            artboard.addController(rive.SimpleAnimation(animationToPlay.animation.name));
            log.info('✅ Started simple animation: ${animationToPlay.animation.name} for $avatarId');
          }
        } catch (e) {
          log.warning('⚠️ Could not start simple animation for $avatarId: $e');
        }
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
      if (avatarId == 'quantum_coach' || avatarId == 'director_coach') {
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
      } else if (cached?.artboard != null) {
        // Handle avatars without state machine controllers (like solar_coach)
        log.info('🎬 Avatar $avatarId has no state machine controller, attempting simple animation trigger');
        return _triggerSimpleAnimation(cached!.artboard, animationName, avatarId);
      } else {
        log.warning('⚠️ No cached artboard found for $avatarId ($cacheKey)');
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

  /// Helper method to trigger animation on a controller with safety checks
  bool _triggerAnimationOnController(rive.StateMachineController controller, String animationName, String context) {
    try {
      // Special handling for solar_coach
      if (context == 'solar_coach') {
        return _triggerSolarCoachAnimation(controller, animationName);
      }
      
      // Add safety check for potential index-based access issues
      if (controller.inputs.isEmpty) {
        log.warning('⚠️ No inputs available in controller for $context');
        return false;
      }
      
      log.info('🔍 Looking for trigger: "$animationName" in ${controller.inputs.length} inputs for $context');
      
      // First try to find and fire a trigger input by exact name match
      for (final input in controller.inputs) {
        log.fine('🔍 Checking input: "${input.name}" (${input.runtimeType})');
        if (input.name.toLowerCase() == animationName.toLowerCase()) {
          if (input is rive.SMITrigger) {
            try {
              input.fire();
              log.info('🎬 Triggered animation: $animationName for $context');
              return true;
            } catch (e) {
              log.severe('❌ Error firing trigger $animationName: $e');
              if (e.toString().contains('RangeError')) {
                log.severe('🔍 RangeError during trigger fire - this is the source!');
              }
              return false;
            }
          } else if (input is rive.SMIBool) {
            try {
              // For boolean inputs, set to true to activate the animation state
              input.value = true;
              log.info('🎬 Set boolean state: $animationName = true for $context');
              return true;
            } catch (e) {
              log.severe('❌ Error setting boolean $animationName: $e');
              return false;
            }
          } else if (input is rive.SMINumber) {
            try {
              // For number inputs, try setting to 1
              input.value = 1.0;
              log.info('🎬 Set number state: $animationName = 1.0 for $context');
              return true;
            } catch (e) {
              log.severe('❌ Error setting number $animationName: $e');
              return false;
            }
          }
        }
      }
      
      // If no exact match, try fallback strategies
      if (animationName.toLowerCase().contains('idle') || animationName.toLowerCase() == 'click ri') {
        // For solar_coach or idle requests, try the first available trigger
        for (final input in controller.inputs) {
          if (input is rive.SMITrigger) {
            try {
              input.fire();
              log.info('🎬 Triggered fallback animation: ${input.name} for $context (requested: $animationName)');
              return true;
            } catch (e) {
              log.severe('❌ Error firing fallback trigger ${input.name}: $e');
              if (e.toString().contains('RangeError')) {
                log.severe('🔍 RangeError during fallback trigger fire!');
              }
            }
          }
        }
      }
      
      log.warning('⚠️ Animation trigger not found: $animationName for $context. Available inputs: ${controller.inputs.map((i) => '${i.name} (${i.runtimeType})').join(', ')}');
      return false;
    } catch (e) {
      log.severe('❌ Error triggering animation $animationName for $context: $e');
      // Log additional context for RangeError debugging
      if (e.toString().contains('RangeError') || e.toString().contains('range')) {
        log.severe('🔍 RangeError detected - Controller inputs count: ${controller.inputs.length}');
        log.severe('🔍 Requested animation: $animationName for context: $context');
        log.severe('🔍 Available inputs: ${controller.inputs.map((i) => i.name).join(', ')}');
      }
      return false;
    }
  }

  /// Trigger simple animation for avatars without state machine controllers
  bool _triggerSimpleAnimation(rive.Artboard artboard, String animationName, String avatarId) {
    try {
      log.info('🎬 Attempting simple animation for $avatarId: $animationName');
      
      // Remove any existing controllers (Rive doesn't have removeAllControllers method)
      // Controllers are automatically managed by Rive when new ones are added
      
      // Find the animation by name
      rive.LinearAnimation? targetAnimation;
      for (final animation in artboard.animations) {
        // Try exact match first
        if (animation.name.toLowerCase() == animationName.toLowerCase()) {
          if (animation is rive.LinearAnimation) {
            targetAnimation = animation;
            break;
          }
        }
      }
      
      // If no exact match, try partial matches
      if (targetAnimation == null) {
        for (final animation in artboard.animations) {
          if (animation.name.toLowerCase().contains(animationName.toLowerCase()) ||
              animationName.toLowerCase().contains(animation.name.toLowerCase())) {
            if (animation is rive.LinearAnimation) {
              targetAnimation = animation;
              break;
            }
          }
        }
      }
      
      // Fallback to animations that might be suitable
      if (targetAnimation == null) {
        final fallbackNames = ['first fly', 'second fly', 'fly', 'idle', 'click'];
        for (final fallback in fallbackNames) {
          for (final animation in artboard.animations) {
            if (animation.name.toLowerCase().contains(fallback)) {
              if (animation is rive.LinearAnimation) {
                targetAnimation = animation;
                break;
              }
            }
          }
          if (targetAnimation != null) break;
        }
      }
      
      // Ultimate fallback: first linear animation
      if (targetAnimation == null) {
        for (final animation in artboard.animations) {
          if (animation is rive.LinearAnimation) {
            targetAnimation = animation;
            break;
          }
        }
      }
      
      if (targetAnimation != null) {
        final simpleController = rive.SimpleAnimation(targetAnimation.name, autoplay: true);
        artboard.addController(simpleController);
        log.info('✅ Started simple animation: ${targetAnimation.name} for $avatarId');
        return true;
      } else {
        log.warning('⚠️ No suitable animation found for $avatarId');
        return false;
      }
    } catch (e) {
      log.severe('❌ Error triggering simple animation for $avatarId: $e');
      if (e.toString().contains('RangeError') || e.toString().contains('range')) {
        log.severe('🔍 RangeError in simple animation - this might be the source!');
      }
      return false;
    }
  }

  /// Dedicated animation trigger for solar_coach
  bool _triggerSolarCoachAnimation(rive.StateMachineController controller, String animationName) {
    try {
      log.info('🌞 Triggering solar_coach animation for: $animationName');
      
      // Solar coach uses "click ri" trigger and "HV 1" boolean
      final clickTrigger = controller.findSMI('click ri');
      final booleanInput = controller.findInput<bool>('HV 1');
      
      if (clickTrigger is rive.SMITrigger) {
        clickTrigger.fire();
        log.info('🌞 Solar coach click trigger fired');
        
        // Toggle boolean state to create variation
        if (booleanInput is rive.SMIBool) {
          booleanInput.value = !booleanInput.value;
          log.info('🌞 Solar coach boolean toggled to: ${booleanInput.value}');
        }
        
        return true;
      } else {
        log.warning('⚠️ Solar coach click trigger not found');
        return false;
      }
    } catch (e) {
      log.severe('❌ Error triggering solar_coach animation: $e');
      return false;
    }
  }

  /// EMERGENCY ISOLATED: solar_coach handler that bypasses ALL normal logic
  Future<rive.Artboard?> _getSolarCoachIsolatedArtboard(String assetPath) async {
    try {
      log.info('🌞 ISOLATED: Creating solar_coach with NO state machine access');
      
      // Load fresh artboard - no caching, no controllers, no state machines
      final rivFile = await rive.RiveFile.asset(assetPath);
      final artboard = rivFile.mainArtboard.instance();
      
      // DON'T add any controllers - just return raw artboard
      // This prevents ANY state machine access that could cause RangeError
      
      log.info('🌞 ISOLATED: Solar coach raw artboard created successfully');
      return artboard;
      
    } catch (e) {
      log.severe('❌ ISOLATED: Error creating solar_coach artboard: $e');
      return null;
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
        if (avatarId == 'quantum_coach' || avatarId == 'director_coach') {
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
        log.info('! No cached controller found for in-place update: $avatarId');
        return false;
      }
    } catch (e) {
      log.warning('❌ Error updating customizations in place for $avatarId: $e');
      return false;
    }
  }

  /// Invalidate cached artboard for an avatar (call when customizations change)
  void invalidateArtboard(String avatarId) {
    // Find and invalidate all cache entries for this avatar (with any instance ID)
    final keysToRemove = <String>[];
    for (final key in _artboardCache.keys) {
      if (key.startsWith('${avatarId}_')) {
        keysToRemove.add(key);
      }
    }
    
    for (final key in keysToRemove) {
      try {
        _artboardCache[key]!.dispose();
        _artboardCache.remove(key);
        log.info('🗑️ Invalidated artboard cache: $key');
      } catch (e) {
        log.warning('⚠️ Error disposing artboard $key: $e');
        _artboardCache.remove(key);
      }
    }
    
    // Reset instance ID for this avatar to force fresh loading
    _avatarInstanceIds.remove(avatarId);
    log.info('✅ Reset instance ID for $avatarId - will get fresh artboard on next load');
  }

  /// Force clear all caches for quantum_coach and director_coach to resolve conflicts
  void clearCustomizableAvatarCaches() {
    log.info('🔄 Force clearing all quantum_coach and director_coach caches with isolation');
    invalidateArtboard('quantum_coach');
    invalidateArtboard('director_coach');
    log.info('✅ Cleared all customizable avatar caches independently');
  }
  
  /// Debug method to verify avatar isolation
  void debugAvatarIsolation() {
    log.info('🔍 AVATAR ISOLATION DEBUG:');
    log.info('Instance IDs: $_avatarInstanceIds');
    log.info('Cached artboards: ${_artboardCache.keys.toList()}');
    log.info('Loading queue: ${_loadingQueue.keys.toList()}');
  }
  
  /// Clear all cached artboards (call on app shutdown or memory pressure)
  void dispose() {
    log.info('🧹 Disposing all cached artboards');
    
    // Clear loading queue
    _loadingQueue.clear();
    
    for (final cached in _artboardCache.values) {
      try {
        cached.dispose();
      } catch (e) {
        // Protect against RangeError during mass disposal
        log.warning('⚠️ Error disposing cached artboard: $e');
      }
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
      try {
        // Safe controller disposal with RangeError protection
        controller?.dispose();
      } catch (e) {
        // Catch and log RangeError during controller disposal
        if (e.toString().contains('RangeError')) {
          log.warning('⚠️ RangeError during controller disposal (likely state machine index issue): $e');
        } else {
          log.warning('⚠️ Error during controller disposal: $e');
        }
        // Continue with disposal even if controller.dispose() fails
      }
      _disposed = true;
    }
  }
}