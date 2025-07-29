// TransportationMapWidget - DEPRECATED
// This widget is no longer used since we replaced Google Maps with lightweight fitness tracker
// Keeping commented for reference in case future reversion is needed

/*
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/riverpod/location_provider.dart';

class TransportationMapWidget extends ConsumerStatefulWidget {
  final double height;
  final bool showRoutes;
  final bool enableInteraction;

  const TransportationMapWidget({
    super.key,
    this.height = 120,
    this.showRoutes = true,
    this.enableInteraction = false,
  });

  @override
  ConsumerState<TransportationMapWidget> createState() => _TransportationMapWidgetState();
}

class _TransportationMapWidgetState extends ConsumerState<TransportationMapWidget> 
    with AutomaticKeepAliveClientMixin {
  GoogleMapController? _mapController;
  bool _isDisposed = false;
  
  @override
  bool get wantKeepAlive => false; // Don't keep alive to save memory
  
  static const String _lightMapStyle = '''
    [
      {
        "featureType": "poi.park",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#a5d6a7"
          }
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "geometry.stroke",
        "stylers": [
          {
            "color": "#ffab40"
          }
        ]
      },
      {
        "featureType": "transit.line",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#4fc3f7"
          }
        ]
      }
    ]
    ''';

  static const String _darkMapStyle = '''
    [
      {
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#212121"
          }
        ]
      },
      {
        "elementType": "labels.icon",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      },
      {
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#757575"
          }
        ]
      },
      {
        "elementType": "labels.text.stroke",
        "stylers": [
          {
            "color": "#212121"
          }
        ]
      },
      {
        "featureType": "administrative",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#757575"
          }
        ]
      },
      {
        "featureType": "administrative.country",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#9e9e9e"
          }
        ]
      },
      {
        "featureType": "administrative.land_parcel",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      },
      {
        "featureType": "administrative.locality",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#bdbdbd"
          }
        ]
      },
      {
        "featureType": "poi",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#757575"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#2e7d32"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#4caf50"
          }
        ]
      },
      {
        "featureType": "road",
        "elementType": "geometry.fill",
        "stylers": [
          {
            "color": "#2c2c2c"
          }
        ]
      },
      {
        "featureType": "road",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#8a8a8a"
          }
        ]
      },
      {
        "featureType": "road.arterial",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#373737"
          }
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#3c3c3c"
          }
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "geometry.stroke",
        "stylers": [
          {
            "color": "#ff9800"
          }
        ]
      },
      {
        "featureType": "road.highway.controlled_access",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#4e4e4e"
          }
        ]
      },
      {
        "featureType": "road.local",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#616161"
          }
        ]
      },
      {
        "featureType": "transit",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#757575"
          }
        ]
      },
      {
        "featureType": "transit.line",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#2196f3"
          }
        ]
      },
      {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#000000"
          }
        ]
      },
      {
        "featureType": "water",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#3d3d3d"
          }
        ]
      }
    ]
    ''';

  String _getMapStyle(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? _darkMapStyle : _lightMapStyle;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _mapController?.dispose();
    _mapController = null;
    super.dispose();
  }
  
  @override
  void deactivate() {
    _mapController?.dispose();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    if (_isDisposed) {
      return Container(
        height: widget.height,
        color: Colors.grey[300],
        child: const Center(child: Text('Map disposed')),
      );
    }
    
    final locationStatus = ref.watch(locationStatusProvider);
    final currentPosition = ref.watch(currentPositionNotifierProvider);
    final ecoRoutes = ref.watch(ecoRoutesNotifierProvider);

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: locationStatus.when(
          data: (status) {
            switch (status) {
              case LocationStatus.available:
                return currentPosition.when(
                  data: (position) => position != null
                      ? _buildGoogleMap(position, ecoRoutes)
                      : _buildLoadingMap(),
                  loading: () => _buildLoadingMap(),
                  error: (error, _) => _buildErrorMap('Location unavailable'),
                );
              case LocationStatus.permissionDenied:
                return _buildPermissionDeniedMap();
              case LocationStatus.serviceDisabled:
                return _buildServiceDisabledMap();
              case LocationStatus.error:
                return _buildErrorMap('Location error');
            }
          },
          loading: () => _buildLoadingMap(),
          error: (error, _) => _buildErrorMap('Failed to load map'),
        ),
      ),
    );
  }

  Widget _buildGoogleMap(Position position, List<Map<String, dynamic>> routes) {
    final initialCameraPosition = CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 14.0,
    );

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: initialCameraPosition,
          onMapCreated: _onMapCreated,
          markers: widget.showRoutes ? _buildOptimizedMarkers(position, routes) : <Marker>{},
          polylines: widget.showRoutes ? _buildOptimizedPolylines(position, routes) : <Polyline>{},
          myLocationEnabled: widget.height > 150, // Only enable for larger maps
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          scrollGesturesEnabled: widget.enableInteraction,
          zoomGesturesEnabled: widget.enableInteraction,
          rotateGesturesEnabled: widget.enableInteraction,
          tiltGesturesEnabled: false,
          mapType: MapType.normal,
          compassEnabled: false,
          trafficEnabled: false,
          buildingsEnabled: widget.height > 200, // Disable buildings for small maps
          style: widget.height > 150 ? _getMapStyle(context) : null, // Simplified style for small maps
          liteModeEnabled: widget.height <= 150, // Use lite mode for small preview maps
        ),
        if (widget.showRoutes && routes.isNotEmpty)
          _buildRouteOverlay(routes),
      ],
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    if (!_isDisposed) {
      _mapController = controller;
    }
  }

  Set<Marker> _buildOptimizedMarkers(Position position, List<Map<String, dynamic>> routes) {
    final markers = <Marker>{};
    
    // For small maps, only show user location
    if (widget.height <= 150) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(position.latitude, position.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
      return markers;
    }
    
    return _buildMarkers(position, routes);
  }

  Set<Polyline> _buildOptimizedPolylines(Position position, List<Map<String, dynamic>> routes) {
    // For small maps, don't show polylines to save memory
    if (widget.height <= 150) {
      return <Polyline>{};
    }
    
    return _buildPolylines(position, routes);
  }

  Set<Marker> _buildMarkers(Position position, List<Map<String, dynamic>> routes) {
    final markers = <Marker>{};

    // Current location marker
    markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: LatLng(position.latitude, position.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(
          title: 'Your Location',
          snippet: 'Start your eco-friendly journey here',
        ),
      ),
    );

    // Add destination markers for demo (could be work, home, etc.)
    if (routes.isNotEmpty) {
      // Sample destination (you could get this from user preferences)
      final destLat = position.latitude + 0.01; // ~1km north
      final destLng = position.longitude + 0.005; // ~0.5km east
      
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(destLat, destLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Destination',
            snippet: 'Eco-friendly routes available',
          ),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines(Position position, List<Map<String, dynamic>> routes) {
    final polylines = <Polyline>{};

    if (routes.isNotEmpty && widget.showRoutes) {
      // Limit the number of routes to prevent memory issues
      final limitedRoutes = routes.take(2).toList();
      
      // Sample route line (in a real app, you'd use Google Directions API)
      final destLat = position.latitude + 0.01;
      final destLng = position.longitude + 0.005;

      // Walking route (green) - simplified with fewer points
      polylines.add(
        Polyline(
          polylineId: const PolylineId('walking_route'),
          points: [
            LatLng(position.latitude, position.longitude),
            LatLng(destLat, destLng),
          ],
          color: Colors.green,
          width: 3,
          patterns: [PatternItem.dot, PatternItem.gap(15)],
        ),
      );

      // Only add biking route if there are multiple routes and map is large enough
      if (limitedRoutes.length > 1 && widget.height > 200) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('biking_route'),
            points: [
              LatLng(position.latitude, position.longitude),
              LatLng(destLat + 0.002, destLng + 0.001),
            ],
            color: Colors.blue,
            width: 2,
            patterns: [PatternItem.dash(15), PatternItem.gap(10)],
          ),
        );
      }
    }

    return polylines;
  }

  Widget _buildRouteOverlay(List<Map<String, dynamic>> routes) {
    if (routes.isEmpty) return const SizedBox();

    final bestRoute = routes.first; // Assuming routes are sorted by eco-friendliness

    return Positioned(
      bottom: 8,
      left: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              _getRouteIcon(bestRoute['icon'] as String),
              color: _getRouteColor(bestRoute['color'] as String),
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bestRoute['name'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '${(bestRoute['carbonSaved'] as double).toStringAsFixed(1)} kg CO₂ saved',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.eco,
              color: Colors.green[600],
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingMap() {
    return Container(
      color: Colors.grey[100],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text(
              'Loading map...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedMap() {
    return Container(
      color: Colors.orange[50],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, color: Colors.orange[600], size: 32),
            const SizedBox(height: 8),
            const Text(
              'Location access needed',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () {
                ref.read(locationPermissionNotifierProvider.notifier).requestPermission();
              },
              child: const Text('Enable Location', style: TextStyle(fontSize: 10)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceDisabledMap() {
    return Container(
      color: Colors.red[50],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_disabled, color: Colors.red[600], size: 32),
            const SizedBox(height: 8),
            const Text(
              'Location services disabled',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const Text(
              'Enable in device settings',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMap(String message) {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.grey[600], size: 32),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getRouteIcon(String iconName) {
    switch (iconName) {
      case 'directions_walk':
        return Icons.directions_walk;
      case 'directions_bike':
        return Icons.directions_bike;
      case 'directions_bus':
        return Icons.directions_bus;
      default:
        return Icons.directions;
    }
  }

  Color _getRouteColor(String colorName) {
    switch (colorName) {
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'orange':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
*/