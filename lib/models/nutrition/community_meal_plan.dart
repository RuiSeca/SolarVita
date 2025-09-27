import 'package:cloud_firestore/cloud_firestore.dart';

enum MealPlanType {
  personal,     // Individual meal plan
  family,       // Family shared meal plan
  circle,       // Supporter circle meal plan
  challenge     // Challenge-based meal plan
}

enum MealPlanVisibility {
  private,      // Only creator can see
  shared,       // Shared with specific people
  public        // Public for community inspiration
}

enum MealType {
  breakfast,
  morningSnack,
  lunch,
  afternoonSnack,
  dinner,
  eveningSnack,
  other
}

class CommunityMealPlan {
  final String id;
  final String title;
  final String? description;
  final String creatorId;
  final String creatorName;
  final String? creatorPhotoURL;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Plan Configuration
  final MealPlanType type;
  final MealPlanVisibility visibility;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> sharedWithIds; // User IDs with access
  final List<String> collaboratorIds; // Users who can edit

  // Meal Plan Content
  final Map<String, DayMealPlan> meals; // Date string -> DayMealPlan
  final MealPlanNutritionGoals nutritionGoals;
  final List<String> dietaryRestrictions;
  final Map<String, dynamic> preferences;

  // Community Features
  final MealPlanRatings ratings;
  final List<String> tags;
  final bool allowForks; // Allow others to create copies
  final String? originalPlanId; // If this is a fork

  // Shopping & Prep
  final Map<String, ShoppingList> shoppingLists; // Week -> ShoppingList
  final Map<String, PrepPlan> prepPlans; // Date -> PrepPlan

  // Analytics
  final MealPlanStats stats;

  CommunityMealPlan({
    required this.id,
    required this.title,
    this.description,
    required this.creatorId,
    required this.creatorName,
    this.creatorPhotoURL,
    required this.createdAt,
    this.updatedAt,
    required this.type,
    this.visibility = MealPlanVisibility.private,
    required this.startDate,
    required this.endDate,
    this.sharedWithIds = const [],
    this.collaboratorIds = const [],
    this.meals = const {},
    required this.nutritionGoals,
    this.dietaryRestrictions = const [],
    this.preferences = const {},
    required this.ratings,
    this.tags = const [],
    this.allowForks = true,
    this.originalPlanId,
    this.shoppingLists = const {},
    this.prepPlans = const {},
    required this.stats,
  });

  factory CommunityMealPlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityMealPlan(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      creatorId: data['creatorId'] ?? '',
      creatorName: data['creatorName'] ?? '',
      creatorPhotoURL: data['creatorPhotoURL'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp?)?.toDate()
          : null,
      type: MealPlanType.values[data['type'] ?? 0],
      visibility: MealPlanVisibility.values[data['visibility'] ?? 0],
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 7)),
      sharedWithIds: List<String>.from(data['sharedWithIds'] ?? []),
      collaboratorIds: List<String>.from(data['collaboratorIds'] ?? []),
      meals: (data['meals'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, DayMealPlan.fromMap(v))),
      nutritionGoals: MealPlanNutritionGoals.fromMap(data['nutritionGoals'] ?? {}),
      dietaryRestrictions: List<String>.from(data['dietaryRestrictions'] ?? []),
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
      ratings: MealPlanRatings.fromMap(data['ratings'] ?? {}),
      tags: List<String>.from(data['tags'] ?? []),
      allowForks: data['allowForks'] ?? true,
      originalPlanId: data['originalPlanId'],
      shoppingLists: (data['shoppingLists'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, ShoppingList.fromMap(v))),
      prepPlans: (data['prepPlans'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, PrepPlan.fromMap(v))),
      stats: MealPlanStats.fromMap(data['stats'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'creatorPhotoURL': creatorPhotoURL,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'type': type.index,
      'visibility': visibility.index,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'sharedWithIds': sharedWithIds,
      'collaboratorIds': collaboratorIds,
      'meals': meals.map((k, v) => MapEntry(k, v.toMap())),
      'nutritionGoals': nutritionGoals.toMap(),
      'dietaryRestrictions': dietaryRestrictions,
      'preferences': preferences,
      'ratings': ratings.toMap(),
      'tags': tags,
      'allowForks': allowForks,
      'originalPlanId': originalPlanId,
      'shoppingLists': shoppingLists.map((k, v) => MapEntry(k, v.toMap())),
      'prepPlans': prepPlans.map((k, v) => MapEntry(k, v.toMap())),
      'stats': stats.toMap(),
    };
  }

  // Helper getters
  int get durationDays => endDate.difference(startDate).inDays + 1;
  bool get isFork => originalPlanId != null;
  double get averageRating => ratings.averageRating;
  bool get isActive => DateTime.now().isBefore(endDate) && DateTime.now().isAfter(startDate);
}

class DayMealPlan {
  final String date; // YYYY-MM-DD format
  final Map<MealType, List<PlannedMeal>> meals;
  final double? targetCalories;
  final Map<String, double> targetMacros;
  final String? notes;

  DayMealPlan({
    required this.date,
    this.meals = const {},
    this.targetCalories,
    this.targetMacros = const {},
    this.notes,
  });

  factory DayMealPlan.fromMap(Map<String, dynamic> data) {
    return DayMealPlan(
      date: data['date'] ?? '',
      meals: (data['meals'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(
                MealType.values[int.parse(k)],
                (v as List<dynamic>).map((m) => PlannedMeal.fromMap(m)).toList(),
              )),
      targetCalories: data['targetCalories']?.toDouble(),
      targetMacros: Map<String, double>.from(
        (data['targetMacros'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v ?? 0).toDouble())),
      ),
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'meals': meals.map((k, v) => MapEntry(k.index.toString(), v.map((m) => m.toMap()).toList())),
      'targetCalories': targetCalories,
      'targetMacros': targetMacros,
      'notes': notes,
    };
  }

  // Helper methods
  List<PlannedMeal> getAllMeals() {
    return meals.values.expand((mealList) => mealList).toList();
  }

  double get totalCalories {
    return getAllMeals().fold(0.0, (total, meal) => total + (meal.calories ?? 0));
  }
}

class PlannedMeal {
  final String? recipeId;
  final String? customMealName;
  final String? customDescription;
  final double servings;
  final double? calories;
  final Map<String, double> macros;
  final DateTime? scheduledTime;
  final bool completed;
  final String? notes;
  final List<String> modifications; // Any modifications to the original recipe

  PlannedMeal({
    this.recipeId,
    this.customMealName,
    this.customDescription,
    this.servings = 1.0,
    this.calories,
    this.macros = const {},
    this.scheduledTime,
    this.completed = false,
    this.notes,
    this.modifications = const [],
  });

  factory PlannedMeal.fromMap(Map<String, dynamic> data) {
    return PlannedMeal(
      recipeId: data['recipeId'],
      customMealName: data['customMealName'],
      customDescription: data['customDescription'],
      servings: (data['servings'] ?? 1.0).toDouble(),
      calories: data['calories']?.toDouble(),
      macros: Map<String, double>.from(
        (data['macros'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v ?? 0).toDouble())),
      ),
      scheduledTime: data['scheduledTime'] != null
          ? (data['scheduledTime'] as Timestamp).toDate()
          : null,
      completed: data['completed'] ?? false,
      notes: data['notes'],
      modifications: List<String>.from(data['modifications'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipeId': recipeId,
      'customMealName': customMealName,
      'customDescription': customDescription,
      'servings': servings,
      'calories': calories,
      'macros': macros,
      'scheduledTime': scheduledTime != null ? Timestamp.fromDate(scheduledTime!) : null,
      'completed': completed,
      'notes': notes,
      'modifications': modifications,
    };
  }

  bool get isRecipe => recipeId != null;
  bool get isCustomMeal => customMealName != null;
  String get displayName => customMealName ?? 'Recipe Meal';
}

class MealPlanNutritionGoals {
  final double? dailyCalories;
  final double? proteinGrams;
  final double? carbGrams;
  final double? fatGrams;
  final double? fiberGrams;
  final Map<String, double> vitamins;
  final Map<String, double> minerals;
  final Map<String, double> customGoals;

  MealPlanNutritionGoals({
    this.dailyCalories,
    this.proteinGrams,
    this.carbGrams,
    this.fatGrams,
    this.fiberGrams,
    this.vitamins = const {},
    this.minerals = const {},
    this.customGoals = const {},
  });

  factory MealPlanNutritionGoals.fromMap(Map<String, dynamic> data) {
    return MealPlanNutritionGoals(
      dailyCalories: data['dailyCalories']?.toDouble(),
      proteinGrams: data['proteinGrams']?.toDouble(),
      carbGrams: data['carbGrams']?.toDouble(),
      fatGrams: data['fatGrams']?.toDouble(),
      fiberGrams: data['fiberGrams']?.toDouble(),
      vitamins: Map<String, double>.from(
        (data['vitamins'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v ?? 0).toDouble())),
      ),
      minerals: Map<String, double>.from(
        (data['minerals'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v ?? 0).toDouble())),
      ),
      customGoals: Map<String, double>.from(
        (data['customGoals'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v ?? 0).toDouble())),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dailyCalories': dailyCalories,
      'proteinGrams': proteinGrams,
      'carbGrams': carbGrams,
      'fatGrams': fatGrams,
      'fiberGrams': fiberGrams,
      'vitamins': vitamins,
      'minerals': minerals,
      'customGoals': customGoals,
    };
  }
}

class ShoppingList {
  final String id;
  final String weekOf; // Week starting date
  final Map<String, ShoppingListItem> items;
  final List<String> stores;
  final double? estimatedCost;
  final bool completed;
  final DateTime? completedAt;

  ShoppingList({
    required this.id,
    required this.weekOf,
    this.items = const {},
    this.stores = const [],
    this.estimatedCost,
    this.completed = false,
    this.completedAt,
  });

  factory ShoppingList.fromMap(Map<String, dynamic> data) {
    return ShoppingList(
      id: data['id'] ?? '',
      weekOf: data['weekOf'] ?? '',
      items: (data['items'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, ShoppingListItem.fromMap(v))),
      stores: List<String>.from(data['stores'] ?? []),
      estimatedCost: data['estimatedCost']?.toDouble(),
      completed: data['completed'] ?? false,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'weekOf': weekOf,
      'items': items.map((k, v) => MapEntry(k, v.toMap())),
      'stores': stores,
      'estimatedCost': estimatedCost,
      'completed': completed,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }
}

class ShoppingListItem {
  final String name;
  final double quantity;
  final String unit;
  final String? category;
  final double? estimatedPrice;
  final bool purchased;
  final List<String> recipeIds; // Which recipes need this item

  ShoppingListItem({
    required this.name,
    required this.quantity,
    required this.unit,
    this.category,
    this.estimatedPrice,
    this.purchased = false,
    this.recipeIds = const [],
  });

  factory ShoppingListItem.fromMap(Map<String, dynamic> data) {
    return ShoppingListItem(
      name: data['name'] ?? '',
      quantity: (data['quantity'] ?? 0).toDouble(),
      unit: data['unit'] ?? '',
      category: data['category'],
      estimatedPrice: data['estimatedPrice']?.toDouble(),
      purchased: data['purchased'] ?? false,
      recipeIds: List<String>.from(data['recipeIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'category': category,
      'estimatedPrice': estimatedPrice,
      'purchased': purchased,
      'recipeIds': recipeIds,
    };
  }
}

class PrepPlan {
  final String date;
  final List<PrepTask> tasks;
  final int estimatedTimeMinutes;
  final bool completed;

  PrepPlan({
    required this.date,
    this.tasks = const [],
    this.estimatedTimeMinutes = 0,
    this.completed = false,
  });

  factory PrepPlan.fromMap(Map<String, dynamic> data) {
    return PrepPlan(
      date: data['date'] ?? '',
      tasks: (data['tasks'] as List<dynamic>? ?? [])
          .map((t) => PrepTask.fromMap(t))
          .toList(),
      estimatedTimeMinutes: data['estimatedTimeMinutes'] ?? 0,
      completed: data['completed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'tasks': tasks.map((t) => t.toMap()).toList(),
      'estimatedTimeMinutes': estimatedTimeMinutes,
      'completed': completed,
    };
  }
}

class PrepTask {
  final String id;
  final String description;
  final String? recipeId;
  final int estimatedMinutes;
  final bool completed;

  PrepTask({
    required this.id,
    required this.description,
    this.recipeId,
    this.estimatedMinutes = 0,
    this.completed = false,
  });

  factory PrepTask.fromMap(Map<String, dynamic> data) {
    return PrepTask(
      id: data['id'] ?? '',
      description: data['description'] ?? '',
      recipeId: data['recipeId'],
      estimatedMinutes: data['estimatedMinutes'] ?? 0,
      completed: data['completed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'recipeId': recipeId,
      'estimatedMinutes': estimatedMinutes,
      'completed': completed,
    };
  }
}

class MealPlanRatings {
  final double averageRating;
  final int totalRatings;
  final Map<int, int> ratingDistribution;
  final DateTime? lastUpdated;

  MealPlanRatings({
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.ratingDistribution = const {},
    this.lastUpdated,
  });

  factory MealPlanRatings.fromMap(Map<String, dynamic> data) {
    return MealPlanRatings(
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

class MealPlanStats {
  final int totalViews;
  final int totalForks;
  final int totalCompletions;
  final Map<String, int> popularRecipes;
  final DateTime lastUpdated;

  MealPlanStats({
    this.totalViews = 0,
    this.totalForks = 0,
    this.totalCompletions = 0,
    this.popularRecipes = const {},
    required this.lastUpdated,
  });

  factory MealPlanStats.fromMap(Map<String, dynamic> data) {
    return MealPlanStats(
      totalViews: data['totalViews'] ?? 0,
      totalForks: data['totalForks'] ?? 0,
      totalCompletions: data['totalCompletions'] ?? 0,
      popularRecipes: Map<String, int>.from(data['popularRecipes'] ?? {}),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalViews': totalViews,
      'totalForks': totalForks,
      'totalCompletions': totalCompletions,
      'popularRecipes': popularRecipes,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}