import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import '../../models/firebase/firebase_avatar.dart';

final log = Logger('FirebaseAvatarService');

/// Service for managing avatar data in Firebase Firestore
/// Handles ownership, purchases, customizations, and real-time synchronization
class FirebaseAvatarService {
  static const String _avatarsCollection = 'avatars';
  static const String _userAvatarStatesCollection = 'user_avatar_states';
  static const String _userAvatarOwnershipsCollection = 'user_avatar_ownerships';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache for better performance
  final Map<String, FirebaseAvatar> _avatarCache = {};
  final Map<String, UserAvatarOwnership> _ownershipCache = {};
  FirebaseAvatarState? _currentUserState;

  // Stream subscriptions for real-time updates
  StreamSubscription<QuerySnapshot>? _avatarsSubscription;
  StreamSubscription<QuerySnapshot>? _ownershipsSubscription;
  StreamSubscription<DocumentSnapshot>? _userStateSubscription;

  // Stream controllers for reactive UI
  final StreamController<List<FirebaseAvatar>> _avatarsController = StreamController.broadcast();
  final StreamController<FirebaseAvatarState?> _userStateController = StreamController.broadcast();
  final StreamController<List<UserAvatarOwnership>> _ownershipsController = StreamController.broadcast();

  /// Stream of all available avatars
  Stream<List<FirebaseAvatar>> get avatarsStream => _avatarsController.stream;

  /// Stream of current user's avatar state
  Stream<FirebaseAvatarState?> get userStateStream => _userStateController.stream;

  /// Stream of current user's avatar ownerships
  Stream<List<UserAvatarOwnership>> get ownershipsStream => _ownershipsController.stream;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Initialize the service and start listening to real-time updates
  Future<void> initialize() async {
    if (currentUserId == null) {
      log.warning('⚠️ No authenticated user - cannot initialize Firebase Avatar Service');
      return;
    }

    log.info('🚀 Initializing Firebase Avatar Service for user: $currentUserId');

    try {
      // Start listening to real-time updates
      await _startListening();
      
      // Try to initialize default avatars if none exist (requires admin permissions)
      try {
        await _ensureDefaultAvatarsExist();
      } catch (e) {
        log.warning('⚠️ Cannot create default avatars (admin permissions required): $e');
        // Continue without seeding - avatars should be managed by admins
      }
      
      // Initialize user state if not exists - do this even if no avatars exist
      try {
        await _ensureUserStateExists();
      } catch (e) {
        log.warning('⚠️ Could not initialize user state: $e');
        // Continue anyway - user state can be created later
      }

      log.info('✅ Firebase Avatar Service initialized successfully');
    } catch (e, stackTrace) {
      log.severe('❌ Failed to initialize Firebase Avatar Service: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Start listening to Firestore real-time updates
  Future<void> _startListening() async {
    if (currentUserId == null) return;

    // Emit initial empty states to prevent AsyncLoading
    log.info('🎬 Emitting initial empty states to prevent loading delays');
    _ownershipsController.add(<UserAvatarOwnership>[]);
    _userStateController.add(null);
    _avatarsController.add(<FirebaseAvatar>[]); // Also emit empty avatars list initially

    // Listen to all avatars
    _avatarsSubscription = _firestore
        .collection(_avatarsCollection)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen(
      (snapshot) {
        final avatars = snapshot.docs
            .map((doc) => FirebaseAvatar.fromFirestore(doc))
            .toList();
        
        // Update cache
        _avatarCache.clear();
        for (final avatar in avatars) {
          _avatarCache[avatar.avatarId] = avatar;
        }
        
        _avatarsController.add(avatars);
        log.info('🔄 Avatars updated: ${avatars.length} total');
      },
      onError: (error) {
        log.severe('❌ Error listening to avatars: $error');
      },
    );

    // Listen to user's avatar ownerships
    _ownershipsSubscription = _firestore
        .collection(_userAvatarOwnershipsCollection)
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .listen(
      (snapshot) {
        log.info('📦 Ownership snapshot received - docs: ${snapshot.docs.length}');
        
        final ownerships = snapshot.docs
            .map((doc) => UserAvatarOwnership.fromFirestore(doc))
            .toList();
        
        // Update cache
        _ownershipCache.clear();
        for (final ownership in ownerships) {
          _ownershipCache['${ownership.userId}_${ownership.avatarId}'] = ownership;
        }
        
        // Always emit the ownerships list, even if empty
        _ownershipsController.add(ownerships);
        log.info('🔄 User ownerships updated: ${ownerships.length} owned');
      },
      onError: (error) {
        log.severe('❌ Error listening to ownerships: $error');
        // Emit empty list on error to prevent indefinite loading
        _ownershipsController.add(<UserAvatarOwnership>[]);
      },
    );

    // Listen to user's avatar state
    _userStateSubscription = _firestore
        .collection(_userAvatarStatesCollection)
        .doc(currentUserId)
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.exists) {
          _currentUserState = FirebaseAvatarState.fromFirestore(snapshot);
        } else {
          // Create a default user state when document doesn't exist
          _currentUserState = FirebaseAvatarState(
            userId: currentUserId!,
            equippedAvatarId: null,
            globalCustomizations: {},
            ownedAvatarIds: [],
            totalPurchases: 0,
            totalSpent: 0,
            lastUpdate: DateTime.now(),
            achievements: {},
          );
          log.info('🎯 Creating default user state for user: $currentUserId');
        }
        
        _userStateController.add(_currentUserState);
        log.info('🔄 User state updated: equipped=${_currentUserState?.equippedAvatarId}');
      },
      onError: (error) {
        log.severe('❌ Error listening to user state: $error');
      },
    );
  }

  /// Stop listening to real-time updates
  Future<void> dispose() async {
    log.info('🧹 Disposing Firebase Avatar Service');
    
    await _avatarsSubscription?.cancel();
    await _ownershipsSubscription?.cancel();
    await _userStateSubscription?.cancel();
    
    await _avatarsController.close();
    await _userStateController.close();
    await _ownershipsController.close();
    
    _avatarCache.clear();
    _ownershipCache.clear();
    _currentUserState = null;
  }

  /// Get all available avatars (cached)
  List<FirebaseAvatar> getAvailableAvatars() {
    return _avatarCache.values.toList();
  }

  /// Get specific avatar by ID
  FirebaseAvatar? getAvatar(String avatarId) {
    return _avatarCache[avatarId];
  }

  /// Get current user's avatar state
  FirebaseAvatarState? getCurrentUserState() {
    return _currentUserState;
  }

  /// Get user's owned avatars
  List<UserAvatarOwnership> getUserOwnerships() {
    return _ownershipCache.values
        .where((ownership) => ownership.userId == currentUserId)
        .toList();
  }

  /// Check if user owns a specific avatar
  bool doesUserOwnAvatar(String avatarId) {
    if (currentUserId == null) return false;
    return _ownershipCache.containsKey('${currentUserId}_$avatarId');
  }

  /// Get user's equipped avatar
  FirebaseAvatar? getEquippedAvatar() {
    final equippedId = _currentUserState?.equippedAvatarId;
    if (equippedId == null) return null;
    return _avatarCache[equippedId];
  }

  /// Purchase an avatar for the current user
  Future<bool> purchaseAvatar(String avatarId, {Map<String, dynamic>? metadata}) async {
    if (currentUserId == null) {
      throw Exception('User must be authenticated to purchase avatars');
    }

    final avatar = _avatarCache[avatarId];
    if (avatar == null) {
      throw Exception('Avatar not found: $avatarId');
    }

    if (!avatar.isPurchasable) {
      throw Exception('Avatar is not purchasable: $avatarId');
    }

    // Check if user already owns this avatar
    if (doesUserOwnAvatar(avatarId)) {
      log.warning('⚠️ User already owns avatar: $avatarId');
      return false;
    }

    try {
      // Use a Firestore transaction to ensure data consistency
      final result = await _firestore.runTransaction<bool>((transaction) async {
        final userStateRef = _firestore.collection(_userAvatarStatesCollection).doc(currentUserId);
        final ownershipRef = _firestore.collection(_userAvatarOwnershipsCollection).doc('${currentUserId}_$avatarId');

        // Get current user state
        final userStateSnapshot = await transaction.get(userStateRef);
        FirebaseAvatarState currentState;
        
        if (userStateSnapshot.exists) {
          currentState = FirebaseAvatarState.fromFirestore(userStateSnapshot);
        } else {
          // Create initial state
          currentState = FirebaseAvatarState(
            userId: currentUserId!,
            equippedAvatarId: avatarId, // Equip first purchased avatar
            globalCustomizations: {},
            ownedAvatarIds: [],
            totalPurchases: 0,
            totalSpent: 0,
            lastUpdate: DateTime.now(),
            achievements: {},
          );
        }

        // Create new ownership record
        final ownership = UserAvatarOwnership(
          userId: currentUserId!,
          avatarId: avatarId,
          purchaseDate: DateTime.now(),
          isEquipped: currentState.ownedAvatarIds.isEmpty, // Equip if first avatar
          customizations: {},
          timesUsed: 0,
          lastUsed: DateTime.now(),
          metadata: metadata ?? {'purchaseSource': 'store', 'pricePaid': avatar.price},
        );

        // Update user state
        final updatedState = currentState.copyWith(
          ownedAvatarIds: [...currentState.ownedAvatarIds, avatarId],
          totalPurchases: currentState.totalPurchases + 1,
          totalSpent: currentState.totalSpent + avatar.price,
          lastUpdate: DateTime.now(),
          equippedAvatarId: currentState.equippedAvatarId ?? avatarId, // Equip if no avatar equipped
        );

        // Write to Firestore
        transaction.set(ownershipRef, ownership.toFirestore());
        transaction.set(userStateRef, updatedState.toFirestore());

        return true;
      });

      if (result) {
        log.info('✅ Successfully purchased avatar: $avatarId for user: $currentUserId');
      }

      return result;
    } catch (e, stackTrace) {
      log.severe('❌ Failed to purchase avatar $avatarId: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Equip an avatar for the current user
  Future<void> equipAvatar(String avatarId) async {
    if (currentUserId == null) {
      throw Exception('User must be authenticated to equip avatars');
    }

    // Check if user owns this avatar
    if (!doesUserOwnAvatar(avatarId)) {
      throw Exception('User does not own avatar: $avatarId');
    }

    try {
      // Use a transaction to update both user state and ownership records
      await _firestore.runTransaction((transaction) async {
        // PHASE 1: ALL READS FIRST
        final userStateRef = _firestore.collection(_userAvatarStatesCollection).doc(currentUserId);
        final ownershipRef = _firestore.collection(_userAvatarOwnershipsCollection).doc('${currentUserId}_$avatarId');
        
        // Read current user state
        final userStateSnapshot = await transaction.get(userStateRef);
        if (!userStateSnapshot.exists) {
          throw Exception('User state not found');
        }
        final currentState = FirebaseAvatarState.fromFirestore(userStateSnapshot);
        
        // Read current avatar ownership
        final ownershipSnapshot = await transaction.get(ownershipRef);
        UserAvatarOwnership? currentOwnership;
        if (ownershipSnapshot.exists) {
          currentOwnership = UserAvatarOwnership.fromFirestore(ownershipSnapshot);
        }
        
        // Read previous equipped avatar ownership (if any)
        UserAvatarOwnership? previousOwnership;
        DocumentReference? previousOwnershipRef;
        if (currentState.equippedAvatarId != null && currentState.equippedAvatarId != avatarId) {
          previousOwnershipRef = _firestore.collection(_userAvatarOwnershipsCollection)
              .doc('${currentUserId}_${currentState.equippedAvatarId}');
          final previousOwnershipSnapshot = await transaction.get(previousOwnershipRef);
          
          if (previousOwnershipSnapshot.exists) {
            previousOwnership = UserAvatarOwnership.fromFirestore(previousOwnershipSnapshot);
          }
        }

        // PHASE 2: ALL WRITES SECOND
        // Update user state with new equipped avatar
        final updatedState = currentState.copyWith(
          equippedAvatarId: avatarId,
          lastUpdate: DateTime.now(),
        );
        transaction.set(userStateRef, updatedState.toFirestore());

        // Update current avatar ownership to mark as equipped and increment usage
        if (currentOwnership != null) {
          final updatedOwnership = currentOwnership.copyWith(
            isEquipped: true,
            timesUsed: currentOwnership.timesUsed + 1,
            lastUsed: DateTime.now(),
          );
          transaction.set(ownershipRef, updatedOwnership.toFirestore());
        }

        // Unequip previously equipped avatar
        if (previousOwnership != null && previousOwnershipRef != null) {
          final unequippedOwnership = previousOwnership.copyWith(isEquipped: false);
          transaction.set(previousOwnershipRef, unequippedOwnership.toFirestore());
        }
      });

      log.info('✅ Successfully equipped avatar: $avatarId for user: $currentUserId');
    } catch (e, stackTrace) {
      log.severe('❌ Failed to equip avatar $avatarId: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Update avatar customizations
  Future<void> updateAvatarCustomizations(String avatarId, Map<String, dynamic> customizations) async {
    if (currentUserId == null) {
      throw Exception('User must be authenticated to customize avatars');
    }

    if (!doesUserOwnAvatar(avatarId)) {
      throw Exception('User does not own avatar: $avatarId');
    }

    try {
      final ownershipRef = _firestore.collection(_userAvatarOwnershipsCollection)
          .doc('${currentUserId}_$avatarId');
      
      await ownershipRef.update({
        'customizations': customizations,
        'lastUsed': Timestamp.fromDate(DateTime.now()),
      });

      log.info('✅ Updated customizations for avatar: $avatarId');
    } catch (e, stackTrace) {
      log.severe('❌ Failed to update avatar customizations: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Get avatar customizations for user
  Map<String, dynamic> getAvatarCustomizations(String avatarId) {
    if (currentUserId == null) return {};
    final ownership = _ownershipCache['${currentUserId}_$avatarId'];
    return ownership?.customizations ?? {};
  }

  /// Ensure default avatars exist in Firestore
  Future<void> _ensureDefaultAvatarsExist() async {
    final existingAvatars = await _firestore.collection(_avatarsCollection).limit(1).get();
    
    if (existingAvatars.docs.isEmpty) {
      log.info('🎯 Creating default avatars in Firestore');
      
      final defaultAvatars = [
        FirebaseAvatar(
          avatarId: 'mummy_coach',
          name: 'Mummy Coach',
          description: 'Ancient fitness wisdom wrapped in mystery. The original Solar Vita coach with timeless appeal.',
          rivAssetPath: 'assets/rive/mummy.riv',
          availableAnimations: ['Idle', 'Jump', 'Run', 'Attack'],
          customProperties: {
            'hasComplexSequence': true,
            'supportsTeleport': true,
            'sequenceOrder': ['Idle', 'Jump', 'Run', 'Attack', 'Jump'],
          },
          price: 0, // Free starter avatar
          rarity: 'common',
          isPurchasable: true,
          requiredAchievements: [],
          releaseDate: DateTime(2024, 1, 1),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        FirebaseAvatar(
          avatarId: 'quantum_coach',
          name: 'Quantum Coach',
          description: 'Advanced AI coach with quantum customization capabilities. Teleports between activities with style.',
          rivAssetPath: 'assets/rive/quantum_coach.riv',
          availableAnimations: ['Idle', 'jump', 'Act_Touch', 'startAct_Touch', 'win', 'Act_1'],
          customProperties: {
            'hasComplexSequence': true,
            'supportsTeleport': true,
            'hasCustomization': true,
            'customizationTypes': ['eyes', 'face', 'skin', 'clothing', 'accessories'],
            'sequenceOrder': ['Idle', 'jump', 'startAct_Touch', 'Act_Touch', 'win'],
          },
          price: 0, // Temporarily free while currency system is being developed
          rarity: 'legendary',
          isPurchasable: true,
          requiredAchievements: ['complete_first_week', 'eco_warrior'],
          releaseDate: DateTime(2024, 6, 1),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        // Note: Ninja Coach removed - no ninja.riv file exists
        // Only include avatars that have actual Rive files
      ];

      // Add default avatars to Firestore
      final batch = _firestore.batch();
      for (final avatar in defaultAvatars) {
        final docRef = _firestore.collection(_avatarsCollection).doc(avatar.avatarId);
        batch.set(docRef, avatar.toFirestore());
      }
      await batch.commit();
      
      log.info('✅ Default avatars created successfully');
    }
  }

  /// Ensure user state exists
  Future<void> _ensureUserStateExists() async {
    if (currentUserId == null) return;

    final userStateDoc = await _firestore
        .collection(_userAvatarStatesCollection)
        .doc(currentUserId)
        .get();

    if (!userStateDoc.exists) {
      log.info('🎯 Creating initial user state for: $currentUserId');
      
      try {
        // Try to give user the free mummy coach avatar if it exists
        final mummyAvatar = getAvatar('mummy_coach');
        if (mummyAvatar != null) {
          await purchaseAvatar('mummy_coach', metadata: {'purchaseSource': 'initial_grant', 'pricePaid': 0});
        } else {
          // Create basic user state without any avatars
          await _firestore
              .collection(_userAvatarStatesCollection)
              .doc(currentUserId!)
              .set({
            'userId': currentUserId!,
            'equippedAvatar': null,
            'lastUpdated': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          });
          log.info('✅ Created basic user state (no default avatars available)');
        }
      } catch (e) {
        log.warning('⚠️ Could not grant default avatar, creating basic state: $e');
        // Create basic user state as fallback
        await _firestore
            .collection(_userAvatarStatesCollection)
            .doc(currentUserId!)
            .set({
          'userId': currentUserId!,
          'equippedAvatar': null,
          'lastUpdated': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  /// Administrative method to add new avatar (for developers/admins)
  Future<void> addAvatar(FirebaseAvatar avatar) async {
    try {
      await _firestore
          .collection(_avatarsCollection)
          .doc(avatar.avatarId)
          .set(avatar.toFirestore());
      
      log.info('✅ Added new avatar: ${avatar.avatarId}');
    } catch (e, stackTrace) {
      log.severe('❌ Failed to add avatar: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Administrative method to update avatar (for developers/admins)
  Future<void> updateAvatar(FirebaseAvatar avatar) async {
    try {
      await _firestore
          .collection(_avatarsCollection)
          .doc(avatar.avatarId)
          .update(avatar.copyWith(updatedAt: DateTime.now()).toFirestore());
      
      log.info('✅ Updated avatar: ${avatar.avatarId}');
    } catch (e, stackTrace) {
      log.severe('❌ Failed to update avatar: $e', e, stackTrace);
      rethrow;
    }
  }
}