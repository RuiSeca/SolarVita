// lib/screens/search/workout_detail/workout_list_screen.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';
import 'workout_detail_screen.dart';
import 'models/workout_item.dart';

class WorkoutListScreen extends StatelessWidget {
  final String categoryTitle;
  final String categoryImage;
  final List<WorkoutItem> workouts;

  const WorkoutListScreen({
    super.key,
    required this.categoryTitle,
    required this.categoryImage,
    required this.workouts,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          _buildWorkoutList(context),
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
    );
  }

  Widget _buildWorkoutList(BuildContext context) {
    if (workouts.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            tr(context, 'no_workouts_available'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final workout = workouts[index];
            return _buildWorkoutCard(context, workout);
          },
          childCount: workouts.length,
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(BuildContext context, WorkoutItem workout) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
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
        },
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppTheme.cardColor(context),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
                child: Image.asset(
                  workout.image,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tr(context, workout.title),
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.timer,
                            size: 16,
                            color: AppTheme.textColor(context).withAlpha(179),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            workout.duration,
                            style: TextStyle(
                              color: AppTheme.textColor(context).withAlpha(179),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.fitness_center,
                            size: 16,
                            color: AppTheme.textColor(context).withAlpha(179),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tr(context, workout.difficulty.toLowerCase()),
                            style: TextStyle(
                              color: AppTheme.textColor(context).withAlpha(179),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
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
}
