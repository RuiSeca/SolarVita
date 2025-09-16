import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../screens/onboarding/models/onboarding_models.dart' show IntentType;
import '../../models/user/user_profile.dart';
import '../../utils/translation_helper.dart';

class DashboardImageService {
  static const String _lastRotationKey = 'last_image_rotation';
  static const String _currentImageSetKey = 'current_image_set';

  // Rotation interval (3 days)
  static const Duration _rotationInterval = Duration(days: 3);

  /// Get personalized images based on user profile
  static Future<List<String>> getPersonalizedImages(UserProfile userProfile) async {
    try {
      final shouldRotate = await _shouldRotateImages();
      List<String> selectedImages;

      if (shouldRotate) {
        selectedImages = await _generateNewImageSet(userProfile);
        await _saveCurrentImageSet(selectedImages);
        await _updateLastRotationTime();
      } else {
        selectedImages = await _getCurrentImageSet();
        if (selectedImages.isEmpty) {
          selectedImages = await _generateNewImageSet(userProfile);
          await _saveCurrentImageSet(selectedImages);
          await _updateLastRotationTime();
        }
      }

      return selectedImages;
    } catch (e) {
      // Fallback to default images if anything fails
      return _getDefaultImages();
    }
  }

  /// Generate new image set based on user preferences
  static Future<List<String>> _generateNewImageSet(UserProfile userProfile) async {
    final intents = userProfile.selectedIntents;

    // Gender is stored in additionalData from onboarding
    final genderFromAdditionalData = userProfile.additionalData['gender'] as String?;
    final genderFromField = userProfile.gender;
    final gender = (genderFromAdditionalData ?? genderFromField)?.toLowerCase();

    debugPrint('=== DASHBOARD IMAGE GENERATION ===');
    debugPrint('Gender from additionalData: $genderFromAdditionalData');
    debugPrint('Gender from field: $genderFromField');
    debugPrint('Final processed gender: $gender');
    debugPrint('Selected intents: $intents');
    debugPrint('=====================================');

    // If no intents selected, default to fitness
    if (intents.isEmpty) {
      debugPrint('No intents selected, defaulting to fitness');
      final fitnessImages = _getImagesForIntent(IntentType.fitness, gender);
      debugPrint('Fitness images for empty intents: $fitnessImages');
      return _selectRandomImages(fitnessImages, 3);
    }

    // For single intent, use only that intent
    if (intents.length == 1) {
      final intent = intents.first;
      final intentImages = _getImagesForIntent(intent, gender);
      debugPrint('Single intent $intent images: $intentImages');
      return _selectRandomImages(intentImages, 3);
    }

    // For multiple intents, get images from each intent
    List<String> selectedImages = [];
    final intentList = intents.toList();
    debugPrint('Processing ${intentList.length} intents: $intentList');

    // Select 1 image from each of the first 3 intents, or distribute evenly
    for (int i = 0; i < 3 && i < intentList.length; i++) {
      final intent = intentList[i];
      debugPrint('🔍 Processing intent $i: $intent');

      final intentImages = _getImagesForIntent(intent, gender);
      debugPrint('Got ${intentImages.length} images for $intent with gender $gender');

      if (intentImages.isNotEmpty) {
        debugPrint('Available images for $intent: $intentImages');
        final randomImage = intentImages[Random().nextInt(intentImages.length)];
        selectedImages.add(randomImage);
        debugPrint('✅ Selected image for intent $intent: $randomImage');

        // Verify the image path is correct for the intent
        _verifyImagePathForIntent(intent, randomImage);
      } else {
        debugPrint('⚠️ No images found for intent $intent with gender $gender');
      }
    }

    // If we need more images and have fewer intents, fill from primary intent
    while (selectedImages.length < 3 && intentList.isNotEmpty) {
      final primaryIntent = intentList[0];
      final primaryIntentImages = _getImagesForIntent(primaryIntent, gender);
      debugPrint('Filling remaining slots with primary intent $primaryIntent');

      if (primaryIntentImages.isNotEmpty) {
        final randomImage = primaryIntentImages[Random().nextInt(primaryIntentImages.length)];
        if (!selectedImages.contains(randomImage)) {
          selectedImages.add(randomImage);
          debugPrint('✅ Added fill image: $randomImage');
        } else {
          debugPrint('🔄 Duplicate image found, breaking to avoid infinite loop');
          break; // Avoid infinite loop if we run out of unique images
        }
      } else {
        debugPrint('❌ No images available for primary intent $primaryIntent');
        break;
      }
    }

    // Ensure we always have exactly 3 images
    if (selectedImages.length < 3) {
      debugPrint('⚠️ Not enough images (${selectedImages.length}), adding fallbacks');
      final fallbackImages = _getDefaultImages();
      for (final fallback in fallbackImages) {
        if (selectedImages.length >= 3) break;
        if (!selectedImages.contains(fallback)) {
          selectedImages.add(fallback);
        }
      }
    }

    final finalImages = selectedImages.take(3).toList();
    debugPrint('🎯 Final selected images: $finalImages');
    return finalImages;
  }

  /// Verify that the image path matches the expected intent
  static void _verifyImagePathForIntent(IntentType intent, String imagePath) {
    switch (intent) {
      case IntentType.mindfulness:
        if (!imagePath.contains('Mindfullness')) {
          debugPrint('🚨 CRITICAL ERROR: Mindfulness intent got wrong image path: $imagePath');
          debugPrint('🚨 Expected path to contain "Mindfullness"');
        }
        break;
      case IntentType.adventure:
        if (!imagePath.contains('Adventure')) {
          debugPrint('🚨 CRITICAL ERROR: Adventure intent got wrong image path: $imagePath');
          debugPrint('🚨 Expected path to contain "Adventure"');
        }
        break;
      case IntentType.fitness:
        if (imagePath.contains('mediation') || imagePath.contains('dog-friend')) {
          debugPrint('🚨 CRITICAL ERROR: Fitness intent got non-fitness image: $imagePath');
          debugPrint('🚨 This image belongs to mindfulness or adventure');
        }
        break;
      case IntentType.eco:
        if (!imagePath.contains('Eco')) {
          debugPrint('🚨 CRITICAL ERROR: Eco intent got wrong image path: $imagePath');
          debugPrint('🚨 Expected path to contain "Eco"');
        }
        break;
      case IntentType.nutrition:
        if (!imagePath.contains('Nutrition')) {
          debugPrint('🚨 CRITICAL ERROR: Nutrition intent got wrong image path: $imagePath');
          debugPrint('🚨 Expected path to contain "Nutrition"');
        }
        break;
      case IntentType.community:
        if (!imagePath.contains('Community')) {
          debugPrint('🚨 CRITICAL ERROR: Community intent got wrong image path: $imagePath');
          debugPrint('🚨 Expected path to contain "Community"');
        }
        break;
    }
  }


  /// Get images for specific intent considering gender
  static List<String> _getImagesForIntent(IntentType intent, String? gender) {
    debugPrint('🔎 Getting images for intent: $intent, gender: $gender');

    List<String> images;
    try {
      switch (intent) {
        case IntentType.eco:
          images = _getGenderedImages('assets/images/dashboard/Eco', gender);
          break;

        case IntentType.fitness:
          images = _getGenderedImages('assets/images/dashboard/Fitness', gender);
          break;

        case IntentType.nutrition:
          images = _getNutritionImages();
          break;

        case IntentType.mindfulness:
          images = _getMindfulnessImages();
          break;

        case IntentType.community:
          images = _getCommunityImages();
          break;

        case IntentType.adventure:
          images = _getAdventureImages();
          break;
      }

      // If no images found or asset loading might fail, use safe fallback
      if (images.isEmpty) {
        debugPrint('⚠️ No images found for $intent, using safe fallbacks');
        images = _getSafeImagesForIntent(intent, gender);
      }
    } catch (e) {
      debugPrint('❌ Error getting images for $intent: $e');
      debugPrint('🔄 Using safe fallback images for $intent');
      images = _getSafeImagesForIntent(intent, gender);
    }

    debugPrint('🔎 Intent $intent returned ${images.length} images: $images');

    // Safety verification - ensure returned images match the expected intent
    for (final image in images) {
      if (!_isImageValidForIntent(image, intent) && !image.contains('dashboard/abs.webp') && !image.contains('dashboard/hiit.webp')) {
        debugPrint('🚨 CRITICAL: Invalid image $image for intent $intent!');
      }
    }

    return images;
  }

  /// Verify that an image path is valid for the given intent
  static bool _isImageValidForIntent(String imagePath, IntentType intent) {
    switch (intent) {
      case IntentType.eco:
        return imagePath.contains('Eco');
      case IntentType.fitness:
        return imagePath.contains('Fitness');
      case IntentType.nutrition:
        return imagePath.contains('Nutrition');
      case IntentType.mindfulness:
        return imagePath.contains('Mindfullness'); // Note: matches the actual folder name
      case IntentType.community:
        return imagePath.contains('Community');
      case IntentType.adventure:
        return imagePath.contains('Adventure');
    }
  }

  /// Get gendered images (male/female/mixed)
  static List<String> _getGenderedImages(String basePath, String? gender) {
    debugPrint('Getting gendered images for basePath: $basePath, gender: $gender');

    List<String> images = [];

    if (basePath.contains('Eco')) {
      if (gender == 'male') {
        images = _getEcoMaleImages();
      } else if (gender == 'female') {
        images = _getEcoFemaleImages();
      } else {
        images = _getEcoMixedImages();
      }
    } else if (basePath.contains('Fitness')) {
      if (gender == 'male') {
        images = _getFitnessMaleImages();
      } else if (gender == 'female') {
        images = _getFitnessFemaleImages();
      } else {
        images = _getFitnessMixedImages();
      }
    }

    debugPrint('Returning ${images.length} images for $basePath/$gender');
    return images;
  }

  // Eco Images - Male
  static List<String> _getEcoMaleImages() {
    return [
      'assets/images/dashboard/Eco/Male/bike.webp',
      'assets/images/dashboard/Eco/Male/bottle-recycle.webp',
      'assets/images/dashboard/Eco/Male/cycling.webp',
      'assets/images/dashboard/Eco/Male/globe-couple.webp',
      'assets/images/dashboard/Eco/Male/hiking-climb-up-mountain.webp',
    ];
  }

  // Eco Images - Female
  static List<String> _getEcoFemaleImages() {
    return [
      'assets/images/dashboard/Eco/Female/bike.webp',
      'assets/images/dashboard/Eco/Female/bottle-recycle.webp',
      'assets/images/dashboard/Eco/Female/eldery-fitness-smile.webp',
      'assets/images/dashboard/Eco/Female/female-nature-exercise.webp',
      'assets/images/dashboard/Eco/Female/globe-couple.webp',
    ];
  }

  // Eco Images - Mixed
  static List<String> _getEcoMixedImages() {
    return [
      'assets/images/dashboard/Eco/Mixed/bike.webp',
      'assets/images/dashboard/Eco/Mixed/bottle-recycle.webp',
      'assets/images/dashboard/Eco/Mixed/globe-couple.webp',
    ];
  }

  // Fitness Images - Male
  static List<String> _getFitnessMaleImages() {
    return [
      'assets/images/dashboard/Fitness/Male/abs.webp',
      'assets/images/dashboard/Fitness/Male/bro.webp',
      'assets/images/dashboard/Fitness/Male/gym-man.webp',
      'assets/images/dashboard/Fitness/Male/hiit.webp',
      'assets/images/dashboard/Fitness/Male/weigh-lift.webp',
    ];
  }

  // Fitness Images - Female
  static List<String> _getFitnessFemaleImages() {
    return [
      'assets/images/dashboard/Fitness/Female/abs.webp',
      'assets/images/dashboard/Fitness/Female/determined-smiling-young-woman.webp',
      'assets/images/dashboard/Fitness/Female/legpress.webp',
      'assets/images/dashboard/Fitness/Female/pillates.webp',
      'assets/images/dashboard/Fitness/Female/young-athletic-woman-exercising.webp',
    ];
  }

  // Fitness Images - Mixed
  static List<String> _getFitnessMixedImages() {
    return [
      'assets/images/dashboard/Fitness/Mixed/abs.webp',
      'assets/images/dashboard/Fitness/Mixed/determined-smiling-young-woman.webp',
      'assets/images/dashboard/Fitness/Mixed/hiit.webp',
      'assets/images/dashboard/Fitness/Mixed/jump.webp',
      'assets/images/dashboard/Fitness/Mixed/rope.webp',
    ];
  }

  /// Get nutrition images (all mixed)
  static List<String> _getNutritionImages() {
    return [
      'assets/images/dashboard/Nutrition/mixed/black-girl-smile-pear.webp',
      'assets/images/dashboard/Nutrition/mixed/black-white-sharing.webp',
      'assets/images/dashboard/Nutrition/mixed/burger-healthy.webp',
      'assets/images/dashboard/Nutrition/mixed/mixed-people-healthy.webp',
      'assets/images/dashboard/Nutrition/mixed/mum-daughther-cooking.webp',
      'assets/images/dashboard/Nutrition/mixed/shooping.webp',
    ];
  }

  /// Get mindfulness images (all mixed)
  static List<String> _getMindfulnessImages() {
    return [
      'assets/images/dashboard/Mindfullness/mixed/mediation-couple-black.webp',
      'assets/images/dashboard/Mindfullness/mixed/mediation-couple.webp',
      'assets/images/dashboard/Mindfullness/mixed/mediation-inside.webp',
      'assets/images/dashboard/Mindfullness/mixed/mediation-outdoor.webp',
      'assets/images/dashboard/Mindfullness/mixed/mediation-sunset.webp',
      'assets/images/dashboard/Mindfullness/mixed/mediation.webp',
    ];
  }

  /// Get community images (all mixed)
  static List<String> _getCommunityImages() {
    return [
      'assets/images/dashboard/Community/community-message.webp',
      'assets/images/dashboard/Community/community-play.webp',
      'assets/images/dashboard/Community/eldery-community.webp',
      'assets/images/dashboard/Community/mixed-community.webp',
      'assets/images/dashboard/Community/run-community.webp',
      'assets/images/dashboard/Community/silhouette-of-climbers-who-climb.webp',
    ];
  }

  /// Get adventure images (all mixed)
  static List<String> _getAdventureImages() {
    return [
      'assets/images/dashboard/Adventure/Mixed/dog-friend.webp',
      'assets/images/dashboard/Adventure/Mixed/mountain-couple.webp',
      'assets/images/dashboard/Adventure/Mixed/mountain-man.webp',
      'assets/images/dashboard/Adventure/Mixed/mountain-women.webp',
      'assets/images/dashboard/Adventure/Mixed/sunsuet-adventure.webp',
    ];
  }

  /// Randomly select specified number of unique images
  static List<String> _selectRandomImages(List<String> imagePool, int count) {
    if (imagePool.isEmpty) return _getDefaultImages();

    final random = Random();
    final Set<String> selected = {};

    // Ensure we don't try to select more images than available
    final targetCount = count.clamp(1, imagePool.length);

    while (selected.length < targetCount && selected.length < imagePool.length) {
      final randomImage = imagePool[random.nextInt(imagePool.length)];
      selected.add(randomImage);
    }

    return selected.toList();
  }

  /// Get dynamic section titles based on user intents
  static String getMainSectionTitle(BuildContext context, Set<IntentType> intents) {
    if (intents.isEmpty) return tr(context, 'explore_popular_workouts');

    if (intents.contains(IntentType.eco) && intents.length == 1) {
      return tr(context, 'explore_eco_fitness');
    } else if (intents.contains(IntentType.nutrition) && intents.length == 1) {
      return tr(context, 'explore_healthy_nutrition');
    } else if (intents.contains(IntentType.mindfulness) && intents.length == 1) {
      return tr(context, 'explore_mindful_practices');
    } else if (intents.contains(IntentType.adventure) && intents.length == 1) {
      return tr(context, 'explore_adventures');
    } else if (intents.contains(IntentType.community) && intents.length == 1) {
      return tr(context, 'explore_community_activities');
    } else if (intents.contains(IntentType.eco) || intents.contains(IntentType.fitness)) {
      return tr(context, 'explore_your_activities');
    } else {
      return tr(context, 'explore_popular_workouts');
    }
  }

  static String getQuickSectionTitle(BuildContext context, Set<IntentType> intents) {
    if (intents.isEmpty) return tr(context, 'quick_exercise_routines');

    if (intents.contains(IntentType.eco) && intents.length == 1) {
      return tr(context, 'quick_eco_workouts');
    } else if (intents.contains(IntentType.nutrition) && intents.length == 1) {
      return tr(context, 'quick_nutrition_ideas');
    } else if (intents.contains(IntentType.mindfulness) && intents.length == 1) {
      return tr(context, 'quick_wellness_moments');
    } else if (intents.contains(IntentType.adventure) && intents.length == 1) {
      return tr(context, 'quick_adventure_activities');
    } else if (intents.contains(IntentType.community) && intents.length == 1) {
      return tr(context, 'quick_group_activities');
    } else if (intents.contains(IntentType.eco) || intents.contains(IntentType.fitness)) {
      return tr(context, 'quick_personalized_routines');
    } else {
      return tr(context, 'quick_exercise_routines');
    }
  }

  /// Get dynamic activity labels based on image and user intents
  static Map<String, String> getActivityLabels(String imagePath, Set<IntentType> intents) {
    final filename = imagePath.split('/').last.replaceAll('.webp', '');

    // Map image filenames to translation keys for primary and secondary labels
    final Map<String, Map<String, String>> imageLabels = {
      // Fitness Images
      'abs': {'primary': 'efficient_abs', 'secondary': 'toned'},
      'hiit': {'primary': 'beginners_hiit', 'secondary': 'hiit'},
      'weigh-lift': {'primary': 'strength_training', 'secondary': 'gym'},
      'gym-man': {'primary': 'strength_training', 'secondary': 'fitness_coach'},
      'rope': {'primary': 'hiit_cardio', 'secondary': 'active_user'},
      'jump': {'primary': 'cardio_blast', 'secondary': 'fitness_enthusiast'},

      // Eco Images
      'bike': {'primary': 'eco_cycling', 'secondary': 'eco_tips'},
      'cycling': {'primary': 'outdoor_cycling', 'secondary': 'eco_tips'},
      'bottle-recycle': {'primary': 'eco_recycling', 'secondary': 'eco_tips'},
      'globe-couple': {'primary': 'earth_friendly', 'secondary': 'eco_tips'},
      'hiking-climb-up-mountain': {'primary': 'mountain_hiking', 'secondary': 'adventure'},

      // Nutrition Images
      'burger-healthy': {'primary': 'healthy_meals', 'secondary': 'supplements'},
      'black-girl-smile-pear': {'primary': 'fruit_nutrition', 'secondary': 'supplements'},
      'mum-daughther-cooking': {'primary': 'family_cooking', 'secondary': 'supplements'},
      'shooping': {'primary': 'healthy_shopping', 'secondary': 'supplements'},
      'mixed-people-healthy': {'primary': 'nutrition_community', 'secondary': 'supplements'},
      'black-white-sharing': {'primary': 'sharing_meals', 'secondary': 'supplements'},

      // Mindfulness Images
      'mediation': {'primary': 'mindful_meditation', 'secondary': 'mindful'},
      'mediation-outdoor': {'primary': 'outdoor_meditation', 'secondary': 'mindful'},
      'mediation-sunset': {'primary': 'sunset_meditation', 'secondary': 'mindful'},
      'mediation-couple': {'primary': 'couple_meditation', 'secondary': 'mindful'},
      'mediation-couple-black': {'primary': 'peaceful_moments', 'secondary': 'mindful'},
      'mediation-inside': {'primary': 'indoor_meditation', 'secondary': 'mindful'},

      // Community Images
      'community-message': {'primary': 'social_fitness', 'secondary': 'regular_trainer'},
      'community-play': {'primary': 'group_activities', 'secondary': 'regular_trainer'},
      'mixed-community': {'primary': 'fitness_community', 'secondary': 'regular_trainer'},
      'run-community': {'primary': 'group_running', 'secondary': 'regular_trainer'},
      'eldery-community': {'primary': 'senior_fitness', 'secondary': 'regular_trainer'},

      // Adventure Images
      'mountain-couple': {'primary': 'adventure_hiking', 'secondary': 'adventure'},
      'mountain-man': {'primary': 'solo_adventure', 'secondary': 'adventure'},
      'mountain-women': {'primary': 'outdoor_adventure', 'secondary': 'adventure'},
      'dog-friend': {'primary': 'pet_exercise', 'secondary': 'adventure'},
      'sunsuet-adventure': {'primary': 'sunset_adventure', 'secondary': 'adventure'},

      // Gender-specific variations
      'determined-smiling-young-woman': {'primary': 'womens_fitness', 'secondary': 'fitness_enthusiast'},
      'eldery-fitness-smile': {'primary': 'senior_fitness', 'secondary': 'active_user'},
      'female-nature-exercise': {'primary': 'outdoor_fitness', 'secondary': 'fitness_enthusiast'},
      'legpress': {'primary': 'leg_strength', 'secondary': 'gym'},
      'pillates': {'primary': 'pilates_session', 'secondary': 'toned'},
      'young-athletic-woman-exercising': {'primary': 'athletic_training', 'secondary': 'fitness_coach'},
      'bro': {'primary': 'partner_workout', 'secondary': 'regular_trainer'},
    };

    // Get labels for this image, fallback to generic fitness
    final labels = imageLabels[filename] ?? {'primary': 'efficient_abs', 'secondary': 'toned'};

    return {
      'primary': labels['primary']!,
      'secondary': labels['secondary']!,
    };
  }

  /// Get primary activity title translation key
  static String getActivityTitle(String imagePath, Set<IntentType> intents) {
    final labels = getActivityLabels(imagePath, intents);
    return labels['primary']!;
  }

  /// Get secondary activity label translation key
  static String getActivityLabel(String imagePath, Set<IntentType> intents) {
    final labels = getActivityLabels(imagePath, intents);
    return labels['secondary']!;
  }

  /// Check if images should rotate
  static Future<bool> _shouldRotateImages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRotationString = prefs.getString(_lastRotationKey);

      if (lastRotationString == null) return true;

      final lastRotation = DateTime.parse(lastRotationString);
      final now = DateTime.now();

      return now.difference(lastRotation) >= _rotationInterval;
    } catch (e) {
      return true; // Default to rotation if error
    }
  }

  /// Save current image set to preferences
  static Future<void> _saveCurrentImageSet(List<String> images) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_currentImageSetKey, images);
    } catch (e) {
      // Silent fail
    }
  }

  /// Get current saved image set
  static Future<List<String>> _getCurrentImageSet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_currentImageSetKey) ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Update last rotation time
  static Future<void> _updateLastRotationTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastRotationKey, DateTime.now().toIso8601String());
    } catch (e) {
      // Silent fail
    }
  }

  /// Fallback images if all else fails
  static List<String> _getDefaultImages() {
    return [
      'assets/images/dashboard/hiit.webp',
      'assets/images/dashboard/abs.webp',
      'assets/images/dashboard/Fitness/Mixed/hiit.webp',
    ];
  }

  /// Get safe, verified working images for each intent (fallback system)
  static List<String> _getSafeImagesForIntent(IntentType intent, String? gender) {
    debugPrint('🔄 Using safe fallback images for intent: $intent');

    // Use the most basic assets that are likely to work
    // These are the root dashboard images that should load reliably
    final basicImages = [
      'assets/images/dashboard/abs.webp',
      'assets/images/dashboard/hiit.webp',
    ];

    // Return images themed for the intent, but use safe paths
    switch (intent) {
      case IntentType.eco:
        return [
          'assets/images/dashboard/abs.webp', // Simple fitness image that exists
          'assets/images/dashboard/hiit.webp',
        ];
      case IntentType.fitness:
        return [
          'assets/images/dashboard/abs.webp',
          'assets/images/dashboard/hiit.webp',
        ];
      case IntentType.nutrition:
      case IntentType.mindfulness:
      case IntentType.community:
      case IntentType.adventure:
        return basicImages;
    }
  }


  /// Force refresh images (useful for testing or when user changes preferences)
  static Future<List<String>> forceRefreshImages(UserProfile userProfile) async {
    debugPrint('🔄 Force refreshing images for profile: ${userProfile.uid}');
    debugPrint('🔄 User intents: ${userProfile.selectedIntents}');
    debugPrint('🔄 User gender: ${userProfile.gender}');
    debugPrint('🔄 User age: ${userProfile.age}');

    // Clear any cached image data
    await _clearImageCache();

    final newImages = await _generateNewImageSet(userProfile);
    await _saveCurrentImageSet(newImages);
    await _updateLastRotationTime();

    debugPrint('🔄 Force refresh complete. New images: $newImages');
    debugPrint('🔄 Images should now reflect gender: ${userProfile.gender}');
    return newImages;
  }

  /// Clear all cached image data
  static Future<void> _clearImageCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentImageSetKey);
      await prefs.remove(_lastRotationKey);
      debugPrint('🧹 Image cache cleared successfully');
    } catch (e) {
      debugPrint('⚠️ Error clearing image cache: $e');
    }
  }

  /// Clear cache when user changes preferences (call this from settings)
  static Future<void> clearCacheOnPreferenceChange() async {
    debugPrint('🏷️ User preferences changed, clearing image cache');
    await _clearImageCache();
  }

  /// Test method to verify image paths (for debugging)
  static void testImagePaths() {
    debugPrint('=== TESTING IMAGE PATHS ===');
    debugPrint('Eco Male: ${_getEcoMaleImages()}');
    debugPrint('Eco Female: ${_getEcoFemaleImages()}');
    debugPrint('Fitness Male: ${_getFitnessMaleImages()}');
    debugPrint('Fitness Female: ${_getFitnessFemaleImages()}');
    debugPrint('Nutrition: ${_getNutritionImages()}');
    debugPrint('Mindfulness: ${_getMindfulnessImages()}');
    debugPrint('=== END TEST ===');
  }
}