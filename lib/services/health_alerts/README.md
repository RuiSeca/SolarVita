# Health Alerts System

This health alerts system provides intelligent color-changing pulse backgrounds based on real health data from APIs and sensors.

## Quick Setup Guide

### 1. Add Dependencies

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  # Existing dependencies
  flutter:
    sdk: flutter
  
  # Add these new dependencies
  http: ^1.1.0
  geolocator: ^10.1.0
  logger: ^2.0.2+1
  shared_preferences: ^2.2.2
  
  # Optional - for health sensor data (can be added later)
  # health: ^10.2.0
```

Run: `flutter pub get`

### 2. Add Your API Key

Your OpenWeatherMap API key has been added to the `.env` file:
```
OPENWEATHER_API_KEY=67ad6c9ef105861fb135be223693f617
```

The services automatically load this from the environment variables - no manual code changes needed!

### 3. Add Permissions

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to provide local weather and air quality data.</string>
```

### 4. Basic Integration

Add to your dashboard:

```dart
import 'package:solar_vitas/widgets/pulse_background.dart';

// In your dashboard build method:
SliverToBoxAdapter(
  child: ScrollAwarePulse(height: 280),
),
```

### 5. Initialize in Your App

```dart
class _DashboardState extends State<DashboardScreen> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _initializeHealthSystem();
  }

  Future<void> _initializeHealthSystem() async {
    final colorManager = PulseColorManager.instance;
    await colorManager.initialize(
      vsync: this,
      userAge: 25, // Get from your user profile
    );
  }
}
```

## How It Works

### Color Priority System:
1. **User Mood Selection** (30 minutes) - Highest priority
2. **Health Alerts** (10 minutes) - High priority  
3. **Circadian Rhythm** (Always active) - Base color

### Data Sources:
- **Air Quality**: OpenWeatherMap Air Pollution API
- **Weather**: OpenWeatherMap Current Weather API
- **Hydration**: Your existing health screen data
- **Heart Rate/Sleep**: Device sensors (graceful fallback if unavailable)

### Alert Colors:
- 🔴 **Red**: Critical alerts (dangerous air quality, extreme weather, severe dehydration)
- 🟠 **Orange**: High alerts (moderate air quality issues, high UV, mild dehydration)
- 🟡 **Yellow**: Warning alerts (minor issues requiring attention)
- 🟢 **Green**: Normal/good conditions

## Testing

During development, set `kDebugMode = true` to use mock data instead of real API calls.

## Troubleshooting

### No Colors Changing:
1. Check API keys are added correctly
2. Verify location permissions granted
3. Check console for error messages

### Location Errors:
1. Enable location services on device
2. Grant location permission to app
3. Test on physical device (location doesn't work well in simulator)

### API Errors:
1. Verify API keys are correct
2. Check internet connection
3. Ensure API quotas not exceeded

## File Structure

```
lib/services/health_alerts/
├── health_alert_models.dart          # Data models and enums
├── weather_service.dart              # OpenWeatherMap integration
├── air_quality_service.dart          # IQAir + OpenWeather integration
├── health_sensor_service.dart        # Device health sensor data
├── health_alert_evaluator.dart      # Health status evaluation logic
├── smart_health_data_collector.dart  # Main data collection service
└── pulse_color_manager.dart          # Color priority and transition management

lib/widgets/
└── pulse_background.dart             # Pulse animation widget

```

## Integration with Your Health Screen

To connect with your existing water tracking, modify the `_getWaterIntakeFromHealthScreen()` method in `smart_health_data_collector.dart`:

```dart
Future<double?> _getWaterIntakeFromHealthScreen() async {
  // Replace this with your actual health screen water tracking
  // Return water intake in milliliters
  return YourHealthScreen.getCurrentWaterIntake();
}
```

## Next Steps

1. Add API keys and test basic functionality
2. Integrate with your existing health screen water tracking
3. Optionally add health sensor support with `health` package
4. Customize colors and thresholds as needed
5. Add additional health metrics based on your app's features

The system is designed to work progressively - it will function with just the API data and gracefully enhance with additional sensor data as available.