import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../../models/workout_routine.dart';
import 'day_workout_screen.dart';
import 'routine_main_screen.dart';

class RoutineDetailScreen extends ConsumerStatefulWidget {
  final WorkoutRoutine routine;

  const RoutineDetailScreen({super.key, required this.routine});

  @override
  ConsumerState<RoutineDetailScreen> createState() =>
      _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends ConsumerState<RoutineDetailScreen> {
  late WorkoutRoutine _currentRoutine;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentRoutine = widget.routine;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: AppBar(
        title: Text(
          _currentRoutine.name,
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textColor(context)),
          onPressed: () => Navigator.pop(context, true),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppTheme.textColor(context)),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'activate',
                child: Row(
                  children: [
                    Icon(
                      _currentRoutine.isActive
                          ? Icons.check_circle
                          : Icons.play_circle_outline,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _currentRoutine.isActive
                          ? tr(context, 'active')
                          : tr(context, 'set_active'),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(
                      Icons.copy,
                      color: AppTheme.textColor(context),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(tr(context, 'duplicate')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(
                      Icons.edit,
                      color: AppTheme.textColor(context),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(tr(context, 'edit_name')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      tr(context, 'delete'),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRoutineStats(),
                  const SizedBox(height: 24),
                  _buildWeeklyCalendar(),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildRoutineStats() {
    final stats = ref
        .read(routineServiceProvider)
        .getRoutineStats(_currentRoutine);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withAlpha(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                tr(context, 'routine_stats'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_currentRoutine.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tr(context, 'active'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  tr(context, 'total_exercises'),
                  '${stats['totalExercises']}',
                  Icons.fitness_center,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  tr(context, 'weekly_minutes'),
                  '${stats['totalMinutes']}',
                  Icons.timer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  tr(context, 'workout_days'),
                  '${stats['workoutDays']}',
                  Icons.calendar_today,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  tr(context, 'avg_workout'),
                  '${stats['averageWorkoutTime']} min',
                  Icons.schedule,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
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
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCalendar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'weekly_schedule'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(7, (index) {
          final day = _currentRoutine.weeklyPlan[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildDayCard(day),
          );
        }),
      ],
    );
  }

  Widget _buildDayCard(DailyWorkout day) {
    final isToday = _isToday(day.dayName);

    return GestureDetector(
      onTap: () => _navigateToDayWorkout(day),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isToday
              ? AppTheme.primaryColor.withAlpha(26)
              : AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isToday
                ? AppTheme.primaryColor
                : AppTheme.primaryColor.withAlpha(26),
            width: isToday ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: day.isRestDay
                    ? Colors.orange.withAlpha(26)
                    : AppTheme.primaryColor.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(
                day.isRestDay ? Icons.bed : Icons.fitness_center,
                color: day.isRestDay ? Colors.orange : AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        tr(context, day.dayName.toLowerCase()),
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tr(context, 'today'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    day.isRestDay
                        ? tr(context, 'rest_day')
                        : day.exercises.isEmpty
                        ? tr(context, 'no_exercises')
                        : '${day.exercises.length} ${tr(context, 'exercises')}',
                    style: TextStyle(
                      color: AppTheme.textColor(context).withAlpha(179),
                      fontSize: 14,
                    ),
                  ),
                  if (day.notes?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      day.notes!,
                      style: TextStyle(
                        color: AppTheme.textColor(context).withAlpha(179),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Column(
              children: [
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.textColor(context).withAlpha(179),
                  size: 16,
                ),
                if (!day.isRestDay && day.exercises.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _getTotalDayDuration(day),
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'quick_actions'),
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
              child: ElevatedButton.icon(
                onPressed: _currentRoutine.isActive
                    ? null
                    : () => _setActiveRoutine(),
                icon: Icon(
                  _currentRoutine.isActive
                      ? Icons.check_circle
                      : Icons.play_circle_outline,
                ),
                label: Text(
                  _currentRoutine.isActive
                      ? tr(context, 'currently_active')
                      : tr(context, 'set_as_active'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentRoutine.isActive
                      ? Colors.grey
                      : AppTheme.primaryColor,
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
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _duplicateRoutine(),
                icon: const Icon(Icons.copy),
                label: Text(tr(context, 'duplicate_routine')),
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
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showDeleteDialog(),
                icon: const Icon(Icons.delete, color: Colors.red),
                label: Text(
                  tr(context, 'delete_routine'),
                  style: const TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool _isToday(String dayName) {
    final today = DateTime.now().weekday;
    final dayNames = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final todayName = dayNames[today - 1];
    return dayName.toLowerCase() == todayName;
  }

  String _getTotalDayDuration(DailyWorkout day) {
    int totalMinutes = 0;
    for (final exercise in day.exercises) {
      final durationText = exercise.duration.replaceAll(RegExp(r'[^\d]'), '');
      totalMinutes += int.tryParse(durationText) ?? 0;
    }
    return '${totalMinutes}min';
  }

  void _navigateToDayWorkout(DailyWorkout day) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DayWorkoutScreen(routine: _currentRoutine, dayWorkout: day),
      ),
    );

    if (result is WorkoutRoutine) {
      setState(() {
        _currentRoutine = result;
      });
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'activate':
        if (!_currentRoutine.isActive) {
          _setActiveRoutine();
        }
        break;
      case 'duplicate':
        _duplicateRoutine();
        break;
      case 'edit':
        _editRoutineName();
        break;
      case 'delete':
        _showDeleteDialog();
        break;
    }
  }

  void _setActiveRoutine() async {
    setState(() => _isLoading = true);

    try {
      final service = ref.read(routineServiceProvider);
      final updatedManager = await service.setActiveRoutine(_currentRoutine.id);
      final updatedRoutine = updatedManager.routines.firstWhere(
        (r) => r.id == _currentRoutine.id,
      );

      setState(() {
        _currentRoutine = updatedRoutine;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'routine_activated')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'error_activating_routine')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _duplicateRoutine() async {
    final nameController = TextEditingController(
      text: '${_currentRoutine.name} Copy',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'duplicate_routine')),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: tr(context, 'routine_name'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: Text(tr(context, 'duplicate')),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _isLoading = true);

      try {
        final service = ref.read(routineServiceProvider);
        await service.duplicateRoutine(_currentRoutine.id, result);

        setState(() => _isLoading = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr(context, 'routine_duplicated')),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _editRoutineName() async {
    final nameController = TextEditingController(text: _currentRoutine.name);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'edit_routine_name')),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: tr(context, 'routine_name'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: Text(tr(context, 'save')),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != _currentRoutine.name) {
      setState(() => _isLoading = true);

      try {
        final updatedRoutine = WorkoutRoutine(
          id: _currentRoutine.id,
          name: result,
          weeklyPlan: _currentRoutine.weeklyPlan,
          createdAt: _currentRoutine.createdAt,
          lastModified: DateTime.now(),
          description: _currentRoutine.description,
          category: _currentRoutine.category,
          isActive: _currentRoutine.isActive,
        );

        final service = ref.read(routineServiceProvider);
        await service.updateRoutine(updatedRoutine);

        setState(() {
          _currentRoutine = updatedRoutine;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr(context, 'routine_updated')),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr(context, 'error_updating_routine')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'delete_routine')),
        content: Text(tr(context, 'delete_routine_confirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRoutine();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              tr(context, 'delete'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteRoutine() async {
    setState(() => _isLoading = true);

    try {
      final service = ref.read(routineServiceProvider);
      await service.deleteRoutine(_currentRoutine.id);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'routine_deleted')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'error_deleting_routine')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
