import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../../models/nutrition/community_recipe.dart';
import '../../models/nutrition/community_meal_plan.dart';
import '../database/firebase_push_notification_service.dart';

class CommunityNutritionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebasePushNotificationService _notificationService =
      FirebasePushNotificationService();

  String? get currentUserId => _auth.currentUser?.uid;

  // ==================== COMMUNITY RECIPES ====================

  /// Create a new community recipe
  Future<String> createCommunityRecipe(CommunityRecipe recipe) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final docRef = await _firestore
          .collection('communityRecipes')
          .add(recipe.toFirestore());

      // Add to user's created recipes
      await _updateUserRecipes(currentUserId!, docRef.id, isCreating: true);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create recipe: $e');
    }
  }

  /// Get community recipes with filtering and sorting
  Stream<List<CommunityRecipe>> getCommunityRecipes({
    RecipeCategory? category,
    List<DietaryTag> dietaryTags = const [],
    DifficultyLevel? difficulty,
    int? maxPrepTime,
    int? maxCookTime,
    String? searchQuery,
    String sortBy = 'createdAt', // createdAt, rating, popularity
    bool descending = true,
    int limit = 20,
  }) {
    Query query = _firestore
        .collection('communityRecipes')
        .where('visibility', isEqualTo: RecipeVisibility.public.index);

    // Apply filters
    if (category != null) {
      query = query.where('category', isEqualTo: category.index);
    }

    if (difficulty != null) {
      query = query.where('difficulty', isEqualTo: difficulty.index);
    }

    if (maxPrepTime != null) {
      query = query.where('prepTimeMinutes', isLessThanOrEqualTo: maxPrepTime);
    }

    if (maxCookTime != null) {
      query = query.where('cookTimeMinutes', isLessThanOrEqualTo: maxCookTime);
    }

    // Apply sorting
    query = query.orderBy('ratings.$sortBy', descending: descending);
    query = query.limit(limit);

    return query.snapshots().map((snapshot) {
      var recipes = snapshot.docs
          .map((doc) => CommunityRecipe.fromFirestore(doc))
          .toList();

      // Apply client-side filters that can't be done in Firestore
      if (dietaryTags.isNotEmpty) {
        recipes = recipes.where((recipe) {
          return dietaryTags.every((tag) => recipe.dietaryTags.contains(tag));
        }).toList();
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        recipes = recipes.where((recipe) {
          return recipe.title.toLowerCase().contains(query) ||
              recipe.description.toLowerCase().contains(query) ||
              recipe.tags.any((tag) => tag.toLowerCase().contains(query));
        }).toList();
      }

      return recipes;
    });
  }

  /// Get user's created recipes
  Stream<List<CommunityRecipe>> getUserRecipes() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('communityRecipes')
        .where('creatorId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunityRecipe.fromFirestore(doc))
            .toList());
  }

  /// Rate a recipe
  Future<void> rateRecipe(String recipeId, int rating) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    if (rating < 1 || rating > 5) throw Exception('Rating must be between 1 and 5');

    try {
      final batch = _firestore.batch();

      // Add/update user's rating
      final userRatingRef = _firestore
          .collection('communityRecipes')
          .doc(recipeId)
          .collection('ratings')
          .doc(currentUserId);

      batch.set(userRatingRef, {
        'userId': currentUserId,
        'rating': rating,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update recipe's overall ratings
      await _updateRecipeRatings(recipeId);

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to rate recipe: $e');
    }
  }

  /// Save recipe to favorites
  Future<void> saveRecipeToFavorites(String recipeId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .update({
        'favoriteRecipes': FieldValue.arrayUnion([recipeId]),
      });
    } catch (e) {
      throw Exception('Failed to save recipe: $e');
    }
  }

  /// Remove recipe from favorites
  Future<void> removeRecipeFromFavorites(String recipeId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .update({
        'favoriteRecipes': FieldValue.arrayRemove([recipeId]),
      });
    } catch (e) {
      throw Exception('Failed to remove recipe: $e');
    }
  }

  /// Get user's favorite recipes
  Stream<List<CommunityRecipe>> getFavoriteRecipes() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .asyncMap((userDoc) async {
      if (!userDoc.exists) return <CommunityRecipe>[];

      final favoriteIds = List<String>.from(userDoc.data()?['favoriteRecipes'] ?? []);
      if (favoriteIds.isEmpty) return <CommunityRecipe>[];

      // Batch get favorite recipes
      final recipes = <CommunityRecipe>[];
      for (final id in favoriteIds) {
        try {
          final recipeDoc = await _firestore
              .collection('communityRecipes')
              .doc(id)
              .get();

          if (recipeDoc.exists) {
            recipes.add(CommunityRecipe.fromFirestore(recipeDoc));
          }
        } catch (e) {
          // Skip failed recipes
        }
      }

      return recipes;
    });
  }

  /// Upload recipe images
  Future<List<String>> uploadRecipeImages(List<File> images, String recipeId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final uploadedUrls = <String>[];

    try {
      for (int i = 0; i < images.length; i++) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final ref = _storage.ref()
            .child('recipes')
            .child(recipeId)
            .child(fileName);

        final uploadTask = ref.putFile(images[i]);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        uploadedUrls.add(downloadUrl);
      }

      return uploadedUrls;
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
  }

  // ==================== COMMUNITY MEAL PLANS ====================

  /// Create a new community meal plan
  Future<String> createCommunityMealPlan(CommunityMealPlan mealPlan) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final docRef = await _firestore
          .collection('communityMealPlans')
          .add(mealPlan.toFirestore());

      // Add to user's created meal plans
      await _updateUserMealPlans(currentUserId!, docRef.id, isCreating: true);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create meal plan: $e');
    }
  }

  /// Get community meal plans
  Stream<List<CommunityMealPlan>> getCommunityMealPlans({
    MealPlanType? type,
    List<String> dietaryRestrictions = const [],
    int? maxDuration,
    String? searchQuery,
    int limit = 20,
  }) {
    Query query = _firestore
        .collection('communityMealPlans')
        .where('visibility', isEqualTo: MealPlanVisibility.public.index);

    if (type != null) {
      query = query.where('type', isEqualTo: type.index);
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      var mealPlans = snapshot.docs
          .map((doc) => CommunityMealPlan.fromFirestore(doc))
          .toList();

      // Apply client-side filters
      if (dietaryRestrictions.isNotEmpty) {
        mealPlans = mealPlans.where((plan) {
          return dietaryRestrictions.every((restriction) =>
              plan.dietaryRestrictions.contains(restriction));
        }).toList();
      }

      if (maxDuration != null) {
        mealPlans = mealPlans.where((plan) =>
            plan.durationDays <= maxDuration).toList();
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        mealPlans = mealPlans.where((plan) {
          return plan.title.toLowerCase().contains(query) ||
              (plan.description?.toLowerCase().contains(query) ?? false) ||
              plan.tags.any((tag) => tag.toLowerCase().contains(query));
        }).toList();
      }

      return mealPlans;
    });
  }

  /// Get user's meal plans
  Stream<List<CommunityMealPlan>> getUserMealPlans() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('communityMealPlans')
        .where('creatorId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunityMealPlan.fromFirestore(doc))
            .toList());
  }

  /// Fork (copy) a meal plan
  Future<String> forkMealPlan(String originalPlanId, {
    String? newTitle,
    String? newDescription,
    MealPlanVisibility? newVisibility,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final originalDoc = await _firestore
          .collection('communityMealPlans')
          .doc(originalPlanId)
          .get();

      if (!originalDoc.exists) {
        throw Exception('Original meal plan not found');
      }

      final originalPlan = CommunityMealPlan.fromFirestore(originalDoc);

      if (!originalPlan.allowForks) {
        throw Exception('This meal plan cannot be forked');
      }

      final forkedPlan = CommunityMealPlan(
        id: '', // Will be set by Firestore
        title: newTitle ?? '${originalPlan.title} (Copy)',
        description: newDescription ?? originalPlan.description,
        creatorId: currentUserId!,
        creatorName: _auth.currentUser?.displayName ?? 'User',
        creatorPhotoURL: _auth.currentUser?.photoURL,
        createdAt: DateTime.now(),
        type: originalPlan.type,
        visibility: newVisibility ?? MealPlanVisibility.private,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: originalPlan.durationDays - 1)),
        meals: originalPlan.meals,
        nutritionGoals: originalPlan.nutritionGoals,
        dietaryRestrictions: originalPlan.dietaryRestrictions,
        preferences: originalPlan.preferences,
        ratings: MealPlanRatings(),
        tags: originalPlan.tags,
        allowForks: true,
        originalPlanId: originalPlanId,
        stats: MealPlanStats(lastUpdated: DateTime.now()),
      );

      final newPlanId = await createCommunityMealPlan(forkedPlan);

      // Update original plan's fork count
      await _firestore
          .collection('communityMealPlans')
          .doc(originalPlanId)
          .update({
        'stats.totalForks': FieldValue.increment(1),
      });

      return newPlanId;
    } catch (e) {
      throw Exception('Failed to fork meal plan: $e');
    }
  }

  /// Share meal plan with users
  Future<void> shareMealPlan(String planId, List<String> userIds) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('communityMealPlans')
          .doc(planId)
          .update({
        'sharedWithIds': FieldValue.arrayUnion(userIds),
      });

      // Send notifications to shared users
      for (final userId in userIds) {
        await _notificationService.sendNotificationToUser(
          userId: userId,
          title: 'Meal Plan Shared',
          body: '${_auth.currentUser?.displayName ?? 'Someone'} shared a meal plan with you',
          type: NotificationType.social,
          data: {
            'type': 'meal_plan_share',
            'planId': planId,
            'senderId': currentUserId!,
          },
        );
      }
    } catch (e) {
      throw Exception('Failed to share meal plan: $e');
    }
  }

  /// Generate shopping list for meal plan
  Future<ShoppingList> generateShoppingList(
    String planId,
    String weekOf,
    {List<String>? selectedDates}
  ) async {
    try {
      final planDoc = await _firestore
          .collection('communityMealPlans')
          .doc(planId)
          .get();

      if (!planDoc.exists) {
        throw Exception('Meal plan not found');
      }

      final plan = CommunityMealPlan.fromFirestore(planDoc);
      final shoppingItems = <String, ShoppingListItem>{};

      // Process each day's meals
      for (final entry in plan.meals.entries) {
        final date = entry.key;
        final dayPlan = entry.value;

        // Skip if selectedDates is provided and this date is not included
        if (selectedDates != null && !selectedDates.contains(date)) {
          continue;
        }

        // Process all meals for this day
        for (final meals in dayPlan.meals.values) {
          for (final meal in meals) {
            if (meal.recipeId != null) {
              // Get recipe and add ingredients
              final recipeDoc = await _firestore
                  .collection('communityRecipes')
                  .doc(meal.recipeId!)
                  .get();

              if (recipeDoc.exists) {
                final recipe = CommunityRecipe.fromFirestore(recipeDoc);
                _addIngredientsToShoppingList(
                  shoppingItems,
                  recipe.ingredients,
                  meal.servings,
                  meal.recipeId!,
                );
              }
            }
          }
        }
      }

      final shoppingList = ShoppingList(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        weekOf: weekOf,
        items: shoppingItems,
      );

      return shoppingList;
    } catch (e) {
      throw Exception('Failed to generate shopping list: $e');
    }
  }

  // ==================== HELPER METHODS ====================

  Future<void> _updateUserRecipes(String userId, String recipeId, {required bool isCreating}) async {
    final userDoc = _firestore.collection('users').doc(userId);

    if (isCreating) {
      await userDoc.update({
        'createdRecipes': FieldValue.arrayUnion([recipeId]),
      });
    } else {
      await userDoc.update({
        'createdRecipes': FieldValue.arrayRemove([recipeId]),
      });
    }
  }

  Future<void> _updateUserMealPlans(String userId, String planId, {required bool isCreating}) async {
    final userDoc = _firestore.collection('users').doc(userId);

    if (isCreating) {
      await userDoc.update({
        'createdMealPlans': FieldValue.arrayUnion([planId]),
      });
    } else {
      await userDoc.update({
        'createdMealPlans': FieldValue.arrayRemove([planId]),
      });
    }
  }

  Future<void> _updateRecipeRatings(String recipeId) async {
    try {
      final ratingsSnapshot = await _firestore
          .collection('communityRecipes')
          .doc(recipeId)
          .collection('ratings')
          .get();

      if (ratingsSnapshot.docs.isEmpty) return;

      final ratings = ratingsSnapshot.docs
          .map((doc) => doc.data()['rating'] as int)
          .toList();

      final totalRatings = ratings.length;
      final averageRating = ratings.reduce((a, b) => a + b) / totalRatings;

      // Calculate rating distribution
      final distribution = <int, int>{};
      for (int i = 1; i <= 5; i++) {
        distribution[i] = ratings.where((r) => r == i).length;
      }

      final newRatings = RecipeRatings(
        averageRating: averageRating,
        totalRatings: totalRatings,
        ratingDistribution: distribution,
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection('communityRecipes')
          .doc(recipeId)
          .update({
        'ratings': newRatings.toMap(),
      });
    } catch (e) {
      // Log error but don't throw to avoid breaking the rating operation
      debugPrint('Failed to update recipe ratings: $e');
    }
  }

  void _addIngredientsToShoppingList(
    Map<String, ShoppingListItem> shoppingItems,
    List<RecipeIngredient> ingredients,
    double servingMultiplier,
    String recipeId,
  ) {
    for (final ingredient in ingredients) {
      final key = '${ingredient.name}_${ingredient.unit}';
      final adjustedAmount = ingredient.amount * servingMultiplier;

      if (shoppingItems.containsKey(key)) {
        // Combine with existing item
        final existing = shoppingItems[key]!;
        shoppingItems[key] = ShoppingListItem(
          name: existing.name,
          quantity: existing.quantity + adjustedAmount,
          unit: existing.unit,
          category: existing.category,
          recipeIds: [...existing.recipeIds, recipeId],
        );
      } else {
        // Add new item
        shoppingItems[key] = ShoppingListItem(
          name: ingredient.name,
          quantity: adjustedAmount,
          unit: ingredient.unit,
          recipeIds: [recipeId],
        );
      }
    }
  }
}