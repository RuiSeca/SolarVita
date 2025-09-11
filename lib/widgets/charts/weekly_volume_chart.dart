import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/exercise/exercise_log.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';

class WeeklyVolumeChart extends StatelessWidget {
  final List<ExerciseLog> logs;
  final double? height;

  const WeeklyVolumeChart({
    super.key,
    required this.logs,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return _buildEmptyState(context);
    }

    final chartData = _prepareWeeklyData();
    
    return Container(
      height: height ?? 200,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'weekly_training_volume'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxY(chartData),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: AppTheme.cardColor(context),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final dayName = _getDayName(context, group.x.toInt());
                      final volume = rod.toY.toStringAsFixed(0);
                      return BarTooltipItem(
                        '$dayName\n$volume kg',
                        TextStyle(
                          color: AppTheme.textColor(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}kg',
                          style: TextStyle(
                            color: AppTheme.textColor(context).withValues(alpha: 0.6),
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _getDayAbbr(context, value.toInt()),
                          style: TextStyle(
                            color: AppTheme.textColor(context).withValues(alpha: 0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _getMaxY(chartData) / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.textColor(context).withValues(alpha: 0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                barGroups: chartData,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SizedBox(
      height: height ?? 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: AppTheme.textColor(context).withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              tr(context, 'no_weekly_data'),
              style: TextStyle(
                color: AppTheme.textColor(context).withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _prepareWeeklyData() {
    // Initialize weekly data (Monday = 0, Sunday = 6)
    final weeklyVolume = List<double>.filled(7, 0);
    
    // Get the current week's Monday
    final now = DateTime.now();
    final currentWeekMonday = now.subtract(Duration(days: now.weekday - 1));
    
    // Calculate volume for each day
    for (final log in logs) {
      // Check if log is from current week
      final logDate = DateTime(log.date.year, log.date.month, log.date.day);
      final daysSinceMonday = logDate.difference(currentWeekMonday).inDays;
      
      if (daysSinceMonday >= 0 && daysSinceMonday < 7) {
        // Calculate total volume for this log
        final volume = log.sets.fold(0.0, (sum, set) => sum + (set.weight * set.reps));
        weeklyVolume[daysSinceMonday] += volume;
      }
    }
    
    // Create bar chart groups
    final barGroups = <BarChartGroupData>[];
    
    for (int i = 0; i < 7; i++) {
      final isToday = i == (now.weekday - 1);
      final volume = weeklyVolume[i];
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: volume,
              color: isToday 
                  ? AppColors.primary 
                  : AppColors.primary.withValues(alpha: 0.7),
              width: 16,
              borderRadius: BorderRadius.circular(4),
              gradient: volume > 0 ? LinearGradient(
                colors: [
                  isToday ? AppColors.primary : AppColors.primary.withValues(alpha: 0.7),
                  isToday ? AppColors.primary.withValues(alpha: 0.7) : AppColors.primary.withValues(alpha: 0.5),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ) : null,
            ),
          ],
        ),
      );
    }
    
    return barGroups;
  }

  double _getMaxY(List<BarChartGroupData> data) {
    if (data.isEmpty) return 100;
    
    double maxValue = 0;
    for (final group in data) {
      for (final rod in group.barRods) {
        if (rod.toY > maxValue) {
          maxValue = rod.toY;
        }
      }
    }
    
    // Add some padding to the top
    return maxValue * 1.2;
  }

  String _getDayName(BuildContext context, int dayIndex) {
    final days = [
      'monday',
      'tuesday', 
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    
    if (dayIndex >= 0 && dayIndex < days.length) {
      return tr(context, days[dayIndex]);
    }
    return '';
  }

  String _getDayAbbr(BuildContext context, int dayIndex) {
    final daysAbbr = [
      'mon',
      'tue',
      'wed', 
      'thu',
      'fri',
      'sat',
      'sun',
    ];
    
    if (dayIndex >= 0 && dayIndex < daysAbbr.length) {
      return tr(context, daysAbbr[dayIndex]);
    }
    return '';
  }
}