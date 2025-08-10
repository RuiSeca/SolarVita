import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/store/avatar_item.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/riverpod/coin_provider.dart';
import '../../../providers/riverpod/avatar_state_provider.dart';
import '../../../utils/translation_helper.dart';
import '../../../services/store/avatar_customization_service.dart';
import 'package:rive/rive.dart' as rive;

class AvatarCard extends ConsumerWidget {
  final AvatarItem item;
  final VoidCallback onTap;

  const AvatarCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for real-time avatar state updates
    final avatarWithState = ref.watch(avatarWithStateProvider(item.id));
    final currentItem = avatarWithState ?? item;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 220, // Make cards taller
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _getBorderColor(currentItem),
            width: currentItem.isEquipped ? 3 : 1,
          ),
          boxShadow: [
            if (currentItem.isNew)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top section with name and buttons
                Container(
                  height: 70, // Increased height to accommodate content
                  padding: const EdgeInsets.all(12), // Reduced padding
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left side - Name and description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentItem.translatedName(context),
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 14, // Slightly smaller
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2), // Reduced spacing
                            Text(
                              currentItem.translatedDescription(context),
                              style: TextStyle(
                                color: AppColors.white.withValues(alpha: 0.7),
                                fontSize: 11, // Slightly smaller
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Right side - Rating/Status
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Rarity stars
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              currentItem.rarity,
                              (index) => Icon(
                                Icons.star,
                                size: 12, // Smaller stars
                                color: _getRarityColor(currentItem),
                              ),
                            ),
                          ),
                          const SizedBox(height: 3), // Reduced spacing
                          // Access type badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), // Smaller padding
                            decoration: BoxDecoration(
                              color: _getAccessTypeColor(currentItem).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10), // Smaller radius
                              border: Border.all(
                                color: _getAccessTypeColor(currentItem).withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              currentItem.accessLabel(context),
                              style: TextStyle(
                                color: _getAccessTypeColor(currentItem),
                                fontSize: 9, // Smaller text
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Large Avatar Preview Space
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: _getPreviewBackgroundColor(currentItem),
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _getPreviewBackgroundColor(currentItem),
                          _getPreviewBackgroundColor(currentItem).withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: Center(
                      child: _buildLargeAvatarPreview(currentItem),
                    ),
                  ),
                ),
                // Bottom section with cost/status
                Container(
                  height: 36, // Slightly reduced height
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Reduced padding
                  child: _buildBottomInfo(context, ref, currentItem),
                ),
              ],
            ),
            // Status overlays
            _buildStatusOverlays(context, ref, currentItem),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeAvatarPreview(AvatarItem currentItem) {
    // Larger avatars for the new layout
    return currentItem.id == 'mummy_coach' 
        ? SizedBox(
            width: 120,
            height: 120,
            child: rive.RiveAnimation.asset(
              'assets/rive/mummy.riv',
              animations: const ['Idle'],
              fit: BoxFit.contain,
            ),
          )
        : currentItem.id == 'quantum_coach'
          ? SizedBox(
              width: 120,
              height: 120,
              child: _QuantumCoachCardPreview(),
            )
          : currentItem.previewImagePath.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  currentItem.previewImagePath,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _getAvatarIcon(currentItem),
                      size: 50,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              )
            : Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Icon(
                  _getAvatarIcon(currentItem),
                  size: 50,
                  color: AppColors.primary,
                ),
              );
  }

  Widget _buildBottomInfo(BuildContext context, WidgetRef ref, AvatarItem currentItem) {
    if (currentItem.isUnlocked && currentItem.isEquipped) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: AppColors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  tr(context, 'status_equipped'),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else if (!currentItem.isUnlocked) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!currentItem.isMemberOnly)
            Row(
              children: [
                Text(
                  currentItem.coinIcon,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 4),
                Text(
                  currentItem.cost.toString(),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  currentItem.coinName(context),
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.withValues(alpha: 0.4)),
              ),
              child: Text(
                tr(context, 'status_member_only'),
                style: const TextStyle(
                  color: Colors.purple,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          // Affordability indicator
          if (!currentItem.isMemberOnly && !_canAfford(ref, currentItem))
            Icon(
              Icons.lock,
              color: Colors.red.withValues(alpha: 0.7),
              size: 16,
            )
          else if (!currentItem.isMemberOnly)
            Icon(
              Icons.shopping_cart,
              color: AppColors.primary,
              size: 16,
            ),
        ],
      );
    }
    return const SizedBox.shrink();
  }


  Widget _buildStatusOverlays(BuildContext context, WidgetRef ref, AvatarItem currentItem) {
    return Stack(
      children: [
        // NEW badge
        if (currentItem.isNew)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tr(context, 'status_new'),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        // Member-only overlay
        if (currentItem.isMemberOnly && !currentItem.isUnlocked)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock,
                      color: AppColors.primary,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr(context, 'status_member_only'),
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // Insufficient coins overlay
        if (!currentItem.isUnlocked && !currentItem.isMemberOnly && !_canAfford(ref, currentItem))
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Icon(
                  Icons.remove_circle_outline,
                  color: Colors.red.withValues(alpha: 0.8),
                  size: 32,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _getBorderColor(AvatarItem currentItem) {
    if (currentItem.isEquipped) return AppColors.primary;
    if (currentItem.isNew) return AppColors.primary.withValues(alpha: 0.6);
    return AppColors.white.withValues(alpha: 0.2);
  }

  Color _getPreviewBackgroundColor(AvatarItem currentItem) {
    switch (currentItem.accessType) {
      case AvatarAccessType.free:
        return Colors.green.withValues(alpha: 0.1);
      case AvatarAccessType.paid:
        return Colors.orange.withValues(alpha: 0.1);
      case AvatarAccessType.member:
        return Colors.purple.withValues(alpha: 0.1);
    }
  }

  Color _getAccessTypeColor(AvatarItem currentItem) {
    switch (currentItem.accessType) {
      case AvatarAccessType.free:
        return Colors.green;
      case AvatarAccessType.paid:
        return Colors.orange;
      case AvatarAccessType.member:
        return Colors.purple;
    }
  }

  Color _getRarityColor(AvatarItem currentItem) {
    switch (currentItem.rarity) {
      case 1:
        return Colors.grey;
      case 2:
        return Colors.green;
      case 3:
        return Colors.blue;
      case 4:
        return Colors.purple;
      case 5:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getAvatarIcon(AvatarItem currentItem) {
    switch (currentItem.category) {
      case AvatarCategory.skins:
        return Icons.person;
      case AvatarCategory.outfits:
        return Icons.checkroom;
      case AvatarCategory.accessories:
        return Icons.watch;
      case AvatarCategory.animations:
        return Icons.play_circle_fill;
    }
  }

  bool _canAfford(WidgetRef ref, AvatarItem currentItem) {
    if (currentItem.isMemberOnly || currentItem.isUnlocked) return true;
    
    return ref.watch(canAffordProvider((currentItem.coinType, currentItem.cost)));
  }
}

class _QuantumCoachCardPreview extends StatefulWidget {
  const _QuantumCoachCardPreview();

  @override
  State<_QuantumCoachCardPreview> createState() => _QuantumCoachCardPreviewState();
}

class _QuantumCoachCardPreviewState extends State<_QuantumCoachCardPreview> {
  rive.StateMachineController? _controller;
  rive.Artboard? _artboard;
  final AvatarCustomizationService _customizationService = AvatarCustomizationService();

  @override
  void initState() {
    super.initState();
    _loadQuantumCoach();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadQuantumCoach() async {
    try {
      await _customizationService.initialize();
      
      final rivFile = await rive.RiveFile.asset('assets/rive/quantum_coach.riv');
      final artboard = rivFile.mainArtboard.instance();
      
      final controller = rive.StateMachineController.fromArtboard(
        artboard,
        'State Machine 1',
      );
      
      if (controller != null) {
        artboard.addController(controller);
        
        // Apply saved customizations
        await _customizationService.applyToRiveInputs('quantum_coach', controller.inputs.toList());
        
        // Force idle animation
        final idleInput = controller.findSMI('Idle');
        if (idleInput is rive.SMITrigger) {
          idleInput.fire();
        }
        
        setState(() {
          _artboard = artboard;
          _controller = controller;
        });
      }
    } catch (e) {
      debugPrint('Error loading Quantum Coach card preview: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_artboard == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.purple,
          strokeWidth: 2,
        ),
      );
    }

    return rive.Rive(
      artboard: _artboard!,
      fit: BoxFit.contain,
    );
  }
}