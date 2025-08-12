import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

final log = Logger('AvatarCleanup');

/// Utility to clean up invalid avatars from Firestore
class AvatarCleanup {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Remove Ninja Coach from Firestore since ninja.riv doesn't exist
  static Future<void> removeNinjaCoach() async {
    try {
      log.info('🗑️ Removing ninja_coach from Firestore (no Rive file exists)');
      
      // Delete from avatars collection
      await _firestore.collection('avatars').doc('ninja_coach').delete();
      
      log.info('✅ ninja_coach removed from Firestore avatars collection');
    } catch (e) {
      log.warning('⚠️ Could not remove ninja_coach (may not exist): $e');
    }
  }
  
  /// Remove any other invalid avatars that don't have Rive files
  static Future<void> cleanupInvalidAvatars() async {
    try {
      log.info('🧹 Cleaning up invalid avatars from Firestore');
      
      // List of avatars that should NOT exist (no Rive files)
      const invalidAvatars = [
        'ninja_coach',
        'classical_coach', // If this exists
      ];
      
      final batch = _firestore.batch();
      
      for (final avatarId in invalidAvatars) {
        final docRef = _firestore.collection('avatars').doc(avatarId);
        batch.delete(docRef);
        log.info('🗑️ Scheduled deletion of: $avatarId');
      }
      
      await batch.commit();
      log.info('✅ Cleanup completed - invalid avatars removed');
    } catch (e) {
      log.severe('❌ Error during avatar cleanup: $e');
    }
  }
  
  /// List all avatars in Firestore for debugging
  static Future<void> listAllAvatars() async {
    try {
      final snapshot = await _firestore.collection('avatars').get();
      log.info('📋 Current avatars in Firestore:');
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        log.info('  - ${doc.id}: ${data['name']} (${data['rivAssetPath']})');
      }
    } catch (e) {
      log.severe('❌ Error listing avatars: $e');
    }
  }
}