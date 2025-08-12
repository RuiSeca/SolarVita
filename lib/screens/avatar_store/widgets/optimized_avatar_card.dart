import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/firebase/firebase_avatar.dart';
import '../../../models/store/currency_system.dart';
import '../../../theme/app_theme.dart';
import '../../../services/assets/asset_cache_service.dart';
import '../../../providers/store/currency_provider.dart';

class OptimizedAvatarCard extends ConsumerStatefulWidget {
  final FirebaseAvatar avatar;
  final UserAvatarOwnership? ownership;
  final VoidCallback? onTap;
  final bool showLoadingOverlay;

  const OptimizedAvatarCard({
    super.key,
    required this.avatar,
    this.ownership,
    this.onTap,
    this.showLoadingOverlay = false,
  });

  @override
  ConsumerState<OptimizedAvatarCard> createState() => _OptimizedAvatarCardState();
}

class _OptimizedAvatarCardState extends ConsumerState<OptimizedAvatarCard>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;
  bool _isPreviewLoaded = false;
  String? _previewImageUrl;

  @override
  void initState() {
    super.initState();
    
    // Initialize shimmer animation for loading state
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.linear,
    ));
    
    _shimmerController.repeat();
    _loadPreviewImage();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  /// Load static preview image using asset cache service
  Future<void> _loadPreviewImage() async {
    try {
      // Try to get from asset cache service
      final assetCacheService = AssetCacheService();
      final cachedAsset = await assetCacheService.getAvatarPreview(widget.avatar.avatarId);
      
      if (mounted) {
        setState(() {
          _isPreviewLoaded = true;
          _previewImageUrl = cachedAsset.localPath;
        });
        _shimmerController.stop();
      }
    } catch (e) {
      // Fallback to bundled asset or placeholder
      if (mounted) {
        setState(() {
          _isPreviewLoaded = true;
          _previewImageUrl = null; // Will show fallback
        });
        _shimmerController.stop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEquipped = widget.ownership?.isEquipped ?? false;
    final currency = ref.watch(userCurrencyProvider);
    
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getRarityColor(widget.avatar.rarity).withValues(alpha: 0.15),
              _getRarityColor(widget.avatar.rarity).withValues(alpha: 0.05),
              Colors.transparent,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEquipped 
              ? AppColors.primary.withValues(alpha: 0.8)
              : _getRarityColor(widget.avatar.rarity).withValues(alpha: 0.4),
            width: isEquipped ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _getRarityColor(widget.avatar.rarity).withValues(alpha: 0.2),
              blurRadius: isEquipped ? 20 : 12,
              offset: const Offset(0, 6),
            ),
            if (isEquipped)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
          ],
        ),
        child: Stack(
          children: [
            // Main card content
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with badges
                _buildHeader(),
                
                // Avatar preview image
                Expanded(
                  flex: 3,
                  child: _buildAvatarPreview(),
                ),
                
                // Avatar info
                Expanded(
                  flex: 2,
                  child: _buildAvatarInfo(currency),
                ),
              ],
            ),
            
            // Loading overlay
            if (widget.showLoadingOverlay)
              _buildLoadingOverlay(),
              
            // Rarity glow effect
            if (widget.avatar.rarity == 'legendary')
              _buildLegendaryGlow(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isEquipped = widget.ownership?.isEquipped ?? false;
    final isOwned = widget.ownership != null;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Rarity badge
          _buildRarityBadge(),
          
          // Status badges
          Row(
            children: [
              if (isEquipped)
                _buildStatusBadge(
                  'EQUIPPED',
                  AppColors.primary,
                  Icons.star_rounded,
                ),
              if (isOwned && !isEquipped)
                _buildStatusBadge(
                  'OWNED',
                  Colors.green,
                  Icons.check_circle_rounded,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRarityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getRarityColor(widget.avatar.rarity).withValues(alpha: 0.3),
            _getRarityColor(widget.avatar.rarity).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getRarityColor(widget.avatar.rarity).withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Text(
        _getRarityDisplayName(widget.avatar.rarity),
        style: TextStyle(
          color: _getRarityColor(widget.avatar.rarity),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(left: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.9,
          colors: [
            _getRarityColor(widget.avatar.rarity).withValues(alpha: 0.1),
            _getRarityColor(widget.avatar.rarity).withValues(alpha: 0.05),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: _buildPreviewImage(),
      ),
    );
  }

  Widget _buildPreviewImage() {
    if (!_isPreviewLoaded) {
      return _buildShimmerPlaceholder();
    }

    // Try to load cached image first
    if (_previewImageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          _previewImageUrl!,
          width: 120,
          height: 120,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildFallbackPreview(),
        ),
      );
    }

    // Try CDN/Firebase Storage with caching
    final previewUrl = 'https://cdn.solarvita.app/avatars/previews/${widget.avatar.avatarId}_preview.webp';
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: previewUrl,
        width: 120,
        height: 120,
        fit: BoxFit.contain,
        placeholder: (context, url) => _buildShimmerPlaceholder(),
        errorWidget: (context, url, error) => _buildFallbackPreview(),
        memCacheWidth: 240, // Optimize memory usage
        memCacheHeight: 240,
      ),
    );
  }

  Widget _buildShimmerPlaceholder() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey.shade300.withValues(alpha: 0.3),
                Colors.grey.shade100.withValues(alpha: 0.3),
                Colors.grey.shade300.withValues(alpha: 0.3),
              ],
              stops: [
                0.0,
                _shimmerAnimation.value,
                1.0,
              ],
            ),
          ),
          child: Icon(
            Icons.person,
            size: 60,
            color: Colors.grey.shade400,
          ),
        );
      },
    );
  }

  Widget _buildFallbackPreview() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getRarityColor(widget.avatar.rarity).withValues(alpha: 0.3),
            _getRarityColor(widget.avatar.rarity).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getRarityColor(widget.avatar.rarity).withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person,
            size: 50,
            color: _getRarityColor(widget.avatar.rarity),
          ),
          const SizedBox(height: 8),
          Text(
            widget.avatar.name.split(' ').first,
            style: TextStyle(
              color: _getRarityColor(widget.avatar.rarity),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarInfo(AsyncValue<UserCurrency?> currency) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar name
          Text(
            widget.avatar.name,
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 4),
          
          // Avatar description
          Text(
            widget.avatar.description,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 12),
          
          // Price/Status section
          _buildPriceSection(currency),
        ],
      ),
    );
  }

  Widget _buildPriceSection(AsyncValue<UserCurrency?> currency) {
    final isOwned = widget.ownership != null;
    final isEquipped = widget.ownership?.isEquipped ?? false;
    final price = StorePricing.getAvatarPrice(widget.avatar.avatarId);
    
    if (isEquipped) {
      return _buildActionButton(
        'EQUIPPED',
        AppColors.primary,
        AppColors.secondary,
        Icons.star_rounded,
        null,
      );
    }
    
    if (isOwned) {
      return _buildActionButton(
        'TAP TO EQUIP',
        Colors.green,
        Colors.green.shade700,
        Icons.touch_app_rounded,
        widget.onTap,
      );
    }
    
    // Not owned - show price
    if (price.isEmpty) {
      return _buildActionButton(
        'FREE',
        Colors.blue,
        Colors.blue.shade700,
        Icons.download_rounded,
        widget.onTap,
      );
    }
    
    // Show price with affordability check
    return currency.when(
      data: (userCurrency) {
        final canAfford = userCurrency?.canAffordMixed(price) ?? false;
        final priceText = _formatPrice(price);
        
        return _buildActionButton(
          priceText,
          canAfford ? AppColors.gold : Colors.grey,
          canAfford ? AppColors.gold.withValues(alpha: 0.8) : Colors.grey.shade700,
          Icons.shopping_cart_rounded,
          canAfford ? widget.onTap : null,
        );
      },
      loading: () => _buildActionButton(
        'LOADING...',
        Colors.grey,
        Colors.grey.shade700,
        Icons.hourglass_empty,
        null,
      ),
      error: (_, __) => _buildActionButton(
        'ERROR',
        Colors.red,
        Colors.red.shade700,
        Icons.error,
        null,
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    Color color1,
    Color color2,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color1, color2]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: onTap != null ? [
          BoxShadow(
            color: color1.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.white, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Processing...',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendaryGlow() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.3 + 0.2 * _shimmerController.value),
                blurRadius: 25,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatPrice(Map<CurrencyType, int> price) {
    final entries = price.entries.toList();
    if (entries.isEmpty) return 'FREE';
    if (entries.length == 1) {
      final entry = entries.first;
      return '${entry.value} ${_getCurrencyIcon(entry.key)}';
    }
    
    // Multiple currencies
    return entries.map((e) => '${e.value}${_getCurrencyIcon(e.key)}').join(' + ');
  }

  String _getCurrencyIcon(CurrencyType type) {
    switch (type) {
      case CurrencyType.coins:
        return '🪙';
      case CurrencyType.points:
        return '⭐';
      case CurrencyType.streak:
        return '🔥';
    }
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
    return rarity.toUpperCase();
  }
}