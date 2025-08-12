import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'scalable_avatar_system.dart';
import 'universal_avatar_controller.dart';
import 'quantum_coach_controller.dart';
import 'avatar_controller_factory.dart';
import 'avatar_interaction_manager.dart';
import '../../widgets/avatar_display.dart';
import '../../providers/riverpod/avatar_state_provider.dart';

final log = Logger('SmartAvatarManager');

/// Modern avatar management system for production use
/// Replaces the bridge pattern with a clean, unified approach
class SmartAvatarManager extends ConsumerStatefulWidget {
  final String screenId;
  final Widget child;
  final Map<String, dynamic>? legacyParameters;

  const SmartAvatarManager({
    super.key,
    required this.screenId,
    required this.child,
    this.legacyParameters,
  });

  @override
  ConsumerState<SmartAvatarManager> createState() => _SmartAvatarManagerState();
}

class _SmartAvatarManagerState extends ConsumerState<SmartAvatarManager> {
  final AvatarConfigurationManager _configManager = AvatarConfigurationManager();
  UniversalAvatarController? _universalController;
  QuantumCoachController? _quantumCoachController;
  bool _isInitialized = false;
  String? _currentEquippedAvatarId;

  @override
  void initState() {
    super.initState();
    _initializeAvatars();
  }

  Future<void> _initializeAvatars() async {
    try {
      log.info('🚀 Initializing SmartAvatarManager for screen: ${widget.screenId}');

      // Initialize configuration manager if needed
      try {
        await _configManager.loadConfiguration();
      } catch (configError) {
        log.warning('⚠️ Config loading failed, using defaults: $configError');
        // Continue with defaults
      }

      // Initialize controllers based on screen and legacy parameters
      await _setupControllers();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }

      log.info('✅ SmartAvatarManager initialized successfully');
    } catch (e, stackTrace) {
      log.severe('❌ Failed to initialize SmartAvatarManager: $e', e, stackTrace);
      
      // Initialize anyway with basic functionality
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  Future<void> _setupControllers() async {
    final factory = AvatarControllerFactory();
    
    // For AI screen, create universal controller for any equipped avatar
    if (widget.screenId == 'ai_screen') {
      log.info('🎯 AI screen detected - checking equipped avatar');
      
      // Get equipped avatar from store, with multiple fallbacks
      final avatarState = ref.read(avatarStateProvider).valueOrNull;
      String equippedAvatarId = avatarState?.equippedAvatarId ?? 'mummy_coach';
      
      // If the equipped avatar doesn't exist, try fallbacks
      if (avatarState?.equippedAvatarId == null) {
        // Try common avatar IDs as fallbacks
        final fallbackAvatars = ['mummy_coach', 'quantum_coach', 'default_avatar'];
        bool foundAvatar = false;
        
        for (final fallbackId in fallbackAvatars) {
          // For now, use the first fallback - could check availability later
          equippedAvatarId = fallbackId;
          foundAvatar = true;
          break;
        }
        
        if (!foundAvatar) {
          log.warning('⚠️ No avatars available, using default placeholder');
          equippedAvatarId = 'placeholder_avatar';
        }
      }
      _currentEquippedAvatarId = equippedAvatarId;
      
      // Get the avatar keys from legacy parameters
      final headerKey = widget.legacyParameters?['headerAvatarKey'] as GlobalKey<AvatarDisplayState>?;
      final largeKey = widget.legacyParameters?['largeAvatarKey'] as GlobalKey<AvatarDisplayState>?;
      
      log.info('🎯 Equipped avatar: $equippedAvatarId');
      log.info('🎯 Avatar keys - Header: ${headerKey != null}, Large: ${largeKey != null}');
      
      // Add a small delay to ensure controllers are fully registered
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Clean up any existing controllers before creating new ones
      if (_universalController != null) {
        factory.removeAvatar('${equippedAvatarId}_ai_screen');
        _universalController = null;
      }
      if (_quantumCoachController != null) {
        factory.removeAvatar('quantum_coach_logic_only');
        _quantumCoachController = null;
      }
      
      // For quantum coach, create BOTH controllers but only ONE visual avatar:
      // 1. Universal controller for Stage 0 teleportation + ALL avatar display (same as all avatars)
      // 2. Quantum controller for card teleportation LOGIC ONLY (no visual avatar)
      if (equippedAvatarId == 'quantum_coach') {
        // Universal controller handles ALL avatar display and Stage 0 (idle → jump → teleport)
        _universalController = factory.createUniversalController(
          avatarId: '${equippedAvatarId}_ai_screen',
          avatarType: equippedAvatarId,
          headerAvatarKey: headerKey,
          largeAvatarKey: largeKey,
        );
        
        // Quantum controller handles card teleportation LOGIC ONLY (no visual)
        _quantumCoachController = factory.createQuantumCoachController(
          avatarId: 'quantum_coach_logic_only',
        );
        
        log.info('🌌 Created BOTH controllers for quantum coach:');
        log.info('  - Universal controller: Stage 0 teleportation + ALL avatar display');
        log.info('  - Quantum controller: Card teleportation logic ONLY (no visual)');
      } else {
        // For all other avatars, only use universal controller
        _universalController = factory.createUniversalController(
          avatarId: '${equippedAvatarId}_ai_screen',
          avatarType: equippedAvatarId,
          headerAvatarKey: headerKey,
          largeAvatarKey: largeKey,
        );
        log.info('🎯 Universal controller created for $equippedAvatarId');
      }
      
      return;
    }

    // Setup Universal Avatar for other screens if legacy parameters provided
    if (widget.legacyParameters != null) {
      final headerKey = widget.legacyParameters!['headerAvatarKey'] as GlobalKey<AvatarDisplayState>?;
      final largeKey = widget.legacyParameters!['largeAvatarKey'] as GlobalKey<AvatarDisplayState>?;

      if (headerKey != null || largeKey != null) {
        // Use mummy as default for legacy screens
        _universalController = factory.createUniversalController(
          avatarId: 'mummy_${widget.screenId}',
          avatarType: 'mummy_coach',
          headerAvatarKey: headerKey,
          largeAvatarKey: largeKey,
        );
        log.info('🎯 Universal controller initialized for ${widget.screenId}');
      }
    }
  }

  @override
  void dispose() {
    log.info('🧹 Disposing SmartAvatarManager for ${widget.screenId}');
    
    final factory = AvatarControllerFactory();
    
    if (_universalController != null) {
      if (widget.screenId == 'ai_screen' && _currentEquippedAvatarId != null) {
        factory.removeAvatar('${_currentEquippedAvatarId}_ai_screen');
      } else {
        factory.removeAvatar('mummy_${widget.screenId}');
      }
    }

    if (_quantumCoachController != null) {
      factory.removeAvatar('quantum_coach_logic_only');
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return widget.child; // Show content while loading
    }

    // Check if equipped avatar has changed and update controllers if needed
    if (widget.screenId == 'ai_screen') {
      final avatarState = ref.watch(avatarStateProvider).valueOrNull;
      final equippedAvatarId = avatarState?.equippedAvatarId ?? 'mummy_coach';
      
      if (_currentEquippedAvatarId != equippedAvatarId) {
        _currentEquippedAvatarId = equippedAvatarId;
        // Update controllers asynchronously to avoid rebuilding during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _setupControllers();
        });
      }
    }

    // For all screens, add avatar overlays
    return Stack(
      children: [
        // Main content
        widget.child,

        // Modern avatar overlays with error protection
        ..._buildAvatarOverlays(),
      ],
    );
  }

  List<Widget> _buildAvatarOverlays() {
    final overlays = <Widget>[];

    try {
      // Add Universal Avatar overlays (for Stage 0 teleportation - all avatars including quantum)
      if (_universalController != null) {
        try {
          overlays.addAll(_buildUniversalAvatarOverlays());
        } catch (e) {
          log.warning('⚠️ Error building universal avatar overlays: $e');
        }
      }

      // NOTE: Quantum Coach overlay is DISABLED to prevent double avatar issue
      // The universal controller handles all avatar display for quantum coach
      // The quantum controller only handles teleportation logic without visual avatar
      // if (_quantumCoachController != null && widget.screenId == 'ai_screen') {
      //   try {
      //     overlays.add(_buildQuantumCoachOverlay());
      //   } catch (e) {
      //     log.warning('⚠️ Error building quantum coach overlay: $e');
      //   }
      // }

      // Add configuration-driven avatars
      try {
        overlays.addAll(_buildConfiguredAvatars());
      } catch (e) {
        log.warning('⚠️ Error building configured avatars: $e');
      }
    } catch (e, stackTrace) {
      log.severe('❌ Error in _buildAvatarOverlays: $e', e, stackTrace);
    }

    return overlays;
  }

  List<Widget> _buildUniversalAvatarOverlays() {
    final overlays = <Widget>[];

    // NOTE: Header avatar is handled by the screen itself to avoid GlobalKey conflicts
    // We only handle the large avatar overlay here

    // Create a GlobalKey for the large avatar if not provided
    final largeAvatarKey = _universalController!.largeAvatarKey ?? GlobalKey<AvatarDisplayState>();

    // Large avatar overlay
    overlays.add(
      ValueListenableBuilder<bool>(
        valueListenable: _universalController!.showLargeAvatar,
        builder: (context, showLarge, child) {
          return AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            top: showLarge ? 120 : -200,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: showLarge ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: () => _universalController!.handleInteraction(AvatarInteractionType.singleTap),
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: _buildSafeLargeAvatarDisplay(
                        key: largeAvatarKey,
                        avatarId: _universalController!.avatarTypeString,
                        width: 120,
                        height: 120,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    // Update the controller with the key if it was created here
    if (_universalController!.largeAvatarKey == null) {
      _universalController = AvatarControllerFactory().createUniversalController(
        avatarId: _universalController!.avatarId,
        avatarType: _universalController!.avatarTypeString,
        headerAvatarKey: _universalController!.headerAvatarKey,
        largeAvatarKey: largeAvatarKey,
      );
    }

    return overlays;
  }

  Widget _buildSafeLargeAvatarDisplay({
    required GlobalKey<AvatarDisplayState> key,
    required String avatarId,
    required double width,
    required double height,
  }) {
    try {
      return AvatarDisplay(
        key: key,
        avatarId: avatarId,
        width: width,
        height: height,
        autoPlaySequence: false, // Controller handles animation manually
        fit: BoxFit.contain,
      );
    } catch (e) {
      log.warning('⚠️ Error creating Large AvatarDisplay: $e');
      // Fallback to a simple container
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.purple.withValues(alpha: 0.3),
          border: Border.all(color: Colors.purple.withValues(alpha: 0.7), width: 3),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, color: Colors.purple, size: width * 0.4),
            Text(
              avatarId,
              style: TextStyle(color: Colors.purple, fontSize: width * 0.08),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }

  List<Widget> _buildConfiguredAvatars() {
    // In this hybrid approach, JSON provides positioning data
    // while Dart controllers handle the actual avatar logic
    // This gives us the best of both worlds:
    // - Easy configuration changes via JSON
    // - Full control over complex interactions via Dart
    
    log.info('📋 Using JSON-enhanced positioning for existing avatars on ${widget.screenId}');
    return []; // Controllers handle the actual widgets with JSON positioning
  }

}

/// Helper extension for easy avatar management
extension SmartAvatarManagerExtension on Widget {
  /// Wrap any screen with smart avatar management
  Widget withSmartAvatars({
    required String screenId,
    Map<String, dynamic>? legacyParameters,
  }) {
    return SmartAvatarManager(
      screenId: screenId,
      legacyParameters: legacyParameters,
      child: this,
    );
  }
}