import 'package:flutter/material.dart';
import '../../models/exercise/exercise_log.dart';
import '../../services/exercises/exercise_tracking_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';

class WorkoutIntensityHeatmap extends StatefulWidget {
  final int weeksToShow;
  final double? height;
  
  const WorkoutIntensityHeatmap({
    super.key,
    this.weeksToShow = 12, // Show ~3 months by default
    this.height,
  });

  @override
  State<WorkoutIntensityHeatmap> createState() => _WorkoutIntensityHeatmapState();
}

class _WorkoutIntensityHeatmapState extends State<WorkoutIntensityHeatmap> {
  final ExerciseTrackingService _trackingService = ExerciseTrackingService();
  List<ExerciseLog> _exerciseLogs = [];
  bool _isLoading = true;
  Map<DateTime, double> _dailyIntensity = {};

  @override
  void initState() {
    super.initState();
    _loadExerciseData();
  }

  Future<void> _loadExerciseData() async {
    setState(() => _isLoading = true);
    
    try {
      final logs = await _trackingService.getAllLogs();
      final dailyIntensity = _calculateDailyIntensity(logs);
      
      setState(() {
        _exerciseLogs = logs;
        _dailyIntensity = dailyIntensity;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Map<DateTime, double> _calculateDailyIntensity(List<ExerciseLog> logs) {
    final Map<DateTime, double> dailyIntensity = {};
    
    // Group logs by date and calculate intensity
    for (final log in logs) {
      final date = DateTime(log.date.year, log.date.month, log.date.day);
      
      // Calculate intensity based on:
      // 1. Number of sets
      // 2. Total volume (weight * reps)
      // 3. Exercise variety
      final sets = log.sets.length;
      final volume = log.sets.fold(0.0, (sum, set) => sum + (set.weight * set.reps));
      
      // Normalize intensity (0.0 to 1.0)
      // Base intensity from sets (up to 0.4 for 10+ sets)
      final setsIntensity = (sets / 25.0).clamp(0.0, 0.4);
      
      // Volume intensity (up to 0.6 for high volume)
      final volumeIntensity = (volume / 5000.0).clamp(0.0, 0.6);
      
      final logIntensity = setsIntensity + volumeIntensity;
      dailyIntensity[date] = (dailyIntensity[date] ?? 0.0) + logIntensity;
    }
    
    // Cap daily intensity at 1.0 and normalize
    dailyIntensity.updateAll((key, value) => value.clamp(0.0, 1.0));
    
    return dailyIntensity;
  }

  List<DateTime> _generateDateRange() {
    final today = DateTime.now();
    final startDate = today.subtract(Duration(days: widget.weeksToShow * 7));
    
    // Start from the beginning of the week (Monday)
    final adjustedStartDate = startDate.subtract(
      Duration(days: startDate.weekday - 1)
    );
    
    final dates = <DateTime>[];
    for (int i = 0; i < widget.weeksToShow * 7; i++) {
      dates.add(adjustedStartDate.add(Duration(days: i)));
    }
    
    return dates;
  }

  Color _getIntensityColor(double intensity) {
    if (intensity == 0) {
      return AppTheme.textColor(context).withValues(alpha: 0.1);
    }
    
    // Create intensity gradient from light green to deep green
    final baseColor = AppColors.primary;
    
    if (intensity <= 0.2) {
      return baseColor.withValues(alpha: 0.2);
    } else if (intensity <= 0.4) {
      return baseColor.withValues(alpha: 0.4);
    } else if (intensity <= 0.6) {
      return baseColor.withValues(alpha: 0.6);
    } else if (intensity <= 0.8) {
      return baseColor.withValues(alpha: 0.8);
    } else {
      return baseColor;
    }
  }

  String _getIntensityLabel(double intensity) {
    if (intensity == 0) return tr(context, 'no_workout');
    if (intensity <= 0.3) return tr(context, 'light_workout');
    if (intensity <= 0.6) return tr(context, 'moderate_workout');
    if (intensity <= 0.8) return tr(context, 'intense_workout');
    return tr(context, 'very_intense_workout');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    return Container(
      height: widget.height ?? 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textColor(context).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr(context, 'workout_intensity_heatmap'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildLegend(),
            ],
          ),
          const SizedBox(height: 16),
          
          // Heatmap
          Expanded(
            child: _buildHeatmap(),
          ),
          
          const SizedBox(height: 8),
          
          // Stats summary
          _buildStatsSummary(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: widget.height ?? 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textColor(context).withValues(alpha: 0.1),
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        Text(
          tr(context, 'less'),
          style: TextStyle(
            color: AppTheme.textColor(context).withValues(alpha: 0.6),
            fontSize: 10,
          ),
        ),
        const SizedBox(width: 4),
        ...List.generate(5, (index) {
          return Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: _getIntensityColor(index * 0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
        const SizedBox(width: 4),
        Text(
          tr(context, 'more'),
          style: TextStyle(
            color: AppTheme.textColor(context).withValues(alpha: 0.6),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildHeatmap() {
    final dates = _generateDateRange();
    const squareSize = 12.0;
    const squareSpacing = 2.0;
    const daysInWeek = 7;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month labels
        Row(
          children: [
            const SizedBox(width: 20), // Offset for day labels
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(widget.weeksToShow, (weekIndex) {
                    return SizedBox(
                      width: squareSize + squareSpacing,
                      child: weekIndex % 4 == 0 // Show every 4th week
                        ? Text(
                            _getMonthLabel(dates[weekIndex * 7]),
                            style: TextStyle(
                              color: AppTheme.textColor(context).withValues(alpha: 0.6),
                              fontSize: 9,
                            ),
                          )
                        : null,
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
          const SizedBox(height: 4),
          
          // Main heatmap grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day of week labels
              Column(
                children: ['', 'Mon', '', 'Wed', '', 'Fri', ''].map((day) {
                  return Container(
                    height: squareSize + squareSpacing,
                    width: 16,
                    alignment: Alignment.centerRight,
                    child: Text(
                      day,
                      style: TextStyle(
                        color: AppTheme.textColor(context).withValues(alpha: 0.6),
                        fontSize: 9,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(width: 4),
              
              // Heatmap squares with constrained width
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    children: List.generate(daysInWeek, (dayOfWeek) {
                      return Row(
                        children: List.generate(widget.weeksToShow, (week) {
                      final dateIndex = week * daysInWeek + dayOfWeek;
                      if (dateIndex >= dates.length) {
                        return SizedBox(
                          width: squareSize + squareSpacing,
                          height: squareSize + squareSpacing,
                        );
                      }
                      
                      final date = dates[dateIndex];
                      final intensity = _dailyIntensity[date] ?? 0.0;
                      
                      return GestureDetector(
                        onTap: () => _showDayDetails(date, intensity),
                        child: Container(
                          width: squareSize,
                          height: squareSize,
                          margin: const EdgeInsets.all(squareSpacing / 2),
                          decoration: BoxDecoration(
                            color: _getIntensityColor(intensity),
                            borderRadius: BorderRadius.circular(2),
                            border: intensity > 0 ? Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              width: 0.5,
                            ) : null,
                          ),
                        ),
                      );
                    }),
                  );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
  }

  Widget _buildStatsSummary() {
    final totalDays = _dailyIntensity.length;
    final activeDays = _dailyIntensity.values.where((intensity) => intensity > 0).length;
    final averageIntensity = totalDays > 0 
        ? _dailyIntensity.values.fold(0.0, (a, b) => a + b) / totalDays
        : 0.0;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          tr(context, 'active_days'), 
          '$activeDays/$totalDays'
        ),
        _buildStatItem(
          tr(context, 'consistency'), 
          '${((activeDays / (totalDays.clamp(1, double.infinity))) * 100).toStringAsFixed(0)}%'
        ),
        _buildStatItem(
          tr(context, 'avg_intensity'), 
          _getIntensityLabel(averageIntensity)
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textColor(context).withValues(alpha: 0.6),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  String _getMonthLabel(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[date.month - 1];
  }

  void _showDayDetails(DateTime date, double intensity) {
    final dayLogs = _exerciseLogs.where((log) {
      final logDate = DateTime(log.date.year, log.date.month, log.date.day);
      return logDate.isAtSameMomentAs(date);
    }).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Text(
          '${_getMonthLabel(date)} ${date.day}',
          style: TextStyle(color: AppTheme.textColor(context)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getIntensityLabel(intensity)} • ${dayLogs.length} ${tr(context, 'exercises')}',
              style: TextStyle(
                color: AppTheme.textColor(context).withValues(alpha: 0.8),
              ),
            ),
            if (dayLogs.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...dayLogs.map((log) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${log.exerciseName} (${log.sets.length} sets)',
                  style: TextStyle(
                    color: AppTheme.textColor(context).withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'close')),
          ),
        ],
      ),
    );
  }
}