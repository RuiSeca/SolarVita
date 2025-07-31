// lib/screens/exercise_history/log_exercise_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/exercise_log.dart';
import '../../models/personal_record.dart';
import '../../services/exercise_tracking_service.dart';
import '../../services/exercise_routine_sync_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../../providers/routine_providers.dart';
import '../search/workout_detail/models/workout_item.dart';
import '../search/search_screen.dart';
import 'exercise_history_screen.dart';

class LogExerciseScreen extends ConsumerStatefulWidget {
  final String? exerciseId; // Optional - if coming from a specific exercise
  final String? initialExerciseName; // Add this parameter to fix the error
  final ExerciseLog? existingLog; // Optional - if editing an existing log
  final String? routineId; // For routine linking
  final String? dayName; // For routine linking

  const LogExerciseScreen({
    super.key,
    this.exerciseId,
    this.initialExerciseName, // Added parameter
    this.existingLog,
    this.routineId,
    this.dayName,
  });

  @override
  ConsumerState<LogExerciseScreen> createState() => _LogExerciseScreenState();
}

class _LogExerciseScreenState extends ConsumerState<LogExerciseScreen> {
  final ExerciseTrackingService _trackingService = ExerciseTrackingService();
  final ExerciseRoutineSyncService _syncService = ExerciseRoutineSyncService();
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

  // Auto-fill and personal records data
  Map<String, dynamic> _autoFillData = {};
  List<PersonalRecord> _personalRecords = [];
  bool _isLoadingAutoFill = false;

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
      _exerciseNameController = TextEditingController(text: widget.initialExerciseName ?? '');
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
      _sets = [ExerciseSet(setNumber: 1, weight: 0, reps: 0)];
      _notesController = TextEditingController();
    }

    // Initialize controllers for each set
    _initializeSetControllers();

    // Load auto-fill data if we have an exercise ID
    if (_exerciseId.isNotEmpty) {
      _loadAutoFillData();
    }
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
        _exerciseId = result.title.hashCode.toString(); // Use same ID format as dynamic duration service
        _exerciseNameController.text = result.title;
      });
      // Load auto-fill data for the new exercise
      _loadAutoFillData();
    }
  }

  Future<void> _loadAutoFillData() async {
    if (_exerciseId.isEmpty) return;

    setState(() {
      _isLoadingAutoFill = true;
    });

    try {
      final autoFillData = await _syncService.getAutoFillData(
        _exerciseId,
        routineId: widget.routineId,
      );
      final personalRecords = await _syncService.getPersonalRecordsForExercise(_exerciseId);

      setState(() {
        _autoFillData = autoFillData;
        _personalRecords = personalRecords;
        _isLoadingAutoFill = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAutoFill = false;
      });
    }
  }

  void _applyAutoFill() {
    if (_autoFillData.isEmpty || _autoFillData['lastLog'] == null) return;

    final lastLog = _autoFillData['lastLog'];
    final lastSets = lastLog['sets'] as List<dynamic>?;
    
    if (lastSets != null && lastSets.isNotEmpty) {
      setState(() {
        // Clear current sets
        _sets.clear();
        _weightControllers.clear();
        _repsControllers.clear();
        _distanceControllers.clear();
        _durationControllers.clear();

        // Apply last log data
        for (int i = 0; i < lastSets.length; i++) {
          final setData = lastSets[i] as Map<String, dynamic>;
          
          _sets.add(ExerciseSet(
            setNumber: i + 1,
            weight: setData['weight']?.toDouble() ?? 0.0,
            reps: setData['reps'] ?? 0,
            distance: setData['distance']?.toDouble(),
            duration: setData['duration'] != null 
                ? Duration(seconds: setData['duration']) 
                : null,
          ));
        }

        // Initialize controllers with the new data
        _initializeSetControllers();

        // Apply notes if available
        if (lastLog['notes'] != null && lastLog['notes'].toString().isNotEmpty) {
          _notesController.text = lastLog['notes'];
        }
      });

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'auto_fill_applied')),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
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
              primary: AppTheme.primaryColor,
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
              primary: AppTheme.primaryColor,
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

    bool success = false;

    if (widget.existingLog != null) {
      // Update existing log using traditional service
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final log = ExerciseLog(
        id: widget.existingLog!.id,
        exerciseId: _exerciseId,
        exerciseName: _exerciseNameController.text,
        date: dateTime,
        sets: _sets,
        notes: _notesController.text,
        routineId: widget.routineId,
        dayName: widget.dayName,
      );

      success = await _trackingService.updateLog(log);
    } else {
      // Create new log using sync service for routine integration
      success = await _syncService.logExerciseToRoutine(
        exerciseId: _exerciseId,
        exerciseName: _exerciseNameController.text,
        sets: _sets,
        notes: _notesController.text,
        routineId: widget.routineId,
        dayName: widget.dayName,
      );
    }

    if (mounted) {
      if (success) {
        // Force immediate state updates before navigation
        if (widget.routineId != null) {
          // Clear cache first to ensure fresh data
          final syncService = ref.read(exerciseRoutineSyncServiceProvider);
          syncService.clearProgressCache(widget.routineId!);
          
          // Invalidate all related providers
          ref.invalidate(weeklyProgressProvider(widget.routineId!));
          ref.invalidate(routineStatsProvider(widget.routineId!));
          ref.invalidate(routineManagerProvider);
          
          // Providers will refresh automatically after invalidation
        }
        
        // Navigate to exercise history after successful log
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            // Navigate to exercise history screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ExerciseHistoryScreen(
                  exerciseId: _exerciseId,
                  initialTitle: _exerciseNameController.text,
                ),
              ),
            );
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'error_saving_log')),
            backgroundColor: Colors.red,
          ),
        );
      }
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
            const SizedBox(height: 16),

            // Auto-fill and Personal Records section
            if (_exerciseId.isNotEmpty) ...[
              _buildAutoFillSection(),
              const SizedBox(height: 16),
            ],

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

  Widget _buildAutoFillSection() {
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr(context, 'smart_logging'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_isLoadingAutoFill)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Auto-fill section
          if (_autoFillData.isNotEmpty && _autoFillData['lastLog'] != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(13),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.history,
                        color: AppTheme.primaryColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tr(context, 'last_workout'),
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _applyAutoFill,
                        child: Text(
                          tr(context, 'use_data'),
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildLastWorkoutPreview(),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Personal Records section
          if (_personalRecords.isNotEmpty) ...[
            Text(
              tr(context, 'personal_records'),
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ..._personalRecords.take(3).map((record) => _buildPersonalRecordItem(record)),
          ],
        ],
      ),
    );
  }

  Widget _buildLastWorkoutPreview() {
    if (_autoFillData.isEmpty || _autoFillData['lastLog'] == null) {
      return const SizedBox.shrink();
    }

    final lastLog = _autoFillData['lastLog'];
    final lastSets = lastLog['sets'] as List<dynamic>?;
    final wasThisWeek = lastLog['wasThisWeek'] ?? false;

    if (lastSets == null || lastSets.isEmpty) {
      return Text(
        tr(context, 'no_previous_data'),
        style: TextStyle(
          color: AppTheme.textColor(context).withAlpha(179),
          fontSize: 12,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          wasThisWeek 
              ? tr(context, 'earlier_this_week')
              : DateFormat.MMMd().format(DateTime.parse(lastLog['date'])),
          style: TextStyle(
            color: AppTheme.textColor(context).withAlpha(179),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${lastSets.length} ${tr(context, 'sets')} • ${lastSets.first['weight']}kg × ${lastSets.first['reps']}',
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalRecordItem(PersonalRecord record) {
    IconData icon;
    Color color;
    
    switch (record.recordType) {
      case 'Max Weight':
        icon = Icons.fitness_center;
        color = Colors.blue;
        break;
      case 'Max Reps':
        icon = Icons.repeat;
        color = Colors.green;
        break;
      case 'Total Volume':
        icon = Icons.trending_up;
        color = Colors.orange;
        break;
      default:
        icon = Icons.star;
        color = AppTheme.primaryColor;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.recordType,
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${record.value.toStringAsFixed(record.recordType == 'Max Reps' ? 0 : 1)}${record.recordType.contains('Weight') || record.recordType.contains('Volume') ? 'kg' : record.recordType.contains('Distance') ? 'km' : ''}',
                  style: TextStyle(
                    color: AppTheme.textColor(context).withAlpha(179),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            DateFormat.MMMd().format(record.date),
            style: TextStyle(
              color: AppTheme.textColor(context).withAlpha(179),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
