// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$mealServiceHash() => r'5f2e147a093be1a1b412b8e10ff2fae960b6ea';

/// See also [mealService].
@ProviderFor(mealService)
final mealServiceProvider = AutoDisposeProvider<MealDBService>.internal(
  mealService,
  name: r'mealServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$mealServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MealServiceRef = AutoDisposeProviderRef<MealDBService>;
String _$mealsHash() => r'37563ee93961283c136afef2fb7384e6c8807459';

/// See also [meals].
@ProviderFor(meals)
final mealsProvider = AutoDisposeProvider<List<Map<String, dynamic>>>.internal(
  meals,
  name: r'mealsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$mealsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MealsRef = AutoDisposeProviderRef<List<Map<String, dynamic>>>;
String _$isMealsLoadingHash() =>
    r'c70ac32d0cb6280e622cebc59b06330b27b11cc5';

/// See also [isMealsLoading].
@ProviderFor(isMealsLoading)
final isMealsLoadingProvider = AutoDisposeProvider<bool>.internal(
  isMealsLoading,
  name: r'isMealsLoadingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isMealsLoadingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsMealsLoadingRef = AutoDisposeProviderRef<bool>;
String _$hasMealsErrorHash() => r'd11d5ec4a09c1d888a7d140ec71212ba11f17f6f';

/// See also [hasMealsError].
@ProviderFor(hasMealsError)
final hasMealsErrorProvider = AutoDisposeProvider<bool>.internal(
  hasMealsError,
  name: r'hasMealsErrorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hasMealsErrorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HasMealsErrorRef = AutoDisposeProviderRef<bool>;
String _$mealsErrorMessageHash() =>
    r'5cf90bff25e235d38ef0c82550361a544b635b24';

/// See also [mealsErrorMessage].
@ProviderFor(mealsErrorMessage)
final mealsErrorMessageProvider = AutoDisposeProvider<String?>.internal(
  mealsErrorMessage,
  name: r'mealsErrorMessageProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$mealsErrorMessageHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MealsErrorMessageRef = AutoDisposeProviderRef<String?>;
String _$mealsErrorDetailsHash() =>
    r'436ada5af07bf26a1221ea90d62f49c7eb6abd4b';

/// See also [mealsErrorDetails].
@ProviderFor(mealsErrorDetails)
final mealsErrorDetailsProvider = AutoDisposeProvider<String?>.internal(
  mealsErrorDetails,
  name: r'mealsErrorDetailsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$mealsErrorDetailsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MealsErrorDetailsRef = AutoDisposeProviderRef<String?>;
String _$currentMealCategoryHash() =>
    r'2ef0740683d71be22b3aee1e4a1bf2863b7713f2';

/// See also [currentMealCategory].
@ProviderFor(currentMealCategory)
final currentMealCategoryProvider = AutoDisposeProvider<String?>.internal(
  currentMealCategory,
  name: r'currentMealCategoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentMealCategoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentMealCategoryRef = AutoDisposeProviderRef<String?>;
String _$currentMealQueryHash() =>
    r'3ef0740683d71be22b3aee1e4a1bf2863b7713f3';

/// See also [currentMealQuery].
@ProviderFor(currentMealQuery)
final currentMealQueryProvider = AutoDisposeProvider<String?>.internal(
  currentMealQuery,
  name: r'currentMealQueryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentMealQueryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentMealQueryRef = AutoDisposeProviderRef<String?>;
String _$hasMealsDataHash() => r'8793f8dd2342fb665fad16436f36ec2fb2624b99';

/// See also [hasMealsData].
@ProviderFor(hasMealsData)
final hasMealsDataProvider = AutoDisposeProvider<bool>.internal(
  hasMealsData,
  name: r'hasMealsDataProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hasMealsDataHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HasMealsDataRef = AutoDisposeProviderRef<bool>;
String _$mealNotifierHash() => r'def520a85b88244136bc8d81c12674fef779ad41';

/// See also [MealNotifier].
@ProviderFor(MealNotifier)
final mealNotifierProvider =
    NotifierProvider<MealNotifier, MealState>.internal(
  MealNotifier.new,
  name: r'mealNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$mealNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MealNotifier = Notifier<MealState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package