import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/firebase/firebase_avatar.dart';
import '../../../models/firebase/localized_firebase_avatar.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/avatar_display.dart';
import '../../../config/avatar_animations_config.dart';

class FirebaseAvatarCard extends ConsumerWidget {
  final FirebaseAvatar avatar;
  final UserAvatarOwnership? ownership;
  final VoidCallback? onTap;

  const FirebaseAvatarCard({
    super.key,
    required this.avatar,
    this.ownership,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwned = ownership != null;
    final isEquipped = ownership?.isEquipped ?? false;
    
    // Get localized avatar data
    final localizedAvatar = context.getLocalizedAvatar(ref, avatar);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getRarityColor(avatar.rarity).withValues(
                alpha: AppTheme.isDarkMode(context) ? 0.15 : 0.1
              ),
              _getRarityColor(avatar.rarity).withValues(
                alpha: AppTheme.isDarkMode(context) ? 0.08 : 0.05
              ),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isEquipped 
              ? AppColors.primary.withValues(alpha: 0.6)
              : _getRarityColor(avatar.rarity).withValues(
                  alpha: AppTheme.isDarkMode(context) ? 0.4 : 0.3
                ),
            width: isEquipped ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _getRarityColor(avatar.rarity).withValues(
                alpha: AppTheme.isDarkMode(context) ? 0.3 : 0.2
              ),
              blurRadius: isEquipped ? 15 : 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with rarity badge and equipped status
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildRarityBadge(),
                  if (isEquipped) _buildEquippedBadge(),
                  if (isOwned && !isEquipped) _buildOwnedBadge(),
                ],
              ),
            ),
            
            // Avatar preview
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.8,
                    colors: [
                      _getRarityColor(avatar.rarity).withValues(
                        alpha: AppTheme.isDarkMode(context) ? 0.15 : 0.1
                      ),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: AvatarDisplay(
                      avatarId: avatar.avatarId,
                      width: 100,
                      height: 100,
                      initialStage: AnimationStage.idle,
                      autoPlaySequence: avatar.avatarId != 'quantum_coach' && avatar.avatarId != 'director_coach', // Disable sequences for problematic avatars
                      sequenceDelay: const Duration(seconds: 5), // Longer delay to reduce conflicts
                      fit: BoxFit.contain,
                      useCustomizations: false, // Use basic version in store to avoid cache conflicts
                    ),
                  ),
                ),
              ),
            ),
            
            // Avatar info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizedAvatar?.displayName ?? avatar.name,
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      localizedAvatar?.displayDescription ?? avatar.description,
                      style: TextStyle(
                        color: AppTheme.textColor(context).withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    _buildPriceOrStatus(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRarityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getRarityColor(avatar.rarity).withValues(alpha: 0.2),
            _getRarityColor(avatar.rarity).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getRarityColor(avatar.rarity).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Text(
        _getRarityDisplayName(avatar.rarity),
        style: TextStyle(
          color: _getRarityColor(avatar.rarity),
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildEquippedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.2),
            AppColors.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            color: AppColors.primary,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            'EQUIPPED',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withValues(alpha: 0.2),
            Colors.green.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: Colors.green,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            'OWNED',
            style: TextStyle(
              color: Colors.green,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceOrStatus() {
    final isOwned = ownership != null;
    final isEquipped = ownership?.isEquipped ?? false;
    
    if (isEquipped) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              color: AppColors.white,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              'EQUIPPED',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
    }
    
    if (isOwned) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.withValues(alpha: 0.8),
              Colors.green.withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.touch_app_rounded,
              color: AppColors.white,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              'TAP TO EQUIP',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
    }
    
    // Not owned - show price or requirements
    if (avatar.price == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.withValues(alpha: 0.8),
              Colors.blue.withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.download_rounded,
              color: AppColors.white,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              'FREE',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.8),
            AppColors.gold.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.monetization_on,
            color: AppColors.white,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            '${avatar.price}',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return Colors.grey;
      case 'rare':
        return Colors.blue;
      case 'epic':
        return Colors.purple;
      case 'legendary':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getRarityDisplayName(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return 'COMMON';
      case 'rare':
        return 'RARE';
      case 'epic':
        return 'EPIC';
      case 'legendary':
        return 'LEGENDARY';
      default:
        return rarity.toUpperCase();
    }
  }
}