// lib/services/ai_service.dart
import '../models/user_context.dart';

class AIService {
  final UserContext context;

  AIService({required this.context});

  String generateResponse(String query) {
    // Default response generation
    if (query.toLowerCase().contains('workout')) {
      return 'Based on your profile, I recommend a ${context.preferredWorkoutDuration}-minute workout today. It would help you maintain your eco-friendly fitness routine!';
    } else if (query.toLowerCase().contains('eco') ||
        query.toLowerCase().contains('environment')) {
      return 'Your fitness activities have helped save ${context.plasticBottlesSaved} plastic bottles and ${context.carbonSaved.toStringAsFixed(1)} kg of carbon so far. Your eco score is ${context.ecoScore}/100!';
    } else if (query.toLowerCase().contains('meal') ||
        query.toLowerCase().contains('food')) {
      return 'Your eco-friendly meal choices have saved ${context.mealCarbonSaved.toStringAsFixed(1)} kg of carbon emissions. Would you like to see some sustainable recipe suggestions?';
    } else if (query.toLowerCase().contains('schedule') ||
        query.toLowerCase().contains('time')) {
      return 'Based on your activity patterns, ${context.suggestedWorkoutTime} might be a good time for your workout today.';
    } else {
      return 'How can I help you with your sustainable fitness journey today?';
    }
  }

  String generateGymResponse(String query) {
    // Enhanced response generation focused on gym and fitness
    final lowerQuery = query.toLowerCase();

    if (lowerQuery.contains('workout plan') || lowerQuery.contains('routine')) {
      return 'Based on your profile, I recommend a ${context.preferredWorkoutDuration}-minute workout focusing on compound movements. Here\'s a simple plan:\n\n'
          '1. Warm-up: 5 minutes of light cardio\n'
          '2. Main workout: 4 sets of squats, bench press, and rows\n'
          '3. Accessory work: 3 sets of core exercises\n'
          '4. Cool down: 5 minutes of stretching\n\n'
          'Would you like me to customize this further?';
    } else if (lowerQuery.contains('protein') ||
        lowerQuery.contains('nutrition')) {
      return 'For optimal muscle recovery, aim for 1.6-2.2g of protein per kg of bodyweight. For someone with your activity level, focusing on whole food protein sources like lean meats, eggs, dairy, and plant-based options like legumes and tofu would be ideal. Would you like me to suggest some high-protein meal ideas?';
    } else if (lowerQuery.contains('lose weight') ||
        lowerQuery.contains('fat loss')) {
      return 'Sustainable fat loss combines proper nutrition, strength training, and cardiovascular exercise. I recommend:\n\n'
          '• A slight caloric deficit (300-500 calories below maintenance)\n'
          '• Strength training 3-4 times per week to preserve muscle\n'
          '• 2-3 cardio sessions (mix of HIIT and steady-state)\n'
          '• Focus on protein intake and whole foods\n\n'
          'Would you like me to help you track your progress in the app?';
    } else if (lowerQuery.contains('muscle') ||
        lowerQuery.contains('gain weight') ||
        lowerQuery.contains('bulk')) {
      return 'For muscle gain, focus on progressive overload in your training and a slight caloric surplus (300-500 calories above maintenance). I recommend:\n\n'
          '• Compound movements like squats, deadlifts, bench press\n'
          '• 3-5 sets of 8-12 reps for hypertrophy\n'
          '• Protein intake of 1.6-2.2g per kg of bodyweight\n'
          '• Sufficient rest between sessions (48-72 hours per muscle group)\n\n'
          'The Exercise History tab can help you track your progressive overload.';
    } else if (lowerQuery.contains('recovery') || lowerQuery.contains('sore')) {
      return 'Effective recovery is crucial for progress. For muscle soreness, consider:\n\n'
          '• Proper hydration and nutrition (focus on protein intake)\n'
          '• Light activity/active recovery on rest days\n'
          '• Quality sleep (7-9 hours)\n'
          '• Mobility work and stretching\n'
          '• Contrast therapy (alternating hot and cold)\n\n'
          'Your body needs time to adapt and grow stronger!';
    } else if (lowerQuery.contains('beginner') ||
        lowerQuery.contains('start')) {
      return 'Welcome to your fitness journey! For beginners, I recommend:\n\n'
          '• Start with full-body workouts 2-3 times per week\n'
          '• Focus on form rather than weight\n'
          '• Include basic movements: squats, push-ups, rows, lunges\n'
          '• Aim for 2-3 sets of 10-15 reps per exercise\n'
          '• Give yourself 48 hours recovery between sessions\n\n'
          'Would you like me to help you set up your first workout in the app?';
    } else if (lowerQuery.contains('cardio') ||
        lowerQuery.contains('running') ||
        lowerQuery.contains('endurance')) {
      return 'For cardiovascular health and endurance, mix different types of cardio:\n\n'
          '• LISS (Low-Intensity Steady State): 30-60 min at comfortable pace, 2-3x/week\n'
          '• HIIT (High-Intensity Interval Training): 15-20 min of work/rest intervals, 1-2x/week\n'
          '• Recreational activities: hiking, swimming, cycling, sports\n\n'
          'This combination provides both heart health benefits and improved conditioning.';
    } else if (lowerQuery.contains('motivation') ||
        lowerQuery.contains('habit')) {
      return 'Building sustainable fitness habits is key to long-term success. Try these strategies:\n\n'
          '• Set specific, measurable goals in the app\n'
          '• Start small and build gradually\n'
          '• Schedule workouts like important meetings\n'
          '• Find a workout buddy or community\n'
          '• Track your progress (the Exercise History tab is perfect for this)\n'
          '• Celebrate small wins along the way\n\n'
          'Remember: consistency beats perfection every time!';
    } else if (lowerQuery.contains('stretch') ||
        lowerQuery.contains('mobility') ||
        lowerQuery.contains('flexible')) {
      return 'Improved mobility and flexibility enhance performance and reduce injury risk. Consider adding:\n\n'
          '• Dynamic stretching before workouts (5-10 minutes)\n'
          '• Static stretching after workouts (hold 30+ seconds)\n'
          '• Dedicated mobility sessions 1-2x/week (15-30 minutes)\n'
          '• Foam rolling for myofascial release\n'
          '• Yoga or targeted mobility exercises for problem areas\n\n'
          'Consistency with mobility work pays dividends over time!';
    } else if (lowerQuery.contains('form') ||
        lowerQuery.contains('technique')) {
      return 'Proper form is crucial for both safety and results. For any exercise:\n\n'
          '• Start with lighter weights to master the movement pattern\n'
          '• Focus on controlled eccentric (lowering) phases\n'
          '• Maintain neutral spine position when appropriate\n'
          '• Consider recording yourself to check form\n'
          '• If unsure, consider working with a professional coach\n\n'
          'Would you like tips on form for any specific exercise?';
    } else {
      return 'How can I help with your fitness goals today? I can provide workout suggestions, nutrition advice, recovery tips, or connect you with other features in the app.';
    }
  }

  String generateQuickResponse(String action) {
    // Default quick responses
    if (action.contains('eco')) {
      return 'Your eco-friendly workouts have saved approximately ${context.plasticBottlesSaved} plastic bottles and reduced carbon emissions by ${context.carbonSaved.toStringAsFixed(1)} kg. Keep up the great work!';
    } else if (action.contains('meal')) {
      return 'I recommend trying our plant-based post-workout recipes. They\'re designed to optimize recovery while having a low environmental impact.';
    } else if (action.contains('schedule')) {
      return 'Based on your activity patterns, ${context.suggestedWorkoutTime} might be the optimal time for your workout today.';
    } else if (action.contains('workout')) {
      return 'For today, I suggest a ${context.preferredWorkoutDuration}-minute eco-friendly workout that includes bodyweight exercises and minimal equipment.';
    } else {
      return 'How can I assist you with your sustainable fitness journey today?';
    }
  }

  String generateWorkoutTips() {
    return 'Here are some workout tips to improve your training:\n\n'
        '• Focus on progressive overload by gradually increasing weight or reps\n'
        '• Maintain proper form throughout each exercise\n'
        '• Include compound movements (squats, deadlifts, bench press) for efficiency\n'
        '• Allow 48-72 hours of recovery for each muscle group\n'
        '• Track your workouts in the Exercise History tab to monitor progress\n'
        '• Mix in different training styles to prevent plateaus\n\n'
        'Would you like specific tips for any particular fitness goal?';
  }

  String generateMealSuggestions() {
    return 'Here are nutritionally balanced meal suggestions to support your fitness goals:\n\n'
        '• Pre-workout: Greek yogurt with berries and a drizzle of honey\n'
        '• Post-workout: Grilled chicken with sweet potato and vegetables\n'
        '• Protein-rich snack: Cottage cheese with sliced almonds\n'
        '• Recovery meal: Salmon with quinoa and steamed broccoli\n'
        '• Plant-based option: Lentil and chickpea bowl with avocado\n\n'
        'These meals provide a good balance of macronutrients to support your training needs.';
  }

  String generateExerciseFormTips() {
    return 'Proper exercise form is crucial for both results and injury prevention. Here are some universal tips:\n\n'
        '• Squat: Keep your chest up, knees tracking over toes\n'
        '• Deadlift: Maintain a neutral spine, push through the floor\n'
        '• Bench Press: Keep shoulders back and down, feet planted firmly\n'
        '• Overhead Press: Engage core, avoid arching your lower back\n'
        '• Row: Pull with your elbows, keep your torso stable\n\n'
        'Would you like specific form tips for another exercise?';
  }
}
