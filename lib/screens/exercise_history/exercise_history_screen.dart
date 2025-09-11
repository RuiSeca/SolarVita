// lib/screens/exercise_history/exercise_history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/exercise/exercise_log.dart';
import '../../models/user/personal_record.dart';
import '../../services/exercises/exercise_tracking_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import 'exercise_detail_history_screen.dart';
import 'log_exercise_screen.dart';
import '../../widgets/common/lottie_loading_widget.dart';
import '../../widgets/charts/exercise_progress_chart.dart';
import '../../widgets/charts/exercise_type_pie_chart.dart';
import '../../widgets/charts/weekly_volume_chart.dart';
import '../../widgets/charts/workout_intensity_heatmap.dart';
import '../../widgets/achievements/personal_record_celebration.dart';

class ExerciseHistoryScreen extends StatefulWidget {
  final String? exerciseId;
  final String? initialTitle;

  const ExerciseHistoryScreen({super.key, this.exerciseId, this.initialTitle});

  @override
  State<ExerciseHistoryScreen> createState() => _ExerciseHistoryScreenState();
}

class _ExerciseHistoryScreenState extends State<ExerciseHistoryScreen>
    with SingleTickerProviderStateMixin {
  final ExerciseTrackingService _trackingService = ExerciseTrackingService();
  late TabController _tabController;
  late Future<List<ExerciseLog>> _logsFuture;
  late DateTimeRange _dateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Default to showing last 30 days
    final now = DateTime.now();
    _dateRange = DateTimeRange(
      start: now.subtract(const Duration(days: 30)),
      end: now,
    );

    _refreshLogs();
  }

  void _refreshLogs() {
    if (widget.exerciseId != null) {
      // Load logs for a specific exercise
      _logsFuture = _trackingService.getAllLogs().then((allLogs) {
        // Filter for specific exercise
        final filteredLogs = allLogs
            .where((log) => log.exerciseId == widget.exerciseId)
            .toList();
        return filteredLogs;
      });
    } else {
      // Load all logs within the selected date range
      _logsFuture = _trackingService.getLogsByDateRange(
        _dateRange.start,
        _dateRange.end,
      );
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppTheme.surfaceColor(context),
              onSurface: AppTheme.textColor(context),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
        _refreshLogs();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.exerciseId != null
              ? tr(context, 'exercise_history_for_title')
              : tr(context, 'exercise_history'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _refreshLogs();
              });
            },
            tooltip: 'Refresh logs',
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: tr(context, 'select_date_range'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: tr(context, 'history')),
            Tab(text: tr(context, 'charts')),
            Tab(text: tr(context, 'records')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildHistoryTab(), _buildChartsTab(), _buildRecordsTab()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  LogExerciseScreen(exerciseId: widget.exerciseId),
            ),
          );

          if (result == true) {
            setState(() {
              _refreshLogs();
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return FutureBuilder<List<ExerciseLog>>(
      future: _logsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LottieLoadingWidget());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              tr(context, 'error_loading_logs'),
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        final logs = snapshot.data ?? [];

        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  widget.exerciseId != null
                      ? 'No logs found for this exercise'
                      : tr(context, 'no_logs_found'),
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                if (widget.exerciseId != null) ...[
                  Text(
                    'Exercise ID: ${widget.exerciseId}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    'Exercise: ${widget.initialTitle ?? 'Unknown'}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  tr(context, 'tap_plus_to_log'),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Group logs by date
        final groupedLogs = <DateTime, List<ExerciseLog>>{};
        for (var log in logs) {
          final date = DateTime(log.date.year, log.date.month, log.date.day);
          if (!groupedLogs.containsKey(date)) {
            groupedLogs[date] = [];
          }
          groupedLogs[date]!.add(log);
        }

        final sortedDates = groupedLogs.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final date = sortedDates[index];
            final dateFormatted = DateFormat.yMMMd().format(date);
            final logsForDate = groupedLogs[date]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    dateFormatted,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                ),
                ...logsForDate.map((log) => _buildLogItem(log)),
                const SizedBox(height: 8),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLogItem(ExerciseLog log) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExerciseDetailHistoryScreen(log: log),
            ),
          );

          if (result == true) {
            setState(() {
              _refreshLogs();
            });
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryColor.withAlpha(26)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.exerciseName,
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${log.sets.length} sets',
                          style: TextStyle(
                            color: AppTheme.textColor(context).withAlpha(179),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          ' • ',
                          style: TextStyle(
                            color: AppTheme.textColor(context).withAlpha(179),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          DateFormat.jm().format(log.date),
                          style: TextStyle(
                            color: AppTheme.textColor(context).withAlpha(179),
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        if (log.routineId != null && log.dayName != null) ...[
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tr(context, log.dayName!.toLowerCase()),
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ] else ...[
                          Icon(
                            Icons.fitness_center,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tr(context, 'standalone'),
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (log.isPersonalRecord)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'PR',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: AppTheme.textColor(context).withAlpha(179),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartsTab() {
    return FutureBuilder<List<ExerciseLog>>(
      future: _logsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LottieLoadingWidget());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              tr(context, 'error_loading_logs'),
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        final logs = snapshot.data ?? [];

        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bar_chart, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  tr(context, 'no_data_for_charts'),
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  tr(context, 'tap_plus_to_log'),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              // Workout Intensity Heatmap (only show for all exercises view)
              if (widget.exerciseId == null) ...[
                Container(
                  margin: const EdgeInsets.all(16),
                  child: const WorkoutIntensityHeatmap(),
                ),
              ],
              
              // Weekly Volume Chart
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.textColor(context).withValues(alpha: 0.1),
                  ),
                ),
                child: WeeklyVolumeChart(logs: logs),
              ),
              
              // Progress Chart (for specific exercise) or Exercise Type Distribution (for all exercises)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.textColor(context).withValues(alpha: 0.1),
                  ),
                ),
                child: widget.exerciseId != null
                    ? ExerciseProgressChart(
                        logs: logs,
                        chartType: 'weight',
                        lineColor: AppColors.primary,
                      )
                    : ExerciseTypePieChart(logs: logs),
              ),
              
              // Additional Progress Charts for specific exercise
              if (widget.exerciseId != null) ...[
                // Volume Progress Chart
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.textColor(context).withValues(alpha: 0.1),
                    ),
                  ),
                  child: ExerciseProgressChart(
                    logs: logs,
                    chartType: 'volume',
                    lineColor: Colors.green,
                  ),
                ),
                
                // Reps Progress Chart
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.textColor(context).withValues(alpha: 0.1),
                    ),
                  ),
                  child: ExerciseProgressChart(
                    logs: logs,
                    chartType: 'reps',
                    lineColor: Colors.orange,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // Helper method to navigate to exercise detail
  void _navigateToExerciseDetail(ExerciseLog log) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseDetailHistoryScreen(log: log),
      ),
    );
  }

  Widget _buildRecordsTab() {
    return FutureBuilder<List<PersonalRecord>>(
      future: widget.exerciseId != null
          ? _trackingService.getPersonalRecordsForExercise(widget.exerciseId!)
          : _trackingService.getAllPersonalRecords(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LottieLoadingWidget());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              tr(context, 'error_loading_records'),
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        final records = snapshot.data ?? [];

        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  tr(context, 'no_personal_records'),
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Group records by exercise
        final groupedRecords = <String, List<PersonalRecord>>{};
        for (var record in records) {
          if (!groupedRecords.containsKey(record.exerciseId)) {
            groupedRecords[record.exerciseId] = [];
          }
          groupedRecords[record.exerciseId]!.add(record);
        }

        return Column(
          children: [
            // Achievement badges section
            Padding(
              padding: const EdgeInsets.all(16),
              child: AchievementBadgesWidget(records: records),
            ),
            
            // Records list
            Expanded(
              child: ListView.builder(
                itemCount: groupedRecords.length,
                itemBuilder: (context, index) {
            final exerciseId = groupedRecords.keys.toList()[index];
            final recordsForExercise = groupedRecords[exerciseId]!;
            final exerciseName = recordsForExercise.first.exerciseName;

            return ExpansionTile(
              title: Text(exerciseName),
              children: recordsForExercise.map((record) {
                return ListTile(
                  leading: const Icon(Icons.emoji_events, color: Colors.amber),
                  title: Text(record.recordType),
                  subtitle: Text(
                    '${_formatRecordValue(record)} • ${DateFormat.yMMMd().format(record.date)}',
                  ),
                  onTap: () async {
                    // Go to the log that created this record
                    final logs = await _trackingService.getAllLogs();
                    final recordLog = logs.firstWhere(
                      (log) => log.id == record.logId,
                      orElse: () => throw Exception('Log not found'),
                    );

                    // Check if the widget is still mounted before navigating
                    if (mounted) {
                      _navigateToExerciseDetail(recordLog);
                    }
                  },
                );
              }).toList(),
            );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatRecordValue(PersonalRecord record) {
    switch (record.recordType) {
      case 'Max Weight':
        return '${record.value.toStringAsFixed(1)} kg';
      case 'Volume':
        return '${record.value.toStringAsFixed(0)} kg';
      default:
        return record.value.toString();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
