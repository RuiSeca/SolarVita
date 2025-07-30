import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../../models/workout_routine.dart';
import '../../models/weekly_progress.dart';
import '../../screens/search/workout_detail/models/workout_item.dart';
import '../../screens/search/workout_detail/workout_detail_screen.dart';
import '../../widgets/common/exercise_image.dart';
import '../../providers/routine_providers.dart';
import 'exercise_selection_screen.dart';

class DayWorkoutScreen extends ConsumerStatefulWidget {
  final WorkoutRoutine routine;
  final DailyWorkout dayWorkout;

  const DayWorkoutScreen({
    super.key,
    required this.routine,
    required this.dayWorkout,
  });

  @override
  ConsumerState<DayWorkoutScreen> createState() => _DayWorkoutScreenState();
}

class _DayWorkoutScreenState extends ConsumerState<DayWorkoutScreen> {
  late WorkoutRoutine _currentRoutine;
  late DailyWorkout _currentDay;
  bool _isLoading = false;
  WeeklyProgress? _weeklyProgress;

  @override
  void initState() {
    super.initState();
    _currentRoutine = widget.routine;
    _currentDay = widget.dayWorkout;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        title: Text(
          tr(context, _currentDay.dayName.toLowerCase()),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppTheme.textColor(context),
          ),
          onPressed: () => Navigator.pop(context, _currentRoutine),
        ),
        actions: [
          if (!_currentDay.isRestDay)
            IconButton(
              icon: Icon(
                Icons.add,
                color: AppTheme.primaryColor,
              ),
              onPressed: () => _addExercise(),
            ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: AppTheme.textColor(context),
            ),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_rest',
                child: Row(
                  children: [
                    Icon(
                      _currentDay.isRestDay ? Icons.fitness_center : Icons.bed,
                      color: _currentDay.isRestDay ? AppTheme.primaryColor : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(_currentDay.isRestDay 
                        ? tr(context, 'make_workout_day')
                        : tr(context, 'make_rest_day')),
                  ],
                ),
              ),
              if (!_currentDay.isRestDay && _currentDay.exercises.isNotEmpty)
                PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.clear_all,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tr(context, 'clear_all_exercises'),
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'notes',
                child: Row(
                  children: [
                    Icon(
                      Icons.note_add,
                      color: AppTheme.textColor(context),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(tr(context, 'edit_notes')),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer(
              builder: (context, ref, child) {
                final progressAsync = ref.watch(weeklyProgressProvider(_currentRoutine.id));
                return progressAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => _currentDay.isRestDay 
                      ? _buildRestDayContent()
                      : _buildWorkoutContent(),
                  data: (progress) {
                    _weeklyProgress = progress;
                    return _currentDay.isRestDay 
                        ? _buildRestDayContent()
                        : _buildWorkoutContent();
                  },
                );
              },
            ),
      floatingActionButton: !_currentDay.isRestDay
          ? FloatingActionButton(
              onPressed: () => _addExercise(),
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildRestDayContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bed,
              size: 80,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),
            Text(
              tr(context, 'rest_day'),
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              tr(context, 'rest_day_description'),
              style: TextStyle(
                color: AppTheme.textColor(context).withAlpha(179),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            if (_currentDay.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor.withAlpha(26),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(context, 'notes'),
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentDay.notes!,
                      style: TextStyle(
                        color: AppTheme.textColor(context).withAlpha(204),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _toggleRestDay(),
              icon: const Icon(Icons.fitness_center),
              label: Text(tr(context, 'make_workout_day')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutContent() {
    if (_currentDay.exercises.isEmpty) {
      return _buildEmptyWorkoutState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_weeklyProgress != null) ...[
            _buildWeeklyProgressSection(),
            const SizedBox(height: 24),
          ],
          _buildWorkoutSummary(),
          const SizedBox(height: 24),
          _buildExercisesList(_weeklyProgress),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildEmptyWorkoutState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 80,
              color: AppTheme.textColor(context).withAlpha(102),
            ),
            const SizedBox(height: 24),
            Text(
              tr(context, 'no_exercises_added'),
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              tr(context, 'add_exercises_to_start'),
              style: TextStyle(
                color: AppTheme.textColor(context).withAlpha(179),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _addExercise(),
              icon: const Icon(Icons.add),
              label: Text(tr(context, 'add_exercise')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _toggleRestDay(),
              icon: const Icon(Icons.bed),
              label: Text(tr(context, 'make_rest_day')),
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutSummary() {
    final totalMinutes = _getTotalDuration();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withAlpha(26),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'workout_summary'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  tr(context, 'exercises'),
                  '${_currentDay.exercises.length}',
                  Icons.fitness_center,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  tr(context, 'duration'),
                  '${totalMinutes}min',
                  Icons.timer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  tr(context, 'calories'),
                  _getTotalCalories(),
                  Icons.local_fire_department,
                ),
              ),
            ],
          ),
          if (_currentDay.notes?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(13),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(context, 'notes'),
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentDay.notes!,
                    style: TextStyle(
                      color: AppTheme.textColor(context).withAlpha(204),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color: AppTheme.textColor(context).withAlpha(179),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildExercisesList(WeeklyProgress? weeklyProgress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'exercises'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _currentDay.exercises.length,
          onReorder: _reorderExercises,
          itemBuilder: (context, index) {
            final exercise = _currentDay.exercises[index];
            return _buildExerciseCard(exercise, index, weeklyProgress, key: ValueKey(exercise.title + index.toString()));
          },
        ),
      ],
    );
  }

  Widget _buildExerciseCard(WorkoutItem exercise, int index, WeeklyProgress? weeklyProgress, {required Key key}) {
    final isCompleted = _isExerciseCompletedFromProgress(exercise.title, weeklyProgress);
    
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _navigateToExerciseDetail(exercise),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isCompleted 
                ? AppTheme.primaryColor.withAlpha(26)
                : AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCompleted 
                  ? AppTheme.primaryColor
                  : AppTheme.primaryColor.withAlpha(26),
              width: isCompleted ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Stack(
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
                  if (isCompleted)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
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
                        Icon(
                          Icons.timer,
                          color: AppTheme.primaryColor,
                          size: 16,
                        ),
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
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: AppTheme.textColor(context).withAlpha(179),
                ),
                onSelected: (value) => _handleExerciseAction(value, index),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility,
                          color: AppTheme.textColor(context),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(tr(context, 'view_details')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tr(context, 'remove'),
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getTotalDuration() {
    int totalMinutes = 0;
    for (final exercise in _currentDay.exercises) {
      totalMinutes += _parseDurationToMinutes(exercise.duration);
    }
    return totalMinutes;
  }
  
  int _parseDurationToMinutes(String duration) {
    // Handle different duration formats: "30s", "2m", "90", "1:30", "1.5m", "60-90"
    final lowerDuration = duration.toLowerCase().trim();
    
    // Handle ranges like "60-90" or "60-90s" - use the lowest value
    if (lowerDuration.contains('-')) {
      final parts = lowerDuration.split('-');
      if (parts.length == 2) {
        final firstPart = parts[0].trim();
        // Use the first (lowest) value from the range
        return _parseSingleDuration(firstPart);
      }
    }
    
    return _parseSingleDuration(lowerDuration);
  }
  
  int _parseSingleDuration(String duration) {
    final lowerDuration = duration.toLowerCase().trim();
    
    // If it contains 's' (seconds)
    if (lowerDuration.contains('s')) {
      final seconds = int.tryParse(lowerDuration.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
      return (seconds / 60).ceil(); // Convert seconds to minutes (round up)
    }
    
    // If it contains 'm' (minutes)
    if (lowerDuration.contains('m')) {
      final minutes = double.tryParse(lowerDuration.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
      return minutes.round();
    }
    
    // If it contains ':' (mm:ss format)
    if (lowerDuration.contains(':')) {
      final parts = lowerDuration.split(':');
      if (parts.length == 2) {
        final minutes = int.tryParse(parts[0]) ?? 0;
        final seconds = int.tryParse(parts[1]) ?? 0;
        return minutes + (seconds / 60).ceil();
      }
    }
    
    // Default: assume it's seconds if just a number
    final number = int.tryParse(lowerDuration.replaceAll(RegExp(r'[^\d]'), ''));
    if (number != null) {
      // If the number is > 10, assume it's seconds, otherwise minutes
      if (number > 10) {
        return (number / 60).ceil(); // Convert seconds to minutes
      } else {
        return number; // Assume minutes
      }
    }
    
    return 0;
  }

  String _getTotalCalories() {
    int totalCalories = 0;
    for (final exercise in _currentDay.exercises) {
      totalCalories += _parseCalories(exercise.caloriesBurn);
    }
    return '${totalCalories}cal';
  }
  
  int _parseCalories(String caloriesStr) {
    // Handle different calorie formats: "150 cal", "150cal", "150", "150-200 cal"
    final lowerCalories = caloriesStr.toLowerCase().trim();
    
    // Handle range formats like "150-200 cal" - take the average
    if (lowerCalories.contains('-')) {
      final parts = lowerCalories.split('-');
      if (parts.length == 2) {
        final firstNum = int.tryParse(parts[0].replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
        final secondNum = int.tryParse(parts[1].replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
        return ((firstNum + secondNum) / 2).round();
      }
    }
    
    // Extract first number from the string
    final match = RegExp(r'\d+').firstMatch(lowerCalories);
    if (match != null) {
      return int.tryParse(match.group(0)!) ?? 0;
    }
    
    return 0;
  }

  void _reorderExercises(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    setState(() => _isLoading = true);

    try {
      final service = ref.read(routineServiceProvider);
      final updatedManager = await service.reorderExercises(
        _currentRoutine.id,
        _currentDay.dayName,
        oldIndex,
        newIndex,
      );
      
      final updatedRoutine = updatedManager.routines.firstWhere(
        (r) => r.id == _currentRoutine.id,
      );
      
      setState(() {
        _currentRoutine = updatedRoutine;
        _currentDay = updatedRoutine.getDayWorkout(_currentDay.dayName);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'error_reordering_exercises')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'toggle_rest':
        _toggleRestDay();
        break;
      case 'clear_all':
        _showClearAllDialog();
        break;
      case 'notes':
        _editNotes();
        break;
    }
  }

  void _handleExerciseAction(String action, int index) {
    switch (action) {
      case 'view':
        _navigateToExerciseDetail(_currentDay.exercises[index]);
        break;
      case 'remove':
        _removeExercise(index);
        break;
    }
  }

  void _addExercise() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseSelectionScreen(
          routine: _currentRoutine,
          dayName: _currentDay.dayName,
        ),
      ),
    );

    if (result is WorkoutRoutine) {
      setState(() {
        _currentRoutine = result;
        _currentDay = result.getDayWorkout(_currentDay.dayName);
      });
      
      // Trigger sync immediately when exercises are added to update planned count
      final syncService = ref.read(exerciseRoutineSyncServiceProvider);
      syncService.syncPlannedExercisesWithRoutine(_currentRoutine.id);
    }
  }

  void _navigateToExerciseDetail(WorkoutItem exercise) async {
    final result = await Navigator.push(
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
          // Pass routine context for proper exercise completion tracking
          routineId: _currentRoutine.id,
          dayName: _currentDay.dayName,
        ),
      ),
    );
    
    // Refresh the screen when returning from exercise detail
    // This ensures exercise completion status is updated immediately
    if (mounted) {
      // Force provider refresh to get latest data
      ref.invalidate(weeklyProgressProvider(_currentRoutine.id));  
      ref.refresh(weeklyProgressProvider(_currentRoutine.id));
      
      // If an exercise was logged, show additional feedback
      if (result == true) {
        // Extra refresh to ensure immediate updates
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            ref.invalidate(weeklyProgressProvider(_currentRoutine.id));
            setState(() {});
          }
        });
      } else {
        setState(() {});
      }
    }
  }

  void _removeExercise(int index) async {
    setState(() => _isLoading = true);

    try {
      final service = ref.read(routineServiceProvider);
      final updatedManager = await service.removeExerciseFromDay(
        _currentRoutine.id,
        _currentDay.dayName,
        index,
      );
      
      final updatedRoutine = updatedManager.routines.firstWhere(
        (r) => r.id == _currentRoutine.id,
      );
      
      setState(() {
        _currentRoutine = updatedRoutine;
        _currentDay = updatedRoutine.getDayWorkout(_currentDay.dayName);
        _isLoading = false;
      });

      // Trigger sync immediately when exercises are removed to update planned count
      final syncService = ref.read(exerciseRoutineSyncServiceProvider);
      syncService.syncPlannedExercisesWithRoutine(_currentRoutine.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'exercise_removed')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'error_removing_exercise')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleRestDay() async {
    setState(() => _isLoading = true);

    try {
      final service = ref.read(routineServiceProvider);
      final updatedManager = await service.setRestDay(
        _currentRoutine.id,
        _currentDay.dayName,
        !_currentDay.isRestDay,
        notes: _currentDay.notes,
      );
      
      final updatedRoutine = updatedManager.routines.firstWhere(
        (r) => r.id == _currentRoutine.id,
      );
      
      setState(() {
        _currentRoutine = updatedRoutine;
        _currentDay = updatedRoutine.getDayWorkout(_currentDay.dayName);
        _isLoading = false;
      });

      // Invalidate providers to update parent screens immediately
      ref.invalidate(weeklyProgressProvider(_currentRoutine.id));
      ref.invalidate(routineManagerProvider);
      ref.refresh(weeklyProgressProvider(_currentRoutine.id));
      ref.refresh(routineManagerProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_currentDay.isRestDay 
                ? tr(context, 'set_as_rest_day')
                : tr(context, 'set_as_workout_day')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'error_updating_day')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'clear_all_exercises')),
        content: Text(tr(context, 'clear_all_exercises_confirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllExercises();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              tr(context, 'clear_all'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _clearAllExercises() async {
    setState(() => _isLoading = true);

    try {
      final service = ref.read(routineServiceProvider);
      final updatedManager = await service.setRestDay(
        _currentRoutine.id,
        _currentDay.dayName,
        false,
        notes: _currentDay.notes,
      );
      
      // This will clear all exercises by setting it as a workout day with empty exercises
      final updatedRoutine = updatedManager.routines.firstWhere(
        (r) => r.id == _currentRoutine.id,
      );
      
      setState(() {
        _currentRoutine = updatedRoutine;
        _currentDay = updatedRoutine.getDayWorkout(_currentDay.dayName);
        _isLoading = false;
      });

      // Trigger sync immediately when exercises are cleared to update planned count
      final syncService = ref.read(exerciseRoutineSyncServiceProvider);
      syncService.syncPlannedExercisesWithRoutine(_currentRoutine.id);

      // Invalidate providers to update parent screens immediately
      ref.invalidate(weeklyProgressProvider(_currentRoutine.id));
      ref.invalidate(routineManagerProvider);
      ref.refresh(weeklyProgressProvider(_currentRoutine.id));
      ref.refresh(routineManagerProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'all_exercises_cleared')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'error_clearing_exercises')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editNotes() async {
    final notesController = TextEditingController(text: _currentDay.notes ?? '');
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'edit_notes')),
        content: TextField(
          controller: notesController,
          decoration: InputDecoration(
            labelText: tr(context, 'notes'),
            border: const OutlineInputBorder(),
            hintText: tr(context, 'add_notes_hint'),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, notesController.text),
            child: Text(tr(context, 'save')),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() => _isLoading = true);

      try {
        final service = ref.read(routineServiceProvider);
        final updatedManager = await service.setRestDay(
          _currentRoutine.id,
          _currentDay.dayName,
          _currentDay.isRestDay,
          notes: result.isEmpty ? null : result,
        );
        
        final updatedRoutine = updatedManager.routines.firstWhere(
          (r) => r.id == _currentRoutine.id,
        );
        
        setState(() {
          _currentRoutine = updatedRoutine;
          _currentDay = updatedRoutine.getDayWorkout(_currentDay.dayName);
          _isLoading = false;
        });

        // Invalidate providers to update parent screens immediately
        ref.invalidate(weeklyProgressProvider(_currentRoutine.id));
        ref.invalidate(routineManagerProvider);
        ref.refresh(weeklyProgressProvider(_currentRoutine.id));
        ref.refresh(routineManagerProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr(context, 'notes_updated')),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr(context, 'error_updating_notes')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Helper methods for completion tracking
  bool _isExerciseCompletedFromProgress(String exerciseTitle, WeeklyProgress? weeklyProgress) {
    if (weeklyProgress == null) return false;
    final dayProgress = weeklyProgress.dailyProgress[_currentDay.dayName];
    return dayProgress?.isExerciseCompleted(exerciseTitle) ?? false;
  }

  // Calculate completion percentage using current local state for instant updates
  double _calculateCurrentCompletionPercentage(DayProgress dayProgress) {
    if (_currentDay.isRestDay) return 100.0;
    final currentPlannedCount = _currentDay.exercises.length;
    if (currentPlannedCount == 0) return 0.0;
    return (dayProgress.completedExercises / currentPlannedCount) * 100;
  }

  Widget _buildWeeklyProgressSection() {
    return Consumer(
      builder: (context, ref, child) {
        final weeklyProgressAsync = ref.watch(weeklyProgressProvider(_currentRoutine.id));
        
        return weeklyProgressAsync.when(
          loading: () => Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => const SizedBox.shrink(),
          data: (weeklyProgress) {
            if (weeklyProgress == null) return const SizedBox.shrink();
            
            final dayProgress = weeklyProgress.dailyProgress[_currentDay.dayName];
            if (dayProgress == null) return const SizedBox.shrink();
            
            return _buildWeeklyProgressContent(weeklyProgress, dayProgress);
          },
        );
      },
    );
  }

  Widget _buildWeeklyProgressContent(WeeklyProgress weeklyProgress, DayProgress dayProgress) {

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withAlpha(26),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr(context, 'daily_progress'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_calculateCurrentCompletionPercentage(dayProgress).round()}%',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Progress bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(26),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              widthFactor: _calculateCurrentCompletionPercentage(dayProgress) / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Daily progress breakdown
          Row(
            children: [
              Expanded(
                child: _buildProgressItem(
                  tr(context, 'completed_exercises'),
                  '${dayProgress.completedExercises}',
                  Icons.check_circle,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProgressItem(
                  tr(context, 'remaining_exercises'),
                  '${(_currentDay.exercises.length - dayProgress.completedExercises).clamp(0, double.infinity)}',
                  Icons.pending,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: ref.read(exerciseRoutineSyncServiceProvider).getRoutineCompletionStats(_currentRoutine.id),
                  builder: (context, snapshot) {
                    final streak = snapshot.data?['currentStreak'] ?? 0;
                    return _buildProgressItem(
                      tr(context, 'streak'),
                      '$streak',
                      Icons.local_fire_department,
                      Colors.orange,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color: AppTheme.textColor(context).withAlpha(179),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}