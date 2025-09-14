import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/templates/workout_template.dart';
import '../../models/exercise/exercise_log.dart';
import '../../services/exercises/exercise_tracking_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../../widgets/achievements/personal_record_celebration.dart';

class TemplateWorkoutScreen extends ConsumerStatefulWidget {
  final WorkoutTemplate template;

  const TemplateWorkoutScreen({
    super.key,
    required this.template,
  });

  @override
  ConsumerState<TemplateWorkoutScreen> createState() => _TemplateWorkoutScreenState();
}

class _TemplateWorkoutScreenState extends ConsumerState<TemplateWorkoutScreen> {
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
    for (int i = 0; i < widget.template.exercises.length; i++) {
      final exercise = widget.template.exercises[i];
      
      // Initialize sets from template
      final sets = exercise.sets.map((templateSet) {
        return ExerciseSet(
          setNumber: templateSet.setNumber,
          weight: templateSet.targetWeight ?? 0.0,
          reps: templateSet.targetReps ?? templateSet.minReps ?? 0,
          distance: templateSet.targetDistance,
          duration: templateSet.targetDuration != null 
            ? Duration(seconds: templateSet.targetDuration!)
            : null,
        );
      }).toList();
      
      // Create controllers for this exercise
      _weightControllers[i] = sets.map((set) => 
        TextEditingController(text: set.weight > 0 ? set.weight.toString() : '')).toList();
      _repsControllers[i] = sets.map((set) => 
        TextEditingController(text: set.reps > 0 ? set.reps.toString() : '')).toList();
      _notesControllers[i] = [TextEditingController(text: exercise.notes ?? '')];
      
      // Create initial log
      _exerciseLogs[i] = ExerciseLog(
        id: '${DateTime.now().millisecondsSinceEpoch}_$i',
        exerciseId: exercise.id,
        exerciseName: exercise.name,
        date: DateTime.now(),
        sets: sets,
        notes: exercise.notes ?? '',
      );
    }
  }

  void _startWorkout() {
    setState(() {
      _isWorkoutStarted = true;
      _workoutStartTime = DateTime.now();
    });
  }

  void _nextExercise() {
    if (_currentExerciseIndex < widget.template.exercises.length - 1) {
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
    final currentLog = _exerciseLogs[exerciseIndex]!;
    
    // Update sets from controllers
    final updatedSets = <ExerciseSet>[];
    for (int i = 0; i < _weightControllers[exerciseIndex]!.length; i++) {
      final weight = double.tryParse(_weightControllers[exerciseIndex]![i].text) ?? 0.0;
      final reps = int.tryParse(_repsControllers[exerciseIndex]![i].text) ?? 0;
      
      updatedSets.add(ExerciseSet(
        setNumber: i + 1,
        weight: weight,
        reps: reps,
        distance: currentLog.sets[i].distance,
        duration: currentLog.sets[i].duration,
      ));
    }
    
    _exerciseLogs[exerciseIndex] = currentLog.copyWith(
      sets: updatedSets,
      notes: _notesControllers[exerciseIndex]!.first.text,
    );
  }

  void _addSet(int exerciseIndex) {
    setState(() {
      final currentSets = _exerciseLogs[exerciseIndex]!.sets;
      final newSetNumber = currentSets.length + 1;
      
      // Copy values from last set for convenience
      double weight = 0;
      int reps = 0;
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
    
    // Save all logged exercises
    bool allSaved = true;
    for (final log in _exerciseLogs.values) {
      // Only save exercises with actual data
      if (log.sets.any((set) => set.weight > 0 || set.reps > 0)) {
        final success = await _trackingService.saveExerciseLog(log);
        if (!success) allSaved = false;
      }
    }
    
    if (mounted) {
      if (allSaved) {
        await _checkAndCelebrateNewRecords();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr(context, 'workout_completed')),
              backgroundColor: AppColors.primary,
            ),
          );
          
          // Navigate back to templates or main screen
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
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
  }

  Future<void> _checkAndCelebrateNewRecords() async {
    try {
      final recentTime = DateTime.now().subtract(const Duration(seconds: 5));
      
      for (final log in _exerciseLogs.values) {
        final records = await _trackingService.getPersonalRecordsForExercise(log.exerciseId);
        final newRecords = records.where((record) => record.date.isAfter(recentTime)).toList();
        
        for (final record in newRecords) {
          if (mounted) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => PersonalRecordCelebration(
                newRecord: record,
                onComplete: () {},
              ),
            );
          }
        }
      }
    } catch (e) {
      // Silently handle errors
    }
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
        title: Column(
          children: [
            Text(
              widget.template.name,
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              '${_currentExerciseIndex + 1} / ${widget.template.exercises.length}',
              style: TextStyle(
                color: AppTheme.textColor(context).withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: AppTheme.textColor(context),
          ),
          onPressed: () => _showExitDialog(),
        ),
        actions: [
          if (_workoutStartTime != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (context, snapshot) {
                    final elapsed = DateTime.now().difference(_workoutStartTime!);
                    final minutes = elapsed.inMinutes;
                    final seconds = elapsed.inSeconds % 60;
                    return Text(
                      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          _updateCurrentExerciseLog();
          setState(() {
            _currentExerciseIndex = index;
          });
        },
        itemCount: widget.template.exercises.length,
        itemBuilder: (context, index) {
          return _buildExercisePage(index);
        },
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildWorkoutPreview() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor(context),
        elevation: 0,
        title: Text(
          widget.template.name,
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppTheme.textColor(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.textColor(context).withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr(context, 'ready_to_start'),
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.template.exercises.length} ${tr(context, 'exercises')} • ${widget.template.estimatedDuration} ${tr(context, 'minutes')}',
                    style: TextStyle(
                      color: AppTheme.textColor(context).withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              tr(context, 'workout_overview'),
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ...widget.template.exercises.asMap().entries.map((entry) {
              final index = entry.key;
              final exercise = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.textColor(context).withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            style: TextStyle(
                              color: AppTheme.textColor(context),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${exercise.sets.length} ${tr(context, 'sets')}',
                            style: TextStyle(
                              color: AppTheme.textColor(context).withValues(alpha: 0.6),
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
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startWorkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  tr(context, 'start_workout'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExercisePage(int exerciseIndex) {
    final exercise = widget.template.exercises[exerciseIndex];
    final log = _exerciseLogs[exerciseIndex]!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.textColor(context).withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (exercise.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    exercise.description!,
                    style: TextStyle(
                      color: AppTheme.textColor(context).withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                  ),
                ],
                if (exercise.restSeconds != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.timer,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${tr(context, 'rest')}: ${exercise.restSeconds! ~/ 60}:${(exercise.restSeconds! % 60).toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Sets section
          Row(
            children: [
              Text(
                tr(context, 'sets'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _addSet(exerciseIndex),
                icon: const Icon(Icons.add),
                label: Text(tr(context, 'add_set')),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Set headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    tr(context, 'set'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    tr(context, 'weight_kg'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    tr(context, 'reps'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Sets
          ...List.generate(log.sets.length, (setIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${setIndex + 1}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: TextFormField(
                        controller: _weightControllers[exerciseIndex]![setIndex],
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                        ],
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: TextFormField(
                        controller: _repsControllers[exerciseIndex]![setIndex],
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: log.sets.length > 1
                          ? () => _removeSet(exerciseIndex, setIndex)
                          : null,
                    ),
                  ),
                ],
              ),
            );
          }),
          
          const SizedBox(height: 24),
          
          // Notes
          Text(
            tr(context, 'notes'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _notesControllers[exerciseIndex]!.first,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: tr(context, 'enter_notes'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        border: Border(
          top: BorderSide(
            color: AppTheme.textColor(context).withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          if (_currentExerciseIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousExercise,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(tr(context, 'previous')),
              ),
            ),
          if (_currentExerciseIndex > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _currentExerciseIndex < widget.template.exercises.length - 1
                  ? _nextExercise
                  : _finishWorkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                _currentExerciseIndex < widget.template.exercises.length - 1
                    ? tr(context, 'next_exercise')
                    : tr(context, 'finish_workout'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
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
        backgroundColor: AppTheme.cardColor(context),
        title: Text(
          tr(context, 'exit_workout'),
          style: TextStyle(color: AppTheme.textColor(context)),
        ),
        content: Text(
          tr(context, 'exit_workout_warning'),
          style: TextStyle(color: AppTheme.textColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              tr(context, 'exit'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    
    // Dispose all controllers
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
}