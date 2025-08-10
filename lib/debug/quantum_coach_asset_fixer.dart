import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

/// Tool to demonstrate clothing system working without missing assets
class QuantumCoachAssetFixer extends StatefulWidget {
  const QuantumCoachAssetFixer({super.key});

  @override
  State<QuantumCoachAssetFixer> createState() => _QuantumCoachAssetFixerState();
}

class _QuantumCoachAssetFixerState extends State<QuantumCoachAssetFixer> {
  rive.Artboard? _artboard;
  rive.StateMachineController? _controller;
  String _status = 'Loading RIVE file...';
  
  // Track current states
  bool _topVisible = true;
  bool _bottomsVisible = true;
  bool _skirtVisible = false;
  
  @override
  void initState() {
    super.initState();
    _loadRiveWithWorkaround();
  }

  Future<void> _loadRiveWithWorkaround() async {
    try {
      setState(() {
        _status = 'Loading RIVE file and implementing workaround...';
      });

      // Load the RIVE file (ignore asset loading errors)
      final rivFile = await rive.RiveFile.asset('assets/rive/quantum_coach.riv');
      final artboard = rivFile.mainArtboard.instance();
      
      // Create state machine controller
      final controller = rive.StateMachineController.fromArtboard(
        artboard,
        'State Machine 1',
      );

      if (controller != null) {
        artboard.addController(controller);
        _controller = controller;
        
        setState(() {
          _artboard = artboard;
          _status = '✅ RIVE loaded successfully! Clothing system ready (ignoring missing assets)';
        });

        // Apply initial clothing states
        _applyClothingStates();
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error loading RIVE: $e';
      });
    }
  }

  void _applyClothingStates() {
    if (_controller == null) return;

    // Set clothing visibility toggles
    final topToggle = _controller!.findInput<bool>('top_check');
    if (topToggle is rive.SMIBool) {
      topToggle.value = _topVisible;
    }

    final bottomsToggle = _controller!.findInput<bool>('bottoms_check');
    if (bottomsToggle is rive.SMIBool) {
      bottomsToggle.value = _bottomsVisible;
    }

    final skirtToggle = _controller!.findInput<bool>('skirt_check');
    if (skirtToggle is rive.SMIBool) {
      skirtToggle.value = _skirtVisible;
    }
  }

  void _fireClothingTrigger(String triggerName, String description) {
    final trigger = _controller?.findSMI(triggerName);
    if (trigger is rive.SMITrigger) {
      trigger.fire();
      setState(() {
        _status = '🎬 Fired $description trigger successfully!\n'
            'Note: Visual changes may be limited due to missing embedded assets.';
      });
    } else {
      setState(() {
        _status = '❌ Trigger $triggerName not found';
      });
    }
  }

  void _toggleClothing(String toggleName, String description) {
    final toggle = _controller?.findInput<bool>(toggleName);
    if (toggle is rive.SMIBool) {
      final newValue = !toggle.value;
      toggle.value = newValue;
      
      // Update local state tracking
      switch (toggleName) {
        case 'top_check':
          _topVisible = newValue;
          break;
        case 'bottoms_check':
          _bottomsVisible = newValue;
          break;
        case 'skirt_check':
          _skirtVisible = newValue;
          break;
      }
      
      setState(() {
        _status = '👔 $description ${newValue ? 'shown' : 'hidden'}\n'
            'Note: Full visual changes require embedded assets.';
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
        title: const Text('Asset-Free Clothing Demo'),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.orange.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚠️ Missing Assets Workaround',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This demo shows that the clothing system works functionally. '
                  'Visual changes are limited because PNG assets need to be '
                  'embedded in the RIVE file during creation.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),

          // RIVE Preview
          if (_artboard != null)
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.grey.shade100,
              child: Center(
                child: SizedBox(
                  width: 250,
                  height: 250,
                  child: rive.Rive(
                    artboard: _artboard!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          
          // Control Panel
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎛️ Clothing Controls',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Visibility Toggles
                  const Text(
                    'Clothing Visibility (These work!)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _toggleClothing('top_check', 'Top'),
                          icon: Icon(_topVisible ? Icons.visibility : Icons.visibility_off),
                          label: Text('Top: ${_topVisible ? 'Visible' : 'Hidden'}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _topVisible ? Colors.blue : Colors.grey,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _toggleClothing('bottoms_check', 'Bottoms'),
                          icon: Icon(_bottomsVisible ? Icons.visibility : Icons.visibility_off),
                          label: Text('Bottoms: ${_bottomsVisible ? 'Visible' : 'Hidden'}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _bottomsVisible ? Colors.green : Colors.grey,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  ElevatedButton.icon(
                    onPressed: () => _toggleClothing('skirt_check', 'Skirt'),
                    icon: Icon(_skirtVisible ? Icons.visibility : Icons.visibility_off),
                    label: Text('Skirt: ${_skirtVisible ? 'Visible' : 'Hidden'}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _skirtVisible ? Colors.pink : Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Style Change Triggers
                  const Text(
                    'Style Changes (Functional but limited visuals)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () => _fireClothingTrigger('top_in', 'Top Style Change'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        child: const Text('👕 Change Top'),
                      ),
                      ElevatedButton(
                        onPressed: () => _fireClothingTrigger('pants_in', 'Pants Style Change'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('👖 Change Pants'),
                      ),
                      ElevatedButton(
                        onPressed: () => _fireClothingTrigger('skirt_in', 'Skirt Style Change'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                        child: const Text('👗 Change Skirt'),
                      ),
                      ElevatedButton(
                        onPressed: () => _fireClothingTrigger('shoes_in', 'Shoes Style Change'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                        child: const Text('👟 Change Shoes'),
                      ),
                      ElevatedButton(
                        onPressed: () => _fireClothingTrigger('hat_in', 'Hat Style Change'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                        child: const Text('🎩 Change Hat'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Status Display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Status:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(_status),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Solution Instructions
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '💡 Solution:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'To fix the visual clothing changes:\n'
                          '1. Open quantum_coach.riv in Rive Editor\n'
                          '2. Re-embed the Chinese PNG assets properly\n'
                          '3. Export with embedded assets\n'
                          '\n'
                          'Alternatively, recreate the clothing system without external assets.',
                        ),
                      ],
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