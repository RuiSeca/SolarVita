// lib/services/ai_service.dart
import 'package:flutter_ai_providers/flutter_ai_providers.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import '../models/user_context.dart';

class AIService {
  final UserContext context;
  late final OpenAIProvider? _localAIProvider;
  static const String _localAIBaseUrl = 'http://<YOUR_VM_PUBLIC_IP>:8080';
  static const String _localAIModel = 'phi-2';

  // Fitness coach system prompt
  static const String _fitnessSystemPrompt = '''
You are an expert fitness coach and nutritionist working with a health-focused app. 
The user has these current stats:
- Preferred workout duration: {workoutDuration} minutes
- Eco score: {ecoScore}/100
- Carbon saved: {carbonSaved} kg CO2
- Current suggested workout time: {workoutTime}

Provide personalized, science-based advice on:
- Workout routines and exercise form
- Goal setting and progress tracking  
- Motivation and mindset
- Integration with their eco-friendly lifestyle

Keep responses concise, actionable, and encouraging. Always prioritize safety.
If you need more information to give specific advice, ask relevant questions.
''';

  AIService({required this.context}) {
    _initializeLocalAI();
  }

  void _initializeLocalAI() {
    try {
      _localAIProvider = OpenAIProvider(
        baseUrl: _localAIBaseUrl,
        apiKey: 'not-needed-for-localai', // LocalAI doesn't require API key
      );
    } catch (e) {
      _localAIProvider = null;
    }
  }

  // Enhanced response generation with LocalAI
  Future<String> generateResponseAsync(String userMessage) async {
    // Check if this is a fitness/health related query
    if (_isFitnessRelated(userMessage) && _localAIProvider != null) {
      try {
        return await _generateLocalAIResponse(userMessage);
      } catch (e) {
        // Fall back to your existing logic
        return generateResponse(userMessage);
      }
    }

    // Use your existing logic for non-fitness queries
    return generateResponse(userMessage);
  }

  Future<String> _generateLocalAIResponse(String userMessage) async {
    final systemPrompt = _fitnessSystemPrompt
        .replaceAll(
            '{workoutDuration}', context.preferredWorkoutDuration.toString())
        .replaceAll('{ecoScore}', context.ecoScore.toString())
        .replaceAll('{carbonSaved}', context.carbonSaved.toString())
        .replaceAll('{workoutTime}', context.suggestedWorkoutTime);

    final response = await _localAIProvider!.chatCompletions(
      model: _localAIModel,
      messages: [
        SystemMessage(content: systemPrompt),
        UserMessage(content: userMessage),
      ],
      temperature: 0.7,
      maxTokens: 300,
    );

    return response.choices.first.message.content ??
        'I apologize, but I couldn\'t generate a response right now.';
  }

  // Streaming response for real-time chat
  Stream<String> generateResponseStream(String userMessage) async* {
    if (_isFitnessRelated(userMessage) && _localAIProvider != null) {
      final systemPrompt = _fitnessSystemPrompt
          .replaceAll(
              '{workoutDuration}', context.preferredWorkoutDuration.toString())
          .replaceAll('{ecoScore}', context.ecoScore.toString())
          .replaceAll('{carbonSaved}', context.carbonSaved.toString())
          .replaceAll('{workoutTime}', context.suggestedWorkoutTime);

      final stream = _localAIProvider!.chatCompletionsStream(
        model: _localAIModel,
        messages: [
          SystemMessage(content: systemPrompt),
          UserMessage(content: userMessage),
        ],
        temperature: 0.7,
        maxTokens: 300,
      );

      await for (final chunk in stream) {
        if (chunk.choices.isNotEmpty) {
          final content = chunk.choices.first.delta.content;
          if (content != null) {
            yield content;
          }
        }
      }
      return;
    }

    // Fallback: yield the complete response at once
    yield generateResponse(userMessage);
  }

  bool _isFitnessRelated(String message) {
    final fitnessKeywords = [
      'workout',
      'exercise',
      'fitness',
      'training',
      'muscle',
      'strength',
      'cardio',
      'running',
      'weight',
      'gym',
      'health',
      'nutrition',
      'diet',
      'protein',
      'calories',
      'fat',
      'carbs',
      'goal',
      'motivation',
      'recovery',
      'rest',
      'sleep',
      'hydration',
      'supplements',
      'form',
      'technique',
      'injury',
      'pain',
      'stretch',
      'flexibility'
    ];

    final lowerMessage = message.toLowerCase();
    return fitnessKeywords.any((keyword) => lowerMessage.contains(keyword));
  }

  // Keep your existing methods for backward compatibility
  String generateResponse(String message) {
    // Your existing implementation
    message = message.toLowerCase();

    if (message.contains('workout') || message.contains('exercise')) {
      return _generateWorkoutResponse(message);
    } else if (message.contains('nutrition') || message.contains('diet')) {
      return _generateNutritionResponse(message);
    } else if (message.contains('eco') || message.contains('environment')) {
      return _generateEcoResponse();
    } else if (message.contains('schedule') || message.contains('time')) {
      return _generateScheduleResponse();
    } else {
      return _generateGenericResponse();
    }
  }

  String generateQuickResponse(String action) {
    // Your existing quick response logic
    if (action.contains('workout')) {
      return "Here's a quick ${context.preferredWorkoutDuration}-minute workout for you!\n\n"
          "🏃‍♂️ 5 min warm-up\n"
          "💪 ${context.preferredWorkoutDuration - 10} min strength training\n"
          "🧘‍♀️ 5 min cool-down\n\n"
          "Suggested time: ${context.suggestedWorkoutTime}";
    } else if (action.contains('eco')) {
      return "🌱 Your eco impact today:\n\n"
          "♻️ ${context.plasticBottlesSaved} plastic bottles saved\n"
          "🌍 ${context.carbonSaved} kg CO₂ reduced\n"
          "🥗 ${context.mealCarbonSaved} kg from sustainable meals\n\n"
          "Eco Score: ${context.ecoScore}/100";
    } else if (action.contains('meal')) {
      return "🍽️ Today's meal suggestions:\n\n"
          "🥗 Breakfast: Green smoothie bowl\n"
          "🥙 Lunch: Quinoa Buddha bowl\n"
          "🍲 Dinner: Lentil curry with rice\n\n"
          "All meals are optimized for your fitness goals!";
    } else if (action.contains('schedule')) {
      return "📅 Your fitness schedule:\n\n"
          "🌅 ${context.suggestedWorkoutTime}: Morning workout\n"
          "🥗 12:00 PM: Healthy lunch\n"
          "🚶‍♂️ 6:00 PM: Evening walk\n"
          "😴 10:00 PM: Wind down routine";
    }

    return "I'm here to help with your fitness and wellness journey! What would you like to know?";
  }

  // Your existing private methods remain the same
  String _generateWorkoutResponse(String message) {
    // Your existing implementation
    return "Let's get moving! Based on your preferences, here's what I recommend...";
  }

  String _generateNutritionResponse(String message) {
    // Your existing implementation
    return "Nutrition is key to reaching your goals! Here are some tips...";
  }

  String _generateEcoResponse() {
    // Your existing implementation
    return "Great question about sustainability! Your current eco score is ${context.ecoScore}/100...";
  }

  String _generateScheduleResponse() {
    // Your existing implementation
    return "Your suggested workout time is ${context.suggestedWorkoutTime}...";
  }

  String _generateGenericResponse() {
    // Your existing implementation
    return "I'm here to help you with fitness, nutrition, and sustainable living!";
  }
}
