import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/translation_helper.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/riverpod/unified_routine_provider.dart';
import '../../search/workout_detail/workout_detail_screen.dart';
import '../../routine/routine_main_screen.dart';
import '../../../screens/search/workout_detail/models/workout_item.dart';
import '../../../widgets/common/exercise_image.dart';
import 'package:logger/logger.dart';

/// Enhanced profile routine widget that shows actual exercises from active routines
class EnhancedProfileRoutineWidget extends ConsumerWidget {
  const EnhancedProfileRoutineWidget({super.key});
  
  static final Logger _logger = Logger();

  void _navigateToExerciseDetail(BuildContext context, WidgetRef ref, WorkoutItem exercise) {
    // Navigate to individual exercise detail
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutDetailScreen(
          categoryTitle: exercise.title,
          imagePath: exercise.image,
          duration: exercise.duration,
          difficulty: exercise.difficulty,
          steps: exercise.steps,
          description: exercise.description,
          rating: exercise.rating,
          caloriesBurn: exercise.caloriesBurn,
        ),
      ),
    ).then((_) {
      // Refresh routine data when coming back
      ref.read(unifiedRoutineProvider.notifier).refreshRoutineData();
    });
  }

  Widget _buildExercisePreview(List<Map<String, dynamic>> todaysExercises) {
    if (todaysExercises.isEmpty) return const SizedBox.shrink();

    // Show up to 3 exercises
    final displayExercises = todaysExercises.take(3).toList();
    
    return Column(
      children: [
        // Horizontal scrollable exercise images
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: displayExercises.length + (todaysExercises.length > 3 ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= displayExercises.length) {
                // Show "more" indicator
                return Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.more_horiz, color: Colors.blue[600]),
                      Text(
                        '+${todaysExercises.length - 3}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final exerciseData = displayExercises[index];
              final exercise = exerciseData['exercise'] as WorkoutItem;
              final status = exerciseData['status'] as String;
              
              return Container(
                width: 60,
                margin: const EdgeInsets.only(right: 8),
                child: Consumer(
                  builder: (context, ref, child) => GestureDetector(
                    onTap: () {
                      // Navigate to individual exercise detail
                      _navigateToExerciseDetail(context, ref, exercise);
                    },
                    child: _buildExerciseImage(exercise, status),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Recent exercise info with status
        if (displayExercises.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(displayExercises.first['status'] as String),
                  size: 14,
                  color: _getStatusColor(displayExercises.first['status'] as String),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${displayExercises.first['dayName']}: ${(displayExercises.first['exercise'] as WorkoutItem).title}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[600],
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: _getStatusColor(displayExercises.first['status'] as String).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusDisplayName(displayExercises.first['status'] as String),
                    style: TextStyle(
                      fontSize: 10,
                      color: _getStatusColor(displayExercises.first['status'] as String),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildExerciseImage(WorkoutItem exercise, String status) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: exercise.image.isNotEmpty 
            ? ExerciseImage(
                imageUrl: exercise.image,
                height: 60,
                width: 60,
                fit: BoxFit.cover,
              )
            : _buildFallbackExerciseImage(exercise.title),
        ),
        // Status indicator overlay
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: _getStatusColor(status),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(
              _getStatusIcon(status),
              size: 8,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackExerciseImage(String exerciseTitle) {
    return Container(
      height: 60,
      width: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.3),
            Colors.blue.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, color: Colors.blue[600], size: 20),
          const SizedBox(height: 2),
          Text(
            exerciseTitle.isNotEmpty ? exerciseTitle[0].toUpperCase() : 'E',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.play_circle_filled;
      case 'pending':
      default:
        return Icons.radio_button_unchecked;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'pending':
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'completed':
        return 'Done';
      case 'in_progress':
        return 'Active';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routineState = ref.watch(unifiedRoutineProvider);
    final todaysExercises = ref.watch(todaysExercisesWithStatusProvider);
    final exerciseCount = ref.watch(todaysExerciseCountProvider);
    final progressPercentage = ref.watch(todaysProgressProvider);
    final statusCounts = ref.watch(todaysStatusCountsProvider);
    final isRestDay = ref.watch(isRestDayProvider);

    // Debug logging
    _logger.d('EnhancedProfileRoutineWidget - exerciseCount: $exerciseCount');
    _logger.d('EnhancedProfileRoutineWidget - isRestDay: $isRestDay');
    _logger.d('EnhancedProfileRoutineWidget - progressPercentage: $progressPercentage');
    _logger.d('EnhancedProfileRoutineWidget - statusCounts: $statusCounts');
    
    if (routineState.isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.blue.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(context, 'todays_workout'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      if (!routineState.hasData) ...[
                        Text(
                          tr(context, 'no_active_routine'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue[600],
                          ),
                        ),
                      ] else if (isRestDay) ...[
                        Text(
                          tr(context, 'rest_day'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange[600],
                          ),
                        ),
                      ] else if (exerciseCount > 0) ...[
                        Text(
                          '$exerciseCount exercises • ${(progressPercentage * 100).toInt()}% complete',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue[600],
                          ),
                        ),
                      ] else ...[
                        Text(
                          tr(context, 'no_exercises_today'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RoutineMainScreen(),
                      ),
                    ).then((_) {
                      // Refresh routine data when coming back
                      ref.read(unifiedRoutineProvider.notifier).refreshRoutineData();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.blue[600],
                    ),
                  ),
                ),
              ],
            ),
            
            // Exercise preview section or action button
            if (!routineState.hasData) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RoutineMainScreen(),
                    ),
                  ).then((_) {
                    ref.read(unifiedRoutineProvider.notifier).refreshRoutineData();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline, color: Colors.blue[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Create Routine',
                        style: TextStyle(
                          color: Colors.blue[600], 
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (isRestDay) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.self_improvement, color: Colors.orange[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Today is your rest day. Take time to recover!',
                        style: TextStyle(
                          color: Colors.orange[600], 
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (exerciseCount > 0) ...[
              const SizedBox(height: 12),
              _buildExercisePreview(todaysExercises),
              if (statusCounts['completed']! > 0 || statusCounts['in_progress']! > 0) ...[
                const SizedBox(height: 8),
                // Progress bar
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progressPercentage,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progressPercentage > 0.7
                            ? Colors.green
                            : progressPercentage > 0.3
                            ? Colors.orange
                            : Colors.blue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Status summary
                Row(
                  children: [
                    if (statusCounts['completed']! > 0) ...[
                      Icon(Icons.check_circle, size: 12, color: Colors.green),
                      const SizedBox(width: 2),
                      Text(
                        '${statusCounts['completed']} done',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (statusCounts['in_progress']! > 0) ...[
                      if (statusCounts['completed']! > 0) const SizedBox(width: 8),
                      Icon(Icons.play_circle_filled, size: 12, color: Colors.orange),
                      const SizedBox(width: 2),
                      Text(
                        '${statusCounts['in_progress']} active',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (statusCounts['pending']! > 0) ...[
                      if (statusCounts['completed']! > 0 || statusCounts['in_progress']! > 0) 
                        const SizedBox(width: 8),
                      Icon(Icons.radio_button_unchecked, size: 12, color: Colors.grey),
                      const SizedBox(width: 2),
                      Text(
                        '${statusCounts['pending']} pending',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}