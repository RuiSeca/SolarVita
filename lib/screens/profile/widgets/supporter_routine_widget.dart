// lib/screens/profile/widgets/supporter_routine_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';
import '../../../models/exercise/workout_routine.dart';
import '../../../models/exercise/exercise_log.dart';
import '../../../models/user/privacy_settings.dart';
import '../../../services/database/firebase_routine_service.dart';
import '../../../widgets/common/exercise_image.dart';
import '../../search/workout_detail/workout_detail_screen.dart';
import '../../search/workout_detail/models/workout_item.dart';

class SupporterRoutineWidget extends StatefulWidget {
  final String supporterId;
  final PrivacySettings privacySettings;

  const SupporterRoutineWidget({
    super.key,
    required this.supporterId,
    required this.privacySettings,
  });

  @override
  State<SupporterRoutineWidget> createState() => _SupporterRoutineWidgetState();
}

class _SupporterRoutineWidgetState extends State<SupporterRoutineWidget> {
  final FirebaseRoutineService _firebaseRoutineService =
      FirebaseRoutineService();
  WorkoutRoutine? _activeRoutine;
  ExerciseLog? _lastLoggedExercise;
  Map<String, dynamic>? _weeklyProgress;
  bool _isLoading = true;
  bool _isExpanded = false;
  bool _isCopying = false;

  @override
  void initState() {
    super.initState();
    _loadRoutineData();
  }

  Future<void> _loadRoutineData() async {
    if (!widget.privacySettings.showWorkoutStats) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Get routine and recent exercise data from Firebase
      final routine = await _firebaseRoutineService.getUserActiveRoutine(
        widget.supporterId,
      );
      final lastExercise = await _firebaseRoutineService.getLastLoggedExercise(
        widget.supporterId,
      );

      // Get weekly progress data if routine exists
      Map<String, dynamic>? weeklyProgress;
      if (routine != null) {
        weeklyProgress = await _firebaseRoutineService.getWeeklyProgress(
          widget.supporterId,
          routine.id,
        );
      }

      if (mounted) {
        setState(() {
          _activeRoutine = routine;
          _lastLoggedExercise = lastExercise;
          _weeklyProgress = weeklyProgress;
          _isLoading = false;
        });
      }
    } catch (e) {
      // If Firebase fails, this could be the user's own profile, so try to show message about syncing
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.privacySettings.showWorkoutStats) {
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryColor.withAlpha(26)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_activeRoutine == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withAlpha(51)),
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_sync, size: 48, color: Colors.grey.withAlpha(128)),
            const SizedBox(height: 12),
            Text(
              'No Routine Found',
              style: TextStyle(
                color: AppTheme.textColor(context),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This user\'s routine may not be synced to Firebase yet.\n\nIf this is your profile, use the Debug Menu to sync your routines.',
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.red.withValues(alpha: 0.1),
            Colors.deepOrange.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with routine info
          _buildRoutineHeader(),

          // Preview content
          if (!_isExpanded) _buildRoutinePreview(),

          // Expanded content
          if (_isExpanded) _buildExpandedContent(),

          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildRoutineHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.fitness_center, color: Colors.red, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(context, 'active_routine'),
                  style: TextStyle(
                    color: AppTheme.textColor(context).withAlpha(179),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _activeRoutine!.name,
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Weekly completion indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'This Week',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_activeRoutine!.description != null &&
                    _activeRoutine!.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _activeRoutine!.description!,
                    style: TextStyle(
                      color: AppTheme.textColor(context).withAlpha(179),
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                // Weekly progress bar
                _buildWeeklyProgressBar(),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            icon: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutinePreview() {
    final todayName = DateFormat.EEEE().format(DateTime.now());
    final todayWorkout = _activeRoutine!.weeklyPlan.firstWhere(
      (day) => day.dayName.toLowerCase() == todayName.toLowerCase(),
      orElse: () => _activeRoutine!.weeklyPlan.first,
    );

    return Column(
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${tr(context, 'today')}: ${tr(context, todayName.toLowerCase())}',
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: todayWorkout.isRestDay
                          ? Colors.orange.withAlpha(26)
                          : AppTheme.primaryColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      todayWorkout.isRestDay
                          ? tr(context, 'rest_day')
                          : '${todayWorkout.exercises.length} ${tr(context, 'exercises')}',
                      style: TextStyle(
                        color: todayWorkout.isRestDay
                            ? Colors.orange
                            : AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              if (!todayWorkout.isRestDay &&
                  todayWorkout.exercises.isNotEmpty) ...[
                const SizedBox(height: 16),
                ...todayWorkout.exercises
                    .take(3)
                    .map((exercise) => _buildExercisePreviewItem(exercise)),
                if (todayWorkout.exercises.length > 3) ...[
                  const SizedBox(height: 8),
                  Text(
                    '+${todayWorkout.exercises.length - 3} ${tr(context, 'more_exercises')}',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],

              // Last logged exercise info
              if (_lastLoggedExercise != null) ...[
                const SizedBox(height: 16),
                _buildLastLoggedExercise(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExercisePreviewItem(WorkoutItem exercise) {
    // Check if this exercise has been completed (simulated based on last logged exercise)
    final isCompleted =
        _lastLoggedExercise?.exerciseName.toLowerCase() ==
        exercise.title.toLowerCase();
    final estimatedSets = _getEstimatedSets(exercise);
    final estimatedReps = _getEstimatedReps(exercise);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
          width: 1,
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
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              if (isCompleted)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check, color: Colors.white, size: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        exercise.title,
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isCompleted ? 'Done' : 'Pending',
                        style: TextStyle(
                          color: isCompleted
                              ? Colors.green
                              : Colors.orange.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (estimatedSets > 0) ...[
                      Icon(Icons.repeat, size: 12, color: Colors.red),
                      const SizedBox(width: 2),
                      Text(
                        '${estimatedSets}x',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (estimatedReps > 0) ...[
                      Text(
                        '$estimatedReps reps',
                        style: TextStyle(
                          color: AppTheme.textColor(context).withAlpha(179),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Icon(
                      Icons.timer,
                      size: 12,
                      color: AppTheme.textColor(context).withAlpha(179),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      exercise.duration,
                      style: TextStyle(
                        color: AppTheme.textColor(context).withAlpha(179),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(
                          exercise.difficulty,
                        ).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        exercise.difficulty,
                        style: TextStyle(
                          color: _getDifficultyColor(exercise.difficulty),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to estimate sets from exercise steps
  int _getEstimatedSets(WorkoutItem exercise) {
    if (exercise.steps.isEmpty) return 3; // Default
    // Look for numbered steps or repetition patterns
    final stepTitles = exercise.steps
        .map((s) => s.title.toLowerCase())
        .toList();
    final setPattern = RegExp(r'set (\d+)|(\d+) sets?|(\d+)x');

    for (final title in stepTitles) {
      final match = setPattern.firstMatch(title);
      if (match != null) {
        final setNum = int.tryParse(
          match.group(1) ?? match.group(2) ?? match.group(3) ?? '',
        );
        if (setNum != null && setNum > 0) return setNum;
      }
    }

    // If steps suggest repetition, estimate based on step count
    if (stepTitles.any((t) => t.contains('repeat') || t.contains('again'))) {
      return (exercise.steps.length / 2).ceil().clamp(2, 5);
    }

    return 3; // Default estimate
  }

  // Helper method to estimate reps from exercise content
  int _getEstimatedReps(WorkoutItem exercise) {
    final description =
        '${exercise.description} ${exercise.steps.map((s) => s.description).join(' ')}'
            .toLowerCase();
    final repPattern = RegExp(r'(\d+)\s*(?:reps?|repetitions?|times?)');

    final match = repPattern.firstMatch(description);
    if (match != null) {
      final reps = int.tryParse(match.group(1) ?? '');
      if (reps != null && reps > 0) return reps;
    }

    // Default based on difficulty
    switch (exercise.difficulty.toLowerCase()) {
      case 'easy':
        return 15;
      case 'medium':
        return 12;
      case 'hard':
        return 10;
      default:
        return 12;
    }
  }

  // Helper method to get difficulty color
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  // Build weekly progress bar showing completion status
  Widget _buildWeeklyProgressBar() {
    if (_activeRoutine == null) return const SizedBox.shrink();

    // Calculate completion based on Firebase weekly progress data or fallback to estimates
    final todayName = DateFormat.EEEE().format(DateTime.now());
    int totalExercises = 0;
    int completedExercises = 0;

    if (_weeklyProgress != null && _weeklyProgress!['dailyProgress'] != null) {
      // Use real Firebase progress data
      final dailyProgress =
          _weeklyProgress!['dailyProgress'] as Map<String, dynamic>;

      // Count total and completed exercises from daily progress
      for (final dayData in dailyProgress.values) {
        if (dayData is Map<String, dynamic>) {
          final plannedCount = dayData['plannedExercises'] as int? ?? 0;
          final completedIds = List<String>.from(
            dayData['completedExerciseIds'] ?? [],
          );
          totalExercises += plannedCount;
          completedExercises += completedIds.length;
        }
      }

      // If no planned exercises recorded, fall back to routine structure
      if (totalExercises == 0) {
        totalExercises = _activeRoutine!.weeklyPlan.fold(
          0,
          (sum, day) => sum + day.exercises.length,
        );
      }
    } else {
      // Fallback to routine structure and estimates
      totalExercises = _activeRoutine!.weeklyPlan.fold(
        0,
        (sum, day) => sum + day.exercises.length,
      );
      completedExercises = _lastLoggedExercise != null
          ? 1
          : 0; // Simplified - only count if we have recent activity
    }

    final progressPercentage = totalExercises > 0
        ? (completedExercises / totalExercises)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Weekly Progress',
              style: TextStyle(
                color: AppTheme.textColor(context).withAlpha(179),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$completedExercises/$totalExercises exercises',
              style: TextStyle(
                color: Colors.red,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progressPercentage,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                progressPercentage > 0.7
                    ? Colors.green
                    : progressPercentage > 0.3
                    ? Colors.orange
                    : Colors.red,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.today, size: 12, color: Colors.red),
            const SizedBox(width: 4),
            Text(
              'Today: $todayName',
              style: TextStyle(
                color: AppTheme.textColor(context).withAlpha(179),
                fontSize: 11,
              ),
            ),
            const Spacer(),
            if (_lastLoggedExercise != null) ...[
              Icon(Icons.check_circle, size: 12, color: Colors.green),
              const SizedBox(width: 2),
              Text(
                'Active',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else ...[
              Icon(Icons.schedule, size: 12, color: Colors.orange),
              const SizedBox(width: 2),
              Text(
                'Not started',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildLastLoggedExercise() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                tr(context, 'last_logged_exercise'),
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  _lastLoggedExercise!.exerciseName,
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                DateFormat.MMMd().format(_lastLoggedExercise!.date),
                style: TextStyle(
                  color: AppTheme.textColor(context).withAlpha(179),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_lastLoggedExercise!.sets.length} sets • ${_lastLoggedExercise!.maxWeight.toStringAsFixed(1)}kg max',
            style: TextStyle(
              color: AppTheme.textColor(context).withAlpha(179),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Column(
      children: [
        const Divider(height: 1),
        Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(context, 'weekly_schedule'),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ..._activeRoutine!.weeklyPlan.map((day) => _buildDayItem(day)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayItem(DailyWorkout day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: day.isRestDay
            ? Colors.orange.withAlpha(13)
            : AppTheme.primaryColor.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: day.isRestDay
              ? Colors.orange.withAlpha(51)
              : AppTheme.primaryColor.withAlpha(51),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr(context, day.dayName.toLowerCase()),
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: day.isRestDay
                      ? Colors.orange.withAlpha(26)
                      : AppTheme.primaryColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  day.isRestDay
                      ? tr(context, 'rest')
                      : '${day.exercises.length}',
                  style: TextStyle(
                    color: day.isRestDay
                        ? Colors.orange
                        : AppTheme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (!day.isRestDay && day.exercises.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...day.exercises.map(
              (exercise) => _buildExpandedExerciseItem(exercise),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpandedExerciseItem(WorkoutItem exercise) {
    final isCompleted =
        _lastLoggedExercise?.exerciseName.toLowerCase() ==
        exercise.title.toLowerCase();
    final estimatedSets = _getEstimatedSets(exercise);
    final estimatedReps = _getEstimatedReps(exercise);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _navigateToExerciseDetail(exercise),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCompleted
                ? Colors.green.withValues(alpha: 0.1)
                : AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCompleted
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: ExerciseImage(
                      imageUrl: exercise.image,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (isCompleted)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check, color: Colors.white, size: 10),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            exercise.title,
                            style: TextStyle(
                              color: AppTheme.textColor(context),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isCompleted ? 'Done' : 'Pending',
                            style: TextStyle(
                              color: isCompleted
                                  ? Colors.green
                                  : Colors.orange.shade700,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (estimatedSets > 0) ...[
                          Icon(
                            Icons.repeat,
                            size: 10,
                            color: Colors.red.shade600,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${estimatedSets}x',
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (estimatedReps > 0) ...[
                          Text(
                            '$estimatedReps reps',
                            style: TextStyle(
                              color: AppTheme.textColor(context).withAlpha(179),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Icon(
                          Icons.timer,
                          size: 10,
                          color: AppTheme.textColor(context).withAlpha(179),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          exercise.duration,
                          style: TextStyle(
                            color: AppTheme.textColor(context).withAlpha(179),
                            fontSize: 10,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(
                              exercise.difficulty,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            exercise.difficulty,
                            style: TextStyle(
                              color: _getDifficultyColor(exercise.difficulty),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: AppTheme.textColor(context).withAlpha(128),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              icon: Icon(
                _isExpanded ? Icons.visibility_off : Icons.visibility,
                size: 16,
              ),
              label: Text(
                _isExpanded
                    ? tr(context, 'show_less')
                    : tr(context, 'view_details'),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isCopying ? null : _copyRoutine,
              icon: _isCopying
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.copy, size: 16),
              label: Text(
                _isCopying
                    ? tr(context, 'copying')
                    : tr(context, 'copy_routine'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
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

  Future<void> _copyRoutine() async {
    if (_activeRoutine == null || _isCopying) return;

    setState(() {
      _isCopying = true;
    });

    try {
      final success = await _firebaseRoutineService.copyRoutineFromUser(
        widget.supporterId,
        _activeRoutine!.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? tr(context, 'routine_copied_successfully')
                  : tr(context, 'failed_to_copy_routine'),
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'error_copying_routine')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCopying = false;
        });
      }
    }
  }
}
