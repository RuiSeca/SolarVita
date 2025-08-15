// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

/// See also [mealService].
@ProviderFor(mealService)
final mealServiceProvider = AutoDisposeProvider<MealDBService>(
  mealService,
  name: r'mealServiceProvider',
);

typedef MealServiceRef = Ref<MealDBService>;

/// See also [meals].
@ProviderFor(meals)
final mealsProvider = AutoDisposeProvider<List<Map<String, dynamic>>>(
  meals,
  name: r'mealsProvider',
);

typedef MealsRef = Ref<List<Map<String, dynamic>>>;

/// See also [isMealsLoading].
@ProviderFor(isMealsLoading)
final isMealsLoadingProvider = AutoDisposeProvider<bool>(
  isMealsLoading,
  name: r'isMealsLoadingProvider',
);

typedef IsMealsLoadingRef = Ref<bool>;

/// See also [hasMealsError].
@ProviderFor(hasMealsError)
final hasMealsErrorProvider = AutoDisposeProvider<bool>(
  hasMealsError,
  name: r'hasMealsErrorProvider',
);

typedef HasMealsErrorRef = Ref<bool>;

/// See also [mealsErrorMessage].
@ProviderFor(mealsErrorMessage)
final mealsErrorMessageProvider = AutoDisposeProvider<String?>(
  mealsErrorMessage,
  name: r'mealsErrorMessageProvider',
);

typedef MealsErrorMessageRef = Ref<String?>;

/// See also [mealsErrorDetails].
@ProviderFor(mealsErrorDetails)
final mealsErrorDetailsProvider = AutoDisposeProvider<String?>(
  mealsErrorDetails,
  name: r'mealsErrorDetailsProvider',
);

typedef MealsErrorDetailsRef = Ref<String?>;

/// See also [currentMealCategory].
@ProviderFor(currentMealCategory)
final currentMealCategoryProvider = AutoDisposeProvider<String?>(
  currentMealCategory,
  name: r'currentMealCategoryProvider',
);

typedef CurrentMealCategoryRef = Ref<String?>;

/// See also [currentMealQuery].
@ProviderFor(currentMealQuery)
final currentMealQueryProvider = AutoDisposeProvider<String?>(
  currentMealQuery,
  name: r'currentMealQueryProvider',
);

typedef CurrentMealQueryRef = Ref<String?>;

/// See also [hasMealsData].
@ProviderFor(hasMealsData)
final hasMealsDataProvider = AutoDisposeProvider<bool>(
  hasMealsData,
  name: r'hasMealsDataProvider',
);

typedef HasMealsDataRef = Ref<bool>;

/// See also [isMealsLoadingDetails].
@ProviderFor(isMealsLoadingDetails)
final isMealsLoadingDetailsProvider = AutoDisposeProvider<bool>(
  isMealsLoadingDetails,
  name: r'isMealsLoadingDetailsProvider',
);

typedef IsMealsLoadingDetailsRef = Ref<bool>;

/// See also [isLoadingMoreMeals].
@ProviderFor(isLoadingMoreMeals)
final isLoadingMoreMealsProvider = AutoDisposeProvider<bool>(
  isLoadingMoreMeals,
  name: r'isLoadingMoreMealsProvider',
);

typedef IsLoadingMoreMealsRef = Ref<bool>;

/// See also [hasMoreMealsData].
@ProviderFor(hasMoreMealsData)
final hasMoreMealsDataProvider = AutoDisposeProvider<bool>(
  hasMoreMealsData,
  name: r'hasMoreMealsDataProvider',
);

typedef HasMoreMealsDataRef = Ref<bool>;

/// See also [currentMealPage].
@ProviderFor(currentMealPage)
final currentMealPageProvider = AutoDisposeProvider<int>(
  currentMealPage,
  name: r'currentMealPageProvider',
);

typedef CurrentMealPageRef = Ref<int>;

/// See also [MealNotifier].
@ProviderFor(MealNotifier)
final mealNotifierProvider = NotifierProvider<MealNotifier, MealState>(
  MealNotifier.new,
  name: r'mealNotifierProvider',
);

typedef _$MealNotifier = Notifier<MealState>;