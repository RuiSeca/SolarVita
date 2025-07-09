import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/user_context.dart';
import '../config/gemini_api_config.dart';
import 'package:logger/logger.dart';

class AIService {
  final UserContext context;
  late final GenerativeModel _model;
  final Logger _logger = Logger();

  // Fitness coach system prompt
  static const String _fitnessSystemPrompt = '''
You are SolarVita's expert fitness coach and wellness advisor, specializing in sustainable health practices. 

Current user profile:
- Preferred workout duration: {workoutDuration} minutes
- Eco score: {ecoScore}/100
- Carbon saved: {carbonSaved} kg CO₂
- Meal carbon saved: {mealCarbonSaved} kg CO₂ 
- Suggested workout time: {workoutTime}
- Plastic bottles saved: {plasticBottlesSaved}

Your expertise covers:
🏋️ Personalized workout routines and exercise form
🥗 Sustainable nutrition and meal planning
🌱 Eco-friendly fitness practices
📈 Goal setting and progress tracking
💪 Motivation and mindset coaching
🔄 Recovery and injury prevention

Personality: Encouraging, knowledgeable, and sustainability-focused. Keep responses concise (2-3 paragraphs max), actionable, and motivating. Always prioritize safety and sustainable practices.

If you need more specific information to give tailored advice, ask 1-2 relevant questions.
''';

  AIService({required this.context}) {
    _initializeGemini();
  }

  void _initializeGemini() {
    if (!GeminiApiConfig.isConfigured()) {
      _logger.e('Gemini API key not configured');
      throw Exception(
          'Gemini API key not configured. Please set GEMINI_API_KEY in .env file.');
    }

    _model = GenerativeModel(
      model: 'gemini-1.5-flash', // Using the fast, free model
      apiKey: GeminiApiConfig.apiKey,
      systemInstruction: Content.system(_getPersonalizedSystemPrompt()),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1000,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
      ],
    );

    _logger.i('Gemini AI service initialized successfully');
  }

  String _getPersonalizedSystemPrompt() {
    return _fitnessSystemPrompt
        .replaceAll(
            '{workoutDuration}', context.preferredWorkoutDuration.toString())
        .replaceAll('{ecoScore}', context.ecoScore.toString())
        .replaceAll('{carbonSaved}', context.carbonSaved.toString())
        .replaceAll('{mealCarbonSaved}', context.mealCarbonSaved.toString())
        .replaceAll('{workoutTime}', context.suggestedWorkoutTime)
        .replaceAll(
            '{plasticBottlesSaved}', context.plasticBottlesSaved.toString());
  }

  // Enhanced response generation with Gemini
  Future<String> generateResponseAsync(String userMessage) async {
    try {
      _logger.d(
          'Generating Gemini response for: ${userMessage.substring(0, userMessage.length.clamp(0, 50))}...');

      final content = [Content.text(userMessage)];
      final response = await _model.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        _logger.d('Gemini response generated successfully');
        return response.text!;
      } else {
        _logger.w('Gemini returned empty response');
        return _getFallbackResponse(userMessage);
      }
    } catch (e) {
      _logger.e('Error generating Gemini response: $e');

      // Graceful fallback to rule-based responses
      return _getFallbackResponse(userMessage);
    }
  }

  // Streaming response for real-time chat
  Stream<String> generateResponseStream(String userMessage) async* {
    try {
      _logger.d(
          'Starting Gemini stream for: ${userMessage.substring(0, userMessage.length.clamp(0, 50))}...');

      final content = [Content.text(userMessage)];
      final response = _model.generateContentStream(content);

      await for (final chunk in response) {
        if (chunk.text != null && chunk.text!.isNotEmpty) {
          yield chunk.text!;
        }
      }
    } catch (e) {
      _logger.e('Error in Gemini stream: $e');

      // Fallback to complete response
      yield _getFallbackResponse(userMessage);
    }
  }

  // Fallback response when Gemini fails
  String _getFallbackResponse(String message) {
    _logger.i('Using fallback response system');
    return generateResponse(message);
  }

  // Keep your existing methods for backward compatibility and fallback
  String generateResponse(String message) {
    message = message.toLowerCase();

    if (message.contains('workout') || message.contains('exercise')) {
      return _generateWorkoutResponse(message);
    } else if (message.contains('nutrition') ||
        message.contains('diet') ||
        message.contains('meal')) {
      return _generateNutritionResponse(message);
    } else if (message.contains('eco') ||
        message.contains('environment') ||
        message.contains('sustainable')) {
      return _generateEcoResponse();
    } else if (message.contains('schedule') ||
        message.contains('time') ||
        message.contains('when')) {
      return _generateScheduleResponse();
    } else if (message.contains('progress') ||
        message.contains('track') ||
        message.contains('goal')) {
      return _generateProgressResponse();
    } else {
      return _generateGenericResponse();
    }
  }

  String generateQuickResponse(String action) {
    if (action.contains('workout')) {
      return "🏋️ Here's your quick ${context.preferredWorkoutDuration}-minute eco-friendly workout!\n\n"
          "🌱 5 min nature-inspired warm-up\n"
          "💪 ${context.preferredWorkoutDuration - 10} min strength training\n"
          "🧘‍♀️ 5 min mindful cool-down\n\n"
          "💡 Best time: ${context.suggestedWorkoutTime}\n"
          "🌍 This workout saves energy by using minimal equipment!";
    } else if (action.contains('eco')) {
      return "🌱 Your amazing eco-impact today:\n\n"
          "♻️ ${context.plasticBottlesSaved} plastic bottles saved\n"
          "🌍 ${context.carbonSaved} kg CO₂ reduced from activities\n"
          "🥗 ${context.mealCarbonSaved} kg CO₂ saved from sustainable meals\n\n"
          "🏆 Eco Score: ${context.ecoScore}/100\n"
          "Keep up the fantastic work! Every choice matters! 🌟";
    } else if (action.contains('meal')) {
      return "🍽️ Today's sustainable meal suggestions:\n\n"
          "🌅 Breakfast: Plant-powered smoothie bowl\n"
          "🥙 Lunch: Local veggie Buddha bowl\n"
          "🍲 Dinner: Seasonal lentil curry\n"
          "🍎 Snacks: Seasonal fruits & nuts\n\n"
          "🌱 All meals support your fitness goals AND the planet!\n"
          "💚 Carbon saved so far: ${context.mealCarbonSaved} kg CO₂";
    } else if (action.contains('schedule')) {
      return "📅 Your optimal daily routine:\n\n"
          "🌅 ${context.suggestedWorkoutTime}: Energizing workout\n"
          "☀️ 12:00 PM: Sustainable lunch break\n"
          "🚶‍♂️ 6:00 PM: Nature walk or bike ride\n"
          "🌙 10:00 PM: Relaxing wind-down routine\n\n"
          "💡 Tip: Align activities with natural daylight to save energy!";
    }

    return "🌟 I'm your SolarVita wellness coach! I'm here to help you achieve your fitness goals while caring for our planet. What would you like to explore today?";
  }

  // Enhanced private methods with eco-fitness focus
  String _generateWorkoutResponse(String message) {
    return "🏋️ Let's create a workout that's good for you AND the planet!\n\n"
        "Based on your ${context.preferredWorkoutDuration}-minute preference, I recommend mixing bodyweight exercises with minimal equipment. "
        "This saves energy while building strength!\n\n"
        "💡 Try outdoor workouts when possible - fresh air boosts performance and connects you with nature. "
        "Your ideal time is ${context.suggestedWorkoutTime}. Need specific exercises or modifications?";
  }

  String _generateNutritionResponse(String message) {
    return "🥗 Nutrition that fuels you and helps the planet!\n\n"
        "Focus on seasonal, local produce when possible - it's fresher, more nutritious, and reduces your carbon footprint. "
        "You've already saved ${context.mealCarbonSaved} kg CO₂ through smart food choices!\n\n"
        "💚 Plant-based proteins, whole grains, and colorful vegetables will power your workouts naturally. What specific nutrition goals are you working on?";
  }

  String _generateEcoResponse() {
    return "🌍 Your sustainability impact is incredible!\n\n"
        "Current stats: ${context.ecoScore}/100 eco score, ${context.carbonSaved} kg CO₂ saved, and ${context.plasticBottlesSaved} bottles diverted from waste! "
        "Combining fitness with environmental care creates a positive cycle.\n\n"
        "🌱 Small actions like using a reusable water bottle during workouts, choosing active transport, or outdoor exercises all add up to major impact!";
  }

  String _generateScheduleResponse() {
    return "⏰ Your personalized schedule optimization:\n\n"
        "Your suggested workout time of ${context.suggestedWorkoutTime} aligns with your body's natural energy peaks. "
        "Consistency in timing helps build lasting habits!\n\n"
        "🌱 Pro tip: Morning workouts often feel more energizing and leave you accomplished all day. Plus, exercising during peak sunlight hours naturally boosts vitamin D!";
  }

  String _generateProgressResponse() {
    return "📈 Progress tracking with purpose!\n\n"
        "Beyond physical gains, you're building environmental impact: ${context.carbonSaved} kg CO₂ saved shows how fitness and sustainability work together. "
        "Your eco score of ${context.ecoScore}/100 reflects mindful choices.\n\n"
        "💪 Remember: progress isn't just about strength or endurance - it's about creating positive habits that benefit you and the planet long-term!";
  }

  String _generateGenericResponse() {
    return "🌟 Welcome to SolarVita - where fitness meets sustainability!\n\n"
        "I'm here to help you achieve your health goals while caring for our planet. Whether you need workout guidance, nutrition advice, or eco-friendly fitness tips, I've got you covered!\n\n"
        "💚 What aspect of your wellness journey would you like to explore today?";
  }

  // Method to update user context (useful for dynamic updates)
  void updateContext(UserContext newContext) {
    // Note: With Gemini, we'd need to create a new model instance for updated system instructions
    // For now, we'll update the context but use it in future messages
    // context = newContext;
    _logger.i(
        'User context updated - new system prompt will apply to future conversations');
  }

  // Test method to verify Gemini connection
  Future<bool> testConnection() async {
    try {
      final response = await _model.generateContent([
        Content.text(
            'Hello! Can you confirm you\'re working as SolarVita\'s fitness coach?')
      ]);

      return response.text != null && response.text!.isNotEmpty;
    } catch (e) {
      _logger.e('Gemini connection test failed: $e');
      return false;
    }
  }
}
