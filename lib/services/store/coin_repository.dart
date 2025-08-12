import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import '../../models/store/coin_economy.dart';
import '../../models/store/avatar_item.dart';

final log = Logger('CoinRepository');

class CoinRepository {
  static const String _coinBalanceKey = 'user_coin_balance';
  static const String _transactionHistoryKey = 'coin_transaction_history';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current coin balance
  Future<UserCoinBalance> getCoinBalance() async {
    try {
      // Try to get from Firestore first for most up-to-date data
      final firestoreBalance = await _getCoinBalanceFromFirestore();
      if (firestoreBalance != null) {
        // Update local storage with Firestore data
        await _saveCoinBalanceLocally(firestoreBalance);
        return firestoreBalance;
      }
    } catch (e) {
      log.warning('⚠️ Failed to get Firestore coin balance, using local: $e');
    }

    // Fallback to local storage
    final prefs = await SharedPreferences.getInstance();
    final balanceJson = prefs.getString(_coinBalanceKey);
    
    if (balanceJson != null) {
      try {
        final balanceMap = json.decode(balanceJson) as Map<String, dynamic>;
        return UserCoinBalance.fromJson(balanceMap);
      } catch (e) {
        log.warning('⚠️ Error parsing local coin balance: $e');
      }
    }
    
    // Return default balance for new users
    return UserCoinBalance(
      streakCoins: 0,
      coachPoints: 0,
      fitGems: 0,
    );
  }

  // Get coin balance from Firestore
  Future<UserCoinBalance?> _getCoinBalanceFromFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('user_coins')
          .doc(user.uid)
          .get();

      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      return UserCoinBalance.fromJson(data);
    } catch (e) {
      log.warning('⚠️ Error retrieving Firestore coin balance: $e');
      return null;
    }
  }

  // Save coin balance to local storage
  Future<void> _saveCoinBalanceLocally(UserCoinBalance balance) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final balanceJson = json.encode(balance.toJson());
      await prefs.setString(_coinBalanceKey, balanceJson);
    } catch (e) {
      log.warning('⚠️ Failed to save coin balance locally: $e');
    }
  }

  // Save coin balance to Firestore
  Future<void> _saveCoinBalanceToFirestore(UserCoinBalance balance) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('user_coins')
          .doc(user.uid)
          .set(balance.toFirestoreJson(), SetOptions(merge: true));
          
      log.info('✅ Coin balance saved to Firestore');
    } catch (e) {
      log.warning('⚠️ Failed to save coin balance to Firestore: $e');
      // Don't throw - local storage is primary
    }
  }

  // Award coins to user
  Future<UserCoinBalance> awardCoins(
    CoinType coinType, 
    int amount, 
    CoinEarningReason reason,
    String message,
  ) async {
    if (amount <= 0) {
      throw ArgumentError('Coin amount must be positive');
    }

    final currentBalance = await getCoinBalance();
    
    // Create updated balance based on coin type
    final UserCoinBalance updatedBalance = switch (coinType) {
      CoinType.streakCoin => currentBalance.copyWith(
          streakCoins: currentBalance.streakCoins + amount,
        ),
      CoinType.coachPoints => currentBalance.copyWith(
          coachPoints: currentBalance.coachPoints + amount,
        ),
      CoinType.fitGems => currentBalance.copyWith(
          fitGems: currentBalance.fitGems + amount,
        ),
    };

    // Save updated balance
    await _saveCoinBalance(updatedBalance);

    // Record transaction
    await _recordTransaction(CoinTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      coinType: coinType,
      amount: amount,
      isPositive: true,
      reason: reason,
      message: message,
      timestamp: DateTime.now(),
    ));

    log.info('💰 Awarded $amount ${coinType.name} for ${reason.name}');
    return updatedBalance;
  }

  // Spend coins
  Future<UserCoinBalance> spendCoins(
    CoinType coinType, 
    int amount, 
    String reason,
  ) async {
    if (amount <= 0) {
      throw ArgumentError('Coin amount must be positive');
    }

    final currentBalance = await getCoinBalance();
    
    // Check if user has enough coins
    final currentAmount = currentBalance.getCoinAmount(coinType);
    if (currentAmount < amount) {
      throw InsufficientCoinsException(
        'Insufficient ${coinType.name}: has $currentAmount, needs $amount'
      );
    }

    // Create updated balance based on coin type
    final UserCoinBalance updatedBalance = switch (coinType) {
      CoinType.streakCoin => currentBalance.copyWith(
          streakCoins: currentBalance.streakCoins - amount,
        ),
      CoinType.coachPoints => currentBalance.copyWith(
          coachPoints: currentBalance.coachPoints - amount,
        ),
      CoinType.fitGems => currentBalance.copyWith(
          fitGems: currentBalance.fitGems - amount,
        ),
    };

    // Save updated balance
    await _saveCoinBalance(updatedBalance);

    // Record transaction
    await _recordTransaction(CoinTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      coinType: coinType,
      amount: amount,
      isPositive: false,
      reason: CoinEarningReason.purchase,
      message: 'Purchased: $reason',
      timestamp: DateTime.now(),
    ));

    log.info('💸 Spent $amount ${coinType.name} for: $reason');
    return updatedBalance;
  }

  // Save coin balance (both local and Firestore)
  Future<void> _saveCoinBalance(UserCoinBalance balance) async {
    // Save locally first (primary storage)
    await _saveCoinBalanceLocally(balance);
    
    // Save to Firestore (backup/sync)
    await _saveCoinBalanceToFirestore(balance);
  }

  // Record transaction in history
  Future<void> _recordTransaction(CoinTransaction transaction) async {
    try {
      // Save locally
      await _recordTransactionLocally(transaction);
      
      // Save to Firestore
      await _recordTransactionToFirestore(transaction);
    } catch (e) {
      log.warning('⚠️ Failed to record transaction: $e');
      // Don't throw - transaction recording is not critical
    }
  }

  // Record transaction locally
  Future<void> _recordTransactionLocally(CoinTransaction transaction) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing transactions
      final historyJson = prefs.getString(_transactionHistoryKey) ?? '[]';
      final historyList = json.decode(historyJson) as List<dynamic>;
      
      // Add new transaction
      historyList.insert(0, transaction.toJson()); // Add to beginning
      
      // Keep only last 100 transactions locally to save space
      if (historyList.length > 100) {
        historyList.removeRange(100, historyList.length);
      }
      
      // Save updated history
      await prefs.setString(_transactionHistoryKey, json.encode(historyList));
    } catch (e) {
      log.warning('⚠️ Failed to record transaction locally: $e');
    }
  }

  // Record transaction to Firestore
  Future<void> _recordTransactionToFirestore(CoinTransaction transaction) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('user_coins')
          .doc(user.uid)
          .collection('transactions')
          .doc(transaction.id)
          .set(transaction.toFirestoreJson());
    } catch (e) {
      log.warning('⚠️ Failed to record transaction to Firestore: $e');
    }
  }

  // Get transaction history
  Future<List<CoinTransaction>> getTransactionHistory({int limit = 50}) async {
    try {
      // Try Firestore first for complete history
      final firestoreHistory = await _getTransactionHistoryFromFirestore(limit);
      if (firestoreHistory.isNotEmpty) {
        return firestoreHistory;
      }
    } catch (e) {
      log.warning('⚠️ Failed to get Firestore transaction history: $e');
    }

    // Fallback to local storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_transactionHistoryKey) ?? '[]';
      final historyList = json.decode(historyJson) as List<dynamic>;
      
      final transactions = historyList
          .take(limit)
          .map((json) => CoinTransaction.fromJson(json as Map<String, dynamic>))
          .toList();
          
      return transactions;
    } catch (e) {
      log.warning('⚠️ Error parsing local transaction history: $e');
      return [];
    }
  }

  // Get transaction history from Firestore
  Future<List<CoinTransaction>> _getTransactionHistoryFromFirestore(int limit) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot = await _firestore
          .collection('user_coins')
          .doc(user.uid)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => CoinTransaction.fromJson(doc.data()))
          .toList();
    } catch (e) {
      log.warning('⚠️ Error retrieving Firestore transaction history: $e');
      return [];
    }
  }

  // Clear all coin data (for testing or reset)
  Future<void> clearAllCoinData() async {
    try {
      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_coinBalanceKey);
      await prefs.remove(_transactionHistoryKey);
      
      // Clear Firestore data
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('user_coins')
            .doc(user.uid)
            .delete();
      }
      
      log.info('🧹 All coin data cleared');
    } catch (e) {
      log.warning('⚠️ Failed to clear coin data: $e');
    }
  }

  // Get coin earning statistics
  Future<CoinEarningStats> getCoinEarningStats() async {
    final transactions = await getTransactionHistory(limit: 1000); // Get more for stats
    
    final Map<CoinType, int> totalEarned = {
      CoinType.streakCoin: 0,
      CoinType.coachPoints: 0,
      CoinType.fitGems: 0,
    };
    
    final Map<CoinType, int> totalSpent = {
      CoinType.streakCoin: 0,
      CoinType.coachPoints: 0,
      CoinType.fitGems: 0,
    };
    
    final Map<CoinEarningReason, int> reasonCounts = {};
    
    for (final transaction in transactions) {
      if (transaction.isPositive) {
        totalEarned[transaction.coinType] = 
            (totalEarned[transaction.coinType] ?? 0) + transaction.amount;
            
        reasonCounts[transaction.reason] = 
            (reasonCounts[transaction.reason] ?? 0) + 1;
      } else {
        totalSpent[transaction.coinType] = 
            (totalSpent[transaction.coinType] ?? 0) + transaction.amount;
      }
    }
    
    return CoinEarningStats(
      totalEarned: totalEarned,
      totalSpent: totalSpent,
      reasonCounts: reasonCounts,
      totalTransactions: transactions.length,
    );
  }
}

// Exception for insufficient coins
class InsufficientCoinsException implements Exception {
  final String message;
  const InsufficientCoinsException(this.message);
  
  @override
  String toString() => 'InsufficientCoinsException: $message';
}

// Statistics for coin earning
class CoinEarningStats {
  final Map<CoinType, int> totalEarned;
  final Map<CoinType, int> totalSpent;
  final Map<CoinEarningReason, int> reasonCounts;
  final int totalTransactions;
  
  const CoinEarningStats({
    required this.totalEarned,
    required this.totalSpent,
    required this.reasonCounts,
    required this.totalTransactions,
  });
  
  int getTotalEarned() {
    return totalEarned.values.fold(0, (total, amount) => total + amount);
  }
  
  int getTotalSpent() {
    return totalSpent.values.fold(0, (total, amount) => total + amount);
  }
}