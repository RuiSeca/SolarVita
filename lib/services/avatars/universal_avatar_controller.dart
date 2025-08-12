import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'avatar_interaction_manager.dart';
import '../../config/avatar_animations_config.dart';
import '../../widgets/avatar_display.dart';

final log = Logger('UniversalAvatarController');

/// Universal controller that handles ALL avatars with the same teleportation flow
/// Only the animations differ per avatar type - configured via JSON
class UniversalAvatarController extends AvatarInteractionController {
  final ValueNotifier<bool> _showLargeAvatar = ValueNotifier(false);
  final ValueNotifier<bool> _showHeaderAvatar = ValueNotifier(true);
  final ValueNotifier<int> _animationStage = ValueNotifier(0);
  
  final GlobalKey<AvatarDisplayState>? headerAvatarKey;
  final GlobalKey<AvatarDisplayState>? largeAvatarKey;
  final String _avatarTypeString;
  
  // Animation configuration for this specific avatar
  late final AvatarAnimationConfig _animationConfig;

  UniversalAvatarController({
    required super.avatarId,
    required String avatarType,
    this.headerAvatarKey,
    this.largeAvatarKey,
  }) : _avatarTypeString = avatarType, super(avatarType: _getAvatarTypeFromString(avatarType)) {
    _animationConfig = AvatarAnimationsConfig.getConfigWithFallback(avatarType);
    log.info('🎯 Universal controller created for $avatarType (ID: $avatarId) with animations: ${_animationConfig.animations.keys.join(", ")}');
    log.info('🎯 Using rive file: ${_animationConfig.rivAssetPath}');
  }

  /// Get the avatar type as string for external use
  String get avatarTypeString => _avatarTypeString;

  /// Convert string avatar type to AvatarType enum
  static AvatarType _getAvatarTypeFromString(String avatarType) {
    switch (avatarType.toLowerCase()) {
      case 'mummy_coach':
      case 'mummy':
        return AvatarType.mummy;
      case 'quantum_coach':
      case 'quantum':
        return AvatarType.quantumCoach;
      default:
        return AvatarType.mummy; // Default fallback
    }
  }

  /// Get whether large avatar should be shown
  ValueListenable<bool> get showLargeAvatar => _showLargeAvatar;

  /// Get whether header avatar should be shown  
  ValueListenable<bool> get showHeaderAvatar => _showHeaderAvatar;

  /// Get current animation stage
  ValueListenable<int> get animationStage => _animationStage;

  @override
  Future<void> handleInteraction(AvatarInteractionType type) async {
    if (type != AvatarInteractionType.singleTap) return;

    final currentStage = _animationStage.value;
    log.info('🎯 $_avatarTypeString interaction - Stage: $currentStage');

    // Stage-specific validation
    if (currentStage == 0) {
      if (headerAvatarKey?.currentState == null) {
        log.warning('⚠️ Header avatar key is null for $_avatarTypeString stage 0');
        return;
      }
    } else {
      if (largeAvatarKey?.currentState == null) {
        log.warning('⚠️ Large avatar key is null for $_avatarTypeString stage $currentStage');
        return;
      }
    }

    try {
      if (currentStage == 0) {
        // Stage 0: UNIVERSAL for all avatars (idle → jump → teleport)
        await _performUniversalJumpAndTeleport();
      } else {
        // Stages 1+: Avatar-specific behavior based on complexity/rarity
        await _performAvatarSpecificStage(currentStage);
      }
    } catch (e, stackTrace) {
      log.severe('❌ Error in $_avatarTypeString interaction: $e', e, stackTrace);
      // Reset to safe state
      _resetToSafeState();
    }
  }

  /// Stage 0: UNIVERSAL jump animation and teleport (same for ALL avatars)
  Future<void> _performUniversalJumpAndTeleport() async {
    final animationData = AnimationSequenceData(
      avatarId: avatarId,
      avatarType: avatarType, // This is the AvatarType enum from parent class
      interactionType: AvatarInteractionType.sequence,
      timestamp: DateTime.now(),
      animationSequence: [AvatarAnimationState.jumping],
      durations: [const Duration(seconds: 4)], // Universal 4 second jump
      currentStep: 0,
    );

    updateInteraction(animationData);

    // Play avatar-specific jump animation
    final headerState = headerAvatarKey?.currentState;
    if (headerState != null) {
      headerState.playStage(AnimationStage.jump);
    }

    await Future.delayed(const Duration(seconds: 4));

    // Hide header, show large avatar
    _showHeaderAvatar.value = false;
    _showLargeAvatar.value = true;
    _animationStage.value = 1;

    // Start with idle on large avatar
    final largeState = largeAvatarKey?.currentState;
    if (largeState != null) {
      largeState.playStage(AnimationStage.idle);
    }

    log.info('🎯 $_avatarTypeString teleported to large view');
  }

  /// Stages 1+: Avatar-specific behavior based on complexity/rarity
  Future<void> _performAvatarSpecificStage(int stage) async {
    // Get avatar complexity from config
    final isComplexAvatar = AvatarAnimationsConfig.supportsComplexSequence(_avatarTypeString);
    
    switch (_avatarTypeString.toLowerCase()) {
      case 'mummy_coach':
      case 'mummy':
        await _performMummyStages(stage);
        break;
      case 'quantum_coach':
      case 'quantum':
        await _performQuantumStages(stage);
        break;
      default:
        // Future expensive avatars will have more elaborate behaviors
        if (isComplexAvatar) {
          await _performComplexAvatarStages(stage);
        } else {
          await _performBasicAvatarStages(stage);
        }
        break;
    }
  }

  /// Mummy coach stages: Simple 3-stage sequence (basic avatar)
  Future<void> _performMummyStages(int stage) async {
    switch (stage) {
      case 1:
        await _performRunAnimation();
        break;
      case 2:
        await _performAttackAnimation();
        break;
      case 3:
        await _performFinalJumpAndReturn();
        break;
      default:
        log.warning('⚠️ Unknown stage $stage for mummy avatar');
        break;
    }
  }

  /// Quantum coach stages: Complex teleportation between cards (premium avatar)
  Future<void> _performQuantumStages(int stage) async {
    switch (stage) {
      case 1:
        // Quantum has unique startAct_Touch animation
        await _performQuantumStartTouch();
        break;
      case 2:
        // Then Act_Touch animation
        await _performQuantumActTouch();
        break;
      case 3:
        // Finally win animation and return
        await _performQuantumWinAndReturn();
        break;
      default:
        log.warning('⚠️ Unknown stage $stage for quantum coach avatar');
        break;
    }
  }

  /// Future expensive avatars: More elaborate behaviors
  Future<void> _performComplexAvatarStages(int stage) async {
    // Complex avatars could have 4+ stages with unique behaviors
    switch (stage) {
      case 1:
        await _performComplexStage1();
        break;
      case 2:
        await _performComplexStage2();
        break;
      case 3:
        await _performComplexStage3();
        break;
      case 4:
        await _performComplexStage4AndReturn();
        break;
      default:
        log.warning('⚠️ Unknown stage $stage for complex avatar');
        break;
    }
  }

  /// Basic avatars: Simple 2-stage sequence
  Future<void> _performBasicAvatarStages(int stage) async {
    switch (stage) {
      case 1:
        await _performBasicAnimation();
        break;
      case 2:
        await _performBasicJumpAndReturn();
        break;
      default:
        log.warning('⚠️ Unknown stage $stage for basic avatar');
        break;
    }
  }

  /// Mummy Stage 1: Run animation for 8 seconds
  Future<void> _performRunAnimation() async {
    final animationData = AnimationSequenceData(
      avatarId: avatarId,
      avatarType: avatarType, // AvatarType enum from parent
      interactionType: AvatarInteractionType.sequence,
      timestamp: DateTime.now(),
      animationSequence: [AvatarAnimationState.running],
      durations: [const Duration(seconds: 8)],
      currentStep: 1,
    );

    updateInteraction(animationData);

    final largeState = largeAvatarKey?.currentState;
    if (largeState != null) {
      largeState.playStage(AnimationStage.run);
    }

    await Future.delayed(const Duration(seconds: 8));
    _animationStage.value = 2;
    
    if (largeState != null) {
      largeState.playStage(AnimationStage.idle);
    }

    log.info('🧟 Mummy finished running animation');
  }

  /// Mummy Stage 2: Attack animation for 1 second
  Future<void> _performAttackAnimation() async {
    final animationData = AnimationSequenceData(
      avatarId: avatarId,
      avatarType: avatarType, // AvatarType enum from parent
      interactionType: AvatarInteractionType.sequence,
      timestamp: DateTime.now(),
      animationSequence: [AvatarAnimationState.attacking],
      durations: [const Duration(seconds: 1)],
      currentStep: 2,
    );

    updateInteraction(animationData);

    final largeState = largeAvatarKey?.currentState;
    if (largeState != null) {
      largeState.playStage(AnimationStage.attack);
    }

    await Future.delayed(const Duration(seconds: 1));
    _animationStage.value = 3;
    
    if (largeState != null) {
      largeState.playStage(AnimationStage.idle);
    }

    log.info('🧟 Mummy finished attack animation');
  }

  /// Mummy Stage 3: Final jump and return to header
  Future<void> _performFinalJumpAndReturn() async {
    final animationData = AnimationSequenceData(
      avatarId: avatarId,
      avatarType: avatarType, // AvatarType enum from parent
      interactionType: AvatarInteractionType.sequence,
      timestamp: DateTime.now(),
      animationSequence: [AvatarAnimationState.jumping],
      durations: [const Duration(seconds: 6)],
      currentStep: 3,
    );

    updateInteraction(animationData);

    final largeState = largeAvatarKey?.currentState;
    if (largeState != null) {
      largeState.playStage(AnimationStage.jump);
    }

    await Future.delayed(const Duration(seconds: 6));

    _showLargeAvatar.value = false;
    _showHeaderAvatar.value = true;
    _animationStage.value = 0;

    final headerState = headerAvatarKey?.currentState;
    if (headerState != null) {
      headerState.playStage(AnimationStage.idle);
    }

    final largeState2 = largeAvatarKey?.currentState;
    if (largeState2 != null) {
      largeState2.stopSequence();
    }

    reset();
    log.info('🧟 Mummy returned to header');
  }

  /// Quantum Stage 1: StartAct_Touch animation (doubled duration)
  Future<void> _performQuantumStartTouch() async {
    final largeState = largeAvatarKey?.currentState;
    if (largeState != null) {
      largeState.playStage(AnimationStage.attack); // Maps to startAct_Touch
    }

    await Future.delayed(const Duration(seconds: 4)); // Doubled from 2s
    _animationStage.value = 2;
    
    if (largeState != null) {
      largeState.playStage(AnimationStage.idle);
    }

    log.info('🌌 Quantum started touch sequence');
  }

  /// Quantum Stage 2: Act_Touch animation (doubled duration)
  Future<void> _performQuantumActTouch() async {
    final largeState = largeAvatarKey?.currentState;
    if (largeState != null) {
      largeState.playStage(AnimationStage.run); // Maps to Act_Touch
    }

    await Future.delayed(const Duration(seconds: 8)); // Doubled from 4s
    _animationStage.value = 3;
    
    if (largeState != null) {
      largeState.playStage(AnimationStage.idle);
    }

    log.info('🌌 Quantum performed touch animation');
  }

  /// Quantum Stage 3: Win animation and return (doubled duration)
  Future<void> _performQuantumWinAndReturn() async {
    final largeState = largeAvatarKey?.currentState;
    if (largeState != null) {
      largeState.playStage(AnimationStage.teleport); // Maps to win
    }

    await Future.delayed(const Duration(seconds: 6)); // Doubled from 3s

    _showLargeAvatar.value = false;
    _showHeaderAvatar.value = true;
    _animationStage.value = 0;

    final headerState = headerAvatarKey?.currentState;
    if (headerState != null) {
      headerState.playStage(AnimationStage.idle);
    }

    final largeState2 = largeAvatarKey?.currentState;
    if (largeState2 != null) {
      largeState2.stopSequence();
    }

    reset();
    log.info('🌌 Quantum coach returned to header');
  }

  /// Complex avatars Stage 1: Extended animation sequence
  Future<void> _performComplexStage1() async {
    final largeState = largeAvatarKey?.currentState;
    if (largeState != null) {
      largeState.playStage(AnimationStage.run);
    }
    await Future.delayed(const Duration(seconds: 5));
    _animationStage.value = 2;
    log.info('🔮 Complex avatar stage 1 complete');
  }

  /// Complex avatars Stage 2: Special ability animation
  Future<void> _performComplexStage2() async {
    final largeState = largeAvatarKey?.currentState;
    if (largeState != null) {
      largeState.playStage(AnimationStage.attack);
    }
    await Future.delayed(const Duration(seconds: 3));
    _animationStage.value = 3;
    log.info('🔮 Complex avatar stage 2 complete');
  }

  /// Complex avatars Stage 3: Ultimate move
  Future<void> _performComplexStage3() async {
    final largeState = largeAvatarKey?.currentState;
    if (largeState != null) {
      largeState.playStage(AnimationStage.teleport);
    }
    await Future.delayed(const Duration(seconds: 4));
    _animationStage.value = 4;
    log.info('🔮 Complex avatar stage 3 complete');
  }

  /// Complex avatars Stage 4: Final sequence and return
  Future<void> _performComplexStage4AndReturn() async {
    final largeState = largeAvatarKey?.currentState;
    if (largeState != null) {
      largeState.playStage(AnimationStage.jump);
    }
    await Future.delayed(const Duration(seconds: 6));

    _showLargeAvatar.value = false;
    _showHeaderAvatar.value = true;
    _animationStage.value = 0;

    final headerState = headerAvatarKey?.currentState;
    if (headerState != null) {
      headerState.playStage(AnimationStage.idle);
    }

    reset();
    log.info('🔮 Complex avatar returned to header');
  }

  /// Basic avatars Stage 1: Simple animation
  Future<void> _performBasicAnimation() async {
    final largeState = largeAvatarKey?.currentState;
    if (largeState != null) {
      largeState.playStage(AnimationStage.run);
    }
    await Future.delayed(const Duration(seconds: 3));
    _animationStage.value = 2;
    log.info('⚡ Basic avatar animation complete');
  }

  /// Basic avatars Stage 2: Jump and return
  Future<void> _performBasicJumpAndReturn() async {
    final largeState = largeAvatarKey?.currentState;
    if (largeState != null) {
      largeState.playStage(AnimationStage.jump);
    }
    await Future.delayed(const Duration(seconds: 3));

    _showLargeAvatar.value = false;
    _showHeaderAvatar.value = true;
    _animationStage.value = 0;

    final headerState = headerAvatarKey?.currentState;
    if (headerState != null) {
      headerState.playStage(AnimationStage.idle);
    }

    reset();
    log.info('⚡ Basic avatar returned to header');
  }

  /// Reset to safe state if error occurs
  void _resetToSafeState() {
    _showLargeAvatar.value = false;
    _showHeaderAvatar.value = true;
    _animationStage.value = 0;
    
    final headerState = headerAvatarKey?.currentState;
    if (headerState != null) {
      headerState.playStage(AnimationStage.idle);
    }
  }

  @override
  void reset() {
    super.reset();
    _showLargeAvatar.value = false;
    _showHeaderAvatar.value = true;
    _animationStage.value = 0;
    log.info('🎯 $_avatarTypeString reset');
  }

  @override
  void dispose() {
    super.dispose();
    _showLargeAvatar.dispose();
    _showHeaderAvatar.dispose();
    _animationStage.dispose();
  }
}