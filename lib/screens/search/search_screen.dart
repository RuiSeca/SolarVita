import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async'; // Kept for TimeoutException in ExerciseProvider
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../../providers/riverpod/exercise_provider.dart';
import 'workout_detail/workout_detail_screen.dart';
import 'workout_detail/workout_detail_type.dart' as detail_types;
import 'workout_detail/workout_list_screen.dart';
import 'workout_detail/models/workout_item.dart';
import '../../widgets/common/lottie_loading_widget.dart';


class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  bool _isSearching = false;
  String _searchQuery = '';
  bool _isLoadingExercises = false;
  String _loadingTarget = '';
  Timer? _timeoutTimer;

  // Flag to prevent automatic navigation during first build
  bool _isFirstBuild = true;

  @override
  void dispose() {
    // Cancel any ongoing loading operations when the screen is disposed
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  void deactivate() {
    // Cancel loading when navigating away from the screen
    super.deactivate();
  }

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
      }
    });
  }

  final List<Map<String, dynamic>> _workoutCategories = [
    {
      'titleKey': 'workout_strength',
      'mainImage': 'assets/images/search/strength_training/strength.webp',
      'smallImages': <String>[
        'assets/images/search/strength_training/strength-1.webp',
        'assets/images/search/strength_training/strength-2.webp',
      ],
      'count': '29+',
      'type': 'challenges',
      'workoutName': 'Dumbbell Bench Press',
      'workoutSmall': 'Leg Press'
    },
    {
      'titleKey': 'workout_abs',
      'mainImage': 'assets/images/search/abs_cardio/abs-1.webp',
      'smallImages': <String>[
        'assets/images/search/abs_cardio/abs-2.webp',
        'assets/images/search/abs_cardio/cardio.webp',
      ],
      'count': '20+',
      'type': 'challenges',
      'workoutName': 'Ab-Wheel Rollout',
      'workoutSmall': 'Rowing'
    },
    {
      'titleKey': 'workout_outdoor',
      'mainImage': 'assets/images/search/outdoor_activities/running.webp',
      'smallImages': <String>[
        'assets/images/search/outdoor_activities/running-1.webp',
        'assets/images/search/outdoor_activities/running-2.webp',
      ],
      'count': '32+',
      'type': 'workouts',
      'workoutName': 'Hiking',
      'workoutSmall': 'Sprinting'
    },
    {
      'titleKey': 'workout_yoga',
      'mainImage': 'assets/images/search/yoga_sessions/yoga.webp',
      'smallImages': <String>[
        'assets/images/search/yoga_sessions/yoga-1.webp',
        'assets/images/search/yoga_sessions/yoga-2.webp',
      ],
      'count': '27+',
      'type': 'activities',
      'workoutName': 'Sun Salutation',
      'workoutSmall': 'Stretching'
    },
    {
      'titleKey': 'workout_calisthenics',
      'mainImage': 'assets/images/search/calisthenics/calisthenics.webp',
      'smallImages': <String>[
        'assets/images/search/calisthenics/calisthenics-1.webp',
        'assets/images/search/calisthenics/calisthenics-2.webp',
      ],
      'count': '50+',
      'type': 'activities',
      'workoutName': 'Pull-ups',
      'workoutSmall': 'Crunch'
    },
    {
      'titleKey': 'workout_meditation',
      'mainImage': 'assets/images/search/meditation/meditation-2.webp',
      'smallImages': <String>[
        'assets/images/search/meditation/meditation-1.webp',
        'assets/images/search/meditation/meditation.webp',
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

  Future<void> _loadExercisesAndNavigate(
      detail_types.WorkoutDetailType type,
      String image,
      String titleKey,
      String title) async {
    // Block navigation during the initial build
    if (_isFirstBuild) {
      return;
    }

    final targetMuscle = _getTargetMuscle(titleKey);
    final provider = ref.read(exerciseNotifierProvider.notifier);
    final exerciseState = ref.read(exerciseNotifierProvider);
    
    // Prevent multiple simultaneous calls
    if (_isLoadingExercises || exerciseState.isLoading) {
      return;
    }

    // Check if we already have data for this target
    if (exerciseState.currentTarget == targetMuscle && exerciseState.hasData) {
      // Navigate immediately with cached data
      _performNavigation(type, title, image, targetMuscle, exerciseState.exercises!);
      return;
    }

    // Clear any previous error state
    provider.clearError();

    // Set loading state
    setState(() {
      _isLoadingExercises = true;
      _loadingTarget = targetMuscle;
    });

    // Add a timeout with more detailed handling
    bool timeoutOccurred = false;
    _timeoutTimer = Timer(const Duration(seconds: 12), () {
      timeoutOccurred = true;
      
      if (mounted) {
        setState(() {
          _isLoadingExercises = false;
          _loadingTarget = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loading timed out. Please try again.')),
        );
      }
    });

    try {
      await provider.loadExercisesByTarget(targetMuscle);

      // Cancel timeout timer
      _timeoutTimer?.cancel();

      // If timeout already occurred, don't proceed
      if (timeoutOccurred || !mounted) {
        return;
      }
      
      // Clear loading state
      setState(() {
        _isLoadingExercises = false;
        _loadingTarget = '';
      });

      final finalState = ref.read(exerciseNotifierProvider);
      
      if (finalState.hasError) {
        _showErrorMessage('Error loading exercises', finalState.errorMessage ?? 'Please try again later');
      } else if (!finalState.hasData || finalState.exercises == null || finalState.exercises!.isEmpty) {
        _showErrorMessage('No exercises found', 'Try a different category');
      } else {
        // Exercises loaded successfully, navigate immediately
        _performNavigation(type, title, image, targetMuscle, finalState.exercises!);
      }
    } catch (e) {
      // Cancel timeout timer
      _timeoutTimer?.cancel();

      if (mounted && !timeoutOccurred) {
        setState(() {
          _isLoadingExercises = false;
          _loadingTarget = '';
        });
        _showErrorMessage('Failed to load exercises', e.toString());
      }
    }
  }

  void _performNavigation(
    detail_types.WorkoutDetailType type,
    String title,
    String image,
    String targetMuscle,
    List<WorkoutItem> exercises,
  ) {
    if (!mounted) {
      return;
    }
    
    switch (type) {
      case detail_types.WorkoutDetailType.categoryList:
        _navigateToCategoryList(title, image, targetMuscle, exercises);
        break;
      case detail_types.WorkoutDetailType.specificExercise:
      case detail_types.WorkoutDetailType.alternateExercise:
        _navigateToSpecificExercise(exercises);
        break;
    }
  }

  void _showErrorMessage(String title, String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title: $message')),
    );
  }

  void _navigateToCategoryList(
    String title,
    String image,
    String targetMuscle,
    List<WorkoutItem> exercises,
  ) {
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
    List<WorkoutItem> exercises,
  ) {
    if (exercises.isEmpty) {
      _showErrorMessage('No exercises found', 'Try a different category');
      return;
    }

    final exercise = exercises.first;
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

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppBar(context),
            if (_isSearching) _buildSearchBar() else _buildTitle(context),

            // Show loading indicator when loading exercises
            if (_isLoadingExercises)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const LottieLoadingWidget(),
                      const SizedBox(height: 16),
                      Text(
                        'Loading exercises for $_loadingTarget...',
                        style: TextStyle(color: AppTheme.textColor(context)),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLoadingExercises = false;
                            _loadingTarget = '';
                          });
                        },
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final exerciseState = ref.watch(exerciseNotifierProvider);
                    
                    if (exerciseState.isLoading) {
                      return const Center(child: LottieLoadingWidget());
                    }

                    if (exerciseState.errorMessage != null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              exerciseState.errorMessage!,
                              style: TextStyle(
                                color: AppTheme.textColor(context),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                ref.read(exerciseNotifierProvider.notifier).clearExercises();
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
                            color: AppTheme.textColor(context),
                            fontSize: 16,
                          ),
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
                          smallImages:
                              List<String>.from(category['smallImages']),
                          count: tr(context, '${category['type']}_count')
                              .replaceAll('{count}', category['count']),
                          workoutName: category['workoutName'],
                          workoutSmall: category['workoutSmall'],
                          isFirstBuild: _isFirstBuild,
                          isLoading: _isLoadingExercises,
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
  final bool isLoading; // New parameter

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
    this.isLoading = false, // Default to false
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
                onTap: (isLoading || isFirstBuild)
                    ? null // Disable when loading
                    : () {
                        if (!isFirstBuild && searchScreenState != null) {
                          searchScreenState._loadExercisesAndNavigate(
                            detail_types.WorkoutDetailType.specificExercise,
                            mainImage,
                            titleKey,
                            title,
                          );
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
                          colorFilter: isLoading
                              ? ColorFilter.mode(
                                  Colors.black.withAlpha(153),
                                  BlendMode.darken,
                                )
                              : ColorFilter.mode(
                                  Colors.black.withAlpha(77),
                                  BlendMode.darken,
                                ),
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
                    if (isLoading)
                      Positioned.fill(
                        child: Center(
                          child: LottieLoadingWidget(),
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
                    onTap: (isLoading || isFirstBuild)
                        ? null // Disable when loading
                        : () {
                            if (!isFirstBuild && searchScreenState != null) {
                              searchScreenState._loadExercisesAndNavigate(
                                detail_types
                                    .WorkoutDetailType.alternateExercise,
                                smallImages[0],
                                titleKey,
                                title,
                              );
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
                              colorFilter: isLoading
                                  ? ColorFilter.mode(
                                      Colors.black.withAlpha(153),
                                      BlendMode.darken,
                                    )
                                  : ColorFilter.mode(
                                      Colors.black.withAlpha(77),
                                      BlendMode.darken,
                                    ),
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
                        if (isLoading)
                          Positioned.fill(
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: LottieLoadingWidget(
                                  width: 24,
                                  height: 24,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: (isLoading || isFirstBuild)
                        ? null // Disable when loading
                        : () {
                            if (!isFirstBuild && searchScreenState != null) {
                              searchScreenState._loadExercisesAndNavigate(
                                detail_types.WorkoutDetailType.categoryList,
                                smallImages[1],
                                titleKey,
                                title,
                              );
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
                              colorFilter: isLoading
                                  ? ColorFilter.mode(
                                      Colors.black.withAlpha(153),
                                      BlendMode.darken,
                                    )
                                  : null,
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
                        if (isLoading)
                          Positioned.fill(
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: LottieLoadingWidget(
                                  width: 24,
                                  height: 24,
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
