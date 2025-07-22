import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class RiveWaterWidget extends StatefulWidget {
  final double? width;
  final double? height;
  final BoxFit? fit;
  final double waterLevel; // 0.0 to 1.0
  final bool isAnimating;
  final VoidCallback? onAnimationComplete;

  const RiveWaterWidget({
    super.key,
    this.width,
    this.height,
    this.fit,
    required this.waterLevel,
    this.isAnimating = false,
    this.onAnimationComplete,
  });

  @override
  State<RiveWaterWidget> createState() => _RiveWaterWidgetState();
}

class _RiveWaterWidgetState extends State<RiveWaterWidget> {
  StateMachineController? _controller;
  SMINumber? _fillLevelInput;
  bool _isRiveInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  void _onRiveInit(Artboard artboard) {
    debugPrint('🚀 Rive artboard initialized');
    
    // Debug: Show what's available in the artboard
    debugPrint('📊 Artboard info:');
    debugPrint('   - Animations count: ${artboard.animations.length}');
    debugPrint('   - Available animations:');
    for (var anim in artboard.animations) {
      debugPrint('     * ${anim.name}');
    }
    
    // Try to find ANY state machine with expanded search
    var stateMachineNames = [
      'State Machine 1', 
      'StateMachine',
      'SM',
      'Main',
      'Default',
      'state machine',
      'statemachine',
      'WaterCup',
      'Cup',
      'Water',
    ];
    
    debugPrint('🔍 Searching for state machines...');
    for (var name in stateMachineNames) {
      _controller = StateMachineController.fromArtboard(artboard, name);
      if (_controller != null) {
        debugPrint('✅ Found state machine: "$name"');
        break;
      } else {
        debugPrint('❌ No state machine named: "$name"');
      }
    }
    
    if (_controller != null) {
      artboard.addController(_controller!);
      debugPrint('🎯 State machine controller added to artboard');
      
      // Debug all inputs before searching for specific ones
      debugPrint('📋 All state machine inputs (${_controller!.inputs.length} total):');
      for (var input in _controller!.inputs) {
        debugPrint('   - "${input.name}" (${input.runtimeType})');
      }
      
      // Find the "input" parameter
      _fillLevelInput = _controller!.findInput<double>('input') as SMINumber?;
      
      if (_fillLevelInput != null) {
        debugPrint('✅ Found input parameter: "input"');
        
        // Set initial water level
        double inputValue = widget.waterLevel * 100;
        _fillLevelInput!.value = inputValue;
        debugPrint('🚰 Set initial water level to: ${inputValue.toStringAsFixed(1)}');
      } else {
        debugPrint('❌ Could not find "input" parameter');
        debugPrint('💡 Available inputs above - check spelling/case');
      }
      
      setState(() {
        _isRiveInitialized = true;
      });
    } else {
      debugPrint('❌ NO STATE MACHINE FOUND');
      debugPrint('🔄 Using individual animations instead');
      
      // Use the appropriate animation based on water level
      String animationName = _getAnimationForWaterLevel(widget.waterLevel);
      
      if (artboard.animations.isNotEmpty) {
        var simpleController = SimpleAnimation(animationName, autoplay: true);
        artboard.addController(simpleController);
        debugPrint('✅ Playing animation: "$animationName" for water level ${(widget.waterLevel * 100).toStringAsFixed(1)}%');
      }
      
      setState(() {
        _isRiveInitialized = true;
      });
    }
  }

  String _getAnimationForWaterLevel(double waterLevel) {
    // Map water level to your 4 animations
    if (waterLevel <= 0.05) {
      return 'Idle';        // 0-5%: Empty cup with idle effects
    } else if (waterLevel <= 0.35) {
      return 'low';         // 5-35%: Low water level
    } else if (waterLevel <= 0.75) {
      return 'default';     // 35-75%: Medium water level
    } else {
      return 'High';        // 75%+: High water level
    }
  }

  @override
  void didUpdateWidget(RiveWaterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update water level when it changes
    if (_isRiveInitialized && oldWidget.waterLevel != widget.waterLevel) {
      if (_fillLevelInput != null) {
        // Use state machine input (if available)
        _animateToWaterLevel(oldWidget.waterLevel, widget.waterLevel);
      } else {
        // Use individual animations - check if we need to switch
        String oldAnimation = _getAnimationForWaterLevel(oldWidget.waterLevel);
        String newAnimation = _getAnimationForWaterLevel(widget.waterLevel);
        
        if (oldAnimation != newAnimation) {
          debugPrint('🌊 Water level changed: ${(oldWidget.waterLevel * 100).toStringAsFixed(1)}% → ${(widget.waterLevel * 100).toStringAsFixed(1)}%');
          debugPrint('🎬 Animation change: "$oldAnimation" → "$newAnimation"');
          
          // Force widget rebuild to switch animation
          setState(() {
            // This will trigger a rebuild with the new animation
          });
        }
      }
      
      // Call completion callback when animating
      if (widget.isAnimating && !oldWidget.isAnimating) {
        debugPrint('💧 Water animation triggered');
        
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            widget.onAnimationComplete?.call();
          }
        });
      }
    }
  }

  void _animateToWaterLevel(double fromLevel, double toLevel) {
    if (_fillLevelInput == null) return;
    
    // Convert from 0-1 range to 0-100 range (as confirmed by your Rive input)
    double fromValue = fromLevel * 100;
    double toValue = toLevel * 100;
    
    debugPrint('🌊 Animating water: ${fromValue.toStringAsFixed(1)}% → ${toValue.toStringAsFixed(1)}%');
    
    // For 250ml increments, create smooth animation
    double difference = (toValue - fromValue).abs();
    
    if (difference < 1) {
      // Very small change, set directly
      _fillLevelInput!.value = toValue;
      debugPrint('💧 Small change - setting directly to ${toValue.toStringAsFixed(1)}%');
    } else {
      // Animate smoothly through steps
      int steps = (difference / 1.5).clamp(3, 20).round(); // 1.5% per step for smooth motion
      int stepDuration = (500 / steps).clamp(20, 50).round(); // Total 500ms for nice feel
      
      debugPrint('📈 Animating in $steps steps over ${steps * stepDuration}ms');
      _animateValueInSteps(fromValue, toValue, steps, stepDuration, 0);
    }
  }

  void _animateValueInSteps(double fromValue, double toValue, int totalSteps, int stepDuration, int currentStep) {
    if (currentStep >= totalSteps || _fillLevelInput == null || !mounted) {
      // Ensure we end exactly at the target value
      if (_fillLevelInput != null && mounted) {
        _fillLevelInput!.value = toValue;
        debugPrint('🎯 Animation complete - final value: ${toValue.toStringAsFixed(1)}%');
      }
      return;
    }
    
    // Use smooth easing for more natural water movement
    double progress = currentStep / (totalSteps - 1);
    
    // Apply ease-out curve for more natural water physics
    double easedProgress = 1 - (1 - progress) * (1 - progress);
    
    double currentValue = fromValue + (toValue - fromValue) * easedProgress;
    
    _fillLevelInput!.value = currentValue;
    
    // Debug every few steps to avoid spam
    if (currentStep % 3 == 0) {
      debugPrint('💧 Step ${currentStep + 1}/$totalSteps: ${currentValue.toStringAsFixed(1)}%');
    }
    
    // Schedule next step
    Future.delayed(Duration(milliseconds: stepDuration), () {
      if (mounted) {
        _animateValueInSteps(fromValue, toValue, totalSteps, stepDuration, currentStep + 1);
      }
    });
  }



  Widget _buildRiveAnimation() {
    try {
      if (_fillLevelInput != null) {
        // Use state machine version if available
        return RiveAnimation.asset(
          'assets/rive/vca_cup.riv',
          fit: widget.fit ?? BoxFit.cover,
          onInit: _onRiveInit,
        );
      } else {
        // Use simple animation version
        String animationName = _getAnimationForWaterLevel(widget.waterLevel);
        
        return RiveAnimation.asset(
          'assets/rive/vca_cup.riv',
          animations: [animationName],
          fit: widget.fit ?? BoxFit.cover,
        );
      }
    } catch (e) {
      debugPrint('❌ Error loading Rive animation: $e');
      return Container(
        color: Colors.cyan.withAlpha(50),
        child: const Center(
          child: Icon(
            Icons.water_drop,
            color: Colors.cyan,
            size: 24,
          ),
        ),
      );
    }
  }


  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width ?? 48,
      height: widget.height ?? 48,
      decoration: BoxDecoration(
        shape: (widget.width == widget.height) ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: (widget.width != widget.height) ? BorderRadius.circular(8) : null,
      ),
      child: ClipRRect(
        borderRadius: (widget.width == widget.height) 
            ? BorderRadius.circular((widget.width ?? 48) / 2)
            : BorderRadius.circular(8),
        child: _buildRiveAnimation(),
      ),
    );
  }
}