import 'package:cloud_firestore/cloud_firestore.dart';

enum RecipeCategory {
  breakfast,
  lunch,
  dinner,
  snack,
  drink,
  dessert,
  appetizer,
  soup,
  salad,
  main,
  side
}

enum DietaryTag {
  vegan,
  vegetarian,
  glutenFree,
  dairyFree,
  nutFree,
  keto,
  paleo,
  lowCarb,
  highProtein,
  lowSodium,
  organic,
  raw,
  wholeFoods
}

enum DifficultyLevel {
  beginner,
  intermediate,
  advanced,
  expert
}

enum RecipeVisibility {
  public,      // Visible to everyone
  circles,     // Visible to supporter circles only
  friends,     // Visible to supporters only
  private      // Visible to creator only
}

class CommunityRecipe {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final List<String> imageUrls;
  final String creatorId;
  final String creatorName;
  final String? creatorPhotoURL;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Recipe Details
  final RecipeCategory category;
  final List<DietaryTag> dietaryTags;
  final DifficultyLevel difficulty;
  final RecipeVisibility visibility;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final int servings;

  // Ingredients & Instructions
  final List<RecipeIngredient> ingredients;
  final List<RecipeInstruction> instructions;
  final List<String> equipment;
  final Map<String, String> tips;

  // Nutrition Information
  final RecipeNutrition nutrition;

  // Community Features
  final RecipeRatings ratings;
  final List<String> collections; // Collections this recipe belongs to
  final List<String> tags; // Custom tags
  final Map<String, dynamic> variations; // Recipe variations shared by community
  final bool allowRemix; // Allow others to create variations

  // Eco Features
  final RecipeEcoInfo ecoInfo;

  // Metadata
  final String? originalRecipeId; // If this is a remix/variation
  final String? source; // External source if imported
  final Map<String, dynamic> metadata;

  CommunityRecipe({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.imageUrls = const [],
    required this.creatorId,
    required this.creatorName,
    this.creatorPhotoURL,
    required this.createdAt,
    this.updatedAt,
    required this.category,
    this.dietaryTags = const [],
    required this.difficulty,
    this.visibility = RecipeVisibility.public,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.servings,
    this.ingredients = const [],
    this.instructions = const [],
    this.equipment = const [],
    this.tips = const {},
    required this.nutrition,
    required this.ratings,
    this.collections = const [],
    this.tags = const [],
    this.variations = const {},
    this.allowRemix = true,
    required this.ecoInfo,
    this.originalRecipeId,
    this.source,
    this.metadata = const {},
  });

  factory CommunityRecipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityRecipe(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      creatorId: data['creatorId'] ?? '',
      creatorName: data['creatorName'] ?? '',
      creatorPhotoURL: data['creatorPhotoURL'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp?)?.toDate()
          : null,
      category: RecipeCategory.values[data['category'] ?? 0],
      dietaryTags: (data['dietaryTags'] as List<dynamic>? ?? [])
          .map((tag) => DietaryTag.values[tag])
          .toList(),
      difficulty: DifficultyLevel.values[data['difficulty'] ?? 0],
      visibility: RecipeVisibility.values[data['visibility'] ?? 0],
      prepTimeMinutes: data['prepTimeMinutes'] ?? 0,
      cookTimeMinutes: data['cookTimeMinutes'] ?? 0,
      servings: data['servings'] ?? 1,
      ingredients: (data['ingredients'] as List<dynamic>? ?? [])
          .map((i) => RecipeIngredient.fromMap(i))
          .toList(),
      instructions: (data['instructions'] as List<dynamic>? ?? [])
          .map((i) => RecipeInstruction.fromMap(i))
          .toList(),
      equipment: List<String>.from(data['equipment'] ?? []),
      tips: Map<String, String>.from(data['tips'] ?? {}),
      nutrition: RecipeNutrition.fromMap(data['nutrition'] ?? {}),
      ratings: RecipeRatings.fromMap(data['ratings'] ?? {}),
      collections: List<String>.from(data['collections'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      variations: Map<String, dynamic>.from(data['variations'] ?? {}),
      allowRemix: data['allowRemix'] ?? true,
      ecoInfo: RecipeEcoInfo.fromMap(data['ecoInfo'] ?? {}),
      originalRecipeId: data['originalRecipeId'],
      source: data['source'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'creatorPhotoURL': creatorPhotoURL,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'category': category.index,
      'dietaryTags': dietaryTags.map((tag) => tag.index).toList(),
      'difficulty': difficulty.index,
      'visibility': visibility.index,
      'prepTimeMinutes': prepTimeMinutes,
      'cookTimeMinutes': cookTimeMinutes,
      'servings': servings,
      'ingredients': ingredients.map((i) => i.toMap()).toList(),
      'instructions': instructions.map((i) => i.toMap()).toList(),
      'equipment': equipment,
      'tips': tips,
      'nutrition': nutrition.toMap(),
      'ratings': ratings.toMap(),
      'collections': collections,
      'tags': tags,
      'variations': variations,
      'allowRemix': allowRemix,
      'ecoInfo': ecoInfo.toMap(),
      'originalRecipeId': originalRecipeId,
      'source': source,
      'metadata': metadata,
    };
  }

  // Helper getters
  int get totalTimeMinutes => prepTimeMinutes + cookTimeMinutes;
  double get averageRating => ratings.averageRating;
  int get totalRatings => ratings.totalRatings;
  bool get isRemix => originalRecipeId != null;
  List<DietaryTag> get primaryDietaryTags => dietaryTags.take(3).toList();

  // Create a copy with modifications
  CommunityRecipe copyWith({
    String? title,
    String? description,
    String? imageUrl,
    List<String>? imageUrls,
    RecipeCategory? category,
    List<DietaryTag>? dietaryTags,
    DifficultyLevel? difficulty,
    RecipeVisibility? visibility,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
    int? servings,
    List<RecipeIngredient>? ingredients,
    List<RecipeInstruction>? instructions,
    List<String>? equipment,
    Map<String, String>? tips,
    RecipeNutrition? nutrition,
    List<String>? collections,
    List<String>? tags,
    bool? allowRemix,
    RecipeEcoInfo? ecoInfo,
  }) {
    return CommunityRecipe(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      creatorId: creatorId,
      creatorName: creatorName,
      creatorPhotoURL: creatorPhotoURL,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      category: category ?? this.category,
      dietaryTags: dietaryTags ?? this.dietaryTags,
      difficulty: difficulty ?? this.difficulty,
      visibility: visibility ?? this.visibility,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      servings: servings ?? this.servings,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      equipment: equipment ?? this.equipment,
      tips: tips ?? this.tips,
      nutrition: nutrition ?? this.nutrition,
      ratings: ratings,
      collections: collections ?? this.collections,
      tags: tags ?? this.tags,
      variations: variations,
      allowRemix: allowRemix ?? this.allowRemix,
      ecoInfo: ecoInfo ?? this.ecoInfo,
      originalRecipeId: originalRecipeId,
      source: source,
      metadata: metadata,
    );
  }
}

class RecipeIngredient {
  final String name;
  final double amount;
  final String unit;
  final String? notes;
  final bool optional;
  final List<String> substitutes;

  RecipeIngredient({
    required this.name,
    required this.amount,
    required this.unit,
    this.notes,
    this.optional = false,
    this.substitutes = const [],
  });

  factory RecipeIngredient.fromMap(Map<String, dynamic> data) {
    return RecipeIngredient(
      name: data['name'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      unit: data['unit'] ?? '',
      notes: data['notes'],
      optional: data['optional'] ?? false,
      substitutes: List<String>.from(data['substitutes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'unit': unit,
      'notes': notes,
      'optional': optional,
      'substitutes': substitutes,
    };
  }

  String get displayText {
    final amountText = amount == amount.roundToDouble()
        ? amount.round().toString()
        : amount.toString();
    return '$amountText $unit $name${optional ? ' (optional)' : ''}';
  }
}

class RecipeInstruction {
  final int step;
  final String instruction;
  final int? timeMinutes;
  final String? imageUrl;
  final List<String> tips;

  RecipeInstruction({
    required this.step,
    required this.instruction,
    this.timeMinutes,
    this.imageUrl,
    this.tips = const [],
  });

  factory RecipeInstruction.fromMap(Map<String, dynamic> data) {
    return RecipeInstruction(
      step: data['step'] ?? 0,
      instruction: data['instruction'] ?? '',
      timeMinutes: data['timeMinutes'],
      imageUrl: data['imageUrl'],
      tips: List<String>.from(data['tips'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'step': step,
      'instruction': instruction,
      'timeMinutes': timeMinutes,
      'imageUrl': imageUrl,
      'tips': tips,
    };
  }
}

class RecipeNutrition {
  final double? calories;
  final double? protein;
  final double? carbohydrates;
  final double? fat;
  final double? fiber;
  final double? sugar;
  final double? sodium;
  final Map<String, double> vitamins;
  final Map<String, double> minerals;

  RecipeNutrition({
    this.calories,
    this.protein,
    this.carbohydrates,
    this.fat,
    this.fiber,
    this.sugar,
    this.sodium,
    this.vitamins = const {},
    this.minerals = const {},
  });

  factory RecipeNutrition.fromMap(Map<String, dynamic> data) {
    return RecipeNutrition(
      calories: data['calories']?.toDouble(),
      protein: data['protein']?.toDouble(),
      carbohydrates: data['carbohydrates']?.toDouble(),
      fat: data['fat']?.toDouble(),
      fiber: data['fiber']?.toDouble(),
      sugar: data['sugar']?.toDouble(),
      sodium: data['sodium']?.toDouble(),
      vitamins: Map<String, double>.from(
        (data['vitamins'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v ?? 0).toDouble())),
      ),
      minerals: Map<String, double>.from(
        (data['minerals'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v ?? 0).toDouble())),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'calories': calories,
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'vitamins': vitamins,
      'minerals': minerals,
    };
  }

  bool get hasNutritionData {
    return calories != null || protein != null || carbohydrates != null || fat != null;
  }
}

class RecipeRatings {
  final double averageRating;
  final int totalRatings;
  final Map<int, int> ratingDistribution; // star -> count
  final DateTime? lastUpdated;

  RecipeRatings({
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.ratingDistribution = const {},
    this.lastUpdated,
  });

  factory RecipeRatings.fromMap(Map<String, dynamic> data) {
    return RecipeRatings(
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      totalRatings: data['totalRatings'] ?? 0,
      ratingDistribution: Map<int, int>.from(data['ratingDistribution'] ?? {}),
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'ratingDistribution': ratingDistribution,
      'lastUpdated': lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
    };
  }
}

class RecipeEcoInfo {
  final double? carbonFootprint; // kg CO2
  final int localIngredients; // count of local ingredients
  final int seasonalIngredients; // count of seasonal ingredients
  final bool organicFriendly;
  final bool zeroWaste;
  final List<String> sustainabilityTips;

  RecipeEcoInfo({
    this.carbonFootprint,
    this.localIngredients = 0,
    this.seasonalIngredients = 0,
    this.organicFriendly = false,
    this.zeroWaste = false,
    this.sustainabilityTips = const [],
  });

  factory RecipeEcoInfo.fromMap(Map<String, dynamic> data) {
    return RecipeEcoInfo(
      carbonFootprint: data['carbonFootprint']?.toDouble(),
      localIngredients: data['localIngredients'] ?? 0,
      seasonalIngredients: data['seasonalIngredients'] ?? 0,
      organicFriendly: data['organicFriendly'] ?? false,
      zeroWaste: data['zeroWaste'] ?? false,
      sustainabilityTips: List<String>.from(data['sustainabilityTips'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'carbonFootprint': carbonFootprint,
      'localIngredients': localIngredients,
      'seasonalIngredients': seasonalIngredients,
      'organicFriendly': organicFriendly,
      'zeroWaste': zeroWaste,
      'sustainabilityTips': sustainabilityTips,
    };
  }

  int get ecoScore {
    int score = 0;
    if (localIngredients > 0) score += localIngredients * 10;
    if (seasonalIngredients > 0) score += seasonalIngredients * 10;
    if (organicFriendly) score += 20;
    if (zeroWaste) score += 30;
    if (carbonFootprint != null && carbonFootprint! < 2.0) score += 25;
    return score.clamp(0, 100);
  }
}