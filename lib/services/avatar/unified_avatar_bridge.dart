import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import '../firebase/firebase_avatar_service.dart';

final log = Logger('UnifiedAvatarBridge');

/// Unified Avatar State Bridge
/// 
/// This service acts as a bridge between the Firebase avatar system and the legacy
/// SharedPreferences system, ensuring state synchronization across both systems
/// while we transition fully to Firebase.
/// 
/// Key responsibilities:
/// 1. Sync equipped avatar state between Firebase and SharedPreferences
/// 2. Provide a single source of truth for equipped avatar
/// 3. Handle migration from legacy system to Firebase
/// 4. Ensure backward compatibility during transition
class UnifiedAvatarBridge {
  static const String _legacyEquippedAvatarKey = 'equipped_avatar_id';
  static const String _migrationCompleteKey = 'avatar_migration_complete';
  
  final FirebaseAvatarService _firebaseService;
  SharedPreferences? _prefs;
  StreamSubscription? _firebaseStateSubscription;
  
  // Current state cache
  String? _cachedEquippedAvatarId;
  DateTime? _lastSyncTime;
  
  // Stream controller for unified equipped avatar state
  final StreamController<String?> _equippedAvatarController = StreamController<String?>.broadcast();
  
  UnifiedAvatarBridge(this._firebaseService);
  
  /// Stream of equipped avatar ID from unified bridge
  Stream<String?> get equippedAvatarStream => _equippedAvatarController.stream;
  
  /// Get currently equipped avatar ID (unified view)
  String? get equippedAvatarId => _cachedEquippedAvatarId;
  
  /// Initialize the bridge and start synchronization
  Future<void> initialize() async {
    try {
      log.info('🌉 Initializing Unified Avatar Bridge...');
      
      _prefs = await SharedPreferences.getInstance();
      
      // Check if migration has been completed
      final migrationComplete = _prefs?.getBool(_migrationCompleteKey) ?? false;
      
      if (!migrationComplete) {
        log.info('📦 Running avatar state migration from legacy to Firebase...');
        await _migrateLegacyToFirebase();
      }
      
      // Start listening to Firebase state changes
      _startFirebaseListener();
      
      // Perform initial sync
      await _performSync();
      
      log.info('✅ Unified Avatar Bridge initialized successfully');
    } catch (e, stackTrace) {
      log.severe('❌ Failed to initialize Unified Avatar Bridge: $e', e, stackTrace);
      rethrow;
    }
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    log.info('🧹 Disposing Unified Avatar Bridge');
    await _firebaseStateSubscription?.cancel();
    await _equippedAvatarController.close();
  }
  
  /// Migrate legacy SharedPreferences state to Firebase
  Future<void> _migrateLegacyToFirebase() async {
    if (_prefs == null) return;
    
    try {
      final legacyEquippedId = _prefs!.getString(_legacyEquippedAvatarKey);
      
      if (legacyEquippedId != null && legacyEquippedId.isNotEmpty) {
        log.info('📦 Found legacy equipped avatar: $legacyEquippedId');
        
        // Check if Firebase has an equipped avatar
        final firebaseState = _firebaseService.getCurrentUserState();
        
        if (firebaseState?.equippedAvatarId == null) {
          log.info('📦 Migrating legacy equipped avatar to Firebase: $legacyEquippedId');
          
          // Ensure user owns the legacy avatar (especially for free avatars)
          if (_firebaseService.doesUserOwnAvatar(legacyEquippedId)) {
            try {
              await _firebaseService.equipAvatar(legacyEquippedId);
              log.info('✅ Successfully migrated legacy equipped avatar to Firebase');
            } catch (e) {
              log.warning('⚠️ Failed to migrate legacy equipped avatar: $e');
              // Continue with migration marked as complete to avoid infinite attempts
            }
          } else {
            log.warning('⚠️ User does not own legacy equipped avatar: $legacyEquippedId');
          }
        } else {
          log.info('📦 Firebase already has equipped avatar: ${firebaseState?.equippedAvatarId}');
        }
      }
      
      // Mark migration as complete
      await _prefs!.setBool(_migrationCompleteKey, true);
      log.info('✅ Avatar migration marked as complete');
      
    } catch (e) {
      log.warning('⚠️ Error during legacy migration: $e');
      // Mark migration as complete to avoid infinite retry
      await _prefs?.setBool(_migrationCompleteKey, true);
    }
  }
  
  /// Start listening to Firebase state changes
  void _startFirebaseListener() {
    _firebaseStateSubscription = _firebaseService.userStateStream.listen(
      (firebaseState) {
        final firebaseEquippedId = firebaseState?.equippedAvatarId;
        log.info('🔄 Firebase state change: equipped=$firebaseEquippedId');
        
        if (firebaseEquippedId != _cachedEquippedAvatarId) {
          _updateUnifiedState(firebaseEquippedId, source: 'firebase');
        }
      },
      onError: (error) {
        log.severe('❌ Error listening to Firebase state: $error');
      },
    );
  }
  
  /// Perform synchronization between Firebase and legacy systems
  Future<void> _performSync() async {
    try {
      log.info('🔄 Performing avatar state sync...');
      
      final firebaseState = _firebaseService.getCurrentUserState();
      final firebaseEquippedId = firebaseState?.equippedAvatarId;
      
      final legacyEquippedId = _prefs?.getString(_legacyEquippedAvatarKey);
      
      log.info('🔍 Sync check - Firebase: $firebaseEquippedId, Legacy: $legacyEquippedId');
      
      // Firebase is the source of truth
      if (firebaseEquippedId != null) {
        // Update legacy to match Firebase
        if (legacyEquippedId != firebaseEquippedId) {
          await _prefs?.setString(_legacyEquippedAvatarKey, firebaseEquippedId);
          log.info('📝 Updated legacy equipped avatar to match Firebase: $firebaseEquippedId');
        }
        _updateUnifiedState(firebaseEquippedId, source: 'sync');
      } else if (legacyEquippedId != null && legacyEquippedId.isNotEmpty) {
        // Firebase is empty but legacy has value - migrate to Firebase
        log.info('📦 Found legacy equipped avatar, migrating to Firebase: $legacyEquippedId');
        if (_firebaseService.doesUserOwnAvatar(legacyEquippedId)) {
          try {
            await _firebaseService.equipAvatar(legacyEquippedId);
            _updateUnifiedState(legacyEquippedId, source: 'migration');
          } catch (e) {
            log.warning('⚠️ Failed to migrate equipped avatar to Firebase: $e');
            _updateUnifiedState(legacyEquippedId, source: 'legacy');
          }
        }
      } else {
        // Both empty - set to null
        _updateUnifiedState(null, source: 'sync');
      }
      
      _lastSyncTime = DateTime.now();
      log.info('✅ Avatar state sync completed');
      
    } catch (e) {
      log.warning('⚠️ Error during avatar state sync: $e');
    }
  }
  
  /// Update the unified state and notify listeners
  void _updateUnifiedState(String? avatarId, {required String source}) {
    if (_cachedEquippedAvatarId != avatarId) {
      log.info('🎯 Unified state update: $_cachedEquippedAvatarId → $avatarId (source: $source)');
      _cachedEquippedAvatarId = avatarId;
      _equippedAvatarController.add(avatarId);
    }
  }
  
  /// Equip avatar through unified bridge (ensures both systems are updated)
  Future<void> equipAvatar(String avatarId) async {
    try {
      log.info('🎯 Unified equip request for avatar: $avatarId');
      
      // Update Firebase first (source of truth)
      await _firebaseService.equipAvatar(avatarId);
      
      // Update legacy system
      await _prefs?.setString(_legacyEquippedAvatarKey, avatarId);
      
      // Update unified state
      _updateUnifiedState(avatarId, source: 'unified_equip');
      
      log.info('✅ Successfully equipped avatar through unified bridge: $avatarId');
      
    } catch (e, stackTrace) {
      log.severe('❌ Failed to equip avatar through unified bridge: $e', e, stackTrace);
      rethrow;
    }
  }
  
  /// Force refresh of the unified state
  Future<void> refresh() async {
    log.info('🔄 Force refreshing unified avatar state...');
    await _performSync();
  }
  
  /// Get debug information about bridge state
  Map<String, dynamic> getDebugInfo() {
    final firebaseState = _firebaseService.getCurrentUserState();
    final legacyEquippedId = _prefs?.getString(_legacyEquippedAvatarKey);
    final migrationComplete = _prefs?.getBool(_migrationCompleteKey) ?? false;
    
    return {
      'unifiedEquippedAvatarId': _cachedEquippedAvatarId,
      'firebaseEquippedAvatarId': firebaseState?.equippedAvatarId,
      'legacyEquippedAvatarId': legacyEquippedId,
      'migrationComplete': migrationComplete,
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'streamListening': _firebaseStateSubscription?.isPaused == false,
    };
  }
}