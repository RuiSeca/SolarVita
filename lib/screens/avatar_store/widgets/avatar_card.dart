import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/store/avatar_item.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/riverpod/coin_provider.dart';
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getBorderColor(),
            width: item.isEquipped ? 3 : 1,
          ),
          boxShadow: [
            if (item.isNew)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar Preview
                Expanded(
                  flex: 2,
                  child: _buildAvatarPreview(),
                ),
                // Item Info
                Expanded(
                  flex: 3,
                  child: _buildItemInfo(),
                ),
              ],
            ),
            // Status badges and overlays
            _buildStatusOverlays(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPreview() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getPreviewBackgroundColor(),
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getPreviewBackgroundColor(),
            _getPreviewBackgroundColor().withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Avatar preview - Rive animation for Mummy Coach, image for others
          Center(
            child: item.id == 'mummy_coach' 
              ? SizedBox(
                  width: 80,
                  height: 80,
                  child: rive.RiveAnimation.asset(
                    'assets/rive/mummy.riv',
                    animations: const ['Idle'], // Idle animation for preview
                    fit: BoxFit.contain,
                  ),
                )
              : item.previewImagePath.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      item.previewImagePath,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          _getAvatarIcon(),
                          size: 32,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _getAvatarIcon(),
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
          ),
          // Rarity stars
          if (item.rarity > 1)
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  item.rarity,
                  (index) => Icon(
                    Icons.star,
                    size: 12,
                    color: _getRarityColor(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemInfo() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          Text(
            item.name,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // Access type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getAccessTypeColor().withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getAccessTypeColor().withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Text(
              item.accessLabel,
              style: TextStyle(
                color: _getAccessTypeColor(),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          // Cost or status
          if (!item.isUnlocked && !item.isMemberOnly)
            Row(
              children: [
                Text(
                  item.coinIcon,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 4),
                Text(
                  item.cost.toString(),
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          else if (item.isEquipped)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'EQUIPPED',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else if (item.isUnlocked)
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 16,
            ),
        ],
      ),
    );
  }

  Widget _buildStatusOverlays(WidgetRef ref) {
    return Stack(
      children: [
        // NEW badge
        if (item.isNew)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'NEW',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        // Member-only overlay
        if (item.isMemberOnly && !item.isUnlocked)
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
                      'Member Only',
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
        if (!item.isUnlocked && !item.isMemberOnly && !_canAfford(ref))
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

  Color _getBorderColor() {
    if (item.isEquipped) return AppColors.primary;
    if (item.isNew) return AppColors.primary.withValues(alpha: 0.6);
    return AppColors.white.withValues(alpha: 0.2);
  }

  Color _getPreviewBackgroundColor() {
    switch (item.accessType) {
      case AvatarAccessType.free:
        return Colors.green.withValues(alpha: 0.1);
      case AvatarAccessType.paid:
        return Colors.orange.withValues(alpha: 0.1);
      case AvatarAccessType.member:
        return Colors.purple.withValues(alpha: 0.1);
    }
  }

  Color _getAccessTypeColor() {
    switch (item.accessType) {
      case AvatarAccessType.free:
        return Colors.green;
      case AvatarAccessType.paid:
        return Colors.orange;
      case AvatarAccessType.member:
        return Colors.purple;
    }
  }

  Color _getRarityColor() {
    switch (item.rarity) {
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

  IconData _getAvatarIcon() {
    switch (item.category) {
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

  bool _canAfford(WidgetRef ref) {
    if (item.isMemberOnly || item.isUnlocked) return true;
    
    return ref.watch(canAffordProvider((item.coinType, item.cost)));
  }
}