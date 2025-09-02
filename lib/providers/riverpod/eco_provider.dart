import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/eco/carbon_activity.dart';
import '../../models/eco/eco_metrics.dart';
import '../../models/food/food_analysis.dart';
import '../../services/database/eco_service.dart';
import '../../services/meal/meal_eco_integration_service.dart';

// Eco service provider
final ecoServiceProvider = Provider<EcoService>((ref) {
  return EcoService();
});

// Meal eco integration service provider
final mealEcoIntegrationProvider = Provider<MealEcoIntegrationService>((ref) {
  return MealEcoIntegrationService();
});

// User's eco metrics stream
final userEcoMetricsProvider = StreamProvider<EcoMetrics>((ref) {
  final ecoService = ref.watch(ecoServiceProvider);
  return ecoService.getUserEcoMetrics();
});

// User's eco activities stream with optional filtering
final userEcoActivitiesProvider =
    StreamProvider.family<List<EcoActivity>, EcoActivitiesQuery>((ref, query) {
      final ecoService = ref.watch(ecoServiceProvider);
      return ecoService.getUserEcoActivities(
        type: query.type,
        limit: query.limit,
        startDate: query.startDate,
        endDate: query.endDate,
      );
    });

// Recent eco activities (last 10)
final recentEcoActivitiesProvider = StreamProvider<List<EcoActivity>>((ref) {
  final ecoService = ref.watch(ecoServiceProvider);
  return ecoService.getUserEcoActivities(limit: 10);
});

// Activities by type providers
final transportActivitiesProvider = StreamProvider<List<EcoActivity>>((ref) {
  final ecoService = ref.watch(ecoServiceProvider);
  return ecoService.getUserEcoActivities(
    type: EcoActivityType.transport,
    limit: 20,
  );
});

final foodActivitiesProvider = StreamProvider<List<EcoActivity>>((ref) {
  final ecoService = ref.watch(ecoServiceProvider);
  return ecoService.getUserEcoActivities(type: EcoActivityType.food, limit: 20);
});

final energyActivitiesProvider = StreamProvider<List<EcoActivity>>((ref) {
  final ecoService = ref.watch(ecoServiceProvider);
  return ecoService.getUserEcoActivities(
    type: EcoActivityType.energy,
    limit: 20,
  );
});

final wasteActivitiesProvider = StreamProvider<List<EcoActivity>>((ref) {
  final ecoService = ref.watch(ecoServiceProvider);
  return ecoService.getUserEcoActivities(
    type: EcoActivityType.waste,
    limit: 20,
  );
});

final consumptionActivitiesProvider = StreamProvider<List<EcoActivity>>((ref) {
  final ecoService = ref.watch(ecoServiceProvider);
  return ecoService.getUserEcoActivities(
    type: EcoActivityType.consumption,
    limit: 20,
  );
});

// Carbon saved analytics
final carbonSavedLast30DaysProvider = FutureProvider<double>((ref) {
  final ecoService = ref.watch(ecoServiceProvider);
  return ecoService.getCarbonSavedLast30Days();
});

final activityCountsByTypeProvider = FutureProvider<Map<EcoActivityType, int>>((
  ref,
) {
  final ecoService = ref.watch(ecoServiceProvider);
  return ecoService.getActivityCountsByType();
});

// Eco activity actions provider
final ecoActivityActionsProvider = Provider<EcoActivityActions>((ref) {
  final ecoService = ref.watch(ecoServiceProvider);
  return EcoActivityActions(ecoService, ref);
});

// Eco widget view state provider (true = Today's, false = All-time)
final ecoWidgetViewStateProvider = StateProvider<bool>((ref) => true);

// Query class for filtering activities
class EcoActivitiesQuery {
  final EcoActivityType? type;
  final int limit;
  final DateTime? startDate;
  final DateTime? endDate;

  const EcoActivitiesQuery({
    this.type,
    this.limit = 50,
    this.startDate,
    this.endDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EcoActivitiesQuery &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          limit == other.limit &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode =>
      type.hashCode ^ limit.hashCode ^ startDate.hashCode ^ endDate.hashCode;
}

// Actions class for eco activities
class EcoActivityActions {
  final EcoService _ecoService;
  final Ref _ref;

  EcoActivityActions(this._ecoService, this._ref);

  // Add new eco activity
  Future<String> addActivity(EcoActivity activity) async {
    try {
      final activityId = await _ecoService.addEcoActivity(activity);

      // Invalidate relevant providers to refresh data
      _ref.invalidate(userEcoMetricsProvider);
      _ref.invalidate(recentEcoActivitiesProvider);
      _ref.invalidate(carbonSavedLast30DaysProvider);
      _ref.invalidate(activityCountsByTypeProvider);

      // Invalidate specific type provider
      switch (activity.type) {
        case EcoActivityType.transport:
          _ref.invalidate(transportActivitiesProvider);
          break;
        case EcoActivityType.food:
          _ref.invalidate(foodActivitiesProvider);
          break;
        case EcoActivityType.energy:
          _ref.invalidate(energyActivitiesProvider);
          break;
        case EcoActivityType.waste:
          _ref.invalidate(wasteActivitiesProvider);
          break;
        case EcoActivityType.consumption:
          _ref.invalidate(consumptionActivitiesProvider);
          break;
      }

      return activityId;
    } catch (e) {
      throw Exception('Failed to add eco activity: $e');
    }
  }

  // Quick activity logging methods
  Future<String> logTransportActivity(
    String activity, {
    double distance = 1.0,
    String? notes,
  }) async {
    try {
      final activityId = await _ecoService.logTransportActivity(
        activity,
        distance: distance,
        notes: notes,
      );

      // Refresh providers
      _ref.invalidate(userEcoMetricsProvider);
      _ref.invalidate(recentEcoActivitiesProvider);
      _ref.invalidate(transportActivitiesProvider);
      _ref.invalidate(carbonSavedLast30DaysProvider);

      return activityId;
    } catch (e) {
      throw Exception('Failed to log transport activity: $e');
    }
  }

  Future<String> logFoodActivity(String activity, {String? notes}) async {
    try {
      final activityId = await _ecoService.logFoodActivity(
        activity,
        notes: notes,
      );

      // Refresh providers
      _ref.invalidate(userEcoMetricsProvider);
      _ref.invalidate(recentEcoActivitiesProvider);
      _ref.invalidate(foodActivitiesProvider);
      _ref.invalidate(carbonSavedLast30DaysProvider);

      return activityId;
    } catch (e) {
      throw Exception('Failed to log food activity: $e');
    }
  }

  Future<String> logConsumptionActivity(
    String activity, {
    String? notes,
  }) async {
    try {
      final activityId = await _ecoService.logConsumptionActivity(
        activity,
        notes: notes,
      );

      // Refresh providers
      _ref.invalidate(userEcoMetricsProvider);
      _ref.invalidate(recentEcoActivitiesProvider);
      _ref.invalidate(consumptionActivitiesProvider);
      _ref.invalidate(carbonSavedLast30DaysProvider);

      return activityId;
    } catch (e) {
      throw Exception('Failed to log consumption activity: $e');
    }
  }

  // Meal logging methods
  Future<String?> logMealActivity(
    String mealCategory, {
    int? calories,
    bool isCustomMeal = false,
    String? mealName,
    String? notes,
  }) async {
    try {
      final activityId = await _ecoService.logMealActivity(
        mealCategory,
        calories: calories,
        isCustomMeal: isCustomMeal,
        mealName: mealName,
        notes: notes,
      );

      // Refresh providers
      _ref.invalidate(userEcoMetricsProvider);
      _ref.invalidate(recentEcoActivitiesProvider);
      _ref.invalidate(foodActivitiesProvider);
      _ref.invalidate(carbonSavedLast30DaysProvider);

      return activityId;
    } catch (e) {
      throw Exception('Failed to log meal activity: $e');
    }
  }

  // Auto-generate eco activity from meal logging
  Future<String?> onMealLogged({
    required String mealCategory,
    String? mealName,
    int? calories,
    bool isCustomMeal = false,
    bool autoGenerate = true,
  }) async {
    if (!autoGenerate) return null;

    try {
      final mealEcoService = _ref.read(mealEcoIntegrationProvider);
      final activityId = await mealEcoService.onMealLogged(
        mealCategory: mealCategory,
        mealName: mealName,
        calories: calories,
        isCustomMeal: isCustomMeal,
        autoGenerate: autoGenerate,
      );

      if (activityId != null) {
        // Refresh providers only if activity was created
        _ref.invalidate(userEcoMetricsProvider);
        _ref.invalidate(recentEcoActivitiesProvider);
        _ref.invalidate(foodActivitiesProvider);
        _ref.invalidate(carbonSavedLast30DaysProvider);
      }

      return activityId;
    } catch (e) {
      // Don't throw error for auto-generated activities
      return null;
    }
  }

  // Process food analysis for eco activity
  Future<String?> onFoodAnalysisLogged(FoodAnalysis foodAnalysis) async {
    try {
      final mealEcoService = _ref.read(mealEcoIntegrationProvider);
      final activityId = await mealEcoService.onFoodAnalysisLogged(
        foodAnalysis,
      );

      if (activityId != null) {
        // Refresh providers only if activity was created
        _ref.invalidate(userEcoMetricsProvider);
        _ref.invalidate(recentEcoActivitiesProvider);
        _ref.invalidate(foodActivitiesProvider);
        _ref.invalidate(carbonSavedLast30DaysProvider);
      }

      return activityId;
    } catch (e) {
      // Don't throw error for auto-generated activities
      return null;
    }
  }

  // Update activity
  Future<void> updateActivity(String activityId, EcoActivity activity) async {
    try {
      await _ecoService.updateEcoActivity(activityId, activity);

      // Refresh all providers since we don't recalculate metrics on update
      _ref.invalidate(userEcoMetricsProvider);
      _ref.invalidate(recentEcoActivitiesProvider);
      _invalidateActivityProviders();
    } catch (e) {
      throw Exception('Failed to update eco activity: $e');
    }
  }

  // Delete activity
  Future<void> deleteActivity(String activityId) async {
    try {
      await _ecoService.deleteEcoActivity(activityId);

      // Refresh all providers since we don't recalculate metrics on delete
      _ref.invalidate(userEcoMetricsProvider);
      _ref.invalidate(recentEcoActivitiesProvider);
      _invalidateActivityProviders();
    } catch (e) {
      throw Exception('Failed to delete eco activity: $e');
    }
  }

  // Transportation methods
  Future<String?> logTransportationFromHealthData({
    required int steps,
    required int activeMinutes,
    String? notes,
    bool autoGenerate = true,
  }) async {
    try {
      final activityId = await _ecoService.logTransportationFromHealthData(
        steps: steps,
        activeMinutes: activeMinutes,
        notes: notes,
        autoGenerate: autoGenerate,
      );

      if (activityId != null) {
        // Refresh providers
        _ref.invalidate(userEcoMetricsProvider);
        _ref.invalidate(recentEcoActivitiesProvider);
        _ref.invalidate(transportActivitiesProvider);
        _ref.invalidate(carbonSavedLast30DaysProvider);
      }

      return activityId;
    } catch (e) {
      throw Exception('Failed to log transportation activity: $e');
    }
  }

  // Helper to invalidate all activity type providers
  void _invalidateActivityProviders() {
    _ref.invalidate(transportActivitiesProvider);
    _ref.invalidate(foodActivitiesProvider);
    _ref.invalidate(energyActivitiesProvider);
    _ref.invalidate(wasteActivitiesProvider);
    _ref.invalidate(consumptionActivitiesProvider);
    _ref.invalidate(carbonSavedLast30DaysProvider);
    _ref.invalidate(activityCountsByTypeProvider);
  }
}

// Derived providers for UI convenience

// Total activities count
final totalActivitiesCountProvider = Provider<AsyncValue<int>>((ref) {
  final recentActivities = ref.watch(recentEcoActivitiesProvider);
  return recentActivities.whenData((activities) => activities.length);
});

// Current streak from metrics
final currentStreakProvider = Provider<AsyncValue<int>>((ref) {
  final metrics = ref.watch(userEcoMetricsProvider);
  return metrics.whenData((metric) => metric.currentStreak);
});

// Today's activities
final todaysActivitiesProvider = Provider<AsyncValue<List<EcoActivity>>>((ref) {
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  final query = EcoActivitiesQuery(
    startDate: startOfDay,
    endDate: endOfDay,
    limit: 20,
  );

  return ref.watch(userEcoActivitiesProvider(query));
});

// Today's carbon saved (calculated from today's activities only)
final todaysCarbonSavedProvider = Provider<AsyncValue<double>>((ref) {
  final todaysActivities = ref.watch(todaysActivitiesProvider);
  return todaysActivities.whenData((activities) {
    return activities.fold<double>(0.0, (sum, activity) => sum + activity.carbonSaved);
  });
});

// Today's bottles saved equivalent
final todaysBottlesSavedProvider = Provider<AsyncValue<int>>((ref) {
  final todaysCarbon = ref.watch(todaysCarbonSavedProvider);
  return todaysCarbon.whenData((carbon) => EcoMetrics.carbonToBottles(carbon));
});

// Today's activity count
final todaysActivityCountProvider = Provider<AsyncValue<int>>((ref) {
  final todaysActivities = ref.watch(todaysActivitiesProvider);
  return todaysActivities.whenData((activities) => activities.length);
});

// Today's activities by type
final todaysActivitiesByTypeProvider = Provider<AsyncValue<Map<EcoActivityType, List<EcoActivity>>>>((ref) {
  final todaysActivities = ref.watch(todaysActivitiesProvider);
  return todaysActivities.whenData((activities) {
    final byType = <EcoActivityType, List<EcoActivity>>{};
    for (final activity in activities) {
      byType[activity.type] = [...(byType[activity.type] ?? []), activity];
    }
    return byType;
  });
});

// Today's carbon by category
final todaysCarbonByTypeProvider = Provider<AsyncValue<Map<EcoActivityType, double>>>((ref) {
  final todaysActivities = ref.watch(todaysActivitiesProvider);
  return todaysActivities.whenData((activities) {
    final byType = <EcoActivityType, double>{};
    for (final activity in activities) {
      byType[activity.type] = (byType[activity.type] ?? 0.0) + activity.carbonSaved;
    }
    return byType;
  });
});

// This week's carbon savings
final thisWeekCarbonSavedProvider = FutureProvider<double>((ref) async {
  final today = DateTime.now();
  final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
  final startOfWeekMidnight = DateTime(
    startOfWeek.year,
    startOfWeek.month,
    startOfWeek.day,
  );

  final query = EcoActivitiesQuery(startDate: startOfWeekMidnight, limit: 100);

  final activities = await ref.watch(userEcoActivitiesProvider(query).future);
  return activities.fold<double>(
    0.0,
    (sum, activity) => sum + activity.carbonSaved,
  );
});

// Meal carbon savings potential provider
final mealCarbonPotentialProvider = Provider.family<double, MealCarbonQuery>((
  ref,
  query,
) {
  return EcoService.calculateMealCarbonSaved(
    query.mealCategory,
    calories: query.calories,
    isCustomMeal: query.isCustomMeal,
  );
});

// Meal sustainability tip provider
final mealSustainabilityTipProvider = Provider.family<String, String>((
  ref,
  mealCategory,
) {
  final mealEcoService = ref.watch(mealEcoIntegrationProvider);
  return mealEcoService.getSustainabilityTip(mealCategory);
});

// Transportation carbon calculation provider
final transportationCarbonPotentialProvider =
    Provider.family<double, TransportationCarbonQuery>((ref, query) {
      return EcoService.calculateTransportationCarbonSaved(
        steps: query.steps,
        activeMinutes: query.activeMinutes,
      );
    });

// Query class for meal carbon calculations
class MealCarbonQuery {
  final String mealCategory;
  final int? calories;
  final bool isCustomMeal;

  const MealCarbonQuery({
    required this.mealCategory,
    this.calories,
    this.isCustomMeal = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealCarbonQuery &&
          runtimeType == other.runtimeType &&
          mealCategory == other.mealCategory &&
          calories == other.calories &&
          isCustomMeal == other.isCustomMeal;

  @override
  int get hashCode =>
      mealCategory.hashCode ^ calories.hashCode ^ isCustomMeal.hashCode;
}

// Query class for transportation carbon calculations
class TransportationCarbonQuery {
  final int steps;
  final int activeMinutes;

  const TransportationCarbonQuery({
    required this.steps,
    required this.activeMinutes,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransportationCarbonQuery &&
          runtimeType == other.runtimeType &&
          steps == other.steps &&
          activeMinutes == other.activeMinutes;

  @override
  int get hashCode => steps.hashCode ^ activeMinutes.hashCode;
}

// Supporter eco data providers

// Supporter's eco metrics stream
final supporterEcoMetricsProvider = StreamProvider.family<EcoMetrics, String>((ref, supporterId) {
  final ecoService = ref.watch(ecoServiceProvider);
  return ecoService.getSupporterEcoMetrics(supporterId);
});

// Supporter's today's activities
final supporterTodaysActivitiesProvider = Provider.family<AsyncValue<List<EcoActivity>>, String>((ref, supporterId) {
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  final query = EcoActivitiesQuery(
    startDate: startOfDay,
    endDate: endOfDay,
    limit: 20,
  );

  return ref.watch(supporterEcoActivitiesProvider(SupporterEcoQuery(
    supporterId: supporterId,
    query: query,
  )));
});

// Supporter's today's carbon saved
final supporterTodaysCarbonSavedProvider = Provider.family<AsyncValue<double>, String>((ref, supporterId) {
  final todaysActivities = ref.watch(supporterTodaysActivitiesProvider(supporterId));
  return todaysActivities.whenData((activities) {
    return activities.fold<double>(0.0, (sum, activity) => sum + activity.carbonSaved);
  });
});

// Supporter's today's bottles saved equivalent
final supporterTodaysBottlesSavedProvider = Provider.family<AsyncValue<int>, String>((ref, supporterId) {
  final todaysCarbon = ref.watch(supporterTodaysCarbonSavedProvider(supporterId));
  return todaysCarbon.whenData((carbon) => EcoMetrics.carbonToBottles(carbon));
});

// Supporter's today's activity count
final supporterTodaysActivityCountProvider = Provider.family<AsyncValue<int>, String>((ref, supporterId) {
  final todaysActivities = ref.watch(supporterTodaysActivitiesProvider(supporterId));
  return todaysActivities.whenData((activities) => activities.length);
});

// Supporter's eco activities stream with optional filtering
final supporterEcoActivitiesProvider = StreamProvider.family<List<EcoActivity>, SupporterEcoQuery>((ref, query) {
  final ecoService = ref.watch(ecoServiceProvider);
  return ecoService.getSupporterEcoActivities(
    query.supporterId,
    type: query.query.type,
    limit: query.query.limit,
    startDate: query.query.startDate,
    endDate: query.query.endDate,
  );
});

// Query class for supporter eco data
class SupporterEcoQuery {
  final String supporterId;
  final EcoActivitiesQuery query;

  const SupporterEcoQuery({
    required this.supporterId,
    required this.query,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupporterEcoQuery &&
          runtimeType == other.runtimeType &&
          supporterId == other.supporterId &&
          query == other.query;

  @override
  int get hashCode => supporterId.hashCode ^ query.hashCode;
}
