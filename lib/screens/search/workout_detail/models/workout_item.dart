// lib/screens/search/workout_detail/models/workout_item.dart
import 'workout_step.dart';

class WorkoutItem {
  final String title;
  final String image;
  final String duration;
  final String difficulty;
  final String description;
  final double rating;
  final int ratingCount;
  final List<WorkoutStep> steps;
  final List<String> equipment;
  final String caloriesBurn;
  final List<String> tips;

  const WorkoutItem({
    required this.title,
    required this.image,
    required this.duration,
    required this.difficulty,
    required this.description,
    required this.rating,
    this.ratingCount = 0,
    required this.steps,
    this.equipment = const [],
    required this.caloriesBurn,
    this.tips = const [],
  });
}
