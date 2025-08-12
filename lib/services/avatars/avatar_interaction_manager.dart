import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

final log = Logger('AvatarInteractionManager');

/// Enum defining different types of avatar interactions
enum AvatarInteractionType {
  singleTap,
  doubleTap,
  longPress,
  gesture,
  sequence,
}

/// Enum defining different avatar types
enum AvatarType {
  mummy,
  quantumCoach,
  robot,
  dragon,
  fairy,
  // Add more avatar types as needed
}

/// Enum defining avatar animation states
enum AvatarAnimationState {
  idle,
  jumping,
  running,
  attacking,
  celebrating,
  teleporting,
  custom,
}

/// Base class for avatar interaction data
abstract class AvatarInteractionData {
  final String avatarId;
  final AvatarType avatarType;
  final AvatarInteractionType interactionType;
  final DateTime timestamp;

  const AvatarInteractionData({
    required this.avatarId,
    required this.avatarType,
    required this.interactionType,
    required this.timestamp,
  });
}

/// Specific interaction data for animation sequences
class AnimationSequenceData extends AvatarInteractionData {
  final List<AvatarAnimationState> animationSequence;
  final List<Duration> durations;
  final int currentStep;
  final bool shouldLoop;

  const AnimationSequenceData({
    required super.avatarId,
    required super.avatarType,
    required super.interactionType,
    required super.timestamp,
    required this.animationSequence,
    required this.durations,
    this.currentStep = 0,
    this.shouldLoop = false,
  });

  AnimationSequenceData copyWith({
    int? currentStep,
    bool? shouldLoop,
  }) {
    return AnimationSequenceData(
      avatarId: avatarId,
      avatarType: avatarType,
      interactionType: interactionType,
      timestamp: timestamp,
      animationSequence: animationSequence,
      durations: durations,
      currentStep: currentStep ?? this.currentStep,
      shouldLoop: shouldLoop ?? this.shouldLoop,
    );
  }
}

/// Teleportation interaction data
class TeleportationData extends AvatarInteractionData {
  final List<String> locations;
  final String currentLocation;
  final int currentStep;
  final Map<String, AvatarAnimationState> locationAnimations;

  const TeleportationData({
    required super.avatarId,
    required super.avatarType,
    required super.interactionType,
    required super.timestamp,
    required this.locations,
    required this.currentLocation,
    this.currentStep = 0,
    required this.locationAnimations,
  });

  TeleportationData copyWith({
    String? currentLocation,
    int? currentStep,
  }) {
    return TeleportationData(
      avatarId: avatarId,
      avatarType: avatarType,
      interactionType: interactionType,
      timestamp: timestamp,
      locations: locations,
      currentLocation: currentLocation ?? this.currentLocation,
      currentStep: currentStep ?? this.currentStep,
      locationAnimations: locationAnimations,
    );
  }
}

/// Base abstract class for avatar interaction controllers
abstract class AvatarInteractionController {
  final String avatarId;
  final AvatarType avatarType;
  final ValueNotifier<AvatarInteractionData?> _currentInteraction;

  AvatarInteractionController({
    required this.avatarId,
    required this.avatarType,
  }) : _currentInteraction = ValueNotifier(null);

  /// Get current interaction state
  ValueListenable<AvatarInteractionData?> get currentInteraction => _currentInteraction;

  /// Handle avatar interaction
  Future<void> handleInteraction(AvatarInteractionType type);

  /// Reset interaction state
  void reset() {
    _currentInteraction.value = null;
  }

  /// Dispose resources
  void dispose() {
    _currentInteraction.dispose();
  }

  /// Update interaction state
  @protected
  void updateInteraction(AvatarInteractionData data) {
    _currentInteraction.value = data;
  }
}

/// Main manager class for all avatar interactions
class AvatarInteractionManager {
  static final AvatarInteractionManager _instance = AvatarInteractionManager._internal();
  factory AvatarInteractionManager() => _instance;
  AvatarInteractionManager._internal();

  final Map<String, AvatarInteractionController> _controllers = {};
  final ValueNotifier<Map<String, AvatarInteractionData>> _globalState = ValueNotifier({});

  /// Register an avatar interaction controller
  void registerController(AvatarInteractionController controller) {
    log.info('Registering avatar controller: ${controller.avatarId} (${controller.avatarType})');
    
    _controllers[controller.avatarId] = controller;
    
    // Listen to controller changes
    controller.currentInteraction.addListener(() {
      final interaction = controller.currentInteraction.value;
      if (interaction != null) {
        _updateGlobalState(controller.avatarId, interaction);
      }
    });
  }

  /// Unregister an avatar interaction controller
  void unregisterController(String avatarId) {
    log.info('Unregistering avatar controller: $avatarId');
    
    final controller = _controllers.remove(avatarId);
    controller?.dispose();
    
    // Remove from global state
    final currentState = Map<String, AvatarInteractionData>.from(_globalState.value);
    currentState.remove(avatarId);
    _globalState.value = currentState;
  }

  /// Get controller for specific avatar
  AvatarInteractionController? getController(String avatarId) {
    return _controllers[avatarId];
  }

  /// Get all controllers of a specific type
  List<AvatarInteractionController> getControllersByType(AvatarType type) {
    return _controllers.values
        .where((controller) => controller.avatarType == type)
        .toList();
  }

  /// Get global interaction state
  ValueListenable<Map<String, AvatarInteractionData>> get globalState => _globalState;

  /// Trigger interaction for specific avatar
  Future<void> triggerInteraction(String avatarId, AvatarInteractionType type) async {
    final controller = _controllers[avatarId];
    if (controller != null) {
      await controller.handleInteraction(type);
    } else {
      log.warning('No controller found for avatar: $avatarId');
    }
  }

  /// Reset all interactions
  void resetAll() {
    log.info('Resetting all avatar interactions');
    for (final controller in _controllers.values) {
      controller.reset();
    }
    _globalState.value = {};
  }

  /// Reset specific avatar interaction
  void resetAvatar(String avatarId) {
    final controller = _controllers[avatarId];
    if (controller != null) {
      controller.reset();
      final currentState = Map<String, AvatarInteractionData>.from(_globalState.value);
      currentState.remove(avatarId);
      _globalState.value = currentState;
    }
  }

  /// Private method to update global state
  void _updateGlobalState(String avatarId, AvatarInteractionData interaction) {
    final currentState = Map<String, AvatarInteractionData>.from(_globalState.value);
    currentState[avatarId] = interaction;
    _globalState.value = currentState;
  }

  /// Dispose all resources
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _globalState.dispose();
  }
}