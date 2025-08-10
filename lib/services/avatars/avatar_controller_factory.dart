import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../../widgets/avatar_display.dart';
import 'avatar_interaction_manager.dart';
import 'mummy_avatar_controller.dart';
import 'quantum_coach_controller.dart';

final log = Logger('AvatarControllerFactory');

/// Factory class for creating avatar controllers
class AvatarControllerFactory {
  static final AvatarControllerFactory _instance = AvatarControllerFactory._internal();
  factory AvatarControllerFactory() => _instance;
  AvatarControllerFactory._internal();

  final AvatarInteractionManager _manager = AvatarInteractionManager();

  /// Create and register a Mummy Avatar controller
  MummyAvatarController createMummyController({
    required String avatarId,
    GlobalKey<AvatarDisplayState>? headerAvatarKey,
    GlobalKey<AvatarDisplayState>? largeAvatarKey,
  }) {
    log.info('Creating Mummy Avatar controller: $avatarId');
    
    final controller = MummyAvatarController(
      avatarId: avatarId,
      headerAvatarKey: headerAvatarKey,
      largeAvatarKey: largeAvatarKey,
    );

    _manager.registerController(controller);
    return controller;
  }

  /// Create and register a Quantum Coach controller
  QuantumCoachController createQuantumCoachController({
    required String avatarId,
  }) {
    log.info('Creating Quantum Coach controller: $avatarId');
    
    final controller = QuantumCoachController(avatarId: avatarId);
    
    _manager.registerController(controller);
    return controller;
  }

  /// Create controller based on avatar type
  AvatarInteractionController? createController({
    required String avatarId,
    required AvatarType avatarType,
    Map<String, dynamic>? parameters,
  }) {
    log.info('Creating controller for $avatarType: $avatarId');

    switch (avatarType) {
      case AvatarType.mummy:
        return createMummyController(
          avatarId: avatarId,
          headerAvatarKey: parameters?['headerAvatarKey'],
          largeAvatarKey: parameters?['largeAvatarKey'],
        );
      
      case AvatarType.quantumCoach:
        return createQuantumCoachController(avatarId: avatarId);
      
      case AvatarType.robot:
      case AvatarType.dragon:
      case AvatarType.fairy:
        // Future avatar types - will be implemented as needed
        log.info('Avatar type $avatarType will be implemented in future releases');
        return null;
    }
  }

  /// Get the global manager instance
  AvatarInteractionManager get manager => _manager;

  /// Convenience method to trigger interaction
  Future<void> triggerInteraction(String avatarId, AvatarInteractionType type) async {
    await _manager.triggerInteraction(avatarId, type);
  }

  /// Convenience method to get controller
  T? getController<T extends AvatarInteractionController>(String avatarId) {
    final controller = _manager.getController(avatarId);
    if (controller is T) {
      return controller;
    }
    return null;
  }

  /// Cleanup specific avatar
  void removeAvatar(String avatarId) {
    log.info('Removing avatar controller: $avatarId');
    _manager.unregisterController(avatarId);
  }

  /// Cleanup all avatars
  void removeAllAvatars() {
    log.info('Removing all avatar controllers');
    _manager.resetAll();
  }
}

/// Extension methods for easier access
extension AvatarControllerFactoryExtensions on AvatarControllerFactory {
  /// Quick access to mummy controller
  MummyAvatarController? getMummyController(String avatarId) {
    return getController<MummyAvatarController>(avatarId);
  }

  /// Quick access to quantum coach controller
  QuantumCoachController? getQuantumCoachController(String avatarId) {
    return getController<QuantumCoachController>(avatarId);
  }
}