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
  final ValueNotifier<bool> _showHeaderAvatar = ValueNotifier(true);
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

  /// Get header avatar key
  GlobalKey<AvatarDisplayState>? get headerAvatarKey => _headerAvatarKey;

  /// Get large avatar key  
  GlobalKey<AvatarDisplayState>? get largeAvatarKey => _largeAvatarKey;

  /// Get whether header avatar should be shown
  ValueListenable<bool> get showHeaderAvatar => _showHeaderAvatar;

  @override
  Future<void> handleInteraction(AvatarInteractionType type) async {
    if (type != AvatarInteractionType.singleTap) return;

    final currentStage = _animationStage.value;
    log.info('🧟 Mummy avatar interaction - Stage: $currentStage');

    // Add defensive checks based on stage
    if (currentStage == 0) {
      // Stage 0 requires header avatar for jump animation
      if (headerAvatarKey?.currentState == null) {
        log.warning('⚠️ Header avatar key is null, cannot proceed with stage 0');
        return;
      }
    } else {
      // Stages 1-3 require large avatar for animations
      if (largeAvatarKey?.currentState == null) {
        log.warning('⚠️ Large avatar key is null, cannot proceed with stage $currentStage');
        return;
      }
    }

    try {
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
        default:
          log.warning('⚠️ Unknown animation stage: $currentStage');
          break;
      }
    } catch (e, stackTrace) {
      log.severe('❌ Error in mummy avatar interaction: $e', e, stackTrace);
      // Reset to safe state if error occurs
      _animationStage.value = 0;
      _showLargeAvatar.value = false;
      _showHeaderAvatar.value = true;
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
      durations: [const Duration(seconds: 4)],
      currentStep: 0,
    );

    updateInteraction(animationData);

    // Trigger jump animation on header avatar
    _headerAvatarKey?.currentState?.playStage(AnimationStage.jump);
    
    // Wait 4 seconds for jump animation
    await Future.delayed(const Duration(seconds: 4));
    
    _showLargeAvatar.value = true;
    _showHeaderAvatar.value = false; // Hide header when large avatar shows
    _animationStage.value = 1;
    
    // Set to idle on large avatar after teleport
    _largeAvatarKey?.currentState?.playStage(AnimationStage.idle);
    
    log.info('🧟 Mummy teleported to large view');
  }

  /// Stage 1: Run animation for 8 seconds
  Future<void> _performRunAnimation() async {
    final animationData = AnimationSequenceData(
      avatarId: avatarId,
      avatarType: avatarType,
      interactionType: AvatarInteractionType.sequence,
      timestamp: DateTime.now(),
      animationSequence: [AvatarAnimationState.running],
      durations: [const Duration(seconds: 8)],
      currentStep: 1,
    );

    updateInteraction(animationData);

    _largeAvatarKey?.currentState?.playStage(AnimationStage.run);
    
    await Future.delayed(const Duration(seconds: 8));
    
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

    // Validate large avatar key before using
    final largeState = _largeAvatarKey?.currentState;
    if (largeState != null) {
      largeState.playStage(AnimationStage.jump);
    } else {
      log.warning('⚠️ Large avatar key is null during final jump');
    }
    
    await Future.delayed(const Duration(seconds: 6));
    
    // Return to profile with error handling
    try {
      _showLargeAvatar.value = false;
      _showHeaderAvatar.value = true; // Show header avatar again
      _animationStage.value = 0; // Reset cycle
      
      // Stop sequence and reset header avatar with validation
      final largeState = _largeAvatarKey?.currentState;
      if (largeState != null) {
        largeState.stopSequence();
      }
      
      final headerState = _headerAvatarKey?.currentState;
      if (headerState != null) {
        headerState.playStage(AnimationStage.idle);
      } else {
        log.warning('⚠️ Header avatar key is null during reset');
      }
      
      // Reset interaction state
      reset();
      
      log.info('🧟 Mummy returned to profile');
    } catch (e, stackTrace) {
      log.severe('❌ Error during mummy return to profile: $e', e, stackTrace);
      // Force reset to safe state
      _showLargeAvatar.value = false;
      _showHeaderAvatar.value = true;
      _animationStage.value = 0;
    }
  }

  @override
  void reset() {
    super.reset();
    _showLargeAvatar.value = false;
    _showHeaderAvatar.value = true;
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