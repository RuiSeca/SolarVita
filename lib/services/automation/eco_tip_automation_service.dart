import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/eco/eco_tip.dart';
import '../../services/chat/enhanced_chat_service.dart';
import '../../utils/logger.dart';

class EcoTipAutomationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EnhancedChatService _chatService = EnhancedChatService();

  static const String _automationSettingsCollection = 'automation_settings';

  // Daily eco tips pool
  static const List<EcoTip> _dailyEcoTips = [
    EcoTip(
      titleKey: 'reduce_water_usage',
      descriptionKey: 'Turn off the tap while brushing your teeth to save up to 8 gallons of water per day.',
      category: 'water_conservation',
      imagePath: 'assets/images/eco/water_conservation.png',
    ),
    EcoTip(
      titleKey: 'use_reusable_bags',
      descriptionKey: 'Bring reusable bags when shopping to reduce plastic waste and protect marine life.',
      category: 'waste_reduction',
      imagePath: 'assets/images/eco/reusable_bags.png',
    ),
    EcoTip(
      titleKey: 'energy_efficient_lighting',
      descriptionKey: 'Switch to LED bulbs - they use 75% less energy and last 25 times longer.',
      category: 'energy_conservation',
      imagePath: 'assets/images/eco/led_bulbs.png',
    ),
    EcoTip(
      titleKey: 'sustainable_transportation',
      descriptionKey: 'Walk, bike, or use public transport for short trips to reduce your carbon footprint.',
      category: 'transportation',
      imagePath: 'assets/images/eco/sustainable_transport.png',
    ),
    EcoTip(
      titleKey: 'reduce_food_waste',
      descriptionKey: 'Plan your meals and store food properly to reduce waste and save money.',
      category: 'food_sustainability',
      imagePath: 'assets/images/eco/food_waste.png',
    ),
    EcoTip(
      titleKey: 'unplug_electronics',
      descriptionKey: 'Unplug electronics when not in use - they consume energy even when turned off.',
      category: 'energy_conservation',
      imagePath: 'assets/images/eco/unplug_electronics.png',
    ),
    EcoTip(
      titleKey: 'choose_local_food',
      descriptionKey: 'Buy local and seasonal produce to reduce transportation emissions and support local farmers.',
      category: 'food_sustainability',
      imagePath: 'assets/images/eco/local_food.png',
    ),
    EcoTip(
      titleKey: 'digital_receipts',
      descriptionKey: 'Choose digital receipts instead of paper ones to reduce paper waste.',
      category: 'waste_reduction',
      imagePath: 'assets/images/eco/digital_receipts.png',
    ),
    EcoTip(
      titleKey: 'shorter_showers',
      descriptionKey: 'Take shorter showers - reducing by just 2 minutes can save 10 gallons of water.',
      category: 'water_conservation',
      imagePath: 'assets/images/eco/shorter_showers.png',
    ),
    EcoTip(
      titleKey: 'recycle_properly',
      descriptionKey: 'Learn your local recycling guidelines to ensure materials are properly recycled.',
      category: 'waste_reduction',
      imagePath: 'assets/images/eco/recycling.png',
    ),
  ];

  // ==================== AUTOMATION SETUP ====================

  /// Enable daily eco tips for a user
  Future<bool> enableDailyEcoTips({
    required String userId,
    required TimeOfDay preferredTime,
    List<String>? supporterIds,
    List<String>? preferredCategories,
  }) async {
    try {
      await _firestore
          .collection(_automationSettingsCollection)
          .doc(userId)
          .set({
        'ecoTipsEnabled': true,
        'preferredHour': preferredTime.hour,
        'preferredMinute': preferredTime.minute,
        'supporterIds': supporterIds ?? [],
        'preferredCategories': preferredCategories ?? [],
        'lastSentDate': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Logger.info('Daily eco tips enabled for user $userId');
      return true;
    } catch (e) {
      Logger.error('Error enabling daily eco tips: $e');
      return false;
    }
  }

  /// Disable daily eco tips for a user
  Future<bool> disableDailyEcoTips(String userId) async {
    try {
      await _firestore
          .collection(_automationSettingsCollection)
          .doc(userId)
          .update({
        'ecoTipsEnabled': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Logger.info('Daily eco tips disabled for user $userId');
      return true;
    } catch (e) {
      Logger.error('Error disabling daily eco tips: $e');
      return false;
    }
  }

  /// Update eco tip preferences
  Future<bool> updateEcoTipPreferences({
    required String userId,
    TimeOfDay? preferredTime,
    List<String>? preferredCategories,
    List<String>? supporterIds,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (preferredTime != null) {
        updateData['preferredHour'] = preferredTime.hour;
        updateData['preferredMinute'] = preferredTime.minute;
      }

      if (preferredCategories != null) {
        updateData['preferredCategories'] = preferredCategories;
      }

      if (supporterIds != null) {
        updateData['supporterIds'] = supporterIds;
      }

      await _firestore
          .collection(_automationSettingsCollection)
          .doc(userId)
          .update(updateData);

      Logger.info('Eco tip preferences updated for user $userId');
      return true;
    } catch (e) {
      Logger.error('Error updating eco tip preferences: $e');
      return false;
    }
  }

  // ==================== AUTOMATED SENDING ====================

  /// Send daily eco tips to all eligible users (called by scheduled function)
  Future<void> sendDailyEcoTips() async {
    try {
      final now = DateTime.now();
      final currentHour = now.hour;
      final currentMinute = now.minute;

      // Get all users with eco tips enabled
      final automationQuery = await _firestore
          .collection(_automationSettingsCollection)
          .where('ecoTipsEnabled', isEqualTo: true)
          .where('preferredHour', isEqualTo: currentHour)
          .get();

      for (final doc in automationQuery.docs) {
        final data = doc.data();
        final userId = doc.id;
        final preferredMinute = data['preferredMinute'] ?? 0;

        // Check if it's the right time (within 5 minutes)
        if ((currentMinute - preferredMinute).abs() <= 5) {
          await _sendEcoTipToUser(userId, data);
        }
      }

      Logger.info('Daily eco tips processing completed');
    } catch (e) {
      Logger.error('Error sending daily eco tips: $e');
    }
  }

  /// Send eco tip to a specific user
  Future<void> _sendEcoTipToUser(String userId, Map<String, dynamic> settings) async {
    try {
      // Check if we already sent a tip today
      final lastSentDate = settings['lastSentDate'] as Timestamp?;
      final today = DateTime.now();

      if (lastSentDate != null) {
        final lastSent = lastSentDate.toDate();
        if (lastSent.year == today.year &&
            lastSent.month == today.month &&
            lastSent.day == today.day) {
          return; // Already sent today
        }
      }

      // Get user's preferred categories
      final preferredCategories = List<String>.from(settings['preferredCategories'] ?? []);
      final supporterIds = List<String>.from(settings['supporterIds'] ?? []);

      // Select an appropriate eco tip
      final selectedTip = _selectEcoTip(preferredCategories);

      // Send to supporter conversations
      if (supporterIds.isNotEmpty) {
        await _sendToSupporters(userId, supporterIds, selectedTip);
      }

      // Update last sent timestamp
      await _firestore
          .collection(_automationSettingsCollection)
          .doc(userId)
          .update({
        'lastSentDate': FieldValue.serverTimestamp(),
      });

      Logger.info('Eco tip sent to user $userId');
    } catch (e) {
      Logger.error('Error sending eco tip to user $userId: $e');
    }
  }

  /// Send eco tip to supporter conversations
  Future<void> _sendToSupporters(String userId, List<String> supporterIds, EcoTip ecoTip) async {
    try {
      // Get user's conversations with supporters
      final conversationsQuery = await _firestore
          .collection('conversations')
          .where('participantIds', arrayContains: userId)
          .get();

      for (final conversationDoc in conversationsQuery.docs) {
        final conversationData = conversationDoc.data();
        final participantIds = List<String>.from(conversationData['participantIds'] ?? []);

        // Check if this conversation includes any of the specified supporters
        final supporterInConversation = participantIds.firstWhere(
          (id) => id != userId && supporterIds.contains(id),
          orElse: () => '',
        );

        if (supporterInConversation.isNotEmpty) {
          await _chatService.sendAutomatedEcoTip(
            conversationId: conversationDoc.id,
            receiverId: supporterInConversation,
            ecoTip: ecoTip,
          );
        }
      }
    } catch (e) {
      Logger.error('Error sending to supporters: $e');
    }
  }

  /// Select an appropriate eco tip based on preferences
  EcoTip _selectEcoTip(List<String> preferredCategories) {
    List<EcoTip> availableTips = _dailyEcoTips;

    // Filter by preferred categories if specified
    if (preferredCategories.isNotEmpty) {
      final filteredTips = _dailyEcoTips
          .where((tip) => preferredCategories.contains(tip.category))
          .toList();

      if (filteredTips.isNotEmpty) {
        availableTips = filteredTips;
      }
    }

    // Select a random tip from available options
    final random = Random();
    return availableTips[random.nextInt(availableTips.length)];
  }

  // ==================== CONTEXTUAL ECO TIPS ====================

  /// Send contextual eco tips based on user activity
  Future<void> sendContextualEcoTip({
    required String userId,
    required String context,
    required List<String> supporterIds,
  }) async {
    try {
      EcoTip? contextualTip;

      switch (context.toLowerCase()) {
        case 'meal_logged':
          contextualTip = _getRandomTipByCategory('food_sustainability');
          break;
        case 'workout_completed':
          contextualTip = _getRandomTipByCategory('transportation');
          break;
        case 'shopping_activity':
          contextualTip = _getRandomTipByCategory('waste_reduction');
          break;
        case 'travel_logged':
          contextualTip = _getRandomTipByCategory('transportation');
          break;
        case 'home_activity':
          contextualTip = _getRandomTipByCategory('energy_conservation');
          break;
      }

      if (contextualTip != null && supporterIds.isNotEmpty) {
        await _sendToSupporters(userId, supporterIds, contextualTip);
        Logger.info('Contextual eco tip sent for context: $context');
      }
    } catch (e) {
      Logger.error('Error sending contextual eco tip: $e');
    }
  }

  EcoTip? _getRandomTipByCategory(String category) {
    final categoryTips = _dailyEcoTips
        .where((tip) => tip.category == category)
        .toList();

    if (categoryTips.isEmpty) return null;

    final random = Random();
    return categoryTips[random.nextInt(categoryTips.length)];
  }

  // ==================== WEEKLY ECO CHALLENGES ====================

  /// Send weekly eco challenge to supporter groups
  Future<void> sendWeeklyEcoChallenge() async {
    try {
      final weeklyChallenge = _getWeeklyChallenge();

      // Get all users with eco tips enabled
      final automationQuery = await _firestore
          .collection(_automationSettingsCollection)
          .where('ecoTipsEnabled', isEqualTo: true)
          .get();

      for (final doc in automationQuery.docs) {
        final userId = doc.id;
        final data = doc.data();
        final supporterIds = List<String>.from(data['supporterIds'] ?? []);

        if (supporterIds.isNotEmpty) {
          await _sendWeeklyChallengeToSupporters(userId, supporterIds, weeklyChallenge);
        }
      }

      Logger.info('Weekly eco challenges sent');
    } catch (e) {
      Logger.error('Error sending weekly eco challenges: $e');
    }
  }

  Future<void> _sendWeeklyChallengeToSupporters(
    String userId,
    List<String> supporterIds,
    Map<String, dynamic> challenge,
  ) async {
    // Implementation would depend on your challenge sharing system
    Logger.info('Weekly eco challenge sent to supporters of user $userId');
  }

  Map<String, dynamic> _getWeeklyChallenge() {
    final challenges = [
      {
        'title': 'Plastic-Free Week',
        'description': 'Avoid single-use plastics for one week',
        'category': 'waste_reduction',
        'points': 100,
      },
      {
        'title': 'Walk to Work Week',
        'description': 'Walk or bike to work every day this week',
        'category': 'transportation',
        'points': 150,
      },
      {
        'title': 'Energy Saving Week',
        'description': 'Reduce your home energy consumption by 20%',
        'category': 'energy_conservation',
        'points': 120,
      },
      {
        'title': 'Zero Food Waste Week',
        'description': 'Plan meals carefully to eliminate food waste',
        'category': 'food_sustainability',
        'points': 130,
      },
    ];

    final random = Random();
    return challenges[random.nextInt(challenges.length)];
  }

  // ==================== UTILITY METHODS ====================

  /// Get automation settings for a user
  Future<Map<String, dynamic>?> getAutomationSettings(String userId) async {
    try {
      final doc = await _firestore
          .collection(_automationSettingsCollection)
          .doc(userId)
          .get();

      return doc.exists ? doc.data() : null;
    } catch (e) {
      Logger.error('Error getting automation settings: $e');
      return null;
    }
  }

  /// Check if eco tips are enabled for a user
  Future<bool> areEcoTipsEnabled(String userId) async {
    try {
      final settings = await getAutomationSettings(userId);
      return settings?['ecoTipsEnabled'] ?? false;
    } catch (e) {
      Logger.error('Error checking eco tips status: $e');
      return false;
    }
  }
}

// Helper class for time of day (since Flutter's TimeOfDay might not be available in services)
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  @override
  String toString() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}