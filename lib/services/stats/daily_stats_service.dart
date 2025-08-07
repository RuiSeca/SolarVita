import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import '../../models/stats/daily_stats.dart';
import '../../models/user/user_progress.dart';
import '../../models/health/health_data.dart';

final log = Logger('DailyStatsService');

class DailyStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save daily stats (called whenever progress is updated)
  Future<void> saveDailyStats(UserProgress progress, HealthData healthData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        log.warning('🚫 No authenticated user for stats saving');
        return;
      }

      final now = DateTime.now();
      final dailyStats = DailyStats(
        date: now,
        goalsCompleted: progress.todayGoalsCompleted,
        completedGoalsCount: progress.completedGoalsCount,
        currentStrikes: progress.currentStrikes,
        totalStrikes: progress.totalStrikes,
        dayStreak: progress.dayStreak,
        level: progress.currentLevel,
        healthData: {
          'steps': healthData.steps.toDouble(),
          'activeMinutes': healthData.activeMinutes.toDouble(),
          'caloriesBurned': healthData.caloriesBurned.toDouble(), // caloriesBurned is already int, convert to double for storage
          'waterIntake': healthData.waterIntake,
          'sleepHours': healthData.sleepHours,
        },
        ecoScore: healthData.carbonSaved ?? 0.0, // Use null-aware operator
      );

      await _firestore
          .collection('user_stats')
          .doc(user.uid)
          .collection('daily')
          .doc(dailyStats.dateKey)
          .set(dailyStats.toJson(), SetOptions(merge: true));

      log.info('📊 Daily stats saved for ${dailyStats.dateKey}');
    } catch (e) {
      log.warning('⚠️ Failed to save daily stats: $e');
    }
  }

  // Get daily stats for a specific date
  Future<DailyStats?> getDailyStats(DateTime date) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      final doc = await _firestore
          .collection('user_stats')
          .doc(user.uid)
          .collection('daily')
          .doc(dateKey)
          .get();

      if (!doc.exists) return null;

      return DailyStats.fromFirestore(doc);
    } catch (e) {
      log.warning('⚠️ Failed to get daily stats: $e');
      return null;
    }
  }

  // Get monthly stats
  Future<MonthlyStats> getMonthlyStats(int year, int month) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return MonthlyStats(year: year, month: month, dailyStats: []);
      }

      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 0);

      log.info('📊 Fetching monthly stats for $year-$month');

      final query = await _firestore
          .collection('user_stats')
          .doc(user.uid)
          .collection('daily')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .orderBy('date')
          .get();

      final dailyStats = query.docs
          .map((doc) => DailyStats.fromFirestore(doc))
          .toList();

      log.info('📊 Retrieved ${dailyStats.length} days of stats for $year-$month');

      return MonthlyStats(
        year: year,
        month: month,
        dailyStats: dailyStats,
      );
    } catch (e) {
      log.warning('⚠️ Failed to get monthly stats: $e');
      return MonthlyStats(year: year, month: month, dailyStats: []);
    }
  }

  // Get stats for multiple months (for overview)
  Future<List<MonthlyStats>> getMonthlyStatsRange(DateTime startDate, DateTime endDate) async {
    final monthlyStats = <MonthlyStats>[];
    
    var currentDate = DateTime(startDate.year, startDate.month, 1);
    final end = DateTime(endDate.year, endDate.month, 1);

    while (currentDate.isBefore(end) || currentDate.isAtSameMomentAs(end)) {
      final stats = await getMonthlyStats(currentDate.year, currentDate.month);
      monthlyStats.add(stats);
      currentDate = DateTime(currentDate.year, currentDate.month + 1, 1);
    }

    return monthlyStats;
  }

  // Get recent stats (last 30 days)
  Future<List<DailyStats>> getRecentStats({int days = 30}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      final query = await _firestore
          .collection('user_stats')
          .doc(user.uid)
          .collection('daily')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .limit(days)
          .get();

      final dailyStats = query.docs
          .map((doc) => DailyStats.fromFirestore(doc))
          .toList();

      log.info('📊 Retrieved ${dailyStats.length} recent days of stats');
      return dailyStats;
    } catch (e) {
      log.warning('⚠️ Failed to get recent stats: $e');
      return [];
    }
  }

  // Get stats overview for dashboard
  Future<Map<String, dynamic>> getStatsOverview() async {
    try {
      final recentStats = await getRecentStats(days: 30);
      final thisMonth = await getMonthlyStats(DateTime.now().year, DateTime.now().month);
      final lastMonth = await getMonthlyStats(
        DateTime.now().month == 1 ? DateTime.now().year - 1 : DateTime.now().year,
        DateTime.now().month == 1 ? 12 : DateTime.now().month - 1,
      );

      return {
        'currentStreak': recentStats.isNotEmpty ? recentStats.first.dayStreak : 0,
        'thisMonthCompletion': thisMonth.completionRate,
        'lastMonthCompletion': lastMonth.completionRate,
        'thisMonthCompleteDays': thisMonth.completeDays,
        'thisMonthTotalDays': thisMonth.totalDays,
        'averageGoalsPerDay': thisMonth.averageGoalsPerDay,
        'bestStreak': thisMonth.maxStreak,
        'recentActivity': recentStats.take(7).toList(),
      };
    } catch (e) {
      log.warning('⚠️ Failed to get stats overview: $e');
      return {};
    }
  }

  // Clean up old stats (optional - for performance)
  Future<void> cleanOldStats({int keepMonths = 6}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final cutoffDate = DateTime.now().subtract(Duration(days: keepMonths * 30));
      
      final query = await _firestore
          .collection('user_stats')
          .doc(user.uid)
          .collection('daily')
          .where('date', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (var doc in query.docs) {
        batch.delete(doc.reference);
      }

      if (query.docs.isNotEmpty) {
        await batch.commit();
        log.info('🧹 Cleaned ${query.docs.length} old stats entries');
      }
    } catch (e) {
      log.warning('⚠️ Failed to clean old stats: $e');
    }
  }
}