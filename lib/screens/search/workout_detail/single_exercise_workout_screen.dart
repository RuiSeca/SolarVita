import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/exercise/exercise_log.dart';
import '../../../services/exercises/exercise_tracking_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';
import '../../../widgets/common/exercise_image.dart';
import 'models/workout_step.dart';

class SingleExerciseWorkoutScreen extends ConsumerStatefulWidget {
  final String exerciseTitle;
  final String imagePath;
  final String duration;
  final String difficulty;
  final List<WorkoutStep> steps;
  final String description;
  final double rating;
  final String caloriesBurn;
  final String? routineId;
  final String? dayName;

  const SingleExerciseWorkoutScreen({
    super.key,
    required this.exerciseTitle,
    required this.imagePath,
    required this.duration,
    required this.difficulty,
    required this.steps,
    required this.description,
    required this.rating,
    required this.caloriesBurn,
    this.routineId,
    this.dayName,
  });

  @override
  ConsumerState<SingleExerciseWorkoutScreen> createState() => _SingleExerciseWorkoutScreenState();
}

class _SingleExerciseWorkoutScreenState extends ConsumerState<SingleExerciseWorkoutScreen> {
  final ExerciseTrackingService _trackingService = ExerciseTrackingService();
  
  bool _isWorkoutStarted = false;
  DateTime? _workoutStartTime;
  
  // Controllers for sets
  final List<TextEditingController> _weightControllers = [];
  final List<TextEditingController> _repsControllers = [];
  final TextEditingController _notesController = TextEditingController();
  
  List<ExerciseSet> _sets = [];

  @override
  void initState() {
    super.initState();
    _initializeDefaultSets();
  }

  void _initializeDefaultSets() {
    // Create intelligent default sets based on exercise type
    final title = widget.exerciseTitle.toLowerCase();
    final difficulty = widget.difficulty.toLowerCase();
    
    if (title.contains('cardio') || title.contains('run') || title.contains('bike')) {
      _sets = [
        ExerciseSet(
          setNumber: 1, 
          weight: 0.0, 
          reps: 0, 
          duration: const Duration(minutes: 20)
        )
      ];
    } else if (title.contains('plank') || title.contains('hold')) {
      _sets = List.generate(3, (index) => ExerciseSet(
        setNumber: index + 1, 
        weight: 0.0, 
        reps: 0, 
        duration: const Duration(seconds: 45)
      ));
    } else {
      // Regular strength exercises
      final numSets = difficulty == 'beginner' ? 2 : (difficulty == 'advanced' ? 4 : 3);
      final targetReps = difficulty == 'advanced' ? 8 : 10;
      
      _sets = List.generate(numSets, (index) => ExerciseSet(
        setNumber: index + 1,
        reps: targetReps,
        weight: 0.0,
      ));
    }
    
    // Initialize controllers
    for (int i = 0; i < _sets.length; i++) {
      _weightControllers.add(TextEditingController(
        text: _sets[i].weight > 0 ? _sets[i].weight.toString() : ''
      ));
      _repsControllers.add(TextEditingController(
        text: _sets[i].reps > 0 ? _sets[i].reps.toString() : ''
      ));
    }
  }

  void _startWorkout() {
    setState(() {
      _isWorkoutStarted = true;
      _workoutStartTime = DateTime.now();
    });
  }

  void _addSet() {
    setState(() {
      final newSetNumber = _sets.length + 1;
      
      // Get defaults from last set
      double weight = 0;
      int reps = 10;
      if (_sets.isNotEmpty) {
        weight = _sets.last.weight;
        reps = _sets.last.reps;
      }
      
      final newSet = ExerciseSet(
        setNumber: newSetNumber,
        weight: weight,
        reps: reps,
      );
      
      _sets.add(newSet);
      
      // Add controllers
      _weightControllers.add(TextEditingController(
        text: weight > 0 ? weight.toString() : ''
      ));
      _repsControllers.add(TextEditingController(
        text: reps > 0 ? reps.toString() : ''
      ));
    });
  }

  void _removeSet(int index) {
    if (_sets.length <= 1) return;
    
    setState(() {
      _sets.removeAt(index);
      _weightControllers[index].dispose();
      _repsControllers[index].dispose();
      _weightControllers.removeAt(index);
      _repsControllers.removeAt(index);
      
      // Renumber remaining sets
      for (int i = 0; i < _sets.length; i++) {
        _sets[i] = ExerciseSet(
          setNumber: i + 1,
          weight: _sets[i].weight,
          reps: _sets[i].reps,
          distance: _sets[i].distance,
          duration: _sets[i].duration,
        );
      }
    });
  }

  Future<void> _finishWorkout() async {
    // Update sets with current controller values
    final updatedSets = <ExerciseSet>[];
    for (int i = 0; i < _sets.length; i++) {
      final weight = double.tryParse(_weightControllers[i].text) ?? 0.0;
      final reps = int.tryParse(_repsControllers[i].text) ?? 0;
      
      updatedSets.add(ExerciseSet(
        setNumber: i + 1,
        weight: weight,
        reps: reps,
        distance: _sets[i].distance,
        duration: _sets[i].duration,
      ));
    }
    
    try {
      // Create exercise log
      final log = ExerciseLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        exerciseId: widget.exerciseTitle.hashCode.toString(),
        exerciseName: widget.exerciseTitle,
        date: DateTime.now(),
        sets: updatedSets,
        notes: _notesController.text,
        routineId: widget.routineId,
        dayName: widget.dayName,
      );
      
      // Save the log
      await _trackingService.saveExerciseLog(log);
      
      if (mounted) {
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
        : Duration.zero;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.amber, size: 28),
            const SizedBox(width: 8),
            Text(tr(context, 'exercise_completed')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.exerciseTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (widget.routineId != null && widget.dayName != null) ...[
              const SizedBox(height: 4),
              Text(
                '${widget.dayName} workout',
                style: TextStyle(
                  color: AppTheme.textColor(context).withAlpha(179),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text('${tr(context, 'sets_completed')}: ${_sets.length}'),
            if (duration.inSeconds > 0)
              Text('${tr(context, 'duration')}: ${duration.inMinutes} ${tr(context, 'minutes')}'),
            const SizedBox(height: 16),
            Text(
              tr(context, 'great_job_single_exercise'),
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
              Navigator.of(context).pop(true); // Return to previous screen with success
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
    for (final controller in _weightControllers) {
      controller.dispose();
    }
    for (final controller in _repsControllers) {
      controller.dispose();
    }
    _notesController.dispose();
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
        title: Flexible(
          child: Text(
            widget.exerciseTitle,
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
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
      body: _buildExerciseWorkout(),
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
          tr(context, 'single_exercise_workout'),
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
            // Exercise header
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
                  if (widget.routineId != null && widget.dayName != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.dayName} Routine',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    widget.exerciseTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildInfoChip(widget.difficulty, Icons.trending_up),
                      const SizedBox(width: 12),
                      _buildInfoChip(widget.duration, Icons.timer),
                      const SizedBox(width: 12),
                      _buildInfoChip('${_sets.length} sets', Icons.repeat),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Exercise description
            if (widget.description.isNotEmpty) ...[
              Text(
                tr(context, 'description'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.description,
                style: TextStyle(
                  color: AppTheme.textColor(context).withAlpha(179),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Exercise instructions preview
            if (widget.steps.isNotEmpty) ...[
              Text(
                tr(context, 'instructions'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
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
                  children: widget.steps.first.instructions.take(3).map((instruction) =>
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              instruction,
                              style: TextStyle(
                                color: AppTheme.textColor(context).withAlpha(179),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ).toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Start button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startWorkout,
                icon: const Icon(Icons.play_arrow, size: 28),
                label: Text(
                  tr(context, 'start_exercise'),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseWorkout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise instructions (full version during workout)
          if (widget.steps.isNotEmpty) ...[
            _buildFullInstructions(),
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
                onPressed: _addSet,
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
          ..._sets.asMap().entries.map((entry) {
            final index = entry.key;
            final set = entry.value;
            return _buildSetRow(index, set);
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
            controller: _notesController,
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

  Widget _buildFullInstructions() {
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
                // Show GIF if available
                if (widget.steps.isNotEmpty && widget.steps.first.gifUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 200,
                      child: ExerciseImage(
                        imageUrl: widget.steps.first.gifUrl,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // All instructions
                ...widget.steps.expand((step) => 
                  step.instructions.map((instruction) => 
                    Padding(
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
                    )
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetRow(int index, ExerciseSet set) {
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
                '${index + 1}',
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
                  controller: _weightControllers[index],
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
                  controller: _repsControllers[index],
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
          if (_sets.length > 1)
            IconButton(
              onPressed: () => _removeSet(index),
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
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
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _finishWorkout,
          icon: const Icon(Icons.check),
          label: Text(tr(context, 'finish_exercise')),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
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