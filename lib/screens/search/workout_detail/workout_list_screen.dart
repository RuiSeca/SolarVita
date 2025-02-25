import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';
import '../../../widgets/common/exercise_image.dart';
import 'workout_detail_screen.dart';
import 'models/workout_item.dart';
import 'package:logging/logging.dart';

final log = Logger('WorkoutListScreen');

class WorkoutListScreen extends StatelessWidget {
  final String categoryTitle;
  final String categoryImage;
  final String targetMuscle;
  final List<WorkoutItem> exercises;

  const WorkoutListScreen({
    super.key,
    required this.categoryTitle,
    required this.categoryImage,
    required this.targetMuscle,
    required this.exercises,
  });

  @override
  Widget build(BuildContext context) {
    log.info('Building WorkoutListScreen with ${exercises.length} exercises');
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildWorkoutCard(context, exercises[index]),
                childCount: exercises.length,
              ),
            ),
          ),
          // Add empty space at the bottom for better UX
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppTheme.surfaceColor(context),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Hero(
              tag: '${categoryTitle}_list',
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(categoryImage),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
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
        title: Text(
          categoryTitle,
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: AppTheme.textColor(context),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.info_outline,
            color: AppTheme.textColor(context),
          ),
          onPressed: () => _showInfoDialog(context),
        ),
      ],
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'about_exercises')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr(context, 'target_muscle_info')
                .replaceAll('{target}', targetMuscle)),
            const SizedBox(height: 12),
            Text(tr(context, 'exercises_count_info')
                .replaceAll('{count}', exercises.length.toString())),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr(context, 'close')),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(BuildContext context, WorkoutItem workout) {
    log.info('Rendering card for: ${workout.title}, image: ${workout.image}');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToDetail(context, workout),
        borderRadius: BorderRadius.circular(16),
        child: Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(16)),
                child: ExerciseImage(
                  imageUrl: workout.image,
                  width: 100,
                  height: 100,
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(16)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        workout.title,
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.timer,
                            size: 14,
                            color: AppTheme.textColor(context).withAlpha(179),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            workout.duration,
                            style: TextStyle(
                              color: AppTheme.textColor(context).withAlpha(179),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.fitness_center,
                            size: 14,
                            color: AppTheme.textColor(context).withAlpha(179),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            workout.difficulty,
                            style: TextStyle(
                              color: AppTheme.textColor(context).withAlpha(179),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      if (workout.equipment.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Equipment: ${workout.equipment.take(2).join(", ")}${workout.equipment.length > 2 ? ", ..." : ""}',
                          style: TextStyle(
                            color: AppTheme.textColor(context).withAlpha(179),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, WorkoutItem workout) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutDetailScreen(
          categoryTitle: workout.title,
          imagePath: workout.image,
          duration: workout.duration,
          difficulty: workout.difficulty,
          steps: workout.steps,
          description: workout.description,
          rating: workout.rating,
          caloriesBurn: workout.caloriesBurn,
        ),
      ),
    );
  }
}
