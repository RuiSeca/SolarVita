import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class RiveEmojiWidget extends StatefulWidget {
  final EmojiType emojiType;
  final double size;
  final bool autoplay;
  final bool continuousPlay;

  const RiveEmojiWidget({
    super.key,
    required this.emojiType,
    this.size = 32,
    this.autoplay = true,
    this.continuousPlay = false,
  });

  @override
  State<RiveEmojiWidget> createState() => _RiveEmojiWidgetState();
}

class _RiveEmojiWidgetState extends State<RiveEmojiWidget> {
  SimpleAnimation? _controller;
  late Artboard? _artboard;
  Timer? _continuousPlayTimer;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: _buildRiveAnimation(),
    );
  }

  Widget _buildRiveAnimation() {
    try {
      debugPrint('🚀 Building Rive animation for: ${widget.emojiType.animationName}');
      
      if (widget.continuousPlay) {
        // For continuous play, use a controller approach
        return RiveAnimation.asset(
          'assets/rive/odin_emojis.riv',
          fit: BoxFit.contain,
          useArtboardSize: false,
          onInit: _onRiveInit,
        );
      } else {
        // For regular play, use SimpleAnimation with autoplay
        return RiveAnimation.asset(
          'assets/rive/odin_emojis.riv',
          animations: [widget.emojiType.animationName],
          fit: BoxFit.contain,
          useArtboardSize: false,
          onInit: widget.autoplay ? _onRiveInitAutoplay : null,
        );
      }
    } catch (e) {
      debugPrint('❌ Error loading Rive emoji: $e');
      // Fallback to text emoji
      return Center(
        child: Text(
          widget.emojiType.fallbackEmoji,
          style: TextStyle(fontSize: widget.size * 0.6),
        ),
      );
    }
  }

  void _onRiveInit(Artboard artboard) {
    _artboard = artboard;
    debugPrint('🎭 Rive artboard initialized for continuous play');
    
    // Start the first animation immediately
    _playAnimation();
    
    if (widget.continuousPlay) {
      _startContinuousPlay();
    }
  }

  void _onRiveInitAutoplay(Artboard artboard) {
    _artboard = artboard;
    debugPrint('🎭 Rive artboard initialized for autoplay');
    
    // For autoplay, start the animation immediately
    _playAnimation();
  }

  void _playAnimation() {
    if (_artboard == null) return;
    
    // Remove existing controller
    if (_controller != null) {
      _artboard!.removeController(_controller!);
      _controller!.dispose();
    }
    
    try {
      // Add new controller
      _controller = SimpleAnimation(widget.emojiType.animationName);
      _artboard!.addController(_controller!);
      debugPrint('🎬 Playing animation: ${widget.emojiType.animationName}');
    } catch (e) {
      debugPrint('❌ Animation "${widget.emojiType.animationName}" not found in Rive file: $e');
      // Try fallback to "Animation 1" if the current name fails
      try {
        _controller = SimpleAnimation('Animation 1');
        _artboard!.addController(_controller!);
        debugPrint('🔄 Fallback to Animation 1');
      } catch (fallbackError) {
        debugPrint('❌ Fallback animation also failed: $fallbackError');
      }
    }
  }

  void _startContinuousPlay() {
    if (!widget.continuousPlay) return;
    
    _continuousPlayTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        debugPrint('🔄 Restarting animation cycle');
        _playAnimation();
      }
    });
  }

  @override
  void dispose() {
    _continuousPlayTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }
}

enum EmojiType {
  neutral,
  laughing, 
  inspiring,
  relating;

  String get animationName {
    // Odin Emojis pack uses "Animation 1" which cycles through different expressions
    // All emoji types use the same animation name since it's a cycling animation
    return 'Animation 1';
  }

  String get fallbackEmoji {
    switch (this) {
      case EmojiType.neutral:
        return '😐';
      case EmojiType.laughing:
        return '😂';
      case EmojiType.inspiring:
        return '🤩';
      case EmojiType.relating:
        return '🤝';
    }
  }

  // Map goal completion count to emoji type
  static EmojiType fromGoalCount(int goalCount) {
    switch (goalCount) {
      case 1:
        return EmojiType.relating; // 1x daily strikes
      case 2:
        return EmojiType.neutral; // 2x daily strikes
      case 3:
      case 4:
        return EmojiType.inspiring; // 3x-4x daily strikes
      case 5:
        return EmojiType.laughing; // 5x daily strikes
      default:
        return EmojiType.neutral; // Default for 0 or other values
    }
  }

  // Map multiplier to emoji type
  static EmojiType fromMultiplier(int multiplier) {
    switch (multiplier) {
      case 1:
        return EmojiType.neutral;
      case 2:
        return EmojiType.relating;
      case 3:
        return EmojiType.inspiring;
      case 4:
      case 5:
        return EmojiType.laughing;
      default:
        return EmojiType.neutral;
    }
  }
  
  // Map level to emoji type
  static EmojiType fromLevel(int level) {
    if (level <= 2) {
      return EmojiType.neutral;
    } else if (level <= 4) {
      return EmojiType.relating;
    } else if (level <= 7) {
      return EmojiType.inspiring;
    } else {
      return EmojiType.laughing;
    }
  }
}