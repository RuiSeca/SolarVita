import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _lastKnownPosition;
  bool _isLocationServiceEnabled = false;
  LocationPermission? _locationPermission;

  // Get current position with permission handling
  Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      _isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!_isLocationServiceEnabled) {
        debugPrint('Location services are disabled.');
        return null;
      }

      // Check permissions
      _locationPermission = await Geolocator.checkPermission();
      if (_locationPermission == LocationPermission.denied) {
        _locationPermission = await Geolocator.requestPermission();
        if (_locationPermission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return null;
        }
      }

      if (_locationPermission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _lastKnownPosition = position;
      return position;
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return _lastKnownPosition; // Return last known position if available
    }
  }

  // Get address from coordinates
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}';
      }
    } catch (e) {
      debugPrint('Error getting address from coordinates: $e');
    }
    return null;
  }

  // Get coordinates from address
  Future<Position?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        return Position(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }
    } catch (e) {
      debugPrint('Error getting coordinates from address: $e');
    }
    return null;
  }

  // Calculate distance between two points
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // Check if location permissions are granted
  Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  // Request location permission
  Future<bool> requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Get last known position (cached)
  Position? get lastKnownPosition => _lastKnownPosition;

  // Listen to position changes (for real-time tracking)
  Stream<Position> getPositionStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Only update when moved 10 meters
    );
    
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  // Generate eco-friendly route suggestions
  List<Map<String, dynamic>> getEcoFriendlyRoutes(Position start, Position end) {
    final distance = calculateDistance(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );

    // Convert distance to km
    final distanceKm = distance / 1000;

    List<Map<String, dynamic>> routes = [];

    // Walking route (always available for short distances)
    if (distanceKm <= 5.0) {
      routes.add({
        'type': 'walking',
        'name': 'Walking Route',
        'distance': distanceKm,
        'duration': (distanceKm / 5.0 * 60).round(), // 5 km/h average walking speed
        'carbonSaved': distanceKm * 0.21, // kg CO2 saved vs car
        'icon': 'directions_walk',
        'color': 'green',
        'description': 'Zero emissions, great exercise!',
      });
    }

    // Biking route (for reasonable distances)
    if (distanceKm <= 15.0) {
      routes.add({
        'type': 'biking',
        'name': 'Biking Route',
        'distance': distanceKm,
        'duration': (distanceKm / 15.0 * 60).round(), // 15 km/h average biking speed
        'carbonSaved': distanceKm * 0.21, // kg CO2 saved vs car
        'icon': 'directions_bike',
        'color': 'blue',
        'description': 'Fast, fun, and eco-friendly!',
      });
    }

    // Public transport route (for longer distances)
    if (distanceKm > 2.0) {
      routes.add({
        'type': 'public_transport',
        'name': 'Public Transport',
        'distance': distanceKm,
        'duration': (distanceKm / 25.0 * 60).round(), // Estimated with stops
        'carbonSaved': distanceKm * 0.15, // kg CO2 saved vs car
        'icon': 'directions_bus',
        'color': 'orange',
        'description': 'Efficient for longer distances',
      });
    }

    return routes;
  }
}