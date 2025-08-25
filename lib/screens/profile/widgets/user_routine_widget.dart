import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/translation_helper.dart';
import '../../../models/exercise/workout_routine.dart';
import '../../../services/database/routine_service.dart';
import '../../../widgets/common/exercise_image.dart';
import '../../search/workout_detail/workout_detail_screen.dart';
import '../../search/workout_detail/models/workout_item.dart';
import '../../../providers/riverpod/user_progress_provider.dart';

class UserRoutineWidget extends ConsumerStatefulWidget {
  const UserRoutineWidget({super.key});

  @override
  ConsumerState<UserRoutineWidget> createState() => _UserRoutineWidgetState();
}

class _UserRoutineWidgetState extends ConsumerState<UserRoutineWidget> {
  final RoutineService _routineService = RoutineService();
  WorkoutRoutine? _activeRoutine;
  Map<String, dynamic>? _weeklyProgress;
  bool _isLoading = true;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadRoutineData();
  }

  Future<void> _loadRoutineData() async {
    try {
      final manager = await _routineService.loadRoutineManager();
      final routine = manager.activeRoutine;
      final progress = await _calculateWeeklyProgress();
      
      if (mounted) {
        setState(() {
          _activeRoutine = routine;
          _weeklyProgress = progress;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _calculateWeeklyProgress() async {
    final userProgress = ref.read(userProgressNotifierProvider).value;
    if (userProgress == null) return {};

    int totalExercises = 0;
    int completedExercises = 0;

    if (_activeRoutine != null) {
      totalExercises = _activeRoutine!.weeklyPlan.fold(
        0,
        (sum, day) => sum + day.exercises.length,
      );

      // Simple calculation based on user progress data  
      // Use completedGoalsCount as a proxy for workout activity
      completedExercises = (userProgress.completedGoalsCount * 2).clamp(0, totalExercises);
    }

    return {
      'totalExercises': totalExercises,
      'completedExercises': completedExercises,
      'progressPercentage': totalExercises > 0 ? completedExercises / totalExercises : 0.0,
    };
  }

  @override
  Widget build(BuildContext context) {
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Navigate to routine creation/selection screen
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withAlpha(76),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(context, 'no_active_routine'),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tr(context, 'tap_to_create_routine'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue.withAlpha(179),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ),
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
          _buildRoutineHeader(),
          if (!_isExpanded) _buildRoutinePreview(),
          if (_isExpanded) _buildExpandedContent(),
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
                  tr(context, 'my_active_routine'),
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

  Widget _buildWeeklyProgressBar() {
    final totalExercises = _weeklyProgress?['totalExercises'] ?? 0;
    final completedExercises = _weeklyProgress?['completedExercises'] ?? 0;
    final progressPercentage = _weeklyProgress?['progressPercentage'] ?? 0.0;

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
              'Today: ${DateFormat.EEEE().format(DateTime.now())}',
              style: TextStyle(
                color: AppTheme.textColor(context).withAlpha(179),
                fontSize: 11,
              ),
            ),
            const Spacer(),
            if (completedExercises > 0) ...[
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
              if (!todayWorkout.isRestDay && todayWorkout.exercises.isNotEmpty) ...[
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExercisePreviewItem(WorkoutItem exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.title,
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.timer, size: 12, color: AppTheme.textColor(context).withAlpha(179)),
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
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(exercise.difficulty).withValues(alpha: 0.2),
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
                    color: day.isRestDay ? Colors.orange : AppTheme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (!day.isRestDay && day.exercises.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...day.exercises.map((exercise) => _buildExpandedExerciseItem(exercise)),
          ],
        ],
      ),
    );
  }

  Widget _buildExpandedExerciseItem(WorkoutItem exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _navigateToExerciseDetail(exercise),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.title,
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.timer, size: 10, color: AppTheme.textColor(context).withAlpha(179)),
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
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(exercise.difficulty).withValues(alpha: 0.2),
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
                _isExpanded ? tr(context, 'show_less') : tr(context, 'view_details'),
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
              onPressed: () {
                // Navigate to routine editing/management screen
              },
              icon: const Icon(Icons.edit, size: 16),
              label: Text(tr(context, 'manage_routine')),
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
}