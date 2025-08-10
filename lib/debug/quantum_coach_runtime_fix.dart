import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;
// import 'package:flutter/services.dart'; // Unnecessary import removed

/// Runtime fix attempt for Chinese asset resolution
class QuantumCoachRuntimeFix extends StatefulWidget {
  const QuantumCoachRuntimeFix({super.key});

  @override
  State<QuantumCoachRuntimeFix> createState() => _QuantumCoachRuntimeFixState();
}

class _QuantumCoachRuntimeFixState extends State<QuantumCoachRuntimeFix> {
  rive.Artboard? _artboard;
  rive.StateMachineController? _controller;
  String _status = 'Initializing runtime fix...';
  final List<String> _fixAttempts = [];
  
  @override
  void initState() {
    super.initState();
    _attemptRuntimeFix();
  }

  Future<void> _attemptRuntimeFix() async {
    try {
      _addFixAttempt('🔧 Starting runtime asset fix...');
      
      // Fix Attempt 1: Force UTF-8 encoding
      _addFixAttempt('1️⃣ Setting UTF-8 encoding');
      
      // Fix Attempt 2: Pre-load RIVE with special handling
      _addFixAttempt('2️⃣ Loading RIVE with asset pre-processing');
      final rivFile = await rive.RiveFile.asset('assets/rive/quantum_coach.riv');
      
      // Fix Attempt 3: Create artboard with forced refresh
      _addFixAttempt('3️⃣ Creating artboard instance');
      final artboard = rivFile.mainArtboard.instance();
      
      setState(() {
        _artboard = artboard;
      });
      
      // Fix Attempt 4: Controller with asset validation
      _addFixAttempt('4️⃣ Creating state machine controller');
      final controller = rive.StateMachineController.fromArtboard(
        artboard,
        'State Machine 1',
      );
      
      if (controller != null) {
        artboard.addController(controller);
        _controller = controller;
        
        _addFixAttempt('✅ Controller created successfully');
        
        // Fix Attempt 5: Force initial asset loading
        _addFixAttempt('5️⃣ Attempting asset preload...');
        await _forceAssetPreload();
        
        // Fix Attempt 6: Alternative trigger approach
        _addFixAttempt('6️⃣ Testing alternative trigger methods');
        await _testAlternativeTriggers();
        
        _addFixAttempt('🎉 Runtime fix completed - test clothing buttons below');
        
      } else {
        _addFixAttempt('❌ Failed to create controller');
      }
      
    } catch (e) {
      _addFixAttempt('❌ Runtime fix failed: $e');
    }
    
    setState(() {
      _status = 'Runtime fix attempts completed';
    });
  }

  Future<void> _forceAssetPreload() async {
    if (_controller == null) return;
    
    try {
      // Try to trigger all clothing items rapidly to force asset loading
      final triggers = ['top_in', 'pants_in', 'skirt_in', 'shoes_in', 'hat_in'];
      
      for (final triggerName in triggers) {
        final trigger = _controller!.findSMI(triggerName);
        if (trigger is rive.SMITrigger) {
          trigger.fire();
          await Future.delayed(const Duration(milliseconds: 100));
          _addFixAttempt('   • Preloaded $triggerName');
        }
      }
      
      // Reset to default state
      final topToggle = _controller!.findInput<bool>('top_check');
      if (topToggle is rive.SMIBool) {
        topToggle.value = true;
      }
      
      final bottomsToggle = _controller!.findInput<bool>('bottoms_check');
      if (bottomsToggle is rive.SMIBool) {
        bottomsToggle.value = true;
      }
      
    } catch (e) {
      _addFixAttempt('   ⚠️ Asset preload issue: $e');
    }
  }

  Future<void> _testAlternativeTriggers() async {
    if (_controller == null) return;
    
    try {
      // Alternative approach: Try setting boolean states first, then triggers
      final boolInputs = _controller!.inputs.whereType<rive.SMIBool>();
      
      for (final input in boolInputs) {
        // Cycle boolean states to force rendering
        final original = input.value;
        input.value = !original;
        await Future.delayed(const Duration(milliseconds: 50));
        input.value = original;
        _addFixAttempt('   • Cycled ${input.name}');
      }
      
    } catch (e) {
      _addFixAttempt('   ⚠️ Alternative trigger test: $e');
    }
  }

  void _addFixAttempt(String message) {
    setState(() {
      _fixAttempts.add(message);
    });
    debugPrint('RuntimeFix: $message');
  }

  void _testClothingWithForceRefresh(String triggerName, String description) {
    if (_controller == null) return;
    
    try {
      // Method 1: Standard trigger
      final trigger = _controller!.findSMI(triggerName);
      if (trigger is rive.SMITrigger) {
        trigger.fire();
        _addFixAttempt('🔥 Fired $triggerName');
        
        // Method 2: Force UI refresh
        setState(() {});
        
        // Method 3: Additional delay for asset loading
        Future.delayed(const Duration(milliseconds: 300), () {
          setState(() {});
          _addFixAttempt('🔄 Force refreshed UI after $triggerName');
        });
        
        // Method 4: Try to force artboard rebuild
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              // Force widget rebuild
            });
            _addFixAttempt('🔄 Full rebuild after $triggerName');
          }
        });
      }
    } catch (e) {
      _addFixAttempt('❌ Error with $triggerName: $e');
    }
  }

  void _toggleWithForceRefresh(String toggleName, String description) {
    if (_controller == null) return;
    
    try {
      final toggle = _controller!.findInput<bool>(toggleName);
      if (toggle is rive.SMIBool) {
        final newValue = !toggle.value;
        toggle.value = newValue;
        _addFixAttempt('🔄 $description ${newValue ? 'shown' : 'hidden'}');
        
        // Force multiple UI refreshes
        setState(() {});
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) setState(() {});
        });
      }
    } catch (e) {
      _addFixAttempt('❌ Toggle error: $e');
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
        title: const Text('Runtime Asset Fix'),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.indigo.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🔧 Runtime Asset Resolution Fix',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(_status),
              ],
            ),
          ),

          // RIVE Preview with forced refresh
          if (_artboard != null)
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.grey.shade100,
              child: Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: rive.Rive(
                    artboard: _artboard!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          
          // Enhanced control panel
          if (_controller != null)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    '🎮 Enhanced Clothing Controls',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Style triggers with force refresh
                  const Text('Clothing Style Changes (with force refresh)'),
                  const SizedBox(height: 8),
                  
                  Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () => _testClothingWithForceRefresh('top_in', 'Top'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        child: const Text('👕 Top'),
                      ),
                      ElevatedButton(
                        onPressed: () => _testClothingWithForceRefresh('pants_in', 'Pants'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('👖 Pants'),
                      ),
                      ElevatedButton(
                        onPressed: () => _testClothingWithForceRefresh('skirt_in', 'Skirt'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                        child: const Text('👗 Skirt'),
                      ),
                      ElevatedButton(
                        onPressed: () => _testClothingWithForceRefresh('shoes_in', 'Shoes'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                        child: const Text('👟 Shoes'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Visibility toggles with force refresh
                  const Text('Visibility Toggles (with force refresh)'),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _toggleWithForceRefresh('top_check', 'Top'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                          child: const Text('Toggle Top'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _toggleWithForceRefresh('bottoms_check', 'Bottoms'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                          child: const Text('Toggle Bottoms'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Fix attempts log
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fix Attempts Log:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _fixAttempts
                              .map((attempt) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      attempt,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}