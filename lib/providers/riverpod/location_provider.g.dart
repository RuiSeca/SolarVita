// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$locationServiceHash() => r'38d15292e1d1d4553c8f07a36b00411aa0a8d30e';

/// See also [locationService].
@ProviderFor(locationService)
final locationServiceProvider = AutoDisposeProvider<LocationService>.internal(
  locationService,
  name: r'locationServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$locationServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LocationServiceRef = AutoDisposeProviderRef<LocationService>;
String _$locationServiceEnabledHash() =>
    r'c878d7a970f54af61570e42b73d3655148eef916';

/// See also [locationServiceEnabled].
@ProviderFor(locationServiceEnabled)
final locationServiceEnabledProvider = AutoDisposeFutureProvider<bool>.internal(
  locationServiceEnabled,
  name: r'locationServiceEnabledProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$locationServiceEnabledHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LocationServiceEnabledRef = AutoDisposeFutureProviderRef<bool>;
String _$positionStreamHash() => r'274803d19605c3cf8e8a510f81ed275a305c07f0';

/// See also [positionStream].
@ProviderFor(positionStream)
final positionStreamProvider = AutoDisposeStreamProvider<Position>.internal(
  positionStream,
  name: r'positionStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$positionStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PositionStreamRef = AutoDisposeStreamProviderRef<Position>;
String _$currentLocationCarbonSavingsHash() =>
    r'e03d0c8a559fe800c7b633f00b2a05f646a9bb5d';

/// See also [currentLocationCarbonSavings].
@ProviderFor(currentLocationCarbonSavings)
final currentLocationCarbonSavingsProvider =
    AutoDisposeProvider<double>.internal(
      currentLocationCarbonSavings,
      name: r'currentLocationCarbonSavingsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$currentLocationCarbonSavingsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentLocationCarbonSavingsRef = AutoDisposeProviderRef<double>;
String _$locationStatusHash() => r'6064fc3147e50d0d42f634604a481a0602988fb6';

/// See also [locationStatus].
@ProviderFor(locationStatus)
final locationStatusProvider =
    AutoDisposeFutureProvider<LocationStatus>.internal(
      locationStatus,
      name: r'locationStatusProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$locationStatusHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LocationStatusRef = AutoDisposeFutureProviderRef<LocationStatus>;
String _$currentPositionNotifierHash() =>
    r'a9948b408bd16d58b7b500b84d12e714914ee369';

/// See also [CurrentPositionNotifier].
@ProviderFor(CurrentPositionNotifier)
final currentPositionNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      CurrentPositionNotifier,
      Position?
    >.internal(
      CurrentPositionNotifier.new,
      name: r'currentPositionNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$currentPositionNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CurrentPositionNotifier = AutoDisposeAsyncNotifier<Position?>;
String _$locationPermissionNotifierHash() =>
    r'd78edc94e25badef0ea61fec5c60a04155802319';

/// See also [LocationPermissionNotifier].
@ProviderFor(LocationPermissionNotifier)
final locationPermissionNotifierProvider =
    AutoDisposeAsyncNotifierProvider<LocationPermissionNotifier, bool>.internal(
      LocationPermissionNotifier.new,
      name: r'locationPermissionNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$locationPermissionNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$LocationPermissionNotifier = AutoDisposeAsyncNotifier<bool>;
String _$ecoRoutesNotifierHash() => r'f6eda9ffc42c0994ba9b3c28159f7e2b4a816032';

/// See also [EcoRoutesNotifier].
@ProviderFor(EcoRoutesNotifier)
final ecoRoutesNotifierProvider =
    AutoDisposeNotifierProvider<
      EcoRoutesNotifier,
      List<Map<String, dynamic>>
    >.internal(
      EcoRoutesNotifier.new,
      name: r'ecoRoutesNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$ecoRoutesNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$EcoRoutesNotifier = AutoDisposeNotifier<List<Map<String, dynamic>>>;
String _$currentAddressNotifierHash() =>
    r'26d852418f8dc641a7b2f02d48cc7ebaa95e3cf9';

/// See also [CurrentAddressNotifier].
@ProviderFor(CurrentAddressNotifier)
final currentAddressNotifierProvider =
    AutoDisposeNotifierProvider<CurrentAddressNotifier, String?>.internal(
      CurrentAddressNotifier.new,
      name: r'currentAddressNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$currentAddressNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CurrentAddressNotifier = AutoDisposeNotifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
