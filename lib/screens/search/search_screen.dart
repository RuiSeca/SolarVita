import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async'; // Kept for TimeoutException in ExerciseProvider
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../../providers/riverpod/exercise_provider.dart';
import '../../providers/riverpod/unified_routine_provider.dart';
import 'workout_detail/workout_detail_screen.dart';
import 'workout_detail/workout_detail_type.dart' as detail_types;
import 'workout_detail/workout_list_screen.dart';
import 'workout_detail/models/workout_item.dart';
import '../../widgets/common/lottie_loading_widget.dart';
import '../../widgets/common/oriented_image.dart';
import '../routine/routine_main_screen.dart';
import '../../providers/riverpod/scroll_controller_provider.dart';
import '../../services/health_alerts/pulse_color_manager.dart';


class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> with TickerProviderStateMixin {
  bool _isSearching = false;
  String _searchQuery = '';
  bool _isLoadingExercises = false;
  String _loadingTarget = '';
  Timer? _timeoutTimer;

  // Flag to prevent automatic navigation during first build
  bool _isFirstBuild = true;

  // Scroll controller for header synchronization
  ScrollController? _scrollController;
  bool _showFloatingButton = false;

  // Animation controller for ethereal glow effect
  late AnimationController _glowAnimationController;

  // Animation controllers for search morph transition
  late AnimationController _colorFadeController;
  late AnimationController _searchMorphController;

  // Focus node for search text field
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchTextController = TextEditingController();

  // Pulse color integration
  Color _currentPulseColor = const Color(0xFF4CAF50); // Default green

  @override
  void dispose() {
    // Cancel any ongoing loading operations when the screen is disposed
    _timeoutTimer?.cancel();
    _glowAnimationController.dispose();
    _colorFadeController.dispose();
    _searchMorphController.dispose();
    _searchFocusNode.dispose();
    _searchTextController.dispose();
    try {
      PulseColorManager.instance.removeListener(_onPulseColorChanged);
    } catch (e) {
      debugPrint('Error removing pulse color listener: $e');
    }
    // Don't dispose the controller - it's managed by the provider
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

    // Initialize animation controller for ethereal glow
    _glowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Initialize animation controller for color fade (2 seconds)
    _colorFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Initialize animation controller for search morph transition (300ms, starts after color fade)
    _searchMorphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Listen to pulse color changes
    _setupPulseColorListener();

    // Listen to search text changes
    _searchTextController.addListener(() {
      setState(() {
        _searchQuery = _searchTextController.text;
      });
    });

    // Use a post-frame callback to reset the flag after initial build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Get the scroll controller from the provider
        _scrollController = ref.read(scrollControllerNotifierProvider.notifier).getController('search');

        // Setup scroll listener for floating button
        _scrollController?.addListener(_onScroll);

        setState(() {
          _isFirstBuild = false;
        });
      }
    });
  }

  void _setupPulseColorListener() {
    try {
      final pulseManager = PulseColorManager.instance;
      pulseManager.addListener(_onPulseColorChanged);
      // Set initial color
      _currentPulseColor = pulseManager.currentColor;
    } catch (e) {
      debugPrint('Failed to setup pulse color listener: $e');
      // Fallback to default green
      _currentPulseColor = const Color(0xFF4CAF50);
    }
  }

  void _onPulseColorChanged() {
    try {
      final newColor = PulseColorManager.instance.currentColor;
      if (mounted && newColor != _currentPulseColor) {
        setState(() {
          _currentPulseColor = newColor;
        });
      }
    } catch (e) {
      debugPrint('Error updating routine button color: $e');
    }
  }

  void _onScroll() {
    // Show floating button when user scrolls down enough
    if (_scrollController != null) {
      final showButton = _scrollController!.offset > 100;
      if (showButton != _showFloatingButton) {
        setState(() {
          _showFloatingButton = showButton;
        });
      }
    }
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
      'workoutNameKey': 'Dumbbell Bench Press',
      'workoutSmallKey': 'Leg Press'
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
      'workoutNameKey': 'Ab-Wheel Rollout',
      'workoutSmallKey': 'Rowing'
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
      'workoutNameKey': 'Hiking',
      'workoutSmallKey': 'Sprinting'
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
      'workoutNameKey': 'Sun Salutation',
      'workoutSmallKey': 'Stretching'
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
      'workoutNameKey': 'Pull-ups',
      'workoutSmallKey': 'Crunch'
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
      'workoutNameKey': 'Mindful Breathing',
      'workoutSmallKey': 'Deep breathing'
    },
  ];

  List<Map<String, dynamic>> get filteredCategories {
    if (_searchQuery.isEmpty) return _workoutCategories;
    return _workoutCategories.where((category) {
      final title = tr(context, category['titleKey']).toLowerCase();
      final workoutName = tr(context, category['workoutNameKey']).toLowerCase();
      final workoutSmall = tr(context, category['workoutSmallKey']).toLowerCase();
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
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Custom SliverAppBar with disappearing header
              SliverAppBar(
                backgroundColor: AppTheme.surfaceColor(context),
                expandedHeight: 200.0,
                floating: false,
                pinned: false,
                elevation: 0,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: SafeArea(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildAppBar(context),
                          _buildRoutineButtonOrSearchBar(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Content
              if (_isLoadingExercises)
                SliverFillRemaining(
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
                SliverToBoxAdapter(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final exerciseState = ref.watch(exerciseNotifierProvider);
                      
                      if (exerciseState.isLoading) {
                        return const SizedBox(
                          height: 400,
                          child: Center(child: LottieLoadingWidget()),
                        );
                      }

                      if (exerciseState.errorMessage != null) {
                        return SizedBox(
                          height: 400,
                          child: Center(
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
                          ),
                        );
                      }

                      final categories = filteredCategories;
                      if (categories.isEmpty) {
                        return SizedBox(
                          height: 400,
                          child: Center(
                            child: Text(
                              tr(context, 'no_workouts_found'),
                              style: TextStyle(
                                color: AppTheme.textColor(context),
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            for (int index = 0; index < categories.length; index++) ...[
                              WorkoutCategoryCard(
                                title: tr(context, categories[index]['titleKey']),
                                titleKey: categories[index]['titleKey'],
                                mainImage: categories[index]['mainImage'],
                                smallImages: List<String>.from(categories[index]['smallImages']),
                                count: tr(context, '${categories[index]['type']}_count')
                                    .replaceAll('{count}', categories[index]['count']),
                                workoutName: tr(context, categories[index]['workoutNameKey']),
                                workoutSmall: tr(context, categories[index]['workoutSmallKey']),
                                isFirstBuild: _isFirstBuild,
                                isLoading: _isLoadingExercises,
                              ),
                              if (index < categories.length - 1) const SizedBox(height: 24),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
          
          // Floating routine button
          _buildFloatingRoutineButton(),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Text(
            tr(context, 'fitness_routines'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
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
                if (_isSearching) {
                  // Start color fade first (2s), then morph (300ms)
                  _colorFadeController.forward().then((_) {
                    if (mounted && _isSearching) {
                      _searchMorphController.forward();
                      Future.delayed(const Duration(milliseconds: 150), () {
                        if (mounted && _isSearching) {
                          _searchFocusNode.requestFocus();
                        }
                      });
                    }
                  });
                } else {
                  // Reverse morph first, then color fade
                  _searchMorphController.reverse().then((_) {
                    if (mounted && !_isSearching) {
                      _colorFadeController.reverse();
                    }
                  });
                  _searchQuery = '';
                  _searchTextController.clear();
                  _searchFocusNode.unfocus();
                }
              });
            },
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineButtonOrSearchBar() {
    final theme = Theme.of(context);
    final backgroundColor = _currentPulseColor;
    final isDarkMode = theme.brightness == Brightness.dark;
    final glassBase = isDarkMode ? Colors.white : Colors.black;
    final iconColor = isDarkMode ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SizedBox(
        width: double.infinity,
        child: AnimatedBuilder(
          animation: Listenable.merge([_glowAnimationController, _colorFadeController, _searchMorphController]),
          builder: (context, child) {
            final animValue = _glowAnimationController.value;
            final colorFadeValue = _colorFadeController.value;

            // Animated gradient positions for flowing liquid/steam effect
            final beginX = -1.5 + (animValue * 2.0);
            final beginY = -1.0 + (animValue * 0.8);

            // Fade out the glow during color fade (2s)
            final glowOpacity = 1.0 - colorFadeValue;

            return GestureDetector(
              onTap: _isSearching ? null : () => _navigateToRoutines(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    // Animated flowing green steam/liquid layer - fades out during color fade
                    if (glowOpacity > 0.01)
                      Positioned.fill(
                        child: Opacity(
                          opacity: glowOpacity,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment(
                                  beginX * 0.4,
                                  beginY * 0.35,
                                ),
                                radius: 0.8 + (animValue * 0.2),
                                colors: [
                                  backgroundColor.withValues(
                                      alpha: isDarkMode ? 0.3 + (animValue * 0.15) : 0.25 + (animValue * 0.1)),
                                  backgroundColor.withValues(
                                      alpha: isDarkMode ? 0.15 + (animValue * 0.1) : 0.12 + (animValue * 0.08)),
                                  backgroundColor.withValues(alpha: isDarkMode ? 0.08 : 0.06),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.4, 0.7, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Main button/text field with glass morphism
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        // Theme-adaptive glass morphism
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _isSearching
                              ? [
                                  glassBase.withValues(alpha: isDarkMode ? 0.15 : 0.04),
                                  glassBase.withValues(alpha: isDarkMode ? 0.06 : 0.02),
                                ]
                              : [
                                  glassBase.withValues(alpha: isDarkMode ? 0.2 : 0.06),
                                  glassBase.withValues(alpha: isDarkMode ? 0.08 : 0.03),
                                  backgroundColor.withValues(alpha: (isDarkMode ? 0.4 : 0.6) * glowOpacity),
                                  backgroundColor.withValues(alpha: (isDarkMode ? 0.6 : 0.8) * glowOpacity),
                                ],
                          stops: _isSearching ? null : const [0.0, 0.3, 0.7, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          // Pulse color border when in search mode
                          color: _isSearching
                              ? backgroundColor.withValues(
                                  alpha: (isDarkMode ? 0.4 : 0.3) * (1.0 - colorFadeValue + (animValue * 0.2)),
                                )
                              : glassBase.withValues(alpha: isDarkMode ? 0.3 : 0.1),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isDarkMode ? Colors.black : Colors.grey.shade400)
                                .withValues(alpha: isDarkMode ? 0.8 : 0.4),
                            blurRadius: 20,
                            offset: Offset(0, isDarkMode ? 6 : 8),
                          ),
                          if (isDarkMode)
                            BoxShadow(
                              color: glassBase.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, -3),
                            ),
                          // Color glow - fades out during color fade, but stays for search field
                          if (glowOpacity > 0.01 || _isSearching)
                            BoxShadow(
                              color: backgroundColor.withValues(
                                alpha: _isSearching
                                    ? (isDarkMode ? 0.15 + (animValue * 0.15) : 0.1 + (animValue * 0.1))
                                    : (isDarkMode ? 0.15 + (animValue * 0.25) : 0.1 + (animValue * 0.2)) *
                                        glowOpacity,
                              ),
                              blurRadius: _isSearching
                                  ? 15 + (animValue * 10)
                                  : (20 + (animValue * 15)) * glowOpacity,
                              offset: const Offset(0, 8),
                              spreadRadius: _isSearching ? -2 : (-4 + (animValue * 2)) * glowOpacity,
                            ),
                        ],
                      ),
                      child: _isSearching
                          ? Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _searchTextController,
                                    focusNode: _searchFocusNode,
                                    style: TextStyle(
                                      color: iconColor.withValues(alpha: 0.9),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: tr(context, 'search_workout'),
                                      hintStyle: TextStyle(
                                        color: iconColor.withValues(alpha: 0.5),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                                if (_searchQuery.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _searchTextController.clear();
                                        _searchQuery = '';
                                      });
                                    },
                                    child: Icon(
                                      Icons.close,
                                      color: iconColor.withValues(alpha: 0.7),
                                      size: 20,
                                    ),
                                  ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.schedule,
                                  color: iconColor.withValues(alpha: 0.9),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  tr(context, 'weekly_routines'),
                                  style: TextStyle(
                                    color: iconColor.withValues(alpha: 0.9),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }


  void _navigateToRoutines() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RoutineMainScreen(),
      ),
    ).then((_) {
      // Refresh routine provider when returning from routine screen
      ref.read(unifiedRoutineProvider.notifier).refreshRoutineData();
    });
  }


  Widget _buildFloatingRoutineButton() {
    final theme = Theme.of(context);
    // Use pulse color instead of static theme color
    final backgroundColor = _currentPulseColor;
    final isDarkMode = theme.brightness == Brightness.dark;

    // Theme-adaptive colors from fan menu FAB
    final glassBase = isDarkMode ? Colors.white : Colors.black;
    final iconColor = isDarkMode ? Colors.white : Colors.black;
    final shadowColor = isDarkMode ? Colors.black : Colors.grey.shade400;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      bottom: _showFloatingButton ? 110 : -80,
      right: 16,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _showFloatingButton ? 1.0 : 0.0,
        child: AnimatedBuilder(
          animation: _glowAnimationController,
          builder: (context, child) {
            // Animated gradient positions for subtle flowing liquid/steam effect
            final animValue = _glowAnimationController.value;
            final beginX = -1.5 + (animValue * 2.0);
            final beginY = -1.0 + (animValue * 0.8);

            return ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  // Animated flowing steam/liquid layer - MORE SUBTLE than weekly routine
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(
                            beginX * 0.3, // Reduced movement range for subtlety
                            beginY * 0.25,
                          ),
                          radius: 0.6 + (animValue * 0.15), // Smaller, softer radius
                          colors: [
                            // Much softer opacity for premium glassy effect
                            backgroundColor.withValues(alpha: isDarkMode ? 0.15 + (animValue * 0.08) : 0.12 + (animValue * 0.06)),
                            backgroundColor.withValues(alpha: isDarkMode ? 0.08 + (animValue * 0.05) : 0.06 + (animValue * 0.04)),
                            backgroundColor.withValues(alpha: isDarkMode ? 0.04 : 0.03),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.4, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Main button with glass morphism
                  Container(
                    decoration: BoxDecoration(
                      // Theme-adaptive glass morphism for floating button
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          // Glass effect with subtle color blend
                          glassBase.withValues(alpha: isDarkMode ? 0.2 : 0.06),
                          glassBase.withValues(alpha: isDarkMode ? 0.08 : 0.03),
                          backgroundColor.withValues(alpha: isDarkMode ? 0.4 : 0.6),
                          backgroundColor.withValues(alpha: isDarkMode ? 0.6 : 0.8),
                        ],
                        stops: const [0.0, 0.3, 0.7, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: glassBase.withValues(alpha: isDarkMode ? 0.3 : 0.1),
                        width: 1.5,
                      ),
                      boxShadow: [
                        // Main shadow - adaptive to theme
                        BoxShadow(
                          color: shadowColor.withValues(alpha: isDarkMode ? 0.8 : 0.4),
                          blurRadius: 20,
                          offset: Offset(0, isDarkMode ? 6 : 8),
                        ),
                        // Inner glow - more prominent in dark mode
                        if (isDarkMode) BoxShadow(
                          color: glassBase.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, -3),
                        ),
                        // Colored glow
                        BoxShadow(
                          color: backgroundColor.withValues(alpha: isDarkMode ? 0.2 : 0.15),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                          spreadRadius: -6,
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        // Subtle inner highlight
                        gradient: RadialGradient(
                          colors: [
                            glassBase.withValues(alpha: isDarkMode ? 0.25 : 0.08),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.85],
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(28),
                          onTap: _navigateToRoutines,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.schedule,
                                  color: iconColor.withValues(alpha: 0.9),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  tr(context, 'routines'),
                                  style: TextStyle(
                                    color: iconColor.withValues(alpha: 0.9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          OrientedImage(
                            imageUrl: mainImage,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 160,
                          ),
                          Container(
                            height: 160,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: isLoading
                                  ? Colors.black.withAlpha(153)
                                  : Colors.black.withAlpha(77),
                            ),
                          ),
                        ],
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
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              OrientedImage(
                                imageUrl: smallImages[0],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 80,
                              ),
                              Container(
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: isLoading
                                      ? Colors.black.withAlpha(153)
                                      : Colors.black.withAlpha(77),
                                ),
                              ),
                            ],
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
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              OrientedImage(
                                imageUrl: smallImages[1],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 70,
                              ),
                              if (isLoading)
                                Container(
                                  height: 70,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.black.withAlpha(153),
                                  ),
                                ),
                            ],
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
