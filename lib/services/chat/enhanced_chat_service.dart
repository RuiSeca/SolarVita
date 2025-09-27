import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/chat/chat_message.dart';
import '../../models/chat/shared_content.dart';
import '../../models/eco/eco_tip.dart';
import '../../utils/logger.dart';

class EnhancedChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // ==================== QUICK SHARING ====================

  /// Share a meal in chat
  Future<bool> shareMeal({
    required String conversationId,
    required String receiverId,
    required String mealId,
    required String mealName,
    required String description,
    required int calories,
    required Map<String, dynamic> nutrients,
    String? imageUrl,
    List<String>? ingredients,
    String? personalNote,
  }) async {
    if (currentUserId == null) return false;

    try {
      final sharedContent = SharedContent.meal(
        mealId: mealId,
        mealName: mealName,
        description: description,
        calories: calories,
        nutrients: nutrients,
        imageUrl: imageUrl,
        ingredients: ingredients,
      );

      final message = ChatMessage(
        messageId: _firestore.collection('temp').doc().id,
        senderId: currentUserId!,
        receiverId: receiverId,
        conversationId: conversationId,
        content: personalNote ?? 'Shared a meal: $mealName',
        timestamp: DateTime.now(),
        senderName: _auth.currentUser?.displayName ?? 'Anonymous',
        messageType: MessageType.mealShare,
        metadata: {
          'sharedContent': sharedContent.toMap(),
          'quickShare': true,
        },
      );

      await _sendMessage(message);
      Logger.info('Meal shared in conversation $conversationId');
      return true;
    } catch (e) {
      Logger.error('Error sharing meal: $e');
      return false;
    }
  }

  /// Share a workout in chat
  Future<bool> shareWorkout({
    required String conversationId,
    required String receiverId,
    required String workoutId,
    required String workoutName,
    required String description,
    required int duration,
    required List<Map<String, dynamic>> exercises,
    String? imageUrl,
    String? difficulty,
    String? personalNote,
  }) async {
    if (currentUserId == null) return false;

    try {
      final sharedContent = SharedContent.workout(
        workoutId: workoutId,
        workoutName: workoutName,
        description: description,
        duration: duration,
        exercises: exercises,
        imageUrl: imageUrl,
        difficulty: difficulty,
      );

      final message = ChatMessage(
        messageId: _firestore.collection('temp').doc().id,
        senderId: currentUserId!,
        receiverId: receiverId,
        conversationId: conversationId,
        content: personalNote ?? 'Shared a workout: $workoutName',
        timestamp: DateTime.now(),
        senderName: _auth.currentUser?.displayName ?? 'Anonymous',
        messageType: MessageType.workoutShare,
        metadata: {
          'sharedContent': sharedContent.toMap(),
          'quickShare': true,
        },
      );

      await _sendMessage(message);
      Logger.info('Workout shared in conversation $conversationId');
      return true;
    } catch (e) {
      Logger.error('Error sharing workout: $e');
      return false;
    }
  }

  /// Share a challenge invitation
  Future<bool> shareChallengeInvite({
    required String conversationId,
    required String receiverId,
    required String challengeId,
    required String challengeName,
    required String description,
    required DateTime endDate,
    String? imageUrl,
    int? currentParticipants,
    String? prize,
    String? personalNote,
  }) async {
    if (currentUserId == null) return false;

    try {
      final sharedContent = SharedContent.challengeInvite(
        challengeId: challengeId,
        challengeName: challengeName,
        description: description,
        endDate: endDate,
        imageUrl: imageUrl,
        currentParticipants: currentParticipants,
        prize: prize,
      );

      final message = ChatMessage(
        messageId: _firestore.collection('temp').doc().id,
        senderId: currentUserId!,
        receiverId: receiverId,
        conversationId: conversationId,
        content: personalNote ?? 'Join me in this challenge: $challengeName',
        timestamp: DateTime.now(),
        senderName: _auth.currentUser?.displayName ?? 'Anonymous',
        messageType: MessageType.challengeInvite,
        metadata: {
          'sharedContent': sharedContent.toMap(),
          'quickShare': true,
        },
      );

      await _sendMessage(message);
      Logger.info('Challenge invite shared in conversation $conversationId');
      return true;
    } catch (e) {
      Logger.error('Error sharing challenge invite: $e');
      return false;
    }
  }

  // ==================== SMART SUGGESTIONS ====================

  /// Generate smart suggestions based on conversation context
  Future<List<SmartSuggestion>> generateSmartSuggestions({
    required String conversationId,
    required String lastMessage,
    required List<String> recentMessages,
  }) async {
    final suggestions = <SmartSuggestion>[];

    try {
      // Analyze message content for context
      final lowerMessage = lastMessage.toLowerCase();

      // Meal-related suggestions
      if (_containsAny(lowerMessage, ['hungry', 'eat', 'food', 'meal', 'breakfast', 'lunch', 'dinner'])) {
        suggestions.addAll(await _getMealSuggestions());
      }

      // Workout-related suggestions
      if (_containsAny(lowerMessage, ['workout', 'exercise', 'gym', 'fitness', 'training', 'tired', 'energy'])) {
        suggestions.addAll(await _getWorkoutSuggestions());
      }

      // Eco-related suggestions
      if (_containsAny(lowerMessage, ['environment', 'green', 'eco', 'sustainable', 'carbon', 'planet'])) {
        suggestions.addAll(await _getEcoSuggestions());
      }

      // Challenge suggestions
      if (_containsAny(lowerMessage, ['challenge', 'compete', 'goal', 'achievement', 'motivation'])) {
        suggestions.addAll(await _getChallengeSuggestions());
      }

      // Weather/outdoor activity suggestions
      if (_containsAny(lowerMessage, ['weather', 'outside', 'walk', 'run', 'outdoor'])) {
        suggestions.addAll(await _getOutdoorSuggestions());
      }

      return suggestions.take(3).toList(); // Limit to 3 suggestions
    } catch (e) {
      Logger.error('Error generating smart suggestions: $e');
      return [];
    }
  }

  Future<List<SmartSuggestion>> _getMealSuggestions() async {
    // In a real implementation, this would fetch personalized meal recommendations
    return [
      SmartSuggestion(
        id: 'meal_suggestion_1',
        type: SuggestionType.meal,
        title: 'Healthy Lunch Ideas',
        description: 'Share some nutritious meal options',
        icon: '🥗',
        actionData: {'type': 'meal_recommendations'},
      ),
      SmartSuggestion(
        id: 'meal_suggestion_2',
        type: SuggestionType.meal,
        title: 'Log Your Meal',
        description: 'Track what you\'re eating',
        icon: '📝',
        actionData: {'type': 'meal_logging'},
      ),
    ];
  }

  Future<List<SmartSuggestion>> _getWorkoutSuggestions() async {
    return [
      SmartSuggestion(
        id: 'workout_suggestion_1',
        type: SuggestionType.workout,
        title: 'Quick 15-min Workout',
        description: 'Perfect for a busy day',
        icon: '⚡',
        actionData: {'type': 'quick_workout', 'duration': 15},
      ),
      SmartSuggestion(
        id: 'workout_suggestion_2',
        type: SuggestionType.workout,
        title: 'Workout Together',
        description: 'Find a partner workout',
        icon: '🤝',
        actionData: {'type': 'partner_workout'},
      ),
    ];
  }

  Future<List<SmartSuggestion>> _getEcoSuggestions() async {
    return [
      SmartSuggestion(
        id: 'eco_suggestion_1',
        type: SuggestionType.ecoTip,
        title: 'Daily Eco Tip',
        description: 'Learn something new about sustainability',
        icon: '🌱',
        actionData: {'type': 'eco_tip'},
      ),
      SmartSuggestion(
        id: 'eco_suggestion_2',
        type: SuggestionType.ecoTip,
        title: 'Carbon Footprint',
        description: 'Check your environmental impact',
        icon: '🌍',
        actionData: {'type': 'carbon_footprint'},
      ),
    ];
  }

  Future<List<SmartSuggestion>> _getChallengeSuggestions() async {
    return [
      SmartSuggestion(
        id: 'challenge_suggestion_1',
        type: SuggestionType.challenge,
        title: 'Active Challenges',
        description: 'Join a community challenge',
        icon: '🏆',
        actionData: {'type': 'active_challenges'},
      ),
    ];
  }

  Future<List<SmartSuggestion>> _getOutdoorSuggestions() async {
    return [
      SmartSuggestion(
        id: 'outdoor_suggestion_1',
        type: SuggestionType.activity,
        title: 'Outdoor Activities',
        description: 'Find activities near you',
        icon: '🌞',
        actionData: {'type': 'outdoor_activities'},
      ),
    ];
  }

  // ==================== AUTOMATED MESSAGING ====================

  /// Send an automated eco tip
  Future<bool> sendAutomatedEcoTip({
    required String conversationId,
    required String receiverId,
    required EcoTip ecoTip,
  }) async {
    if (currentUserId == null) return false;

    try {
      final sharedContent = SharedContent.ecoTip(
        tipId: DateTime.now().millisecondsSinceEpoch.toString(),
        title: ecoTip.titleKey,
        description: ecoTip.descriptionKey,
        category: ecoTip.category,
        imageUrl: ecoTip.imagePath,
      );

      final message = ChatMessage(
        messageId: _firestore.collection('temp').doc().id,
        senderId: 'system', // System-generated message
        receiverId: receiverId,
        conversationId: conversationId,
        content: '🌱 Daily Eco Tip: ${ecoTip.titleKey}',
        timestamp: DateTime.now(),
        senderName: 'SolarVita',
        messageType: MessageType.ecoTip,
        metadata: {
          'sharedContent': sharedContent.toMap(),
          'automated': true,
        },
      );

      await _sendMessage(message);
      Logger.info('Automated eco tip sent to conversation $conversationId');
      return true;
    } catch (e) {
      Logger.error('Error sending automated eco tip: $e');
      return false;
    }
  }

  // ==================== HELPER METHODS ====================

  Future<void> _sendMessage(ChatMessage message) async {
    await _firestore
        .collection('conversations')
        .doc(message.conversationId)
        .collection('messages')
        .doc(message.messageId)
        .set(message.toFirestore());

    // Update conversation last message
    await _firestore
        .collection('conversations')
        .doc(message.conversationId)
        .update({
      'lastMessage': message.content,
      'lastMessageTimestamp': message.timestamp,
      'lastMessageType': message.messageType.name,
    });
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }
}

// ==================== MODELS ====================

enum SuggestionType {
  meal,
  workout,
  ecoTip,
  challenge,
  activity,
}

class SmartSuggestion {
  final String id;
  final SuggestionType type;
  final String title;
  final String description;
  final String icon;
  final Map<String, dynamic> actionData;

  const SmartSuggestion({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.actionData,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'title': title,
      'description': description,
      'icon': icon,
      'actionData': actionData,
    };
  }

  factory SmartSuggestion.fromMap(Map<String, dynamic> map) {
    return SmartSuggestion(
      id: map['id'] ?? '',
      type: SuggestionType.values[map['type'] ?? 0],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '💡',
      actionData: Map<String, dynamic>.from(map['actionData'] ?? {}),
    );
  }
}