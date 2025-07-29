import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../../models/workout_routine.dart';
import '../../providers/riverpod/exercise_provider.dart';
import '../../screens/search/workout_detail/models/workout_item.dart';
import '../../widgets/common/lottie_loading_widget.dart';
import '../../widgets/common/exercise_image.dart';
import 'routine_main_screen.dart';

class ExerciseSelectionScreen extends ConsumerStatefulWidget {
  final WorkoutRoutine routine;
  final String dayName;

  const ExerciseSelectionScreen({
    super.key,
    required this.routine,
    required this.dayName,
  });

  @override
  ConsumerState<ExerciseSelectionScreen> createState() =>
      _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState
    extends ConsumerState<ExerciseSelectionScreen> {
  String _selectedMuscleGroup = 'pectorals';
  bool _isLoading = false;
  final Set<String> _selectedExercises = {};

  final Map<String, String> _muscleGroups = {
    'pectorals': 'Chest',
    'biceps': 'Biceps',
    'triceps': 'Triceps',
    'abs': 'Abs',
    'quads': 'Quadriceps',
    'hamstrings': 'Hamstrings',
    'glutes': 'Glutes',
    'calves': 'Calves',
    'lats': 'Lats',
    'traps': 'Traps',
    'delts': 'Shoulders',
    'forearms': 'Forearms',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExercises();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        title: Text(
          tr(context, 'add_exercises'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_selectedExercises.isNotEmpty)
            TextButton(
              onPressed: _isLoading ? null : _addSelectedExercises,
              child: Text(
                '${tr(context, 'add')} (${_selectedExercises.length})',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildMuscleGroupSelector(),
          Expanded(child: _buildExerciseList()),
        ],
      ),
      floatingActionButton: _selectedExercises.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isLoading ? null : _addSelectedExercises,
              backgroundColor: AppTheme.primaryColor,
              icon: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.add, color: Colors.white),
              label: Text(
                '${tr(context, 'add')} ${_selectedExercises.length}',
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildMuscleGroupSelector() {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              tr(context, 'muscle_groups'),
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _muscleGroups.length,
              itemBuilder: (context, index) {
                final muscleGroup = _muscleGroups.keys.elementAt(index);
                final displayName = _muscleGroups[muscleGroup]!;
                final isSelected = _selectedMuscleGroup == muscleGroup;

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FilterChip(
                    label: Text(displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedMuscleGroup = muscleGroup;
                        _selectedExercises.clear();
                      });
                      _loadExercises();
                    },
                    selectedColor: AppTheme.primaryColor.withAlpha(51),
                    checkmarkColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textColor(context),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textColor(context).withAlpha(51),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList() {
    return Consumer(
      builder: (context, ref, child) {
        final exerciseState = ref.watch(exerciseNotifierProvider);

        if (exerciseState.isLoading) {
          return const Center(child: LottieLoadingWidget());
        }

        if (exerciseState.hasError) {
          return _buildErrorState(
            exerciseState.errorMessage ?? 'Unknown error',
          );
        }

        if (!exerciseState.hasData ||
            exerciseState.exercises?.isEmpty == true) {
          return _buildEmptyState();
        }

        final exercises = exerciseState.exercises!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: exercises.length,
          itemBuilder: (context, index) {
            final exercise = exercises[index];
            final isSelected = _selectedExercises.contains(exercise.title);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildExerciseCard(exercise, isSelected),
            );
          },
        );
      },
    );
  }

  Widget _buildExerciseCard(WorkoutItem exercise, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedExercises.remove(exercise.title);
          } else {
            _selectedExercises.add(exercise.title);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withAlpha(26)
              : AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.primaryColor.withAlpha(26),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ExerciseImage(
                imageUrl: exercise.image,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.title,
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.timer, color: AppTheme.primaryColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        exercise.duration,
                        style: TextStyle(
                          color: AppTheme.textColor(context).withAlpha(179),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.fitness_center,
                        color: AppTheme.primaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        exercise.difficulty,
                        style: TextStyle(
                          color: AppTheme.textColor(context).withAlpha(179),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        exercise.caloriesBurn,
                        style: TextStyle(
                          color: AppTheme.textColor(context).withAlpha(179),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        exercise.rating.toString(),
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
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textColor(context).withAlpha(102),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.textColor(context).withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text(
            tr(context, 'error_loading_exercises'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: AppTheme.textColor(context).withAlpha(179),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadExercises(),
            child: Text(tr(context, 'retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: AppTheme.textColor(context).withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text(
            tr(context, 'no_exercises_found'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr(context, 'try_different_muscle_group'),
            style: TextStyle(
              color: AppTheme.textColor(context).withAlpha(179),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _loadExercises() async {
    final provider = ref.read(exerciseNotifierProvider.notifier);
    await provider.loadExercisesByTarget(_selectedMuscleGroup);
  }

  void _addSelectedExercises() async {
    if (_selectedExercises.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final exerciseState = ref.read(exerciseNotifierProvider);
      if (!exerciseState.hasData) {
        throw Exception('No exercises loaded');
      }

      final allExercises = exerciseState.exercises!;
      final exercisesToAdd = allExercises
          .where((exercise) => _selectedExercises.contains(exercise.title))
          .toList();

      final service = ref.read(routineServiceProvider);
      WorkoutRoutine updatedRoutine = widget.routine;

      // Add each selected exercise to the day
      for (final exercise in exercisesToAdd) {
        final updatedManager = await service.addExerciseToDay(
          updatedRoutine.id,
          widget.dayName,
          exercise,
        );
        updatedRoutine = updatedManager.routines.firstWhere(
          (r) => r.id == widget.routine.id,
        );
      }

      if (mounted) {
        Navigator.pop(context, updatedRoutine);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${exercisesToAdd.length} ${tr(context, 'exercises_added')}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'error_adding_exercises')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
