import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // Kept for TimeoutException in ExerciseProvider
import 'package:logging/logging.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../../providers/exercise_provider.dart';
import 'workout_detail/workout_detail_screen.dart';
import 'workout_detail/workout_detail_type.dart' as detail_types;
import 'workout_detail/workout_list_screen.dart';
import 'workout_detail/models/workout_item.dart';

final logger = Logger('SearchScreen');

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  bool _isSearching = false;
  String _searchQuery = '';
  // Flag to prevent automatic navigation during first build
  bool _isFirstBuild = true;

  @override
  void initState() {
    super.initState();
    _isFirstBuild = true;

    // Use a post-frame callback to reset the flag after initial build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isFirstBuild = false;
        });
        logger.info(
            "SearchScreen initial build completed, navigation now enabled");
      }
    });
  }

  final List<Map<String, dynamic>> _workoutCategories = [
    {
      'titleKey': 'workout_strength',
      'mainImage': 'assets/images/search/strength_training/strength.jpg',
      'smallImages': <String>[
        'assets/images/search/strength_training/strength-1.jpg',
        'assets/images/search/strength_training/strength-2.jpg',
      ],
      'count': '29+',
      'type': 'challenges',
      'workoutName': 'Dumbbell Bench Press',
      'workoutSmall': 'Leg Press'
    },
    {
      'titleKey': 'workout_abs',
      'mainImage': 'assets/images/search/abs_cardio/abs-1.jpg',
      'smallImages': <String>[
        'assets/images/search/abs_cardio/abs-2.jpg',
        'assets/images/search/abs_cardio/cardio.jpg',
      ],
      'count': '20+',
      'type': 'challenges',
      'workoutName': 'Ab-Wheel Rollout',
      'workoutSmall': 'Rowing'
    },
    {
      'titleKey': 'workout_outdoor',
      'mainImage': 'assets/images/search/outdoor_activities/running.jpg',
      'smallImages': <String>[
        'assets/images/search/outdoor_activities/running-1.jpg',
        'assets/images/search/outdoor_activities/running-2.jpg',
      ],
      'count': '32+',
      'type': 'workouts',
      'workoutName': 'Hiking',
      'workoutSmall': 'Sprinting'
    },
    {
      'titleKey': 'workout_yoga',
      'mainImage': 'assets/images/search/yoga_sessions/yoga.jpg',
      'smallImages': <String>[
        'assets/images/search/yoga_sessions/yoga-1.jpg',
        'assets/images/search/yoga_sessions/yoga-2.jpg',
      ],
      'count': '27+',
      'type': 'activities',
      'workoutName': 'Sun Salutation',
      'workoutSmall': 'Stretching'
    },
    {
      'titleKey': 'workout_calisthenics',
      'mainImage': 'assets/images/search/calisthenics/calisthenics.jpg',
      'smallImages': <String>[
        'assets/images/search/calisthenics/calisthenics-1.jpg',
        'assets/images/search/calisthenics/calisthenics-2.jpg',
      ],
      'count': '50+',
      'type': 'activities',
      'workoutName': 'Pull-ups',
      'workoutSmall': 'Crunch'
    },
    {
      'titleKey': 'workout_meditation',
      'mainImage': 'assets/images/search/meditation/meditation-2.jpg',
      'smallImages': <String>[
        'assets/images/search/meditation/meditation-1.jpg',
        'assets/images/search/meditation/meditation.jpg',
      ],
      'count': '13+',
      'type': 'challenges',
      'workoutName': 'Mindful Breathing',
      'workoutSmall': 'Deep breathing'
    },
  ];

  List<Map<String, dynamic>> get filteredCategories {
    if (_searchQuery.isEmpty) return _workoutCategories;
    return _workoutCategories.where((category) {
      final title = tr(context, category['titleKey']).toLowerCase();
      final workoutName = category['workoutName'].toString().toLowerCase();
      final workoutSmall = category['workoutSmall'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query) ||
          workoutName.contains(query) ||
          workoutSmall.contains(query);
    }).toList();
  }

  Future<void> _navigateToDetail(
      BuildContext context,
      detail_types.WorkoutDetailType type,
      String image,
      String titleKey,
      String title) async {
    // Debug logging
    logger.info("_navigateToDetail called for $titleKey (type: $type)");

    // Block navigation during the initial build
    if (_isFirstBuild) {
      logger.info("Blocking automatic navigation attempt during initial build");
      return;
    }

    // Ensure the context is still mounted
    if (!context.mounted) return;

    final provider = Provider.of<ExerciseProvider>(context, listen: false);
    final targetMuscle = _getTargetMuscle(titleKey);

    logger.info("Loading exercises for target muscle: $targetMuscle");

    // Show loading dialog with cancellation option
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false, // Prevent back button closing
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(
                child: Text(tr(context, 'loading_exercises')),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                logger.info("User cancelled loading operation");
                Navigator.of(dialogContext).pop();
              },
              child: Text(tr(context, 'cancel')),
            ),
          ],
        ),
      ),
    );

    try {
      await provider.loadExercisesByTarget(targetMuscle);

      // Check if context is still valid
      if (!context.mounted) return;

      // Dismiss the loading dialog
      _dismissLoadingDialog(context);

      if (provider.hasError) {
        logger.severe("Provider returned error: ${provider.errorMessage}");
        _showErrorDialog(
          context,
          provider.errorMessage ?? 'Error loading exercises',
          provider.errorDetails ?? 'Please try again later',
          () => provider.retryCurrentTarget(),
        );
      } else if (!provider.hasData) {
        logger.info("Provider has no data");
        _showErrorDialog(
          context,
          tr(context, 'no_exercises_found'),
          tr(context, 'try_different_category'),
          null,
        );
      } else {
        logger.info(
            "Successfully loaded ${provider.exercises?.length} exercises");
        // Navigate based on workout type
        switch (type) {
          case detail_types.WorkoutDetailType.categoryList:
            _navigateToCategoryList(
                context, title, image, targetMuscle, provider.exercises!);
            break;
          case detail_types.WorkoutDetailType.specificExercise:
          case detail_types.WorkoutDetailType.alternateExercise:
            _navigateToSpecificExercise(context, provider.exercises!);
            break;
        }
      }
    } catch (e) {
      logger.severe("Exception during exercise loading: $e");
      if (context.mounted) {
        _dismissLoadingDialog(context);
        _showErrorSnackBar(context, 'Unexpected error: $e');
      }
    }
  }

  void _dismissLoadingDialog(BuildContext context) {
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _navigateToCategoryList(
    BuildContext context,
    String title,
    String image,
    String targetMuscle,
    List<WorkoutItem> exercises,
  ) {
    logger.info("Navigating to category list: $title");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutListScreen(
          categoryTitle: title,
          categoryImage: image,
          targetMuscle: targetMuscle,
          exercises: exercises,
        ),
      ),
    );
  }

  void _navigateToSpecificExercise(
    BuildContext context,
    List<WorkoutItem> exercises,
  ) {
    if (exercises.isEmpty) {
      logger
          .info("Cannot navigate to specific exercise: no exercises available");
      _showErrorSnackBar(context, tr(context, 'no_exercises_found'));
      return;
    }

    final exercise = exercises.first;
    logger.info("Navigating to specific exercise: ${exercise.title}");
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
    );
  }

  void _showErrorDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback? onRetry,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: Text(tr(context, 'close')),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onRetry();
              },
              child: Text(tr(context, 'retry')),
            ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: tr(context, 'dismiss'),
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  String _getTargetMuscle(String categoryKey) {
    switch (categoryKey) {
      case 'workout_strength':
        return 'pectorals';
      case 'workout_abs':
        return 'abs';
      case 'workout_outdoor':
        return 'cardio'; // Valid approximation
      case 'workout_yoga':
        return 'traps'; // Closest match, adjust as needed
      case 'workout_calisthenics':
        return 'biceps';
      case 'workout_meditation':
        return 'spine'; // No direct match, consider 'back' or skip
      default:
        return 'pectorals';
    }
  }

  @override
  Widget build(BuildContext context) {
    logger.info("Building SearchScreen (isFirstBuild: $_isFirstBuild)");

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppBar(context),
            if (_isSearching) _buildSearchBar() else _buildTitle(context),
            Expanded(
              child: Consumer<ExerciseProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            provider.errorMessage!,
                            style: TextStyle(
                                color: AppTheme.textColor(context),
                                fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              provider.clearExercises();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final categories = filteredCategories;
                  if (categories.isEmpty) {
                    return Center(
                      child: Text(
                        tr(context, 'no_workouts_found'),
                        style: TextStyle(
                            color: AppTheme.textColor(context), fontSize: 16),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: categories.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 24),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return WorkoutCategoryCard(
                        title: tr(context, category['titleKey']),
                        titleKey: category['titleKey'],
                        mainImage: category['mainImage'],
                        smallImages: List<String>.from(category['smallImages']),
                        count: tr(context, '${category['type']}_count')
                            .replaceAll('{count}', category['count']),
                        workoutName: category['workoutName'],
                        workoutSmall: category['workoutSmall'],
                        isFirstBuild: _isFirstBuild,
                      );
                    },
                  );
                },
              ),
            ),
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
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: AppTheme.textColor(context),
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchQuery = '';
              });
            },
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: tr(context, 'search_workout'),
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
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
}

class WorkoutCategoryCard extends StatelessWidget {
  final String title;
  final String titleKey;
  final String mainImage;
  final List<String> smallImages;
  final String count;
  final String workoutName;
  final String workoutSmall;
  final bool isFirstBuild;

  const WorkoutCategoryCard({
    super.key,
    required this.title,
    required this.titleKey,
    required this.mainImage,
    required this.smallImages,
    required this.count,
    required this.workoutName,
    required this.workoutSmall,
    required this.isFirstBuild,
  });

  @override
  Widget build(BuildContext context) {
    final searchScreenState =
        context.findAncestorStateOfType<_SearchScreenState>();
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
                onTap: () {
                  logger.info(
                      "Main card tapped: $titleKey for specific exercise");
                  if (!isFirstBuild && searchScreenState != null) {
                    searchScreenState._navigateToDetail(
                      context,
                      detail_types.WorkoutDetailType.specificExercise,
                      mainImage,
                      titleKey,
                      title,
                    );
                  } else {
                    logger.info("Ignoring tap during first build");
                  }
                },
                child: Stack(
                  children: [
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: AssetImage(mainImage),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(153),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          workoutName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      logger.info(
                          "Small card tapped: $titleKey for alternate exercise");
                      if (!isFirstBuild && searchScreenState != null) {
                        searchScreenState._navigateToDetail(
                          context,
                          detail_types.WorkoutDetailType.alternateExercise,
                          smallImages[0],
                          titleKey,
                          title,
                        );
                      } else {
                        logger.info("Ignoring tap during first build");
                      }
                    },
                    child: Stack(
                      children: [
                        Container(
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: AssetImage(smallImages[0]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(153),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              workoutSmall,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      logger.info(
                          "Category card tapped: $titleKey for category list");
                      if (!isFirstBuild && searchScreenState != null) {
                        searchScreenState._navigateToDetail(
                          context,
                          detail_types.WorkoutDetailType.categoryList,
                          smallImages[1],
                          titleKey,
                          title,
                        );
                      } else {
                        logger.info("Ignoring tap during first build");
                      }
                    },
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
                              colors: [Colors.black54, Colors.black26],
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
