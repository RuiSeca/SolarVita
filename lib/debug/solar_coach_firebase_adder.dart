import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

final log = Logger('SolarCoachFirebaseAdder');

/// Debug helper to add solar_coach to Firebase avatars collection
class SolarCoachFirebaseAdder {
  static const String collectionName = 'avatars';
  
  /// Add solar_coach to Firebase if it doesn't exist
  static Future<void> addSolarCoachToFirebase() async {
    try {
      log.info('🌞 Checking if solar_coach exists in Firebase...');
      
      final firestore = FirebaseFirestore.instance;
      final avatarsCollection = firestore.collection(collectionName);
      
      // Check if solar_coach already exists
      final existingDoc = await avatarsCollection.doc('solar_coach').get();
      if (existingDoc.exists) {
        log.info('✅ solar_coach already exists in Firebase');
        return;
      }
      
      log.info('🚀 Adding solar_coach to Firebase avatars collection...');
      
      // Create the solar_coach document with updated configuration
      final solarCoachData = {
        'avatarId': 'solar_coach',
        'name': 'Solar Coach',
        'description': 'Radiant energy coach that harnesses the power of the sun. Flies with grace and solar energy using simple animations.',
        'rivAssetPath': 'assets/rive/solar.riv',
        'availableAnimations': ['ClICK 5', 'ClICK 4', 'ClICK 3', 'ClICK 2', 'ClICK 1', 'SECOND FLY', 'FIRST FLY'],
        'customProperties': {
          'hasComplexSequence': false, // Updated to false
          'supportsTeleport': false,
          'hasCustomization': false,
          'usesStateMachineTriggers': true, // New property
          'triggerInputs': ['click ri'], // Available trigger inputs
          'sequenceOrder': ['click ri'], // Updated sequence
          'animationApproach': 'simple', // Indicates this uses simple animations not state machine
        },
        'price': 0,
        'rarity': 'epic',
        'isPurchasable': true,
        'requiredAchievements': [],
        'releaseDate': Timestamp.fromDate(DateTime(2024, 8, 1)),
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };
      
      // Add to Firebase
      await avatarsCollection.doc('solar_coach').set(solarCoachData);
      
      log.info('✅ Successfully added solar_coach to Firebase!');
      log.info('🌞 solar_coach should now appear in the avatar store');
      
    } catch (e) {
      log.severe('❌ Error adding solar_coach to Firebase: $e');
      rethrow;
    }
  }
  
  /// Update existing solar_coach in Firebase with new configuration
  static Future<void> updateSolarCoachInFirebase() async {
    try {
      log.info('🔄 Updating solar_coach configuration in Firebase...');
      
      final firestore = FirebaseFirestore.instance;
      final avatarsCollection = firestore.collection(collectionName);
      
      // Check if solar_coach exists
      final existingDoc = await avatarsCollection.doc('solar_coach').get();
      if (!existingDoc.exists) {
        log.warning('⚠️ solar_coach does not exist in Firebase. Use addSolarCoachToFirebase() first.');
        return;
      }
      
      // Update with new configuration
      final updatedData = {
        'description': 'Radiant energy coach that harnesses the power of the sun. Flies with grace and solar energy using simple animations.',
        'availableAnimations': ['ClICK 5', 'ClICK 4', 'ClICK 3', 'ClICK 2', 'ClICK 1', 'SECOND FLY', 'FIRST FLY'],
        'customProperties': {
          'hasComplexSequence': false, // Updated to false
          'supportsTeleport': false,
          'hasCustomization': false,
          'usesStateMachineTriggers': true, // New property
          'triggerInputs': ['click ri'], // Available trigger inputs
          'sequenceOrder': ['click ri'], // Updated sequence
          'animationApproach': 'simple', // Indicates this uses simple animations not state machine
        },
        'updatedAt': Timestamp.now(),
      };
      
      // Update in Firebase
      await avatarsCollection.doc('solar_coach').update(updatedData);
      
      log.info('✅ Successfully updated solar_coach configuration in Firebase!');
      log.info('🌞 solar_coach now uses the new simple animation approach');
      
    } catch (e) {
      log.severe('❌ Error updating solar_coach in Firebase: $e');
      rethrow;
    }
  }

  /// Remove solar_coach from Firebase (for testing)
  static Future<void> removeSolarCoachFromFirebase() async {
    try {
      log.info('🗑️ Removing solar_coach from Firebase...');
      
      final firestore = FirebaseFirestore.instance;
      await firestore.collection(collectionName).doc('solar_coach').delete();
      
      log.info('✅ solar_coach removed from Firebase');
      
    } catch (e) {
      log.severe('❌ Error removing solar_coach from Firebase: $e');
      rethrow;
    }
  }
  
  /// List all avatars currently in Firebase
  static Future<void> listFirebaseAvatars() async {
    try {
      log.info('📋 Listing all avatars in Firebase...');
      
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection(collectionName).get();
      
      log.info('Found ${snapshot.docs.length} avatars in Firebase:');
      for (final doc in snapshot.docs) {
        final data = doc.data();
        log.info('  - ${data['avatarId']}: ${data['name']} (${data['rarity']})');
      }
      
    } catch (e) {
      log.severe('❌ Error listing Firebase avatars: $e');
    }
  }
}