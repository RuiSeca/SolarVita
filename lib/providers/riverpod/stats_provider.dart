import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/stats/daily_stats.dart';
import '../../services/stats/daily_stats_service.dart';

// Daily Stats Service Provider
final dailyStatsServiceProvider = Provider<DailyStatsService>((ref) {
  return DailyStatsService();
});

// Current Month Stats Provider
final currentMonthStatsProvider = FutureProvider<MonthlyStats>((ref) async {
  final service = ref.watch(dailyStatsServiceProvider);
  final now = DateTime.now();
  return service.getMonthlyStats(now.year, now.month);
});

// Previous Month Stats Provider  
final previousMonthStatsProvider = FutureProvider<MonthlyStats>((ref) async {
  final service = ref.watch(dailyStatsServiceProvider);
  final now = DateTime.now();
  final prevMonth = now.month == 1 ? 12 : now.month - 1;
  final year = now.month == 1 ? now.year - 1 : now.year;
  return service.getMonthlyStats(year, prevMonth);
});

// Specific Month Stats Provider (with parameters)
final monthStatsProvider = FutureProvider.family<MonthlyStats, ({int year, int month})>((ref, params) async {
  final service = ref.watch(dailyStatsServiceProvider);
  return service.getMonthlyStats(params.year, params.month);
});

// Recent Stats Provider (last 30 days)
final recentStatsProvider = FutureProvider<List<DailyStats>>((ref) async {
  final service = ref.watch(dailyStatsServiceProvider);
  return service.getRecentStats(days: 30);
});

// Stats Overview Provider (for dashboard quick stats)
final statsOverviewProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(dailyStatsServiceProvider);
  return service.getStatsOverview();
});

// Daily Stats Provider for specific date
final dailyStatsProvider = FutureProvider.family<DailyStats?, DateTime>((ref, date) async {
  final service = ref.watch(dailyStatsServiceProvider);
  return service.getDailyStats(date);
});

// Multi-month range provider (for trends)
final monthlyStatsRangeProvider = FutureProvider.family<List<MonthlyStats>, ({DateTime start, DateTime end})>((ref, params) async {
  final service = ref.watch(dailyStatsServiceProvider);
  return service.getMonthlyStatsRange(params.start, params.end);
});

// Current month navigation state
class MonthNavigationState {
  final int year;
  final int month;
  
  const MonthNavigationState({
    required this.year,
    required this.month,
  });

  MonthNavigationState copyWith({int? year, int? month}) {
    return MonthNavigationState(
      year: year ?? this.year,
      month: month ?? this.month,
    );
  }

  MonthNavigationState previousMonth() {
    if (month == 1) {
      return MonthNavigationState(year: year - 1, month: 12);
    } else {
      return MonthNavigationState(year: year, month: month - 1);
    }
  }

  MonthNavigationState nextMonth() {
    if (month == 12) {
      return MonthNavigationState(year: year + 1, month: 1);
    } else {
      return MonthNavigationState(year: year, month: month + 1);
    }
  }

  bool get isCurrentMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  bool get isFutureMonth {
    final now = DateTime.now();
    final current = DateTime(now.year, now.month);
    final this_ = DateTime(year, month);
    return this_.isAfter(current);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthNavigationState &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month;

  @override
  int get hashCode => year.hashCode ^ month.hashCode;
}

// Month Navigation State Notifier
class MonthNavigationNotifier extends StateNotifier<MonthNavigationState> {
  MonthNavigationNotifier() : super(MonthNavigationState(
    year: DateTime.now().year,
    month: DateTime.now().month,
  ));

  void goToPreviousMonth() {
    state = state.previousMonth();
  }

  void goToNextMonth() {
    if (!state.nextMonth().isFutureMonth) {
      state = state.nextMonth();
    }
  }

  void goToCurrentMonth() {
    final now = DateTime.now();
    state = MonthNavigationState(year: now.year, month: now.month);
  }

  void goToMonth(int year, int month) {
    final newState = MonthNavigationState(year: year, month: month);
    if (!newState.isFutureMonth) {
      state = newState;
    }
  }
}

// Month Navigation Provider
final monthNavigationProvider = StateNotifierProvider<MonthNavigationNotifier, MonthNavigationState>((ref) {
  return MonthNavigationNotifier();
});

// Current viewed month stats (based on navigation)
final currentViewedMonthStatsProvider = FutureProvider<MonthlyStats>((ref) async {
  final navigation = ref.watch(monthNavigationProvider);
  final service = ref.watch(dailyStatsServiceProvider);
  return service.getMonthlyStats(navigation.year, navigation.month);
});

// Selected Day Provider for bottom card display
final selectedDayProvider = StateProvider<DailyStats?>((ref) => null);