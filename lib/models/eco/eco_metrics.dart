import 'package:cloud_firestore/cloud_firestore.dart';

class EcoMetrics {
  final String userId;
  final double totalCarbonSaved; // Total kg CO2 saved
  final int plasticBottlesSaved; // Equivalent plastic bottles saved
  final double mealCarbonSaved; // Carbon saved from sustainable food choices
  final double transportCarbonSaved; // Carbon saved from sustainable transport
  final double energyCarbonSaved; // Carbon saved from energy conservation
  final double wasteCarbonSaved; // Carbon saved from waste reduction
  final int ecoScore; // Overall eco score (0-100)
  final int currentStreak; // Current daily eco activity streak
  final int longestStreak; // Longest streak achieved
  final DateTime lastUpdated;
  final Map<String, int> activityCounts; // Count of each activity type
  final Map<String, double> monthlySavings; // Monthly carbon savings

  const EcoMetrics({
    required this.userId,
    required this.totalCarbonSaved,
    required this.plasticBottlesSaved,
    required this.mealCarbonSaved,
    required this.transportCarbonSaved,
    required this.energyCarbonSaved,
    required this.wasteCarbonSaved,
    required this.ecoScore,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastUpdated,
    required this.activityCounts,
    required this.monthlySavings,
  });

  // Factory constructor from Firestore
  factory EcoMetrics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EcoMetrics(
      userId: data['userId'] ?? '',
      totalCarbonSaved: (data['totalCarbonSaved'] ?? 0.0).toDouble(),
      plasticBottlesSaved: data['plasticBottlesSaved'] ?? 0,
      mealCarbonSaved: (data['mealCarbonSaved'] ?? 0.0).toDouble(),
      transportCarbonSaved: (data['transportCarbonSaved'] ?? 0.0).toDouble(),
      energyCarbonSaved: (data['energyCarbonSaved'] ?? 0.0).toDouble(),
      wasteCarbonSaved: (data['wasteCarbonSaved'] ?? 0.0).toDouble(),
      ecoScore: data['ecoScore'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      activityCounts: data['activityCounts'] != null
          ? Map<String, int>.from(data['activityCounts'])
          : {},
      monthlySavings: data['monthlySavings'] != null
          ? Map<String, double>.from(data['monthlySavings'])
          : {},
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'totalCarbonSaved': totalCarbonSaved,
      'plasticBottlesSaved': plasticBottlesSaved,
      'mealCarbonSaved': mealCarbonSaved,
      'transportCarbonSaved': transportCarbonSaved,
      'energyCarbonSaved': energyCarbonSaved,
      'wasteCarbonSaved': wasteCarbonSaved,
      'ecoScore': ecoScore,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'activityCounts': activityCounts,
      'monthlySavings': monthlySavings,
    };
  }

  // Create empty metrics for new user
  factory EcoMetrics.empty(String userId) {
    return EcoMetrics(
      userId: userId,
      totalCarbonSaved: 0.0,
      plasticBottlesSaved: 0,
      mealCarbonSaved: 0.0,
      transportCarbonSaved: 0.0,
      energyCarbonSaved: 0.0,
      wasteCarbonSaved: 0.0,
      ecoScore: 0,
      currentStreak: 0,
      longestStreak: 0,
      lastUpdated: DateTime.now(),
      activityCounts: {},
      monthlySavings: {},
    );
  }

  // Calculate plastic bottles equivalent from carbon saved
  static int carbonToBottles(double carbonKg) {
    // 1.5L plastic bottle ≈ 0.2 kg CO2 (manufacturing + transportation + disposal)
    // Based on AI Overview: 3.7 kg CO2 ≈ 18-19 bottles (0.2 kg per bottle)
    return (carbonKg / 0.2).round();
  }

  // Calculate eco score based on total impact
  static int calculateEcoScore(double totalCarbon, int activityCount, int streak) {
    // Base score from carbon saved (up to 60 points)
    final carbonScore = (totalCarbon * 2).clamp(0, 60).toInt();
    
    // Activity diversity bonus (up to 20 points)
    final diversityScore = (activityCount * 2).clamp(0, 20).toInt();
    
    // Streak bonus (up to 20 points)
    final streakScore = (streak).clamp(0, 20).toInt();
    
    return (carbonScore + diversityScore + streakScore).clamp(0, 100);
  }

  // Update metrics with new activity
  EcoMetrics addActivity(String activityType, double carbonSaved) {
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    
    // Update activity counts
    final newActivityCounts = Map<String, int>.from(activityCounts);
    newActivityCounts[activityType] = (newActivityCounts[activityType] ?? 0) + 1;
    
    // Update monthly savings
    final newMonthlySavings = Map<String, double>.from(monthlySavings);
    newMonthlySavings[monthKey] = (newMonthlySavings[monthKey] ?? 0.0) + carbonSaved;
    
    // Calculate new totals
    final newTotalCarbon = totalCarbonSaved + carbonSaved;
    final newPlasticBottles = carbonToBottles(newTotalCarbon);
    
    // Update category-specific savings
    double newMealCarbon = mealCarbonSaved;
    double newTransportCarbon = transportCarbonSaved;
    double newEnergyCarbon = energyCarbonSaved;
    double newWasteCarbon = wasteCarbonSaved;
    
    switch (activityType) {
      case 'food':
        newMealCarbon += carbonSaved;
        break;
      case 'transport':
        newTransportCarbon += carbonSaved;
        break;
      case 'energy':
        newEnergyCarbon += carbonSaved;
        break;
      case 'waste':
        newWasteCarbon += carbonSaved;
        break;
    }
    
    // Calculate streak (simplified - would need more logic for real streak calculation)
    final newStreak = _calculateStreak(now);
    final newLongestStreak = newStreak > longestStreak ? newStreak : longestStreak;
    
    // Calculate new eco score
    final newEcoScore = calculateEcoScore(
      newTotalCarbon, 
      newActivityCounts.length, 
      newStreak,
    );
    
    return EcoMetrics(
      userId: userId,
      totalCarbonSaved: newTotalCarbon,
      plasticBottlesSaved: newPlasticBottles,
      mealCarbonSaved: newMealCarbon,
      transportCarbonSaved: newTransportCarbon,
      energyCarbonSaved: newEnergyCarbon,
      wasteCarbonSaved: newWasteCarbon,
      ecoScore: newEcoScore,
      currentStreak: newStreak,
      longestStreak: newLongestStreak,
      lastUpdated: now,
      activityCounts: newActivityCounts,
      monthlySavings: newMonthlySavings,
    );
  }

  // Helper method to calculate streak (simplified)
  int _calculateStreak(DateTime today) {
    final daysSinceLastUpdate = today.difference(lastUpdated).inDays;
    
    if (daysSinceLastUpdate == 0) {
      // Same day activity
      return currentStreak;
    } else if (daysSinceLastUpdate == 1) {
      // Next day activity - continue streak
      return currentStreak + 1;
    } else {
      // Gap in days - reset streak
      return 1;
    }
  }

  // Copy with method for updates
  EcoMetrics copyWith({
    String? userId,
    double? totalCarbonSaved,
    int? plasticBottlesSaved,
    double? mealCarbonSaved,
    double? transportCarbonSaved,
    double? energyCarbonSaved,
    double? wasteCarbonSaved,
    int? ecoScore,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastUpdated,
    Map<String, int>? activityCounts,
    Map<String, double>? monthlySavings,
  }) {
    return EcoMetrics(
      userId: userId ?? this.userId,
      totalCarbonSaved: totalCarbonSaved ?? this.totalCarbonSaved,
      plasticBottlesSaved: plasticBottlesSaved ?? this.plasticBottlesSaved,
      mealCarbonSaved: mealCarbonSaved ?? this.mealCarbonSaved,
      transportCarbonSaved: transportCarbonSaved ?? this.transportCarbonSaved,
      energyCarbonSaved: energyCarbonSaved ?? this.energyCarbonSaved,
      wasteCarbonSaved: wasteCarbonSaved ?? this.wasteCarbonSaved,
      ecoScore: ecoScore ?? this.ecoScore,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      activityCounts: activityCounts ?? this.activityCounts,
      monthlySavings: monthlySavings ?? this.monthlySavings,
    );
  }
}