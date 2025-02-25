import 'workout_step.dart';

class WorkoutItem {
  final String title;
  final String image;
  final String duration;
  final String difficulty;
  final String description;
  final double rating;
  final List<WorkoutStep> steps;
  final List<String> equipment;
  final String caloriesBurn;
  final List<String> tips;

  WorkoutItem({
    required this.title,
    required this.image,
    required this.duration,
    required this.difficulty,
    required this.description,
    required this.rating,
    required this.steps,
    required this.equipment,
    required this.caloriesBurn,
    required this.tips,
  });
}
