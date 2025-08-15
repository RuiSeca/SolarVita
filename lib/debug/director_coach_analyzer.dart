import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

/// Debug tool to analyze the director_coach.riv file structure
class DirectorCoachAnalyzer extends StatefulWidget {
  const DirectorCoachAnalyzer({super.key});

  @override
  State<DirectorCoachAnalyzer> createState() => _DirectorCoachAnalyzerState();
}

class _DirectorCoachAnalyzerState extends State<DirectorCoachAnalyzer> {
  rive.Artboard? _artboard;
  String _analysisResult = 'Loading RIVE file...';
  final List<rive.StateMachineController> _controllers = [];

  @override
  void initState() {
    super.initState();
    _analyzeRiveFile();
  }

  Future<void> _analyzeRiveFile() async {
    try {
      // Load the RIVE file
      final rivFile = await rive.RiveFile.asset(
        'assets/rive/director_coach.riv',
      );
      final artboard = rivFile.mainArtboard;

      setState(() {
        _artboard = artboard.instance();
      });

      // Analyze the structure
      final analysis = StringBuffer();
      analysis.writeln('🎬 DIRECTOR COACH RIVE ANALYSIS');
      analysis.writeln('=' * 40);
      analysis.writeln();

      // Basic artboard info
      analysis.writeln('📊 ARTBOARD INFO:');
      analysis.writeln('Name: ${artboard.name}');
      analysis.writeln(
        'Size: ${artboard.width.toStringAsFixed(1)} x ${artboard.height.toStringAsFixed(1)}',
      );
      analysis.writeln();

      // Animations
      analysis.writeln('🎬 ANIMATIONS (${artboard.animations.length} total):');
      for (int i = 0; i < artboard.animations.length; i++) {
        final animation = artboard.animations[i];
        analysis.writeln('  [$i] ${animation.name} (${animation.runtimeType})');
      }
      analysis.writeln();

      // State machines
      analysis.writeln('🤖 STATE MACHINES (${artboard.stateMachines.length} total):');
      final stateMachinesList = artboard.stateMachines.toList();
      for (int i = 0; i < stateMachinesList.length; i++) {
        final stateMachine = stateMachinesList[i];
        analysis.writeln('  [$i] ${stateMachine.name}');
      }
      analysis.writeln();

      // Test state machine creation
      analysis.writeln('🧪 STATE MACHINE TESTING:');
      for (int i = 0; i < stateMachinesList.length; i++) {
        final stateMachine = stateMachinesList[i];
        analysis.writeln('Testing State Machine [$i]: ${stateMachine.name}');
        
        try {
          // Create test artboard instance
          final testArtboard = artboard.instance();
          final controller = rive.StateMachineController.fromArtboard(
            testArtboard,
            stateMachine.name,
          );
          
          if (controller != null) {
            _controllers.add(controller);
            testArtboard.addController(controller);
            
            analysis.writeln('  ✅ SUCCESS: Controller created');
            analysis.writeln('  📝 Inputs (${controller.inputs.length} total):');
            
            final inputsList = controller.inputs.toList();
            for (int j = 0; j < inputsList.length; j++) {
              final input = inputsList[j];
              analysis.writeln('    [$j] ${input.name} (${input.runtimeType})');
            }
          } else {
            analysis.writeln('  ❌ FAILED: Controller is null');
          }
        } catch (e) {
          analysis.writeln('  💥 ERROR: $e');
          if (e.toString().contains('RangeError')) {
            analysis.writeln('  🔍 RANGE ERROR DETECTED - This is the problematic state machine!');
          }
        }
        analysis.writeln();
      }

      // Animation details
      analysis.writeln('🎭 DETAILED ANIMATION ANALYSIS:');
      for (int i = 0; i < artboard.animations.length; i++) {
        final animation = artboard.animations[i];
        analysis.writeln('Animation [$i]: ${animation.name}');
        
        if (animation is rive.LinearAnimation) {
          analysis.writeln('  Type: Linear Animation');
          analysis.writeln('  Duration: ${animation.duration.toStringAsFixed(2)}s');
          analysis.writeln('  Work Area: ${animation.workStart.toStringAsFixed(2)}s - ${animation.workEnd.toStringAsFixed(2)}s');
        } else {
          analysis.writeln('  Type: ${animation.runtimeType}');
        }
        analysis.writeln();
      }

      // Summary and recommendations
      analysis.writeln('📋 SUMMARY & RECOMMENDATIONS:');
      if (stateMachinesList.isEmpty) {
        analysis.writeln('⚠️  No state machines found - use SimpleAnimation approach');
      } else {
        analysis.writeln('✅ ${stateMachinesList.length} state machine(s) found');
      }
      
      if (artboard.animations.isNotEmpty) {
        analysis.writeln('✅ ${artboard.animations.length} animation(s) available');
        analysis.writeln('💡 Recommended default animation: ${artboard.animations.first.name}');
      }
      
      setState(() {
        _analysisResult = analysis.toString();
      });

    } catch (e) {
      setState(() {
        _analysisResult = 'ERROR LOADING DIRECTOR COACH RIV FILE:\n\n$e\n\nStack Trace:\n${StackTrace.current}';
      });
    }
  }

  @override
  void dispose() {
    // Clean up controllers
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Director Coach RIV Analyzer'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Analysis Results
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                _analysisResult,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
          
          // Visual Preview (if available)
          if (_artboard != null)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.purple[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: rive.Rive(
                  artboard: _artboard!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
        ],
      ),
    );
  }
}