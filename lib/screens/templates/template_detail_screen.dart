import 'package:flutter/material.dart';
import '../../models/templates/workout_template.dart';
import '../../models/exercise/workout_routine.dart';
import '../../utils/translation_helper.dart';
import '../../theme/app_theme.dart';
import 'template_workout_screen.dart';
import '../routine/routine_creation_screen.dart';

class TemplateDetailScreen extends StatelessWidget {
  final WorkoutTemplate template;

  const TemplateDetailScreen({
    super.key,
    required this.template,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor(context),
        elevation: 0,
        title: Text(
          template.name,
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
        actions: [
          PopupMenuButton(
            icon: Icon(
              Icons.more_vert,
              color: AppTheme.textColor(context),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'create_routine',
                child: Row(
                  children: [
                    const Icon(Icons.add_task),
                    const SizedBox(width: 8),
                    Text(tr(context, 'create_routine_from_template')),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'create_routine':
                  _createRoutineFromTemplate(context);
                  break;
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildTemplateInfo(context),
            _buildExercisesList(context),
            const SizedBox(height: 20),
            _buildActionButtons(context),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (template.imageUrl != null)
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(template.imageUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            template.description,
            style: TextStyle(
              color: AppTheme.textColor(context).withValues(alpha: 0.8),
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateInfo(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textColor(context).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  context,
                  Icons.schedule,
                  tr(context, 'duration'),
                  '${template.estimatedDuration} ${tr(context, 'minutes')}',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  context,
                  Icons.trending_up,
                  tr(context, 'difficulty'),
                  _getDifficultyLabel(context, template.difficulty),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  context,
                  Icons.category,
                  tr(context, 'category'),
                  _getCategoryLabel(context, template.category),
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  context,
                  Icons.fitness_center,
                  tr(context, 'exercises'),
                  '${template.exercises.length}',
                ),
              ),
            ],
          ),
          if (template.targetMuscles.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildTargetMuscles(context),
          ],
          if (template.equipment.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildEquipment(context),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 24,
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
          label,
          style: TextStyle(
            color: AppTheme.textColor(context).withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTargetMuscles(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'target_muscles'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: template.targetMuscles.map((muscle) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                tr(context, muscle.toLowerCase()),
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEquipment(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'equipment_needed'),
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: template.equipment.map((equipment) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.textColor(context).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.textColor(context).withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getEquipmentIcon(equipment),
                    size: 14,
                    color: AppTheme.textColor(context).withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    tr(context, equipment.toLowerCase()),
                    style: TextStyle(
                      color: AppTheme.textColor(context).withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildExercisesList(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'exercises'),
            style: TextStyle(
              color: AppTheme.textColor(context),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: template.exercises.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final exercise = template.exercises[index];
              return _buildExerciseCard(context, exercise, index + 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, TemplateExercise exercise, int position) {
    return Container(
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
          Row(
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
                    '$position',
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
                    if (exercise.description != null)
                      Text(
                        exercise.description!,
                        style: TextStyle(
                          color: AppTheme.textColor(context).withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSetsInfo(context, exercise),
          if (exercise.restSeconds != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.timer,
                  size: 16,
                  color: AppTheme.textColor(context).withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  '${tr(context, 'rest')}: ${exercise.restSeconds! ~/ 60}:${(exercise.restSeconds! % 60).toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: AppTheme.textColor(context).withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
          if (exercise.notes != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      exercise.notes!,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                      ),
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

  Widget _buildSetsInfo(BuildContext context, TemplateExercise exercise) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: exercise.sets.map((set) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.textColor(context).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (set.type != SetType.normal) ...[
                Text(
                  set.type.shortName,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                set.displayText,
                style: TextStyle(
                  color: AppTheme.textColor(context).withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getDifficultyLabel(BuildContext context, String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return tr(context, 'beginner');
      case 'intermediate':
        return tr(context, 'intermediate');
      case 'advanced':
        return tr(context, 'advanced');
      default:
        return difficulty;
    }
  }

  String _getCategoryLabel(BuildContext context, String category) {
    switch (category.toLowerCase()) {
      case 'strength':
        return tr(context, 'strength_training');
      case 'cardio':
        return tr(context, 'cardio');
      case 'flexibility':
        return tr(context, 'flexibility');
      case 'full_body':
        return tr(context, 'full_body');
      default:
        return category;
    }
  }

  IconData _getEquipmentIcon(String equipment) {
    switch (equipment.toLowerCase()) {
      case 'dumbbells':
        return Icons.fitness_center;
      case 'barbell':
        return Icons.fitness_center;
      case 'resistance_bands':
        return Icons.linear_scale;
      case 'pull_up_bar':
        return Icons.horizontal_rule;
      case 'none':
        return Icons.accessibility;
      default:
        return Icons.fitness_center;
    }
  }

  void _createRoutineFromTemplate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoutineCreationScreen(
          template: _convertTemplateToWorkoutRoutine(),
        ),
      ),
    );
  }
  
  WorkoutRoutine _convertTemplateToWorkoutRoutine() {
    // Convert the template to a WorkoutRoutine format for routine creation
    return WorkoutRoutine(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: template.name,
      weeklyPlan: _createDefaultWeeklyPlan(),
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      description: template.description,
      category: template.category,
      isActive: false,
    );
  }
  
  List<DailyWorkout> _createDefaultWeeklyPlan() {
    // Create a basic weekly plan that can be customized in routine creation
    return List.generate(7, (index) {
      final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return DailyWorkout(
        dayName: dayNames[index],
        isRestDay: index == 6, // Sunday as rest day by default
        exercises: [], // Will be populated in routine creation
      );
    });
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _createRoutineFromTemplate(context),
              icon: const Icon(Icons.add_task),
              label: Text(tr(context, 'create_routine')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor.withAlpha(51),
                foregroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _startWorkout(context),
              icon: const Icon(Icons.play_arrow),
              label: Text(tr(context, 'start_workout')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
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

  void _startWorkout(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TemplateWorkoutScreen(
          template: template,
        ),
      ),
    );
  }
}