import 'package:cloud_firestore/cloud_firestore.dart';
import 'avatar_item.dart';

class UserCoinBalance {
  final int streakCoins;
  final int coachPoints;
  final int fitGems;
  final DateTime lastUpdated;
  final Map<String, int> dailyEarnings;
  final Map<String, int> totalEarned;
  final Map<String, int> totalSpent;

  UserCoinBalance({
    this.streakCoins = 0,
    this.coachPoints = 0,
    this.fitGems = 0,
    DateTime? lastUpdated,
    this.dailyEarnings = const {},
    this.totalEarned = const {},
    this.totalSpent = const {},
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  // Helper methods
  int getCoinAmount(CoinType type) {
    switch (type) {
      case CoinType.streakCoin:
        return streakCoins;
      case CoinType.coachPoints:
        return coachPoints;
      case CoinType.fitGems:
        return fitGems;
    }
  }

  bool canAfford(CoinType type, int amount) {
    return getCoinAmount(type) >= amount;
  }

  // Factory constructors
  factory UserCoinBalance.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserCoinBalance.fromJson(data);
  }

  factory UserCoinBalance.fromJson(Map<String, dynamic> json) {
    return UserCoinBalance(
      streakCoins: json['streakCoins'] as int? ?? 0,
      coachPoints: json['coachPoints'] as int? ?? 0,
      fitGems: json['fitGems'] as int? ?? 0,
      lastUpdated: json['lastUpdated'] != null
          ? (json['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
      dailyEarnings: Map<String, int>.from(json['dailyEarnings'] ?? {}),
      totalEarned: Map<String, int>.from(json['totalEarned'] ?? {}),
      totalSpent: Map<String, int>.from(json['totalSpent'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'streakCoins': streakCoins,
      'coachPoints': coachPoints,
      'fitGems': fitGems,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'dailyEarnings': dailyEarnings,
      'totalEarned': totalEarned,
      'totalSpent': totalSpent,
    };
  }

  UserCoinBalance copyWith({
    int? streakCoins,
    int? coachPoints,
    int? fitGems,
    DateTime? lastUpdated,
    Map<String, int>? dailyEarnings,
    Map<String, int>? totalEarned,
    Map<String, int>? totalSpent,
  }) {
    return UserCoinBalance(
      streakCoins: streakCoins ?? this.streakCoins,
      coachPoints: coachPoints ?? this.coachPoints,
      fitGems: fitGems ?? this.fitGems,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      dailyEarnings: dailyEarnings ?? this.dailyEarnings,
      totalEarned: totalEarned ?? this.totalEarned,
      totalSpent: totalSpent ?? this.totalSpent,
    );
  }

  // Coin operations
  UserCoinBalance addCoins(CoinType type, int amount, String reason) {
    final now = DateTime.now();
    
    Map<String, int> updatedDaily = Map.from(dailyEarnings);
    Map<String, int> updatedTotal = Map.from(totalEarned);
    
    final coinKey = type.toString().split('.').last;
    updatedDaily[coinKey] = (updatedDaily[coinKey] ?? 0) + amount;
    updatedTotal[coinKey] = (updatedTotal[coinKey] ?? 0) + amount;

    switch (type) {
      case CoinType.streakCoin:
        return copyWith(
          streakCoins: streakCoins + amount,
          lastUpdated: now,
          dailyEarnings: updatedDaily,
          totalEarned: updatedTotal,
        );
      case CoinType.coachPoints:
        return copyWith(
          coachPoints: coachPoints + amount,
          lastUpdated: now,
          dailyEarnings: updatedDaily,
          totalEarned: updatedTotal,
        );
      case CoinType.fitGems:
        return copyWith(
          fitGems: fitGems + amount,
          lastUpdated: now,
          dailyEarnings: updatedDaily,
          totalEarned: updatedTotal,
        );
    }
  }

  UserCoinBalance spendCoins(CoinType type, int amount, String reason) {
    if (!canAfford(type, amount)) {
      throw Exception('Insufficient ${type.toString().split('.').last}');
    }

    final now = DateTime.now();
    Map<String, int> updatedSpent = Map.from(totalSpent);
    
    final coinKey = type.toString().split('.').last;
    updatedSpent[coinKey] = (updatedSpent[coinKey] ?? 0) + amount;

    switch (type) {
      case CoinType.streakCoin:
        return copyWith(
          streakCoins: streakCoins - amount,
          lastUpdated: now,
          totalSpent: updatedSpent,
        );
      case CoinType.coachPoints:
        return copyWith(
          coachPoints: coachPoints - amount,
          lastUpdated: now,
          totalSpent: updatedSpent,
        );
      case CoinType.fitGems:
        return copyWith(
          fitGems: fitGems - amount,
          lastUpdated: now,
          totalSpent: updatedSpent,
        );
    }
  }

  @override
  String toString() => 'UserCoinBalance(streak: $streakCoins, coach: $coachPoints, gems: $fitGems)';
}


// Coin earning events
class CoinEarningEvent {
  final CoinType type;
  final int amount;
  final String reason;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const CoinEarningEvent({
    required this.type,
    required this.amount,
    required this.reason,
    required this.timestamp,
    this.metadata = const {},
  });

  factory CoinEarningEvent.fromJson(Map<String, dynamic> json) {
    return CoinEarningEvent(
      type: CoinType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      amount: json['amount'] as int,
      reason: json['reason'] as String,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'amount': amount,
      'reason': reason,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }
}

// Predefined coin earning rules
class CoinEarningRules {
  static const Map<String, Map<CoinType, int>> dailyRewards = {
    'daily_login': {CoinType.streakCoin: 10},
    'complete_workout': {CoinType.coachPoints: 25},
    'complete_all_goals': {CoinType.coachPoints: 50, CoinType.streakCoin: 5},
    'week_streak': {CoinType.streakCoin: 100},
    'month_streak': {CoinType.streakCoin: 500},
  };

  static const Map<String, Map<CoinType, int>> activityRewards = {
    'steps_10k': {CoinType.coachPoints: 15},
    'active_minutes_30': {CoinType.coachPoints: 20},
    'water_goal': {CoinType.coachPoints: 10},
    'sleep_goal': {CoinType.coachPoints: 15},
    'calories_goal': {CoinType.coachPoints: 20},
  };

  static const Map<String, Map<CoinType, int>> socialRewards = {
    'share_achievement': {CoinType.coachPoints: 25},
    'invite_friend': {CoinType.streakCoin: 50},
    'tribe_participation': {CoinType.coachPoints: 15},
  };

  static int getRewardAmount(String action, CoinType type) {
    // Check daily rewards first
    if (dailyRewards.containsKey(action) && 
        dailyRewards[action]!.containsKey(type)) {
      return dailyRewards[action]![type]!;
    }
    
    // Check activity rewards
    if (activityRewards.containsKey(action) && 
        activityRewards[action]!.containsKey(type)) {
      return activityRewards[action]![type]!;
    }
    
    // Check social rewards
    if (socialRewards.containsKey(action) && 
        socialRewards[action]!.containsKey(type)) {
      return socialRewards[action]![type]!;
    }
    
    return 0;
  }
}

// Coin earning reasons enum
enum CoinEarningReason {
  goalCompletion,
  levelUp,
  streakMilestone,
  perfectDay,
  purchase,
  manual,
}

// Coin transaction class for tracking purchases and earnings
class CoinTransaction {
  final String id;
  final CoinType coinType;
  final int amount;
  final bool isPositive;
  final CoinEarningReason reason;
  final String message;
  final DateTime timestamp;

  const CoinTransaction({
    required this.id,
    required this.coinType,
    required this.amount,
    required this.isPositive,
    required this.reason,
    required this.message,
    required this.timestamp,
  });

  factory CoinTransaction.fromJson(Map<String, dynamic> json) {
    return CoinTransaction(
      id: json['id'] as String,
      coinType: CoinType.values.firstWhere(
        (e) => e.name == json['coinType'],
        orElse: () => CoinType.streakCoin,
      ),
      amount: json['amount'] as int,
      isPositive: json['isPositive'] as bool,
      reason: CoinEarningReason.values.firstWhere(
        (e) => e.name == json['reason'],
        orElse: () => CoinEarningReason.manual,
      ),
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coinType': coinType.name,
      'amount': amount,
      'isPositive': isPositive,
      'reason': reason.name,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}