import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/exercise/workout_routine.dart';
import '../../models/user/weekly_progress.dart';
import '../../models/exercise/exercise_log.dart';
import '../../services/exercises/exercise_tracking_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../../widgets/common/exercise_image.dart';

class RoutineWorkoutScreen extends ConsumerStatefulWidget {
  final WorkoutRoutine routine;
  final DailyWorkout dayWorkout;
  final WeeklyProgress? weeklyProgress;

  const RoutineWorkoutScreen({
    super.key,
    required this.routine,
    required this.dayWorkout,
    this.weeklyProgress,
  });

  @override
  ConsumerState<RoutineWorkoutScreen> createState() => _RoutineWorkoutScreenState();
}

class _RoutineWorkoutScreenState extends ConsumerState<RoutineWorkoutScreen> {
  final ExerciseTrackingService _trackingService = ExerciseTrackingService();
  final PageController _pageController = PageController();
  
  int _currentExerciseIndex = 0;
  bool _isWorkoutStarted = false;
  DateTime? _workoutStartTime;
  
  // Store logs for each exercise
  final Map<int, ExerciseLog> _exerciseLogs = {};
  
  // Controllers for each exercise's sets
  final Map<int, List<TextEditingController>> _weightControllers = {};
  final Map<int, List<TextEditingController>> _repsControllers = {};
  final Map<int, List<TextEditingController>> _notesControllers = {};

  @override
  void initState() {
    super.initState();
    _initializeExerciseData();
  }

  void _initializeExerciseData() {
    for (int i = 0; i < widget.dayWorkout.exercises.length; i++) {
      final exercise = widget.dayWorkout.exercises[i];
      
      // Create default sets based on exercise type (similar to template logic)
      final sets = _createDefaultSetsForExercise(exercise);
      
      // Create controllers for this exercise
      _weightControllers[i] = sets.map((set) => 
        TextEditingController(text: set.weight > 0 ? set.weight.toString() : '')).toList();
      _repsControllers[i] = sets.map((set) => 
        TextEditingController(text: set.reps > 0 ? set.reps.toString() : '')).toList();
      _notesControllers[i] = [TextEditingController(text: '')];
      
      // Create initial log
      _exerciseLogs[i] = ExerciseLog(
        id: '${DateTime.now().millisecondsSinceEpoch}_$i',
        exerciseId: exercise.title.hashCode.toString(),
        exerciseName: exercise.title,
        date: DateTime.now(),
        sets: sets,
        notes: '',
        routineId: widget.routine.id,
        dayName: widget.dayWorkout.dayName,
      );
    }
  }

  List<ExerciseSet> _createDefaultSetsForExercise(exercise) {
    // Create intelligent default sets based on exercise type and difficulty
    final title = exercise.title.toLowerCase();
    final difficulty = exercise.difficulty.toLowerCase();
    
    if (title.contains('cardio') || title.contains('run') || title.contains('bike')) {
      return [
        ExerciseSet(
          setNumber: 1, 
          weight: 0.0, 
          reps: 0, 
          duration: const Duration(minutes: 20)
        )
      ];
    } else if (title.contains('plank') || title.contains('hold')) {
      return List.generate(3, (index) => ExerciseSet(
        setNumber: index + 1, 
        weight: 0.0, 
        reps: 0, 
        duration: const Duration(seconds: 45)
      ));
    } else {
      // Regular strength exercises
      final numSets = difficulty == 'beginner' ? 2 : (difficulty == 'advanced' ? 4 : 3);
      final targetReps = difficulty == 'advanced' ? 8 : 10;
      
      return List.generate(numSets, (index) => ExerciseSet(
        setNumber: index + 1,
        reps: targetReps,
        weight: 0.0,
      ));
    }
  }

  void _startWorkout() {
    setState(() {
      _isWorkoutStarted = true;
      _workoutStartTime = DateTime.now();
    });
  }

  void _nextExercise() {
    if (_currentExerciseIndex < widget.dayWorkout.exercises.length - 1) {
      _updateCurrentExerciseLog();
      setState(() {
        _currentExerciseIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousExercise() {
    if (_currentExerciseIndex > 0) {
      _updateCurrentExerciseLog();
      setState(() {
        _currentExerciseIndex--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _updateCurrentExerciseLog() {
    final exerciseIndex = _currentExerciseIndex;
    final weightControllers = _weightControllers[exerciseIndex]!;
    final repsControllers = _repsControllers[exerciseIndex]!;
    final notesController = _notesControllers[exerciseIndex]![0];
    
    final updatedSets = <ExerciseSet>[];
    for (int i = 0; i < weightControllers.length; i++) {
      final weight = double.tryParse(weightControllers[i].text) ?? 0.0;
      final reps = int.tryParse(repsControllers[i].text) ?? 0;
      
      updatedSets.add(ExerciseSet(
        setNumber: i + 1,
        weight: weight,
        reps: reps,
      ));
    }
    
    _exerciseLogs[exerciseIndex] = _exerciseLogs[exerciseIndex]!.copyWith(
      sets: updatedSets,
      notes: notesController.text,
    );
  }

  void _addSet(int exerciseIndex) {
    setState(() {
      final currentSets = _exerciseLogs[exerciseIndex]!.sets;
      final newSetNumber = currentSets.length + 1;
      
      // Get weight and reps from previous set as defaults
      double weight = 0;
      int reps = 10;
      if (currentSets.isNotEmpty) {
        weight = currentSets.last.weight;
        reps = currentSets.last.reps;
      }
      
      final newSet = ExerciseSet(
        setNumber: newSetNumber,
        weight: weight,
        reps: reps,
      );
      
      // Update log
      _exerciseLogs[exerciseIndex] = _exerciseLogs[exerciseIndex]!.copyWith(
        sets: [...currentSets, newSet],
      );
      
      // Add controllers
      _weightControllers[exerciseIndex]!.add(
        TextEditingController(text: weight > 0 ? weight.toString() : ''));
      _repsControllers[exerciseIndex]!.add(
        TextEditingController(text: reps > 0 ? reps.toString() : ''));
    });
  }

  void _removeSet(int exerciseIndex, int setIndex) {
    if (_exerciseLogs[exerciseIndex]!.sets.length <= 1) return;
    
    setState(() {
      final currentSets = _exerciseLogs[exerciseIndex]!.sets;
      currentSets.removeAt(setIndex);
      
      // Renumber sets
      for (int i = 0; i < currentSets.length; i++) {
        currentSets[i] = ExerciseSet(
          setNumber: i + 1,
          weight: currentSets[i].weight,
          reps: currentSets[i].reps,
          distance: currentSets[i].distance,
          duration: currentSets[i].duration,
        );
      }
      
      _exerciseLogs[exerciseIndex] = _exerciseLogs[exerciseIndex]!.copyWith(
        sets: currentSets,
      );
      
      // Remove controllers
      _weightControllers[exerciseIndex]!.removeAt(setIndex);
      _repsControllers[exerciseIndex]!.removeAt(setIndex);
    });
  }

  Future<void> _finishWorkout() async {
    _updateCurrentExerciseLog();
    
    try {
      // Save all exercise logs
      for (final log in _exerciseLogs.values) {
        await _trackingService.saveExerciseLog(log);
      }
      
      if (mounted) {
        // Show celebration
        _showWorkoutCompletedDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'error_saving_workout')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showWorkoutCompletedDialog() {
    final duration = _workoutStartTime != null
        ? DateTime.now().difference(_workoutStartTime!)
        : const Duration(minutes: 45);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.amber, size: 28),
            const SizedBox(width: 8),
            Text(tr(context, 'workout_completed')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.dayWorkout.dayName} • ${widget.routine.name}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('${tr(context, 'exercises_completed')}: ${widget.dayWorkout.exercises.length}'),
            Text('${tr(context, 'duration')}: ${duration.inMinutes} ${tr(context, 'minutes')}'),
            const SizedBox(height: 16),
            Text(
              tr(context, 'great_job_message'),
              style: TextStyle(
                color: AppTheme.textColor(context).withAlpha(179),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to day screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(tr(context, 'done')),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controllers in _weightControllers.values) {
      for (final controller in controllers) {
        controller.dispose();
      }
    }
    for (final controllers in _repsControllers.values) {
      for (final controller in controllers) {
        controller.dispose();
      }
    }
    for (final controllers in _notesControllers.values) {
      for (final controller in controllers) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isWorkoutStarted) {
      return _buildWorkoutPreview();
    }
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor(context),
        elevation: 0,
        title: Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  widget.dayWorkout.dayName,
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              Text(
                '${_currentExerciseIndex + 1} of ${widget.dayWorkout.exercises.length}',
                style: TextStyle(
                  color: AppTheme.textColor(context).withAlpha(179),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Live timer display
          if (_workoutStartTime != null)
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (context, snapshot) {
                    final elapsed = DateTime.now().difference(_workoutStartTime!);
                    final minutes = elapsed.inMinutes;
                    final seconds = elapsed.inSeconds % 60;
                    return Text(
                      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
            ),
          Flexible(
            child: IconButton(
              icon: Icon(Icons.close, color: AppTheme.textColor(context)),
              onPressed: () => _showExitDialog(),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.dayWorkout.exercises.length,
        onPageChanged: (index) {
          if (index != _currentExerciseIndex) {
            _updateCurrentExerciseLog();
            setState(() {
              _currentExerciseIndex = index;
            });
          }
        },
        itemBuilder: (context, index) {
          return _buildExercisePage(index);
        },
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildWorkoutPreview() {
    final totalExercises = widget.dayWorkout.exercises.length;
    final estimatedDuration = totalExercises * 8; // Rough estimate
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor(context),
        elevation: 0,
        title: Text(
          '${widget.dayWorkout.dayName} Workout',
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Routine context card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withAlpha(204),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.routine.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.dayWorkout.dayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildInfoChip('$totalExercises exercises', Icons.fitness_center),
                      const SizedBox(width: 12),
                      _buildInfoChip('~$estimatedDuration min', Icons.timer),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Exercises preview
            Text(
              tr(context, 'exercises'),
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ...widget.dayWorkout.exercises.asMap().entries.map((entry) {
              final index = entry.key;
              final exercise = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
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
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${exercise.difficulty} • ${exercise.duration}',
                            style: TextStyle(
                              color: AppTheme.textColor(context).withAlpha(179),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            
            const SizedBox(height: 32),
            
            // Start button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startWorkout,
                icon: const Icon(Icons.play_arrow, size: 28),
                label: Text(
                  tr(context, 'start_workout'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
              ),
            ),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisePage(int exerciseIndex) {
    final exercise = widget.dayWorkout.exercises[exerciseIndex];
    final log = _exerciseLogs[exerciseIndex]!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
                  exercise.title,
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildExerciseInfoChip(exercise.difficulty, Icons.trending_up, Colors.orange),
                    const SizedBox(width: 8),
                    _buildExerciseInfoChip(exercise.duration, Icons.timer, Colors.blue),
                    if (exercise.equipment.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _buildExerciseInfoChip(exercise.equipment.first, Icons.fitness_center, Colors.green),
                    ],
                  ],
                ),
                if (exercise.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    exercise.description,
                    style: TextStyle(
                      color: AppTheme.textColor(context).withAlpha(179),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Exercise Instructions and GIF
          if (exercise.steps.isNotEmpty) ...[
            _buildExerciseInstructions(exercise),
            const SizedBox(height: 24),
          ],
          
          // Sets section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr(context, 'sets'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () => _addSet(exerciseIndex),
                icon: const Icon(Icons.add, size: 18),
                label: Text(tr(context, 'add_set')),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Sets list
          ...log.sets.asMap().entries.map((entry) {
            final setIndex = entry.key;
            final set = entry.value;
            return _buildSetRow(exerciseIndex, setIndex, set);
          }),
          
          const SizedBox(height: 24),
          
          // Notes section
          Text(
            tr(context, 'notes'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesControllers[exerciseIndex]![0],
            decoration: InputDecoration(
              hintText: tr(context, 'add_notes'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryColor.withAlpha(51)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryColor.withAlpha(51)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
            ),
            maxLines: 3,
          ),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildExerciseInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetRow(int exerciseIndex, int setIndex, ExerciseSet set) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withAlpha(26),
        ),
      ),
      child: Row(
        children: [
          // Set number
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${setIndex + 1}',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Weight input
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(context, 'weight'),
                  style: TextStyle(
                    color: AppTheme.textColor(context).withAlpha(179),
                    fontSize: 12,
                  ),
                ),
                TextField(
                  controller: _weightControllers[exerciseIndex]![setIndex],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '0',
                    suffixText: 'kg',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Reps input
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(context, 'reps'),
                  style: TextStyle(
                    color: AppTheme.textColor(context).withAlpha(179),
                    fontSize: 12,
                  ),
                ),
                TextField(
                  controller: _repsControllers[exerciseIndex]![setIndex],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '0',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Delete set button
          if (_exerciseLogs[exerciseIndex]!.sets.length > 1)
            IconButton(
              onPressed: () => _removeSet(exerciseIndex, setIndex),
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final isLastExercise = _currentExerciseIndex >= widget.dayWorkout.exercises.length - 1;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentExerciseIndex > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousExercise,
                icon: const Icon(Icons.arrow_back),
                label: Text(tr(context, 'previous')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          
          if (_currentExerciseIndex > 0) const SizedBox(width: 16),
          
          Expanded(
            flex: isLastExercise ? 1 : 2,
            child: ElevatedButton.icon(
              onPressed: isLastExercise ? _finishWorkout : _nextExercise,
              icon: Icon(isLastExercise ? Icons.check : Icons.arrow_forward),
              label: Text(isLastExercise ? tr(context, 'finish') : tr(context, 'next')),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastExercise ? Colors.green : AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseInstructions(exercise) {
    return Container(
      width: double.infinity,
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
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(26),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  tr(context, 'how_to_perform'),
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Content with GIF and instructions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show GIF from first step (if available)
                if (exercise.steps.isNotEmpty && exercise.steps.first.gifUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 200,
                      child: ExerciseImage(
                        imageUrl: exercise.steps.first.gifUrl,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Instructions from all steps
                ...exercise.steps.asMap().entries.expand((entry) {
                  final stepIndex = entry.key;
                  final step = entry.value;
                  return [
                    if (stepIndex > 0) const SizedBox(height: 12),
                    ...step.instructions.asMap().entries.map((instructionEntry) {
                      final instruction = instructionEntry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                instruction,
                                style: TextStyle(
                                  color: AppTheme.textColor(context),
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ];
                }),
                
                // Tips if available
                if (exercise.tips.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.amber.withAlpha(51),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.lightbulb_outline,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tr(context, 'tips'),
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...exercise.tips.map((tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• $tip',
                            style: TextStyle(
                              color: AppTheme.textColor(context).withAlpha(204),
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'exit_workout')),
        content: Text(tr(context, 'exit_workout_confirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit workout
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(tr(context, 'exit'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}