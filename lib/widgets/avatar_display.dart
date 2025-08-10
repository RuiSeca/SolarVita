import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart' as rive;
import '../config/avatar_animations_config.dart';
import '../providers/riverpod/avatar_state_provider.dart';

class AvatarDisplay extends ConsumerStatefulWidget {
  final String? avatarId;
  final AnimationStage initialStage;
  final double width;
  final double height;
  final bool autoPlaySequence;
  final Duration sequenceDelay;
  final VoidCallback? onSequenceComplete;
  final BoxFit fit;

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
  });

  @override
  ConsumerState<AvatarDisplay> createState() => AvatarDisplayState();
}

class AvatarDisplayState extends ConsumerState<AvatarDisplay>
    with TickerProviderStateMixin {
  rive.RiveAnimationController? _controller;
  rive.Artboard? _artboard;
  AvatarAnimationConfig? _currentConfig;
  AnimationStage _currentStage = AnimationStage.idle;
  bool _isSequenceRunning = false;
  int _sequenceIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentStage = widget.initialStage;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String get _effectiveAvatarId {
    if (widget.avatarId != null) {
      return widget.avatarId!;
    }
    
    // Use equipped avatar from state
    final avatarState = ref.read(avatarStateProvider).valueOrNull;
    return avatarState?.equippedAvatarId ?? 'classic_coach';
  }

  @override
  Widget build(BuildContext context) {
    final avatarId = _effectiveAvatarId;
    final config = AvatarAnimationsConfig.getConfigWithFallback(avatarId);

    // Reload if avatar configuration changed
    if (_currentConfig?.avatarId != config.avatarId) {
      _currentConfig = config;
      _loadAvatarAnimation();
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: _artboard != null
          ? rive.Rive(
              artboard: _artboard!,
              fit: widget.fit,
            )
          : _buildFallback(avatarId),
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
            'Loading...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadAvatarAnimation() async {
    if (_currentConfig == null) return;

    try {
      final rivFile = await rive.RiveFile.asset(_currentConfig!.rivAssetPath);
      final artboard = rivFile.mainArtboard;
      
      // Clone the artboard to avoid sharing state
      final clonedArtboard = artboard.instance();
      
      // Set up state machine or direct animation control
      rive.RiveAnimationController? controller = rive.StateMachineController.fromArtboard(
        clonedArtboard,
        'State Machine 1', // Default state machine name
      );
      
      // Fallback to simple animation controller if no state machine
      controller ??= rive.SimpleAnimation(_currentConfig!.defaultAnimation);
      
      clonedArtboard.addController(controller);
      _controller?.dispose();
      _controller = controller;
      
      setState(() {
        _artboard = clonedArtboard;
      });

      // Start auto sequence if enabled
      if (widget.autoPlaySequence && mounted) {
        _startAutoSequence();
      } else {
        // Play initial animation
        _playAnimation(_currentStage);
      }
    } catch (e) {
      debugPrint('Failed to load avatar animation: $e');
      // Keep current state or show fallback
    }
  }

  void _playAnimation(AnimationStage stage) {
    if (_currentConfig == null || _controller == null) return;

    final animationName = _currentConfig!.getAnimation(stage);
    if (animationName == null) return;

    _currentStage = stage;

    // Handle different controller types
    if (_controller is rive.StateMachineController) {
      // Trigger state machine inputs if available
      final stateMachine = _controller as rive.StateMachineController;
      
      // Look for trigger inputs that match our animation names
      for (final input in stateMachine.inputs) {
        if (input.name.toLowerCase() == animationName.toLowerCase() && 
            input is rive.SMITrigger) {
          input.fire();
          break;
        }
      }
    } else if (_controller is rive.SimpleAnimation) {
      // For simple animations, we'd need to recreate with new animation
      // This is more complex, so we'll stick with the current approach
    }
  }

  void _startAutoSequence() {
    if (_isSequenceRunning || !widget.autoPlaySequence) return;

    final sequenceOrder = AvatarAnimationsConfig.getSequenceOrder(_effectiveAvatarId);
    if (sequenceOrder == null || sequenceOrder.isEmpty) return;

    _isSequenceRunning = true;
    _sequenceIndex = 0;
    _playNextInSequence(sequenceOrder);
  }

  void _playNextInSequence(List<String> sequence) {
    if (!mounted || !_isSequenceRunning) return;

    if (_sequenceIndex >= sequence.length) {
      _isSequenceRunning = false;
      _sequenceIndex = 0;
      widget.onSequenceComplete?.call();
      
      // Restart sequence after delay if still auto-playing
      if (widget.autoPlaySequence) {
        Future.delayed(widget.sequenceDelay, () {
          if (mounted && widget.autoPlaySequence) {
            _startAutoSequence();
          }
        });
      }
      return;
    }

    final animationName = sequence[_sequenceIndex];
    final stage = _getStageFromAnimationName(animationName);
    
    if (stage != null) {
      _playAnimation(stage);
    }

    _sequenceIndex++;

    // Schedule next animation
    Future.delayed(widget.sequenceDelay, () {
      _playNextInSequence(sequence);
    });
  }

  AnimationStage? _getStageFromAnimationName(String animationName) {
    if (_currentConfig == null) return null;

    for (final entry in _currentConfig!.animations.entries) {
      if (entry.value == animationName) {
        return entry.key;
      }
    }
    return null;
  }

  // Public methods for external control
  void playStage(AnimationStage stage) {
    if (mounted) {
      _playAnimation(stage);
    }
  }

  void startSequence() {
    if (mounted) {
      _startAutoSequence();
    }
  }

  void stopSequence() {
    _isSequenceRunning = false;
    if (mounted) {
      _playAnimation(AnimationStage.idle);
    }
  }

  bool get isSequenceRunning => _isSequenceRunning;
  AnimationStage get currentStage => _currentStage;
  String? get currentAvatarId => _currentConfig?.avatarId;
}