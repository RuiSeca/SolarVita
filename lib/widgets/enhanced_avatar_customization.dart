import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart' as rive;
import '../models/store/quantum_coach_config.dart';
import '../providers/firebase/firebase_avatar_provider.dart';
import '../providers/avatar/avatar_artboard_provider.dart';
import '../theme/app_theme.dart';

/// Enhanced avatar customization widget for Quantum Coach and Director Coach
class EnhancedAvatarCustomization extends ConsumerStatefulWidget {
  final double width;
  final double height;
  final VoidCallback? onCustomizationChanged;
  final bool showActionsTab;
  final bool showStatesTab;
  final bool enableAutoSave;
  final String avatarId; // Add avatarId parameter

  const EnhancedAvatarCustomization({
    super.key,
    this.width = 300,
    this.height = 300,
    this.onCustomizationChanged,
    this.showActionsTab = false,
    this.showStatesTab = false,
    this.enableAutoSave = false, // Disable auto-save by default
    this.avatarId = 'quantum_coach', // Default to quantum_coach for backward compatibility
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
  
  // Debouncing for save operations
  Timer? _saveDebounceTimer;
  Map<String, dynamic>? _pendingCustomizations;
  bool _isSaving = false;
  
  // Current selections
  int _selectedEye = 0;
  int _selectedFace = 0;
  int _selectedSkin = 0;
  bool _topCheck = false;
  bool _bottomsCheck = false;
  bool _shoesCheck = false;
  bool _hatCheck = false;
  bool _earringCheck = false;
  bool _necklaceCheck = false;
  bool _glassCheck = false;
  bool _hairCheck = false;

  // Track whether we've initialized to avoid duplicate initialization
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize tab controller - only 3 tabs: Face, Clothes, Accessories
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Initialize only once when dependencies are ready
    if (!_isInitialized) {
      _isInitialized = true;
      
      // Use post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Initialize Rive
          _initializeRive();
          
          // Load saved customizations
          _loadSavedCustomizations();
        }
      });
    }
  }

  @override
  void dispose() {
    // Cancel any pending save operations
    _saveDebounceTimer?.cancel();
    
    // Save any pending customizations before disposal
    if (_pendingCustomizations != null && !_isSaving) {
      _performSave(_pendingCustomizations!).catchError((e) {
        debugPrint('Warning: Failed to save pending customizations on dispose: $e');
      });
    }
    
    _tabController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeRive() async {
    try {
      // Force refresh the artboard to ensure we get the latest customizations
      ref.invalidate(customizedArtboardProvider(widget.avatarId));
      
      final artboard = await ref.read(customizedArtboardProvider(widget.avatarId).future);
      
      if (artboard != null && mounted) {
        setState(() {
          _artboard = artboard;
        });
        
        // Initialize state machine controller
        _controller = rive.StateMachineController.fromArtboard(artboard, 'State Machine 1');
        if (_controller != null && mounted) {
          artboard.addController(_controller!);
          setState(() {});
        }
        
        // Apply existing customizations to the new artboard
        _applyCustomizationsToArtboard();
      }
    } catch (e) {
      debugPrint('Error initializing Rive: $e');
    }
  }

  void _loadSavedCustomizations() {
    try {
      final avatarService = ref.read(firebaseAvatarServiceProvider);
      final customizations = avatarService.getAvatarCustomizations(widget.avatarId);
      
      if (customizations.isNotEmpty) {
        setState(() {
          _selectedEye = customizations['eye_color']?.toInt() ?? 0;
          _selectedFace = customizations['face']?.toInt() ?? 0;
          _selectedSkin = customizations['skin_color']?.toInt() ?? 0;
          _topCheck = customizations['top_check'] ?? false;
          _bottomsCheck = customizations['bottoms_check'] ?? false;
          _shoesCheck = customizations['shoes_check'] ?? false;
          _hatCheck = customizations['hat_check'] ?? false;
          _earringCheck = customizations['earring_check'] ?? false;
          _necklaceCheck = customizations['necklace_check'] ?? false;
          _glassCheck = customizations['glass_check'] ?? false;
          _hairCheck = customizations['hair_check'] ?? false;
        });
        
        // Apply to artboard
        _applyCustomizationsToArtboard();
      }
    } catch (e) {
      debugPrint('Error loading saved customizations: $e');
    }
  }

  void _applyCustomizationsToArtboard() {
    if (_controller == null) return;
    
    try {
      // Apply number inputs
      _setNumberInput('eye_color', _selectedEye.toDouble());
      _setNumberInput('face', _selectedFace.toDouble());
      _setNumberInput('skin_color', _selectedSkin.toDouble());
      
      // Apply boolean inputs
      _setBoolInput('top_check', _topCheck);
      _setBoolInput('bottoms_check', _bottomsCheck);
      _setBoolInput('shoes_check', _shoesCheck);
      _setBoolInput('hat_check', _hatCheck);
      _setBoolInput('earring_check', _earringCheck);
      _setBoolInput('necklace_check', _necklaceCheck);
      _setBoolInput('glass_check', _glassCheck);
      _setBoolInput('hair_check', _hairCheck);
    } catch (e) {
      debugPrint('Error applying customizations: $e');
    }
  }

  void _setNumberInput(String inputName, double value) {
    if (_controller == null) return;
    
    try {
      final input = _controller!.findInput<double>(inputName);
      if (input is rive.SMINumber) {
        input.value = value;
        debugPrint('✅ Set number input $inputName = $value');
        
        // Real-time preview is handled by the Rive controller directly
        // Removed problematic cache live updates that were failing
      }
    } catch (e) {
      debugPrint('Error setting number input $inputName: $e');
    }
  }

  void _setBoolInput(String inputName, bool value) {
    if (_controller == null) return;
    
    try {
      final input = _controller!.findInput<bool>(inputName);
      if (input is rive.SMIBool) {
        input.value = value;
        debugPrint('✅ Set bool input $inputName = $value');
        
        // Real-time preview is handled by the Rive controller directly
        // Removed problematic cache live updates that were failing
      }
    } catch (e) {
      debugPrint('Error setting bool input $inputName: $e');
    }
  }

  /// Manual save method triggered by save button
  Future<void> _manualSaveCustomizations() async {
    if (_isSaving) return;

    final customizations = {
      'eye_color': _selectedEye,
      'face': _selectedFace,
      'skin_color': _selectedSkin,
      'top_check': _topCheck,
      'bottoms_check': _bottomsCheck,
      'shoes_check': _shoesCheck,
      'hat_check': _hatCheck,
      'earring_check': _earringCheck,
      'necklace_check': _necklaceCheck,
      'glass_check': _glassCheck,
      'hair_check': _hairCheck,
    };

    try {
      // Add timeout to prevent infinite loading
      await _performSave(customizations).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⚠️ Save operation timed out, but customizations may have been saved');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('Save completed, but preview refresh timed out'),
                  ],
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
      );
    } catch (e) {
      debugPrint('❌ Manual save failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Save failed. Please try again.'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }


  Future<void> _performSave(Map<String, dynamic> customizations) async {
    if (_isSaving) return;
    
    try {
      _isSaving = true;
      debugPrint('💾 SAVE DEBUG: Starting customization save for ${widget.avatarId}');
      debugPrint('💾 SAVE DEBUG: Customizations: $customizations');
      
      final avatarService = ref.read(firebaseAvatarServiceProvider);
      
      // DEBUG: Check if user owns the avatar
      final ownsAvatar = avatarService.doesUserOwnAvatar(widget.avatarId);
      debugPrint('💾 SAVE DEBUG: User owns ${widget.avatarId}: $ownsAvatar');
      
      // DEBUG: Check current user ID
      final userId = avatarService.currentUserId;
      debugPrint('💾 SAVE DEBUG: Current user ID: $userId');
      
      if (!ownsAvatar) {
        debugPrint('❌ SAVE ERROR: User does not own ${widget.avatarId}, cannot save customizations');
        return;
      }
      
      await avatarService.updateAvatarCustomizations(widget.avatarId, customizations);
      
      debugPrint('✅ SAVE SUCCESS: Customizations saved successfully for ${widget.avatarId}');
      
      // Small delay to let Firebase save complete before cache updates
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Refresh customizations without destroying artboard to prevent freezing
      await _refreshCustomizationsOnly();
      
      // Show success message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Customizations saved successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      
      if (widget.onCustomizationChanged != null) {
        widget.onCustomizationChanged!();
      }
    } catch (e) {
      debugPrint('❌ SAVE ERROR: Failed to save customizations: $e');
      // Don't rethrow - just log the error to prevent UI freezing
    } finally {
      _isSaving = false;
      _pendingCustomizations = null;
    }
  }

  /// Refresh customizations only without destroying the artboard (prevents freezing)
  Future<void> _refreshCustomizationsOnly() async {
    try {
      // Check if widget is still mounted
      if (!mounted) {
        debugPrint('⚠️ Widget disposed, skipping customization refresh for ${widget.avatarId}');
        return;
      }
      
      debugPrint('🔄 Refreshing customizations for ${widget.avatarId} and notifying all screens');
      
      // Just reapply the customizations to the existing artboard
      // This preserves the artboard and prevents freezing
      _applyCustomizationsToArtboard();
      
      // Small delay to prevent setState during build issues
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (!mounted) return;
      
      // AGGRESSIVE BUT TARGETED: Clear caches completely for this avatar to ensure animations work
      debugPrint('🎯 Performing complete cache refresh for ${widget.avatarId} to ensure animations work');
      
      // Use post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        
        try {
          // Invalidate ALL providers for this avatar
          ref.invalidate(customizedArtboardProvider(widget.avatarId));
          ref.invalidate(basicArtboardProvider(widget.avatarId));
          
          // Clear all caches for this avatar in the manager
          final cacheNotifier = ref.read(artboardCacheNotifierProvider);
          cacheNotifier.onCustomizationsChangedImmediate(widget.avatarId);
          
          debugPrint('🧹 Cleared ALL caches for ${widget.avatarId} - animations should work across all screens');
        } catch (e) {
          debugPrint('⚠️ Error during cache clear: $e');
        }
      });
      
      debugPrint('✅ Successfully refreshed customizations for ${widget.avatarId} across all screens');
      
    } catch (e) {
      debugPrint('⚠️ Error refreshing customizations: $e');
      // Don't rethrow - the save already succeeded
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
              'Loading Avatar...',
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

    return SingleChildScrollView(
      child: Column(
        children: [
          // Avatar Preview - Modern Card Design with Theme Support
          Container(
            width: widget.width,
            height: widget.height,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppTheme.isDarkMode(context) ? [
                  Colors.purple.shade900.withValues(alpha: 0.3),
                  Colors.blue.shade900.withValues(alpha: 0.3),
                ] : [
                  Colors.purple.shade50,
                  Colors.blue.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.isDarkMode(context) 
                  ? Colors.purple.withValues(alpha: 0.4)
                  : Colors.purple.withValues(alpha: 0.2), 
                width: 1
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.isDarkMode(context)
                    ? Colors.purple.withValues(alpha: 0.2)
                    : Colors.purple.withValues(alpha: 0.1),
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
                  // Background pattern with theme support
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topRight,
                          radius: 1.5,
                          colors: [
                            AppTheme.isDarkMode(context)
                              ? Colors.purple.withValues(alpha: 0.1)
                              : Colors.purple.withValues(alpha: 0.05),
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
                        : Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  color: AppTheme.isDarkMode(context) 
                                    ? Colors.purple.shade300
                                    : Colors.purple
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Loading Avatar...',
                                  style: TextStyle(
                                    color: AppTheme.isDarkMode(context)
                                      ? Colors.purple.shade300
                                      : Colors.purple
                                  )
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Customization Tabs - Modern Design with theme support and responsive height
          Container(
            constraints: BoxConstraints(
              minHeight: 400,
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor(context),
              borderRadius: BorderRadius.circular(28),
              border: AppTheme.isDarkMode(context) ? Border.all(
                color: Colors.purple.withValues(alpha: 0.2),
                width: 1,
              ) : null,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.isDarkMode(context)
                    ? Colors.purple.withValues(alpha: 0.15)
                    : Colors.purple.withValues(alpha: 0.08),
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
                  // Modern Tab Bar with theme support
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.isDarkMode(context)
                        ? Colors.grey.shade800
                        : Colors.grey.shade100,
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
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: AppTheme.isDarkMode(context)
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                      labelStyle: const TextStyle(
                        fontSize: 13,
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Save Button with theme support
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _manualSaveCustomizations,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.isDarkMode(context)
                  ? Colors.purple.shade400
                  : Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 8,
                shadowColor: AppTheme.isDarkMode(context)
                  ? Colors.purple.withValues(alpha: 0.4)
                  : Colors.purple.withValues(alpha: 0.3),
              ),
              child: _isSaving
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Saving...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.save_rounded, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Save Customizations',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          
          // Add bottom padding to ensure content is not cut off
          const SizedBox(height: 100),
        ],
      ),
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
                        _setNumberInput('eye_color', _selectedEye.toDouble());
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue.withValues(alpha: 0.3) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: isSelected ? Colors.purple : Colors.grey.shade300,
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: Colors.purple.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ] : null,
                        ),
                        child: isSelected 
                          ? const Icon(Icons.check, color: Colors.white, size: 24)
                          : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Face Section
          _buildCustomizationSection(
            'Face',
            Icons.face,
            Colors.orange,
            Column(
              children: [
                Text('Current: Face ${_selectedFace + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(5, (index) {
                    final isSelected = _selectedFace == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFace = index;
                        });
                        _setNumberInput('face', _selectedFace.toDouble());
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange.shade100, Colors.orange.shade200],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isSelected ? Colors.orange : Colors.grey.shade300,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.orange : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Skin Section
          _buildCustomizationSection(
            'Skin',
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
                        setState(() {
                          _selectedSkin = option.id;
                        });
                        _setNumberInput('skin_color', _selectedSkin.toDouble());
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.brown.withValues(alpha: 0.3) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: isSelected ? Colors.brown : Colors.grey.shade300,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: isSelected 
                          ? const Icon(Icons.check, color: Colors.white, size: 24)
                          : null,
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
        children: [
          _buildToggleSection('Top', Icons.shopping_bag, _topCheck, (value) {
            setState(() {
              _topCheck = value;
            });
            _setBoolInput('top_check', _topCheck);
          }),
          
          const SizedBox(height: 16),
          
          _buildToggleSection('Bottoms', Icons.checkroom, _bottomsCheck, (value) {
            setState(() {
              _bottomsCheck = value;
            });
            _setBoolInput('bottoms_check', _bottomsCheck);
          }),
          
          const SizedBox(height: 16),
          
          _buildToggleSection('Shoes', Icons.directions_run, _shoesCheck, (value) {
            setState(() {
              _shoesCheck = value;
            });
            _setBoolInput('shoes_check', _shoesCheck);
          }),
        ],
      ),
    );
  }

  Widget _buildAccessoryCustomization() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildToggleSection('Hat', Icons.architecture, _hatCheck, (value) {
            setState(() {
              _hatCheck = value;
            });
            _setBoolInput('hat_check', _hatCheck);
          }),
          
          const SizedBox(height: 16),
          
          _buildToggleSection('Earring', Icons.star, _earringCheck, (value) {
            setState(() {
              _earringCheck = value;
            });
            _setBoolInput('earring_check', _earringCheck);
          }),
          
          const SizedBox(height: 16),
          
          _buildToggleSection('Necklace', Icons.circle, _necklaceCheck, (value) {
            setState(() {
              _necklaceCheck = value;
            });
            _setBoolInput('necklace_check', _necklaceCheck);
          }),
          
          const SizedBox(height: 16),
          
          _buildToggleSection('Glasses', Icons.visibility, _glassCheck, (value) {
            setState(() {
              _glassCheck = value;
            });
            _setBoolInput('glass_check', _glassCheck);
          }),
          
          const SizedBox(height: 16),
          
          _buildToggleSection('Hair', Icons.face, _hairCheck, (value) {
            setState(() {
              _hairCheck = value;
            });
            _setBoolInput('hair_check', _hairCheck);
          }),
        ],
      ),
    );
  }


  Widget _buildCustomizationSection(String title, IconData icon, Color color, Widget content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.isDarkMode(context)
          ? color.withValues(alpha: 0.1)
          : color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.isDarkMode(context)
            ? color.withValues(alpha: 0.3)
            : color.withValues(alpha: 0.2)
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.isDarkMode(context)
                    ? color.withValues(alpha: 0.3)
                    : color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildToggleSection(String title, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.isDarkMode(context)
          ? Colors.grey.withValues(alpha: 0.1)
          : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.isDarkMode(context)
            ? Colors.grey.withValues(alpha: 0.3)
            : Colors.grey.withValues(alpha: 0.2)
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value 
              ? (AppTheme.isDarkMode(context) 
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.green.withValues(alpha: 0.2))
              : (AppTheme.isDarkMode(context)
                  ? Colors.grey.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
            icon, 
            color: value 
              ? (AppTheme.isDarkMode(context) ? Colors.green.shade300 : Colors.green)
              : (AppTheme.isDarkMode(context) ? Colors.grey.shade400 : Colors.grey), 
            size: 20
          ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: value 
                ? (AppTheme.isDarkMode(context) ? Colors.green.shade300 : Colors.green)
                : (AppTheme.isDarkMode(context) ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppTheme.isDarkMode(context)
                  ? Colors.purple.shade300
                  : Colors.purple;
              }
              return null;
            }),
          ),
        ],
      ),
    );
  }
}