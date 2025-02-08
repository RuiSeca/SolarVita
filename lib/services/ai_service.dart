// lib/services/ai_service.dart

import '../models/user_context.dart';

class AIService {
  final UserContext context;

  AIService({required this.context});

  String generateResponse(String text) {
    text = text.toLowerCase();

    if (text.contains('workout') || text.contains('exercise')) {
      return "Based on your eco-fitness goals, I recommend a ${context.preferredWorkoutDuration}-minute bodyweight workout. It's both effective and has zero carbon footprint! Would you like to see the exercises?";
    }

    if (text.contains('eco') || text.contains('environmental')) {
      return "Great question about sustainability! You've saved ${context.plasticBottlesSaved} plastic bottles and your eco-score is ${context.ecoScore}. Want some tips to improve further?";
    }

    if (text.contains('meal') || text.contains('food')) {
      return "I can suggest a sustainable meal plan that's reduced your carbon footprint by ${context.mealCarbonSaved}kg this week. Would you like to see some local, seasonal recipes?";
    }

    if (text.contains('schedule') || text.contains('plan')) {
      return "I've analyzed your patterns and found the optimal time for your eco-friendly workout: ${context.suggestedWorkoutTime}. This aligns with lower energy usage periods!";
    }

    return "I'm here to help with both your fitness journey and environmental impact. What specific aspect would you like to focus on?";
  }

  String generateQuickResponse(String action) {
    switch (action) {
      case 'Workout Plan':
        return generateResponse("Show me today's workout plan");
      case 'Eco Tips':
        return generateResponse(
            "What eco-friendly tips do you have for me today?");
      case 'Meal Ideas':
        return generateResponse("Suggest a sustainable meal for today");
      case 'Schedule':
        return generateResponse("What's the best time for my workout today?");
      default:
        return generateResponse("");
    }
  }
}
