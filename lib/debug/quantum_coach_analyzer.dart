import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

/// Debug tool to analyze the quantum_coach.riv file structure
class QuantumCoachAnalyzer extends StatefulWidget {
  const QuantumCoachAnalyzer({super.key});

  @override
  State<QuantumCoachAnalyzer> createState() => _QuantumCoachAnalyzerState();
}

class _QuantumCoachAnalyzerState extends State<QuantumCoachAnalyzer> {
  rive.Artboard? _artboard;
  rive.StateMachineController? _controller;
  String _analysisResult = 'Loading RIVE file...';

  @override
  void initState() {
    super.initState();
    _analyzeRiveFile();
  }

  Future<void> _analyzeRiveFile() async {
    try {
      // Load the RIVE file
      final rivFile = await rive.RiveFile.asset(
        'assets/rive/quantum_coach.riv',
      );
      final artboard = rivFile.mainArtboard;

      setState(() {
        _artboard = artboard.instance();
      });

      // Analyze the structure
      final analysis = StringBuffer();
      analysis.writeln('🎭 QUANTUM COACH RIVE ANALYSIS');
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
        analysis.writeln('${i + 1}. ${animation.name}');
      }
      analysis.writeln();

      // Try to find state machines
      analysis.writeln('🤖 STATE MACHINES:');
      final stateMachines = artboard.stateMachines.toList();
      for (int i = 0; i < stateMachines.length; i++) {
        final stateMachine = stateMachines[i];
        analysis.writeln('${i + 1}. ${stateMachine.name}');

        // Try to create a controller to inspect inputs
        final controller = rive.StateMachineController.fromArtboard(
          _artboard!,
          stateMachine.name,
        );

        if (controller != null) {
          analysis.writeln('   📥 INPUTS ($controller.inputs.length total):');

          for (final input in controller.inputs) {
            final type = input.runtimeType.toString();
            analysis.writeln('   • ${input.name} ($type)');

            // For SMINumber inputs, show current value and detect customization type
            if (input is rive.SMINumber) {
              analysis.writeln('     Value: ${input.value}');
              // Detect customization categories
              final inputName = input.name.toLowerCase();
              if (inputName.contains('eye')) {
                analysis.writeln('     🔹 EYE CUSTOMIZATION detected');
              } else if (inputName.contains('skin')) {
                analysis.writeln('     🔹 SKIN CUSTOMIZATION detected');
              } else if (inputName.contains('cloth') ||
                  inputName.contains('shirt') ||
                  inputName.contains('outfit') ||
                  inputName.contains('jacket')) {
                analysis.writeln('     🔹 CLOTHING CUSTOMIZATION detected');
              } else if (inputName.contains('color') ||
                  inputName.contains('hue') ||
                  inputName.contains('tint')) {
                analysis.writeln('     🔹 COLOR PARAMETER detected');
              }
            }
            // For SMIBool inputs, show current value and detect clothing toggles
            else if (input is rive.SMIBool) {
              analysis.writeln('     Value: ${input.value}');
              final inputName = input.name.toLowerCase();
              if (inputName.contains('cloth') ||
                  inputName.contains('shirt') ||
                  inputName.contains('jacket') ||
                  inputName.contains('outfit')) {
                analysis.writeln('     🔹 CLOTHING TOGGLE detected');
              } else if (inputName.contains('show') ||
                  inputName.contains('visible') ||
                  inputName.contains('enable')) {
                analysis.writeln('     🔹 VISIBILITY TOGGLE detected');
              }
            }
            // For SMITrigger inputs
            else if (input is rive.SMITrigger) {
              analysis.writeln('     Type: Trigger');
              final inputName = input.name.toLowerCase();
              if (inputName.contains('cloth') ||
                  inputName.contains('outfit') ||
                  inputName.contains('change')) {
                analysis.writeln('     🔹 CLOTHING ANIMATION detected');
              }
            }
          }

          // Store the first controller for interaction testing
          if (_controller == null) {
            _controller = controller;
            _artboard!.addController(controller);
          } else {
            controller.dispose();
          }
        }
        analysis.writeln();
      }

      // Components and objects
      analysis.writeln('🎨 ARTBOARD COMPONENTS:');
      analysis.writeln('Drawables: ${artboard.drawables.length}');
      analysis.writeln();

      // Customization Summary
      analysis.writeln('🎨 CUSTOMIZATION SUMMARY:');
      if (_controller != null) {
        final eyeInputs = _controller!.inputs
            .where((input) => input.name.toLowerCase().contains('eye'))
            .toList();
        final skinInputs = _controller!.inputs
            .where((input) => input.name.toLowerCase().contains('skin'))
            .toList();
        final clothingInputs = _controller!.inputs
            .where(
              (input) =>
                  input.name.toLowerCase().contains('cloth') ||
                  input.name.toLowerCase().contains('shirt') ||
                  input.name.toLowerCase().contains('outfit') ||
                  input.name.toLowerCase().contains('jacket'),
            )
            .toList();

        // Also detect Chinese clothing terms from the error log
        final chineseClothingInputs = _controller!.inputs
            .where(
              (input) =>
                  input.name.contains('鞋') ||
                  input.name.contains('耳饰') ||
                  input.name.contains('裤') ||
                  input.name.contains('衣') ||
                  input.name.contains('背饰') ||
                  input.name.contains('发') ||
                  input.name.contains('面饰') ||
                  input.name.contains('项链') ||
                  input.name.contains('头饰') ||
                  input.name.contains('手持物') ||
                  input.name.contains('裙子'),
            )
            .toList();

        analysis.writeln(
          '👁️  Eye Customization: ${eyeInputs.length} parameters',
        );
        for (final input in eyeInputs) {
          analysis.writeln('   • ${input.name}');
        }

        analysis.writeln(
          '🧑 Skin Customization: ${skinInputs.length} parameters',
        );
        for (final input in skinInputs) {
          analysis.writeln('   • ${input.name}');
        }

        analysis.writeln(
          '👕 Clothing Customization: ${clothingInputs.length + chineseClothingInputs.length} parameters',
        );
        for (final input in clothingInputs) {
          analysis.writeln('   • ${input.name} (English)');
        }
        for (final input in chineseClothingInputs) {
          final translation = _translateChineseClothing(input.name);
          analysis.writeln('   • ${input.name} ($translation)');
        }

        // Missing Assets Warning
        if (chineseClothingInputs.isNotEmpty) {
          analysis.writeln();
          analysis.writeln('⚠️  MISSING ASSETS DETECTED:');
          analysis.writeln(
            'Chinese-named clothing assets may have missing images.',
          );
          analysis.writeln('This can cause visual elements not to display.');
          analysis.writeln('Affected categories:');
          final categories = <String>{};
          for (final input in chineseClothingInputs) {
            categories.add(_translateChineseClothing(input.name));
          }
          for (final category in categories) {
            analysis.writeln('   • $category');
          }
        }
      } else {
        analysis.writeln(
          'No state machine controller available for customization analysis',
        );
      }
      analysis.writeln();

      setState(() {
        _analysisResult = analysis.toString();
      });
    } catch (e) {
      setState(() {
        _analysisResult = '❌ Error loading RIVE file: $e';
      });
    }
  }

  String _translateChineseClothing(String chineseName) {
    final translations = {
      '鞋': 'Shoes',
      '耳饰': 'Earrings',
      '裤': 'Pants',
      '衣': 'Clothing/Shirt',
      '背饰': 'Back Accessories',
      '中发': 'Middle Hair',
      '后发': 'Back Hair',
      '前发': 'Front Hair',
      '面饰': 'Face Accessories',
      '项链': 'Necklace',
      '头饰': 'Head Accessories',
      '手持物': 'Handheld Items',
      '裙子': 'Skirt',
    };

    for (final entry in translations.entries) {
      if (chineseName.contains(entry.key)) {
        return entry.value;
      }
    }
    return 'Unknown Clothing Item';
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quantum Coach RIVE Analyzer'),
        backgroundColor: Colors.purple.shade800,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // RIVE Preview
          if (_artboard != null)
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.black12,
              child: Center(
                child: SizedBox(
                  width: 150,
                  height: 150,
                  child: rive.Rive(artboard: _artboard!, fit: BoxFit.contain),
                ),
              ),
            ),

          // Interaction buttons (if controller is available)
          if (_controller != null)
            Container(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                children: [
                  for (final input in _controller!.inputs)
                    if (input is rive.SMITrigger)
                      ElevatedButton(
                        onPressed: () => input.fire(),
                        child: Text(input.name),
                      ),
                ],
              ),
            ),

          // Analysis results
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: SelectableText(
                  _analysisResult,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
