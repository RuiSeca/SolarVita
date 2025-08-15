// Avatar animation configuration system
// Maps each avatar to its specific .riv file and available animations

enum AnimationStage { idle, jump, run, attack, teleport }

class AvatarAnimationConfig {
  final String avatarId;
  final String rivAssetPath;
  final Map<AnimationStage, String> animations;
  final String defaultAnimation;
  final Map<String, dynamic>? customProperties;

  const AvatarAnimationConfig({
    required this.avatarId,
    required this.rivAssetPath,
    required this.animations,
    required this.defaultAnimation,
    this.customProperties,
  });

  String? getAnimation(AnimationStage stage) {
    return animations[stage];
  }

  bool hasAnimation(AnimationStage stage) {
    return animations.containsKey(stage) && animations[stage] != null;
  }

  List<AnimationStage> get availableStages {
    return animations.keys.toList();
  }
}

class AvatarAnimationsConfig {
  static const Map<String, AvatarAnimationConfig> _configs = {
    'mummy_coach': AvatarAnimationConfig(
      avatarId: 'mummy_coach',
      rivAssetPath: 'assets/rive/mummy.riv',
      animations: {
        AnimationStage.idle: 'Idle',
        AnimationStage.jump: 'Jump',
        AnimationStage.run: 'Run',
        AnimationStage.attack: 'Attack',
      },
      defaultAnimation: 'Idle',
      customProperties: {
        'hasComplexSequence': true,
        'supportsTeleport': true,
        'sequenceOrder': ['Idle', 'Jump', 'Run', 'Attack', 'Jump'],
      },
    ),
    'classic_coach': AvatarAnimationConfig(
      avatarId: 'classic_coach',
      rivAssetPath: 'assets/rive/mummy.riv', // Using mummy.riv as fallback
      animations: {
        AnimationStage.idle: 'Idle',
        AnimationStage.jump: 'Jump',
        AnimationStage.run: 'Run',
      },
      defaultAnimation: 'Idle',
      customProperties: {
        'hasComplexSequence': false,
        'supportsTeleport': false,
      },
    ),
    'director_coach': AvatarAnimationConfig(
      avatarId: 'director_coach',
      rivAssetPath: 'assets/rive/director_coach.riv',
      animations: {
        AnimationStage.idle: 'starAct_Touch', // Use actual SMITrigger
        AnimationStage.jump: 'jump', // Use actual SMITrigger
        AnimationStage.run: 'Act_Touch', // Use actual SMITrigger
        AnimationStage.attack: 'Act_1', // Use actual SMITrigger
        AnimationStage.teleport: 'win', // Use actual SMITrigger
      },
      defaultAnimation: 'starAct_Touch', // Use actual SMITrigger as default
      customProperties: {
        'hasComplexSequence': true,
        'supportsTeleport': false,
        'hasCustomization': true, // Enable customization system
        'customizationTypes': ['eyes', 'face', 'skin', 'clothing', 'accessories', 'hair'],
        'sequenceOrder': ['starAct_Touch', 'jump', 'Act_Touch', 'Act_1', 'win'], // Use actual triggers
        'useStateMachine': true, // Uses State Machine 1 for advanced features
        'availableAnimations': ['starAct_Touch', 'Act_Touch', 'Act_1', 'back_in', 'win', 'jump'], // Actual SMITriggers
        'theme': 'movie_director',
        'eyeColors': 10, // eye 0 through eye 9
        'stateMachineInputs': {
          'triggers': ['starAct_Touch', 'Act_Touch', 'Act_1', 'back_in', 'win', 'jump'],
          'booleans': ['jumpright_check', 'home', 'flower_check'],
          'numbers': ['stateaction', 'flower_state']
        },
      },
    ),
    'ninja_coach': AvatarAnimationConfig(
      avatarId: 'ninja_coach',
      rivAssetPath: 'assets/rive/ninja.riv',
      animations: {
        AnimationStage.idle: 'Idle',
        AnimationStage.jump: 'Jump',
        AnimationStage.run: 'Run',
        AnimationStage.attack: 'Attack',
        AnimationStage.teleport: 'Teleport',
      },
      defaultAnimation: 'Idle',
      customProperties: {
        'hasComplexSequence': true,
        'supportsTeleport': true,
        'sequenceOrder': ['Idle', 'Teleport', 'Attack', 'Jump'],
      },
    ),
    'robot_coach': AvatarAnimationConfig(
      avatarId: 'robot_coach',
      rivAssetPath: 'assets/rive/robot.riv',
      animations: {
        AnimationStage.idle: 'Idle',
        AnimationStage.run: 'Run',
        AnimationStage.attack: 'Laser',
      },
      defaultAnimation: 'Idle',
      customProperties: {
        'hasComplexSequence': false,
        'supportsTeleport': false,
        'sequenceOrder': ['Idle', 'Run', 'Laser'],
      },
    ),
    'wizard_coach': AvatarAnimationConfig(
      avatarId: 'wizard_coach',
      rivAssetPath: 'assets/rive/wizard.riv',
      animations: {
        AnimationStage.idle: 'Idle',
        AnimationStage.jump: 'Float',
        AnimationStage.attack: 'Spell',
        AnimationStage.teleport: 'Teleport',
      },
      defaultAnimation: 'Idle',
      customProperties: {
        'hasComplexSequence': true,
        'supportsTeleport': true,
        'sequenceOrder': ['Idle', 'Float', 'Spell', 'Teleport'],
      },
    ),
    'dragon_coach': AvatarAnimationConfig(
      avatarId: 'dragon_coach',
      rivAssetPath: 'assets/rive/dragon.riv',
      animations: {
        AnimationStage.idle: 'Idle',
        AnimationStage.jump: 'Fly',
        AnimationStage.run: 'Run',
        AnimationStage.attack: 'FireBreath',
      },
      defaultAnimation: 'Idle',
      customProperties: {
        'hasComplexSequence': true,
        'supportsTeleport': false,
        'sequenceOrder': ['Idle', 'Fly', 'Run', 'FireBreath'],
      },
    ),
    'quantum_coach': AvatarAnimationConfig(
      avatarId: 'quantum_coach',
      rivAssetPath: 'assets/rive/quantum_coach.riv',
      animations: {
        AnimationStage.idle: 'starAct_Touch', // Use actual SMITrigger (same as director)
        AnimationStage.jump: 'jump', // Use actual SMITrigger
        AnimationStage.run: 'Act_Touch', // Use actual SMITrigger
        AnimationStage.attack: 'Act_1', // Use actual SMITrigger
        AnimationStage.teleport: 'win', // Use actual SMITrigger
      },
      defaultAnimation: 'starAct_Touch', // Same default as director_coach
      customProperties: {
        'hasComplexSequence': true,
        'supportsTeleport': true,
        'hasCustomization': true,
        'customizationTypes': ['eyes', 'skin', 'clothing'],
        'availableAnimations': ['starAct_Touch', 'Act_Touch', 'Act_1', 'back_in', 'win', 'jump'], // Actual SMITriggers
        'sequenceOrder': ['starAct_Touch', 'jump', 'Act_Touch', 'Act_1', 'win'], // Use actual triggers
        'useStateMachine': true, // Uses state machine
        'stateMachineInputs': {
          'triggers': ['starAct_Touch', 'Act_Touch', 'Act_1', 'back_in', 'win', 'jump'],
          'booleans': ['jumpright_check', 'home', 'flower_check'],
          'numbers': ['stateaction', 'flower_state']
        },
      },
    ),
    'solar_coach': AvatarAnimationConfig(
      avatarId: 'solar_coach',
      rivAssetPath: 'assets/rive/solar.riv',
      animations: {
        AnimationStage.idle: 'State Machine 1',
        AnimationStage.jump: 'State Machine 1', 
        AnimationStage.run: 'State Machine 1',
        AnimationStage.attack: 'State Machine 1',
      },
      defaultAnimation: 'State Machine 1',
      customProperties: {
        'hasComplexSequence': false,
        'supportsTeleport': false,
        'hasCustomization': true, // Enable to use state machine
        'useDirectStateMachine': true, // New flag for direct state machine usage
        'stateMachineName': 'State Machine 1',
        'triggerInput': 'click ri', // Single trigger input
        'booleanInput': 'HV 1', // Boolean input for state control
        'availableAnimations': ['ClICK 5', 'ClICK 4', 'ClICK 3', 'ClICK 2', 'ClICK 1', 'SECOND FLY', 'FIRST FLY'],
        'sequenceOrder': ['State Machine 1'],
      },
    ),
  };

  /// Get animation configuration for a specific avatar
  static AvatarAnimationConfig? getConfig(String avatarId) {
    return _configs[avatarId];
  }

  /// Get all available avatar IDs with animation configs
  static List<String> get availableAvatarIds {
    return _configs.keys.toList();
  }

  /// Check if avatar has animation configuration
  static bool hasConfig(String avatarId) {
    return _configs.containsKey(avatarId);
  }

  /// Get default fallback config for unknown avatars
  static AvatarAnimationConfig getDefaultConfig() {
    return const AvatarAnimationConfig(
      avatarId: 'classic_coach',
      rivAssetPath: 'assets/rive/mummy.riv', // Using mummy.riv as fallback
      animations: {AnimationStage.idle: 'Idle'},
      defaultAnimation: 'Idle',
      customProperties: {
        'hasComplexSequence': false,
        'supportsTeleport': false,
      },
    );
  }

  /// Get config with fallback to default
  static AvatarAnimationConfig getConfigWithFallback(String avatarId) {
    return getConfig(avatarId) ?? getDefaultConfig();
  }

  /// Get all configs
  static Map<String, AvatarAnimationConfig> get allConfigs => _configs;

  /// Check if avatar supports complex animation sequences
  static bool supportsComplexSequence(String avatarId) {
    final config = getConfig(avatarId);
    return config?.customProperties?['hasComplexSequence'] ?? false;
  }

  /// Check if avatar supports teleportation
  static bool supportsTeleport(String avatarId) {
    final config = getConfig(avatarId);
    return config?.customProperties?['supportsTeleport'] ?? false;
  }

  /// Check if avatar supports a specific animation stage
  static bool supportsAnimationStage(String avatarId, AnimationStage stage) {
    final config = getConfig(avatarId);
    if (config == null) return false;
    return config.animations.containsKey(stage);
  }

  /// Get fallback animation stage for unsupported stages
  static AnimationStage getFallbackStage(String avatarId, AnimationStage requestedStage) {
    final config = getConfigWithFallback(avatarId);
    
    // If the requested stage is supported, return it
    if (config.animations.containsKey(requestedStage)) {
      return requestedStage;
    }
    
    // Fallback priority: idle -> jump -> first available
    if (config.animations.containsKey(AnimationStage.idle)) {
      return AnimationStage.idle;
    }
    if (config.animations.containsKey(AnimationStage.jump)) {
      return AnimationStage.jump;
    }
    
    // Return first available animation stage
    return config.animations.keys.first;
  }

  /// Get animation sequence order for avatar
  static List<String>? getSequenceOrder(String avatarId) {
    final config = getConfig(avatarId);
    return config?.customProperties?['sequenceOrder']?.cast<String>();
  }

  /// Get animation for specific stage with fallback
  static String getAnimationForStage(String avatarId, AnimationStage stage) {
    final config = getConfigWithFallback(avatarId);
    return config.getAnimation(stage) ?? config.defaultAnimation;
  }

  /// Get Rive asset path for avatar
  static String getRivePath(String avatarId) {
    final config = getConfigWithFallback(avatarId);
    return config.rivAssetPath;
  }
}
