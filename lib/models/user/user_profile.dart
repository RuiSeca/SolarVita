import 'package:cloud_firestore/cloud_firestore.dart';
import '../../screens/onboarding/models/onboarding_models.dart' show IntentType;

class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String? username;
  final String? photoURL;
  final String? bio;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final DateTime? lastActive;
  final bool isOnboardingComplete;
  final bool isPublic;
  final bool isVerified;
  final WorkoutPreferences workoutPreferences;
  final SustainabilityPreferences sustainabilityPreferences;
  final DiaryPreferences diaryPreferences;
  final DietaryPreferences dietaryPreferences;
  final int supportersCount;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final List<String> interests;
  final Set<IntentType> selectedIntents;
  final String? gender;
  final int? age;
  final Map<String, dynamic> additionalData;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.username,
    this.photoURL,
    this.bio,
    required this.createdAt,
    required this.lastUpdated,
    this.lastActive,
    this.isOnboardingComplete = false,
    this.isPublic = true,
    this.isVerified = false,
    required this.workoutPreferences,
    required this.sustainabilityPreferences,
    required this.diaryPreferences,
    required this.dietaryPreferences,
    this.supportersCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.interests = const [],
    this.selectedIntents = const {},
    this.gender,
    this.age,
    this.additionalData = const {},
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      username: data['username'],
      photoURL: data['photoURL'],
      bio: data['bio'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive: data['lastActive'] != null ? (data['lastActive'] as Timestamp?)?.toDate() : null,
      isOnboardingComplete: data['isOnboardingComplete'] ?? false,
      isPublic: data['isPublic'] ?? true,
      isVerified: data['isVerified'] ?? false,
      workoutPreferences: WorkoutPreferences.fromMap(data['workoutPreferences'] ?? {}),
      sustainabilityPreferences: SustainabilityPreferences.fromMap(data['sustainabilityPreferences'] ?? {}),
      diaryPreferences: DiaryPreferences.fromMap(data['diaryPreferences'] ?? {}),
      dietaryPreferences: DietaryPreferences.fromMap(data['dietaryPreferences'] ?? {}),
      supportersCount: data['supportersCount'] ?? 0,
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      postsCount: data['postsCount'] ?? 0,
      interests: List<String>.from(data['interests'] ?? []),
      selectedIntents: (data['selectedIntents'] as List<dynamic>?)
          ?.map((e) => IntentType.values.firstWhere((v) => v.name == e.toString()))
          .toSet() ?? {},
      gender: data['gender'],
      age: data['age'],
      additionalData: Map<String, dynamic>.from(data['additionalData'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'username': username,
      'photoURL': photoURL,
      'bio': bio,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
      'isOnboardingComplete': isOnboardingComplete,
      'isPublic': isPublic,
      'isVerified': isVerified,
      'workoutPreferences': workoutPreferences.toMap(),
      'sustainabilityPreferences': sustainabilityPreferences.toMap(),
      'diaryPreferences': diaryPreferences.toMap(),
      'dietaryPreferences': dietaryPreferences.toMap(),
      'supportersCount': supportersCount,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'interests': interests,
      'selectedIntents': selectedIntents.map((e) => e.name).toList(),
      'gender': gender,
      'age': age,
      'additionalData': additionalData,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'username': username,
      'photoURL': photoURL,
      'bio': bio,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'lastActive': lastActive?.toIso8601String(),
      'isOnboardingComplete': isOnboardingComplete,
      'isPublic': isPublic,
      'isVerified': isVerified,
      'workoutPreferences': workoutPreferences.toMap(),
      'sustainabilityPreferences': sustainabilityPreferences.toMap(),
      'diaryPreferences': diaryPreferences.toMap(),
      'dietaryPreferences': dietaryPreferences.toMap(),
      'supportersCount': supportersCount,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'interests': interests,
      'selectedIntents': selectedIntents.map((e) => e.name).toList(),
      'gender': gender,
      'age': age,
      'additionalData': additionalData,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      username: map['username'],
      photoURL: map['photoURL'],
      bio: map['bio'],
      createdAt: map['createdAt'] is String 
          ? DateTime.parse(map['createdAt'])
          : (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdated: map['lastUpdated'] is String 
          ? DateTime.parse(map['lastUpdated'])
          : (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive: map['lastActive'] != null 
          ? (map['lastActive'] is String 
              ? DateTime.parse(map['lastActive'])
              : (map['lastActive'] as Timestamp?)?.toDate())
          : null,
      isOnboardingComplete: map['isOnboardingComplete'] ?? false,
      isPublic: map['isPublic'] ?? true,
      isVerified: map['isVerified'] ?? false,
      workoutPreferences: WorkoutPreferences.fromMap(map['workoutPreferences'] ?? {}),
      sustainabilityPreferences: SustainabilityPreferences.fromMap(map['sustainabilityPreferences'] ?? {}),
      diaryPreferences: DiaryPreferences.fromMap(map['diaryPreferences'] ?? {}),
      dietaryPreferences: DietaryPreferences.fromMap(map['dietaryPreferences'] ?? {}),
      supportersCount: map['supportersCount'] ?? 0,
      followersCount: map['followersCount'] ?? 0,
      followingCount: map['followingCount'] ?? 0,
      postsCount: map['postsCount'] ?? 0,
      interests: List<String>.from(map['interests'] ?? []),
      selectedIntents: (map['selectedIntents'] as List<dynamic>?)
          ?.map((e) => IntentType.values.firstWhere((v) => v.name == e.toString()))
          .toSet() ?? {},
      gender: map['gender'],
      age: map['age'],
      additionalData: Map<String, dynamic>.from(map['additionalData'] ?? {}),
    );
  }

  UserProfile copyWith({
    String? email,
    String? displayName,
    String? username,
    String? photoURL,
    String? bio,
    DateTime? lastUpdated,
    DateTime? lastActive,
    bool? isOnboardingComplete,
    bool? isPublic,
    bool? isVerified,
    WorkoutPreferences? workoutPreferences,
    SustainabilityPreferences? sustainabilityPreferences,
    DiaryPreferences? diaryPreferences,
    DietaryPreferences? dietaryPreferences,
    int? supportersCount,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    List<String>? interests,
    Set<IntentType>? selectedIntents,
    String? gender,
    int? age,
    Map<String, dynamic>? additionalData,
  }) {
    return UserProfile(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      photoURL: photoURL ?? this.photoURL,
      bio: bio ?? this.bio,
      createdAt: createdAt,
      lastUpdated: lastUpdated ?? DateTime.now(),
      lastActive: lastActive ?? this.lastActive,
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
      isPublic: isPublic ?? this.isPublic,
      isVerified: isVerified ?? this.isVerified,
      workoutPreferences: workoutPreferences ?? this.workoutPreferences,
      sustainabilityPreferences: sustainabilityPreferences ?? this.sustainabilityPreferences,
      diaryPreferences: diaryPreferences ?? this.diaryPreferences,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      supportersCount: supportersCount ?? this.supportersCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      interests: interests ?? this.interests,
      selectedIntents: selectedIntents ?? this.selectedIntents,
      gender: gender ?? this.gender,
      age: age ?? this.age,
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
  final List<String> ecoFriendlyActivities;
  final String preferredTransportMode;

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
    this.ecoFriendlyActivities = const [],
    this.preferredTransportMode = 'walking',
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
      ecoFriendlyActivities: List<String>.from(map['ecoFriendlyActivities'] ?? []),
      preferredTransportMode: map['preferredTransportMode'] ?? 'walking',
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
      'ecoFriendlyActivities': ecoFriendlyActivities,
      'preferredTransportMode': preferredTransportMode,
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
    List<String>? ecoFriendlyActivities,
    String? preferredTransportMode,
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
      ecoFriendlyActivities: ecoFriendlyActivities ?? this.ecoFriendlyActivities,
      preferredTransportMode: preferredTransportMode ?? this.preferredTransportMode,
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

class DietaryPreferences {
  final String dietType;
  final List<String> allergies;
  final List<String> restrictions;
  final bool preferOrganic;
  final bool preferLocal;
  final bool preferSeasonal;
  final bool reduceMeatConsumption;
  final bool sustainableSeafood;
  final int dailyCalorieGoal;
  final int proteinPercentage;
  final int carbsPercentage;
  final int fatPercentage;
  final int mealsPerDay;
  final bool enableSnacks;
  final bool intermittentFasting;
  final String breakfastTime;
  final String lunchTime;
  final String dinnerTime;
  final String snackTime;

  DietaryPreferences({
    this.dietType = 'omnivore',
    this.allergies = const [],
    this.restrictions = const [],
    this.preferOrganic = true,
    this.preferLocal = true,
    this.preferSeasonal = true,
    this.reduceMeatConsumption = false,
    this.sustainableSeafood = true,
    this.dailyCalorieGoal = 2000,
    this.proteinPercentage = 20,
    this.carbsPercentage = 50,
    this.fatPercentage = 30,
    this.mealsPerDay = 3,
    this.enableSnacks = true,
    this.intermittentFasting = false,
    this.breakfastTime = '08:00',
    this.lunchTime = '12:30',
    this.dinnerTime = '19:00',
    this.snackTime = '15:30',
  });

  factory DietaryPreferences.fromMap(Map<String, dynamic> map) {
    return DietaryPreferences(
      dietType: map['dietType'] ?? 'omnivore',
      allergies: List<String>.from(map['allergies'] ?? []),
      restrictions: List<String>.from(map['restrictions'] ?? []),
      preferOrganic: map['preferOrganic'] ?? true,
      preferLocal: map['preferLocal'] ?? true,
      preferSeasonal: map['preferSeasonal'] ?? true,
      reduceMeatConsumption: map['reduceMeatConsumption'] ?? false,
      sustainableSeafood: map['sustainableSeafood'] ?? true,
      dailyCalorieGoal: map['dailyCalorieGoal'] ?? 2000,
      proteinPercentage: map['proteinPercentage'] ?? 20,
      carbsPercentage: map['carbsPercentage'] ?? 50,
      fatPercentage: map['fatPercentage'] ?? 30,
      mealsPerDay: map['mealsPerDay'] ?? 3,
      enableSnacks: map['enableSnacks'] ?? true,
      intermittentFasting: map['intermittentFasting'] ?? false,
      breakfastTime: map['breakfastTime'] ?? '08:00',
      lunchTime: map['lunchTime'] ?? '12:30',
      dinnerTime: map['dinnerTime'] ?? '19:00',
      snackTime: map['snackTime'] ?? '15:30',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dietType': dietType,
      'allergies': allergies,
      'restrictions': restrictions,
      'preferOrganic': preferOrganic,
      'preferLocal': preferLocal,
      'preferSeasonal': preferSeasonal,
      'reduceMeatConsumption': reduceMeatConsumption,
      'sustainableSeafood': sustainableSeafood,
      'dailyCalorieGoal': dailyCalorieGoal,
      'proteinPercentage': proteinPercentage,
      'carbsPercentage': carbsPercentage,
      'fatPercentage': fatPercentage,
      'mealsPerDay': mealsPerDay,
      'enableSnacks': enableSnacks,
      'intermittentFasting': intermittentFasting,
      'breakfastTime': breakfastTime,
      'lunchTime': lunchTime,
      'dinnerTime': dinnerTime,
      'snackTime': snackTime,
    };
  }

  DietaryPreferences copyWith({
    String? dietType,
    List<String>? allergies,
    List<String>? restrictions,
    bool? preferOrganic,
    bool? preferLocal,
    bool? preferSeasonal,
    bool? reduceMeatConsumption,
    bool? sustainableSeafood,
    int? dailyCalorieGoal,
    int? proteinPercentage,
    int? carbsPercentage,
    int? fatPercentage,
    int? mealsPerDay,
    bool? enableSnacks,
    bool? intermittentFasting,
    String? breakfastTime,
    String? lunchTime,
    String? dinnerTime,
    String? snackTime,
  }) {
    return DietaryPreferences(
      dietType: dietType ?? this.dietType,
      allergies: allergies ?? this.allergies,
      restrictions: restrictions ?? this.restrictions,
      preferOrganic: preferOrganic ?? this.preferOrganic,
      preferLocal: preferLocal ?? this.preferLocal,
      preferSeasonal: preferSeasonal ?? this.preferSeasonal,
      reduceMeatConsumption: reduceMeatConsumption ?? this.reduceMeatConsumption,
      sustainableSeafood: sustainableSeafood ?? this.sustainableSeafood,
      dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
      proteinPercentage: proteinPercentage ?? this.proteinPercentage,
      carbsPercentage: carbsPercentage ?? this.carbsPercentage,
      fatPercentage: fatPercentage ?? this.fatPercentage,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      enableSnacks: enableSnacks ?? this.enableSnacks,
      intermittentFasting: intermittentFasting ?? this.intermittentFasting,
      breakfastTime: breakfastTime ?? this.breakfastTime,
      lunchTime: lunchTime ?? this.lunchTime,
      dinnerTime: dinnerTime ?? this.dinnerTime,
      snackTime: snackTime ?? this.snackTime,
    );
  }
}