import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../../config/avatar_animations_config.dart';
import '../../widgets/avatar_display.dart';
import 'avatar_interaction_manager.dart';

final log = Logger('MummyAvatarController');

/// Specific controller for Mummy Avatar interactions
class MummyAvatarController extends AvatarInteractionController {
  final GlobalKey<AvatarDisplayState>? _headerAvatarKey;
  final GlobalKey<AvatarDisplayState>? _largeAvatarKey;
  final ValueNotifier<bool> _showLargeAvatar = ValueNotifier(false);
  final ValueNotifier<int> _animationStage = ValueNotifier(0);

  MummyAvatarController({
    required super.avatarId,
    GlobalKey<AvatarDisplayState>? headerAvatarKey,
    GlobalKey<AvatarDisplayState>? largeAvatarKey,
  }) : _headerAvatarKey = headerAvatarKey,
       _largeAvatarKey = largeAvatarKey,
       super(avatarType: AvatarType.mummy);

  /// Get current animation stage (0-3)
  ValueListenable<int> get animationStage => _animationStage;

  /// Get whether large avatar should be shown
  ValueListenable<bool> get showLargeAvatar => _showLargeAvatar;

  @override
  Future<void> handleInteraction(AvatarInteractionType type) async {
    if (type != AvatarInteractionType.singleTap) return;

    final currentStage = _animationStage.value;
    log.info('🧟 Mummy avatar interaction - Stage: $currentStage');

    switch (currentStage) {
      case 0: // First click: Idle -> Jump -> disappear and show large avatar
        await _performJumpAndTeleport();
        break;
      case 1: // Second click: Run animation for 10 seconds
        await _performRunAnimation();
        break;
      case 2: // Third click: Attack for 1 second
        await _performAttackAnimation();
        break;
      case 3: // Fourth click: Jump for 6 seconds -> back to profile
        await _performFinalJumpAndReturn();
        break;
    }
  }

  /// Stage 0: Jump animation and teleport to large avatar
  Future<void> _performJumpAndTeleport() async {
    final animationData = AnimationSequenceData(
      avatarId: avatarId,
      avatarType: avatarType,
      interactionType: AvatarInteractionType.sequence,
      timestamp: DateTime.now(),
      animationSequence: [AvatarAnimationState.jumping],
      durations: [const Duration(seconds: 2)],
      currentStep: 0,
    );

    updateInteraction(animationData);

    // Trigger jump animation on header avatar
    _headerAvatarKey?.currentState?.playStage(AnimationStage.jump);
    
    // Wait for animation, then show large avatar
    await Future.delayed(const Duration(seconds: 2));
    
    _showLargeAvatar.value = true;
    _animationStage.value = 1;
    
    // Start sequence on large avatar
    _largeAvatarKey?.currentState?.startSequence();
    
    log.info('🧟 Mummy teleported to large view');
  }

  /// Stage 1: Run animation for 10 seconds
  Future<void> _performRunAnimation() async {
    final animationData = AnimationSequenceData(
      avatarId: avatarId,
      avatarType: avatarType,
      interactionType: AvatarInteractionType.sequence,
      timestamp: DateTime.now(),
      animationSequence: [AvatarAnimationState.running],
      durations: [const Duration(seconds: 10)],
      currentStep: 1,
    );

    updateInteraction(animationData);

    _largeAvatarKey?.currentState?.playStage(AnimationStage.run);
    
    await Future.delayed(const Duration(seconds: 10));
    
    _animationStage.value = 2;
    _largeAvatarKey?.currentState?.playStage(AnimationStage.idle);
    
    log.info('🧟 Mummy finished running animation');
  }

  /// Stage 2: Attack animation for 1 second
  Future<void> _performAttackAnimation() async {
    final animationData = AnimationSequenceData(
      avatarId: avatarId,
      avatarType: avatarType,
      interactionType: AvatarInteractionType.sequence,
      timestamp: DateTime.now(),
      animationSequence: [AvatarAnimationState.attacking],
      durations: [const Duration(seconds: 1)],
      currentStep: 2,
    );

    updateInteraction(animationData);

    _largeAvatarKey?.currentState?.playStage(AnimationStage.attack);
    
    await Future.delayed(const Duration(seconds: 1));
    
    _animationStage.value = 3;
    _largeAvatarKey?.currentState?.playStage(AnimationStage.idle);
    
    log.info('🧟 Mummy finished attack animation');
  }

  /// Stage 3: Final jump and return to header
  Future<void> _performFinalJumpAndReturn() async {
    final animationData = AnimationSequenceData(
      avatarId: avatarId,
      avatarType: avatarType,
      interactionType: AvatarInteractionType.sequence,
      timestamp: DateTime.now(),
      animationSequence: [AvatarAnimationState.jumping],
      durations: [const Duration(seconds: 6)],
      currentStep: 3,
    );

    updateInteraction(animationData);

    _largeAvatarKey?.currentState?.playStage(AnimationStage.jump);
    
    await Future.delayed(const Duration(seconds: 6));
    
    // Return to profile
    _showLargeAvatar.value = false;
    _animationStage.value = 0; // Reset cycle
    
    // Stop sequence and reset header avatar
    _largeAvatarKey?.currentState?.stopSequence();
    _headerAvatarKey?.currentState?.playStage(AnimationStage.idle);
    
    // Reset interaction state
    reset();
    
    log.info('🧟 Mummy returned to profile');
  }

  @override
  void reset() {
    super.reset();
    _showLargeAvatar.value = false;
    _animationStage.value = 0;
    log.info('🧟 Mummy avatar reset');
  }

  @override
  void dispose() {
    super.dispose();
    _showLargeAvatar.dispose();
    _animationStage.dispose();
  }
}