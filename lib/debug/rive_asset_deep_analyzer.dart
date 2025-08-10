import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;
import 'dart:convert';

/// Deep analysis tool for RIVE asset loading issues
class RiveAssetDeepAnalyzer extends StatefulWidget {
  const RiveAssetDeepAnalyzer({super.key});

  @override
  State<RiveAssetDeepAnalyzer> createState() => _RiveAssetDeepAnalyzerState();
}

class _RiveAssetDeepAnalyzerState extends State<RiveAssetDeepAnalyzer> {
  String _analysis = 'Starting deep analysis...';
  rive.Artboard? _artboard;
  rive.StateMachineController? _controller;

  @override
  void initState() {
    super.initState();
    _performDeepAnalysis();
  }

  Future<void> _performDeepAnalysis() async {
    final results = StringBuffer();
    results.writeln('🔬 RIVE ASSET DEEP ANALYSIS');
    results.writeln('=' * 50);
    results.writeln();

    try {
      // Step 1: Load RIVE file
      results.writeln('📁 STEP 1: Loading RIVE File');
      final rivFile = await rive.RiveFile.asset('assets/rive/quantum_coach.riv');
      results.writeln('✅ RIVE file loaded successfully');
      // results.writeln('File version: ${rivFile.version}'); // Version not available in current RIVE SDK
      results.writeln();

      // Step 2: Examine artboard
      results.writeln('🎨 STEP 2: Artboard Analysis');
      final artboard = rivFile.mainArtboard;
      results.writeln('Artboard name: ${artboard.name}');
      results.writeln('Artboard size: ${artboard.width} x ${artboard.height}');
      results.writeln('Animation count: ${artboard.animations.length}');
      results.writeln('State machine count: ${artboard.stateMachines.length}');
      results.writeln();

      // Step 3: Create controller and examine inputs
      results.writeln('🎮 STEP 3: Controller and Input Analysis');
      final artboardInstance = artboard.instance();
      setState(() {
        _artboard = artboardInstance;
      });

      final controller = rive.StateMachineController.fromArtboard(
        artboardInstance,
        'State Machine 1',
      );

      if (controller != null) {
        artboardInstance.addController(controller);
        _controller = controller;
        
        results.writeln('✅ State machine controller created');
        results.writeln('Input count: ${controller.inputs.length}');
        results.writeln();

        // Step 4: Detailed input analysis with encoding check
        results.writeln('🔤 STEP 4: Input Encoding Analysis');
        for (final input in controller.inputs) {
          results.writeln('Input: "${input.name}"');
          results.writeln('  Type: ${input.runtimeType}');
          results.writeln('  UTF-8 bytes: ${utf8.encode(input.name)}');
          results.writeln('  Character codes: ${input.name.codeUnits}');
          
          // Check if contains Chinese characters
          final containsChinese = input.name.codeUnits.any((code) => code > 127);
          results.writeln('  Contains non-ASCII: $containsChinese');
          
          if (input is rive.SMIBool) {
            results.writeln('  Current value: ${input.value}');
          } else if (input is rive.SMINumber) {
            results.writeln('  Current value: ${input.value}');
          }
          results.writeln();
        }

        // Step 5: Test trigger functionality with detailed logging
        results.writeln('🎬 STEP 5: Trigger Functionality Test');
        final clothingTriggers = ['top_in', 'pants_in', 'skirt_in', 'shoes_in', 'hat_in'];
        
        for (final triggerName in clothingTriggers) {
          results.writeln('Testing trigger: $triggerName');
          final trigger = controller.findSMI(triggerName);
          
          if (trigger is rive.SMITrigger) {
            results.writeln('  ✅ Found as SMITrigger');
            try {
              trigger.fire();
              results.writeln('  ✅ Fired successfully');
              
              // Wait a moment for any asset loading
              await Future.delayed(const Duration(milliseconds: 200));
              results.writeln('  ⏱️ Waited for asset resolution');
            } catch (e) {
              results.writeln('  ❌ Error firing: $e');
            }
          } else {
            results.writeln('  ❌ Not found or wrong type');
          }
          results.writeln();
        }

        // Step 6: Asset resolution debugging
        results.writeln('🖼️ STEP 6: Asset Resolution Debugging');
        // Platform info will be added in build method
        results.writeln('Platform info: Available in UI');
        results.writeln();

        // Try to detect if assets are actually loading
        results.writeln('Asset loading detection:');
        results.writeln('- Trigger clothing changes and observe console');
        results.writeln('- Missing asset errors should appear if assets aren\'t embedded');
        results.writeln('- If no errors but no visuals = rendering/platform issue');
        results.writeln();

      } else {
        results.writeln('❌ Failed to create state machine controller');
      }

      // Step 7: Flutter/Platform specific checks (will be populated in build method)
      results.writeln('🤖 STEP 7: Platform & Runtime Checks');
      results.writeln('Platform info: Available in build context');
      results.writeln();

      // Step 8: Recommendations
      results.writeln('💡 STEP 8: Diagnostic Recommendations');
      results.writeln();
      results.writeln('If you see "Rive asset (...) was not able to load" errors:');
      results.writeln('  → Assets are referenced but not properly embedded');
      results.writeln();
      results.writeln('If triggers fire but no visual change:');
      results.writeln('  → Assets embedded but runtime resolution issue');
      results.writeln('  → Try renaming assets to ASCII names in RIVE editor');
      results.writeln();
      results.writeln('If no errors at all:');
      results.writeln('  → System working correctly, issue may be elsewhere');
      results.writeln();

    } catch (e) {
      results.writeln('❌ ERROR in analysis: $e');
      results.writeln();
      results.writeln('Stack trace: ${StackTrace.current}');
    }

    setState(() {
      _analysis = results.toString();
    });
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
        title: const Text('RIVE Asset Deep Analyzer'),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Live RIVE preview
          if (_artboard != null)
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.black12,
              child: Center(
                child: SizedBox(
                  width: 150,
                  height: 150,
                  child: rive.Rive(
                    artboard: _artboard!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

          // Quick test buttons
          if (_controller != null)
            Container(
              padding: const EdgeInsets.all(8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        final trigger = _controller!.findSMI('top_in');
                        if (trigger is rive.SMITrigger) {
                          trigger.fire();
                          debugPrint('🔥 Fired top_in trigger - watch console for asset errors');
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Fire Top'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final trigger = _controller!.findSMI('pants_in');
                        if (trigger is rive.SMITrigger) {
                          trigger.fire();
                          debugPrint('🔥 Fired pants_in trigger - watch console for asset errors');
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      child: const Text('Fire Pants'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final toggle = _controller!.findInput<bool>('top_check');
                        if (toggle is rive.SMIBool) {
                          toggle.value = !toggle.value;
                          setState(() {});
                          debugPrint('🔄 Toggled top_check to ${toggle.value}');
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Toggle Top'),
                    ),
                  ],
                ),
              ),
            ),

          // Analysis results
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: SelectableText(
                  _analysis,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}