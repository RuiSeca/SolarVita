import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/carbon_activity.dart';
import '../models/eco_metrics.dart';

class EcoService {
  static final EcoService _instance = EcoService._internal();
  factory EcoService() => _instance;
  EcoService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Collections
  static const String ecoActivitiesCollection = 'ecoActivities';
  static const String ecoMetricsCollection = 'ecoMetrics';

  /// EcoActivity CRUD Operations

  // Add a new eco activity
  Future<String> addEcoActivity(EcoActivity activity) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    try {
      // Add activity to Firestore
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection(ecoActivitiesCollection)
          .add(activity.toFirestore());

      // Update user's eco metrics
      await _updateEcoMetrics(activity);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add eco activity: $e');
    }
  }

  // Get user's eco activities with optional filtering
  Stream<List<EcoActivity>> getUserEcoActivities({
    EcoActivityType? type,
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    Query query = _firestore
        .collection('users')
        .doc(userId)
        .collection(ecoActivitiesCollection)
        .orderBy('date', descending: true);

    // Apply filters
    if (type != null) {
      query = query.where('type', isEqualTo: type.toString());
    }

    if (startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    query = query.limit(limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => EcoActivity.fromFirestore(doc))
          .toList();
    });
  }

  // Get specific eco activity
  Future<EcoActivity?> getEcoActivity(String activityId) async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection(ecoActivitiesCollection)
          .doc(activityId)
          .get();

      if (doc.exists) {
        return EcoActivity.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting eco activity: $e');
      return null;
    }
  }

  // Update eco activity
  Future<void> updateEcoActivity(String activityId, EcoActivity activity) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(ecoActivitiesCollection)
          .doc(activityId)
          .update(activity.toFirestore());

      // Note: For simplicity, we're not recalculating metrics on update
      // In a production app, you'd want to handle this more carefully
    } catch (e) {
      throw Exception('Failed to update eco activity: $e');
    }
  }

  // Delete eco activity
  Future<void> deleteEcoActivity(String activityId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(ecoActivitiesCollection)
          .doc(activityId)
          .delete();

      // Note: For simplicity, we're not recalculating metrics on delete
      // In a production app, you'd want to handle this more carefully
    } catch (e) {
      throw Exception('Failed to delete eco activity: $e');
    }
  }

  /// EcoMetrics Operations

  // Get user's eco metrics
  Stream<EcoMetrics> getUserEcoMetrics() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value(EcoMetrics.empty(''));
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection(ecoMetricsCollection)
        .doc('current')
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return EcoMetrics.fromFirestore(doc);
      } else {
        return EcoMetrics.empty(userId);
      }
    });
  }

  // Update eco metrics when a new activity is added
  Future<void> _updateEcoMetrics(EcoActivity activity) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final metricsDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection(ecoMetricsCollection)
          .doc('current')
          .get();

      EcoMetrics currentMetrics;
      if (metricsDoc.exists) {
        currentMetrics = EcoMetrics.fromFirestore(metricsDoc);
      } else {
        currentMetrics = EcoMetrics.empty(userId);
      }

      // Update metrics with new activity
      final updatedMetrics = currentMetrics.addActivity(
        activity.type.toString().split('.').last, // Remove enum prefix
        activity.carbonSaved,
      );

      // Save updated metrics
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(ecoMetricsCollection)
          .doc('current')
          .set(updatedMetrics.toFirestore());
    } catch (e) {
      debugPrint('Error updating eco metrics: $e');
    }
  }

  /// Carbon Calculation Helpers

  // Calculate carbon saved for different activities
  static double calculateCarbonSaved(EcoActivityType type, String activity, {Map<String, dynamic>? metadata}) {
    switch (type) {
      case EcoActivityType.transport:
        return _calculateTransportCarbon(activity, metadata);
      case EcoActivityType.food:
        return _calculateFoodCarbon(activity, metadata);
      case EcoActivityType.energy:
        return _calculateEnergyCarbon(activity, metadata);
      case EcoActivityType.waste:
        return _calculateWasteCarbon(activity, metadata);
      case EcoActivityType.consumption:
        return _calculateConsumptionCarbon(activity, metadata);
    }
  }

  /// Meal-specific Carbon Calculations

  // Calculate carbon saved by choosing sustainable meal option
  static double calculateMealCarbonSaved(String mealCategory, {int? calories, bool isCustomMeal = false}) {
    if (isCustomMeal && calories != null) {
      return _calculateCustomMealCarbon(calories);
    }
    
    return _calculateCategoryMealCarbon(mealCategory.toLowerCase());
  }

  // Carbon footprint per kg of food by meal category (kg CO₂/kg food)
  static const Map<String, double> _mealCarbonFootprint = {
    // High carbon impact (red meat)
    'beef': 60.0,
    'lamb': 39.2,
    'goat': 35.0,
    
    // Medium-high carbon impact
    'pork': 12.1,
    
    // Medium carbon impact
    'chicken': 6.9,
    'seafood': 5.0,
    'dessert': 3.0,
    'breakfast': 4.0, // Average varies widely
    
    // Low carbon impact
    'vegan': 2.0,
    'vegetarian': 3.5,
    'pasta': 1.1,
    'side': 1.5,
    'starter': 2.0,
    
    // Unspecified/mixed
    'miscellaneous': 4.0,
  };

  // Average carbon footprint for mixed/standard meals (kg CO₂/kg food)
  static const double _averageMealCarbon = 7.0;

  // Calculate carbon saved by choosing lower-impact meal category
  static double _calculateCategoryMealCarbon(String category) {
    final categoryCarbon = _mealCarbonFootprint[category] ?? _averageMealCarbon;
    
    // Calculate carbon saved compared to average meal
    // Positive value = carbon saved, negative = extra carbon
    final carbonSaved = _averageMealCarbon - categoryCarbon;
    
    // Assume standard serving size of 250g (0.25kg)
    const standardServingKg = 0.25;
    final totalCarbonDifference = carbonSaved * standardServingKg;
    
    // Only return positive values (actual savings)
    return totalCarbonDifference > 0 ? totalCarbonDifference : 0.0;
  }

  // Calculate carbon impact for custom meals based on calories
  static double _calculateCustomMealCarbon(int calories) {
    // Average carbon per calorie for home cooking: ~0.002 kg CO₂/calorie
    // This assumes home cooking vs restaurant/processed food
    const carbonPerCalorie = 0.002;
    
    // Calculate carbon saved vs restaurant equivalent
    // Restaurant meals typically have 50% higher carbon footprint
    final homeCookingCarbon = calories * carbonPerCalorie;
    final restaurantCarbon = homeCookingCarbon * 1.5;
    
    return restaurantCarbon - homeCookingCarbon; // Carbon saved by home cooking
  }

  // Transport carbon calculations
  static double _calculateTransportCarbon(String activity, Map<String, dynamic>? metadata) {
    final distance = metadata?['distance']?.toDouble() ?? 1.0; // km
    
    switch (activity) {
      case 'walking':
        return distance * 0.0; // Walking saves vs driving
      case 'biking':
        return distance * 0.21; // vs car (0.21 kg CO2/km saved)
      case 'publicTransport':
        return distance * 0.15; // vs car
      case 'carpooling':
        return distance * 0.1; // vs solo driving
      case 'electricVehicle':
        return distance * 0.12; // vs gas car
      default:
        return 1.0;
    }
  }

  // Food carbon calculations
  static double _calculateFoodCarbon(String activity, Map<String, dynamic>? metadata) {
    switch (activity) {
      case 'plantBasedMeal':
        return 2.5; // vs meat meal
      case 'localProduce':
        return 0.8; // vs imported
      case 'organicFood':
        return 0.5; // vs conventional
      case 'reduceFoodWaste':
        return 1.2; // per meal not wasted
      case 'homeCooking':
        return 0.6; // vs restaurant/takeout
      default:
        return 0.5;
    }
  }

  // Energy carbon calculations
  static double _calculateEnergyCarbon(String activity, Map<String, dynamic>? metadata) {
    switch (activity) {
      case 'ledBulbs':
        return 0.3; // per bulb per day
      case 'unplugDevices':
        return 0.5; // per day
      case 'solarPower':
        return 5.0; // per day
      case 'energyEfficientAppliances':
        return 2.0; // per appliance per day
      case 'naturalLight':
        return 0.2; // per day
      default:
        return 0.3;
    }
  }

  // Waste carbon calculations
  static double _calculateWasteCarbon(String activity, Map<String, dynamic>? metadata) {
    switch (activity) {
      case 'recycling':
        return 0.5; // per item
      case 'composting':
        return 0.8; // per day
      case 'reducePackaging':
        return 0.3; // per item
      case 'donateItems':
        return 1.0; // per item
      case 'upcycling':
        return 1.5; // per item
      default:
        return 0.5;
    }
  }

  // Consumption carbon calculations
  static double _calculateConsumptionCarbon(String activity, Map<String, dynamic>? metadata) {
    switch (activity) {
      case 'reusableBottle':
        return 0.2; // per use (vs single-use 1.5L bottle - 0.2 kg CO₂)
      case 'reusableBag':
        return 0.04; // per use (vs plastic bag)
      case 'secondHandClothing':
        return 5.0; // per item vs new
      case 'repairInsteadOfBuy':
        return 3.0; // per item
      case 'buyLocal':
        return 0.5; // per item vs imported
      default:
        return 0.5;
    }
  }

  /// Convenience methods for quick activity logging

  // Log meal-based eco activity
  Future<String> logMealActivity(String mealCategory, {int? calories, bool isCustomMeal = false, String? mealName, String? notes}) async {
    final carbonSaved = calculateMealCarbonSaved(mealCategory, calories: calories, isCustomMeal: isCustomMeal);
    
    // Only log if there's actual carbon savings (positive impact)
    if (carbonSaved <= 0) {
      throw Exception('This meal choice doesn\'t provide significant carbon savings');
    }

    final activityName = isCustomMeal ? 'homeCooking' : _getMealActivityName(mealCategory);
    final displayName = mealName ?? _getMealDisplayName(mealCategory, isCustomMeal);

    final ecoActivity = EcoActivity(
      id: '', // Will be set by Firestore
      userId: currentUserId!,
      type: EcoActivityType.food,
      activity: activityName,
      carbonSaved: carbonSaved,
      date: DateTime.now(),
      notes: notes,
      autoGenerated: true, // Generated from meal logging
      metadata: {
        'mealCategory': mealCategory,
        'calories': calories,
        'isCustomMeal': isCustomMeal,
        'mealName': displayName,
      },
    );

    return addEcoActivity(ecoActivity);
  }

  // Helper method to get activity name for meal categories
  static String _getMealActivityName(String category) {
    switch (category.toLowerCase()) {
      case 'vegan':
      case 'vegetarian':
        return 'plantBasedMeal';
      case 'beef':
      case 'lamb':
      case 'goat':
      case 'pork':
        return 'reduceMeatConsumption';
      default:
        return 'sustainableMeal';
    }
  }

  // Helper method to get display name for meals
  static String _getMealDisplayName(String category, bool isCustomMeal) {
    if (isCustomMeal) return 'Home Cooked Meal';
    
    switch (category.toLowerCase()) {
      case 'vegan': return 'Vegan Meal';
      case 'vegetarian': return 'Vegetarian Meal';
      case 'chicken': return 'Chicken Meal';
      case 'seafood': return 'Seafood Meal';
      case 'pasta': return 'Pasta Meal';
      case 'breakfast': return 'Breakfast Meal';
      case 'side': return 'Side Dish';
      case 'starter': return 'Starter/Appetizer';
      case 'dessert': return 'Dessert';
      default: return '${category[0].toUpperCase()}${category.substring(1)} Meal';
    }
  }

  // Log transport activity
  Future<String> logTransportActivity(String activity, {double distance = 1.0, String? notes}) async {
    final carbonSaved = calculateCarbonSaved(
      EcoActivityType.transport, 
      activity, 
      metadata: {'distance': distance},
    );

    final ecoActivity = EcoActivity(
      id: '', // Will be set by Firestore
      userId: currentUserId!,
      type: EcoActivityType.transport,
      activity: activity,
      carbonSaved: carbonSaved,
      date: DateTime.now(),
      notes: notes,
      metadata: {'distance': distance},
    );

    return addEcoActivity(ecoActivity);
  }

  // Log food activity
  Future<String> logFoodActivity(String activity, {String? notes}) async {
    final carbonSaved = calculateCarbonSaved(EcoActivityType.food, activity);

    final ecoActivity = EcoActivity(
      id: '', // Will be set by Firestore
      userId: currentUserId!,
      type: EcoActivityType.food,
      activity: activity,
      carbonSaved: carbonSaved,
      date: DateTime.now(),
      notes: notes,
      autoGenerated: true, // Assuming this comes from meal logging
    );

    return addEcoActivity(ecoActivity);
  }

  // Log consumption activity
  Future<String> logConsumptionActivity(String activity, {String? notes}) async {
    final carbonSaved = calculateCarbonSaved(EcoActivityType.consumption, activity);

    final ecoActivity = EcoActivity(
      id: '', // Will be set by Firestore
      userId: currentUserId!,
      type: EcoActivityType.consumption,
      activity: activity,
      carbonSaved: carbonSaved,
      date: DateTime.now(),
      notes: notes,
    );

    return addEcoActivity(ecoActivity);
  }

  /// Transportation-specific Carbon Calculations

  // Calculate carbon saved from walking/active transportation based on health data
  static double calculateTransportationCarbonSaved({required int steps, required int activeMinutes}) {
    // Calculate walking distance from steps (average step = 0.8m)
    final walkingKm = steps * 0.0008;
    
    // Carbon saved per km of walking vs driving (0.21 kg CO₂/km)
    final walkingCarbonSaved = walkingKm * 0.21;
    
    // Additional carbon saved from active minutes (general activity vs sedentary lifestyle)
    // Active lifestyle reduces transportation dependence
    final activeMinutesCarbonSaved = activeMinutes * 0.01; // 0.01 kg CO₂ per active minute
    
    return walkingCarbonSaved + activeMinutesCarbonSaved;
  }

  // Log transportation activity based on health data
  Future<String?> logTransportationFromHealthData({
    required int steps,
    required int activeMinutes,
    String? notes,
    bool autoGenerate = true,
  }) async {
    final carbonSaved = calculateTransportationCarbonSaved(
      steps: steps,
      activeMinutes: activeMinutes,
    );
    
    // Only log if there's significant carbon savings (minimum threshold)
    if (carbonSaved < 0.1) {
      return null; // Not enough activity to generate eco impact
    }
    
    // Determine primary activity type based on steps and active minutes
    String activityType;
    if (steps > 8000) {
      activityType = 'walking';
    } else if (activeMinutes > 30) {
      activityType = 'activeTransport';
    } else {
      activityType = 'sustainableMovement';
    }
    
    final ecoActivity = EcoActivity(
      id: '', // Will be set by Firestore
      userId: currentUserId!,
      type: EcoActivityType.transport,
      activity: activityType,
      carbonSaved: carbonSaved,
      date: DateTime.now(),
      notes: notes,
      autoGenerated: autoGenerate,
      metadata: {
        'steps': steps,
        'activeMinutes': activeMinutes,
        'walkingDistance': steps * 0.0008, // km
        'activityType': activityType,
      },
    );

    return addEcoActivity(ecoActivity);
  }

  /// Analytics methods

  // Get carbon saved in last 30 days
  Future<double> getCarbonSavedLast30Days() async {
    final userId = currentUserId;
    if (userId == null) return 0.0;

    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection(ecoActivitiesCollection)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
        .get();

    double totalCarbon = 0.0;
    for (final doc in snapshot.docs) {
      final activity = EcoActivity.fromFirestore(doc);
      totalCarbon += activity.carbonSaved;
    }

    return totalCarbon;
  }

  // Get activity counts by type
  Future<Map<EcoActivityType, int>> getActivityCountsByType() async {
    final userId = currentUserId;
    if (userId == null) return {};

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection(ecoActivitiesCollection)
        .get();

    final counts = <EcoActivityType, int>{};
    for (final doc in snapshot.docs) {
      final activity = EcoActivity.fromFirestore(doc);
      counts[activity.type] = (counts[activity.type] ?? 0) + 1;
    }

    return counts;
  }
}