import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/firebase/firebase_avatar.dart';
import '../../widgets/enhanced_avatar_customization.dart';
import '../../widgets/avatar_customization.dart';
import '../../services/store/avatar_customization_service.dart' as store_service;
import '../../models/store/quantum_coach_config.dart';
import '../../providers/firebase/firebase_avatar_provider.dart';
import '../../theme/app_theme.dart';

/// Universal Avatar Studio Screen
/// Scalable customization system that works with any avatar
class AvatarStudioScreen extends ConsumerStatefulWidget {
  final FirebaseAvatar avatar;
  final bool isOwned;

  const AvatarStudioScreen({
    super.key,
    required this.avatar,
    required this.isOwned,
  });

  @override
  ConsumerState<AvatarStudioScreen> createState() => _AvatarStudioScreenState();
}

class _AvatarStudioScreenState extends ConsumerState<AvatarStudioScreen>
    with TickerProviderStateMixin {
  final store_service.AvatarCustomizationService _customizationService = store_service.AvatarCustomizationService();
  
  late AnimationController _headerAnimationController;
  late AnimationController _contentAnimationController;
  
  bool _isLoading = false;
  AvatarConfig? _avatarConfig;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeService();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _contentAnimationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _contentAnimationController.forward();
    });
  }

  Future<void> _initializeService() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _customizationService.initialize();
      _avatarConfig = _generateAvatarConfig(widget.avatar);
    } catch (e) {
      debugPrint('Error initializing avatar studio: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Generate avatar configuration based on avatar properties
  AvatarConfig _generateAvatarConfig(FirebaseAvatar avatar) {
    final customProps = avatar.customProperties;
    
    return AvatarConfig(
      avatarId: avatar.avatarId,
      name: avatar.name,
      description: avatar.description,
      rarity: avatar.rarity,
      hasCustomization: customProps['hasCustomization'] == true,
      customizationTypes: List<String>.from(customProps['customizationTypes'] ?? []),
      features: _extractFeatures(customProps),
      themeColors: _getThemeColors(avatar.rarity),
      supportedAnimations: avatar.availableAnimations,
    );
  }

  /// Extract avatar features from custom properties
  List<AvatarFeature> _extractFeatures(Map<String, dynamic> customProps) {
    final features = <AvatarFeature>[];
    
    // For Quantum Coach and Director Coach, use the detailed configuration (both use same config)
    if (widget.avatar.avatarId == 'quantum_coach' || widget.avatar.avatarId == 'director_coach') {
      features.addAll([
        AvatarFeature(
          type: 'Eyes',
          icon: Icons.visibility,
          emoji: '👁️',
          description: '${QuantumCoachConfig.eyeOptions.length} Eye Options',
        ),
        AvatarFeature(
          type: 'Face',
          icon: Icons.face,
          emoji: '😊',
          description: '${QuantumCoachConfig.faceOptions.length} Face Expressions',
        ),
        AvatarFeature(
          type: 'Skin',
          icon: Icons.palette,
          emoji: '🎨',
          description: '${QuantumCoachConfig.skinOptions.length} Skin Tones',
        ),
        AvatarFeature(
          type: 'Clothing',
          icon: Icons.checkroom,
          emoji: '👕',
          description: '${QuantumCoachConfig.clothingItems.length} Clothing Items',
        ),
        AvatarFeature(
          type: 'Accessories',
          icon: Icons.diamond,
          emoji: '💎',
          description: '${QuantumCoachConfig.accessoryItems.length} Accessories',
        ),
        AvatarFeature(
          type: 'Interactive',
          icon: Icons.touch_app,
          emoji: '👆',
          description: '${QuantumCoachConfig.interactiveActions.length} Touch Actions',
        ),
        AvatarFeature(
          type: 'States',
          icon: Icons.settings,
          emoji: '⚙️',
          description: '${QuantumCoachConfig.stateControls.length} State Controls',
        ),
      ]);
    } else {
      // For other avatars, use generic customization types
      final customizationTypes = List<String>.from(customProps['customizationTypes'] ?? []);
      
      for (final type in customizationTypes) {
        switch (type.toLowerCase()) {
          case 'eyes':
            features.add(AvatarFeature(
              type: 'Eyes',
              icon: Icons.visibility,
              emoji: '👁️',
              description: 'Customize eye color and effects',
            ));
            break;
          case 'face':
            features.add(AvatarFeature(
              type: 'Face',
              icon: Icons.face,
              emoji: '😊',
              description: 'Customize facial features and expressions',
            ));
            break;
          case 'skin':
            features.add(AvatarFeature(
              type: 'Skin',
              icon: Icons.palette,
              emoji: '🎨',
              description: 'Change skin tone and texture',
            ));
            break;
          case 'clothing':
            features.add(AvatarFeature(
              type: 'Clothing',
              icon: Icons.checkroom,
              emoji: '👕',
              description: 'Toggle outfits and accessories',
            ));
            break;
          case 'hair':
            features.add(AvatarFeature(
              type: 'Hair',
              icon: Icons.face_retouching_natural,
              emoji: '💇',
              description: 'Modify hairstyle options',
            ));
            break;
          case 'accessories':
            features.add(AvatarFeature(
              type: 'Accessories',
              icon: Icons.diamond,
              emoji: '💎',
              description: 'Add jewelry and extras',
            ));
            break;
        }
      }
    }

    // Add general features
    if (customProps['hasComplexSequence'] == true) {
      features.add(AvatarFeature(
        type: 'Animations',
        icon: Icons.animation,
        emoji: '🎭',
        description: 'Advanced animation sequences',
      ));
    }

    if (customProps['supportsTeleport'] == true) {
      features.add(AvatarFeature(
        type: 'Teleport',
        icon: Icons.flash_on,
        emoji: '⚡',
        description: 'Teleportation abilities',
      ));
    }

    return features;
  }

  /// Get theme colors based on rarity
  List<Color> _getThemeColors(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'legendary':
        return [Colors.purple.shade800, Colors.blue.shade900];
      case 'epic':
        return [Colors.deepOrange.shade800, Colors.red.shade700];
      case 'rare':
        return [Colors.blue.shade700, Colors.indigo.shade800];
      default:
        return [Colors.grey.shade700, Colors.blueGrey.shade800];
    }
  }

  Future<void> _resetCustomizations() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildResetDialog(),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _customizationService.resetCustomizations(widget.avatar.avatarId);

        if (mounted) {
          _showSuccessMessage('All customizations reset to defaults!');
        }
      } catch (e) {
        if (mounted) {
          _showErrorMessage('Error resetting: $e');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _obtainFreeAvatar() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get the Firebase avatar service
      final avatarService = ref.read(firebaseAvatarServiceProvider);
      
      // Create ownership record for free avatar using purchase method (will be free since price = 0)
      await avatarService.purchaseAvatar(widget.avatar.avatarId, metadata: {'obtainType': 'free_claim'});
      
      if (mounted) {
        _showSuccessMessage('${widget.avatar.name} obtained successfully!');
        
        // Refresh the screen by popping and pushing back, or trigger a rebuild
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Error obtaining avatar: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🏪 DEBUG: AvatarStudioScreen.build() - Avatar: ${widget.avatar.avatarId}, Owned: ${widget.isOwned}');
    
    if (_avatarConfig == null || _isLoading) {
      return _buildLoadingScreen();
    }

    // Check real-time ownership status from Firebase instead of relying on passed parameter
    final ownerships = ref.watch(userAvatarOwnershipsProvider);
    final isReallyOwned = ownerships.when(
      data: (ownershipList) => ownershipList.any((o) => o.avatarId == widget.avatar.avatarId),
      loading: () => widget.isOwned, // Fallback to passed parameter while loading
      error: (_, __) => widget.isOwned, // Fallback to passed parameter on error
    );

    debugPrint('🏪 DEBUG: Real-time ownership check: $isReallyOwned (Passed: ${widget.isOwned})');

    if (!isReallyOwned) {
      debugPrint('🚫 DEBUG: Avatar not owned (real-time check), showing purchase screen');
      return _buildPurchaseRequiredScreen();
    }

    if (!_avatarConfig!.hasCustomization) {
      debugPrint('🚫 DEBUG: Avatar has no customization, showing info screen');
      return _buildNoCustomizationScreen();
    }

    debugPrint('✅ DEBUG: Showing customization screen for ${widget.avatar.avatarId}');
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: CustomScrollView(
        slivers: [
          _buildAnimatedAppBar(),
          SliverToBoxAdapter(child: _buildFeatureHighlights()),
          SliverToBoxAdapter(child: _buildCustomizationWidget()),
          SliverToBoxAdapter(child: _buildStatusFooter()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: Center(
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
              'Loading ${widget.avatar.name} Studio...',
              style: TextStyle(
                color: AppTheme.textColor(context).withValues(alpha: 0.7)
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseRequiredScreen() {
    final isFree = widget.avatar.price == 0;
    
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textColor(context),
        title: Text('${widget.avatar.name} Studio'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _avatarConfig?.themeColors ?? [Colors.grey, Colors.blueGrey],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isFree ? Icons.card_giftcard : Icons.lock, 
                  size: 40, 
                  color: Colors.white
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isFree ? 'Get for Free!' : 'Purchase Required',
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isFree 
                  ? 'Claim ${widget.avatar.name} for free to access its customization studio!'
                  : 'You need to own ${widget.avatar.name} to access its customization studio.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textColor(context).withValues(alpha: 0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              if (isFree) ...[
                ElevatedButton(
                  onPressed: _obtainFreeAvatar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.isDarkMode(context) 
                      ? Colors.green.shade400
                      : Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Obtain for Free', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 12),
              ],
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.isDarkMode(context)
                    ? Colors.purple.shade400
                    : Colors.purple,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Back to Store', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoCustomizationScreen() {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textColor(context),
        title: Text('${widget.avatar.name} Studio'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _avatarConfig!.themeColors,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.brush_outlined, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text(
                'No Customization Available',
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${widget.avatar.name} doesn\'t support customization at this time.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textColor(context).withValues(alpha: 0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.isDarkMode(context)
                    ? Colors.purple.shade400
                    : Colors.purple,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Back to Store', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      foregroundColor: AppTheme.textColor(context),
      flexibleSpace: FlexibleSpaceBar(
        background: AnimatedBuilder(
          animation: _headerAnimationController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _avatarConfig!.themeColors.map((color) => 
                    color.withValues(alpha: 0.9 * _headerAnimationController.value)
                  ).toList() + [
                    Colors.black.withValues(alpha: 0.7 * _headerAnimationController.value),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - _headerAnimationController.value)),
                    child: Opacity(
                      opacity: _headerAnimationController.value,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: _avatarConfig!.themeColors),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: _avatarConfig!.themeColors.first.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              _getRarityIcon(_avatarConfig!.rarity),
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${_avatarConfig!.name} Studio',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Advanced ${_avatarConfig!.rarity.toUpperCase()} Customization',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        IconButton(
          onPressed: _resetCustomizations,
          icon: const Icon(Icons.refresh),
          tooltip: 'Reset All Customizations',
        ),
      ],
    );
  }

  Widget _buildFeatureHighlights() {
    return AnimatedBuilder(
      animation: _contentAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _contentAnimationController.value)),
          child: Opacity(
            opacity: _contentAnimationController.value,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _avatarConfig!.themeColors.map((color) => 
                    color.withValues(alpha: 0.3)
                  ).toList(),
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _avatarConfig!.themeColors.first.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Available Features',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _avatarConfig!.features.map((feature) => 
                      _buildFeatureChip(feature)
                    ).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomizationWidget() {
    return AnimatedBuilder(
      animation: _contentAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 40 * (1 - _contentAnimationController.value)),
          child: Opacity(
            opacity: _contentAnimationController.value,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _getCustomizationWidgetForAvatar(),
            ),
          ),
        );
      },
    );
  }

  Widget _getCustomizationWidgetForAvatar() {
    // For Quantum Coach and Director Coach, use the enhanced customization widget
    if (widget.avatar.avatarId == 'quantum_coach' || widget.avatar.avatarId == 'director_coach') {
      return EnhancedAvatarCustomization(
        avatarId: widget.avatar.avatarId, // Pass the avatarId parameter
        width: MediaQuery.of(context).size.width - 32,
        height: 300,
        showActionsTab: false, // Disabled - caused freezing issues
        showStatesTab: false,  // Disabled - caused freezing issues
        enableAutoSave: true,
        onCustomizationChanged: () {
          // Customization changes are auto-saved with debouncing
        },
      );
    } else {
      // For other avatars, use the generic avatar customization widget
      return AvatarCustomization(
        avatarId: widget.avatar.avatarId,
        width: MediaQuery.of(context).size.width - 32,
        height: 300,
        onCustomizationChanged: () {
          // Customization changes are auto-saved
        },
      );
    }
  }

  Widget _buildStatusFooter() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Studio Ready',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Auto-save enabled • ${_avatarConfig!.supportedAnimations.length} animations • ${_avatarConfig!.features.length} features',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildFeatureChip(AvatarFeature feature) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        '${feature.emoji} ${feature.type}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildResetDialog() {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.refresh, color: Colors.orange),
          const SizedBox(width: 12),
          const Text('Reset All Customizations'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This will reset all customizations for ${_avatarConfig!.name} to default values:'),
          const SizedBox(height: 12),
          ..._avatarConfig!.features.map((feature) => 
            _buildResetItem(feature.emoji, '${feature.type} → Default')
          ),
          const SizedBox(height: 12),
          const Text(
            'This action cannot be undone.',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Reset All'),
        ),
      ],
    );
  }

  Widget _buildResetItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  IconData _getRarityIcon(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'legendary':
        return Icons.psychology;
      case 'epic':
        return Icons.whatshot;
      case 'rare':
        return Icons.star;
      default:
        return Icons.person;
    }
  }
}

/// Avatar configuration model
class AvatarConfig {
  final String avatarId;
  final String name;
  final String description;
  final String rarity;
  final bool hasCustomization;
  final List<String> customizationTypes;
  final List<AvatarFeature> features;
  final List<Color> themeColors;
  final List<String> supportedAnimations;

  const AvatarConfig({
    required this.avatarId,
    required this.name,
    required this.description,
    required this.rarity,
    required this.hasCustomization,
    required this.customizationTypes,
    required this.features,
    required this.themeColors,
    required this.supportedAnimations,
  });
}

/// Avatar feature model
class AvatarFeature {
  final String type;
  final IconData icon;
  final String emoji;
  final String description;

  const AvatarFeature({
    required this.type,
    required this.icon,
    required this.emoji,
    required this.description,
  });
}