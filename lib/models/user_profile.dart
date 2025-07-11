import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final bool isOnboardingComplete;
  final WorkoutPreferences workoutPreferences;
  final SustainabilityPreferences sustainabilityPreferences;
  final DiaryPreferences diaryPreferences;
  final Map<String, dynamic> additionalData;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.createdAt,
    required this.lastUpdated,
    this.isOnboardingComplete = false,
    required this.workoutPreferences,
    required this.sustainabilityPreferences,
    required this.diaryPreferences,
    this.additionalData = const {},
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      isOnboardingComplete: data['isOnboardingComplete'] ?? false,
      workoutPreferences: WorkoutPreferences.fromMap(data['workoutPreferences'] ?? {}),
      sustainabilityPreferences: SustainabilityPreferences.fromMap(data['sustainabilityPreferences'] ?? {}),
      diaryPreferences: DiaryPreferences.fromMap(data['diaryPreferences'] ?? {}),
      additionalData: Map<String, dynamic>.from(data['additionalData'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'isOnboardingComplete': isOnboardingComplete,
      'workoutPreferences': workoutPreferences.toMap(),
      'sustainabilityPreferences': sustainabilityPreferences.toMap(),
      'diaryPreferences': diaryPreferences.toMap(),
      'additionalData': additionalData,
    };
  }

  UserProfile copyWith({
    String? email,
    String? displayName,
    String? photoURL,
    DateTime? lastUpdated,
    bool? isOnboardingComplete,
    WorkoutPreferences? workoutPreferences,
    SustainabilityPreferences? sustainabilityPreferences,
    DiaryPreferences? diaryPreferences,
    Map<String, dynamic>? additionalData,
  }) {
    return UserProfile(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt,
      lastUpdated: lastUpdated ?? DateTime.now(),
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
      workoutPreferences: workoutPreferences ?? this.workoutPreferences,
      sustainabilityPreferences: sustainabilityPreferences ?? this.sustainabilityPreferences,
      diaryPreferences: diaryPreferences ?? this.diaryPreferences,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}

class WorkoutPreferences {
  final List<String> preferredWorkoutTypes;
  final int workoutFrequencyPerWeek;
  final int sessionDurationMinutes;
  final String fitnessLevel;
  final List<String> fitnessGoals;
  final Map<String, bool> availableDays;
  final String preferredTime;

  WorkoutPreferences({
    this.preferredWorkoutTypes = const [],
    this.workoutFrequencyPerWeek = 3,
    this.sessionDurationMinutes = 30,
    this.fitnessLevel = 'beginner',
    this.fitnessGoals = const [],
    this.availableDays = const {
      'monday': true,
      'tuesday': true,
      'wednesday': true,
      'thursday': true,
      'friday': true,
      'saturday': true,
      'sunday': true,
    },
    this.preferredTime = 'morning',
  });

  factory WorkoutPreferences.fromMap(Map<String, dynamic> map) {
    return WorkoutPreferences(
      preferredWorkoutTypes: List<String>.from(map['preferredWorkoutTypes'] ?? []),
      workoutFrequencyPerWeek: map['workoutFrequencyPerWeek'] ?? 3,
      sessionDurationMinutes: map['sessionDurationMinutes'] ?? 30,
      fitnessLevel: map['fitnessLevel'] ?? 'beginner',
      fitnessGoals: List<String>.from(map['fitnessGoals'] ?? []),
      availableDays: Map<String, bool>.from(map['availableDays'] ?? {
        'monday': true,
        'tuesday': true,
        'wednesday': true,
        'thursday': true,
        'friday': true,
        'saturday': true,
        'sunday': true,
      }),
      preferredTime: map['preferredTime'] ?? 'morning',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'preferredWorkoutTypes': preferredWorkoutTypes,
      'workoutFrequencyPerWeek': workoutFrequencyPerWeek,
      'sessionDurationMinutes': sessionDurationMinutes,
      'fitnessLevel': fitnessLevel,
      'fitnessGoals': fitnessGoals,
      'availableDays': availableDays,
      'preferredTime': preferredTime,
    };
  }

  WorkoutPreferences copyWith({
    List<String>? preferredWorkoutTypes,
    int? workoutFrequencyPerWeek,
    int? sessionDurationMinutes,
    String? fitnessLevel,
    List<String>? fitnessGoals,
    Map<String, bool>? availableDays,
    String? preferredTime,
  }) {
    return WorkoutPreferences(
      preferredWorkoutTypes: preferredWorkoutTypes ?? this.preferredWorkoutTypes,
      workoutFrequencyPerWeek: workoutFrequencyPerWeek ?? this.workoutFrequencyPerWeek,
      sessionDurationMinutes: sessionDurationMinutes ?? this.sessionDurationMinutes,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      fitnessGoals: fitnessGoals ?? this.fitnessGoals,
      availableDays: availableDays ?? this.availableDays,
      preferredTime: preferredTime ?? this.preferredTime,
    );
  }
}

class SustainabilityPreferences {
  final List<String> sustainabilityGoals;
  final String carbonFootprintTarget;
  final bool trackWaterUsage;
  final bool trackEnergyUsage;
  final bool trackWasteReduction;
  final bool trackTransportation;
  final List<String> interestedCategories;
  final bool receiveEcoTips;
  final int ecoTipFrequency;

  SustainabilityPreferences({
    this.sustainabilityGoals = const [],
    this.carbonFootprintTarget = 'moderate',
    this.trackWaterUsage = true,
    this.trackEnergyUsage = true,
    this.trackWasteReduction = true,
    this.trackTransportation = true,
    this.interestedCategories = const [],
    this.receiveEcoTips = true,
    this.ecoTipFrequency = 3,
  });

  factory SustainabilityPreferences.fromMap(Map<String, dynamic> map) {
    return SustainabilityPreferences(
      sustainabilityGoals: List<String>.from(map['sustainabilityGoals'] ?? []),
      carbonFootprintTarget: map['carbonFootprintTarget'] ?? 'moderate',
      trackWaterUsage: map['trackWaterUsage'] ?? true,
      trackEnergyUsage: map['trackEnergyUsage'] ?? true,
      trackWasteReduction: map['trackWasteReduction'] ?? true,
      trackTransportation: map['trackTransportation'] ?? true,
      interestedCategories: List<String>.from(map['interestedCategories'] ?? []),
      receiveEcoTips: map['receiveEcoTips'] ?? true,
      ecoTipFrequency: map['ecoTipFrequency'] ?? 3,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sustainabilityGoals': sustainabilityGoals,
      'carbonFootprintTarget': carbonFootprintTarget,
      'trackWaterUsage': trackWaterUsage,
      'trackEnergyUsage': trackEnergyUsage,
      'trackWasteReduction': trackWasteReduction,
      'trackTransportation': trackTransportation,
      'interestedCategories': interestedCategories,
      'receiveEcoTips': receiveEcoTips,
      'ecoTipFrequency': ecoTipFrequency,
    };
  }

  SustainabilityPreferences copyWith({
    List<String>? sustainabilityGoals,
    String? carbonFootprintTarget,
    bool? trackWaterUsage,
    bool? trackEnergyUsage,
    bool? trackWasteReduction,
    bool? trackTransportation,
    List<String>? interestedCategories,
    bool? receiveEcoTips,
    int? ecoTipFrequency,
  }) {
    return SustainabilityPreferences(
      sustainabilityGoals: sustainabilityGoals ?? this.sustainabilityGoals,
      carbonFootprintTarget: carbonFootprintTarget ?? this.carbonFootprintTarget,
      trackWaterUsage: trackWaterUsage ?? this.trackWaterUsage,
      trackEnergyUsage: trackEnergyUsage ?? this.trackEnergyUsage,
      trackWasteReduction: trackWasteReduction ?? this.trackWasteReduction,
      trackTransportation: trackTransportation ?? this.trackTransportation,
      interestedCategories: interestedCategories ?? this.interestedCategories,
      receiveEcoTips: receiveEcoTips ?? this.receiveEcoTips,
      ecoTipFrequency: ecoTipFrequency ?? this.ecoTipFrequency,
    );
  }
}

class DiaryPreferences {
  final bool enableDailyReminders;
  final String reminderTime;
  final List<String> trackingCategories;
  final bool enableMoodTracking;
  final bool enableGoalTracking;
  final bool enableProgressPhotos;
  final bool privateByDefault;
  final String defaultTemplate;

  DiaryPreferences({
    this.enableDailyReminders = true,
    this.reminderTime = '20:00',
    this.trackingCategories = const ['workout', 'nutrition', 'mood', 'sustainability'],
    this.enableMoodTracking = true,
    this.enableGoalTracking = true,
    this.enableProgressPhotos = false,
    this.privateByDefault = true,
    this.defaultTemplate = 'daily_summary',
  });

  factory DiaryPreferences.fromMap(Map<String, dynamic> map) {
    return DiaryPreferences(
      enableDailyReminders: map['enableDailyReminders'] ?? true,
      reminderTime: map['reminderTime'] ?? '20:00',
      trackingCategories: List<String>.from(map['trackingCategories'] ?? ['workout', 'nutrition', 'mood', 'sustainability']),
      enableMoodTracking: map['enableMoodTracking'] ?? true,
      enableGoalTracking: map['enableGoalTracking'] ?? true,
      enableProgressPhotos: map['enableProgressPhotos'] ?? false,
      privateByDefault: map['privateByDefault'] ?? true,
      defaultTemplate: map['defaultTemplate'] ?? 'daily_summary',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enableDailyReminders': enableDailyReminders,
      'reminderTime': reminderTime,
      'trackingCategories': trackingCategories,
      'enableMoodTracking': enableMoodTracking,
      'enableGoalTracking': enableGoalTracking,
      'enableProgressPhotos': enableProgressPhotos,
      'privateByDefault': privateByDefault,
      'defaultTemplate': defaultTemplate,
    };
  }

  DiaryPreferences copyWith({
    bool? enableDailyReminders,
    String? reminderTime,
    List<String>? trackingCategories,
    bool? enableMoodTracking,
    bool? enableGoalTracking,
    bool? enableProgressPhotos,
    bool? privateByDefault,
    String? defaultTemplate,
  }) {
    return DiaryPreferences(
      enableDailyReminders: enableDailyReminders ?? this.enableDailyReminders,
      reminderTime: reminderTime ?? this.reminderTime,
      trackingCategories: trackingCategories ?? this.trackingCategories,
      enableMoodTracking: enableMoodTracking ?? this.enableMoodTracking,
      enableGoalTracking: enableGoalTracking ?? this.enableGoalTracking,
      enableProgressPhotos: enableProgressPhotos ?? this.enableProgressPhotos,
      privateByDefault: privateByDefault ?? this.privateByDefault,
      defaultTemplate: defaultTemplate ?? this.defaultTemplate,
    );
  }
}