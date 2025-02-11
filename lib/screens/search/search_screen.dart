import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:solar_vitas/utils/translation_helper.dart';
import 'workout_detail/workout_detail_screen.dart';
import 'workout_detail/workout_detail_type.dart' as detail_types;
import 'workout_detail/workout_list_screen.dart';
import 'workout_detail/workout_data.dart';
import 'workout_detail/models/workout_step.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppBar(context),
            _buildTitle(context),
            _buildWorkoutList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.eco,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                tr(context, 'app_name'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.search, color: AppTheme.textColor(context)),
            onPressed: () {},
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Text(
        tr(context, 'fitness_routines'),
        style: TextStyle(
          color: AppTheme.textColor(context),
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildWorkoutList(BuildContext context) {
    final List<Map<String, dynamic>> workoutCategories = [
      {
        'titleKey': 'workout_strength',
        'mainImage': 'assets/images/search/strength_training/strength.jpg',
        'smallImages': <String>[
          'assets/images/search/strength_training/strength-1.jpg',
          'assets/images/search/strength_training/strength-2.jpg',
        ],
        'count': '29+',
        'type': 'challenges'
      },
      {
        'titleKey': 'workout_abs',
        'mainImage': 'assets/images/search/abs_cardio/abs-1.jpg',
        'smallImages': <String>[
          'assets/images/search/abs_cardio/abs-2.jpg',
          'assets/images/search/abs_cardio/cardio.jpg',
        ],
        'count': '20+',
        'type': 'challenges'
      },
      {
        'titleKey': 'workout_outdoor',
        'mainImage': 'assets/images/search/outdoor_activities/running.jpg',
        'smallImages': <String>[
          'assets/images/search/outdoor_activities/running-1.jpg',
          'assets/images/search/outdoor_activities/running-2.jpg',
        ],
        'count': '32+',
        'type': 'workouts'
      },
      {
        'titleKey': 'workout_yoga',
        'mainImage': 'assets/images/search/yoga_sessions/yoga.jpg',
        'smallImages': <String>[
          'assets/images/search/yoga_sessions/yoga-1.jpg',
          'assets/images/search/yoga_sessions/yoga-2.jpg',
        ],
        'count': '27+',
        'type': 'activities'
      },
      {
        'titleKey': 'workout_calisthenics',
        'mainImage': 'assets/images/search/calisthenics/calisthenics.jpg',
        'smallImages': <String>[
          'assets/images/search/calisthenics/calisthenics-1.jpg',
          'assets/images/search/calisthenics/calisthenics-2.jpg',
        ],
        'count': '50+',
        'type': 'activities'
      },
      {
        'titleKey': 'workout_meditation',
        'mainImage': 'assets/images/search/meditation/meditation-2.jpg',
        'smallImages': <String>[
          'assets/images/search/meditation/meditation-1.jpg',
          'assets/images/search/meditation/meditation.jpg',
        ],
        'count': '13+',
        'type': 'challenges'
      },
    ];

    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: workoutCategories.length,
        separatorBuilder: (context, index) => const SizedBox(height: 24),
        itemBuilder: (context, index) {
          final category = workoutCategories[index];
          return WorkoutCategoryCard(
            title: tr(context, category['titleKey'] as String),
            titleKey: category['titleKey'] as String, // Add this line
            mainImage: category['mainImage'] as String,
            smallImages: (category['smallImages'] as List).cast<String>(),
            count: tr(
              context,
              '${category['type'] as String}_count',
            ).replaceAll('{count}', category['count'] as String),
          );
        },
      ),
    );
  }
}

class WorkoutCategoryCard extends StatelessWidget {
  final String title;
  final String titleKey; // Add this field
  final String mainImage;
  final List<String> smallImages;
  final String count;
  final List<String> workoutSteps;

  const WorkoutCategoryCard({
    super.key,
    required this.title,
    required this.titleKey, // Add this parameter
    required this.mainImage,
    required this.smallImages,
    required this.count,
    this.workoutSteps = const [
      'warm_up',
      'cardio_session',
      'strength_training',
      'core_workout',
      'flexibility_exercise',
      'cool_down',
      'nutrition_tips',
      'hydration_importance',
      'mindfulness_practice',
    ],
  });

  void _navigateToDetail(
      BuildContext context, detail_types.WorkoutDetailType type, String image) {
    if (type == detail_types.WorkoutDetailType.categoryList) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkoutListScreen(
            categoryTitle: title,
            categoryImage: image,
            workouts: categoryWorkouts[titleKey] ?? [],
          ),
        ),
      );
    } else {
      // Create a sample WorkoutStep for initial navigation
      final defaultStep = WorkoutStep(
        title: 'Sample Step',
        duration: '5 min',
        description: 'Sample description',
        instructions: ['Step 1', 'Step 2'],
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkoutDetailScreen(
            categoryTitle: title,
            imagePath: image,
            duration: '30 min',
            difficulty: 'Medium',
            steps: [defaultStep],
            description: 'Sample workout description',
            rating: 4.5,
            caloriesBurn: '300 kcal',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () => _navigateToDetail(
                  context,
                  detail_types.WorkoutDetailType.specificExercise,
                  mainImage,
                ),
                child: Hero(
                  tag: '${title}_specificExercise',
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: AssetImage(mainImage),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _navigateToDetail(
                      context,
                      detail_types.WorkoutDetailType.alternateExercise,
                      smallImages[0],
                    ),
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: AssetImage(smallImages[0]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _navigateToDetail(
                      context,
                      detail_types.WorkoutDetailType.categoryList,
                      smallImages[1],
                    ),
                    child: Stack(
                      children: [
                        Container(
                          height: 70,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: AssetImage(smallImages[1]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Container(
                          height: 70,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [
                                Colors.black54,
                                Colors.black26,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 8,
                          right: 8,
                          child: Center(
                            child: Text(
                              count,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
