import 'package:flutter/material.dart';
import '../../models/exercise/exercise_log.dart';
import '../../services/exercises/exercise_tracking_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../../screens/exercise_history/exercise_history_screen.dart';

class DailyExerciseSummaryCard extends StatefulWidget {
  const DailyExerciseSummaryCard({super.key});

  @override
  State<DailyExerciseSummaryCard> createState() => _DailyExerciseSummaryCardState();
}

class _DailyExerciseSummaryCardState extends State<DailyExerciseSummaryCard> {
  final ExerciseTrackingService _trackingService = ExerciseTrackingService();
  List<ExerciseLog> _todaysLogs = [];
  bool _isLoading = true;
  int _exerciseStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadTodaysExerciseData();
  }

  Future<void> _loadTodaysExerciseData() async {
    setState(() => _isLoading = true);
    
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      // Get today's logs
      final allLogs = await _trackingService.getAllLogs();
      final todaysLogs = allLogs.where((log) {
        return log.date.isAfter(startOfDay) && log.date.isBefore(endOfDay);
      }).toList();
      
      // Calculate exercise streak
      final streak = await _calculateExerciseStreak(allLogs);
      
      setState(() {
        _todaysLogs = todaysLogs;
        _exerciseStreak = streak;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<int> _calculateExerciseStreak(List<ExerciseLog> allLogs) async {
    if (allLogs.isEmpty) return 0;
    
    // Group logs by date
    final logsByDate = <DateTime, List<ExerciseLog>>{};
    for (final log in allLogs) {
      final date = DateTime(log.date.year, log.date.month, log.date.day);
      logsByDate.putIfAbsent(date, () => []).add(log);
    }
    
    // Calculate streak from today backwards
    int streak = 0;
    final today = DateTime.now();
    DateTime currentDate = DateTime(today.year, today.month, today.day);
    
    while (logsByDate.containsKey(currentDate)) {
      streak++;
      currentDate = currentDate.subtract(const Duration(days: 1));
    }
    
    return streak;
  }

  Map<String, dynamic> _calculateDailySummary() {
    if (_todaysLogs.isEmpty) {
      return {
        'totalTime': 0,
        'caloriesBurned': 0,
        'exerciseCount': 0,
        'topExerciseType': 'none',
      };
    }
    
    // Calculate total volume and estimate calories burned
    double totalVolume = 0;
    int totalSets = 0;
    final exerciseTypes = <String, int>{};
    
    for (final log in _todaysLogs) {
      totalSets += log.sets.length;
      
      // Calculate volume for this exercise (weight * reps gives total weight moved)
      final volume = log.sets.fold(0.0, (sum, set) => sum + (set.weight * set.reps));
      totalVolume += volume;
      
      // Categorize exercise type
      final type = _categorizeExercise(log.exerciseName);
      exerciseTypes[type] = (exerciseTypes[type] ?? 0) + 1;
    }
    
    // Estimate workout time (assume 2-3 minutes per set including rest)
    final estimatedTimeMinutes = (totalSets * 2.5).round();
    
    // More realistic calorie estimation:
    // - Base calories from time: ~3-5 calories per minute
    // - Volume bonus: much smaller multiplier since volume can be very high
    final baseCalories = estimatedTimeMinutes * 4; // 4 cal/min average
    final volumeBonus = (totalVolume * 0.01).round(); // Much smaller multiplier
    final caloriesBurned = (baseCalories + volumeBonus).clamp(0, 800); // Cap at reasonable max
    
    // Find most common exercise type
    String topExerciseType = 'general';
    int maxCount = 0;
    exerciseTypes.forEach((type, count) {
      if (count > maxCount) {
        maxCount = count;
        topExerciseType = type;
      }
    });
    
    return {
      'totalTime': estimatedTimeMinutes,
      'caloriesBurned': caloriesBurned,
      'exerciseCount': _todaysLogs.length,
      'topExerciseType': topExerciseType,
    };
  }

  String _categorizeExercise(String exerciseName) {
    final name = exerciseName.toLowerCase();
    
    if (name.contains('bench') || name.contains('press') || name.contains('squat') || name.contains('deadlift')) {
      return 'strength';
    } else if (name.contains('run') || name.contains('bike') || name.contains('cardio')) {
      return 'cardio';
    } else if (name.contains('push') || name.contains('pull') || name.contains('bodyweight')) {
      return 'calisthenics';
    } else if (name.contains('yoga') || name.contains('stretch')) {
      return 'flexibility';
    }
    
    return 'general';
  }

  IconData _getExerciseTypeIcon(String type) {
    switch (type) {
      case 'strength':
        return Icons.fitness_center;
      case 'cardio':
        return Icons.directions_run;
      case 'calisthenics':
        return Icons.self_improvement;
      case 'flexibility':
        return Icons.spa;
      case 'none':
        return Icons.fitness_center;
      default:
        return Icons.sports_gymnastics;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingCard(context);
    }

    final summary = _calculateDailySummary();
    final hasWorkout = _todaysLogs.isNotEmpty;
    
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ExerciseHistoryScreen(),
        ),
      ),
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.textColor(context).withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Exercise Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hasWorkout 
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getExerciseTypeIcon(summary['topExerciseType']),
                color: hasWorkout ? AppColors.primary : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            hasWorkout 
                                ? '${summary['exerciseCount']} ${tr(context, 'exercises')}'
                                : tr(context, 'no_workouts_today'),
                            style: TextStyle(
                              color: AppTheme.textColor(context),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_exerciseStreak > 0) ...[
                              Icon(
                                Icons.local_fire_department,
                                color: Colors.orange,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '$_exerciseStreak',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              hasWorkout 
                                  ? '${summary['caloriesBurned']} cal'
                                  : '0 cal',
                              style: TextStyle(
                                color: hasWorkout ? AppColors.primary : Colors.grey,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Text(
                      tr(context, 'exercise_summary'),
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      hasWorkout 
                          ? '${summary['totalTime']}min workout • ${tr(context, 'tap_for_details')}'
                          : tr(context, 'tap_to_start_workout'),
                      style: TextStyle(
                        color: AppTheme.textColor(context).withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            
            // Progress indicator
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                value: hasWorkout ? 1.0 : 0.0,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  hasWorkout ? AppColors.primary : Colors.grey
                ),
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textColor(context).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 14,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 12,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}