// lib/screens/exercise_history/log_exercise_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/exercise_log.dart';
import '../../services/exercise_tracking_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../search/workout_detail/models/workout_item.dart';
import '../search/search_screen.dart';

class LogExerciseScreen extends StatefulWidget {
  final String? exerciseId; // Optional - if coming from a specific exercise
  final String? initialExerciseName; // Add this parameter to fix the error
  final ExerciseLog? existingLog; // Optional - if editing an existing log

  const LogExerciseScreen({
    super.key,
    this.exerciseId,
    this.initialExerciseName, // Added parameter
    this.existingLog,
  });

  @override
  State<LogExerciseScreen> createState() => _LogExerciseScreenState();
}

class _LogExerciseScreenState extends State<LogExerciseScreen> {
  final ExerciseTrackingService _trackingService = ExerciseTrackingService();
  final _formKey = GlobalKey<FormState>();

  late String _exerciseId;
  late TextEditingController _exerciseNameController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late List<ExerciseSet> _sets;
  late TextEditingController _notesController;

  // For each set, we need controllers for weight and reps
  late List<TextEditingController> _weightControllers;
  late List<TextEditingController> _repsControllers;
  late List<TextEditingController> _distanceControllers;
  late List<TextEditingController> _durationControllers;

  @override
  void initState() {
    super.initState();

    if (widget.existingLog != null) {
      // Editing an existing log
      _exerciseId = widget.existingLog!.exerciseId;
      _exerciseNameController =
          TextEditingController(text: widget.existingLog!.exerciseName);
      _selectedDate = widget.existingLog!.date;
      _selectedTime = TimeOfDay.fromDateTime(widget.existingLog!.date);
      _sets = List.from(widget.existingLog!.sets);
      _notesController = TextEditingController(text: widget.existingLog!.notes);
    } else {
      // Creating a new log
      _exerciseId = widget.exerciseId ?? '';
      _exerciseNameController = TextEditingController();
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
      _sets = [ExerciseSet(setNumber: 1, weight: 0, reps: 0)];
      _notesController = TextEditingController();
    }

    // Initialize controllers for each set
    _initializeSetControllers();
  }

  void _initializeSetControllers() {
    _weightControllers = _sets
        .map((set) => TextEditingController(text: set.weight.toString()))
        .toList();

    _repsControllers = _sets
        .map((set) => TextEditingController(text: set.reps.toString()))
        .toList();

    _distanceControllers = _sets
        .map((set) =>
            TextEditingController(text: set.distance?.toString() ?? ''))
        .toList();

    _durationControllers = _sets
        .map((set) => TextEditingController(
            text: set.duration != null
                ? "${set.duration!.inMinutes}:${(set.duration!.inSeconds % 60).toString().padLeft(2, '0')}"
                : ''))
        .toList();
  }

  Future<void> _selectExercise() async {
    // Navigate to search screen in selection mode
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SearchScreen(),
        // In a real implementation, you'd have a selection mode
        // that returns the selected exercise
      ),
    );

    if (result != null && result is WorkoutItem) {
      setState(() {
        _exerciseId = result.title; // This should be a proper ID in a real app
        _exerciseNameController.text = result.title;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppTheme.surfaceColor(context),
              onSurface: AppTheme.textColor(context),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppTheme.surfaceColor(context),
              onSurface: AppTheme.textColor(context),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _addSet() {
    setState(() {
      final newSetNumber = _sets.length + 1;

      // If there's a previous set, copy its values for convenience
      double weight = 0;
      int reps = 0;
      double? distance;
      Duration? duration;

      if (_sets.isNotEmpty) {
        weight = _sets.last.weight;
        reps = _sets.last.reps;
        distance = _sets.last.distance;
        duration = _sets.last.duration;
      }

      _sets.add(ExerciseSet(
        setNumber: newSetNumber,
        weight: weight,
        reps: reps,
        distance: distance,
        duration: duration,
      ));

      // Add controllers for the new set
      _weightControllers.add(TextEditingController(text: weight.toString()));
      _repsControllers.add(TextEditingController(text: reps.toString()));
      _distanceControllers
          .add(TextEditingController(text: distance?.toString() ?? ''));
      _durationControllers = _sets
          .map((set) => TextEditingController(
              text: set.duration != null
                  ? "${set.duration!.inMinutes}:${(set.duration!.inSeconds % 60).toString().padLeft(2, '0')}"
                  : ''))
          .toList();
    });
  }

  void _removeSet(int index) {
    setState(() {
      _sets.removeAt(index);
      _weightControllers.removeAt(index);
      _repsControllers.removeAt(index);
      _distanceControllers.removeAt(index);
      _durationControllers.removeAt(index);

      // Renumber the remaining sets
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

  Future<void> _saveLog() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Update set values from controllers
    for (int i = 0; i < _sets.length; i++) {
      final weight = double.tryParse(_weightControllers[i].text) ?? 0;
      final reps = int.tryParse(_repsControllers[i].text) ?? 0;

      double? distance;
      if (_distanceControllers[i].text.isNotEmpty) {
        distance = double.tryParse(_distanceControllers[i].text);
      }

      Duration? duration;
      if (_durationControllers[i].text.isNotEmpty) {
        final parts = _durationControllers[i].text.split(':');
        if (parts.length == 2) {
          final minutes = int.tryParse(parts[0]) ?? 0;
          final seconds = int.tryParse(parts[1]) ?? 0;
          duration = Duration(minutes: minutes, seconds: seconds);
        }
      }

      _sets[i] = ExerciseSet(
        setNumber: i + 1,
        weight: weight,
        reps: reps,
        distance: distance,
        duration: duration,
      );
    }

    // Create date time from selected date and time
    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // Create log object
    ExerciseLog log;
    if (widget.existingLog != null) {
      // Update existing log
      log = ExerciseLog(
        id: widget.existingLog!.id,
        exerciseId: _exerciseId,
        exerciseName: _exerciseNameController.text,
        date: dateTime,
        sets: _sets,
        notes: _notesController.text,
      );

      await _trackingService.updateLog(log);
    } else {
      // Create new log
      log = ExerciseLog(
        id: _trackingService.generateId(),
        exerciseId: _exerciseId,
        exerciseName: _exerciseNameController.text,
        date: dateTime,
        sets: _sets,
        notes: _notesController.text,
      );

      await _trackingService.saveExerciseLog(log);
    }

    if (mounted) {
      Navigator.pop(context, true); // Return true to refresh parent screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingLog != null
            ? tr(context, 'edit_log')
            : tr(context, 'log_exercise')),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Exercise selection
            Text(
              tr(context, 'exercise'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _exerciseNameController,
              decoration: InputDecoration(
                hintText: tr(context, 'enter_exercise_name'),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _selectExercise,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return tr(context, 'please_enter_exercise_name');
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Date and Time
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(context, 'date'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat.yMMMd().format(_selectedDate),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(context, 'time'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 18,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedTime.format(context),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Sets
            Row(
              children: [
                Text(
                  tr(context, 'sets'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addSet,
                  icon: const Icon(Icons.add),
                  label: Text(tr(context, 'add_set')),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Column headers
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
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      tr(context, 'weight_kg'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      tr(context, 'reps'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  SizedBox(width: 40),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Set rows
            ...List.generate(_sets.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${index + 1}',
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
                          controller: _weightControllers[index],
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*$')),
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
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextFormField(
                          controller: _repsControllers[index],
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
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed:
                            _sets.length > 1 ? () => _removeSet(index) : null,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),

            // Advanced metrics (Distance/Duration) - toggleable in a real app
            /*
            ExpansionTile(
              title: Text(tr(context, 'advanced_metrics')),
              children: [
                // Distance/duration fields would go here
              ],
            ),
            const SizedBox(height: 24),
            */

            // Notes
            Text(
              tr(context, 'notes'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: tr(context, 'enter_notes'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _saveLog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.existingLog != null
                    ? tr(context, 'update_log')
                    : tr(context, 'save_log'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _exerciseNameController.dispose();
    _notesController.dispose();

    for (var controller in _weightControllers) {
      controller.dispose();
    }

    for (var controller in _repsControllers) {
      controller.dispose();
    }

    for (var controller in _distanceControllers) {
      controller.dispose();
    }

    for (var controller in _durationControllers) {
      controller.dispose();
    }

    super.dispose();
  }
}
