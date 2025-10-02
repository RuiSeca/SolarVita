class TranslatedMeal {
  final String id;
  final String originalLanguage;
  final String targetLanguage;
  final String originalName;
  final String translatedName;
  final List<String> originalInstructions;
  final List<String> translatedInstructions;
  final List<String> originalIngredients;
  final List<String> translatedIngredients;
  final List<String>? originalMeasures;
  final List<String>? translatedMeasures;
  final String? originalCategory;
  final String? translatedCategory;
  final String? originalArea;
  final String? translatedArea;
  final DateTime translatedAt;
  final String? youtubeUrl;
  final String? imagePath;
  final String? calories;
  final String? prepTime;
  final String? cookTime;
  final String? difficulty;
  final int? servings;
  final bool? isVegan;
  final Map<String, dynamic>? nutritionFacts;

  const TranslatedMeal({
    required this.id,
    required this.originalLanguage,
    required this.targetLanguage,
    required this.originalName,
    required this.translatedName,
    required this.originalInstructions,
    required this.translatedInstructions,
    required this.originalIngredients,
    required this.translatedIngredients,
    this.originalMeasures,
    this.translatedMeasures,
    this.originalCategory,
    this.translatedCategory,
    this.originalArea,
    this.translatedArea,
    required this.translatedAt,
    this.youtubeUrl,
    this.imagePath,
    this.calories,
    this.prepTime,
    this.cookTime,
    this.difficulty,
    this.servings,
    this.isVegan,
    this.nutritionFacts,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'originalLanguage': originalLanguage,
      'targetLanguage': targetLanguage,
      'originalName': originalName,
      'translatedName': translatedName,
      'originalInstructions': originalInstructions.join('|||'),
      'translatedInstructions': translatedInstructions.join('|||'),
      'originalIngredients': originalIngredients.join('|||'),
      'translatedIngredients': translatedIngredients.join('|||'),
      'originalMeasures': originalMeasures?.join('|||'),
      'translatedMeasures': translatedMeasures?.join('|||'),
      'originalCategory': originalCategory,
      'translatedCategory': translatedCategory,
      'originalArea': originalArea,
      'translatedArea': translatedArea,
      'translatedAt': translatedAt.millisecondsSinceEpoch,
      'youtubeUrl': youtubeUrl,
      'imagePath': imagePath,
      'calories': calories,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'difficulty': difficulty,
      'servings': servings,
      'isVegan': isVegan == true ? 1 : 0,
      'nutritionFacts': nutritionFacts?.entries.map((e) => '${e.key}:${e.value}').join('|||'),
    };
  }

  factory TranslatedMeal.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? nutritionFacts;
    if (map['nutritionFacts'] != null && map['nutritionFacts'] is String) {
      final nutritionString = map['nutritionFacts'] as String;
      nutritionFacts = {};
      for (final pair in nutritionString.split('|||')) {
        final parts = pair.split(':');
        if (parts.length == 2) {
          nutritionFacts[parts[0]] = parts[1];
        }
      }
    }

    return TranslatedMeal(
      id: map['id'] as String,
      originalLanguage: map['originalLanguage'] as String,
      targetLanguage: map['targetLanguage'] as String,
      originalName: map['originalName'] as String,
      translatedName: map['translatedName'] as String,
      originalInstructions: (map['originalInstructions'] as String? ?? '').split('|||'),
      translatedInstructions: (map['translatedInstructions'] as String? ?? '').split('|||'),
      originalIngredients: (map['originalIngredients'] as String? ?? '').split('|||'),
      translatedIngredients: (map['translatedIngredients'] as String? ?? '').split('|||'),
      originalMeasures: (map['originalMeasures'] as String?)?.split('|||'),
      translatedMeasures: (map['translatedMeasures'] as String?)?.split('|||'),
      originalCategory: map['originalCategory'] as String?,
      translatedCategory: map['translatedCategory'] as String?,
      originalArea: map['originalArea'] as String?,
      translatedArea: map['translatedArea'] as String?,
      translatedAt: DateTime.fromMillisecondsSinceEpoch(map['translatedAt'] as int),
      youtubeUrl: map['youtubeUrl'] as String?,
      imagePath: map['imagePath'] as String?,
      calories: map['calories'] as String?,
      prepTime: map['prepTime'] as String?,
      cookTime: map['cookTime'] as String?,
      difficulty: map['difficulty'] as String?,
      servings: map['servings'] as int?,
      isVegan: (map['isVegan'] as int?) == 1,
      nutritionFacts: nutritionFacts,
    );
  }

  TranslatedMeal copyWith({
    String? id,
    String? originalLanguage,
    String? targetLanguage,
    String? originalName,
    String? translatedName,
    List<String>? originalInstructions,
    List<String>? translatedInstructions,
    List<String>? originalIngredients,
    List<String>? translatedIngredients,
    List<String>? originalMeasures,
    List<String>? translatedMeasures,
    String? originalCategory,
    String? translatedCategory,
    String? originalArea,
    String? translatedArea,
    DateTime? translatedAt,
    String? youtubeUrl,
    String? imagePath,
    String? calories,
    String? prepTime,
    String? cookTime,
    String? difficulty,
    int? servings,
    bool? isVegan,
    Map<String, dynamic>? nutritionFacts,
  }) {
    return TranslatedMeal(
      id: id ?? this.id,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      originalName: originalName ?? this.originalName,
      translatedName: translatedName ?? this.translatedName,
      originalInstructions: originalInstructions ?? this.originalInstructions,
      translatedInstructions: translatedInstructions ?? this.translatedInstructions,
      originalIngredients: originalIngredients ?? this.originalIngredients,
      translatedIngredients: translatedIngredients ?? this.translatedIngredients,
      originalMeasures: originalMeasures ?? this.originalMeasures,
      translatedMeasures: translatedMeasures ?? this.translatedMeasures,
      originalCategory: originalCategory ?? this.originalCategory,
      translatedCategory: translatedCategory ?? this.translatedCategory,
      originalArea: originalArea ?? this.originalArea,
      translatedArea: translatedArea ?? this.translatedArea,
      translatedAt: translatedAt ?? this.translatedAt,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      imagePath: imagePath ?? this.imagePath,
      calories: calories ?? this.calories,
      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
      difficulty: difficulty ?? this.difficulty,
      servings: servings ?? this.servings,
      isVegan: isVegan ?? this.isVegan,
      nutritionFacts: nutritionFacts ?? this.nutritionFacts,
    );
  }
}