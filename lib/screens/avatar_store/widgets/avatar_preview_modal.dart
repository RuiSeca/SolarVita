import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/store/avatar_item.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/riverpod/coin_provider.dart';
import 'package:rive/rive.dart' as rive;

class AvatarPreviewModal extends ConsumerStatefulWidget {
  final AvatarItem item;

  const AvatarPreviewModal({
    super.key,
    required this.item,
  });

  @override
  ConsumerState<AvatarPreviewModal> createState() => _AvatarPreviewModalState();
}

class _AvatarPreviewModalState extends ConsumerState<AvatarPreviewModal> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  String _currentAnimation = 'Idle';
  String _currentCelebrationAnimation = 'Run'; // For celebration mode
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                _buildHandle(),
                _buildHeader(),
                Expanded(child: _buildPreviewArea()),
                _buildActionArea(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.item.name,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (widget.item.isNew)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.item.description,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                // Rarity and category
                Row(
                  children: [
                    Row(
                      children: List.generate(
                        widget.item.rarity,
                        (index) => Icon(
                          Icons.star,
                          size: 16,
                          color: _getRarityColor(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getAccessTypeColor().withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getAccessTypeColor().withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.item.accessLabel,
                        style: TextStyle(
                          color: _getAccessTypeColor(),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: AppColors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewArea() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getPreviewBackgroundColor(),
            _getPreviewBackgroundColor().withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Animation toggle buttons
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardDark.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAnimationButton('Idle'),
                _buildAnimationButton('Celebration'),
                if (widget.item.category == AvatarCategory.animations)
                  _buildAnimationButton('Special'),
              ],
            ),
          ),
          // Avatar preview - Rive animation for Mummy Coach
          Expanded(
            child: Center(
              child: widget.item.id == 'mummy_coach'
                ? SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      children: [
                        rive.RiveAnimation.asset(
                          'assets/rive/mummy.riv',
                          animations: [_getCurrentRiveAnimation()],
                          fit: BoxFit.contain,
                        ),
                        if (_isLoading)
                          Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        width: 3,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            _getAvatarIcon(),
                            size: 80,
                            color: AppColors.primary,
                          ),
                        ),
                        if (_isLoading)
                          Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
            ),
          ),
          // Celebration animation buttons (only for mummy coach in celebration mode)
          if (widget.item.id == 'mummy_coach' && _currentAnimation == 'Celebration')
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cardDark.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCelebrationButton('Run'),
                  _buildCelebrationButton('Attack'),
                  _buildCelebrationButton('Jump'),
                ],
              ),
            ),
          // Current animation indicator
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _currentAnimation == 'Celebration' 
                ? 'Animation: $_currentCelebrationAnimation'
                : 'Animation: $_currentAnimation',
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.7),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimationButton(String animation) {
    final isSelected = _currentAnimation == animation;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentAnimation = animation;
          _isLoading = true;
        });
        // Simulate loading animation
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          animation,
          style: TextStyle(
            color: isSelected ? AppColors.white : AppColors.white.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildActionArea() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Cost or status info
          if (!widget.item.isUnlocked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cost',
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.8),
                      fontSize: 16,
                    ),
                  ),
                  if (!widget.item.isMemberOnly)
                    Row(
                      children: [
                        Text(
                          widget.item.coinIcon,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.item.cost.toString(),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.item.coinName,
                          style: TextStyle(
                            color: AppColors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'Member Only',
                      style: TextStyle(
                        color: Colors.purple,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          // Action buttons
          Row(
            children: [
              if (widget.item.isUnlocked && !widget.item.isEquipped)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _equipItem(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Equip',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else if (widget.item.isEquipped)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Equipped',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else if (widget.item.isMemberOnly)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showMembershipUpgrade(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Join to Unlock',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ElevatedButton(
                    onPressed: _canAfford() ? () => _purchaseItem() : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canAfford() ? AppColors.primary : Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _canAfford() ? 'Buy' : 'Insufficient Coins',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              // Share button
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  onPressed: () => _shareItem(),
                  icon: const Icon(
                    Icons.share,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getCurrentRiveAnimation() {
    if (_currentAnimation == 'Celebration') {
      return _currentCelebrationAnimation;
    }
    return _currentAnimation;
  }

  Widget _buildCelebrationButton(String animation) {
    final isSelected = _currentCelebrationAnimation == animation;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentCelebrationAnimation = animation;
          _isLoading = true;
        });
        // Simulate loading animation
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          animation,
          style: TextStyle(
            color: isSelected ? AppColors.white : AppColors.white.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Color _getRarityColor() {
    switch (widget.item.rarity) {
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

  Color _getAccessTypeColor() {
    switch (widget.item.accessType) {
      case AvatarAccessType.free:
        return Colors.green;
      case AvatarAccessType.paid:
        return Colors.orange;
      case AvatarAccessType.member:
        return Colors.purple;
    }
  }

  Color _getPreviewBackgroundColor() {
    switch (widget.item.accessType) {
      case AvatarAccessType.free:
        return Colors.green.withValues(alpha: 0.1);
      case AvatarAccessType.paid:
        return Colors.orange.withValues(alpha: 0.1);
      case AvatarAccessType.member:
        return Colors.purple.withValues(alpha: 0.1);
    }
  }

  IconData _getAvatarIcon() {
    switch (widget.item.category) {
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

  bool _canAfford() {
    if (widget.item.isMemberOnly || widget.item.isUnlocked) return true;
    
    return ref.watch(canAffordProvider((widget.item.coinType, widget.item.cost)));
  }

  void _equipItem() {
    // Handle equip logic
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.item.name} equipped!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _purchaseItem() async {
    try {
      // Attempt to spend coins
      final success = await ref.read(coinBalanceProvider.notifier).spendCoins(
        widget.item.coinType, 
        widget.item.cost, 
        widget.item.name,
      );
      
      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.item.name} purchased! 🎉'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Insufficient ${widget.item.coinName}! 💸'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed! Please try again. ⚠️'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showMembershipUpgrade() {
    // Show membership upgrade modal
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Membership upgrade required!'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  void _shareItem() {
    // Handle share logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Shared ${widget.item.name}!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}