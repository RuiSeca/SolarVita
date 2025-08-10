import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'scalable_avatar_system.dart';
import 'avatar_interaction_manager.dart';
import 'mummy_avatar_controller.dart';
import 'quantum_coach_controller.dart';
import 'avatar_controller_factory.dart';

final log = Logger('AvatarMigrationBridge');

/// Bridge system that allows new scalable architecture to coexist with old controllers
/// This enables gradual migration without breaking existing functionality
class AvatarMigrationBridge {
  static final AvatarMigrationBridge _instance = AvatarMigrationBridge._internal();
  factory AvatarMigrationBridge() => _instance;
  AvatarMigrationBridge._internal();

  final Map<String, dynamic> _legacyControllers = {};
  final AvatarControllerFactory _factory = AvatarControllerFactory();
  bool _isInitialized = false;

  /// Initialize the bridge system
  Future<void> initialize() async {
    if (_isInitialized) return;

    log.info('🌉 Initializing Avatar Migration Bridge');
    
    // Load configuration
    final configManager = AvatarConfigurationManager();
    await configManager.loadConfiguration();
    
    _isInitialized = true;
    log.info('✅ Avatar Migration Bridge initialized');
  }

  /// Create or get existing legacy controller for avatar
  T? getLegacyController<T>(String avatarId, String avatarType, {Map<String, dynamic>? parameters}) {
    if (_legacyControllers.containsKey(avatarId)) {
      return _legacyControllers[avatarId] as T?;
    }

    log.info('🔗 Creating legacy controller for $avatarId ($avatarType)');

    dynamic controller;
    switch (avatarType) {
      case 'sequential':
      case 'mummy':
        controller = _factory.createMummyController(
          avatarId: avatarId,
          headerAvatarKey: parameters?['headerAvatarKey'],
          largeAvatarKey: parameters?['largeAvatarKey'],
        );
        break;
      
      case 'teleportation':
      case 'quantum_coach':
        controller = _factory.createQuantumCoachController(
          avatarId: avatarId,
        );
        break;
      
      default:
        log.warning('⚠️ Unknown avatar type: $avatarType');
        return null;
    }

    if (controller != null) {
      _legacyControllers[avatarId] = controller;
    }

    return controller as T?;
  }

  /// Remove legacy controller
  void removeLegacyController(String avatarId) {
    if (_legacyControllers.containsKey(avatarId)) {
      log.info('🗑️ Removing legacy controller: $avatarId');
      _factory.removeAvatar(avatarId);
      _legacyControllers.remove(avatarId);
    }
  }

  /// Check if avatar should use legacy system or new system
  bool shouldUseLegacySystem(String avatarId) {
    final configManager = AvatarConfigurationManager();
    final config = configManager.getAvatarConfig(avatarId);
    
    // Use new system if config explicitly sets it, otherwise use legacy
    return config?.customProperties['useLegacySystem'] as bool? ?? true;
  }

  /// Clean up all legacy controllers
  void dispose() {
    log.info('🧹 Disposing Avatar Migration Bridge');
    for (final avatarId in _legacyControllers.keys.toList()) {
      removeLegacyController(avatarId);
    }
    _isInitialized = false;
  }
}

/// Enhanced UniversalAvatarWidget that can work with legacy controllers
class BridgedAvatarWidget extends StatefulWidget {
  final String avatarId;
  final String screenId;
  final Map<String, dynamic> overrideProperties;
  final Map<String, dynamic>? legacyParameters;

  const BridgedAvatarWidget({
    super.key,
    required this.avatarId,
    required this.screenId,
    this.overrideProperties = const {},
    this.legacyParameters,
  });

  @override
  State<BridgedAvatarWidget> createState() => _BridgedAvatarWidgetState();
}

class _BridgedAvatarWidgetState extends State<BridgedAvatarWidget> {
  final AvatarMigrationBridge _bridge = AvatarMigrationBridge();
  AvatarConfig? _config;
  dynamic _legacyController;

  @override
  void initState() {
    super.initState();
    _initializeAvatar();
  }

  void _initializeAvatar() {
    final configManager = AvatarConfigurationManager();
    _config = configManager.getAvatarConfig(widget.avatarId);

    if (_config == null) {
      log.warning('⚠️ No configuration found for avatar: ${widget.avatarId}');
      return;
    }

    // Check if should use legacy system
    if (_bridge.shouldUseLegacySystem(widget.avatarId)) {
      log.info('🔄 Using legacy system for ${widget.avatarId}');
      _legacyController = _bridge.getLegacyController(
        widget.avatarId,
        _config!.type,
        parameters: widget.legacyParameters,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_config == null) {
      return const SizedBox.shrink();
    }

    // Get positioning for this screen
    final positioning = _config!.positioning[widget.screenId] as Map<String, dynamic>?;
    if (positioning == null) {
      return const SizedBox.shrink();
    }

    final coordinates = positioning['coordinates'] as Map<String, dynamic>;
    final width = (coordinates['width'] as num).toDouble();
    final height = (coordinates['height'] as num).toDouble();

    // Use legacy controller if available
    if (_legacyController != null) {
      return _buildLegacyAvatarWidget(width, height);
    }

    // Use new system
    return _buildNewAvatarWidget(width, height);
  }

  Widget _buildLegacyAvatarWidget(double width, double height) {
    if (_legacyController is MummyAvatarController) {
      final controller = _legacyController as MummyAvatarController;
      return ValueListenableBuilder<bool>(
        valueListenable: controller.showLargeAvatar,
        builder: (context, showLargeAvatar, child) {
          if (showLargeAvatar) {
            return const SizedBox.shrink(); // Large avatar handled elsewhere
          }
          
          return Container(
            width: width,
            height: height,
            child: GestureDetector(
              onTap: () => controller.handleInteraction(AvatarInteractionType.singleTap),
              child: _buildAvatarVisual(),
            ),
          );
        },
      );
    }
    
    if (_legacyController is QuantumCoachController) {
      final controller = _legacyController as QuantumCoachController;
      return ValueListenableBuilder<CoachLocation>(
        valueListenable: controller.currentLocation,
        builder: (context, location, child) {
          return ValueListenableBuilder<bool>(
            valueListenable: controller.isVisible,
            builder: (context, isVisible, child) {
              // Map screen ID to CoachLocation
              CoachLocation expectedLocation = CoachLocation.aiScreen;
              switch (widget.screenId) {
                case 'meal_plan':
                  expectedLocation = CoachLocation.mealPlan;
                  break;
                case 'workout_tips':
                  expectedLocation = CoachLocation.workoutTips;
                  break;
                case 'eco_stats':
                  expectedLocation = CoachLocation.ecoStats;
                  break;
              }

              if (location == expectedLocation && isVisible) {
                return Container(
                  width: width,
                  height: height,
                  child: GestureDetector(
                    onTap: () => controller.handleInteraction(AvatarInteractionType.singleTap),
                    child: _buildAvatarVisual(),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildNewAvatarWidget(double width, double height) {
    return Container(
      width: width,
      height: height,
      child: GestureDetector(
        onTap: () => _handleNewSystemInteraction(),
        child: _buildAvatarVisual(),
      ),
    );
  }

  Widget _buildAvatarVisual() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.purple.withValues(alpha: 0.1),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getAvatarIcon(),
              color: Colors.purple,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              _config!.name,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAvatarIcon() {
    switch (_config!.type) {
      case 'sequential':
        return Icons.psychology;
      case 'teleportation':
        return Icons.flash_on;
      default:
        return Icons.smart_toy;
    }
  }

  void _handleNewSystemInteraction() {
    log.info('🆕 New system interaction for ${widget.avatarId}');
    // New system interaction handling
  }

  @override
  void dispose() {
    // Don't dispose legacy controllers here - they're managed by the bridge
    super.dispose();
  }
}

/// Enhanced AvatarScreenManager that works with the bridge system
class BridgedAvatarScreenManager extends StatefulWidget {
  final String screenId;
  final Widget child;
  final Map<String, dynamic>? legacyParameters;

  const BridgedAvatarScreenManager({
    super.key,
    required this.screenId,
    required this.child,
    this.legacyParameters,
  });

  @override
  State<BridgedAvatarScreenManager> createState() => _BridgedAvatarScreenManagerState();
}

class _BridgedAvatarScreenManagerState extends State<BridgedAvatarScreenManager> {
  final AvatarMigrationBridge _bridge = AvatarMigrationBridge();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeBridge();
  }

  Future<void> _initializeBridge() async {
    await _bridge.initialize();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return widget.child;
    }

    final configManager = AvatarConfigurationManager();

    return ValueListenableBuilder<bool>(
      valueListenable: configManager.isLoaded,
      builder: (context, isLoaded, child) {
        if (!isLoaded) {
          return widget.child;
        }

        final avatars = configManager.getAvatarsForScreen(widget.screenId);
        final layout = configManager.getLayoutForScreen(widget.screenId);

        return Stack(
          children: [
            widget.child,
            ...avatars.map((avatar) => _buildPositionedAvatar(avatar, layout)),
          ],
        );
      },
    );
  }

  Widget _buildPositionedAvatar(AvatarConfig avatar, AvatarLayoutConfig? layout) {
    // Find placement for this avatar
    final placement = layout?.placements
        .where((p) => p.avatarId == avatar.id)
        .firstOrNull;

    if (placement == null) return const SizedBox.shrink();

    final coords = placement.coordinates;
    final x = coords['x'] ?? 0;
    final y = coords['y'] ?? 0;
    final anchor = coords['anchor'] as String?;

    Widget avatarWidget = BridgedAvatarWidget(
      avatarId: avatar.id,
      screenId: widget.screenId,
      legacyParameters: widget.legacyParameters,
    );

    // Position based on anchor
    return Positioned(
      top: anchor?.contains('bottom') == true ? null : y,
      bottom: anchor?.contains('bottom') == true ? y.abs() : null,
      left: anchor?.contains('right') == true ? null : (x >= 0 ? x : null),
      right: anchor?.contains('right') == true ? x.abs() : null,
      child: avatarWidget,
    );
  }

  @override
  void dispose() {
    _bridge.dispose();
    super.dispose();
  }
}