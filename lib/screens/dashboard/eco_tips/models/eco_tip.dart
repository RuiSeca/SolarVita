// lib/screens/eco_tips/models/eco_tip.dart
class EcoTip {
  final String title;
  final String description;
  final String? imagePath;
  final String category;

  EcoTip({
    required this.title,
    required this.description,
    this.imagePath,
    required this.category,
  });
}
