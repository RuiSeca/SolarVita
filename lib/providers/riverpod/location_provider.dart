import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/location_service.dart';

part 'location_provider.g.dart';

// Location service provider
@riverpod
LocationService locationService(Ref ref) {
  return LocationService();
}

// Current position provider
@riverpod
class CurrentPositionNotifier extends _$CurrentPositionNotifier {
  @override
  Future<Position?> build() async {
    final service = ref.read(locationServiceProvider);
    return await service.getCurrentPosition();
  }

  Future<void> updatePosition() async {
    state = const AsyncValue.loading();
    final service = ref.read(locationServiceProvider);
    
    try {
      final position = await service.getCurrentPosition();
      state = AsyncValue.data(position);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> requestPermissionAndUpdate() async {
    final service = ref.read(locationServiceProvider);
    final hasPermission = await service.requestLocationPermission();
    
    if (hasPermission) {
      await updatePosition();
    } else {
      state = AsyncValue.error('Location permission denied', StackTrace.current);
    }
  }
}

// Location permission status provider
@riverpod
class LocationPermissionNotifier extends _$LocationPermissionNotifier {
  @override
  Future<bool> build() async {
    final service = ref.read(locationServiceProvider);
    return await service.hasLocationPermission();
  }

  Future<void> requestPermission() async {
    state = const AsyncValue.loading();
    final service = ref.read(locationServiceProvider);
    
    try {
      final hasPermission = await service.requestLocationPermission();
      state = AsyncValue.data(hasPermission);
      
      // Update position if permission granted
      if (hasPermission) {
        ref.read(currentPositionNotifierProvider.notifier).updatePosition();
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// Location service enabled provider
@riverpod
Future<bool> locationServiceEnabled(Ref ref) async {
  final service = ref.read(locationServiceProvider);
  return await service.isLocationServiceEnabled();
}

// Eco-friendly routes provider
@riverpod
class EcoRoutesNotifier extends _$EcoRoutesNotifier {
  @override
  List<Map<String, dynamic>> build() {
    return [];
  }

  void updateRoutes(Position start, Position end) {
    final service = ref.read(locationServiceProvider);
    final routes = service.getEcoFriendlyRoutes(start, end);
    state = routes;
  }

  void clearRoutes() {
    state = [];
  }
}

// Current address provider
@riverpod
class CurrentAddressNotifier extends _$CurrentAddressNotifier {
  @override
  String? build() {
    return null;
  }

  Future<void> updateAddressFromPosition(Position position) async {
    final service = ref.read(locationServiceProvider);
    try {
      final address = await service.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      state = address;
    } catch (e) {
      state = null;
    }
  }
}

// Position stream provider for real-time tracking
@riverpod
Stream<Position> positionStream(Ref ref) {
  final service = ref.read(locationServiceProvider);
  return service.getPositionStream();
}

// Transportation carbon savings provider based on current location
@riverpod
double currentLocationCarbonSavings(Ref ref) {
  final routes = ref.watch(ecoRoutesNotifierProvider);
  
  // Calculate total potential carbon savings from all eco routes
  return routes.fold<double>(0, (sum, route) {
    return sum + (route['carbonSaved'] as double? ?? 0);
  });
}

// Helper provider to check if location features are available
@riverpod
Future<LocationStatus> locationStatus(Ref ref) async {
  final hasPermission = await ref.watch(locationPermissionNotifierProvider.future);
  final serviceEnabled = await ref.watch(locationServiceEnabledProvider.future);
  
  if (!serviceEnabled) {
    return LocationStatus.serviceDisabled;
  } else if (!hasPermission) {
    return LocationStatus.permissionDenied;
  } else {
    return LocationStatus.available;
  }
}

enum LocationStatus {
  available,
  permissionDenied,
  serviceDisabled,
  error,
}