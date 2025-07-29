import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../../models/workout_routine.dart';
import '../../screens/search/workout_detail/models/workout_item.dart';
import '../../screens/search/workout_detail/workout_detail_screen.dart';
import '../../widgets/common/exercise_image.dart';
import 'exercise_selection_screen.dart';
import 'routine_main_screen.dart';

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
          : _currentDay.isRestDay 
              ? _buildRestDayContent()
              : _buildWorkoutContent(),
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
          _buildWorkoutSummary(),
          const SizedBox(height: 24),
          _buildExercisesList(),
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

  Widget _buildExercisesList() {
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
            return _buildExerciseCard(exercise, index, key: ValueKey(exercise.title + index.toString()));
          },
        ),
      ],
    );
  }

  Widget _buildExerciseCard(WorkoutItem exercise, int index, {required Key key}) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _navigateToExerciseDetail(exercise),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColor.withAlpha(26),
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
      final durationText = exercise.duration.replaceAll(RegExp(r'[^\d]'), '');
      totalMinutes += int.tryParse(durationText) ?? 0;
    }
    return totalMinutes;
  }

  String _getTotalCalories() {
    int totalCalories = 0;
    for (final exercise in _currentDay.exercises) {
      final caloriesText = exercise.caloriesBurn.replaceAll(RegExp(r'[^\d]'), '');
      totalCalories += int.tryParse(caloriesText) ?? 0;
    }
    return '${totalCalories}cal';
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
    }
  }

  void _navigateToExerciseDetail(WorkoutItem exercise) {
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
}