import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/store/coin_economy.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/riverpod/coin_provider.dart';
import '../../../data/mock_avatar_data.dart';

class CoinHeader extends ConsumerWidget {
  const CoinHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coinBalanceAsync = ref.watch(coinBalanceProvider);
    
    return coinBalanceAsync.when(
      data: (coinBalance) => _buildHeader(context, coinBalance),
      loading: () => _buildLoadingHeader(context),
      error: (error, stackTrace) => _buildErrorHeader(context),
    );
  }

  Widget _buildHeader(BuildContext context, UserCoinBalance coinBalance) {
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
                _buildCoinDisplay(
                  icon: '🔥',
                  label: 'Streak',
                  amount: coinBalance.streakCoins,
                  color: Colors.orange,
                ),
                _buildDivider(),
                _buildCoinDisplay(
                  icon: '⭐',
                  label: 'Points',
                  amount: coinBalance.coachPoints,
                  color: Colors.amber,
                ),
                _buildDivider(),
                _buildCoinDisplay(
                  icon: '💎',
                  label: 'Gems',
                  amount: coinBalance.fitGems,
                  color: AppColors.primary,
                ),
                _buildDivider(),
                _buildAvatarDisplay(),
              ],
            ),
          ),
        ),
        // Stats HUD Section
        _buildStatsHUD(context),
      ],
    );
  }

  Widget _buildLoadingHeader(BuildContext context) {
    return Column(
      children: [
        // Loading Coins Section
        Container(
          margin: const EdgeInsets.fromLTRB(12, 6, 12, 4),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.1),
                AppColors.secondary.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLoadingCoinDisplay('🔥', 'Streak Coins', Colors.orange),
              _buildDivider(),
              _buildLoadingCoinDisplay('⭐', 'Coach Points', Colors.yellow),
              _buildDivider(),
              _buildLoadingCoinDisplay('💎', 'Fit Gems', AppColors.primary),
            ],
          ),
        ),
        // Loading Stats Section
        Container(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(
                  4,
                  (index) => Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.red.withValues(alpha: 0.1),
            Colors.red.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Failed to load coin balance',
            style: TextStyle(
              color: Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinDisplay({
    required String icon,
    required String label,
    required int amount,
    required Color color,
  }) {
    return Flexible(
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(
                  fontSize: 24,
                ),
              ),
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
      ),
    );
  }

  Widget _buildAvatarDisplay() {
    // Get unlocked avatars count
    final avatars = MockAvatarData.getAvatarItems();
    final unlockedCount = avatars.where((avatar) => avatar.isUnlocked).length;
    
    return Flexible(
      child: Column(
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
            'Avatars',
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.6),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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

  Widget _buildLoadingCoinDisplay(String icon, String label, Color color) {
    return Flexible(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: color.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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

  Widget _buildStatsHUD(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        // Mock data for now - replace with actual providers
        final mockStats = _getMockUserStats();
        
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.1),
                AppColors.secondary.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Level and XP Progress
                Row(
                  children: [
                    _buildHUDItem(
                      icon: '🎯',
                      label: 'Level',
                      value: mockStats['level'].toString(),
                      color: AppColors.primary,
                      flex: 2,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 5,
                      child: _buildXPProgress(
                        currentXP: mockStats['currentXP'],
                        nextLevelXP: mockStats['nextLevelXP'],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Stats Grid
                Row(
                  children: [
                    _buildHUDItem(
                      icon: '💪',
                      label: 'Workouts',
                      value: mockStats['totalWorkouts'].toString(),
                      color: Colors.green,
                    ),
                    _buildHUDItem(
                      icon: '🏆',
                      label: 'Win Rate',
                      value: '${mockStats['winRate']}%',
                      color: Colors.amber,
                    ),
                    _buildHUDItem(
                      icon: '🔥',
                      label: 'Streak',
                      value: '${mockStats['currentStreak']}d',
                      color: Colors.orange,
                    ),
                    _buildHUDItem(
                      icon: '⏱️',
                      label: 'Avg Time',
                      value: '${mockStats['avgWorkoutTime']}m',
                      color: Colors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Membership Status
                _buildMembershipStatus(mockStats['membershipType']),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHUDItem({
    required String icon,
    required String label,
    required String value,
    required Color color,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildXPProgress({required int currentXP, required int nextLevelXP}) {
    final progress = currentXP / nextLevelXP;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'XP Progress',
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$currentXP / $nextLevelXP',
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primary.withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMembershipStatus(String membershipType) {
    final isMember = membershipType != 'free';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: isMember
            ? LinearGradient(
                colors: [Colors.purple.withValues(alpha: 0.2), Colors.pink.withValues(alpha: 0.2)],
              )
            : null,
        color: isMember ? null : AppColors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMember
              ? Colors.purple.withValues(alpha: 0.3)
              : AppColors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMember ? Icons.workspace_premium : Icons.person,
            color: isMember ? Colors.purple : AppColors.white.withValues(alpha: 0.6),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            isMember ? membershipType.toUpperCase() : 'FREE MEMBER',
            style: TextStyle(
              color: isMember ? Colors.purple : AppColors.white.withValues(alpha: 0.6),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getMockUserStats() {
    // Replace with actual data providers
    return {
      'level': 12,
      'currentXP': 2840,
      'nextLevelXP': 3500,
      'totalWorkouts': 127,
      'winRate': 87,
      'currentStreak': 15,
      'avgWorkoutTime': 42,
      'membershipType': 'premium', // 'free', 'premium', 'vip'
    };
  }
}