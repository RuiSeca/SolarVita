// lib/models/user_context.dart

class UserContext {
  final int preferredWorkoutDuration;
  final int plasticBottlesSaved;
  final int ecoScore;
  final double carbonSaved;
  final double mealCarbonSaved;
  final String suggestedWorkoutTime;

  UserContext({
    this.preferredWorkoutDuration = 30,
    this.plasticBottlesSaved = 0,
    this.ecoScore = 0,
    this.carbonSaved = 0.0,
    this.mealCarbonSaved = 0.0,
    this.suggestedWorkoutTime = '8:00 AM',
  });
}
