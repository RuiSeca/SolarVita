class HealthData {
  final int steps;
  final int activeMinutes;
  final int caloriesBurned;
  final double sleepHours;
  final double heartRate;
  final double waterIntake; // in liters, iOS only
  final DateTime lastUpdated;
  final bool isDataAvailable;

  const HealthData({
    required this.steps,
    required this.activeMinutes,
    required this.caloriesBurned,
    required this.sleepHours,
    required this.heartRate,
    required this.waterIntake,
    required this.lastUpdated,
    required this.isDataAvailable,
  });

  // Create mock data for demo purposes
  factory HealthData.mock() {
    return HealthData(
      steps: 2146,
      activeMinutes: 45,
      caloriesBurned: 320,
      sleepHours: 7.2,
      heartRate: 72.0,
      waterIntake: 0.0, // Will be handled separately
      lastUpdated: DateTime.now(),
      isDataAvailable: false,
    );
  }

  // Create empty data
  factory HealthData.empty() {
    return HealthData(
      steps: 0,
      activeMinutes: 0,
      caloriesBurned: 0,
      sleepHours: 0.0,
      heartRate: 0.0,
      waterIntake: 0.0,
      lastUpdated: DateTime.now(),
      isDataAvailable: false,
    );
  }

  HealthData copyWith({
    int? steps,
    int? activeMinutes,
    int? caloriesBurned,
    double? sleepHours,
    double? heartRate,
    double? waterIntake,
    DateTime? lastUpdated,
    bool? isDataAvailable,
  }) {
    return HealthData(
      steps: steps ?? this.steps,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      sleepHours: sleepHours ?? this.sleepHours,
      heartRate: heartRate ?? this.heartRate,
      waterIntake: waterIntake ?? this.waterIntake,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isDataAvailable: isDataAvailable ?? this.isDataAvailable,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'steps': steps,
      'activeMinutes': activeMinutes,
      'caloriesBurned': caloriesBurned,
      'sleepHours': sleepHours,
      'heartRate': heartRate,
      'waterIntake': waterIntake,
      'lastUpdated': lastUpdated.toIso8601String(),
      'isDataAvailable': isDataAvailable,
    };
  }

  factory HealthData.fromJson(Map<String, dynamic> json) {
    return HealthData(
      steps: json['steps'] ?? 0,
      activeMinutes: json['activeMinutes'] ?? 0,
      caloriesBurned: json['caloriesBurned'] ?? 0,
      sleepHours: json['sleepHours']?.toDouble() ?? 0.0,
      heartRate: json['heartRate']?.toDouble() ?? 0.0,
      waterIntake: json['waterIntake']?.toDouble() ?? 0.0,
      lastUpdated: DateTime.parse(json['lastUpdated']),
      isDataAvailable: json['isDataAvailable'] ?? false,
    );
  }
}

class HealthPermissionStatus {
  final bool isGranted;
  final bool isHealthAppInstalled;
  final bool hasRequestedPermissions;
  final List<String> grantedPermissions;
  final List<String> deniedPermissions;
  final String? errorMessage;

  const HealthPermissionStatus({
    required this.isGranted,
    required this.isHealthAppInstalled,
    required this.hasRequestedPermissions,
    required this.grantedPermissions,
    required this.deniedPermissions,
    this.errorMessage,
  });

  factory HealthPermissionStatus.denied({String? errorMessage}) {
    return HealthPermissionStatus(
      isGranted: false,
      isHealthAppInstalled: false,
      hasRequestedPermissions: false,
      grantedPermissions: [],
      deniedPermissions: [],
      errorMessage: errorMessage,
    );
  }

  factory HealthPermissionStatus.granted({
    required bool isHealthAppInstalled,
    required List<String> grantedPermissions,
    List<String> deniedPermissions = const [],
  }) {
    return HealthPermissionStatus(
      isGranted: true,
      isHealthAppInstalled: isHealthAppInstalled,
      hasRequestedPermissions: true,
      grantedPermissions: grantedPermissions,
      deniedPermissions: deniedPermissions,
    );
  }
}