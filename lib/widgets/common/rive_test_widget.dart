import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class RiveTestWidget extends StatefulWidget {
  const RiveTestWidget({super.key});

  @override
  State<RiveTestWidget> createState() => _RiveTestWidgetState();
}

class _RiveTestWidgetState extends State<RiveTestWidget> {
  StateMachineController? _controller;
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Column(
        children: [
          // Test 1: Simple animation
          Expanded(
            child: Container(
              decoration: BoxDecoration(border: Border.all()),
              child: RiveAnimation.asset(
                'assets/rive/odin_emojis.riv',
                onInit: _onRiveInit,
                placeHolder: const Center(
                  child: Text('Loading...', style: TextStyle(fontSize: 10)),
                ),
              ),
            ),
          ),
          const Text('Rive Test', style: TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  void _onRiveInit(Artboard artboard) {
    debugPrint('🧪 TEST: Rive artboard initialized');
    debugPrint('📊 TEST: Animations count: ${artboard.animations.length}');
    
    // List all animations
    for (var anim in artboard.animations) {
      debugPrint('🎬 TEST: Animation: "${anim.name}"');
    }
    
    // Try to find ANY state machine
    var testNames = ['State Machine 1', 'StateMachine', 'SM', 'Main', 'Default'];
    for (var name in testNames) {
      var controller = StateMachineController.fromArtboard(artboard, name);
      if (controller != null) {
        debugPrint('✅ TEST: Found state machine: "$name"');
        artboard.addController(controller);
        _controller = controller;
        break;
      }
    }
    
    if (_controller == null) {
      debugPrint('❌ TEST: No state machine found, trying simple animation');
      // Try first available animation if no state machine
      if (artboard.animations.isNotEmpty) {
        var simpleController = SimpleAnimation(artboard.animations.first.name);
        artboard.addController(simpleController);
        debugPrint('🎬 TEST: Playing simple animation: ${artboard.animations.first.name}');
      }
    }
  }
  
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}