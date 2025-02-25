class WorkoutStep {
  final String title;
  final String duration;
  final String description;
  final List<String> instructions;
  final String gifUrl;
  bool isCompleted;

  WorkoutStep({
    required this.title,
    required this.duration,
    required this.description,
    required this.instructions,
    required this.gifUrl,
    this.isCompleted = false,
  });

  void toggleCompleted() {
    isCompleted = !isCompleted;
  }
}
