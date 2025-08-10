import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/store/avatar_item.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/riverpod/coin_provider.dart';
import '../../../providers/riverpod/avatar_state_provider.dart';
import '../../../utils/translation_helper.dart';
import '../enhanced_quantum_coach_screen.dart';
import '../../../services/store/avatar_customization_service.dart';
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
    // Watch for real-time avatar state updates
    final avatarWithState = ref.watch(avatarWithStateProvider(widget.item.id));
    final currentItem = avatarWithState ?? widget.item;

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
                _buildHeader(currentItem),
                Expanded(child: _buildPreviewArea()),
                _buildActionArea(currentItem),
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

  Widget _buildHeader(AvatarItem currentItem) {
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
                      currentItem.translatedName(context),
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (currentItem.isNew)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tr(context, 'status_new'),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (currentItem.isEquipped)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tr(context, 'status_equipped'),
                          style: const TextStyle(
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
                  currentItem.translatedDescription(context),
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
                        currentItem.rarity,
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
                        currentItem.accessLabel(context),
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
          // Animation toggle buttons (enhanced for Quantum Coach)
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardDark.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: widget.item.id == 'quantum_coach'
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAnimationButton('Idle'),
                    _buildAnimationButton('Customization'),
                  ],
                )
              : const SizedBox.shrink(), // No animation buttons for other avatars
          ),
          // Avatar preview - Rive animation for Mummy Coach and Quantum Coach
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
                : widget.item.id == 'quantum_coach'
                ? _currentAnimation == 'Customization'
                  ? Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purple.withValues(alpha: 0.2), Colors.blue.withValues(alpha: 0.2)],
                        ),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: Colors.purple.withValues(alpha: 0.5),
                          width: 3,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _openQuantumCoachCustomization(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.tune,
                              size: 60,
                              color: Colors.purple,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Open Studio',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Full Customization',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        children: [
                          _buildCustomizedQuantumCoach(),
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
          // Current mode indicator
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.item.id == 'quantum_coach'
                ? _currentAnimation == 'Customization'
                  ? 'Mode: Tap to open Customization Studio'
                  : 'Mode: Basic Idle Animation'
                : _currentAnimation == 'Celebration' 
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

  Widget _buildActionArea(AvatarItem currentItem) {
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
          // Cost or status info with enhanced Quantum Coach features
          if (!currentItem.isUnlocked)
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
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tr(context, 'action_cost'),
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.8),
                          fontSize: 16,
                        ),
                      ),
                      if (!currentItem.isMemberOnly)
                        Row(
                          children: [
                            Text(
                              currentItem.coinIcon,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              currentItem.cost.toString(),
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              currentItem.coinName(context),
                              style: TextStyle(
                                color: AppColors.white.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          tr(context, 'status_member_only'),
                          style: TextStyle(
                            color: Colors.purple,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  if (currentItem.id == 'quantum_coach') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.purple, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Includes 153+ animations & full customization studio',
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            )
          else if (currentItem.id == 'quantum_coach')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.withValues(alpha: 0.2), Colors.blue.withValues(alpha: 0.2)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.purple.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology, color: Colors.purple, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Quantum Coach Features',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.tune, color: Colors.blue, size: 14),
                      const SizedBox(width: 6),
                      Text('153+ animations & customizations', 
                        style: TextStyle(color: AppColors.white.withValues(alpha: 0.8), fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.palette, color: Colors.purple, size: 14),
                      const SizedBox(width: 6),
                      Text('Advanced clothing, accessories & facial features', 
                        style: TextStyle(color: AppColors.white.withValues(alpha: 0.8), fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          // Action buttons
          Row(
            children: [
              if (currentItem.isUnlocked && !currentItem.isEquipped)
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _equipItem(currentItem),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                      : Text(
                          tr(context, 'action_equip'),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  ),
                )
              else if (currentItem.isEquipped)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      tr(context, 'action_equipped'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else if (currentItem.isMemberOnly)
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
                    child: Text(
                      tr(context, 'action_join_to_unlock'),
                      style: const TextStyle(
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
                    onPressed: _canAfford(currentItem) && !_isLoading ? () => _purchaseItem(currentItem) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canAfford(currentItem) && !_isLoading ? AppColors.primary : Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                      : Text(
                          _canAfford(currentItem) ? tr(context, 'actions_buy') : tr(context, 'action_insufficient_coins'),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  ),
                ),
              const SizedBox(width: 12),
              // Customize button for Quantum Coach (if unlocked)
              if (currentItem.id == 'quantum_coach' && currentItem.isUnlocked)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple, Colors.blue],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: IconButton(
                    onPressed: () => _openQuantumCoachCustomization(),
                    icon: const Icon(
                      Icons.tune,
                      color: AppColors.white,
                    ),
                    tooltip: 'Customize Quantum Coach',
                  ),
                ),
              if (currentItem.id == 'quantum_coach' && currentItem.isUnlocked)
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
                  onPressed: () => _shareItem(currentItem),
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

  bool _canAfford(AvatarItem item) {
    if (item.isMemberOnly || item.isUnlocked) return true;
    
    return ref.watch(canAffordProvider((item.coinType, item.cost)));
  }

  void _equipItem(AvatarItem item) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final result = await ref.read(avatarStateProvider.notifier).equipAvatar(item.id);
      
      if (mounted) {
        if (result.success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to equip avatar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _purchaseItem(AvatarItem item) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final result = await ref.read(avatarStateProvider.notifier).purchaseAvatar(item);
      
      if (mounted) {
        if (result.success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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

  void _openQuantumCoachCustomization() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EnhancedQuantumCoachScreen(),
      ),
    );
  }

  void _shareItem(AvatarItem item) {
    // Handle share logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Shared ${item.name}!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildCustomizedQuantumCoach() {
    return FutureBuilder<rive.Artboard?>(
      future: _loadQuantumCoachWithCustomizations(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return rive.Rive(
            artboard: snapshot.data!,
            fit: BoxFit.contain,
          );
        }
        return rive.RiveAnimation.asset(
          'assets/rive/quantum_coach.riv',
          animations: const ['Idle'],
          fit: BoxFit.contain,
        );
      },
    );
  }

  Future<rive.Artboard?> _loadQuantumCoachWithCustomizations() async {
    try {
      final customizationService = AvatarCustomizationService();
      await customizationService.initialize();
      
      final rivFile = await rive.RiveFile.asset('assets/rive/quantum_coach.riv');
      final artboard = rivFile.mainArtboard.instance();
      
      final controller = rive.StateMachineController.fromArtboard(
        artboard,
        'State Machine 1',
      );
      
      if (controller != null) {
        artboard.addController(controller);
        
        // Apply saved customizations
        await customizationService.applyToRiveInputs('quantum_coach', controller.inputs.toList());
        
        // Ensure idle animation is running
        final idleInput = controller.findSMI('Idle');
        if (idleInput is rive.SMITrigger) {
          idleInput.fire();
        }
        
        return artboard;
      }
    } catch (e) {
      debugPrint('Error loading customized Quantum Coach: $e');
    }
    return null;
  }

}