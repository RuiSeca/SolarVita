// lib/screens/search/workout_detail/models/workout_step.dart
class WorkoutStep {
  final String title;
  final String duration;
  final String description;
  final List<String> instructions;
  final bool isCompleted;

  const WorkoutStep({
    required this.title,
    required this.duration,
    required this.description,
    required this.instructions,
    this.isCompleted = false,
  });
}
