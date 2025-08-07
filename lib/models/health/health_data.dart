// Custom health permission status to match service API expectations
class SolarVitaHealthPermissionStatus {
  final bool _isGranted;
  final String? errorMessage;
  final bool? isHealthAppInstalled;
  final List<String>? grantedPermissions;

  const SolarVitaHealthPermissionStatus._internal(
    this._isGranted, {
    this.errorMessage,
    this.isHealthAppInstalled,
    this.grantedPermissions,
  });

  // Factory constructors to match service API
  static SolarVitaHealthPermissionStatus granted({
    bool? isHealthAppInstalled,
    List<String>? grantedPermissions,
  }) {
    return SolarVitaHealthPermissionStatus._internal(
      true,
      isHealthAppInstalled: isHealthAppInstalled,
      grantedPermissions: grantedPermissions,
    );
  }
  
  static SolarVitaHealthPermissionStatus denied({String? errorMessage}) {
    return SolarVitaHealthPermissionStatus._internal(false, errorMessage: errorMessage);
  }
  
  static const SolarVitaHealthPermissionStatus notDetermined = SolarVitaHealthPermissionStatus._internal(false);

  // Getter to check if permissions are granted
  bool get isGranted => _isGranted;

  @override
  String toString() => _isGranted ? 'granted' : 'denied${errorMessage != null ? ': $errorMessage' : ''}';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SolarVitaHealthPermissionStatus &&
          runtimeType == other.runtimeType &&
          _isGranted == other._isGranted;

  @override
  int get hashCode => _isGranted.hashCode;
}

// Alias for backward compatibility
typedef HealthPermissionStatus = SolarVitaHealthPermissionStatus;

class HealthData {
  final int steps;
  final int activeMinutes;
  final int caloriesBurned; // Changed to int to match existing code expectations
  final double waterIntake;
  final double sleepHours;
  final double? carbonSaved;
  final double heartRate;
  final DateTime lastUpdated; // Changed to non-null to match existing usage
  final bool isDataAvailable;

  const HealthData({
    required this.steps,
    required this.activeMinutes,
    required this.caloriesBurned,
    required this.waterIntake,
    required this.sleepHours,
    this.carbonSaved,
    this.heartRate = 0.0,
    required this.lastUpdated,
    this.isDataAvailable = false,
  });

  HealthData copyWith({
    int? steps,
    int? activeMinutes,
    int? caloriesBurned, // Changed to int
    double? waterIntake,
    double? sleepHours,
    double? carbonSaved,
    double? heartRate,
    DateTime? lastUpdated,
    bool? isDataAvailable,
  }) {
    return HealthData(
      steps: steps ?? this.steps,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      waterIntake: waterIntake ?? this.waterIntake,
      sleepHours: sleepHours ?? this.sleepHours,
      carbonSaved: carbonSaved ?? this.carbonSaved,
      heartRate: heartRate ?? this.heartRate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isDataAvailable: isDataAvailable ?? this.isDataAvailable,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'steps': steps,
      'activeMinutes': activeMinutes,
      'caloriesBurned': caloriesBurned,
      'waterIntake': waterIntake,
      'sleepHours': sleepHours,
      'carbonSaved': carbonSaved,
      'heartRate': heartRate,
      'lastUpdated': lastUpdated.toIso8601String(), // Removed null safety operator
      'isDataAvailable': isDataAvailable,
    };
  }

  factory HealthData.fromJson(Map<String, dynamic> json) {
    return HealthData(
      steps: json['steps'] as int? ?? 0,
      activeMinutes: json['activeMinutes'] as int? ?? 0,
      caloriesBurned: (json['caloriesBurned'] as num?)?.toInt() ?? 0, // Changed to int
      waterIntake: (json['waterIntake'] as num?)?.toDouble() ?? 0.0,
      sleepHours: (json['sleepHours'] as num?)?.toDouble() ?? 0.0,
      carbonSaved: (json['carbonSaved'] as num?)?.toDouble(),
      heartRate: (json['heartRate'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.tryParse(json['lastUpdated'] as String) ?? DateTime.now()
          : DateTime.now(), // Always provide non-null DateTime
      isDataAvailable: json['isDataAvailable'] as bool? ?? false,
    );
  }

  // Static factory method for empty/default health data
  factory HealthData.empty() {
    return HealthData(
      steps: 0,
      activeMinutes: 0,
      caloriesBurned: 0, // Changed to int
      waterIntake: 0.0,
      sleepHours: 0.0,
      heartRate: 0.0,
      lastUpdated: DateTime.now(), // Provide current time as default
      isDataAvailable: false,
    );
  }

  // Helper getter for backward compatibility (no longer needed but keeping for safety)
  DateTime get lastUpdatedSafe => lastUpdated;
  DateTime get lastUpdatedOrNow => lastUpdated;
  DateTime get safeLastUpdated => lastUpdated;

  @override
  String toString() {
    return 'HealthData(steps: $steps, activeMinutes: $activeMinutes, caloriesBurned: $caloriesBurned, waterIntake: $waterIntake, sleepHours: $sleepHours, heartRate: $heartRate, isDataAvailable: $isDataAvailable, carbonSaved: $carbonSaved)';
  }
}

// Extension to handle common UI patterns
extension HealthDataExtensions on HealthData {
  // Common patterns for DateTime handling
  String get lastUpdatedFormatted {
    return '${lastUpdated.day}/${lastUpdated.month}/${lastUpdated.year} ${lastUpdated.hour}:${lastUpdated.minute.toString().padLeft(2, '0')}';
  }
  
  bool get hasValidLastUpdated => true; // Always true since lastUpdated is non-null
  
  // Time ago helper
  String get timeAgo {
    final diff = DateTime.now().difference(lastUpdated);
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} minutes ago';
    return 'Just now';
  }
}