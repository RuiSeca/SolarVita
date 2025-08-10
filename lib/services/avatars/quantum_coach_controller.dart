import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'avatar_interaction_manager.dart';

final log = Logger('QuantumCoachController');

/// Available locations for Quantum Coach teleportation within AI screen
enum CoachLocation {
  ecoCard,     // Eco button at top center
  workoutCard, // Workout button in grid
  mealCard,    // Meal button in grid  
  scheduleCard,// Schedule button in grid
  foodCard,    // Food recognizer button in grid
}

/// Specific controller for Quantum Coach teleportation interactions
class QuantumCoachController extends AvatarInteractionController {
  final ValueNotifier<CoachLocation> _currentLocation = ValueNotifier(CoachLocation.ecoCard);
  final ValueNotifier<bool> _isVisible = ValueNotifier(true);
  final ValueNotifier<String> _currentAnimation = ValueNotifier('Idle');
  final ValueNotifier<int> _teleportationStep = ValueNotifier(0);

  // Available animations for random selection
  static const List<String> _availableAnimations = [
    'Idle',
    'scratching head',
    'flower out',
    'flower in',
    'jump 2',
    'jumpidle',
    'jumpright',
    'jumpleft',
    'win 2',
    'star idle action 1',
    'staractTouch',
    'Sitting position (No. 5)',
    'Sitting posture (No. 2)',
  ];

  // Teleportation sequence between card locations within AI screen
  static const List<CoachLocation> _teleportationSequence = [
    CoachLocation.ecoCard,     // Start with eco button (top center)
    CoachLocation.workoutCard, // Move to workout button 
    CoachLocation.mealCard,    // Move to meal button
    CoachLocation.scheduleCard,// Move to schedule button
    CoachLocation.foodCard,    // End with food recognizer button
  ];

  QuantumCoachController({
    required super.avatarId,
  }) : super(avatarType: AvatarType.quantumCoach);

  /// Get current location
  ValueListenable<CoachLocation> get currentLocation => _currentLocation;

  /// Get visibility state
  ValueListenable<bool> get isVisible => _isVisible;

  /// Get current animation
  ValueListenable<String> get currentAnimation => _currentAnimation;

  /// Get teleportation step (0-4)
  ValueListenable<int> get teleportationStep => _teleportationStep;

  @override
  Future<void> handleInteraction(AvatarInteractionType type) async {
    if (type != AvatarInteractionType.singleTap) return;

    final currentStep = _teleportationStep.value;
    log.info('🌌 Quantum Coach interaction - Step: $currentStep');

    switch (currentStep) {
      case 0: // Step 1 (AI Screen): Click → Jump animation → Teleport to random location
        await _performJumpAndTeleport();
        break;
      case 1:
      case 2:
      case 3: // Steps 2-4: Click → Idle → Random animation → Move to next location
        await _performRandomAnimationAndMove();
        break;
      case 4: // Step 5: Click → Win animation → Return to AI screen → Reset cycle
        await _performWinAnimationAndReturn();
        break;
    }
  }

  /// Step 1: Jump animation and teleport to random location
  Future<void> _performJumpAndTeleport() async {
    final teleportData = TeleportationData(
      avatarId: avatarId,
      avatarType: avatarType,
      interactionType: AvatarInteractionType.sequence,
      timestamp: DateTime.now(),
      locations: _teleportationSequence.map((e) => e.name).toList(),
      currentLocation: _currentLocation.value.name,
      currentStep: 0,
      locationAnimations: {
        for (var loc in _teleportationSequence)
          loc.name: AvatarAnimationState.jumping
      },
    );

    updateInteraction(teleportData);

    // Play jump animation
    _currentAnimation.value = 'jump 2';
    
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Teleport to next location in sequence (start with workoutCard after ecoCard)
    final currentIndex = _teleportationSequence.indexOf(_currentLocation.value);
    final nextIndex = (currentIndex + 1) % _teleportationSequence.length;
    final nextLocation = _teleportationSequence[nextIndex];
    
    _currentLocation.value = nextLocation;
    _teleportationStep.value = 1;
    _currentAnimation.value = 'Idle';
    
    log.info('🌌 Quantum Coach teleported to ${nextLocation.name}');
  }

  /// Steps 2-4: Random animation and move to next location
  Future<void> _performRandomAnimationAndMove() async {
    final currentStep = _teleportationStep.value;
    
    final teleportData = TeleportationData(
      avatarId: avatarId,
      avatarType: avatarType,
      interactionType: AvatarInteractionType.sequence,
      timestamp: DateTime.now(),
      locations: _teleportationSequence.map((e) => e.name).toList(),
      currentLocation: _currentLocation.value.name,
      currentStep: currentStep,
      locationAnimations: {
        for (var loc in _teleportationSequence)
          loc.name: AvatarAnimationState.custom
      },
    );

    updateInteraction(teleportData);

    // Start with idle
    _currentAnimation.value = 'Idle';
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Play random animation
    final randomAnimation = _availableAnimations[Random().nextInt(_availableAnimations.length)];
    _currentAnimation.value = randomAnimation;
    
    // Animation duration varies by type
    Duration animationDuration = const Duration(seconds: 2);
    if (randomAnimation.contains('jump')) {
      animationDuration = const Duration(seconds: 3);
    } else if (randomAnimation.contains('win')) {
      animationDuration = const Duration(seconds: 4);
    }
    
    await Future.delayed(animationDuration);
    
    // Move to next location
    final currentIndex = _teleportationSequence.indexOf(_currentLocation.value);
    final nextIndex = (currentIndex + 1) % _teleportationSequence.length;
    final nextLocation = _teleportationSequence[nextIndex];
    
    // Brief invisibility for teleportation effect
    _isVisible.value = false;
    await Future.delayed(const Duration(milliseconds: 300));
    
    _currentLocation.value = nextLocation;
    _isVisible.value = true;
    _currentAnimation.value = 'Idle';
    _teleportationStep.value = currentStep + 1;
    
    log.info('🌌 Quantum Coach moved to ${nextLocation.name} (step ${currentStep + 1})');
  }

  /// Step 5: Win animation and return to AI screen
  Future<void> _performWinAnimationAndReturn() async {
    final teleportData = TeleportationData(
      avatarId: avatarId,
      avatarType: avatarType,
      interactionType: AvatarInteractionType.sequence,
      timestamp: DateTime.now(),
      locations: _teleportationSequence.map((e) => e.name).toList(),
      currentLocation: _currentLocation.value.name,
      currentStep: 4,
      locationAnimations: {
        for (var loc in _teleportationSequence)
          loc.name: AvatarAnimationState.celebrating
      },
    );

    updateInteraction(teleportData);

    // Play win animation
    _currentAnimation.value = 'win 2';
    
    await Future.delayed(const Duration(seconds: 3));
    
    // Teleport back to starting position (eco card) with celebration  
    _isVisible.value = false;
    await Future.delayed(const Duration(milliseconds: 500));
    
    _currentLocation.value = CoachLocation.ecoCard;
    _isVisible.value = true;
    _currentAnimation.value = 'star idle action 1';
    
    await Future.delayed(const Duration(seconds: 2));
    
    // Reset cycle
    _teleportationStep.value = 0;
    _currentAnimation.value = 'Idle';
    reset();
    
    log.info('🌌 Quantum Coach returned to AI screen and reset cycle');
  }

  /// Get random animation (useful for external triggers)
  String getRandomAnimation() {
    return _availableAnimations[Random().nextInt(_availableAnimations.length)];
  }

  /// Force teleport to specific location
  void teleportTo(CoachLocation location) {
    _currentLocation.value = location;
    _currentAnimation.value = 'Idle';
    log.info('🌌 Quantum Coach force teleported to ${location.name}');
  }

  @override
  void reset() {
    super.reset();
    _currentLocation.value = CoachLocation.aiScreen;
    _isVisible.value = true;
    _currentAnimation.value = 'Idle';
    _teleportationStep.value = 0;
    log.info('🌌 Quantum Coach reset');
  }

  @override
  void dispose() {
    super.dispose();
    _currentLocation.dispose();
    _isVisible.dispose();
    _currentAnimation.dispose();
    _teleportationStep.dispose();
  }
}