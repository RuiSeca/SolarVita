import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

/// Enhanced debug tool to find the actual source of the RangeError
class SolarCoachAnalyzer extends StatefulWidget {
  const SolarCoachAnalyzer({super.key});

  @override
  State<SolarCoachAnalyzer> createState() => _SolarCoachAnalyzerState();
}

class _SolarCoachAnalyzerState extends State<SolarCoachAnalyzer> {
  String _analysisResults = 'Loading...';
  final List<rive.StateMachineController?> _controllers = [];

  @override
  void initState() {
    super.initState();
    _runComprehensiveAnalysis();
  }

  Future<void> _runComprehensiveAnalysis() async {
    final results = StringBuffer();
    
    try {
      results.writeln('🌞 COMPREHENSIVE SOLAR.RIV ANALYSIS');
      results.writeln('=' * 50);
      results.writeln();
      
      // Load the file
      results.writeln('📁 Loading solar.riv...');
      final rivFile = await rive.RiveFile.asset('assets/rive/solar.riv');
      results.writeln('✅ File loaded successfully');
      results.writeln();
      
      // Analyze artboard
      final artboard = rivFile.mainArtboard;
      results.writeln('🎨 ARTBOARD ANALYSIS');
      results.writeln('Name: ${artboard.name}');
      results.writeln('Size: ${artboard.width.toStringAsFixed(1)} x ${artboard.height.toStringAsFixed(1)}');
      results.writeln('Animations: ${artboard.animations.length}');
      results.writeln('State Machines: ${artboard.stateMachines.length}');
      results.writeln();
      
      // List all animations
      results.writeln('🎬 AVAILABLE ANIMATIONS:');
      final animationsList = artboard.animations.toList();
      for (int i = 0; i < animationsList.length; i++) {
        final animation = animationsList[i];
        results.writeln('  [$i] ${animation.name}');
      }
      results.writeln();
      
      // List all state machines
      results.writeln('🤖 AVAILABLE STATE MACHINES:');
      final stateMachinesList = artboard.stateMachines.toList();
      for (int i = 0; i < stateMachinesList.length; i++) {
        final stateMachine = stateMachinesList[i];
        results.writeln('  [$i] ${stateMachine.name}');
      }
      results.writeln();
      
      // Test each state machine
      results.writeln('=== TESTING STATE MACHINES:');
      for (int i = 0; i < stateMachinesList.length; i++) {
        final stateMachine = stateMachinesList[i];
        results.writeln('Testing State Machine [$i]: ${stateMachine.name}');
        
        try {
          // Create artboard instance for testing
          final testArtboard = artboard.instance();
          final controller = rive.StateMachineController.fromArtboard(
            testArtboard,
            stateMachine.name,
          );
          
          if (controller != null) {
            _controllers.add(controller);
            testArtboard.addController(controller);
            results.writeln('   ✅ Controller created successfully');
            results.writeln('  📥 Inputs: ${controller.inputs.length}');
            
            // List all inputs
            final inputsList = controller.inputs.toList();
            for (int j = 0; j < inputsList.length; j++) {
              final input = inputsList[j];
              results.writeln('    - ${input.name} (${input.runtimeType})');
            }
          } else {
            results.writeln('   ❌ Controller creation failed');
          }
        } catch (e) {
          results.writeln('   ❌ ERROR: $e');
          if (e.toString().contains('RangeError')) {
            results.writeln('   🔍 FOUND RANGEERROR IN STATE MACHINE TESTING!');
          }
        }
        results.writeln();
      }
      
      // Configuration compatibility check
      results.writeln('🔧 CONFIGURATION COMPATIBILITY:');
      results.writeln('Expected animations from config:');
      results.writeln('  - FIRST FLY');
      results.writeln('  - SECOND FLY');
      results.writeln();
      
      results.writeln('Animation compatibility:');
      final hasFirstFly = animationsList.any((a) => a.name == 'FIRST FLY');
      final hasSecondFly = animationsList.any((a) => a.name == 'SECOND FLY');
      results.writeln('  FIRST FLY: ${hasFirstFly ? ' ✅ Found' : ' ❌ Missing'}');
      results.writeln('  SECOND FLY: ${hasSecondFly ? ' ✅ Found' : ' ❌ Missing'}');
      results.writeln();
      
      // Range error diagnosis
      results.writeln('=== RANGEERROR DIAGNOSIS:');
      results.writeln('Error: "Not in inclusive range 0..1: 2"');
      results.writeln('This suggests code is trying to access:');
      results.writeln('  - State machine index 2, but only 0-${stateMachinesList.length - 1} exist');
      results.writeln('  - Or animation index 2, but only 0-${animationsList.length - 1} exist');
      results.writeln();
      
      if (stateMachinesList.length <= 2) {
        results.writeln('🎯 LIKELY CAUSE: Code tries to access state machine [2]');
        results.writeln('   but only ${stateMachinesList.length} state machines exist');
      }
      
      results.writeln();
      results.writeln('🔍 RECOMMENDED FIXES:');
      results.writeln('1. Check where state machine index 2 is being accessed');
      results.writeln('2. Use state machine by name instead: "State Machine 1"');
      results.writeln('3. Add bounds checking before accessing arrays');
      results.writeln('4. Check animation stage values not being used as indices');
      
    } catch (e) {
      results.writeln('❌ ANALYSIS FAILED: $e');
      if (e.toString().contains('RangeError')) {
        results.writeln('🔍 RANGEERROR OCCURRED DURING ANALYSIS!');
        results.writeln('This confirms the issue is in the basic Rive file access');
      }
    }
    
    setState(() {
      _analysisResults = results.toString();
    });
  }

  @override
  void dispose() {
    // Clean up controllers
    for (final controller in _controllers) {
      controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solar Coach Analyzer'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade700),
          ),
          child: SelectableText(
            _analysisResults,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Colors.green,
              height: 1.4,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _analysisResults = 'Re-running analysis...';
          });
          _runComprehensiveAnalysis();
        },
        backgroundColor: Colors.orange.shade800,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}