import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';
import '../../../widgets/common/exercise_image.dart';
import '../../../services/exercises/exercise_tracking_service.dart'; // Import tracking service
import '../../../services/exercises/exercise_routine_sync_service.dart';
import '../../../models/exercise/exercise_log.dart';
import '../../../models/user/personal_record.dart';
import '../../exercise_history/log_exercise_screen.dart'; // Import log screen
import '../../exercise_history/exercise_history_screen.dart';
import 'models/workout_step.dart';
import 'package:logging/logging.dart';
import 'package:intl/intl.dart';

final log = Logger('WorkoutDetailScreen');

class WorkoutDetailScreen extends StatefulWidget {
  final String categoryTitle;
  final String imagePath;
  final String duration;
  final String difficulty;
  final List<WorkoutStep> steps;
  final String description;
  final double rating;
  final String caloriesBurn;
  final String? routineId; // Optional routine context
  final String? dayName; // Optional day context

  const WorkoutDetailScreen({
    super.key,
    required this.categoryTitle,
    required this.imagePath,
    required this.duration,
    required this.difficulty,
    required this.steps,
    required this.description,
    required this.rating,
    required this.caloriesBurn,
    this.routineId,
    this.dayName,
  });

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  final Map<String, bool> _expandedSteps = {};
  final ExerciseTrackingService _trackingService = ExerciseTrackingService();
  final ExerciseRoutineSyncService _syncService = ExerciseRoutineSyncService();

  List<ExerciseLog> _recentLogs = [];
  List<PersonalRecord> _personalRecords = [];
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    log.info('Loading WorkoutDetailScreen with imagePath: ${widget.imagePath}');
    for (var step in widget.steps) {
      log.info('Step GIF: ${step.gifUrl}');
    }
    _loadExerciseData();
  }

  Future<void> _loadExerciseData() async {
    if (_isLoadingData) return;

    setState(() {
      _isLoadingData = true;
    });

    try {
      final exerciseId = _generateExerciseId(widget.categoryTitle);
      final logs = await _trackingService.getLogsForExercise(exerciseId);
      final records = await _syncService.getPersonalRecordsForExercise(
        exerciseId,
      );

      setState(() {
        _recentLogs = logs.take(3).toList();
        _personalRecords = records;
        _isLoadingData = false;
      });
    } catch (e) {
      log.severe('Error loading exercise data: $e');
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(child: _buildContent(context)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppTheme.surfaceColor(context),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            ExerciseImage(
              imageUrl: widget.imagePath,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppTheme.surfaceColor(context)],
                ),
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor(context).withAlpha(204),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      // Add action button for exercise history
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor(context).withAlpha(204),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history, color: AppTheme.textColor(context)),
          ),
          onPressed: () => _navigateToExerciseHistory(),
          tooltip: tr(context, 'view_exercise_history'),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildStats(context),
          const SizedBox(height: 24),
          _buildExerciseContext(),
          const SizedBox(height: 24),
          _buildDescription(context),
          const SizedBox(height: 24),
          _buildWorkoutOverview(context),
          const SizedBox(height: 24),

          // Smart logging section
          if (_personalRecords.isNotEmpty || _recentLogs.isNotEmpty) ...[
            _buildSmartLoggingSection(context),
            const SizedBox(height: 24),
          ],

          // New row with two buttons
          Row(
            children: [
              // Log Exercise Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _logExercise(),
                  icon: const Icon(Icons.add_chart),
                  label: Text(tr(context, 'log_exercise')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Start Workout Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Handle workout start
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: Text(tr(context, 'start_now')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.categoryTitle,
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 20),
            const SizedBox(width: 4),
            Text(
              widget.rating.toString(),
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),

            // Add Performance Badge if there are existing logs
            FutureBuilder(
              future: _getExerciseHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData &&
                    (snapshot.data as List).isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.trending_up,
                            size: 14,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tr(
                              context,
                              'tracked',
                            ), // or 'You\'re tracking this'
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStats(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(context, Icons.timer, widget.duration, 'Duration'),
        _buildStatItem(
          context,
          Icons.local_fire_department,
          widget.caloriesBurn,
          'Calories',
        ),
        _buildStatItem(
          context,
          Icons.fitness_center,
          widget.difficulty,
          'Level',
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withAlpha(26),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textColor(context).withAlpha(179),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseContext() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: widget.routineId != null
            ? AppTheme.primaryColor.withAlpha(26)
            : Colors.grey.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.routineId != null
              ? AppTheme.primaryColor.withAlpha(51)
              : Colors.grey.withAlpha(51),
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.routineId != null ? Icons.schedule : Icons.fitness_center,
            color: widget.routineId != null
                ? AppTheme.primaryColor
                : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.routineId != null
                      ? tr(context, 'part_of_routine')
                      : tr(context, 'standalone_exercise'),
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.routineId != null && widget.dayName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${tr(context, 'routine_day')}: ${tr(context, widget.dayName!.toLowerCase())}',
                    style: TextStyle(
                      color: AppTheme.textColor(context).withAlpha(179),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      widget.description,
      style: TextStyle(
        color: AppTheme.textColor(context).withAlpha(204),
        fontSize: 16,
        height: 1.5,
      ),
    );
  }

  Widget _buildWorkoutOverview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'workout_overview'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...widget.steps.map((step) => _buildWorkoutStep(context, step)),
      ],
    );
  }

  Widget _buildWorkoutStep(BuildContext context, WorkoutStep step) {
    bool isExpanded = _expandedSteps[step.title] ?? false;

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expandedSteps[step.title] = !isExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor.withAlpha(26)),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    step.isCompleted ? Icons.check : Icons.play_arrow,
                    color: AppTheme.primaryColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        step.duration,
                        style: TextStyle(
                          color: AppTheme.textColor(context).withAlpha(179),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            margin: const EdgeInsets.only(
              left: 36,
              right: 12,
              top: 8,
              bottom: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.description,
                  style: TextStyle(
                    color: AppTheme.textColor(context).withAlpha(204),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                if (step.gifUrl.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    height: 200,
                    child: ExerciseImage(
                      imageUrl: step.gifUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 12),
                ...step.instructions.map(
                  (instruction) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 6, right: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            instruction,
                            style: TextStyle(
                              color: AppTheme.textColor(context),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // New method to log this exercise
  void _logExercise() async {
    // For routine exercises, use the exercise title as ID to ensure proper completion tracking
    // For standalone exercises, use the generated ID
    final exerciseId = widget.routineId != null
        ? widget
              .categoryTitle // Use exact title for routine exercises
        : _generateExerciseId(
            widget.categoryTitle,
          ); // Use generated ID for standalone

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogExerciseScreen(
          exerciseId: exerciseId,
          initialExerciseName: widget.categoryTitle,
          routineId: widget.routineId, // Pass routine context
          dayName: widget.dayName, // Pass day context
        ),
      ),
    );
    if (result == true) {
      // Refresh UI after logging
      setState(() {});

      // Show a confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'exercise_logged_successfully')),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // If this was a routine exercise, notify parent to refresh
        if (widget.routineId != null) {
          // Small delay to ensure snackbar shows, then return to parent
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              Navigator.pop(
                context,
                true,
              ); // Return true to indicate exercise was logged
            }
          });
        }
      }
    }
  }

  // Navigate to exercise history for this exercise
  void _navigateToExerciseHistory() {
    final exerciseId = _generateExerciseId(widget.categoryTitle);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseHistoryScreen(
          exerciseId: exerciseId,
          initialTitle: widget.categoryTitle,
        ),
      ),
    );
  }

  // Generate a consistent ID from the exercise name
  String _generateExerciseId(String name) {
    // Use consistent ID format with dynamic duration service
    return name.hashCode.toString();
  }

  // Get exercise history to check if user has logs for this exercise
  Future<List> _getExerciseHistory() async {
    final exerciseId = _generateExerciseId(widget.categoryTitle);
    return await _trackingService.getLogsForExercise(exerciseId);
  }

  Widget _buildSmartLoggingSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withAlpha(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                tr(context, 'your_progress'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Personal Records Section
          if (_personalRecords.isNotEmpty) ...[
            Text(
              tr(context, 'personal_records'),
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: _personalRecords
                  .take(3)
                  .map(
                    (record) =>
                        Expanded(child: _buildPersonalRecordCard(record)),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Recent Workouts Section
          if (_recentLogs.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr(context, 'recent_workouts'),
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton(
                  onPressed: _navigateToExerciseHistory,
                  child: Text(
                    tr(context, 'view_all'),
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._recentLogs.map((log) => _buildRecentWorkoutItem(log)),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonalRecordCard(PersonalRecord record) {
    IconData icon;
    Color color;

    switch (record.recordType) {
      case 'Max Weight':
        icon = Icons.fitness_center;
        color = Colors.blue;
        break;
      case 'Max Reps':
        icon = Icons.repeat;
        color = Colors.green;
        break;
      case 'Total Volume':
        icon = Icons.trending_up;
        color = Colors.orange;
        break;
      default:
        icon = Icons.star;
        color = AppTheme.primaryColor;
    }

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            '${record.value.toStringAsFixed(record.recordType == 'Max Reps' ? 0 : 1)}${record.recordType.contains('Weight') || record.recordType.contains('Volume')
                ? 'kg'
                : record.recordType.contains('Distance')
                ? 'km'
                : ''}',
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            record.recordType,
            style: TextStyle(
              color: AppTheme.textColor(context).withAlpha(179),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentWorkoutItem(ExerciseLog log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withAlpha(13),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.fitness_center,
              color: AppTheme.primaryColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat.MMMd().format(log.date),
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${log.sets.length} sets • ${log.maxWeight.toStringAsFixed(1)}kg • ${log.sets.fold(0, (sum, set) => sum + set.reps)} reps',
                  style: TextStyle(
                    color: AppTheme.textColor(context).withAlpha(179),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (log.isPersonalRecord)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700), // Gold color
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'PR',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
