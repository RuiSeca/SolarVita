import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../../models/store/coin_economy.dart';
import '../../models/store/avatar_item.dart';
import '../../models/user/user_progress.dart';
import '../../services/store/coin_repository.dart';
import 'user_progress_provider.dart';

final log = Logger('CoinProvider');

// Coin repository provider
final coinRepositoryProvider = Provider<CoinRepository>((ref) {
  return CoinRepository();
});

// Main coin balance notifier
class CoinBalanceNotifier extends AsyncNotifier<UserCoinBalance> {
  late CoinRepository _coinRepository;
  StreamSubscription<UserProgress>? _progressSubscription;

  @override
  Future<UserCoinBalance> build() async {
    _coinRepository = ref.read(coinRepositoryProvider);
    
    // Initialize coin balance
    final initialBalance = await _coinRepository.getCoinBalance();
    
    // Listen to user progress changes for automatic coin earning
    _setupProgressListener();
    
    return initialBalance;
  }

  // Set up listener for user progress changes to award coins automatically
  void _setupProgressListener() {
    // Listen to user progress changes
    ref.listen<AsyncValue<UserProgress>>(
      userProgressNotifierProvider,
      (previous, next) {
        // Award coins when progress changes
        next.whenData((newProgress) async {
          if (previous?.hasValue == true) {
            final previousProgress = previous!.requireValue;
            await _checkForCoinRewards(previousProgress, newProgress);
          }
        });
      },
    );
  }

  // Check if user earned coins from progress changes
  Future<void> _checkForCoinRewards(
    UserProgress previousProgress, 
    UserProgress currentProgress,
  ) async {
    try {
      // Award coins for completing goals
      await _awardGoalCompletionCoins(previousProgress, currentProgress);
      
      // Award coins for level ups
      await _awardLevelUpCoins(previousProgress, currentProgress);
      
      // Award coins for streak milestones
      await _awardStreakMilestoneCoins(previousProgress, currentProgress);
      
    } catch (e) {
      log.warning('⚠️ Error checking coin rewards: $e');
    }
  }

  // Award coins for completing daily goals
  Future<void> _awardGoalCompletionCoins(
    UserProgress previousProgress, 
    UserProgress currentProgress,
  ) async {
    final previousCompletedCount = previousProgress.completedGoalsCount;
    final currentCompletedCount = currentProgress.completedGoalsCount;
    
    // Only award if more goals were completed
    if (currentCompletedCount > previousCompletedCount) {
      final newGoalsCompleted = currentCompletedCount - previousCompletedCount;
      final multiplier = currentProgress.todayMultiplier;
      
      // Calculate coins based on goals completed and multiplier
      int streakCoinsToAward = 0;
      int coachPointsToAward = 0;
      
      // Award StreakCoins for each goal completed
      streakCoinsToAward = newGoalsCompleted * 5; // 5 coins per goal
      
      // Award CoachPoints with multiplier bonus
      coachPointsToAward = newGoalsCompleted * multiplier * 3; // 3 points per goal * multiplier
      
      // Perfect day bonus (all 5 goals completed)
      if (currentCompletedCount == 5 && previousCompletedCount < 5) {
        streakCoinsToAward += 25; // Perfect day bonus
        coachPointsToAward += 50;  // Perfect day coach points
        
        // Award FitGems for perfect days
        await _awardCoins(
          CoinType.fitGems, 
          1, 
          CoinEarningReason.perfectDay,
          'Perfect day completed! All goals achieved! 🌟',
        );
      }
      
      if (streakCoinsToAward > 0) {
        await _awardCoins(
          CoinType.streakCoin, 
          streakCoinsToAward, 
          CoinEarningReason.goalCompletion,
          'Completed $newGoalsCompleted daily goal${newGoalsCompleted > 1 ? 's' : ''}! 🎯',
        );
      }
      
      if (coachPointsToAward > 0) {
        await _awardCoins(
          CoinType.coachPoints, 
          coachPointsToAward, 
          CoinEarningReason.goalCompletion,
          'Earned ${multiplier}x multiplier bonus! ⭐',
        );
      }
      
      log.info('🪙 Awarded $streakCoinsToAward StreakCoins + $coachPointsToAward CoachPoints for completing $newGoalsCompleted goals');
    }
  }

  // Award coins for leveling up
  Future<void> _awardLevelUpCoins(
    UserProgress previousProgress, 
    UserProgress currentProgress,
  ) async {
    if (currentProgress.currentLevel > previousProgress.currentLevel) {
      final newLevel = currentProgress.currentLevel;
      
      // Award more coins for higher levels
      final streakCoins = newLevel * 10; // 10 coins per level
      final coachPoints = newLevel * 15; // 15 points per level
      final fitGems = (newLevel / 2).ceil(); // 1 gem every 2 levels
      
      await _awardCoins(
        CoinType.streakCoin, 
        streakCoins, 
        CoinEarningReason.levelUp,
        'Level $newLevel achieved! 🏆',
      );
      
      await _awardCoins(
        CoinType.coachPoints, 
        coachPoints, 
        CoinEarningReason.levelUp,
        'Level $newLevel mastery bonus! ⭐',
      );
      
      await _awardCoins(
        CoinType.fitGems, 
        fitGems, 
        CoinEarningReason.levelUp,
        'Premium level $newLevel reward! 💎',
      );
      
      log.info('🎉 Level up reward: $streakCoins StreakCoins, $coachPoints CoachPoints, $fitGems FitGems');
    }
  }

  // Award coins for streak milestones
  Future<void> _awardStreakMilestoneCoins(
    UserProgress previousProgress, 
    UserProgress currentProgress,
  ) async {
    final previousStreak = previousProgress.dayStreak;
    final currentStreak = currentProgress.dayStreak;
    
    // Award milestone bonuses
    final milestones = [7, 14, 30, 60, 100, 365]; // Weekly, bi-weekly, monthly, etc.
    
    for (final milestone in milestones) {
      if (currentStreak >= milestone && previousStreak < milestone) {
        // Award milestone bonus
        final streakCoins = milestone * 2; // 2 coins per day in streak
        final coachPoints = milestone * 3; // 3 points per day in streak
        final fitGems = (milestone / 10).ceil(); // 1 gem per 10 days
        
        await _awardCoins(
          CoinType.streakCoin, 
          streakCoins, 
          CoinEarningReason.streakMilestone,
          '$milestone day streak achieved! 🔥',
        );
        
        await _awardCoins(
          CoinType.coachPoints, 
          coachPoints, 
          CoinEarningReason.streakMilestone,
          '$milestone day consistency bonus! ⚡',
        );
        
        await _awardCoins(
          CoinType.fitGems, 
          fitGems, 
          CoinEarningReason.streakMilestone,
          '$milestone day mastery gem! 💎',
        );
        
        log.info('🔥 Streak milestone $milestone: $streakCoins StreakCoins, $coachPoints CoachPoints, $fitGems FitGems');
        break; // Only award one milestone at a time
      }
    }
  }

  // Award specific coins
  Future<void> _awardCoins(
    CoinType coinType, 
    int amount, 
    CoinEarningReason reason,
    String message,
  ) async {
    try {
      final updatedBalance = await _coinRepository.awardCoins(coinType, amount, reason, message);
      state = AsyncValue.data(updatedBalance);
      
      // Log transaction
      log.info('💰 Awarded $amount ${coinType.name} for ${reason.name}');
    } catch (e) {
      log.warning('⚠️ Failed to award $amount ${coinType.name}: $e');
    }
  }

  // Spend coins (for purchases)
  Future<bool> spendCoins(CoinType coinType, int amount, String reason) async {
    try {
      final currentBalance = state.valueOrNull;
      if (currentBalance == null) return false;
      
      // Check if user has enough coins
      final currentAmount = currentBalance.getCoinAmount(coinType);
      if (currentAmount < amount) {
        log.warning('⚠️ Insufficient ${coinType.name}: has $currentAmount, needs $amount');
        return false;
      }
      
      final updatedBalance = await _coinRepository.spendCoins(coinType, amount, reason);
      state = AsyncValue.data(updatedBalance);
      
      log.info('💸 Spent $amount ${coinType.name} for: $reason');
      return true;
    } catch (e) {
      log.warning('⚠️ Failed to spend $amount ${coinType.name}: $e');
      return false;
    }
  }

  // Get coin transaction history
  Future<List<CoinTransaction>> getTransactionHistory() async {
    return await _coinRepository.getTransactionHistory();
  }

  // Manual coin award (for testing or admin purposes)
  Future<void> manualAwardCoins(
    CoinType coinType, 
    int amount, 
    String reason,
  ) async {
    await _awardCoins(coinType, amount, CoinEarningReason.manual, reason);
  }

  // Refresh coin balance
  Future<void> refresh() async {
    try {
      state = const AsyncValue.loading();
      final balance = await _coinRepository.getCoinBalance();
      state = AsyncValue.data(balance);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void dispose() {
    _progressSubscription?.cancel();
  }
}

// Main provider instance
final coinBalanceProvider = AsyncNotifierProvider<CoinBalanceNotifier, UserCoinBalance>(
  () => CoinBalanceNotifier(),
);

// Convenience providers for UI access
final streakCoinsProvider = Provider<int>((ref) {
  final balanceAsync = ref.watch(coinBalanceProvider);
  return balanceAsync.when(
    data: (balance) => balance.streakCoins,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final coachPointsProvider = Provider<int>((ref) {
  final balanceAsync = ref.watch(coinBalanceProvider);
  return balanceAsync.when(
    data: (balance) => balance.coachPoints,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final fitGemsProvider = Provider<int>((ref) {
  final balanceAsync = ref.watch(coinBalanceProvider);
  return balanceAsync.when(
    data: (balance) => balance.fitGems,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// Check if user can afford a specific cost
final canAffordProvider = Provider.family<bool, (CoinType, int)>((ref, params) {
  final coinType = params.$1;
  final cost = params.$2;
  final balanceAsync = ref.watch(coinBalanceProvider);
  
  return balanceAsync.when(
    data: (balance) => balance.getCoinAmount(coinType) >= cost,
    loading: () => false,
    error: (_, __) => false,
  );
});

// Total coins earned (sum of all coins for display)
final totalCoinsEarnedProvider = Provider<int>((ref) {
  final balanceAsync = ref.watch(coinBalanceProvider);
  return balanceAsync.when(
    data: (balance) => balance.streakCoins + balance.coachPoints + balance.fitGems,
    loading: () => 0,
    error: (_, __) => 0,
  );
});