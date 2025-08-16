import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/firebase/firebase_avatar.dart';
import '../../../models/firebase/localized_firebase_avatar.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';
import '../../../widgets/avatar_display.dart';
import '../../../config/avatar_animations_config.dart';
import '../../../providers/firebase/firebase_avatar_provider.dart';
import '../../../models/store/currency_system.dart';
import '../../../providers/store/currency_provider.dart';
import '../avatar_studio_screen.dart';

class FirebaseAvatarPreviewModal extends ConsumerStatefulWidget {
  final FirebaseAvatar avatar;
  final UserAvatarOwnership? ownership;

  const FirebaseAvatarPreviewModal({
    super.key,
    required this.avatar,
    this.ownership,
  });

  @override
  ConsumerState<FirebaseAvatarPreviewModal> createState() => _FirebaseAvatarPreviewModalState();
}

class _FirebaseAvatarPreviewModalState extends ConsumerState<FirebaseAvatarPreviewModal>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Helper methods to get localized avatar data
  String _getLocalizedName(BuildContext context) {
    final localizedAvatar = context.getLocalizedAvatar(ref, widget.avatar);
    return localizedAvatar?.displayName ?? widget.avatar.name;
  }
  
  String _getLocalizedDescription(BuildContext context) {
    final localizedAvatar = context.getLocalizedAvatar(ref, widget.avatar);
    return localizedAvatar?.displayDescription ?? widget.avatar.description;
  }

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
        ),
        child: SlideTransition(
          position: _slideAnimation,
          child: DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.darkSurface,
                      AppColors.darkSurface.withValues(alpha: 0.95),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(
                    color: _getRarityColor(widget.avatar.rarity).withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      _buildAvatarPreview(),
                      _buildAvatarInfo(),
                      _buildAnimationsList(),
                      if (widget.avatar.customProperties['hasCustomization'] == true)
                        _buildCustomizations(),
                      _buildActionButtons(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isEquipped = widget.ownership?.isEquipped ?? false;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getRarityColor(widget.avatar.rarity).withValues(alpha: 0.1),
            _getRarityColor(widget.avatar.rarity).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.white,
                size: 18,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _getLocalizedName(context),
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (isEquipped)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: AppColors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'EQUIPPED',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getRarityColor(widget.avatar.rarity).withValues(alpha: 0.2),
                            _getRarityColor(widget.avatar.rarity).withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _getRarityColor(widget.avatar.rarity).withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _getRarityDisplayName(widget.avatar.rarity),
                        style: TextStyle(
                          color: _getRarityColor(widget.avatar.rarity),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (widget.avatar.price > 0)
                      Row(
                        children: [
                          Icon(
                            Icons.monetization_on,
                            color: AppColors.gold,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.avatar.price}',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'FREE',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPreview() {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.8,
          colors: [
            _getRarityColor(widget.avatar.rarity).withValues(alpha: 0.15),
            _getRarityColor(widget.avatar.rarity).withValues(alpha: 0.05),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getRarityColor(widget.avatar.rarity).withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Center(
        child: SizedBox(
          width: 150,
          height: 150,
          child: AvatarDisplay(
            avatarId: widget.avatar.avatarId,
            width: 150,
            height: 150,
            initialStage: AnimationStage.idle,
            autoPlaySequence: true,
            sequenceDelay: const Duration(seconds: 3),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'about_avatar'),
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _getLocalizedDescription(context),
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.8),
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAnimationsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'available_animations'),
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.avatar.availableAnimations.map((animation) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.2),
                      AppColors.secondary.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  animation,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCustomizations() {
    final customizationTypes = widget.avatar.customProperties['customizationTypes'] as List<dynamic>? ?? [];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'customization_options'),
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: customizationTypes.map<Widget>((type) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.withValues(alpha: 0.2),
                      Colors.purple.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.purple.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  type.toString().toUpperCase(),
                  style: TextStyle(
                    color: Colors.purple,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    // Check real-time ownership status instead of relying on widget.ownership
    final ownerships = ref.watch(userAvatarOwnershipsProvider);
    
    return ownerships.when(
      data: (ownershipList) {
        final ownership = ownershipList.cast<UserAvatarOwnership?>().firstWhere(
          (o) => o?.avatarId == widget.avatar.avatarId,
          orElse: () => null,
        );
        
        final isOwned = ownership != null;
        final isEquipped = ownership?.isEquipped ?? false;
        
        debugPrint('🎭 DEBUG: Action buttons - Avatar: ${widget.avatar.avatarId}, Owned: $isOwned, Equipped: $isEquipped');
        
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              if (isEquipped) ...[
                // Already equipped - show customize button if available
                if (widget.avatar.customProperties['hasCustomization'] == true)
                  _buildCustomizeButton(ownership),
              ] else if (isOwned) ...[
                // Owned but not equipped - show equip button
                _buildEquipButton(),
              ] else ...[
                // Not owned - show purchase/unlock button
                _buildPurchaseButton(),
              ],
              
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // For free avatars, show action buttons even when ownership is loading
            if (widget.avatar.price == 0) ...[
              // Check if this free avatar is currently equipped
              () {
                final equippedAvatar = ref.watch(equippedAvatarProvider);
                final isCurrentlyEquipped = equippedAvatar?.avatarId == widget.avatar.avatarId;
                
                if (isCurrentlyEquipped && widget.avatar.customProperties['hasCustomization'] == true) {
                  // Show customize button if equipped and has customization
                  return _buildCustomizeButton(widget.ownership);
                } else {
                  // Show equip button 
                  return _buildEquipButton();
                }
              }(),
            ] else ...[
              // For paid avatars, show loading spinner
              Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ],
          ],
        ),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Error loading ownership data',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            // For free avatars, show equip button even on error
            if (widget.avatar.price == 0)
              _buildEquipButton()
            else
              _buildPurchaseButton(), // Fallback to purchase button on error
          ],
        ),
      ),
    );
  }

  Widget _buildEquipButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleEquipAvatar,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: AppColors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tr(context, 'equip_avatar'),
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPurchaseButton() {
    // Get price and check affordability
    final price = StorePricing.getAvatarPrice(widget.avatar.avatarId);
    final currency = ref.watch(userCurrencyProvider);
    
    final canAfford = currency.when(
      data: (userCurrency) => userCurrency?.canAffordMixed(price) ?? false,
      loading: () => false,
      error: (_, __) => false,
    );
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.avatar.price == 0
                ? [Colors.green, Colors.green.shade700]
                : canAfford
                    ? [AppColors.gold, AppColors.gold.withValues(alpha: 0.8)]
                    : [Colors.grey, Colors.grey.shade700],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (widget.avatar.price == 0 ? Colors.green : AppColors.gold)
                  .withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading || !canAfford ? null : _handlePurchaseAvatar,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.avatar.price == 0
                          ? Icons.download_rounded
                          : Icons.shopping_cart_rounded,
                      color: AppColors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.avatar.price == 0
                          ? tr(context, 'unlock_free')
                          : '${tr(context, 'purchase_for')} ${widget.avatar.price}',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCustomizeButton(UserAvatarOwnership? ownership) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple, Colors.purple.shade700],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ElevatedButton(
          onPressed: () => _handleCustomizeAvatar(ownership),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.palette_rounded,
                color: AppColors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                tr(context, 'customize_avatar'),
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleEquipAvatar() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final equipmentService = ref.read(avatarEquipmentProvider);
      await equipmentService.equipAvatar(widget.avatar.avatarId);
      
      // For equipping, we don't need to invalidate cache since we're just changing which avatar is active
      // The equipped avatar state will be updated by the providers automatically
      debugPrint('✅ Avatar equipped successfully: ${widget.avatar.avatarId}');
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getLocalizedName(context)} equipped successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePurchaseAvatar() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final purchaseService = ref.read(avatarPurchaseProvider);
      final success = await purchaseService.purchaseAvatar(
        widget.avatar.avatarId,
        metadata: {
          'purchaseSource': 'store_preview',
          'pricePaid': widget.avatar.price,
        },
      );
      
      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getLocalizedName(context)} purchased successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Purchase failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleCustomizeAvatar([UserAvatarOwnership? ownership]) {
    debugPrint('🎨 DEBUG: Customize tapped - Avatar: ${widget.avatar.avatarId}, Ownership: ${ownership?.avatarId}');
    
    // Navigate to universal avatar studio
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AvatarStudioScreen(
          avatar: widget.avatar,
          isOwned: ownership != null,
        ),
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