import 'package:flutter/material.dart';
import '../components/animated_waves.dart';

enum OnboardingState {
  splash,
  introGateway,
  introConnection,
  introCallToAction,
  personalIntent,
  identitySetup,
  baselineSetup,
  commitment,
  login,
  dashboard,
}

enum IntentType {
  eco,
  fitness,
  nutrition,
  community,
  mindfulness,
  adventure,
}

enum FitnessLevel {
  beginner,
  intermediate,
  advanced,
}

enum EcoHabit {
  publicTransport,
  cycling,
  vegetarian,
  recycling,
  renewableEnergy,
  minimalism,
}

enum DietaryPreference {
  vegetarian,
  vegan,
  glutenFree,
  dairyFree,
  keto,
  paleo,
  mediterranean,
  noRestrictions,
}

class IntentOption {
  final IntentType type;
  final IconData icon;
  final String label;
  final String description;
  final WavePersonality wavePersonality;
  final Color color;

  IntentOption({
    required this.type,
    required this.icon,
    required this.label,
    required this.description,
    required this.wavePersonality,
    Color? color,
  }) : color = color ?? _getDefaultColor(type);

  static Color _getDefaultColor(IntentType type) {
    switch (type) {
      case IntentType.eco:
        return const Color(0xFF10B981);
      case IntentType.fitness:
        return const Color(0xFF3B82F6);
      case IntentType.nutrition:
        return const Color(0xFF14B8A6);
      case IntentType.community:
        return const Color(0xFFEC4899);
      case IntentType.mindfulness:
        return const Color(0xFF8B5CF6);
      case IntentType.adventure:
        return const Color(0xFFF59E0B);
    }
  }
}

class UserProfile {
  final String name;
  final String? preferredName;
  final String? pronouns;
  final String email;
  final String password;
  final String? location;
  final String? profileImagePath;
  final int age;
  final FitnessLevel fitnessLevel;
  final Set<IntentType> selectedIntents;
  final Set<EcoHabit> currentEcoHabits;
  final Set<DietaryPreference> dietaryPreferences;
  final TimeOfDay? preferredWorkoutTime;

  UserProfile({
    required this.name,
    this.preferredName,
    this.pronouns,
    required this.email,
    required this.password,
    this.location,
    this.profileImagePath,
    this.age = 25,
    this.fitnessLevel = FitnessLevel.intermediate,
    this.selectedIntents = const {},
    this.currentEcoHabits = const {},
    this.dietaryPreferences = const {},
    this.preferredWorkoutTime,
  });

  UserProfile copyWith({
    String? name,
    String? preferredName,
    String? pronouns,
    String? email,
    String? password,
    String? location,
    String? profileImagePath,
    int? age,
    FitnessLevel? fitnessLevel,
    Set<IntentType>? selectedIntents,
    Set<EcoHabit>? currentEcoHabits,
    Set<DietaryPreference>? dietaryPreferences,
    TimeOfDay? preferredWorkoutTime,
  }) {
    return UserProfile(
      name: name ?? this.name,
      preferredName: preferredName ?? this.preferredName,
      pronouns: pronouns ?? this.pronouns,
      email: email ?? this.email,
      password: password ?? this.password,
      location: location ?? this.location,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      age: age ?? this.age,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      selectedIntents: selectedIntents ?? this.selectedIntents,
      currentEcoHabits: currentEcoHabits ?? this.currentEcoHabits,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      preferredWorkoutTime: preferredWorkoutTime ?? this.preferredWorkoutTime,
    );
  }

  String get displayName => preferredName ?? name;
  
  WavePersonality get dominantWavePersonality {
    if (selectedIntents.isEmpty) return WavePersonality.eco;
    
    final intentMap = {
      IntentType.eco: WavePersonality.eco,
      IntentType.fitness: WavePersonality.fitness,
      IntentType.nutrition: WavePersonality.wellness,
      IntentType.community: WavePersonality.community,
      IntentType.mindfulness: WavePersonality.mindfulness,
      IntentType.adventure: WavePersonality.adventure,
    };
    
    return intentMap[selectedIntents.first] ?? WavePersonality.eco;
  }
}