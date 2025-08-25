import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart' as rive;
import '../config/avatar_animations_config.dart';

/// Advanced avatar customization widget with missing asset handling
class AvatarCustomization extends ConsumerStatefulWidget {
  final String avatarId;
  final double width;
  final double height;
  final VoidCallback? onCustomizationChanged;

  const AvatarCustomization({
    super.key,
    required this.avatarId,
    this.width = 200,
    this.height = 200,
    this.onCustomizationChanged,
  });

  @override
  ConsumerState<AvatarCustomization> createState() => _AvatarCustomizationState();
}

class _AvatarCustomizationState extends ConsumerState<AvatarCustomization> {
  rive.StateMachineController? _controller;
  rive.Artboard? _artboard;
  
  // Customization state
  final Map<String, double> _customizationValues = {};
  final Map<String, bool> _customizationToggles = {};
  final Set<String> _workingInputs = {};
  final Set<String> _brokenInputs = {};
  
  // Input categories
  final List<rive.SMIInput> _eyeInputs = [];
  final List<rive.SMIInput> _skinInputs = [];
  final List<rive.SMIInput> _clothingInputs = [];
  final List<rive.SMIInput> _hairInputs = [];
  final List<rive.SMIInput> _accessoryInputs = [];

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadAvatar() async {
    try {
      final config = AvatarAnimationsConfig.getConfigWithFallback(widget.avatarId);
      final rivFile = await rive.RiveFile.asset(config.rivAssetPath);
      
      // Handle RuntimeArtboard properly
      rive.Artboard artboard;
      try {
        artboard = rivFile.mainArtboard.instance();
      } catch (e) {
        debugPrint('⚠️ Failed to clone artboard, using original: $e');
        artboard = rivFile.mainArtboard;
      }

      // Try to create state machine controller
      final controller = rive.StateMachineController.fromArtboard(
        artboard,
        'State Machine 1',
      );

      if (controller != null) {
        artboard.addController(controller);
        _controller = controller;
        
        setState(() {
          _artboard = artboard;
        });

        // Analyze and categorize inputs
        _analyzeInputs();
        
        // Test each input to see if it works
        await _validateInputs();
      }
    } catch (e) {
      debugPrint('Error loading avatar for customization: $e');
    }
  }

  void _analyzeInputs() {
    if (_controller == null) return;

    _eyeInputs.clear();
    _skinInputs.clear();
    _clothingInputs.clear();
    _hairInputs.clear();
    _accessoryInputs.clear();

    for (final input in _controller!.inputs) {
      final name = input.name.toLowerCase();
      
      // Categorize inputs
      if (name.contains('eye') || name.contains('眼')) {
        _eyeInputs.add(input);
      } else if (name.contains('skin') || name.contains('皮')) {
        _skinInputs.add(input);
      } else if (name.contains('cloth') || name.contains('shirt') || 
                name.contains('衣') || name.contains('裤') || name.contains('裙')) {
        _clothingInputs.add(input);
      } else if (name.contains('hair') || name.contains('发')) {
        _hairInputs.add(input);
      } else if (name.contains('饰') || name.contains('链') || name.contains('鞋')) {
        _accessoryInputs.add(input);
      }

      // Initialize values
      if (input is rive.SMINumber) {
        _customizationValues[input.name] = input.value;
      } else if (input is rive.SMIBool) {
        _customizationToggles[input.name] = input.value;
      }
    }
  }

  Future<void> _validateInputs() async {
    _workingInputs.clear();
    _brokenInputs.clear();

    for (final input in _controller!.inputs) {
      try {
        if (input is rive.SMINumber) {
          final originalValue = input.value;
          input.value = originalValue + 0.1; // Small test change
          await Future.delayed(const Duration(milliseconds: 50));
          input.value = originalValue; // Restore
          _workingInputs.add(input.name);
        } else if (input is rive.SMIBool) {
          final originalValue = input.value;
          input.value = !originalValue; // Toggle test
          await Future.delayed(const Duration(milliseconds: 50));
          input.value = originalValue; // Restore
          _workingInputs.add(input.name);
        } else if (input is rive.SMITrigger) {
          _workingInputs.add(input.name);
        }
      } catch (e) {
        _brokenInputs.add(input.name);
        debugPrint('Input ${input.name} appears to be broken: $e');
      }
    }

    setState(() {});
  }

  Widget _buildCustomizationSection(
    String title, 
    IconData icon, 
    List<rive.SMIInput> inputs,
    Color color,
  ) {
    if (inputs.isEmpty) return const SizedBox.shrink();

    final workingInputs = inputs.where((input) => _workingInputs.contains(input.name)).toList();
    final brokenInputs = inputs.where((input) => _brokenInputs.contains(input.name)).toList();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text('${workingInputs.length} working, ${brokenInputs.length} missing assets'),
        children: [
          // Working inputs
          ...workingInputs.map((input) => _buildInputControl(input, color)),
          
          // Broken inputs with warning
          if (brokenInputs.isNotEmpty) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Missing Assets (${brokenInputs.length})',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...brokenInputs.map((input) => Padding(
                    padding: const EdgeInsets.only(left: 24, bottom: 4),
                    child: Text(
                      '• ${input.name}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputControl(rive.SMIInput input, Color color) {
    if (input is rive.SMINumber) {
      // Get the current value and determine appropriate range
      final currentValue = _customizationValues[input.name] ?? input.value;
      
      // Determine min/max range based on current value
      double minValue = 0.0;
      double maxValue = 1.0;
      
      // If current value is outside 0-1 range, adjust the range
      if (currentValue < 0) {
        minValue = currentValue - 1.0;
      } else if (currentValue > 1) {
        maxValue = currentValue + 1.0;
      }
      
      // For very large values, use a more reasonable range
      if (currentValue.abs() > 100) {
        minValue = -360.0; // Common for hue values
        maxValue = 360.0;
      } else if (currentValue.abs() > 10) {
        minValue = -50.0;
        maxValue = 50.0;
      }
      
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(input.name, style: const TextStyle(fontWeight: FontWeight.w500)),
            Row(
              children: [
                Text(minValue.toStringAsFixed(1), 
                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
                Expanded(
                  child: Slider(
                    value: currentValue.clamp(minValue, maxValue),
                    min: minValue,
                    max: maxValue,
                    divisions: ((maxValue - minValue) * 10).toInt().clamp(10, 1000),
                    activeColor: color,
                    onChanged: (value) {
                      setState(() {
                        _customizationValues[input.name] = value;
                        input.value = value;
                      });
                      widget.onCustomizationChanged?.call();
                    },
                  ),
                ),
                Text(maxValue.toStringAsFixed(1), 
                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
            Center(
              child: Text(
                'Current: ${currentValue.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    } else if (input is rive.SMIBool) {
      return SwitchListTile(
        title: Text(input.name),
        value: _customizationToggles[input.name] ?? input.value,
        activeThumbColor: color,
        onChanged: (value) {
          setState(() {
            _customizationToggles[input.name] = value;
            input.value = value;
          });
          widget.onCustomizationChanged?.call();
        },
      );
    } else if (input is rive.SMITrigger) {
      return ListTile(
        title: Text(input.name),
        trailing: ElevatedButton(
          onPressed: () => input.fire(),
          style: ElevatedButton.styleFrom(backgroundColor: color),
          child: const Text('Trigger'),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar Preview
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _artboard != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: rive.Rive(
                    artboard: _artboard!,
                    fit: BoxFit.contain,
                  ),
                )
              : const Center(child: CircularProgressIndicator()),
        ),
        
        const SizedBox(height: 16),
        
        // Customization Controls
        if (_controller != null) ...[
          _buildCustomizationSection(
            'Eyes', 
            Icons.visibility, 
            _eyeInputs, 
            Colors.blue,
          ),
          _buildCustomizationSection(
            'Skin', 
            Icons.face, 
            _skinInputs, 
            Colors.orange,
          ),
          _buildCustomizationSection(
            'Clothing', 
            Icons.checkroom, 
            _clothingInputs, 
            Colors.purple,
          ),
          _buildCustomizationSection(
            'Hair', 
            Icons.face_retouching_natural, 
            _hairInputs, 
            Colors.brown,
          ),
          _buildCustomizationSection(
            'Accessories', 
            Icons.diamond, 
            _accessoryInputs, 
            Colors.pink,
          ),
        ],
        
        // Summary
        if (_controller != null)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Customization Status', 
                    style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Text('${_workingInputs.length} working parameters'),
                    ],
                  ),
                  if (_brokenInputs.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.error, color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Text('${_brokenInputs.length} missing assets'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}