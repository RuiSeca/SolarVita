// models/sustainable_products.dart
class SustainableProduct {
  final String nameKey;
  final String descriptionKey;
  final String imagePath;
  final String websiteUrl;
  final String discountCode;
  final int discountPercentage;

  const SustainableProduct({
    required this.nameKey,
    required this.descriptionKey,
    required this.imagePath,
    required this.websiteUrl,
    required this.discountCode,
    required this.discountPercentage,
  });
}
