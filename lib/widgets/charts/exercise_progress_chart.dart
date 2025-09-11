import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/exercise/exercise_log.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';

class ExerciseProgressChart extends StatelessWidget {
  final List<ExerciseLog> logs;
  final String chartType; // 'weight', 'volume', 'reps'
  final Color? lineColor;

  const ExerciseProgressChart({
    super.key,
    required this.logs,
    this.chartType = 'weight',
    this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return _buildEmptyState(context);
    }

    final chartData = _prepareChartData();
    
    if (chartData.isEmpty) {
      return _buildEmptyState(context);
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getChartTitle(context),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _getHorizontalInterval(chartData),
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.textColor(context).withValues(alpha: 0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatYAxisValue(value),
                          style: TextStyle(
                            color: AppTheme.textColor(context).withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: _getBottomInterval(chartData.length),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < logs.length) {
                          return Text(
                            _formatDate(logs[index].date),
                            style: TextStyle(
                              color: AppTheme.textColor(context).withValues(alpha: 0.6),
                              fontSize: 10,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData,
                    isCurved: true,
                    curveSmoothness: 0.2,
                    color: lineColor ?? AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: lineColor ?? AppColors.primary,
                          strokeWidth: 2,
                          strokeColor: AppTheme.surfaceColor(context),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          (lineColor ?? AppColors.primary).withValues(alpha: 0.3),
                          (lineColor ?? AppColors.primary).withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: AppTheme.cardColor(context),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((touchedSpot) {
                        final logIndex = touchedSpot.x.toInt();
                        if (logIndex >= 0 && logIndex < logs.length) {
                          final log = logs[logIndex];
                          return LineTooltipItem(
                            '${_formatTooltipValue(touchedSpot.y)}\n${_formatDate(log.date)}',
                            TextStyle(
                              color: AppTheme.textColor(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }
                        return null;
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: AppTheme.textColor(context).withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              tr(context, 'no_progress_data'),
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

  List<FlSpot> _prepareChartData() {
    final spots = <FlSpot>[];
    
    for (int i = 0; i < logs.length; i++) {
      final log = logs[i];
      double value = 0;
      
      switch (chartType) {
        case 'weight':
          // Get max weight from all sets
          if (log.sets.isNotEmpty) {
            value = log.sets.map((set) => set.weight).reduce((a, b) => a > b ? a : b);
          }
          break;
        case 'volume':
          // Calculate total volume (weight × reps)
          value = log.sets.fold(0.0, (sum, set) => sum + (set.weight * set.reps));
          break;
        case 'reps':
          // Get max reps from all sets
          if (log.sets.isNotEmpty) {
            value = log.sets.map((set) => set.reps.toDouble()).reduce((a, b) => a > b ? a : b);
          }
          break;
      }
      
      if (value > 0) {
        spots.add(FlSpot(i.toDouble(), value));
      }
    }
    
    return spots;
  }

  String _getChartTitle(BuildContext context) {
    switch (chartType) {
      case 'weight':
        return tr(context, 'max_weight_progress');
      case 'volume':
        return tr(context, 'total_volume_progress');
      case 'reps':
        return tr(context, 'max_reps_progress');
      default:
        return tr(context, 'progress_chart');
    }
  }

  double _getHorizontalInterval(List<FlSpot> data) {
    if (data.isEmpty) return 10;
    
    final maxY = data.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    final minY = data.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    final range = maxY - minY;
    
    if (range == 0) return 10;
    return range / 4; // Show ~4 horizontal lines
  }

  double _getBottomInterval(int dataLength) {
    if (dataLength <= 5) return 1;
    if (dataLength <= 10) return 2;
    return (dataLength / 5).ceil().toDouble();
  }

  String _formatYAxisValue(double value) {
    switch (chartType) {
      case 'weight':
      case 'volume':
        return '${value.toInt()}kg';
      case 'reps':
        return value.toInt().toString();
      default:
        return value.toInt().toString();
    }
  }

  String _formatTooltipValue(double value) {
    switch (chartType) {
      case 'weight':
        return '${value.toStringAsFixed(1)} kg';
      case 'volume':
        return '${value.toStringAsFixed(0)} kg total';
      case 'reps':
        return '${value.toInt()} reps';
      default:
        return value.toStringAsFixed(1);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '${difference}d ago';
    
    return '${date.month}/${date.day}';
  }
}