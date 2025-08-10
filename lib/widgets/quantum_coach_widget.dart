import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;
import 'package:logging/logging.dart';
import '../services/avatars/quantum_coach_controller.dart';
import '../services/store/avatar_customization_service.dart';
import '../services/avatars/avatar_interaction_manager.dart';

final log = Logger('QuantumCoachWidget');

/// Widget that displays the Quantum Coach avatar with controller integration
class QuantumCoachWidget extends StatefulWidget {
  final double width;
  final double height;
  final CoachLocation expectedLocation;
  final QuantumCoachController controller;
  final EdgeInsets? margin;

  const QuantumCoachWidget({
    super.key,
    this.width = 120,
    this.height = 120,
    required this.expectedLocation,
    required this.controller,
    this.margin,
  });

  @override
  State<QuantumCoachWidget> createState() => _QuantumCoachWidgetState();
}

class _QuantumCoachWidgetState extends State<QuantumCoachWidget>
    with SingleTickerProviderStateMixin {
  rive.StateMachineController? _riveController;
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
    
    // Listen to controller animation changes
    widget.controller.currentAnimation.addListener(_onAnimationChanged);
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
    _riveController?.dispose();
    _fadeController.dispose();
    widget.controller.currentAnimation.removeListener(_onAnimationChanged);
    super.dispose();
  }

  Future<void> _loadQuantumCoach() async {
    try {
      await _customizationService.initialize();
      
      final rivFile = await rive.RiveFile.asset('assets/rive/quantum_coach.riv');
      final artboard = rivFile.mainArtboard.instance();
      
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
            _riveController = controller;
          });
          
          // Start with idle animation
          _playAnimation('Idle');
        }
      }
    } catch (e) {
      log.severe('Error loading Quantum Coach Widget: $e');
    }
  }

  void _onAnimationChanged() {
    final currentAnimation = widget.controller.currentAnimation.value;
    _playAnimation(currentAnimation);
  }

  void _playAnimation(String animationName) {
    if (_riveController == null) return;

    try {
      // Try to find and trigger the animation
      final input = _riveController!.findSMI(animationName);
      if (input is rive.SMITrigger) {
        log.info('🌌 Playing Quantum Coach animation: $animationName');
        input.fire();
      } else {
        log.warning('⚠️ Quantum Coach animation not found: $animationName');
        // Fallback to Idle if animation not found
        final idleInput = _riveController!.findSMI('Idle');
        if (idleInput is rive.SMITrigger) {
          idleInput.fire();
        }
      }
    } catch (e) {
      log.warning('⚠️ Error playing Quantum Coach animation $animationName: $e');
    }
  }

  void _handleCoachTap() {
    // Haptic feedback
    _fadeController.forward(from: 0.8);
    
    // Trigger the interaction logic through controller
    widget.controller.handleInteraction(AvatarInteractionType.singleTap);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CoachLocation>(
      valueListenable: widget.controller.currentLocation,
      builder: (context, currentLocation, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: widget.controller.isVisible,
          builder: (context, isVisible, child) {
            // Only show if this widget's location matches the current coach location
            final shouldShow = currentLocation == widget.expectedLocation && isVisible;
            
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
          },
        );
      },
    );
  }
}