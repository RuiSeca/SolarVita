import 'package:cloud_firestore/cloud_firestore.dart';

class DailyStats {
  final DateTime date;
  final Map<String, bool> goalsCompleted;
  final int completedGoalsCount;
  final int currentStrikes;
  final int totalStrikes;
  final int dayStreak;
  final int level;
  final Map<String, double> healthData;
  final double ecoScore;
  
  const DailyStats({
    required this.date,
    required this.goalsCompleted,
    required this.completedGoalsCount,
    required this.currentStrikes,
    required this.totalStrikes,
    required this.dayStreak,
    required this.level,
    required this.healthData,
    this.ecoScore = 0.0,
  });

  // Helper getters
  bool get isComplete => completedGoalsCount >= 5;
  bool get isPartial => completedGoalsCount > 0 && completedGoalsCount < 5;
  bool get isEmpty => completedGoalsCount == 0;
  
  String get dateKey => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  
  // Goal completion percentages
  double get completionPercentage => (completedGoalsCount / 5.0) * 100;
  
  // Individual goal checks
  bool get stepsCompleted => goalsCompleted['steps'] ?? false;
  bool get activeMinutesCompleted => goalsCompleted['activeMinutes'] ?? false;
  bool get caloriesBurnCompleted => goalsCompleted['caloriesBurn'] ?? false;
  bool get waterIntakeCompleted => goalsCompleted['waterIntake'] ?? false;
  bool get sleepQualityCompleted => goalsCompleted['sleepQuality'] ?? false;

  factory DailyStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyStats.fromJson(data);
  }

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      date: (json['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      goalsCompleted: Map<String, bool>.from(json['goalsCompleted'] ?? {}),
      completedGoalsCount: json['completedGoalsCount'] as int? ?? 0,
      currentStrikes: json['currentStrikes'] as int? ?? 0,
      totalStrikes: json['totalStrikes'] as int? ?? 0,
      dayStreak: json['dayStreak'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      healthData: Map<String, double>.from(
        (json['healthData'] as Map<String, dynamic>? ?? {})
            .map((key, value) => MapEntry(key, (value as num?)?.toDouble() ?? 0.0)),
      ),
      ecoScore: (json['ecoScore'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': Timestamp.fromDate(date),
      'goalsCompleted': goalsCompleted,
      'completedGoalsCount': completedGoalsCount,
      'currentStrikes': currentStrikes,
      'totalStrikes': totalStrikes,
      'dayStreak': dayStreak,
      'level': level,
      'healthData': healthData,
      'ecoScore': ecoScore,
      'dateKey': dateKey,
    };
  }

  DailyStats copyWith({
    DateTime? date,
    Map<String, bool>? goalsCompleted,
    int? completedGoalsCount,
    int? currentStrikes,
    int? totalStrikes,
    int? dayStreak,
    int? level,
    Map<String, double>? healthData,
    double? ecoScore,
  }) {
    return DailyStats(
      date: date ?? this.date,
      goalsCompleted: goalsCompleted ?? this.goalsCompleted,
      completedGoalsCount: completedGoalsCount ?? this.completedGoalsCount,
      currentStrikes: currentStrikes ?? this.currentStrikes,
      totalStrikes: totalStrikes ?? this.totalStrikes,
      dayStreak: dayStreak ?? this.dayStreak,
      level: level ?? this.level,
      healthData: healthData ?? this.healthData,
      ecoScore: ecoScore ?? this.ecoScore,
    );
  }

  @override
  String toString() {
    return 'DailyStats(date: $dateKey, completed: $completedGoalsCount/5, streak: $dayStreak)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyStats &&
          runtimeType == other.runtimeType &&
          dateKey == other.dateKey;

  @override
  int get hashCode => dateKey.hashCode;
}

// Monthly stats aggregation
class MonthlyStats {
  final int year;
  final int month;
  final List<DailyStats> dailyStats;
  
  const MonthlyStats({
    required this.year,
    required this.month,
    required this.dailyStats,
  });

  // Aggregated metrics
  int get totalDays => dailyStats.length;
  int get completeDays => dailyStats.where((day) => day.isComplete).length;
  int get partialDays => dailyStats.where((day) => day.isPartial).length;
  int get emptyDays => dailyStats.where((day) => day.isEmpty).length;
  
  double get completionRate => totalDays > 0 ? (completeDays / totalDays) * 100 : 0.0;
  double get averageGoalsPerDay => totalDays > 0 
      ? dailyStats.map((day) => day.completedGoalsCount).reduce((a, b) => a + b) / totalDays 
      : 0.0;
      
  int get maxStreak => dailyStats.isEmpty ? 0 : dailyStats.map((day) => day.dayStreak).reduce((a, b) => a > b ? a : b);
  int get currentMonthStreak => dailyStats.isEmpty ? 0 : dailyStats.last.dayStreak;
  
  String get monthName {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }
  
  // Get stats for a specific day
  DailyStats? getDay(int day) {
    try {
      return dailyStats.firstWhere((stats) => stats.date.day == day);
    } catch (e) {
      return null;
    }
  }
  
  // Get calendar grid (includes empty days for proper calendar layout)
  List<DailyStats?> getCalendarGrid() {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final startOfWeek = firstDay.weekday % 7; // 0 = Sunday
    
    final grid = <DailyStats?>[];
    
    // Add empty days at the beginning
    for (int i = 0; i < startOfWeek; i++) {
      grid.add(null);
    }
    
    // Add actual days
    for (int day = 1; day <= lastDay.day; day++) {
      grid.add(getDay(day));
    }
    
    return grid;
  }
}