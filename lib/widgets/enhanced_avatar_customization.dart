import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart' as rive;
import '../config/avatar_animations_config.dart';
import '../models/store/quantum_coach_config.dart';
import '../services/store/avatar_customization_service.dart';

/// Enhanced avatar customization widget specifically for Quantum Coach
class EnhancedAvatarCustomization extends ConsumerStatefulWidget {
  final double width;
  final double height;
  final VoidCallback? onCustomizationChanged;
  final bool showActionsTab;
  final bool showStatesTab;
  final bool enableAutoSave;

  const EnhancedAvatarCustomization({
    super.key,
    this.width = 300,
    this.height = 300,
    this.onCustomizationChanged,
    this.showActionsTab = false,
    this.showStatesTab = false,
    this.enableAutoSave = true,
  });

  @override
  ConsumerState<EnhancedAvatarCustomization> createState() => 
      _EnhancedAvatarCustomizationState();
}

class _EnhancedAvatarCustomizationState 
    extends ConsumerState<EnhancedAvatarCustomization>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  
  rive.StateMachineController? _controller;
  rive.Artboard? _artboard;
  final AvatarCustomizationService _customizationService = AvatarCustomizationService();
  
  // Current selections
  int _selectedEye = 12;
  int _selectedFace = 4;
  int _selectedSkin = 1;
  
  // Clothing states (parameters that will exist in RIVE file after adding them)
  final Map<String, bool> _clothingStates = {
    'top_check': true,
    'bottoms_check': true,
    'skirt_check': true,
    'shoes_check': true,
    'hat_check': true,
  };
  
  // Accessory states (parameters that will exist in RIVE file after adding them)
  final Map<String, bool> _accessoryStates = {
    'earring_check': true,
    'necklace_check': true,
    'glass_check': true,
    'hair_check': true,
    'back_check': true,
    'handobject_check': true,
  };
  
  // State values
  final Map<String, double> _stateValues = {
    'sit': 0.0,
    'flower_state': 0.0,
    'stateaction': 0.0,
  };

  @override
  void initState() {
    super.initState();
    
    // Calculate tab count based on what tabs to show
    int tabCount = 3; // Always have Face, Clothes, Accessories
    if (widget.showActionsTab) tabCount++;
    if (widget.showStatesTab) tabCount++;
    
    _tabController = TabController(length: tabCount, vsync: this);
    _initializeAsync();
  }

  Future<void> _initializeAsync() async {
    try {
      debugPrint('🔧 Starting async initialization...');
      
      debugPrint('📋 Initializing customization service...');
      await _customizationService.initialize();
      debugPrint('✅ Customization service initialized');
      
      debugPrint('🎮 Loading avatar...');
      await _loadAvatar();
      debugPrint('✅ Initialization complete');
      
    } catch (e) {
      debugPrint('❌ Error initializing enhanced avatar customization: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAvatar() async {
    try {
      debugPrint('🚀 Starting to load Quantum Coach avatar...');
      
      final config = AvatarAnimationsConfig.getConfigWithFallback('quantum_coach');
      debugPrint('📁 Config loaded: ${config.rivAssetPath}');
      
      final rivFile = await rive.RiveFile.asset(config.rivAssetPath);
      debugPrint('✅ RIVE file loaded successfully');
      
      // Handle RuntimeArtboard properly
      rive.Artboard artboard;
      try {
        artboard = rivFile.mainArtboard.instance();
        debugPrint('🎨 Artboard cloned successfully');
      } catch (e) {
        debugPrint('⚠️ Failed to clone artboard, using original: $e');
        artboard = rivFile.mainArtboard;
        debugPrint('🎨 Using original artboard');
      }

      final controller = rive.StateMachineController.fromArtboard(
        artboard,
        'State Machine 1',
      );

      if (controller != null) {
        debugPrint('🎮 Controller created successfully');
        artboard.addController(controller);
        _controller = controller;
        
        setState(() {
          _artboard = artboard;
        });
        debugPrint('🔄 State updated - artboard and controller set');

        // Validate clothing assets availability
        _validateClothingAssets();
        
        // Debug: List all boolean inputs
        _debugListAllInputs();

        // Load and apply saved customizations
        await _loadSavedCustomizations();
        _applyCurrentCustomizations();
        
        // Ensure idle animation is running
        _fireTrigger('Idle');
        
        debugPrint('✨ Avatar loading completed successfully');
      } else {
        debugPrint('❌ Failed to create controller');
      }
    } catch (e) {
      debugPrint('❌ Error loading enhanced avatar: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _loadSavedCustomizations() async {
    try {
      debugPrint('📖 Loading saved customizations...');
      
      final customization = await _customizationService.getCustomization('quantum_coach');
      
      // Load saved face values
      _selectedEye = (customization.numberValues['eye_color'] ?? 12.0).toInt();
      _selectedFace = (customization.numberValues['face'] ?? 4.0).toInt();
      _selectedSkin = (customization.numberValues['skin_color'] ?? 1.0).toInt();
      
      // Load saved clothing states (all default to true = visible)
      _clothingStates['top_check'] = customization.booleanValues['top_check'] ?? true;
      _clothingStates['bottoms_check'] = customization.booleanValues['bottoms_check'] ?? true;
      _clothingStates['skirt_check'] = customization.booleanValues['skirt_check'] ?? true;
      _clothingStates['shoes_check'] = customization.booleanValues['shoes_check'] ?? true;
      _clothingStates['hat_check'] = customization.booleanValues['hat_check'] ?? true;
      
      // Load saved accessory states (all default to true = visible)
      _accessoryStates['earring_check'] = customization.booleanValues['earring_check'] ?? true;
      _accessoryStates['necklace_check'] = customization.booleanValues['necklace_check'] ?? true;
      _accessoryStates['glass_check'] = customization.booleanValues['glass_check'] ?? true;
      _accessoryStates['hair_check'] = customization.booleanValues['hair_check'] ?? true;
      _accessoryStates['back_check'] = customization.booleanValues['back_check'] ?? true;
      _accessoryStates['handobject_check'] = customization.booleanValues['handobject_check'] ?? true;
      
      // Load saved state values
      _stateValues['sit'] = customization.numberValues['sit'] ?? 0.0;
      _stateValues['flower_state'] = customization.numberValues['flower_state'] ?? 0.0;
      _stateValues['stateaction'] = customization.numberValues['stateaction'] ?? 0.0;
      
      debugPrint('✅ Loaded saved customizations: Eye=$_selectedEye, Face=$_selectedFace, Skin=$_selectedSkin');
      debugPrint('🔧 Clothing states: $_clothingStates');
      
    } catch (e) {
      debugPrint('⚠️ Error loading saved customizations: $e');
      // Keep default values if loading fails
    }
  }

  void _validateClothingAssets() {
    if (_controller == null) return;

    // Check for Chinese clothing inputs that might have missing assets
    final chineseClothingInputs = _controller?.inputs.where((input) => 
      input.name.contains('鞋') || input.name.contains('耳饰') || 
      input.name.contains('裤') || input.name.contains('衣') || 
      input.name.contains('背饰') || input.name.contains('发') || 
      input.name.contains('面饰') || input.name.contains('项链') || 
      input.name.contains('头饰') || input.name.contains('手持物') || 
      input.name.contains('裙子')).toList() ?? [];

    if (chineseClothingInputs.isNotEmpty) {
      debugPrint('Found ${chineseClothingInputs.length} Chinese clothing inputs:');
      for (final input in chineseClothingInputs) {
        debugPrint('  • ${input.name} (${input.runtimeType})');
        
        // For clothing inputs, try to set safe default values
        if (input is rive.SMIBool) {
          // Start with clothing visible for testing
          input.value = true;
        }
      }
    }
  }

  void _applyCurrentCustomizations() {
    if (_controller == null) return;

    // Apply eye, face, skin values
    _setNumberInput('eye_color', _selectedEye.toDouble());
    _setNumberInput('face', _selectedFace.toDouble());
    _setNumberInput('skin_color', _selectedSkin.toDouble());

    // Apply clothing states
    for (final entry in _clothingStates.entries) {
      _setBoolInput(entry.key, entry.value);
    }
    
    // Apply accessory states
    for (final entry in _accessoryStates.entries) {
      _setBoolInput(entry.key, entry.value);
    }

    // Apply state values
    for (final entry in _stateValues.entries) {
      _setNumberInput(entry.key, entry.value);
    }
  }

  void _setNumberInput(String name, double value) {
    final input = _controller?.findInput<double>(name);
    if (input is rive.SMINumber) {
      input.value = value;
      if (widget.enableAutoSave) {
        _customizationService.updateNumber('quantum_coach', name, value);
      }
    }
  }

  void _setBoolInput(String name, bool value) {
    final input = _controller?.findInput<bool>(name);
    if (input is rive.SMIBool) {
      debugPrint('✅ Setting boolean input $name = $value');
      input.value = value;
      if (widget.enableAutoSave) {
        _customizationService.updateBoolean('quantum_coach', name, value);
      }
    } else {
      debugPrint('❌ Boolean input $name not found in RIVE file');
      // List all available boolean inputs for debugging
      final allInputs = _controller?.inputs ?? [];
      final boolInputs = allInputs.whereType<rive.SMIBool>().toList();
      debugPrint('Available boolean inputs: ${boolInputs.map((i) => i.name).join(', ')}');
    }
  }
  
  void _debugListAllInputs() {
    if (_controller == null) return;
    
    final allInputs = _controller!.inputs;
    debugPrint('🔍 === ALL RIVE INPUTS DEBUG ===');
    debugPrint('Total inputs: ${allInputs.length}');
    
    final boolInputs = allInputs.whereType<rive.SMIBool>().toList();
    debugPrint('Boolean inputs (${boolInputs.length}):');
    for (final input in boolInputs) {
      debugPrint('  • ${input.name} = ${input.value}');
    }
    
    final numberInputs = allInputs.whereType<rive.SMINumber>().toList();
    debugPrint('Number inputs (${numberInputs.length}):');
    for (final input in numberInputs) {
      debugPrint('  • ${input.name} = ${input.value}');
    }
    
    final triggerInputs = allInputs.whereType<rive.SMITrigger>().toList();
    debugPrint('Trigger inputs (${triggerInputs.length}):');
    for (final input in triggerInputs) {
      debugPrint('  • ${input.name}');
    }
    
    debugPrint('🔍 === END INPUTS DEBUG ===');
  }

  void _fireTrigger(String name) {
    final input = _controller?.findSMI(name);
    if (input is rive.SMITrigger) {
      try {
        debugPrint('Firing trigger: $name');
        input.fire();
        
        // Give a small delay for the animation to process
        Future.delayed(const Duration(milliseconds: 100), () {
          setState(() {}); // Force rebuild to show changes
        });
      } catch (e) {
        debugPrint('Error firing trigger $name: $e');
      }
    } else {
      debugPrint('Trigger $name not found or not a trigger type');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state if not ready
    if (_artboard == null || _controller == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.purple),
            const SizedBox(height: 16),
            const Text(
              'Loading Quantum Coach...',
              style: TextStyle(
                color: Colors.purple,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Artboard: ${_artboard != null ? '✅' : '❌'}\nController: ${_controller != null ? '✅' : '❌'}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Avatar Preview - Modern Card Design
        Container(
          width: widget.width,
          height: widget.height,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.shade50,
                Colors.blue.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.purple.withValues(alpha: 0.2), 
              width: 1
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(23),
            child: Stack(
              children: [
                // Background pattern
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topRight,
                        radius: 1.5,
                        colors: [
                          Colors.purple.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Avatar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _artboard != null
                      ? rive.Rive(
                          artboard: _artboard!,
                          fit: BoxFit.contain,
                        )
                      : const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: Colors.purple),
                              SizedBox(height: 16),
                              Text('Loading Quantum Coach...',
                                style: TextStyle(color: Colors.purple)),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Customization Tabs - Modern Design
        Container(
          height: 450,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withValues(alpha: 0.08),
                blurRadius: 30,
                offset: const Offset(0, 15),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Modern Tab Bar
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple, Colors.blue],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey.shade600,
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: [
                      const Tab(
                        icon: Icon(Icons.face_rounded, size: 20), 
                        text: 'Face',
                        height: 60,
                      ),
                      const Tab(
                        icon: Icon(Icons.checkroom_rounded, size: 20), 
                        text: 'Clothes',
                        height: 60,
                      ),
                      const Tab(
                        icon: Icon(Icons.diamond_rounded, size: 20), 
                        text: 'Accessories',
                        height: 60,
                      ),
                      if (widget.showActionsTab) const Tab(
                        icon: Icon(Icons.touch_app_rounded, size: 20), 
                        text: 'Actions',
                        height: 60,
                      ),
                      if (widget.showStatesTab) const Tab(
                        icon: Icon(Icons.tune_rounded, size: 20), 
                        text: 'States',
                        height: 60,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Tab Content - Spacious Container
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFaceCustomization(),
                      _buildClothingCustomization(),
                      _buildAccessoryCustomization(),
                      if (widget.showActionsTab) _buildInteractiveActions(),
                      if (widget.showStatesTab) _buildStateControls(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFaceCustomization() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Eyes Section
          _buildCustomizationSection(
            'Eyes',
            Icons.visibility,
            Colors.blue,
            Column(
              children: [
                Text('Current: ${QuantumCoachConfig.eyeOptions[_selectedEye].name}',
                  style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: QuantumCoachConfig.eyeOptions.map((option) {
                    final isSelected = _selectedEye == option.id;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedEye = option.id;
                        });
                        _setNumberInput('eye_color', option.id.toDouble());
                        widget.onCustomizationChanged?.call();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          option.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Face Expression Section
          _buildCustomizationSection(
            'Face Expression',
            Icons.sentiment_satisfied,
            Colors.orange,
            Column(
              children: [
                Text('Current: ${QuantumCoachConfig.faceOptions[_selectedFace].name}',
                  style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: QuantumCoachConfig.faceOptions.map((option) {
                    final isSelected = _selectedFace == option.id;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFace = option.id;
                        });
                        _setNumberInput('face', option.id.toDouble());
                        widget.onCustomizationChanged?.call();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.orange : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.orange : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          option.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Skin Tone Section
          _buildCustomizationSection(
            'Skin Tone',
            Icons.palette,
            Colors.brown,
            Column(
              children: [
                Text('Current: ${QuantumCoachConfig.skinOptions[_selectedSkin].name}',
                  style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: QuantumCoachConfig.skinOptions.map((option) {
                    final isSelected = _selectedSkin == option.id;
                    return GestureDetector(
                      onTap: () {
                        debugPrint('🎨 DEBUG: Skin option tapped - ${option.name} (ID: ${option.id})');
                        setState(() {
                          _selectedSkin = option.id;
                        });
                        _setNumberInput('skin_color', option.id.toDouble());
                        widget.onCustomizationChanged?.call();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.brown : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.brown : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          option.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClothingCustomization() {
    return SingleChildScrollView(
      child: Column(
        children: QuantumCoachConfig.clothingItems.map((item) {
          return _buildCustomizationSection(
            item.name,
            Icons.checkroom,
            Colors.purple,
            Column(
              children: [
                Text(item.description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Toggle clothing on/off
                    if (item.toggle != null)
                      ElevatedButton.icon(
                        onPressed: () {
                          final toggle = item.toggle;
                          if (toggle != null) {
                            debugPrint('🔄 Attempting to toggle ${item.name} ($toggle)');
                            final currentState = _clothingStates[toggle] ?? false;
                            debugPrint('📊 Current state: $currentState -> ${!currentState}');
                            setState(() {
                              _clothingStates[toggle] = !currentState;
                            });
                            _setBoolInput(toggle, !currentState);
                            widget.onCustomizationChanged?.call();
                          }
                        },
                        icon: Icon(_clothingStates[item.toggle] ?? false 
                            ? Icons.visibility 
                            : Icons.visibility_off),
                        label: Text(_clothingStates[item.toggle] ?? false 
                            ? 'Hide' 
                            : 'Show'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade100,
                          foregroundColor: Colors.purple.shade700,
                        ),
                      ),
                    // Change clothing style
                    ElevatedButton.icon(
                      onPressed: () {
                        debugPrint('Attempting to change style for: ${item.name} using trigger: ${item.trigger}');
                        _fireTrigger(item.trigger);
                        widget.onCustomizationChanged?.call();
                      },
                      icon: Text(item.icon, style: const TextStyle(fontSize: 18)),
                      label: const Text('Check Style'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAccessoryCustomization() {
    return SingleChildScrollView(
      child: Column(
        children: QuantumCoachConfig.accessoryItems.map((item) {
          return _buildCustomizationSection(
            item.name,
            Icons.diamond,
            Colors.pink,
            Column(
              children: [
                Text(item.description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Toggle accessory on/off
                    if (item.toggle != null)
                      ElevatedButton.icon(
                        onPressed: () {
                          final toggle = item.toggle;
                          if (toggle != null) {
                            final currentState = _accessoryStates[toggle] ?? false;
                            setState(() {
                              _accessoryStates[toggle] = !currentState;
                            });
                            _setBoolInput(toggle, !currentState);
                            widget.onCustomizationChanged?.call();
                          }
                        },
                        icon: Icon(_accessoryStates[item.toggle] ?? false 
                            ? Icons.visibility 
                            : Icons.visibility_off),
                        label: Text(_accessoryStates[item.toggle] ?? false 
                            ? 'Hide' 
                            : 'Show'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink.shade100,
                          foregroundColor: Colors.pink.shade700,
                        ),
                      ),
                    // Change accessory style
                    ElevatedButton.icon(
                      onPressed: () {
                        _fireTrigger(item.trigger);
                        widget.onCustomizationChanged?.call();
                      },
                      icon: Text(item.icon, style: const TextStyle(fontSize: 18)),
                      label: const Text('Check'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInteractiveActions() {
    return SingleChildScrollView(
      child: Column(
        children: QuantumCoachConfig.interactiveActions.map((action) {
          return _buildCustomizationSection(
            action.name,
            Icons.touch_app,
            Colors.green,
            Column(
              children: [
                Text(action.description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    _fireTrigger(action.trigger);
                  },
                  icon: Text(action.icon, style: const TextStyle(fontSize: 18)),
                  label: Text(action.name),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStateControls() {
    return SingleChildScrollView(
      child: Column(
        children: QuantumCoachConfig.stateControls.map((control) {
          return _buildCustomizationSection(
            control.name,
            Icons.tune,
            Colors.teal,
            Column(
              children: [
                Text(control.description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(control.min.toString(), 
                      style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    Expanded(
                      child: Slider(
                        value: _stateValues[control.parameter] ?? control.min,
                        min: control.min,
                        max: control.max,
                        divisions: (control.max - control.min).toInt(),
                        activeColor: Colors.teal,
                        onChanged: (value) {
                          setState(() {
                            _stateValues[control.parameter] = value;
                          });
                          _setNumberInput(control.parameter, value);
                          widget.onCustomizationChanged?.call();
                        },
                      ),
                    ),
                    Text(control.max.toString(), 
                      style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                Text('Current: ${(_stateValues[control.parameter] ?? control.min).toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCustomizationSection(String title, IconData icon, Color color, Widget content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            content,
          ],
        ),
      ),
    );
  }
}