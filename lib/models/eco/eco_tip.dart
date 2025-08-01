// lib/screens/eco_tips/models/eco_tip.dart
class EcoTip {
  final String titleKey;
  final String descriptionKey;
  final String category;
  final String imagePath;

  const EcoTip({
    required this.titleKey,
    required this.descriptionKey,
    required this.category,
    required this.imagePath,
  });
}
