import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart' as rive;
import 'package:logging/logging.dart';
import '../providers/riverpod/interactive_coach_provider.dart';
import '../services/store/avatar_customization_service.dart';

final log = Logger('InteractiveQuantumCoach');

class InteractiveQuantumCoach extends ConsumerStatefulWidget {
  final double width;
  final double height;
  final CoachLocation expectedLocation;
  final EdgeInsets? margin;

  const InteractiveQuantumCoach({
    super.key,
    this.width = 120,
    this.height = 120,
    required this.expectedLocation,
    this.margin,
  });

  @override
  ConsumerState<InteractiveQuantumCoach> createState() => _InteractiveQuantumCoachState();
}

class _InteractiveQuantumCoachState extends ConsumerState<InteractiveQuantumCoach>
    with SingleTickerProviderStateMixin {
  rive.StateMachineController? _controller;
  rive.Artboard? _artboard;
  final AvatarCustomizationService _customizationService = AvatarCustomizationService();
  
  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimationControllers();
    _loadQuantumCoach();
  }

  void _initAnimationControllers() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.elasticOut,
    ));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadQuantumCoach() async {
    try {
      await _customizationService.initialize();
      
      final rivFile = await rive.RiveFile.asset('assets/rive/quantum_coach.riv');
      
      // Handle RuntimeArtboard properly
      rive.Artboard artboard;
      try {
        artboard = rivFile.mainArtboard.instance();
      } catch (e) {
        log.warning('⚠️ Failed to clone artboard, using original: $e');
        artboard = rivFile.mainArtboard;
      }
      
      final controller = rive.StateMachineController.fromArtboard(
        artboard,
        'State Machine 1',
      );
      
      if (controller != null) {
        artboard.addController(controller);
        
        // Apply saved customizations
        await _customizationService.applyToRiveInputs('quantum_coach', controller.inputs.toList());
        
        if (mounted) {
          setState(() {
            _artboard = artboard;
            _controller = controller;
          });
          
          // Start with idle animation
          _playAnimation('Idle');
        }
      }
    } catch (e) {
      log.severe('Error loading Interactive Quantum Coach: $e');
    }
  }

  void _playAnimation(String animationName) {
    if (_controller == null) return;

    try {
      // Try to find and trigger the animation
      final input = _controller!.findSMI(animationName);
      if (input is rive.SMITrigger) {
        log.info('🎭 Triggering animation: $animationName');
        input.fire();
      } else {
        log.warning('⚠️ Animation not found or not trigger type: $animationName');
        // Fallback to Idle if animation not found
        final idleInput = _controller!.findSMI('Idle');
        if (idleInput is rive.SMITrigger) {
          idleInput.fire();
        }
      }
    } catch (e) {
      log.warning('⚠️ Error playing animation $animationName: $e');
    }
  }

  void _handleCoachTap() {
    final coachNotifier = ref.read(interactiveCoachProvider.notifier);
    
    // Haptic feedback
    _fadeController.forward(from: 0.8);
    
    // Trigger the interaction logic
    coachNotifier.handleCoachClick();
  }

  @override
  Widget build(BuildContext context) {
    final coachState = ref.watch(interactiveCoachProvider);
    
    // Only show if this widget's location matches the current coach location
    final shouldShow = coachState.currentLocation == widget.expectedLocation && coachState.isVisible;
    
    // Play animation when it changes
    ref.listen<String>(currentCoachAnimationProvider, (previous, next) {
      if (shouldShow && previous != next) {
        _playAnimation(next);
      }
    });

    if (!shouldShow) {
      return const SizedBox.shrink();
    }

    if (_artboard == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        margin: widget.margin,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.purple,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              margin: widget.margin,
              child: GestureDetector(
                onTap: _handleCoachTap,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: rive.Rive(
                      artboard: _artboard!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Helper widget for positioning on different screens
class PositionedInteractiveCoach extends ConsumerWidget {
  final CoachLocation location;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double width;
  final double height;

  const PositionedInteractiveCoach({
    super.key,
    required this.location,
    this.top,
    this.bottom,
    this.left,
    this.right,
    this.width = 120,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: InteractiveQuantumCoach(
        expectedLocation: location,
        width: width,
        height: height,
      ),
    );
  }
}