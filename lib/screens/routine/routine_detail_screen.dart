import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../utils/translation_helper.dart';
import '../../models/exercise/workout_routine.dart';
import '../../providers/routine_providers.dart';
import '../../services/exercises/dynamic_duration_service.dart';
import 'day_workout_screen.dart';

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
  final DynamicDurationService _dynamicDurationService =
      DynamicDurationService();

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
                  if (_currentRoutine.isActive) ...[
                    _buildWeeklyProgress(),
                    const SizedBox(height: 24),
                  ],
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

  Widget _buildWeeklyProgress() {
    return Consumer(
      builder: (context, ref, child) {
        final statsAsync = ref.watch(routineStatsProvider(_currentRoutine.id));
        return statsAsync.when(
          loading: () => Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => const SizedBox.shrink(),
          data: (stats) => Container(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr(context, 'this_week_progress'),
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withAlpha(26),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${stats['completionPercentage']?.round() ?? 0}%',
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
                    widthFactor: (stats['completionPercentage'] ?? 0) / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: _buildProgressItem(
                        tr(context, 'completed'),
                        '${stats['totalExercisesCompleted'] ?? 0}',
                        Icons.check_circle,
                        AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildProgressItem(
                        tr(context, 'remaining'),
                        '${((stats['totalPlannedExercises'] ?? 0) - (stats['totalExercisesCompleted'] ?? 0)).clamp(0, double.infinity).toInt()}',
                        Icons.schedule,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildProgressItem(
                        tr(context, 'streak'),
                        '${stats['currentStreak'] ?? 0}',
                        Icons.local_fire_department,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
                child: FutureBuilder<double>(
                  future: _calculateWeeklyDynamicMinutes(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final dynamicMinutes = snapshot.data!.round();
                      final staticMinutes = (stats['totalMinutes'] as num)
                          .toDouble();
                      final improvement =
                          staticMinutes - dynamicMinutes.toDouble();

                      return _buildDynamicStatItem(
                        tr(context, 'weekly_minutes'),
                        '$dynamicMinutes',
                        staticMinutes.toString(),
                        improvement,
                        Icons.timer,
                      );
                    } else {
                      return _buildStatItem(
                        tr(context, 'weekly_minutes'),
                        '${stats['totalMinutes']}',
                        Icons.timer,
                      );
                    }
                  },
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
                child: FutureBuilder<double>(
                  future: _calculateAverageDynamicWorkoutTime(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final dynamicAvg = snapshot.data!.round();
                      final staticAvg = (stats['averageWorkoutTime'] as num)
                          .toDouble();
                      final improvement = staticAvg - dynamicAvg.toDouble();

                      return _buildDynamicStatItem(
                        tr(context, 'avg_workout'),
                        '$dynamicAvg min',
                        '$staticAvg min',
                        improvement,
                        Icons.schedule,
                      );
                    } else {
                      return _buildStatItem(
                        tr(context, 'avg_workout'),
                        '${stats['averageWorkoutTime']} min',
                        Icons.schedule,
                      );
                    }
                  },
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
                      Flexible(
                        child: Text(
                          tr(context, day.dayName.toLowerCase()),
                          style: TextStyle(
                            color: AppTheme.textColor(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
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
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.textColor(context).withAlpha(179),
                  size: 16,
                ),
                if (!day.isRestDay && day.exercises.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  FutureBuilder<DynamicWorkoutDuration>(
                    future: _dynamicDurationService.calculateDayDynamicDuration(
                      day,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final duration = snapshot.data!;
                        final staticTime = duration.formattedStaticDuration;
                        final dynamicTime = duration.formattedDynamicDuration;
                        final isFaster = duration.isFasterThanStatic;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Dynamic duration (prominent)
                            Text(
                              dynamicTime,
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            // Static duration comparison (subtle)
                            if (staticTime != dynamicTime) ...[
                              const SizedBox(height: 2),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isFaster
                                        ? Icons.trending_down
                                        : Icons.trending_up,
                                    color: isFaster
                                        ? Colors.green
                                        : Colors.orange,
                                    size: 10,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    staticTime,
                                    style: TextStyle(
                                      color: AppTheme.textColor(
                                        context,
                                      ).withAlpha(128),
                                      fontSize: 10,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        );
                      } else {
                        // Fallback to static duration while loading
                        return Text(
                          _getTotalDayDuration(day),
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }
                    },
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
          tr(context, 'actions_hub'),
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
      totalMinutes += _parseDurationToMinutes(exercise.duration);
    }
    return '${totalMinutes}min';
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
      final seconds =
          int.tryParse(lowerDuration.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
      return (seconds / 60).ceil(); // Convert seconds to minutes (round up)
    }

    // If it contains 'm' (minutes)
    if (lowerDuration.contains('m')) {
      final minutes =
          double.tryParse(lowerDuration.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
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

    // Always refresh providers when returning from day workout screen
    // This ensures stats and progress are updated if exercises were logged or rest day changes made
    if (mounted) {
      ref.invalidate(routineStatsProvider(_currentRoutine.id));
      ref.invalidate(routineManagerProvider);

      // Also reload the current routine from the updated manager
      _reloadCurrentRoutine();

      // Trigger background sync of planned exercises (in case exercises were added/removed)
      final syncService = ref.read(exerciseRoutineSyncServiceProvider);
      syncService.syncPlannedExercisesWithRoutine(_currentRoutine.id);
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

  // Calculate total weekly dynamic minutes
  Future<double> _calculateWeeklyDynamicMinutes() async {
    double total = 0;
    for (final day in _currentRoutine.weeklyPlan) {
      if (!day.isRestDay && day.exercises.isNotEmpty) {
        final dayDuration = await _dynamicDurationService
            .calculateDayDynamicDuration(day);
        total += dayDuration.totalDynamicMinutes;
      }
    }
    return total;
  }

  // Calculate average dynamic workout time
  Future<double> _calculateAverageDynamicWorkoutTime() async {
    final totalMinutes = await _calculateWeeklyDynamicMinutes();
    final workoutDays = _currentRoutine.weeklyPlan
        .where((day) => !day.isRestDay && day.exercises.isNotEmpty)
        .length;
    return workoutDays > 0 ? totalMinutes / workoutDays : 0;
  }

  // Build dynamic stat item with comparison
  Widget _buildDynamicStatItem(
    String title,
    String dynamicValue,
    String staticValue,
    double improvement,
    IconData icon,
  ) {
    final isImprovement = improvement > 0;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dynamicValue,
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (improvement.abs() > 0.5) ...[
                const SizedBox(width: 4),
                Icon(
                  isImprovement ? Icons.trending_down : Icons.trending_up,
                  color: isImprovement ? Colors.green : Colors.orange,
                  size: 12,
                ),
              ],
            ],
          ),
          if (improvement.abs() > 0.5) ...[
            const SizedBox(height: 2),
            Text(
              staticValue,
              style: TextStyle(
                color: AppTheme.textColor(context).withAlpha(128),
                fontSize: 10,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ],
          const SizedBox(height: 4),
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

  // Reload current routine from the updated routine manager
  void _reloadCurrentRoutine() async {
    try {
      final routineManager = await ref.read(routineManagerProvider.future);
      final updatedRoutine = routineManager.routines.firstWhere(
        (r) => r.id == _currentRoutine.id,
        orElse: () => _currentRoutine, // Fallback to current if not found
      );

      if (mounted) {
        setState(() {
          _currentRoutine = updatedRoutine;
        });
      }
    } catch (e) {
      // Handle error silently, keep current routine
    }
  }
}
