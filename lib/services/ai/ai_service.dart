// lib/services/ai_service.dart
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../models/user/user_context.dart';
import '../../config/gemini_api_config.dart';
import 'ai_security_service.dart';

class AIService {
  final UserContext context;
  late final GenerativeModel? _fastModel;
  late final GenerativeModel? _standardModel;
  bool _useGemini = true;
  
  // Security service for dissertation implementation
  final AISecurityService _securityService = AISecurityService();

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

  // Session tracking
  String? _currentSessionId;

  // Fitness coach system prompt with your new personality
  static const String _fitnessSystemPrompt = '''
You're SolarVita's fun, down-to-earth fitness coach — think: gym bro/gal with a brain, heart, and an eco-friendly water bottle. You're here to help{userName} get fit, stay healthy, and save the planet a bit while they're at it.

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
    // Simple, consistent system prompt - no introduction logic
    String conversationContext = '''
CONVERSATION STATUS: You are their SolarVita fitness coach.
- Be helpful, friendly, and direct
- Jump straight into answering their question or providing advice
- Keep responses concise and actionable
- Reference conversation history when relevant
- No need for greetings or introductions
- Focus on being genuinely helpful
''';

    // Personalize with user's name if available
    final userName = context.displayName != null 
        ? ' ${context.displayName}' 
        : '';

    // Fixed: Removed the ?. operator since mealCarbonSaved is not nullable
    return _fitnessSystemPrompt
        .replaceAll('{userName}', userName)
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
      // SECURITY LAYER: Validate input for prompt injection and malicious content
      final securityValidation = await _securityService.validateInput(userMessage);
      if (!securityValidation.isValid) {
        // Return security-friendly message without revealing detection details
        return "I want to keep our conversation focused on health and fitness topics that I can safely help with. Let's talk about your wellness goals instead! 💪";
      }

      // Use sanitized input for processing
      final sanitizedInput = securityValidation.sanitizedInput ?? userMessage;

      // Check rate limits first
      if (!await _checkRateLimit()) {
        return _getRateLimitMessage();
      }

      // Check cache for recent similar queries
      final cachedResponse = _getCachedResponse(sanitizedInput);
      if (cachedResponse != null) {
        return cachedResponse;
      }

      // Add to conversation history (use original message for history)
      _addToHistory(userMessage, isUser: true);

      // Build contextual prompt with conversation history (use sanitized input)
      final contextualPrompt = _buildContextualPrompt(sanitizedInput);

      // Select appropriate model based on query complexity
      final model = _selectModel(sanitizedInput);

      if (model == null) {
        return _getContextAwareFallback(sanitizedInput);
      }

      // Generate response with timeout
      final response = await _generateWithTimeout(model, contextualPrompt);

      if (response.isEmpty) {
        return _getContextAwareFallback(sanitizedInput);
      }

      // SECURITY LAYER: Filter response for medical content and safety
      final responseFilter = await _securityService.filterResponse(response, userMessage);
      
      final finalResponse = responseFilter.isBlocked 
          ? "I can't provide that type of health information, but I'm here to help with your fitness and wellness journey in other ways! What would you like to know about exercise or healthy living? 🌟"
          : (responseFilter.filteredResponse ?? response);

      // Cache the original response (before filtering)
      _cacheResponse(sanitizedInput, response);

      // Add filtered response to conversation history
      _addToHistory(finalResponse, isUser: false);

      // No introduction tracking needed

      // Track request for rate limiting
      _trackRequest();

      return finalResponse;
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

        // No introduction tracking needed

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

  // Simple fallback without introductions or eco mentions
  String _getContextAwareFallback(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();

    // Analyze the message for specific topics
    if (lowerMessage.contains('workout') || lowerMessage.contains('exercise')) {
      return "I'm having a technical issue right now, but I'm still here to help with your workout! "
          "Can you tell me more about what kind of workout you're looking for? "
          "Home workout, gym routine, or something specific?";
    }

    if (lowerMessage.contains('nutrition') ||
        lowerMessage.contains('meal') ||
        lowerMessage.contains('food')) {
      return "My nutrition knowledge is having a brief hiccup, but I'd still love to help! "
          "What kind of nutrition question do you have? Meal planning, healthy recipes, or dietary advice?";
    }

    if (lowerMessage.contains('eco') || lowerMessage.contains('environment')) {
      return "I'm having some technical difficulties, but I can still help with sustainability topics! "
          "What eco-friendly aspect would you like to discuss?";
    }

    // General casual fallback
    return "I'm experiencing a technical issue at the moment, but I'm still here to help! "
        "Could you rephrase your question or let me know what specific topic you'd like assistance with?";
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
    _conversationHistory.clear();
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
  }

  void endConversation() {
    _conversationHistory.clear();
  }

  // Conversation history management for UI controls
  void clearConversationHistory() {
    _conversationHistory.clear();
    debugPrint('🔄 Conversation history cleared');
  }

  List<ConversationTurn> getConversationHistory() {
    return List.from(_conversationHistory);
  }

  int getConversationLength() {
    return _conversationHistory.length;
  }

  bool hasActiveConversation() {
    return _conversationHistory.isNotEmpty;
  }

  String getConversationSummary() {
    if (_conversationHistory.isEmpty) {
      return 'No active conversation';
    }
    return '${_conversationHistory.length} messages exchanged';
  }

  // Introduction state management removed

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
  }

  // Get usage statistics
  Map<String, dynamic> getUsageStats() {
    return {
      'daily_requests': _dailyRequestCount,
      'daily_limit': _maxRequestsPerDay,
      'requests_remaining': _maxRequestsPerDay - _dailyRequestCount,
      'cache_size': _responseCache.length,
      'conversation_length': _conversationHistory.length,
      'session_id': _currentSessionId,
    };
  }

  // Get conversation state
  Map<String, dynamic> getConversationState() {
    return {
      'message_count': _conversationHistory.length,
      'session_id': _currentSessionId,
      'last_message_time': _conversationHistory.isNotEmpty
          ? _conversationHistory.first.timestamp.toIso8601String()
          : null,
    };
  }

  // Get security metrics for dissertation analysis
  Future<SecurityMetrics> getSecurityMetrics() async {
    return await _securityService.getSecurityMetrics();
  }

  // Reset security metrics for testing
  Future<void> resetSecurityMetrics() async {
    await _securityService.resetMetrics();
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
