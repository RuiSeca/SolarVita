import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final log = Logger('InteractiveCoachProvider');

enum CoachLocation {
  aiScreen,
  mealPlan,
  workoutTips,
  ecoStats,
}

enum CoachAnimationState {
  idle,
  animating,
  teleporting,
  winning,
}

class InteractiveCoachState {
  final CoachLocation currentLocation;
  final CoachAnimationState animationState;
  final String currentAnimation;
  final int animationCycleStep;
  final bool isVisible;

  const InteractiveCoachState({
    this.currentLocation = CoachLocation.aiScreen,
    this.animationState = CoachAnimationState.idle,
    this.currentAnimation = 'Idle',
    this.animationCycleStep = 0,
    this.isVisible = true,
  });

  InteractiveCoachState copyWith({
    CoachLocation? currentLocation,
    CoachAnimationState? animationState,
    String? currentAnimation,
    int? animationCycleStep,
    bool? isVisible,
  }) {
    return InteractiveCoachState(
      currentLocation: currentLocation ?? this.currentLocation,
      animationState: animationState ?? this.animationState,
      currentAnimation: currentAnimation ?? this.currentAnimation,
      animationCycleStep: animationCycleStep ?? this.animationCycleStep,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

class InteractiveCoachNotifier extends StateNotifier<InteractiveCoachState> {
  InteractiveCoachNotifier() : super(const InteractiveCoachState());

  // Available animations for the interactive system
  static const List<String> availableAnimations = [
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
    'actTouch1', // act touch animations
    'actTouch2',
    'actTouch3',
    'actTouch4',
    'actTouch5',
    'Sitting position', // No. 5
    'sitting posture', // No. 2
  ];

  // Locations for the teleportation cycle
  static const List<CoachLocation> teleportLocations = [
    CoachLocation.mealPlan,
    CoachLocation.workoutTips,
    CoachLocation.ecoStats,
  ];

  final Random _random = Random();

  /// Handle coach click - main interaction logic
  Future<void> handleCoachClick() async {
    if (state.animationState == CoachAnimationState.animating) {
      return; // Don't interrupt ongoing animations
    }

    log.info('🎮 Coach clicked at step ${state.animationCycleStep} in ${state.currentLocation.name}');

    switch (state.animationCycleStep) {
      case 0:
        await _performJumpAndTeleport();
        break;
      case 1:
      case 2:
      case 3:
        await _performRandomAnimationAndMove();
        break;
      case 4:
        await _performWinAnimationAndReturn();
        break;
    }
  }

  /// Step 1: Jump animation and teleport to random location
  Future<void> _performJumpAndTeleport() async {
    state = state.copyWith(
      animationState: CoachAnimationState.animating,
      currentAnimation: 'jump 2',
    );

    // Wait for jump animation
    await Future.delayed(const Duration(milliseconds: 1500));

    // Choose random teleport location
    final newLocation = teleportLocations[_random.nextInt(teleportLocations.length)];
    
    log.info('🚀 Teleporting to ${newLocation.name}');

    state = state.copyWith(
      currentLocation: newLocation,
      animationState: CoachAnimationState.idle,
      currentAnimation: 'Idle',
      animationCycleStep: 1,
    );
  }

  /// Steps 2-4: Random animation then move to next location
  Future<void> _performRandomAnimationAndMove() async {
    // First show idle
    state = state.copyWith(
      animationState: CoachAnimationState.idle,
      currentAnimation: 'Idle',
    );

    await Future.delayed(const Duration(milliseconds: 800));

    // Then perform random animation
    final randomAnimation = _getRandomAnimation();
    log.info('🎭 Playing random animation: $randomAnimation');

    state = state.copyWith(
      animationState: CoachAnimationState.animating,
      currentAnimation: randomAnimation,
    );

    await Future.delayed(const Duration(milliseconds: 2000));

    // Move to next location or prepare for win
    final currentStep = state.animationCycleStep;
    if (currentStep < 4) {
      final nextLocation = _getNextLocation();
      log.info('📍 Moving to ${nextLocation.name}');

      state = state.copyWith(
        currentLocation: nextLocation,
        animationState: CoachAnimationState.idle,
        currentAnimation: 'Idle',
        animationCycleStep: currentStep + 1,
      );
    }
  }

  /// Step 5: Win animation and return to AI screen
  Future<void> _performWinAnimationAndReturn() async {
    log.info('🏆 Playing win animation and returning to AI screen');

    state = state.copyWith(
      animationState: CoachAnimationState.winning,
      currentAnimation: 'win 2',
    );

    await Future.delayed(const Duration(milliseconds: 3000));

    // Return to AI screen and reset cycle
    state = state.copyWith(
      currentLocation: CoachLocation.aiScreen,
      animationState: CoachAnimationState.idle,
      currentAnimation: 'Idle',
      animationCycleStep: 0,
    );

    log.info('🔄 Cycle complete - back to AI screen');
  }

  /// Get a random animation from available animations
  String _getRandomAnimation() {
    final animations = availableAnimations.where((anim) => anim != 'Idle').toList();
    return animations[_random.nextInt(animations.length)];
  }

  /// Get next location in the cycle
  CoachLocation _getNextLocation() {
    final currentIndex = teleportLocations.indexOf(state.currentLocation);
    if (currentIndex == -1) {
      // If somehow not in teleport locations, go to first one
      return teleportLocations.first;
    }
    
    // Move to next location, or stay at current if it's the last step
    if (currentIndex < teleportLocations.length - 1) {
      return teleportLocations[currentIndex + 1];
    }
    
    // Stay at current location for final step
    return state.currentLocation;
  }

  /// Reset the coach state (for debugging or manual reset)
  void resetCoach() {
    log.info('🔄 Resetting coach to initial state');
    state = const InteractiveCoachState();
  }

  /// Force coach to specific location (for debugging)
  void forceLocation(CoachLocation location) {
    log.info('🎯 Forcing coach to ${location.name}');
    state = state.copyWith(currentLocation: location);
  }

  /// Force specific animation (for debugging)
  void forceAnimation(String animation) {
    log.info('🎭 Forcing animation: $animation');
    state = state.copyWith(
      animationState: CoachAnimationState.animating,
      currentAnimation: animation,
    );
  }
}

// Main provider
final interactiveCoachProvider = StateNotifierProvider<InteractiveCoachNotifier, InteractiveCoachState>(
  (ref) => InteractiveCoachNotifier(),
);

// Convenience providers for specific locations
final coachVisibleOnAIScreenProvider = Provider<bool>((ref) {
  final coachState = ref.watch(interactiveCoachProvider);
  return coachState.currentLocation == CoachLocation.aiScreen && coachState.isVisible;
});

final coachVisibleOnMealPlanProvider = Provider<bool>((ref) {
  final coachState = ref.watch(interactiveCoachProvider);
  return coachState.currentLocation == CoachLocation.mealPlan && coachState.isVisible;
});

final coachVisibleOnWorkoutProvider = Provider<bool>((ref) {
  final coachState = ref.watch(interactiveCoachProvider);
  return coachState.currentLocation == CoachLocation.workoutTips && coachState.isVisible;
});

final coachVisibleOnEcoStatsProvider = Provider<bool>((ref) {
  final coachState = ref.watch(interactiveCoachProvider);
  return coachState.currentLocation == CoachLocation.ecoStats && coachState.isVisible;
});

// Current animation provider
final currentCoachAnimationProvider = Provider<String>((ref) {
  final coachState = ref.watch(interactiveCoachProvider);
  return coachState.currentAnimation;
});