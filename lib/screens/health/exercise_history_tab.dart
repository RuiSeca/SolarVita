// lib/screens/health/exercise_history_tab.dart
import 'package:flutter/material.dart';
import '../exercise_history/exercise_history_screen.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../../services/exercises/exercise_tracking_service.dart';
import '../../models/exercise/exercise_log.dart';
import '../../models/user/personal_record.dart';
import '../../widgets/common/lottie_loading_widget.dart';

class ExerciseHistoryTab extends StatelessWidget {
  const ExerciseHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 180,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withAlpha(179),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(context, 'your_progress'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tr(context, 'track_your_fitness_journey'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              title: Text(tr(context, 'exercise_history')),
            ),
          ),
          SliverToBoxAdapter(child: _buildRecentWorkouts(context)),
          SliverToBoxAdapter(child: _buildPersonalRecords(context)),
          SliverToBoxAdapter(child: _buildActivityOverview(context)),
          SliverToBoxAdapter(child: const SizedBox(height: 16)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ExerciseHistoryScreen(),
            ),
          );
        },
        tooltip: tr(context, 'log_workout'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRecentWorkouts(BuildContext context) {
    final trackingService = ExerciseTrackingService();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr(context, 'recent_workouts'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ExerciseHistoryScreen(),
                    ),
                  );
                },
                child: Text(tr(context, 'view_all')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<ExerciseLog>>(
            future: trackingService.getAllLogs(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: LottieLoadingWidget(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(child: Text(tr(context, 'error_loading_data')));
              }

              final logs = snapshot.data ?? [];

              if (logs.isEmpty) {
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.fitness_center,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          tr(context, 'no_workouts_yet'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr(context, 'log_your_first_workout'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ExerciseHistoryScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: Text(tr(context, 'log_workout')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Show only the 3 most recent logs
              final recentLogs = logs.take(3).toList();

              return Column(
                children: recentLogs
                    .map(
                      (log) => _buildWorkoutCard(
                        context,
                        log,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExerciseHistoryScreen(
                                exerciseId: log.exerciseId,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(
    BuildContext context,
    ExerciseLog log, {
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.exerciseName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: AppTheme.textColor(context).withAlpha(153),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(log.date),
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textColor(context).withAlpha(153),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.repeat,
                          size: 14,
                          color: AppTheme.textColor(context).withAlpha(153),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${log.sets.length} sets',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textColor(context).withAlpha(153),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (log.isPersonalRecord)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalRecords(BuildContext context) {
    final trackingService = ExerciseTrackingService();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'personal_records'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<PersonalRecord>>(
            future: trackingService.getAllPersonalRecords(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: LottieLoadingWidget(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(child: Text(tr(context, 'error_loading_data')));
              }

              final records = snapshot.data ?? [];

              if (records.isEmpty) {
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          tr(context, 'no_records_yet'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr(context, 'keep_training_to_achieve'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Group records by exercise and show just the top few
              final groupedRecords = <String, List<PersonalRecord>>{};
              for (var record in records) {
                if (!groupedRecords.containsKey(record.exerciseId)) {
                  groupedRecords[record.exerciseId] = [];
                }
                groupedRecords[record.exerciseId]!.add(record);
              }

              // Take just the first 3 exercises
              final topExerciseIds = groupedRecords.keys.take(3).toList();

              return Column(
                children: topExerciseIds.map((exerciseId) {
                  final recordsList = groupedRecords[exerciseId]!;
                  final exerciseName = recordsList.first.exerciseName;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exerciseName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...recordsList.map(
                            (record) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.emoji_events,
                                    size: 20,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      record.recordType,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Text(
                                    _formatRecordValue(record),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityOverview(BuildContext context) {
    final trackingService = ExerciseTrackingService();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'activity_overview'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<ExerciseLog>>(
            future: trackingService.getAllLogs(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: LottieLoadingWidget(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(child: Text(tr(context, 'error_loading_data')));
              }

              final logs = snapshot.data ?? [];

              if (logs.isEmpty) {
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.insights,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          tr(context, 'no_activity_data'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Calculate some basic stats
              final now = DateTime.now();
              final startOfWeek = DateTime(
                now.year,
                now.month,
                now.day,
              ).subtract(Duration(days: now.weekday - 1));
              final startOfMonth = DateTime(now.year, now.month, 1);

              final workoutsThisWeek = logs
                  .where((log) => log.date.isAfter(startOfWeek))
                  .length;
              final workoutsThisMonth = logs
                  .where((log) => log.date.isAfter(startOfMonth))
                  .length;
              final totalWorkouts = logs.length;

              // Get unique exercises
              final uniqueExercises = logs
                  .map((log) => log.exerciseId)
                  .toSet()
                  .length;

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildStatCard(
                            context,
                            tr(context, 'this_week'),
                            workoutsThisWeek.toString(),
                            Colors.green,
                            Icons.date_range,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            context,
                            tr(context, 'this_month'),
                            workoutsThisMonth.toString(),
                            Colors.blue,
                            Icons.calendar_month,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatCard(
                            context,
                            tr(context, 'total_workouts'),
                            totalWorkouts.toString(),
                            Colors.purple,
                            Icons.fitness_center,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            context,
                            tr(context, 'exercises'),
                            uniqueExercises.toString(),
                            Colors.orange,
                            Icons.category,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textColor(context).withAlpha(179),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
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
}
