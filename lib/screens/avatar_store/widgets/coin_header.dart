import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/store/currency_system.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/store/currency_provider.dart';
import '../../../data/mock_avatar_data.dart';
import '../../../utils/translation_helper.dart';
import '../../store/currency_purchase_screen.dart';

class CoinHeader extends ConsumerWidget {
  const CoinHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyAsync = ref.watch(userCurrencyProvider);
    
    return currencyAsync.when(
      data: (currency) => _buildHeader(context, currency),
      loading: () => _buildFallbackHeader(context), // Show fallback instead of loading
      error: (error, stackTrace) => _buildFallbackHeader(context), // Show fallback instead of error
    );
  }

  Widget _buildFallbackHeader(BuildContext context) {
    // Show realistic demo currency data when Firebase is loading/erroring
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(12, 6, 12, 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.white.withValues(alpha: 0.08),
                AppColors.white.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _navigateToCurrencyStore(context),
                    child: _buildCoinDisplay(
                      icon: '🪙',
                      label: tr(context, 'currencies_coins'),
                      amount: 1250, // Demo fallback amount
                      color: AppColors.gold,
                      isMainCurrency: true,
                      isTappable: true,
                    ),
                  ),
                ),
                _buildDivider(),
                Expanded(
                  child: _buildCoinDisplay(
                    icon: '⭐',
                    label: tr(context, 'currencies_points'),
                    amount: 850, // Demo fallback amount
                    color: Colors.amber,
                  ),
                ),
                _buildDivider(),
                Expanded(
                  child: _buildCoinDisplay(
                    icon: '🔥',
                    label: tr(context, 'currencies_streak'),
                    amount: 7, // Demo fallback amount
                    color: Colors.orange,
                  ),
                ),
                _buildDivider(),
                Expanded(child: _buildAvatarDisplay(context)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, UserCurrency? currency) {
    if (currency == null) return _buildFallbackHeader(context);
    return Column(
      children: [
        // Coins Section
        Container(
          margin: const EdgeInsets.fromLTRB(12, 6, 12, 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.white.withValues(alpha: 0.08),
                AppColors.white.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                // Primary spendable currency - coins (tappable to buy more)
                Expanded(
                  child: GestureDetector(
                    onTap: () => _navigateToCurrencyStore(context),
                    child: _buildCoinDisplay(
                      icon: '🪙',
                      label: tr(context, 'currencies_coins'),
                      amount: currency.getBalance(CurrencyType.coins),
                      color: AppColors.gold,
                      isMainCurrency: true,
                      isTappable: true,
                    ),
                  ),
                ),
                _buildDivider(),
                // Activity tracking - points (non-spendable)
                Expanded(
                  child: _buildCoinDisplay(
                    icon: '⭐',
                    label: tr(context, 'currencies_points'),
                    amount: currency.getBalance(CurrencyType.points),
                    color: Colors.amber,
                  ),
                ),
                _buildDivider(),
                // Streak tracking (non-spendable)
                Expanded(
                  child: _buildCoinDisplay(
                    icon: '🔥',
                    label: tr(context, 'currencies_streak'),
                    amount: currency.getBalance(CurrencyType.streak),
                    color: Colors.orange,
                  ),
                ),
                _buildDivider(),
                Expanded(child: _buildAvatarDisplay(context)),
              ],
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildCoinDisplay({
    required String icon,
    required String label,
    required int amount,
    required Color color,
    bool isMainCurrency = false,
    bool isTappable = false,
  }) {
    return Column(
        children: [
          Container(
            width: isMainCurrency ? 42 : 36,
            height: isMainCurrency ? 42 : 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: isMainCurrency ? 0.3 : 0.2),
                  color.withValues(alpha: isMainCurrency ? 0.15 : 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: isMainCurrency ? 0.4 : 0.3),
                width: isMainCurrency ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: isMainCurrency ? 0.3 : 0.2),
                  blurRadius: isMainCurrency ? 12 : 8,
                  offset: Offset(0, isMainCurrency ? 3 : 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    icon,
                    style: const TextStyle(
                      fontSize: 24,
                    ),
                  ),
                ),
                if (isTappable)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatCoinAmount(amount),
            style: TextStyle(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.6),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
    );
  }

  Widget _buildAvatarDisplay(BuildContext context) {
    // Get unlocked avatars count
    final avatars = MockAvatarData.getAvatarItems();
    final unlockedCount = avatars.where((avatar) => avatar.isUnlocked).length;
    
    return Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.withValues(alpha: 0.2),
                  Colors.purple.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.purple.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '🎭',
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            unlockedCount.toString(),
            style: TextStyle(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr(context, 'stats_avatars'),
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.6),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.white.withValues(alpha: 0.0),
            AppColors.white.withValues(alpha: 0.15),
            AppColors.white.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }


  String _formatCoinAmount(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toString();
  }



  /// Navigate to currency purchase screen
  void _navigateToCurrencyStore(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CurrencyPurchaseScreen(),
      ),
    );
  }
}