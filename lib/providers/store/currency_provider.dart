import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../../models/store/currency_system.dart';
import '../../services/store/currency_service.dart';
import '../../services/store/daily_goals_currency_service.dart';
import '../../providers/firebase/firebase_avatar_provider.dart';

final log = Logger('CurrencyProvider');

/// Provider for Currency Service
final currencyServiceProvider = Provider<CurrencyService>((ref) {
  final service = CurrencyService();
  
  // Initialize service immediately if user is already authenticated
  final authState = ref.read(authStateProvider);
  if (authState.hasValue && authState.value != null) {
    service.initialize().catchError((error) {
      log.severe('Failed to initialize Currency Service immediately: $error');
    });
  }
  
  // Listen to auth state changes and reinitialize service when needed
  ref.listen(authStateProvider, (previous, next) {
    if (next.hasValue) {
      final user = next.value;
      if (user != null) {
        // User signed in, initialize service
        service.initialize().catchError((error) {
          log.severe('Failed to initialize Currency Service: $error');
        });
      } else {
        // User signed out, dispose service
        service.dispose().catchError((error) {
          log.warning('Error disposing Currency Service: $error');
        });
      }
    }
  });

  // Dispose service when provider is disposed
  ref.onDispose(() {
    service.dispose().catchError((error) {
      log.warning('Error disposing Currency Service: $error');
    });
  });

  return service;
});

/// Provider for current user's currency
final userCurrencyProvider = StreamProvider<UserCurrency?>((ref) {
  final service = ref.read(currencyServiceProvider);
  return service.currencyStream;
});

/// Provider for current user's streak
final userStreakProvider = StreamProvider<UserStreak?>((ref) {
  final service = ref.read(currencyServiceProvider);
  return service.streakStream;
});

/// Provider for currency balances
final currencyBalancesProvider = Provider<Map<CurrencyType, int>>((ref) {
  final currency = ref.watch(userCurrencyProvider).valueOrNull;
  return currency?.balances ?? {
    CurrencyType.coins: 0,
    CurrencyType.points: 0,
    CurrencyType.streak: 0,
  };
});

/// Provider for formatted currency displays
final formattedCurrencyProvider = Provider<Map<CurrencyType, String>>((ref) {
  final service = ref.read(currencyServiceProvider);
  
  return {
    for (final type in CurrencyType.values)
      type: service.getFormattedBalance(type),
  };
});

/// Provider for streak display information
final streakDisplayProvider = Provider<Map<String, dynamic>>((ref) {
  final service = ref.read(currencyServiceProvider);
  return service.getStreakDisplayInfo();
});

/// Provider for checking if user can afford specific items
final affordabilityProvider = Provider.family<bool, Map<CurrencyType, int>>((ref, price) {
  final currency = ref.watch(userCurrencyProvider).valueOrNull;
  return currency?.canAffordMixed(price) ?? false;
});

/// Provider for avatar purchase affordability
final avatarAffordabilityProvider = Provider.family<bool, String>((ref, avatarId) {
  final price = StorePricing.getAvatarPrice(avatarId);
  if (price.isEmpty) return true; // Free avatar
  
  final currency = ref.watch(userCurrencyProvider).valueOrNull;
  return currency?.canAffordMixed(price) ?? false;
});

/// Provider for currency operations
final currencyOperationsProvider = Provider<CurrencyOperations>((ref) {
  final service = ref.read(currencyServiceProvider);
  return CurrencyOperations(service);
});

/// Provider for Daily Goals Currency Service (auto-initialized)
final dailyGoalsCurrencyServiceProvider = Provider<DailyGoalsCurrencyService>((ref) {
  final currencyService = ref.read(currencyServiceProvider);
  final service = DailyGoalsCurrencyService(currencyService);
  
  // Initialize the service when created
  service.initialize().catchError((error) {
    log.warning('Failed to initialize Daily Goals Currency Service: $error');
  });
  
  // Dispose when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// Provider for currency transaction history
final transactionHistoryProvider = FutureProvider.family<List<CurrencyTransaction>, TransactionFilter>((ref, filter) async {
  final service = ref.read(currencyServiceProvider);
  return await service.getTransactionHistory(
    limit: filter.limit,
    currencyType: filter.currencyType,
    transactionType: filter.transactionType,
  );
});

/// Provider for recent transactions (last 10)
final recentTransactionsProvider = FutureProvider<List<CurrencyTransaction>>((ref) async {
  final service = ref.read(currencyServiceProvider);
  return await service.getTransactionHistory(limit: 10);
});

/// Provider for currency statistics
final currencyStatsProvider = Provider<CurrencyStats>((ref) {
  final currency = ref.watch(userCurrencyProvider).valueOrNull;
  final streak = ref.watch(userStreakProvider).valueOrNull;
  
  return CurrencyStats(
    totalGemsEquivalent: currency?.totalSpendable ?? 0,
    currentStreak: streak?.currentStreak ?? 0,
    longestStreak: streak?.longestStreak ?? 0,
    streakTier: streak?.streakTier ?? 'Beginner',
    streakBonusPoints: streak?.streakBonusPoints ?? 0,
    balances: currency?.balances ?? {},
  );
});

/// Helper class for currency operations
class CurrencyOperations {
  final CurrencyService _service;

  const CurrencyOperations(this._service);

  /// Earn currency for activity
  Future<void> earnCurrency(String activity, {Map<String, dynamic>? metadata}) async {
    try {
      await _service.earnCurrency(activity, metadata: metadata);
      log.info('✅ Currency earned for activity: $activity');
    } catch (e) {
      log.severe('❌ Failed to earn currency for $activity: $e');
      rethrow;
    }
  }

  /// Spend currency
  Future<bool> spendCurrency(CurrencyType type, int amount, String reason, {Map<String, dynamic>? metadata}) async {
    try {
      final success = await _service.spendCurrency(type, amount, reason, metadata: metadata);
      if (success) {
        log.info('✅ Currency spent: $type $amount for $reason');
      } else {
        log.warning('⚠️ Insufficient currency for $reason');
      }
      return success;
    } catch (e) {
      log.severe('❌ Failed to spend currency: $e');
      return false;
    }
  }

  /// Update user streak
  Future<void> updateStreak(String activityType) async {
    try {
      await _service.updateStreak(activityType);
      log.info('✅ Streak updated for activity: $activityType');
    } catch (e) {
      log.severe('❌ Failed to update streak: $e');
      rethrow;
    }
  }

  /// Purchase avatar
  Future<bool> purchaseAvatar(String avatarId) async {
    try {
      final success = await _service.purchaseAvatar(avatarId);
      if (success) {
        log.info('✅ Avatar purchased: $avatarId');
      } else {
        log.warning('⚠️ Avatar purchase failed: $avatarId');
      }
      return success;
    } catch (e) {
      log.severe('❌ Avatar purchase error: $e');
      return false;
    }
  }

  /// Daily login reward
  Future<void> processDailyLogin() async {
    await earnCurrency('daily_login', metadata: {'login_time': DateTime.now().toIso8601String()});
    await updateStreak('daily_login');
  }

  /// Workout completion reward
  Future<void> processWorkoutCompletion(String workoutType, int durationMinutes) async {
    await earnCurrency('complete_workout', metadata: {
      'workout_type': workoutType,
      'duration_minutes': durationMinutes,
    });
    await updateStreak('workout');
  }

  /// Eco action reward
  Future<void> processEcoAction(String actionType) async {
    await earnCurrency('eco_action', metadata: {'action_type': actionType});
    await updateStreak('eco_action');
  }

  /// Social post reward
  Future<void> processSocialPost(String postId) async {
    await earnCurrency('social_post', metadata: {'post_id': postId});
  }

  /// Achievement unlock reward
  Future<void> processAchievementUnlock(String achievementId) async {
    await earnCurrency('achievement_unlock', metadata: {'achievement_id': achievementId});
  }
}

/// Filter for transaction history queries
class TransactionFilter {
  final int limit;
  final CurrencyType? currencyType;
  final TransactionType? transactionType;

  const TransactionFilter({
    this.limit = 50,
    this.currencyType,
    this.transactionType,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionFilter &&
          runtimeType == other.runtimeType &&
          limit == other.limit &&
          currencyType == other.currencyType &&
          transactionType == other.transactionType;

  @override
  int get hashCode => limit.hashCode ^ currencyType.hashCode ^ transactionType.hashCode;
}

/// Currency statistics summary
class CurrencyStats {
  final int totalGemsEquivalent;
  final int currentStreak;
  final int longestStreak;
  final String streakTier;
  final int streakBonusPoints;
  final Map<CurrencyType, int> balances;

  const CurrencyStats({
    required this.totalGemsEquivalent,
    required this.currentStreak,
    required this.longestStreak,
    required this.streakTier,
    required this.streakBonusPoints,
    required this.balances,
  });

  /// Get balance for specific currency type
  int getBalance(CurrencyType type) => balances[type] ?? 0;

  /// Get formatted balance
  String getFormattedBalance(CurrencyType type) {
    final balance = getBalance(type);
    if (balance < 1000) return balance.toString();
    if (balance < 1000000) return '${(balance / 1000).toStringAsFixed(1)}K';
    return '${(balance / 1000000).toStringAsFixed(1)}M';
  }

  @override
  String toString() {
    return 'CurrencyStats{totalGems: $totalGemsEquivalent, streak: $currentStreak ($streakTier), balances: $balances}';
  }
}

/// Provider for currency leaderboard
final currencyLeaderboardProvider = FutureProvider.family<List<LeaderboardEntry>, LeaderboardType>((ref, type) async {
  final service = ref.read(currencyServiceProvider);
  
  try {
    // Get leaderboard data from Firestore
    return await _fetchLeaderboardData(service, type);
  } catch (e) {
    log.severe('❌ Failed to fetch leaderboard: $e');
    return <LeaderboardEntry>[];
  }
});

/// Fetch leaderboard data from Firestore
Future<List<LeaderboardEntry>> _fetchLeaderboardData(CurrencyService service, LeaderboardType type) async {
  // Since we don't have access to other users' data due to security rules,
  // we'll implement a mock leaderboard for now
  
  // In a real implementation, this would be done via Cloud Functions
  // that aggregate public leaderboard data
  
  final mockLeaderboard = <LeaderboardEntry>[
    LeaderboardEntry(
      userId: 'demo_user_1',
      displayName: 'EcoWarrior',
      value: _getMockValue(type, 1),
      rank: 1,
      avatarUrl: null,
    ),
    LeaderboardEntry(
      userId: 'demo_user_2', 
      displayName: 'GreenChampion',
      value: _getMockValue(type, 2),
      rank: 2,
      avatarUrl: null,
    ),
    LeaderboardEntry(
      userId: 'demo_user_3',
      displayName: 'SolarExplorer',
      value: _getMockValue(type, 3),
      rank: 3,
      avatarUrl: null,
    ),
    LeaderboardEntry(
      userId: 'demo_user_4',
      displayName: 'ClimateHero',
      value: _getMockValue(type, 4),
      rank: 4,
      avatarUrl: null,
    ),
    LeaderboardEntry(
      userId: 'demo_user_5',
      displayName: 'NatureGuardian',
      value: _getMockValue(type, 5),
      rank: 5,
      avatarUrl: null,
    ),
  ];
  
  // Add current user to leaderboard if available
  final currentCurrency = service.getCurrentCurrency();
  final currentStreak = service.getCurrentStreak();
  
  if (currentCurrency != null) {
    final currentUserValue = switch (type) {
      LeaderboardType.totalGems => currentCurrency.totalSpendable,
      LeaderboardType.longestStreak => currentStreak?.longestStreak ?? 0,
      LeaderboardType.currentStreak => currentStreak?.currentStreak ?? 0,
      LeaderboardType.weeklyEarnings => currentCurrency.getBalance(CurrencyType.points), // Mock weekly
    };
    
    mockLeaderboard.add(LeaderboardEntry(
      userId: 'current_user',
      displayName: 'You',
      value: currentUserValue,
      rank: 6, // For now, place user at 6th
      avatarUrl: null,
    ));
  }
  
  return mockLeaderboard;
}

/// Get mock values for different leaderboard types
int _getMockValue(LeaderboardType type, int rank) {
  return switch (type) {
    LeaderboardType.totalGems => [2500, 2200, 1800, 1500, 1200][rank - 1],
    LeaderboardType.longestStreak => [45, 38, 32, 28, 24][rank - 1], 
    LeaderboardType.currentStreak => [15, 12, 10, 8, 6][rank - 1],
    LeaderboardType.weeklyEarnings => [850, 720, 650, 580, 520][rank - 1],
  };
}

/// Leaderboard types
enum LeaderboardType {
  totalGems,
  longestStreak,
  currentStreak,
  weeklyEarnings,
}

/// Leaderboard entry
class LeaderboardEntry {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int value;
  final int rank;

  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.value,
    required this.rank,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaderboardEntry &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          rank == other.rank;

  @override
  int get hashCode => userId.hashCode ^ rank.hashCode;

  @override
  String toString() => 'LeaderboardEntry{rank: $rank, user: $displayName, value: $value}';
}