import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';
import '../../../widgets/common/exercise_image.dart';
import '../../../services/exercise_tracking_service.dart'; // Import tracking service
import '../../exercise_history/log_exercise_screen.dart'; // Import log screen
import '../../exercise_history/exercise_history_screen.dart';
import 'models/workout_step.dart';
import 'package:logging/logging.dart';

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
  });

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  final Map<String, bool> _expandedSteps = {};
  final ExerciseTrackingService _trackingService = ExerciseTrackingService();

  @override
  void initState() {
    super.initState();
    log.info('Loading WorkoutDetailScreen with imagePath: ${widget.imagePath}');
    for (var step in widget.steps) {
      log.info('Step GIF: ${step.gifUrl}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: _buildContent(context),
          ),
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
                  colors: [
                    Colors.transparent,
                    AppTheme.surfaceColor(context),
                  ],
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
          child: Icon(
            Icons.arrow_back,
            color: AppTheme.textColor(context),
          ),
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
            child: Icon(
              Icons.history,
              color: AppTheme.textColor(context),
            ),
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
          _buildDescription(context),
          const SizedBox(height: 24),
          _buildWorkoutOverview(context),
          const SizedBox(height: 24),

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
                    backgroundColor: AppColors.primary,
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
            const Icon(
              Icons.star,
              color: Colors.amber,
              size: 20,
            ),
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
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.trending_up,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tr(context,
                                'tracked'), // or 'You\'re tracking this'
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
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
        _buildStatItem(context, Icons.local_fire_department,
            widget.caloriesBurn, 'Calories'),
        _buildStatItem(
            context, Icons.fitness_center, widget.difficulty, 'Level'),
      ],
    );
  }

  Widget _buildStatItem(
      BuildContext context, IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(26),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
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
              border: Border.all(
                color: AppColors.primary.withAlpha(26),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    step.isCompleted ? Icons.check : Icons.play_arrow,
                    color: AppColors.primary,
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
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            margin:
                const EdgeInsets.only(left: 36, right: 12, top: 8, bottom: 16),
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
                ...step.instructions.map((instruction) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(top: 6, right: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
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
                    )),
              ],
            ),
          ),
      ],
    );
  }

  // New method to log this exercise
  void _logExercise() async {
    // Generate an exercise ID (in a real app, you'd have actual IDs)
    final exerciseId = _generateExerciseId(widget.categoryTitle);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogExerciseScreen(
          exerciseId: exerciseId,
          initialExerciseName: widget.categoryTitle,
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
    // In a real app, you would use real IDs from your database
    // This is just a simple way to generate a consistent ID for demo purposes
    return name.toLowerCase().replaceAll(' ', '_');
  }

  // Get exercise history to check if user has logs for this exercise
  Future<List> _getExerciseHistory() async {
    final exerciseId = _generateExerciseId(widget.categoryTitle);
    return await _trackingService.getLogsForExercise(exerciseId);
  }
}
