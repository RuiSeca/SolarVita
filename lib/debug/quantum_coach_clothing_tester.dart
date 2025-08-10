import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

/// Diagnostic tool specifically for testing Quantum Coach clothing functionality
class QuantumCoachClothingTester extends StatefulWidget {
  const QuantumCoachClothingTester({super.key});

  @override
  State<QuantumCoachClothingTester> createState() =>
      _QuantumCoachClothingTesterState();
}

class _QuantumCoachClothingTesterState
    extends State<QuantumCoachClothingTester> {
  rive.Artboard? _artboard;
  rive.StateMachineController? _controller;
  String _testResults = 'Loading RIVE file...';

  @override
  void initState() {
    super.initState();
    _loadAndTestClothing();
  }

  Future<void> _loadAndTestClothing() async {
    try {
      final results = StringBuffer();
      results.writeln('🧪 QUANTUM COACH CLOTHING DIAGNOSTIC');
      results.writeln('=' * 50);
      results.writeln();

      // Load the RIVE file
      final rivFile = await rive.RiveFile.asset(
        'assets/rive/quantum_coach.riv',
      );
      final artboard = rivFile.mainArtboard.instance();

      setState(() {
        _artboard = artboard;
      });

      // Create state machine controller
      final controller = rive.StateMachineController.fromArtboard(
        artboard,
        'State Machine 1',
      );

      if (controller != null) {
        artboard.addController(controller);
        _controller = controller;

        results.writeln('✅ RIVE file loaded successfully');
        results.writeln('✅ State machine controller created');
        results.writeln();

        // Test all clothing-related inputs
        results.writeln('👕 CLOTHING INPUTS ANALYSIS:');
        final clothingInputs = controller.inputs
            .where((input) => _isClothingInput(input.name))
            .toList();

        results.writeln(
          'Found ${clothingInputs.length} clothing-related inputs:',
        );
        results.writeln();

        for (final input in clothingInputs) {
          results.writeln('• ${input.name} (${input.runtimeType})');

          if (input is rive.SMIBool) {
            results.writeln('  Current value: ${input.value}');
            results.writeln('  Type: Boolean toggle');
          } else if (input is rive.SMITrigger) {
            results.writeln('  Type: Animation trigger');
          } else if (input is rive.SMINumber) {
            results.writeln('  Current value: ${input.value}');
            results.writeln('  Type: Numeric parameter');
          }
          results.writeln();
        }

        // Test specific known triggers
        results.writeln('🎬 TESTING CLOTHING TRIGGERS:');
        final testTriggers = [
          'top_in',
          'pants_in',
          'skirt_in',
          'shoes_in',
          'hat_in',
        ];

        for (final triggerName in testTriggers) {
          final trigger = controller.findSMI(triggerName);
          if (trigger is rive.SMITrigger) {
            results.writeln('✅ $triggerName - Found and available');
          } else {
            results.writeln('❌ $triggerName - Not found or not a trigger');
          }
        }
        results.writeln();

        // Test clothing toggles
        results.writeln('👔 TESTING CLOTHING TOGGLES:');
        final testToggles = ['top_check', 'bottoms_check', 'skirt_check'];

        for (final toggleName in testToggles) {
          final toggle = controller.findInput<bool>(toggleName);
          if (toggle is rive.SMIBool) {
            results.writeln('✅ $toggleName - Found (current: ${toggle.value})');
          } else {
            results.writeln('❌ $toggleName - Not found or not a boolean');
          }
        }
        results.writeln();

        // Check for Chinese asset-related inputs
        results.writeln('🈳 CHINESE ASSET INPUTS:');
        final chineseInputs = controller.inputs
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

        if (chineseInputs.isNotEmpty) {
          results.writeln(
            'Found ${chineseInputs.length} Chinese-named inputs:',
          );
          for (final input in chineseInputs) {
            final translation = _getChineseTranslation(input.name);
            results.writeln(
              '• ${input.name} ($translation) - ${input.runtimeType}',
            );

            if (input is rive.SMIBool) {
              results.writeln('  Value: ${input.value}');
            } else if (input is rive.SMINumber) {
              results.writeln('  Value: ${input.value}');
            }
          }
        } else {
          results.writeln('No Chinese-named inputs found');
        }
        results.writeln();

        // Asset availability check
        results.writeln('📁 ASSET AVAILABILITY:');
        results.writeln('Expected PNG files in assets/rive/quantum_coach/:');
        final expectedAssets = [
          '衣-4344323.png (Clothing)',
          '裤-4344328.png (Pants)',
          '裙子-4337335.png (Skirt)',
          '鞋-4344342.png (Shoes)',
          '头饰-4344329.png (Headwear)',
        ];

        for (final asset in expectedAssets) {
          results.writeln('• $asset');
        }
        results.writeln();
        results.writeln(
          'Note: These files should be embedded in the RIVE file',
        );
        results.writeln(
          'or properly referenced for the clothing system to work.',
        );
      } else {
        results.writeln('❌ Failed to create state machine controller');
      }

      setState(() {
        _testResults = results.toString();
      });
    } catch (e) {
      setState(() {
        _testResults =
            '❌ Error loading RIVE file: $e\n\nThis could indicate:\n'
            '• RIVE file is corrupted or missing\n'
            '• Asset path is incorrect\n'
            '• Required dependencies are missing';
      });
    }
  }

  bool _isClothingInput(String name) {
    final clothingTerms = [
      'cloth',
      'shirt',
      'top',
      'bottom',
      'pants',
      'skirt',
      'shoe',
      'hat',
      'jacket',
      'dress',
      'outfit',
      'wear',
      '衣',
      '裤',
      '裙',
      '鞋',
      '帽',
    ];

    final lowerName = name.toLowerCase();
    return clothingTerms.any(
      (term) => lowerName.contains(term) || name.contains(term),
    );
  }

  String _getChineseTranslation(String name) {
    final translations = {
      '鞋': 'Shoes',
      '耳饰': 'Earrings',
      '裤': 'Pants',
      '衣': 'Clothing',
      '背饰': 'Back Accessories',
      '中发': 'Middle Hair',
      '后发': 'Back Hair',
      '前发': 'Front Hair',
      '面饰': 'Face Accessories',
      '项链': 'Necklace',
      '头饰': 'Headwear',
      '手持物': 'Handheld Items',
      '裙子': 'Skirt',
    };

    for (final entry in translations.entries) {
      if (name.contains(entry.key)) {
        return entry.value;
      }
    }
    return 'Unknown';
  }

  void _testClothingTrigger(String triggerName) {
    final trigger = _controller?.findSMI(triggerName);
    if (trigger is rive.SMITrigger) {
      trigger.fire();
      setState(() {
        _testResults = _testResults.replaceFirst(
          '• Testing $triggerName...',
          '✅ $triggerName fired successfully!',
        );
      });
    }
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
        title: const Text('Clothing System Tester'),
        backgroundColor: Colors.purple.shade800,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // RIVE Preview
          if (_artboard != null)
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.black12,
              child: Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: rive.Rive(artboard: _artboard!, fit: BoxFit.contain),
                ),
              ),
            ),

          // Test buttons
          if (_controller != null)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Test Clothing Changes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () => _testClothingTrigger('top_in'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: const Text('Change Top'),
                      ),
                      ElevatedButton(
                        onPressed: () => _testClothingTrigger('pants_in'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Change Pants'),
                      ),
                      ElevatedButton(
                        onPressed: () => _testClothingTrigger('skirt_in'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                        ),
                        child: const Text('Change Skirt'),
                      ),
                      ElevatedButton(
                        onPressed: () => _testClothingTrigger('shoes_in'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown,
                        ),
                        child: const Text('Change Shoes'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Test results
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: SelectableText(
                  _testResults,
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
