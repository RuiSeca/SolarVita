// lib/screens/exercise_history/exercise_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/exercise/exercise_log.dart';
import '../../services/exercises/exercise_tracking_service.dart';
import '../../utils/translation_helper.dart';
import 'log_exercise_screen.dart';

class ExerciseDetailHistoryScreen extends StatelessWidget {
  final ExerciseLog log;

  const ExerciseDetailHistoryScreen({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(log.exerciseName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LogExerciseScreen(
                    exerciseId: log.exerciseId,
                    existingLog: log,
                  ),
                ),
              );

              if (result == true && context.mounted) {
                Navigator.pop(context, true); // Refresh parent screen
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header info card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat.yMMMMd().format(log.date),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat.jm().format(log.date),
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withAlpha(179),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.fitness_center,
                              size: 20,
                              color: theme.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${log.totalVolume.toStringAsFixed(0)} kg',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${log.sets.length} ${tr(context, 'sets')}',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodyMedium?.color?.withAlpha(
                              179,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sets section
            Text(
              tr(context, 'sets'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Sets list
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Table header
                    Row(
                      children: [
                        SizedBox(
                          width: 50,
                          child: Text(
                            tr(context, 'set'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            tr(context, 'weight'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            tr(context, 'reps'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                        ),
                        if (log.sets.any((s) => s.distance != null))
                          Expanded(
                            child: Text(
                              tr(context, 'distance'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            ),
                          ),
                        if (log.sets.any((s) => s.duration != null))
                          Expanded(
                            child: Text(
                              tr(context, 'time'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Divider(),

                    // Set rows
                    ...log.sets.map(
                      (set) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 50,
                              child: Text(
                                '${set.setNumber}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(child: Text('${set.weight} kg')),
                            Expanded(child: Text('${set.reps}')),
                            if (log.sets.any((s) => s.distance != null))
                              Expanded(
                                child: Text(
                                  set.distance != null
                                      ? '${set.distance} km'
                                      : '-',
                                ),
                              ),
                            if (log.sets.any((s) => s.duration != null))
                              Expanded(
                                child: Text(
                                  set.duration != null
                                      ? _formatDuration(set.duration!)
                                      : '-',
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Notes section
            if (log.notes.isNotEmpty) ...[
              Text(
                tr(context, 'notes'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(log.notes, style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Stats section
            Text(
              tr(context, 'stats'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatRow(
                      context,
                      tr(context, 'total_volume'),
                      '${log.totalVolume.toStringAsFixed(0)} kg',
                      Icons.fitness_center,
                    ),
                    const Divider(),
                    _buildStatRow(
                      context,
                      tr(context, 'max_weight'),
                      '${log.maxWeight.toStringAsFixed(1)} kg',
                      Icons.trending_up,
                    ),
                    const Divider(),
                    _buildStatRow(
                      context,
                      tr(context, 'sets_completed'),
                      '${log.sets.length}',
                      Icons.repeat,
                    ),
                    const Divider(),
                    _buildStatRow(
                      context,
                      tr(context, 'total_reps'),
                      '${log.sets.fold(0, (sum, set) => sum + set.reps)}',
                      Icons.tag,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'delete_log')),
        content: Text(tr(context, 'delete_log_confirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr(context, 'cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              tr(context, 'delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final service = ExerciseTrackingService();
      final success = await service.deleteLog(log.id);

      if (success && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tr(context, 'log_deleted'))));
        Navigator.pop(context, true); // Refresh parent screen
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(context, 'error_deleting_log'))),
        );
      }
    }
  }
}
