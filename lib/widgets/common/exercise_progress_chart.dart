// lib/widgets/exercise_progress_chart.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/exercise_log.dart';
import '../../theme/app_theme.dart';

enum ChartMetric {
  weight,
  volume,
  reps,
}

class ExerciseProgressChart extends StatefulWidget {
  final List<ExerciseLog> logs;
  final ChartMetric metric;
  final int timeSpan; // Days to include in the chart

  const ExerciseProgressChart({
    super.key,
    required this.logs,
    this.metric = ChartMetric.weight,
    this.timeSpan = 30,
  });

  @override
  State<ExerciseProgressChart> createState() => _ExerciseProgressChartState();
}

class _ExerciseProgressChartState extends State<ExerciseProgressChart> {
  late List<ExerciseLog> _filteredLogs;

  @override
  void initState() {
    super.initState();
    _filterLogs();
  }

  @override
  void didUpdateWidget(ExerciseProgressChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.logs != widget.logs ||
        oldWidget.timeSpan != widget.timeSpan ||
        oldWidget.metric != widget.metric) {
      _filterLogs();
    }
  }

  void _filterLogs() {
    // Filter logs by time span
    final cutoffDate = DateTime.now().subtract(Duration(days: widget.timeSpan));
    _filteredLogs = widget.logs
        .where((log) => log.date.isAfter(cutoffDate))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date)); // Sort by date (oldest first)
  }

  @override
  Widget build(BuildContext context) {
    if (_filteredLogs.isEmpty) {
      return Center(
        child: Text(
          'No data available for the selected period',
          style: TextStyle(
            color: AppTheme.textColor(context).withAlpha(77),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getChartTitle(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 250,
            child: LineChart(_createLineChart()),
          ),
        ],
      ),
    );
  }

  String _getChartTitle() {
    switch (widget.metric) {
      case ChartMetric.weight:
        return 'Max Weight Progress';
      case ChartMetric.volume:
        return 'Total Volume Progress';
      case ChartMetric.reps:
        return 'Total Reps Progress';
    }
  }

  LineChartData _createLineChart() {
    final spots = _createChartData();
    final maxY =
        spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) * 1.1;
    final minY =
        spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b) * 0.9;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: _calculateYInterval(minY, maxY),
        verticalInterval: 1,
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < _filteredLogs.length) {
                final date = _filteredLogs[value.toInt()].date;
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    DateFormat('M/d').format(date),
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textColor(context).withAlpha(179),
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
            interval: _calculateXInterval(),
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            getTitlesWidget: (value, meta) {
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  _formatYValue(value),
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textColor(context).withAlpha(179),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff37434d), width: 1),
      ),
      minX: 0,
      maxX: (_filteredLogs.length - 1).toDouble(),
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: false,
          color: Theme.of(context).primaryColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Theme.of(context).primaryColor,
                strokeWidth: 1,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: Theme.of(context).primaryColor.withAlpha(51),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: AppTheme.cardColor(context).withAlpha(204),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((touchedSpot) {
              final index = touchedSpot.x.toInt();
              if (index >= 0 && index < _filteredLogs.length) {
                final log = _filteredLogs[index];
                final value = touchedSpot.y;
                final date = DateFormat.yMMMd().format(log.date);

                return LineTooltipItem(
                  '${_getTooltipTitle()}: ${_formatYValue(value)}\n$date',
                  TextStyle(
                    color: AppTheme.textColor(context),
                    fontWeight: FontWeight.bold,
                  ),
                );
              }
              return null;
            }).toList();
          },
        ),
      ),
    );
  }

  List<FlSpot> _createChartData() {
    final spots = <FlSpot>[];

    for (int i = 0; i < _filteredLogs.length; i++) {
      final log = _filteredLogs[i];
      double value;

      switch (widget.metric) {
        case ChartMetric.weight:
          value = log.maxWeight;
          break;
        case ChartMetric.volume:
          value = log.totalVolume;
          break;
        case ChartMetric.reps:
          value = log.sets.fold(0, (sum, set) => sum + set.reps).toDouble();
          break;
      }

      spots.add(FlSpot(i.toDouble(), value));
    }

    return spots;
  }

  String _getTooltipTitle() {
    switch (widget.metric) {
      case ChartMetric.weight:
        return 'Max Weight';
      case ChartMetric.volume:
        return 'Total Volume';
      case ChartMetric.reps:
        return 'Total Reps';
    }
  }

  String _formatYValue(double value) {
    switch (widget.metric) {
      case ChartMetric.weight:
        return '${value.toStringAsFixed(1)} kg';
      case ChartMetric.volume:
        return '${value.toStringAsFixed(0)} kg';
      case ChartMetric.reps:
        return value.toStringAsFixed(0);
    }
  }

  double _calculateYInterval(double min, double max) {
    final range = max - min;
    if (range <= 5) return 1;
    if (range <= 20) return 5;
    if (range <= 100) return 20;
    return range / 5;
  }

  double _calculateXInterval() {
    final count = _filteredLogs.length;
    if (count <= 7) return 1;
    if (count <= 14) return 2;
    if (count <= 30) return 5;
    return count / 6;
  }
}
