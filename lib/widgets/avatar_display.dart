import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart' as rive;
import '../config/avatar_animations_config.dart';
import '../providers/avatar/avatar_artboard_provider.dart';
import '../providers/avatar/unified_avatar_provider.dart';
import '../utils/rive_utils.dart';

class AvatarDisplay extends ConsumerStatefulWidget {
  final String? avatarId;
  final AnimationStage initialStage;
  final double width;
  final double height;
  final bool autoPlaySequence;
  final Duration sequenceDelay;
  final VoidCallback? onSequenceComplete;
  final BoxFit fit;
  final bool useCustomizations; // New flag to control customization loading
  final bool preferEquipped; // New flag to prefer equipped avatar over explicit avatarId

  const AvatarDisplay({
    super.key,
    this.avatarId,
    this.initialStage = AnimationStage.idle,
    this.width = 200,
    this.height = 200,
    this.autoPlaySequence = false,
    this.sequenceDelay = const Duration(seconds: 2),
    this.onSequenceComplete,
    this.fit = BoxFit.contain,
    this.useCustomizations = true, // Default to true for backward compatibility
    this.preferEquipped = false, // Default to false for backward compatibility
  });

  @override
  ConsumerState<AvatarDisplay> createState() => AvatarDisplayState();
}

class AvatarDisplayState extends ConsumerState<AvatarDisplay>
    with TickerProviderStateMixin {
  bool _isSequenceRunning = false;
  int _sequenceIndex = 0;
  String? _lastLoadedAvatarId; // Track last successfully loaded avatar to prevent cycling

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    try {
      // Use unified provider for consistent equipped avatar state
      final unifiedState = ref.watch(unifiedAvatarStateProvider);
      
      // Smart avatar ID resolution based on preferEquipped flag
      final effectiveAvatarId = widget.preferEquipped 
          ? (unifiedState.equippedAvatarId ?? widget.avatarId ?? 'mummy_coach')
          : (widget.avatarId ?? unifiedState.equippedAvatarId ?? 'mummy_coach');
      
      
      
      
      // Debug logging for equipped avatar
      debugPrint('🎭 AvatarDisplay build: widget.avatarId=${widget.avatarId}, unified.equipped=${unifiedState.equippedAvatarId}, effective=$effectiveAvatarId, preferEquipped=${widget.preferEquipped}');


    // Cache switching optimization - don't aggressively clear cache to prevent freezing
    if (_lastLoadedAvatarId != null && _lastLoadedAvatarId != effectiveAvatarId) {
      debugPrint('🔄 Avatar switching detected: $_lastLoadedAvatarId → $effectiveAvatarId (preserving cache for smooth transition)');
      // Removed aggressive cache clearing that was causing freezing between customized avatars
    }


    // Use appropriate provider based on whether customizations are needed
    final artboardProvider = widget.useCustomizations 
        ? customizedArtboardProvider(effectiveAvatarId)
        : basicArtboardProvider(effectiveAvatarId);
    
    final artboardAsync = ref.watch(artboardProvider);

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: artboardAsync.when(
        data: (artboard) {
          if (artboard != null) {
            // Update last successfully loaded avatar ID
            _lastLoadedAvatarId = effectiveAvatarId;
            
            // Start animation sequence if requested and not already running
            if (widget.autoPlaySequence && !_isSequenceRunning) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _startAnimationSequence(artboard);
              });
            }
            
            try {
              return rive.Rive(
                artboard: artboard,
                fit: widget.fit,
              );
            } catch (e) {
              debugPrint('❌ Error rendering Rive widget for $effectiveAvatarId: $e');
              if (e.toString().contains('RangeError')) {
                debugPrint('🔍 RangeError in Rive widget rendering!');
                debugPrint('🔍 This is likely the source of the RangeError!');
              }
              return _buildFallback(effectiveAvatarId);
            }
          } else {
            return _buildFallback(effectiveAvatarId);
          }
        },
        loading: () {
          // During loading, show the last successfully loaded avatar if available
          final loadingAvatarId = _lastLoadedAvatarId ?? effectiveAvatarId;
          return _buildLoading(loadingAvatarId);
        },
        error: (error, stack) {
          debugPrint('❌ Error loading artboard for $effectiveAvatarId: $error');
          return _buildFallback(effectiveAvatarId);
        },
      ),
    );
    } catch (e) {
      // EMERGENCY CIRCUIT BREAKER: Catch any RangeError and show safe fallback
      debugPrint('🚨 EMERGENCY: Avatar display error caught: $e');
      if (e.toString().contains('RangeError')) {
        debugPrint('🚨 EMERGENCY: RangeError in AvatarDisplay build - using emergency fallback');
        return _buildEmergencyFallback('error_avatar');
      }
      // Re-throw non-RangeError exceptions
      rethrow;
    }
  }


  Widget _buildEmergencyFallback(String avatarId) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.warning,
            size: widget.width * 0.3,
            color: Colors.red[600] ?? Colors.red,
          ),
          const SizedBox(height: 8),
          Text(
            'Avatar Error',
            style: TextStyle(
              color: Colors.red[600] ?? Colors.red,
              fontSize: widget.width * 0.06,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(String avatarId) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: widget.width * 0.2,
            height: widget.width * 0.2,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Loading $avatarId...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: widget.width * 0.06,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFallback(String avatarId) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person,
            size: widget.width * 0.4,
            color: Colors.grey,
          ),
          const SizedBox(height: 8),
          Text(
            avatarId,
            style: TextStyle(
              color: Colors.grey,
              fontSize: widget.width * 0.08,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _startAnimationSequence(rive.Artboard artboard) {
    if (_isSequenceRunning || !widget.autoPlaySequence) return;
    
    final unifiedState = ref.read(unifiedAvatarStateProvider);
    final effectiveAvatarId = widget.preferEquipped 
        ? (unifiedState.equippedAvatarId ?? widget.avatarId ?? 'mummy_coach')
        : (widget.avatarId ?? unifiedState.equippedAvatarId ?? 'mummy_coach');
    final sequenceOrder = AvatarAnimationsConfig.getSequenceOrder(effectiveAvatarId);
    
    if (sequenceOrder == null || sequenceOrder.isEmpty) return;

    // Find the state machine controller from the artboard
    final controller = _findStateMachineController(artboard);
    if (controller == null) return;

    _isSequenceRunning = true;
    _sequenceIndex = 0;
    _playSequenceStep(controller, effectiveAvatarId);
  }

  void _playSequenceStep(rive.StateMachineController controller, String avatarId) {
    if (!mounted || !_isSequenceRunning) return;
    
    final sequenceOrder = AvatarAnimationsConfig.getSequenceOrder(avatarId);
    if (sequenceOrder == null || _sequenceIndex >= sequenceOrder.length) {
      _isSequenceRunning = false;
      _sequenceIndex = 0;
      widget.onSequenceComplete?.call();
      return;
    }

    final animationName = sequenceOrder[_sequenceIndex];
    _playAnimation(controller, animationName, avatarId);
    
    _sequenceIndex++;
    
    Future.delayed(widget.sequenceDelay, () {
      if (mounted && _isSequenceRunning) {
        _playSequenceStep(controller, avatarId);
      }
    });
  }

  void _playAnimation(rive.StateMachineController controller, String animationName, String avatarId) {
    try {
      // Use safe animation triggering utility
      final success = RiveUtils.safeTriggerAnimation(controller, animationName, avatarId);
      
      if (!success) {
        debugPrint('⚠️ Failed to trigger animation $animationName for $avatarId');
      }
    } catch (e) {
      debugPrint('❌ Error playing animation $animationName: $e');
    }
  }

  rive.StateMachineController? _findStateMachineController(rive.Artboard artboard) {
    try {
      // Look for any StateMachineController in the artboard
      return artboard.animations.whereType<rive.StateMachineController>().firstOrNull;
    } catch (e) {
      debugPrint('❌ Error finding StateMachineController: $e');
      return null;
    }
  }

  void stopSequence() {
    _isSequenceRunning = false;
  }

  void playStage(AnimationStage stage) {
    try {
      final unifiedState = ref.read(unifiedAvatarStateProvider);
      final effectiveAvatarId = widget.preferEquipped 
          ? (unifiedState.equippedAvatarId ?? widget.avatarId ?? 'mummy_coach')
          : (widget.avatarId ?? unifiedState.equippedAvatarId ?? 'mummy_coach');
      
      // Validate if the avatar supports this animation stage
      if (!AvatarAnimationsConfig.supportsAnimationStage(effectiveAvatarId, stage)) {
        final fallbackStage = AvatarAnimationsConfig.getFallbackStage(effectiveAvatarId, stage);
        debugPrint('⚠️ Avatar $effectiveAvatarId does not support stage $stage, falling back to $fallbackStage');
        stage = fallbackStage;
      }
      
      final config = AvatarAnimationsConfig.getConfigWithFallback(effectiveAvatarId);
      
      // Get the animation name for this stage
      final animationName = config.getAnimation(stage) ?? config.defaultAnimation;
      
      // Use the artboard cache notifier to trigger the animation
      final cacheNotifier = ref.read(artboardCacheNotifierProvider);
      final success = cacheNotifier.triggerAnimation(
        effectiveAvatarId, 
        animationName, 
        useCustomized: widget.useCustomizations
      );
      
      if (success) {
        debugPrint('✅ Successfully triggered $animationName for stage $stage on $effectiveAvatarId');
      } else {
        debugPrint('⚠️ Failed to trigger $animationName for stage $stage on $effectiveAvatarId');
      }
    } catch (e) {
      debugPrint('❌ Error in playStage: $e');
    }
  }

  /// Trigger a specific animation by name
  void triggerAnimation(String animationName) {
    try {
      final unifiedState = ref.read(unifiedAvatarStateProvider);
      final effectiveAvatarId = widget.preferEquipped 
          ? (unifiedState.equippedAvatarId ?? widget.avatarId ?? 'mummy_coach')
          : (widget.avatarId ?? unifiedState.equippedAvatarId ?? 'mummy_coach');
      
      final cacheNotifier = ref.read(artboardCacheNotifierProvider);
      final success = cacheNotifier.triggerAnimation(
        effectiveAvatarId, 
        animationName, 
        useCustomized: widget.useCustomizations
      );
      
      if (success) {
        debugPrint('✅ Successfully triggered animation $animationName on $effectiveAvatarId');
      } else {
        debugPrint('⚠️ Failed to trigger animation $animationName on $effectiveAvatarId');
      }
    } catch (e) {
      debugPrint('❌ Error triggering animation $animationName: $e');
    }
  }

  /// Set a number input on the avatar (for external control)
  void setNumberInput(String inputName, double value) {
    try {
      final unifiedState = ref.read(unifiedAvatarStateProvider);
      final effectiveAvatarId = widget.preferEquipped 
          ? (unifiedState.equippedAvatarId ?? widget.avatarId ?? 'mummy_coach')
          : (widget.avatarId ?? unifiedState.equippedAvatarId ?? 'mummy_coach');
      
      final cacheNotifier = ref.read(artboardCacheNotifierProvider);
      final success = cacheNotifier.setNumberInput(
        effectiveAvatarId, 
        inputName, 
        value, 
        useCustomized: widget.useCustomizations
      );
      
      if (success) {
        debugPrint('✅ Successfully set $inputName = $value on $effectiveAvatarId');
      } else {
        debugPrint('⚠️ Failed to set $inputName = $value on $effectiveAvatarId');
      }
    } catch (e) {
      debugPrint('❌ Error setting number input $inputName: $e');
    }
  }

  /// Set a boolean input on the avatar (for external control)
  void setBoolInput(String inputName, bool value) {
    try {
      final unifiedState = ref.read(unifiedAvatarStateProvider);
      final effectiveAvatarId = widget.preferEquipped 
          ? (unifiedState.equippedAvatarId ?? widget.avatarId ?? 'mummy_coach')
          : (widget.avatarId ?? unifiedState.equippedAvatarId ?? 'mummy_coach');
      
      final cacheNotifier = ref.read(artboardCacheNotifierProvider);
      final success = cacheNotifier.setBoolInput(
        effectiveAvatarId, 
        inputName, 
        value, 
        useCustomized: widget.useCustomizations
      );
      
      if (success) {
        debugPrint('✅ Successfully set $inputName = $value on $effectiveAvatarId');
      } else {
        debugPrint('⚠️ Failed to set $inputName = $value on $effectiveAvatarId');
      }
    } catch (e) {
      debugPrint('❌ Error setting bool input $inputName: $e');
    }
  }
}