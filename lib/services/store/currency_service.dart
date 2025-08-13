import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';
import '../../models/store/currency_system.dart';

final log = Logger('CurrencyService');

/// Service for managing user currency, streaks, and transactions
class CurrencyService {
  static const String _currencyCollection = 'user_currency';
  static const String _streaksCollection = 'user_streaks';
  static const String _transactionsCollection = 'currency_transactions';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream controllers for real-time updates
  final StreamController<UserCurrency> _currencyController = StreamController.broadcast();
  final StreamController<UserStreak> _streakController = StreamController.broadcast();

  // Stream subscriptions
  StreamSubscription<DocumentSnapshot>? _currencySubscription;
  StreamSubscription<DocumentSnapshot>? _streakSubscription;

  // Cache
  UserCurrency? _currentCurrency;
  UserStreak? _currentStreak;

  /// Stream of current user's currency
  Stream<UserCurrency> get currencyStream => _currencyController.stream;

  /// Stream of current user's streak
  Stream<UserStreak> get streakStream => _streakController.stream;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Initialize the currency service
  Future<void> initialize() async {
    if (currentUserId == null) {
      log.warning('⚠️ No authenticated user - cannot initialize Currency Service');
      return;
    }

    log.info('🚀 Initializing Currency Service for user: $currentUserId');

    try {
      // Start listening to currency changes
      _startCurrencyListener();
      
      // Start listening to streak changes
      _startStreakListener();
      
      // Try to ensure user currency exists (but don't fail if no permissions)
      try {
        await _ensureUserCurrencyExists();
      } catch (e) {
        if (e.toString().contains('permission-denied')) {
          log.warning('⚠️ No write permission for currency - running in local mode');
        } else {
          log.warning('⚠️ Failed to create currency document: $e');
        }
      }
      
      // Try to ensure user streak exists (but don't fail if no permissions)
      try {
        await _ensureUserStreakExists();
      } catch (e) {
        if (e.toString().contains('permission-denied')) {
          log.warning('⚠️ No write permission for streaks - running in local mode');
        } else {
          log.warning('⚠️ Failed to create streak document: $e');
        }
      }
      
      // Check for daily streak reset (only if we have streaks data)
      try {
        await _checkDailyStreakReset();
      } catch (e) {
        log.warning('⚠️ Failed to check streak reset: $e');
      }

      log.info('✅ Currency Service initialized successfully');
    } catch (e, stackTrace) {
      log.severe('❌ Failed to initialize Currency Service: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Start listening to currency changes
  void _startCurrencyListener() {
    if (currentUserId == null) {
      log.warning('⚠️ Cannot start currency listener - currentUserId is null');
      return;
    }

    log.info('🎧 Starting currency listener for user: $currentUserId');
    
    // Emit default currency immediately to prevent loading state
    _currentCurrency = UserCurrency.newUser(currentUserId!);
    _currencyController.add(_currentCurrency!);
    log.info('📤 Emitted initial default currency while loading from Firestore');
    
    _currencySubscription = _firestore
        .collection(_currencyCollection)
        .doc(currentUserId)
        .snapshots()
        .listen(
      (snapshot) {
        log.info('📥 Currency snapshot received - exists: ${snapshot.exists}');
        if (snapshot.exists) {
          try {
            _currentCurrency = UserCurrency.fromFirestore(snapshot);
            _currencyController.add(_currentCurrency!);
            log.info('🔄 Currency updated from Firestore: ${_currentCurrency!.totalSpendable} coins available');
            log.info('💰 Full currency data: ${_currentCurrency!.toString()}');
          } catch (e) {
            log.severe('❌ Error parsing currency document: $e');
            log.info('📄 Raw document data: ${snapshot.data()}');
          }
        } else {
          // Document doesn't exist yet, emit default currency
          log.info('💰 Currency document not found, using local default currency for user: $currentUserId');
          _currentCurrency = UserCurrency.newUser(currentUserId!);
          _currencyController.add(_currentCurrency!);
          log.info('🔄 Currency updated: ${_currentCurrency!.totalSpendable} coins available (local mode)');
        }
      },
      onError: (error) {
        log.severe('❌ Error listening to currency: $error');
      },
    );
  }

  /// Start listening to streak changes
  void _startStreakListener() {
    if (currentUserId == null) return;

    _streakSubscription = _firestore
        .collection(_streaksCollection)
        .doc(currentUserId)
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.exists) {
          _currentStreak = UserStreak.fromFirestore(snapshot);
          _streakController.add(_currentStreak!);
          log.info('🔥 Streak updated: ${_currentStreak!.currentStreak} days (${_currentStreak!.streakTier})');
        } else {
          // Document doesn't exist yet, emit default streak
          log.info('🔥 Streak document not found, using local default streak for user: $currentUserId');
          _currentStreak = UserStreak.newUser(currentUserId!);
          _streakController.add(_currentStreak!);
          log.info('🔥 Streak updated: ${_currentStreak!.currentStreak} days (${_currentStreak!.streakTier}) (local mode)');
        }
      },
      onError: (error) {
        log.severe('❌ Error listening to streak: $error');
      },
    );
  }

  /// Ensure user currency document exists
  Future<void> _ensureUserCurrencyExists() async {
    if (currentUserId == null) return;

    final currencyDoc = await _firestore
        .collection(_currencyCollection)
        .doc(currentUserId)
        .get();

    if (!currencyDoc.exists) {
      log.info('💰 Creating initial currency for user: $currentUserId');
      
      final newCurrency = UserCurrency.newUser(currentUserId!);
      await _firestore
          .collection(_currencyCollection)
          .doc(currentUserId)
          .set(newCurrency.toFirestore());
      
      // Log initial currency transaction
      await _logTransaction(
        CurrencyType.coins,
        50,
        TransactionType.earned,
        'welcome_bonus',
        50,
        {'source': 'new_user_bonus'},
      );
      
      await _logTransaction(
        CurrencyType.points,
        100,
        TransactionType.earned,
        'welcome_bonus',
        100,
        {'source': 'new_user_bonus'},
      );
    }
  }

  /// Ensure user streak document exists
  Future<void> _ensureUserStreakExists() async {
    if (currentUserId == null) return;

    final streakDoc = await _firestore
        .collection(_streaksCollection)
        .doc(currentUserId)
        .get();

    if (!streakDoc.exists) {
      log.info('🔥 Creating initial streak for user: $currentUserId');
      
      final newStreak = UserStreak.newUser(currentUserId!);
      await _firestore
          .collection(_streaksCollection)
          .doc(currentUserId)
          .set(newStreak.toFirestore());
    }
  }

  /// Check for daily streak reset
  Future<void> _checkDailyStreakReset() async {
    if (_currentStreak == null) return;

    final streak = _currentStreak!;
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final lastActivity = DateTime(
      streak.lastActivityDate.year,
      streak.lastActivityDate.month,
      streak.lastActivityDate.day,
    );

    // If last activity was before yesterday, reset streak
    if (lastActivity.isBefore(yesterday)) {
      log.info('🔄 Resetting streak due to inactivity');
      final resetStreak = streak.resetStreak();
      await _updateStreak(resetStreak);
    }
  }

  /// Get current user currency
  UserCurrency? getCurrentCurrency() => _currentCurrency;

  /// Get current user streak
  UserStreak? getCurrentStreak() => _currentStreak;

  /// Earn currency for activity
  Future<void> earnCurrency(String activity, {Map<String, dynamic>? metadata}) async {
    if (currentUserId == null || _currentCurrency == null) {
      throw Exception('User not initialized');
    }

    log.info('💰 Processing earn currency for activity: $activity');

    try {
      // Calculate reward with streak bonus
      final currentStreakCount = _currentStreak?.currentStreak ?? 0;
      final rewards = DailyRewards.calculateReward(activity, currentStreakCount);
      
      if (rewards.isEmpty) {
        log.warning('⚠️ No rewards configured for activity: $activity');
        return;
      }

      // Use transaction to ensure consistency
      await _firestore.runTransaction((transaction) async {
        final currencyRef = _firestore.collection(_currencyCollection).doc(currentUserId);
        final currencySnapshot = await transaction.get(currencyRef);
        
        if (!currencySnapshot.exists) {
          throw Exception('Currency document not found');
        }
        
        UserCurrency currency = UserCurrency.fromFirestore(currencySnapshot);
        
        // Apply all rewards
        for (final entry in rewards.entries) {
          currency = currency.earn(entry.key, entry.value);
          
          // Log individual transaction
          await _logTransaction(
            entry.key,
            entry.value,
            TransactionType.earned,
            activity,
            currency.getBalance(entry.key),
            {
              'streak_bonus': currentStreakCount > 0,
              'streak_count': currentStreakCount,
              'multiplier': DailyRewards.getStreakMultiplier(currentStreakCount),
              ...?metadata,
            },
          );
        }
        
        // Update currency
        transaction.set(currencyRef, currency.toFirestore());
        
        log.info('✅ Currency earned for $activity: $rewards');
      });
    } catch (e, stackTrace) {
      log.severe('❌ Failed to earn currency for $activity: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Spend currency
  Future<bool> spendCurrency(CurrencyType type, int amount, String reason, {Map<String, dynamic>? metadata}) async {
    if (currentUserId == null || _currentCurrency == null) {
      throw Exception('User not initialized');
    }

    log.info('💸 Processing spend currency: $type $amount for $reason');

    try {
      // Check if user can afford
      if (!_currentCurrency!.canAfford(type, amount)) {
        log.warning('⚠️ Insufficient currency: has ${_currentCurrency!.getBalance(type)}, needs $amount');
        return false;
      }

      // Use transaction to ensure consistency
      await _firestore.runTransaction((transaction) async {
        final currencyRef = _firestore.collection(_currencyCollection).doc(currentUserId);
        final currencySnapshot = await transaction.get(currencyRef);
        
        if (!currencySnapshot.exists) {
          throw Exception('Currency document not found');
        }
        
        UserCurrency currency = UserCurrency.fromFirestore(currencySnapshot);
        
        // Double-check affordability
        if (!currency.canAfford(type, amount)) {
          throw Exception('Insufficient currency after re-check');
        }
        
        // Spend currency
        currency = currency.spend(type, amount);
        
        // Update currency
        transaction.set(currencyRef, currency.toFirestore());
        
        // Log transaction
        await _logTransaction(
          type,
          -amount,
          TransactionType.spent,
          reason,
          currency.getBalance(type),
          metadata,
        );
      });
      
      log.info('✅ Currency spent: $type $amount for $reason');
      return true;
    } catch (e, stackTrace) {
      log.severe('❌ Failed to spend currency: $e', e, stackTrace);
      return false;
    }
  }

  /// Update user streak for activity
  Future<void> updateStreak(String activityType) async {
    if (currentUserId == null || _currentStreak == null) {
      throw Exception('User not initialized');
    }

    log.info('🔥 Updating streak for activity: $activityType');

    try {
      final oldStreak = _currentStreak!.currentStreak;
      final newStreak = _currentStreak!.updateStreak(activityType);
      
      // Only update if streak actually changed
      if (newStreak.currentStreak != oldStreak || 
          newStreak.lastActivityDate.day != _currentStreak!.lastActivityDate.day) {
        await _updateStreak(newStreak);
        
        // Award streak bonus if applicable
        if (newStreak.currentStreak > oldStreak) {
          final bonusPoints = newStreak.streakBonusPoints;
          if (bonusPoints > 0) {
            await earnCurrency('streak_bonus', metadata: {
              'streak_count': newStreak.currentStreak,
              'activity_type': activityType,
            });
          }
        }
        
        log.info('✅ Streak updated: $oldStreak → ${newStreak.currentStreak} (${newStreak.streakTier})');
      }
    } catch (e, stackTrace) {
      log.severe('❌ Failed to update streak: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Update streak document
  Future<void> _updateStreak(UserStreak streak) async {
    await _firestore
        .collection(_streaksCollection)
        .doc(currentUserId)
        .set(streak.toFirestore());
  }

  /// Log currency transaction
  Future<void> _logTransaction(
    CurrencyType currencyType,
    int amount,
    TransactionType type,
    String reason,
    int balanceAfter,
    Map<String, dynamic>? metadata,
  ) async {
    if (currentUserId == null) return;

    try {
      final transactionId = const Uuid().v4();
      final transaction = CurrencyTransaction(
        transactionId: transactionId,
        userId: currentUserId!,
        currencyType: currencyType,
        amount: amount,
        type: type,
        reason: reason,
        timestamp: DateTime.now(),
        metadata: metadata ?? {},
        balanceAfter: balanceAfter,
      );

      await _firestore
          .collection(_transactionsCollection)
          .doc(transactionId)
          .set(transaction.toFirestore());
    } catch (e) {
      log.warning('⚠️ Failed to log transaction: $e');
    }
  }

  /// Get transaction history
  Future<List<CurrencyTransaction>> getTransactionHistory({
    int limit = 50,
    CurrencyType? currencyType,
    TransactionType? transactionType,
  }) async {
    if (currentUserId == null) return [];

    try {
      Query query = _firestore
          .collection(_transactionsCollection)
          .where('userId', isEqualTo: currentUserId)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (currencyType != null) {
        query = query.where('currencyType', isEqualTo: currencyType.name);
      }

      if (transactionType != null) {
        query = query.where('type', isEqualTo: transactionType.name);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => CurrencyTransaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      log.severe('❌ Failed to get transaction history: $e');
      return [];
    }
  }

  /// Purchase avatar with currency
  Future<bool> purchaseAvatar(String avatarId) async {
    final price = StorePricing.getAvatarPrice(avatarId);
    
    if (price.isEmpty) {
      // Free avatar
      return true;
    }

    log.info('🛒 Attempting to purchase avatar $avatarId for $price');

    try {
      // Check if user can afford
      if (_currentCurrency == null || !_currentCurrency!.canAffordMixed(price)) {
        log.warning('⚠️ Cannot afford avatar $avatarId');
        return false;
      }

      // Spend currency for each type in price
      for (final entry in price.entries) {
        final success = await spendCurrency(
          entry.key,
          entry.value,
          'avatar_purchase_$avatarId',
          metadata: {'avatar_id': avatarId},
        );
        
        if (!success) {
          log.severe('❌ Failed to spend ${entry.key} for avatar $avatarId');
          return false;
        }
      }
      
      log.info('✅ Avatar $avatarId purchased successfully');
      return true;
    } catch (e, stackTrace) {
      log.severe('❌ Failed to purchase avatar $avatarId: $e', e, stackTrace);
      return false;
    }
  }

  /// Get currency formatted display
  String getFormattedBalance(CurrencyType type) {
    final balance = _currentCurrency?.getBalance(type) ?? 0;
    
    if (balance < 1000) return balance.toString();
    if (balance < 1000000) return '${(balance / 1000).toStringAsFixed(1)}K';
    return '${(balance / 1000000).toStringAsFixed(1)}M';
  }

  /// Get streak display info
  Map<String, dynamic> getStreakDisplayInfo() {
    final streak = _currentStreak;
    if (streak == null) {
      return {
        'current': 0,
        'tier': 'Beginner',
        'bonus_points': 0,
        'next_milestone': 3,
        'is_active': false,
      };
    }

    int nextMilestone;
    if (streak.currentStreak < 3) {
      nextMilestone = 3;
    } else if (streak.currentStreak < 7) {
      nextMilestone = 7;
    } else if (streak.currentStreak < 14) {
      nextMilestone = 14;
    } else if (streak.currentStreak < 30) {
      nextMilestone = 30;
    } else {
      nextMilestone = (streak.currentStreak ~/ 30 + 1) * 30;
    }

    return {
      'current': streak.currentStreak,
      'longest': streak.longestStreak,
      'tier': streak.streakTier,
      'bonus_points': streak.streakBonusPoints,
      'next_milestone': nextMilestone,
      'is_active': streak.isActive,
      'can_continue_today': streak.canContinueToday,
    };
  }

  /// Add currency to user's balance
  Future<void> addCurrency(
    CurrencyType currencyType,
    int amount,
    String reason, {
    Map<String, dynamic>? metadata,
  }) async {
    if (currentUserId == null || _currentCurrency == null) {
      throw Exception('User not initialized');
    }

    try {
      await _firestore.runTransaction((transaction) async {
        final currencyRef = _firestore.collection(_currencyCollection).doc(currentUserId);
        final currencySnapshot = await transaction.get(currencyRef);
        
        if (!currencySnapshot.exists) {
          throw Exception('Currency document not found');
        }
        
        UserCurrency currency = UserCurrency.fromFirestore(currencySnapshot);
        
        // Add to existing balance
        final currentBalance = currency.getBalance(currencyType);
        final newBalance = currentBalance + amount;
        
        final updatedBalances = Map<CurrencyType, int>.from(currency.balances);
        updatedBalances[currencyType] = newBalance;
        
        final updatedCurrency = currency.copyWith(
          balances: updatedBalances,
          lastUpdated: DateTime.now(),
        );
        
        transaction.update(currencyRef, updatedCurrency.toFirestore());
        
        // Log the transaction
        await _logTransaction(
          currencyType,
          amount,
          TransactionType.earned,
          reason,
          newBalance,
          metadata,
        );
      });
      
      log.info('✅ Added $amount ${currencyType.name} for $reason');
    } catch (e, stackTrace) {
      log.severe('❌ Failed to add currency: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Set currency balance to specific amount
  Future<void> setCurrency(
    CurrencyType currencyType,
    int amount,
    String reason, {
    Map<String, dynamic>? metadata,
  }) async {
    if (currentUserId == null || _currentCurrency == null) {
      throw Exception('User not initialized');
    }

    try {
      await _firestore.runTransaction((transaction) async {
        final currencyRef = _firestore.collection(_currencyCollection).doc(currentUserId);
        final currencySnapshot = await transaction.get(currencyRef);
        
        if (!currencySnapshot.exists) {
          throw Exception('Currency document not found');
        }
        
        UserCurrency currency = UserCurrency.fromFirestore(currencySnapshot);
        
        final updatedBalances = Map<CurrencyType, int>.from(currency.balances);
        updatedBalances[currencyType] = amount;
        
        final updatedCurrency = currency.copyWith(
          balances: updatedBalances,
          lastUpdated: DateTime.now(),
        );
        
        transaction.update(currencyRef, updatedCurrency.toFirestore());
        
        // Log the transaction
        await _logTransaction(
          currencyType,
          amount,
          TransactionType.set,
          reason,
          amount,
          metadata,
        );
      });
      
      log.info('✅ Set ${currencyType.name} balance to $amount for $reason');
    } catch (e, stackTrace) {
      log.severe('❌ Failed to set currency: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Get current currency (async version for external services)
  Future<UserCurrency?> getCurrentCurrencyAsync() async {
    if (_currentCurrency != null) {
      return _currentCurrency;
    }

    if (currentUserId == null) return null;

    try {
      final snapshot = await _firestore
          .collection(_currencyCollection)
          .doc(currentUserId)
          .get();

      if (snapshot.exists) {
        return UserCurrency.fromFirestore(snapshot);
      }
      return null;
    } catch (e) {
      log.warning('❌ Failed to get current currency: $e');
      return null;
    }
  }

  /// Dispose service
  Future<void> dispose() async {
    log.info('🧹 Disposing Currency Service');
    
    await _currencySubscription?.cancel();
    await _streakSubscription?.cancel();
    
    await _currencyController.close();
    await _streakController.close();
    
    _currentCurrency = null;
    _currentStreak = null;
  }
}