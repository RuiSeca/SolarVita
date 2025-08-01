// lib/services/ai_service.dart
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../models/user/user_context.dart';
import '../../config/gemini_api_config.dart';

class AIService {
  final UserContext context;
  late final GenerativeModel? _fastModel;
  late final GenerativeModel? _standardModel;
  bool _useGemini = true;

  // Rate limiting for free tier
  static const int _maxRequestsPerMinute = 15; // Free tier limit
  static const int _maxRequestsPerDay = 1500; // Free tier daily limit
  static const Duration _rateLimitWindow = Duration(minutes: 1);

  // Request tracking
  final List<DateTime> _requestTimes = [];
  int _dailyRequestCount = 0;
  DateTime? _lastRequestDate;

  // Response caching
  final Map<String, CachedResponse> _responseCache = {};
  static const Duration _cacheExpiry = Duration(hours: 1);
  static const int _maxCacheSize = 100;

  // Conversation context
  final List<ConversationTurn> _conversationHistory = [];
  static const int _maxHistoryLength = 10;

  // Introduction tracking
  bool _hasIntroduced = false;
  String? _currentSessionId;

  // Fitness coach system prompt with your new personality
  static const String _fitnessSystemPrompt = '''
You're SolarVita's fun, down-to-earth fitness coach — think: gym bro/gal with a brain, heart, and an eco-friendly water bottle. You're here to help users get fit, stay healthy, and save the planet a bit while they're at it.

Current user profile:
- Workout duration goal: {workoutDuration} mins
- Eco score: {ecoScore}/100
- Carbon saved: {carbonSaved} kg CO₂
- Meal carbon saved: {mealCarbonSaved} kg CO₂ 
- Suggested workout time: {workoutTime}
- Plastic bottles saved: {plasticBottlesSaved} 💧

You cover everything from:
🏋️ Lifting weights, gym routines, bodyweight workouts, and cardio (yes, even burpees)
🥗 Meal planning, nutrition tips, healthy swaps — not just kale and quinoa, promise
🧠 Mindset tips, motivation boosts, and "get-your-butt-off-the-couch" energy
🛌 Recovery, rest days, soreness, injury prevention
🌱 Eco-friendly fitness tips, low-impact meals, sustainable living
📊 Progress tracking, goal setting, habit building
💬 General chat, life advice, random questions — you're a friend who happens to know fitness

Your vibe? Chill, a little funny, always supportive. Talk like a close friend — casual, relatable, and engaging. Use emojis, real talk, and humor when it fits. Responses should be short and punchy (2–3 paragraphs), always useful, and leave the user feeling hyped or better informed.

If you're missing info to give personalized advice, ask 1–2 quick, friendly questions like: 
"Hey, are we talking gym workouts or home stuff today?" or "You got any equipment handy?"

{conversationContext}

Keep it real, keep it fun, and remember — you're not just a fitness bot, you're their supportive friend who happens to love helping people get stronger! 💪
''';

  AIService({required this.context}) {
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _initializeModels();
    _loadRequestHistory();
  }

  void _initializeModels() {
    if (!GeminiApiConfig.isConfigured()) {
      _useGemini = false;
      return;
    }

    try {
      // Fast model for quick responses
      _fastModel = GenerativeModel(
        model: 'gemini-1.5-flash-8b', // Fastest free model
        apiKey: GeminiApiConfig.apiKey,
        systemInstruction: Content.system(_getPersonalizedSystemPrompt()),
        generationConfig: GenerationConfig(
          temperature: 0.8, // Slightly higher for more personality
          topK: 25,
          topP: 0.85,
          maxOutputTokens: 600, // Bit more room for personality
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
          SafetySetting(
            HarmCategory.sexuallyExplicit,
            HarmBlockThreshold.medium,
          ),
          SafetySetting(
            HarmCategory.dangerousContent,
            HarmBlockThreshold.medium,
          ),
        ],
      );

      // Standard model for complex queries
      _standardModel = GenerativeModel(
        model: 'gemini-1.5-flash', // Standard free model
        apiKey: GeminiApiConfig.apiKey,
        systemInstruction: Content.system(_getPersonalizedSystemPrompt()),
        generationConfig: GenerationConfig(
          temperature: 0.8, // Higher for more personality
          topK: 40,
          topP: 0.9,
          maxOutputTokens: 1200, // More room for detailed responses
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
          SafetySetting(
            HarmCategory.sexuallyExplicit,
            HarmBlockThreshold.medium,
          ),
          SafetySetting(
            HarmCategory.dangerousContent,
            HarmBlockThreshold.medium,
          ),
        ],
      );
    } catch (e) {
      _useGemini = false;
      _fastModel = null;
      _standardModel = null;
    }
  }

  String _getPersonalizedSystemPrompt() {
    String conversationContext;

    if (_conversationHistory.isEmpty) {
      conversationContext =
          '''
CONVERSATION STATUS: This is the start of a new conversation. 
- Give a fun, casual intro as their SolarVita fitness coach
- Mention their awesome eco achievements (${context.ecoScore}/100 eco score, ${context.carbonSaved} kg CO₂ saved)
- Ask what they want to chat about today — fitness, life, or whatever!
- Keep it friendly and welcoming, not robotic
''';
    } else {
      conversationContext = '''
CONVERSATION STATUS: This is a continuing conversation.
- Jump right back into the flow — no need to re-introduce yourself
- Reference what you talked about before when relevant
- Keep the same fun, supportive energy
- Don't repeat info you already shared
''';
    }

    // Fixed: Removed the ?. operator since mealCarbonSaved is not nullable
    return _fitnessSystemPrompt
        .replaceAll(
          '{workoutDuration}',
          context.preferredWorkoutDuration.toString(),
        )
        .replaceAll('{ecoScore}', context.ecoScore.toString())
        .replaceAll('{carbonSaved}', context.carbonSaved.toString())
        .replaceAll('{mealCarbonSaved}', context.mealCarbonSaved.toString())
        .replaceAll('{workoutTime}', context.suggestedWorkoutTime)
        .replaceAll(
          '{plasticBottlesSaved}',
          context.plasticBottlesSaved.toString(),
        )
        .replaceAll('{conversationContext}', conversationContext);
  }

  // Main response generation method
  Future<String> generateResponseAsync(String userMessage) async {
    try {
      // Check rate limits first
      if (!await _checkRateLimit()) {
        return _getRateLimitMessage();
      }

      // Check cache for recent similar queries
      final cachedResponse = _getCachedResponse(userMessage);
      if (cachedResponse != null) {
        return cachedResponse;
      }

      // Add to conversation history
      _addToHistory(userMessage, isUser: true);

      // Build contextual prompt with conversation history
      final contextualPrompt = _buildContextualPrompt(userMessage);

      // Select appropriate model based on query complexity
      final model = _selectModel(userMessage);

      if (model == null) {
        return _getContextAwareFallback(userMessage);
      }

      // Generate response with timeout
      final response = await _generateWithTimeout(model, contextualPrompt);

      if (response.isEmpty) {
        return _getContextAwareFallback(userMessage);
      }

      // Cache the response
      _cacheResponse(userMessage, response);

      // Add to conversation history
      _addToHistory(response, isUser: false);

      // Mark as introduced if this was the first interaction
      if (!_hasIntroduced) {
        _hasIntroduced = true;
      }

      // Track request for rate limiting
      _trackRequest();

      return response;
    } catch (e) {
      return _getContextAwareFallback(userMessage);
    }
  }

  // Streaming response for better UX
  Stream<String> generateResponseStream(String userMessage) async* {
    try {
      if (!await _checkRateLimit()) {
        yield _getRateLimitMessage();
        return;
      }

      _addToHistory(userMessage, isUser: true);
      final contextualPrompt = _buildContextualPrompt(userMessage);
      final model = _selectModel(userMessage);

      if (model == null) {
        yield _getContextAwareFallback(userMessage);
        return;
      }

      final stream = model.generateContentStream([
        Content.text(contextualPrompt),
      ]);
      String fullResponse = '';

      await for (final chunk in stream.timeout(Duration(seconds: 30))) {
        if (chunk.text != null && chunk.text!.isNotEmpty) {
          fullResponse += chunk.text!;
          yield chunk.text!;
        }
      }

      if (fullResponse.isNotEmpty) {
        _cacheResponse(userMessage, fullResponse);
        _addToHistory(fullResponse, isUser: false);

        // Mark as introduced if this was the first interaction
        if (!_hasIntroduced) {
          _hasIntroduced = true;
        }

        _trackRequest();
      }
    } catch (e) {
      yield _getContextAwareFallback(userMessage);
    }
  }

  // Smart model selection based on query complexity
  GenerativeModel? _selectModel(String query) {
    if (!_useGemini || _fastModel == null || _standardModel == null) {
      return null;
    }

    // Use fast model for simple queries and casual chat
    if (query.length < 50 || _isSimpleQuery(query)) {
      return _fastModel;
    }
    // Use standard model for complex queries
    return _standardModel;
  }

  bool _isSimpleQuery(String query) {
    final simplePatterns = [
      'quick',
      'fast',
      'simple',
      'short',
      'brief',
      'yes',
      'no',
      'how much',
      'when',
      'where',
      'thanks',
      'thank you',
      'ok',
      'okay',
      'hi',
      'hello',
      'hey',
      'what\'s up',
      'how are you',
      'good morning',
      'good night',
    ];
    final lowerQuery = query.toLowerCase();
    return simplePatterns.any(
      (pattern) => lowerQuery.contains(pattern.toString()),
    );
  }

  // Build contextual prompt with conversation history
  String _buildContextualPrompt(String userMessage) {
    final StringBuilder prompt = StringBuilder();

    // Add conversation state context
    if (_conversationHistory.isEmpty) {
      prompt.writeln(
        "CONVERSATION STATE: This is the first message in a new conversation.",
      );
    } else {
      prompt.writeln("CONVERSATION STATE: This is a continuing conversation.");
      prompt.writeln("RECENT CONVERSATION:");
      final recentHistory = _conversationHistory
          .take(6)
          .toList(); // Last 3 exchanges
      for (final turn in recentHistory) {
        prompt.writeln("${turn.isUser ? 'User' : 'Coach'}: ${turn.message}");
      }
    }

    prompt.writeln();
    prompt.writeln("CURRENT USER MESSAGE: $userMessage");

    return prompt.toString();
  }

  // Generate response with timeout and retry
  Future<String> _generateWithTimeout(
    GenerativeModel model,
    String prompt,
  ) async {
    try {
      final response = await model
          .generateContent([Content.text(prompt)])
          .timeout(Duration(seconds: 20));

      return response.text?.trim() ?? '';
    } on TimeoutException {
      throw Exception('Response timed out');
    }
  }

  // Context-aware fallback with personality
  String _getContextAwareFallback(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();

    // Check if this is the first interaction
    if (_conversationHistory.isEmpty) {
      return "Hey there! 👋 I'm your SolarVita fitness coach, and I'm having a tiny tech hiccup right now, "
          "but I'm still pumped to help you out! I can see you've got a solid ${context.ecoScore}/100 eco score "
          "and have saved ${context.carbonSaved} kg CO₂ - that's seriously awesome! 🌱 "
          "What's on your mind today? Fitness, food, life stuff, or just want to chat?";
    }

    // Analyze the message for continuing conversations
    if (lowerMessage.contains('workout') || lowerMessage.contains('exercise')) {
      return "💪 Ugh, my brain's buffering right now, but I'm still here for you! "
          "Since you're thinking ${context.preferredWorkoutDuration}-minute workouts, "
          "how about we start with some quick warm-up moves? Give me a sec to get my head straight, "
          "or tell me more about what kind of workout vibe you're feeling!";
    }

    if (lowerMessage.contains('nutrition') ||
        lowerMessage.contains('meal') ||
        lowerMessage.contains('food')) {
      return "🥗 My nutrition brain is being a bit slow today, but hey - you've already saved "
          "${context.plasticBottlesSaved} plastic bottles, so you're clearly making smart choices! "
          "What kind of food situation are we talking about? Meal prep, snack attack, or something else?";
    }

    if (lowerMessage.contains('eco') || lowerMessage.contains('environment')) {
      return "🌱 Love that you're thinking green! My eco-knowledge is taking a breather, "
          "but your ${context.ecoScore}/100 score and ${context.carbonSaved} kg CO₂ saved speaks for itself! "
          "What sustainability stuff is on your mind?";
    }

    // General casual fallback
    return "😅 My brain's having a moment, but I'm still here! "
        "Can you give me a different angle on what you're asking? "
        "I'm ready to get back to helping you crush your goals! 💪";
  }

  // Rate limiting implementation
  Future<bool> _checkRateLimit() async {
    final now = DateTime.now();

    // Check daily limit
    if (_lastRequestDate == null || !_isSameDay(_lastRequestDate!, now)) {
      _dailyRequestCount = 0;
      _lastRequestDate = now;
      await _saveRequestHistory();
    }

    if (_dailyRequestCount >= _maxRequestsPerDay) {
      return false;
    }

    // Check per-minute limit
    final windowStart = now.subtract(_rateLimitWindow);
    _requestTimes.removeWhere((time) => time.isBefore(windowStart));

    if (_requestTimes.length >= _maxRequestsPerMinute) {
      return false;
    }

    return true;
  }

  void _trackRequest() {
    final now = DateTime.now();
    _requestTimes.add(now);
    _dailyRequestCount++;
    _saveRequestHistory();
  }

  String _getRateLimitMessage() {
    if (_dailyRequestCount >= _maxRequestsPerDay) {
      return "🚫 Alright, I've hit my daily chat limit to keep this app free for everyone! "
          "But don't worry - I'll be back tomorrow with fresh energy and terrible gym jokes. "
          "Maybe use this time to actually do those workouts we've been talking about? 😉";
    } else {
      return "⏱️ Taking a quick breather to stay within the free usage limits! "
          "Give me about a minute and I'll be ready to chat again. "
          "Perfect time for some stretches! 🤸‍♀️";
    }
  }

  // Response caching
  String? _getCachedResponse(String query) {
    final key = _getCacheKey(query);
    final cached = _responseCache[key];

    if (cached != null &&
        DateTime.now().difference(cached.timestamp) < _cacheExpiry) {
      return cached.response;
    }

    if (cached != null) {
      _responseCache.remove(key);
    }

    return null;
  }

  void _cacheResponse(String query, String response) {
    if (_responseCache.length >= _maxCacheSize) {
      // Remove oldest entries
      final sortedEntries = _responseCache.entries.toList()
        ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));

      for (int i = 0; i < _maxCacheSize ~/ 4; i++) {
        _responseCache.remove(sortedEntries[i].key);
      }
    }

    final key = _getCacheKey(query);
    _responseCache[key] = CachedResponse(
      response: response,
      timestamp: DateTime.now(),
    );
  }

  String _getCacheKey(String query) {
    return query.toLowerCase().trim();
  }

  // Conversation history management
  void _addToHistory(String message, {required bool isUser}) {
    _conversationHistory.insert(
      0,
      ConversationTurn(
        message: message,
        isUser: isUser,
        timestamp: DateTime.now(),
      ),
    );

    // Keep only recent history
    if (_conversationHistory.length > _maxHistoryLength) {
      _conversationHistory.removeRange(
        _maxHistoryLength,
        _conversationHistory.length,
      );
    }
  }

  // Session management
  void startNewConversation() {
    _hasIntroduced = false;
    _conversationHistory.clear();
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
  }

  void endConversation() {
    _hasIntroduced = false;
    _conversationHistory.clear();
  }

  // Persistence
  Future<void> _loadRequestHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _dailyRequestCount = prefs.getInt('daily_request_count') ?? 0;

      final lastDateString = prefs.getString('last_request_date');
      if (lastDateString != null) {
        _lastRequestDate = DateTime.parse(lastDateString);

        // Reset if it's a new day
        if (!_isSameDay(_lastRequestDate!, DateTime.now())) {
          _dailyRequestCount = 0;
        }
      }
    } catch (e) {
      // Ignore history load errors
    }
  }

  Future<void> _saveRequestHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('daily_request_count', _dailyRequestCount);
      if (_lastRequestDate != null) {
        await prefs.setString(
          'last_request_date',
          _lastRequestDate!.toIso8601String(),
        );
      }
    } catch (e) {
      // Ignore history save errors
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Public methods for backward compatibility
  String generateResponse(String message) {
    // This method should not be used anymore, but kept for compatibility
    return _getContextAwareFallback(message);
  }

  String generateQuickResponse(String action) {
    // This method should not be used anymore, but kept for compatibility
    return _getContextAwareFallback("Quick help with: $action");
  }

  // Test connection
  Future<bool> testConnection() async {
    try {
      if (!await _checkRateLimit()) {
        return false;
      }

      if (_fastModel == null) {
        return false;
      }

      final response = await _generateWithTimeout(
        _fastModel,
        'Hey! Just checking if you\'re working properly as our SolarVita fitness coach!',
      );

      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Utility methods
  void clearCache() {
    _responseCache.clear();
  }

  void clearHistory() {
    _conversationHistory.clear();
    _hasIntroduced = false;
  }

  // Get usage statistics
  Map<String, dynamic> getUsageStats() {
    return {
      'daily_requests': _dailyRequestCount,
      'daily_limit': _maxRequestsPerDay,
      'requests_remaining': _maxRequestsPerDay - _dailyRequestCount,
      'cache_size': _responseCache.length,
      'conversation_length': _conversationHistory.length,
      'has_introduced': _hasIntroduced,
      'session_id': _currentSessionId,
    };
  }

  // Get conversation state
  Map<String, dynamic> getConversationState() {
    return {
      'has_introduced': _hasIntroduced,
      'message_count': _conversationHistory.length,
      'session_id': _currentSessionId,
      'last_message_time': _conversationHistory.isNotEmpty
          ? _conversationHistory.first.timestamp.toIso8601String()
          : null,
    };
  }
}

// Helper classes
class CachedResponse {
  final String response;
  final DateTime timestamp;

  CachedResponse({required this.response, required this.timestamp});
}

class ConversationTurn {
  final String message;
  final bool isUser;
  final DateTime timestamp;

  ConversationTurn({
    required this.message,
    required this.isUser,
    required this.timestamp,
  });
}

class StringBuilder {
  final StringBuffer _buffer = StringBuffer();

  void writeln([Object? obj]) {
    _buffer.writeln(obj);
  }

  @override
  String toString() => _buffer.toString();
}
