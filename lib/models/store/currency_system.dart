import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of currency in the Solar Vita ecosystem
enum CurrencyType {
  coins,     // Primary currency - purchased with real money or earned through activities
  points,    // Activity points - earned through daily goals and progress (displayed but not spendable)
  streak,    // Streak points - earned through consecutive days (displayed but not spendable)
}

/// User's currency balance and transaction history
class UserCurrency {
  final String userId;
  final Map<CurrencyType, int> balances;
  final DateTime lastUpdated;
  final Map<String, dynamic> metadata;

  const UserCurrency({
    required this.userId,
    required this.balances,
    required this.lastUpdated,
    required this.metadata,
  });

  /// Get balance for specific currency type
  int getBalance(CurrencyType type) => balances[type] ?? 0;

  /// Get total spendable currency (coins only)
  int get totalSpendable {
    return getBalance(CurrencyType.coins);
  }

  /// Check if user can afford a purchase
  bool canAfford(CurrencyType type, int amount) {
    return getBalance(type) >= amount;
  }

  /// Check if user can afford with mixed currency
  bool canAffordMixed(Map<CurrencyType, int> cost) {
    for (final entry in cost.entries) {
      if (!canAfford(entry.key, entry.value)) {
        return false;
      }
    }
    return true;
  }

  /// Create updated currency after transaction
  UserCurrency spend(CurrencyType type, int amount) {
    if (!canAfford(type, amount)) {
      throw Exception('Insufficient ${type.name}: has ${getBalance(type)}, needs $amount');
    }

    final newBalances = Map<CurrencyType, int>.from(balances);
    newBalances[type] = (newBalances[type] ?? 0) - amount;

    return UserCurrency(
      userId: userId,
      balances: newBalances,
      lastUpdated: DateTime.now(),
      metadata: metadata,
    );
  }

  /// Create updated currency after earning
  UserCurrency earn(CurrencyType type, int amount) {
    final newBalances = Map<CurrencyType, int>.from(balances);
    newBalances[type] = (newBalances[type] ?? 0) + amount;

    return UserCurrency(
      userId: userId,
      balances: newBalances,
      lastUpdated: DateTime.now(),
      metadata: metadata,
    );
  }

  /// Create a copy with updated values
  UserCurrency copyWith({
    String? userId,
    Map<CurrencyType, int>? balances,
    DateTime? lastUpdated,
    Map<String, dynamic>? metadata,
  }) {
    return UserCurrency(
      userId: userId ?? this.userId,
      balances: balances ?? this.balances,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'balances': balances.map((key, value) => MapEntry(key.name, value)),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'metadata': metadata,
    };
  }

  /// Create from Firestore document
  factory UserCurrency.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final balancesMap = <CurrencyType, int>{};
    final balancesData = data['balances'] as Map<String, dynamic>? ?? {};
    
    for (final entry in balancesData.entries) {
      try {
        final type = CurrencyType.values.firstWhere((t) => t.name == entry.key);
        balancesMap[type] = entry.value as int;
      } catch (e) {
        // Skip unknown currency types
      }
    }

    return UserCurrency(
      userId: doc.id,
      balances: balancesMap,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
    );
  }

  /// Create new user currency with default balances
  factory UserCurrency.newUser(String userId) {
    return UserCurrency(
      userId: userId,
      balances: {
        CurrencyType.coins: 50,    // Starting coins
        CurrencyType.points: 100, // Starting points
        CurrencyType.streak: 0,   // No starting streak
      },
      lastUpdated: DateTime.now(),
      metadata: {
        'createdAt': DateTime.now().toIso8601String(),
        'version': 1,
      },
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserCurrency &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() {
    return 'UserCurrency{userId: $userId, coins: ${getBalance(CurrencyType.coins)}, points: ${getBalance(CurrencyType.points)}, streak: ${getBalance(CurrencyType.streak)}}';
  }
}

/// Currency transaction record
class CurrencyTransaction {
  final String transactionId;
  final String userId;
  final CurrencyType currencyType;
  final int amount;
  final TransactionType type;
  final String reason;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final int balanceAfter;

  const CurrencyTransaction({
    required this.transactionId,
    required this.userId,
    required this.currencyType,
    required this.amount,
    required this.type,
    required this.reason,
    required this.timestamp,
    required this.metadata,
    required this.balanceAfter,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'transactionId': transactionId,
      'userId': userId,
      'currencyType': currencyType.name,
      'amount': amount,
      'type': type.name,
      'reason': reason,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
      'balanceAfter': balanceAfter,
    };
  }

  /// Create from Firestore document
  factory CurrencyTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return CurrencyTransaction(
      transactionId: doc.id,
      userId: data['userId'] as String,
      currencyType: CurrencyType.values.firstWhere((t) => t.name == data['currencyType']),
      amount: data['amount'] as int,
      type: TransactionType.values.firstWhere((t) => t.name == data['type']),
      reason: data['reason'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
      balanceAfter: data['balanceAfter'] as int,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrencyTransaction &&
          runtimeType == other.runtimeType &&
          transactionId == other.transactionId;

  @override
  int get hashCode => transactionId.hashCode;

  @override
  String toString() {
    return 'CurrencyTransaction{id: $transactionId, type: $type, currency: $currencyType, amount: $amount, reason: $reason}';
  }
}

/// Types of currency transactions
enum TransactionType {
  earned,     // User earned currency
  spent,      // User spent currency
  purchased,  // User purchased currency with real money
  gifted,     // Currency was gifted by admin/friend
  refunded,   // Currency was refunded
  set,        // Currency balance was set to specific amount
  bonus,      // Bonus currency (streaks, achievements)
  penalty,    // Currency removed (violations, etc.)
}

/// Streak tracking and rewards
class UserStreak {
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime lastActivityDate;
  final List<String> streakTypes; // daily_login, workout, eco_action, etc.
  final Map<String, int> streakCounts; // count per streak type
  final DateTime createdAt;
  final DateTime lastUpdated;

  const UserStreak({
    required this.userId,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastActivityDate,
    required this.streakTypes,
    required this.streakCounts,
    required this.createdAt,
    required this.lastUpdated,
  });

  /// Check if streak is active (last activity was yesterday or today)
  bool get isActive {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final today = DateTime(now.year, now.month, now.day);
    final lastActivity = DateTime(lastActivityDate.year, lastActivityDate.month, lastActivityDate.day);
    
    return lastActivity.isAtSameMomentAs(yesterday) || lastActivity.isAtSameMomentAs(today);
  }

  /// Check if user can continue streak today
  bool get canContinueToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastActivity = DateTime(lastActivityDate.year, lastActivityDate.month, lastActivityDate.day);
    
    return lastActivity.isBefore(today);
  }

  /// Calculate streak bonus points based on current streak
  int get streakBonusPoints {
    if (currentStreak < 3) return 0;
    if (currentStreak < 7) return 5;
    if (currentStreak < 14) return 10;
    if (currentStreak < 30) return 20;
    return 50; // 30+ day streak
  }

  /// Get streak tier name
  String get streakTier {
    if (currentStreak < 3) return 'Beginner';
    if (currentStreak < 7) return 'Committed';
    if (currentStreak < 14) return 'Dedicated';
    if (currentStreak < 30) return 'Champion';
    return 'Legend';
  }

  /// Update streak for new activity
  UserStreak updateStreak(String activityType) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastActivity = DateTime(lastActivityDate.year, lastActivityDate.month, lastActivityDate.day);
    
    // Don't update if already done today
    if (lastActivity.isAtSameMomentAs(today)) {
      return this;
    }
    
    int newCurrentStreak;
    int newLongestStreak = longestStreak;
    
    if (canContinueToday) {
      // Continue streak
      newCurrentStreak = currentStreak + 1;
    } else {
      // Reset streak
      newCurrentStreak = 1;
    }
    
    // Update longest streak if needed
    if (newCurrentStreak > longestStreak) {
      newLongestStreak = newCurrentStreak;
    }

    // Update streak counts
    final newStreakTypes = List<String>.from(streakTypes);
    if (!newStreakTypes.contains(activityType)) {
      newStreakTypes.add(activityType);
    }
    
    final newStreakCounts = Map<String, int>.from(streakCounts);
    newStreakCounts[activityType] = (newStreakCounts[activityType] ?? 0) + 1;

    return UserStreak(
      userId: userId,
      currentStreak: newCurrentStreak,
      longestStreak: newLongestStreak,
      lastActivityDate: now,
      streakTypes: newStreakTypes,
      streakCounts: newStreakCounts,
      createdAt: createdAt,
      lastUpdated: now,
    );
  }

  /// Reset streak (for missed days)
  UserStreak resetStreak() {
    return UserStreak(
      userId: userId,
      currentStreak: 0,
      longestStreak: longestStreak,
      lastActivityDate: lastActivityDate,
      streakTypes: streakTypes,
      streakCounts: streakCounts,
      createdAt: createdAt,
      lastUpdated: DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActivityDate': Timestamp.fromDate(lastActivityDate),
      'streakTypes': streakTypes,
      'streakCounts': streakCounts,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  /// Create from Firestore document
  factory UserStreak.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserStreak(
      userId: doc.id,
      currentStreak: data['currentStreak'] as int? ?? 0,
      longestStreak: data['longestStreak'] as int? ?? 0,
      lastActivityDate: (data['lastActivityDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      streakTypes: List<String>.from(data['streakTypes'] as List? ?? []),
      streakCounts: Map<String, int>.from(data['streakCounts'] as Map? ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create new user streak
  factory UserStreak.newUser(String userId) {
    final now = DateTime.now();
    return UserStreak(
      userId: userId,
      currentStreak: 0,
      longestStreak: 0,
      lastActivityDate: now,
      streakTypes: [],
      streakCounts: {},
      createdAt: now,
      lastUpdated: now,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserStreak &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() {
    return 'UserStreak{userId: $userId, current: $currentStreak, longest: $longestStreak, tier: $streakTier, active: $isActive}';
  }
}

/// Daily activity rewards configuration
class DailyRewards {
  static const Map<String, Map<CurrencyType, int>> activityRewards = {
    'daily_login': {
      CurrencyType.points: 10,
      CurrencyType.streak: 1,
    },
    'complete_workout': {
      CurrencyType.points: 25,
      CurrencyType.coins: 2,
    },
    'eco_action': {
      CurrencyType.points: 15,
      CurrencyType.coins: 1,
    },
    'social_post': {
      CurrencyType.points: 5,
    },
    'achievement_unlock': {
      CurrencyType.coins: 10,
      CurrencyType.points: 50,
    },
  };

  /// Get streak bonus multiplier based on current streak
  static double getStreakMultiplier(int streak) {
    if (streak < 3) return 1.0;
    if (streak < 7) return 1.2;
    if (streak < 14) return 1.5;
    if (streak < 30) return 2.0;
    return 3.0; // 30+ day streak
  }

  /// Calculate actual reward with streak bonus
  static Map<CurrencyType, int> calculateReward(String activity, int currentStreak) {
    final baseReward = activityRewards[activity] ?? {};
    final multiplier = getStreakMultiplier(currentStreak);
    
    return baseReward.map((currency, amount) => 
      MapEntry(currency, (amount * multiplier).round())
    );
  }
}

/// Purchase prices for various items
class StorePricing {
  static const Map<String, Map<CurrencyType, int>> avatarPrices = {
    // Free avatars
    'mummy_coach': {},
    'classic_coach': {},
    
    // Paid avatars
    'quantum_coach': {
      CurrencyType.coins: 50,
    },
    'ninja_coach': {
      CurrencyType.coins: 30,
    },
    'robot_coach': {
      CurrencyType.coins: 40,
    },
    'wizard_coach': {
      CurrencyType.coins: 60,
    },
    'dragon_coach': {
      CurrencyType.coins: 100,
    },
  };

  /// Get price for avatar
  static Map<CurrencyType, int> getAvatarPrice(String avatarId) {
    return avatarPrices[avatarId] ?? {CurrencyType.coins: 50};
  }

  /// Check if avatar is free
  static bool isAvatarFree(String avatarId) {
    final price = getAvatarPrice(avatarId);
    return price.isEmpty || price.values.every((amount) => amount == 0);
  }
}