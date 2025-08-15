import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import '../../models/firebase/firebase_avatar.dart';

final log = Logger('FirebaseAvatarService');

/// Service for managing avatar data in Firebase Firestore
/// Handles ownership, purchases, customizations, and real-time synchronization
class FirebaseAvatarService {
  static const String _avatarsCollection = 'avatars'; // Collection name matches Firestore
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
  Stream<List<UserAvatarOwnership>> get ownershipsStream {
    // Don't emit immediately on stream access - let the listener handle it
    // This prevents confusion between initial cache and real Firebase data
    log.info('📤 Ownerships stream accessed - listener should provide data');
    return _ownershipsController.stream;
  }

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Initialize the service and start listening to real-time updates
  Future<void> initialize() async {
    if (currentUserId == null) {
      log.warning('⚠️ No authenticated user - cannot initialize Firebase Avatar Service');
      return;
    }

    log.info('🚀 Initializing Firebase Avatar Service for user: $currentUserId');
    
    // Immediate debug test - try to fetch avatars right now
    try {
      log.info('🔬 DEBUG: Testing immediate avatar collection access...');
      final testSnapshot = await _firestore.collection(_avatarsCollection).limit(1).get();
      log.info('🔬 DEBUG: Test fetch result - docs found: ${testSnapshot.docs.length}');
      if (testSnapshot.docs.isNotEmpty) {
        log.info('🔬 DEBUG: First doc ID: ${testSnapshot.docs.first.id}');
        log.info('🔬 DEBUG: First doc data: ${testSnapshot.docs.first.data()}');
      }
    } catch (debugError) {
      log.severe('🔬 DEBUG: Test fetch failed: $debugError');
    }

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

      // Ensure ownership records exist for all free avatars
      await _ensureFreeAvatarOwnerships();
      
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
    if (!_ownershipsController.isClosed) {
      _ownershipsController.add(<UserAvatarOwnership>[]);
      log.info('📤 Emitted initial empty ownership state');
    }
    if (!_userStateController.isClosed) {
      _userStateController.add(null);
      log.info('📤 Emitted initial null user state');
    }
    if (!_avatarsController.isClosed) {
      _avatarsController.add(<FirebaseAvatar>[]);
      log.info('📤 Emitted initial empty avatars state');
    }

    // Listen to all avatars
    log.info('🎯 Starting avatars listener for collection: $_avatarsCollection');
    _avatarsSubscription = _firestore
        .collection(_avatarsCollection)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen(
      (snapshot) {
        log.info('📦 Avatars snapshot received - docs: ${snapshot.docs.length}');
        
        final avatars = <FirebaseAvatar>[];
        for (final doc in snapshot.docs) {
          try {
            final avatar = FirebaseAvatar.fromFirestore(doc);
            avatars.add(avatar);
            log.info('✅ Loaded avatar: ${avatar.avatarId} - ${avatar.name}');
          } catch (e) {
            log.severe('❌ Error parsing avatar document ${doc.id}: $e');
            log.info('📄 Raw avatar data: ${doc.data()}');
          }
        }
        
        // Update cache
        _avatarCache.clear();
        for (final avatar in avatars) {
          _avatarCache[avatar.avatarId] = avatar;
        }
        
        _avatarsController.add(avatars);
        log.info('🔄 Avatars updated: ${avatars.length} total successfully loaded');
      },
      onError: (error) {
        log.severe('❌ Error listening to avatars: $error');
        // Emit empty list on error to prevent indefinite loading
        _avatarsController.add(<FirebaseAvatar>[]);
      },
    );
    
    // Also add immediate manual fetch for avatars to speed up initial load
    Future.microtask(() async {
      try {
        log.info('🚀 Immediate avatar fetch for faster load');
        final snapshot = await _firestore
            .collection(_avatarsCollection)
            .orderBy('createdAt', descending: false)
            .get();
        
        log.info('🔍 Manual avatar fetch found ${snapshot.docs.length} avatar docs');
        
        if (snapshot.docs.isNotEmpty) {
          final avatars = <FirebaseAvatar>[];
          for (final doc in snapshot.docs) {
            try {
              final avatar = FirebaseAvatar.fromFirestore(doc);
              avatars.add(avatar);
              log.info('⚡ Manual load avatar: ${avatar.avatarId} - ${avatar.name}');
            } catch (e) {
              log.severe('❌ Error in manual avatar parse ${doc.id}: $e');
            }
          }
          
          // Update cache
          _avatarCache.clear();
          for (final avatar in avatars) {
            _avatarCache[avatar.avatarId] = avatar;
          }
          
          _avatarsController.add(avatars);
          log.info('⚡ Manual avatar fetch successful: ${avatars.length} loaded');
        }
      } catch (e) {
        log.severe('❌ Manual avatar fetch failed: $e');
      }
    });

    // Listen to user's avatar ownerships
    log.info('🎯 Starting ownership listener for user: $currentUserId');
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

    // Add a timeout to detect if the listener never fires, then try manual fetch
    Timer(const Duration(seconds: 1), () async {
      if (!_ownershipsController.isClosed) {
        log.warning('⚠️ Ownership listener timeout (1s) - trying manual fetch');
        try {
          final snapshot = await _firestore
              .collection(_userAvatarOwnershipsCollection)
              .where('userId', isEqualTo: currentUserId)
              .get();
          
          log.info('🔍 Manual fetch found ${snapshot.docs.length} ownership docs');
          
          final ownerships = snapshot.docs
              .map((doc) => UserAvatarOwnership.fromFirestore(doc))
              .toList();
          
          // Update cache
          _ownershipCache.clear();
          for (final ownership in ownerships) {
            _ownershipCache['${ownership.userId}_${ownership.avatarId}'] = ownership;
          }
          
          _ownershipsController.add(ownerships);
          log.info('✅ Manual ownership fetch successful: ${ownerships.length} owned');
        } catch (e) {
          log.severe('❌ Manual ownership fetch failed: $e');
          _ownershipsController.add(<UserAvatarOwnership>[]);
        }
      }
    });
    
    // Also add immediate manual fetch to speed up initial load
    Future.microtask(() async {
      if (currentUserId != null) {
        try {
          log.info('🚀 Immediate ownership fetch for faster load');
          final snapshot = await _firestore
              .collection(_userAvatarOwnershipsCollection)
              .where('userId', isEqualTo: currentUserId)
              .get();
          
          log.info('⚡ Immediate fetch found ${snapshot.docs.length} ownership docs');
          
          final ownerships = snapshot.docs
              .map((doc) => UserAvatarOwnership.fromFirestore(doc))
              .toList();
          
          // Update cache
          _ownershipCache.clear();
          for (final ownership in ownerships) {
            _ownershipCache['${ownership.userId}_${ownership.avatarId}'] = ownership;
          }
          
          _ownershipsController.add(ownerships);
          log.info('⚡ Immediate ownership fetch complete: ${ownerships.length} owned');
        } catch (e) {
          log.warning('⚠️ Immediate ownership fetch failed: $e');
          // Emit empty list on error to unblock the UI
          _ownershipsController.add(<UserAvatarOwnership>[]);
        }
      }
    });

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
    
    // Check cache first
    if (_ownershipCache.containsKey('${currentUserId}_$avatarId')) {
      log.info('✅ Avatar $avatarId found in ownership cache');
      return true;
    }
    
    // For free avatars (price = 0), auto-create ownership and consider them owned
    final avatar = _avatarCache[avatarId];
    if (avatar != null && avatar.price == 0) {
      log.info('🆓 Avatar $avatarId is free (price=0), considering owned and auto-creating ownership record');
      // Create ownership record asynchronously (don't wait for it)
      _createOwnershipForFreeAvatar(avatarId);
      return true; // Return true immediately for free avatars
    }
    
    // For paid avatars, also check if they might be free but not cached yet
    // This handles the case where avatar data hasn't loaded yet
    if (avatar == null) {
      log.warning('⚠️ Avatar $avatarId not found in cache, cannot determine ownership');
      // For safety, assume ownership if we can't determine the price
      // The customization will fail gracefully if user doesn't actually own it
      return true;
    }
    
    log.info('❌ Avatar $avatarId is paid (price=${avatar.price}) and not in ownership cache');
    return false;
  }

  /// Get user's equipped avatar
  FirebaseAvatar? getEquippedAvatar() {
    final equippedId = _currentUserState?.equippedAvatarId;
    if (equippedId == null) return null;
    return _avatarCache[equippedId];
  }
  
  /// Debug method to check avatar system state
  Map<String, dynamic> getDebugInfo() {
    return {
      'currentUserId': currentUserId,
      'userState': _currentUserState?.toString(),
      'equippedAvatarId': _currentUserState?.equippedAvatarId,
      'avatarsInCache': _avatarCache.keys.toList(),
      'ownershipsInCache': _ownershipCache.keys.toList(),
      'streamListening': {
        'avatars': _avatarsSubscription?.isPaused == false,
        'ownerships': _ownershipsSubscription?.isPaused == false,
        'userState': _userStateSubscription?.isPaused == false,
      },
    };
  }

  /// Ensure ownership records exist for all free avatars
  Future<void> _ensureFreeAvatarOwnerships() async {
    if (currentUserId == null) return;
    
    try {
      log.info('🆓 Ensuring ownership records for all free avatars...');
      
      final freeAvatars = _avatarCache.values.where((avatar) => avatar.price == 0).toList();
      
      for (final avatar in freeAvatars) {
        await _createOwnershipForFreeAvatar(avatar.avatarId);
      }
      
      log.info('✅ Completed free avatar ownership check for ${freeAvatars.length} free avatars');
    } catch (e) {
      log.warning('⚠️ Error ensuring free avatar ownerships: $e');
    }
  }

  /// Create ownership record for free avatar
  Future<void> _createOwnershipForFreeAvatar(String avatarId) async {
    if (currentUserId == null) return;
    
    final ownershipId = '${currentUserId}_$avatarId';
    
    // Check if already exists to avoid duplicate creation
    if (_ownershipCache.containsKey(ownershipId)) {
      log.info('🆓 Ownership already exists for free avatar: $avatarId');
      return;
    }
    
    final ownership = UserAvatarOwnership(
      userId: currentUserId!,
      avatarId: avatarId,
      purchaseDate: DateTime.now(),
      isEquipped: false,
      customizations: {},
      timesUsed: 0,
      lastUsed: DateTime.now(),
      metadata: {'type': 'free_avatar', 'auto_granted': true},
    );

    try {
      await _firestore
          .collection(_userAvatarOwnershipsCollection)
          .doc(ownershipId)
          .set(ownership.toFirestore());
      
      // Update cache
      _ownershipCache[ownershipId] = ownership;
      log.info('✅ Created ownership record for free avatar: $avatarId');
      
      // Emit updated ownerships list to refresh UI
      final allOwnerships = _ownershipCache.values
          .where((ownership) => ownership.userId == currentUserId)
          .toList();
      _ownershipsController.add(allOwnerships);
      log.info('🔄 Refreshed ownerships stream after free avatar creation');
    } catch (e) {
      log.warning('⚠️ Failed to create ownership for free avatar $avatarId: $e');
    }
  }

  /// Ensure ownership record exists for free avatar (synchronous creation)
  Future<void> _ensureOwnershipForFreeAvatar(String avatarId) async {
    if (currentUserId == null) return;
    
    final ownershipId = '${currentUserId}_$avatarId';
    
    // Check if already exists in cache
    if (_ownershipCache.containsKey(ownershipId)) {
      log.info('🆓 Ownership already cached for free avatar: $avatarId');
      return;
    }
    
    // Check if exists in Firestore
    try {
      final ownershipDoc = await _firestore
          .collection(_userAvatarOwnershipsCollection)
          .doc(ownershipId)
          .get();
      
      if (ownershipDoc.exists) {
        final ownership = UserAvatarOwnership.fromFirestore(ownershipDoc);
        _ownershipCache[ownershipId] = ownership;
        log.info('🆓 Found existing ownership in Firestore for free avatar: $avatarId');
        return;
      }
      
      // Create new ownership record
      final ownership = UserAvatarOwnership(
        userId: currentUserId!,
        avatarId: avatarId,
        purchaseDate: DateTime.now(),
        isEquipped: false,
        customizations: {},
        timesUsed: 0,
        lastUsed: DateTime.now(),
        metadata: {'type': 'free_avatar', 'auto_granted': true},
      );

      await _firestore
          .collection(_userAvatarOwnershipsCollection)
          .doc(ownershipId)
          .set(ownership.toFirestore());
      
      // Update cache
      _ownershipCache[ownershipId] = ownership;
      log.info('✅ Created and cached ownership record for free avatar: $avatarId');
      
      // Emit updated ownerships list to refresh UI
      final allOwnerships = _ownershipCache.values
          .where((ownership) => ownership.userId == currentUserId)
          .toList();
      _ownershipsController.add(allOwnerships);
      log.info('🔄 Refreshed ownerships stream after ensuring free avatar ownership');
      
    } catch (e) {
      log.warning('⚠️ Failed to ensure ownership for free avatar $avatarId: $e');
      // Don't rethrow - this will be handled gracefully by calling code
    }
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

    // Check if user already owns this avatar (with actual ownership record)
    if (_ownershipCache.containsKey('${currentUserId}_$avatarId')) {
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

    // Note: solar_coach now uses direct RIV loading - no longer blocked

    // Check if user owns this avatar or if it's a free avatar
    if (!doesUserOwnAvatar(avatarId)) {
      throw Exception('User does not own avatar: $avatarId');
    }
    
    // For free avatars, ensure ownership record exists
    final avatar = _avatarCache[avatarId];
    if (avatar != null && avatar.price == 0 && !_ownershipCache.containsKey('${currentUserId}_$avatarId')) {
      log.info('🎁 Creating ownership record for free avatar: $avatarId');
      await _createOwnershipForFreeAvatar(avatarId);
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
      
      // Each avatar now has isolated caching - no need to clear other avatars
      log.info('🔧 Avatar equipped with isolated caching - no cross-avatar interference');
      
      // CRITICAL: Force refresh providers to ensure immediate state sync
      await _forceRefreshProviders(avatarId);
      
      // Force a refresh of the streams to ensure UI updates immediately
      try {
        // Wait a moment for Firestore to propagate
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Trigger stream updates by reading the documents again
        final userStateDoc = await _firestore.collection(_userAvatarStatesCollection).doc(currentUserId).get();
        if (userStateDoc.exists) {
          final updatedState = FirebaseAvatarState.fromFirestore(userStateDoc);
          _currentUserState = updatedState;
          _userStateController.add(updatedState);
          log.info('🔄 Force-refreshed user state stream after equip: equipped=${updatedState.equippedAvatarId}');
        }
        
        // Also refresh ownerships
        final ownershipDocs = await _firestore
            .collection(_userAvatarOwnershipsCollection)
            .where('userId', isEqualTo: currentUserId)
            .get();
        
        final ownerships = ownershipDocs.docs
            .map((doc) => UserAvatarOwnership.fromFirestore(doc))
            .toList();
        
        _ownershipCache.clear();
        for (final ownership in ownerships) {
          _ownershipCache['${ownership.userId}_${ownership.avatarId}'] = ownership;
        }
        
        _ownershipsController.add(ownerships);
        log.info('🔄 Force-refreshed ownerships stream after equip: ${ownerships.length} ownerships');
        
      } catch (refreshError) {
        log.warning('⚠️ Error force-refreshing streams after equip: $refreshError');
      }
    } catch (e, stackTrace) {
      log.severe('❌ Failed to equip avatar $avatarId: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Update avatar customizations with better error handling and local caching
  Future<void> updateAvatarCustomizations(String avatarId, Map<String, dynamic> customizations) async {
    if (currentUserId == null) {
      log.warning('⚠️ User must be authenticated to customize avatars');
      return; // Don't throw, just return silently to prevent UI freezing
    }

    log.info('💾 SAVE DEBUG: Starting updateAvatarCustomizations for $avatarId');
    log.info('💾 SAVE DEBUG: Customizations: $customizations');

    // Check ownership and ensure it exists for free avatars
    if (!doesUserOwnAvatar(avatarId)) {
      log.warning('⚠️ User does not own avatar: $avatarId');
      return; // Don't throw, just return silently
    }

    // For free avatars, ensure ownership record exists synchronously
    final avatar = _avatarCache[avatarId];
    if (avatar != null && avatar.price == 0) {
      await _ensureOwnershipForFreeAvatar(avatarId);
    }

    try {
      final ownershipKey = '${currentUserId}_$avatarId';
      
      // Update local cache immediately for responsive UI
      if (_ownershipCache.containsKey(ownershipKey)) {
        final currentOwnership = _ownershipCache[ownershipKey]!;
        _ownershipCache[ownershipKey] = currentOwnership.copyWith(
          customizations: customizations,
          lastUsed: DateTime.now(),
        );
        log.info('✅ Updated local cache for avatar: $avatarId');
      } else {
        log.warning('⚠️ Ownership record not found in cache for $avatarId, attempting to create...');
        await _ensureOwnershipForFreeAvatar(avatarId);
        
        // Try again after creating ownership
        if (_ownershipCache.containsKey(ownershipKey)) {
          final currentOwnership = _ownershipCache[ownershipKey]!;
          _ownershipCache[ownershipKey] = currentOwnership.copyWith(
            customizations: customizations,
            lastUsed: DateTime.now(),
          );
          log.info('✅ Created ownership and updated cache for avatar: $avatarId');
        }
      }
      
      // Update Firestore with timeout and retry
      final ownershipRef = _firestore.collection(_userAvatarOwnershipsCollection)
          .doc(ownershipKey);
      
      await ownershipRef.update({
        'customizations': customizations,
        'lastUsed': Timestamp.fromDate(DateTime.now()),
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          log.warning('⚠️ Timeout updating customizations for avatar: $avatarId');
          // Don't throw on timeout - local cache is already updated
        },
      );

      log.info('✅ SAVE SUCCESS: Updated Firestore customizations for avatar: $avatarId');
    } catch (e) {
      log.warning('⚠️ Failed to update avatar customizations (local cache preserved): $e');
      // Don't rethrow - this prevents UI freezing and local cache is still updated
    }
  }
  
  /// Batch update multiple avatar customizations for better performance
  Future<void> batchUpdateCustomizations(Map<String, Map<String, dynamic>> avatarCustomizations) async {
    if (currentUserId == null || avatarCustomizations.isEmpty) {
      return;
    }

    try {
      final batch = _firestore.batch();
      final timestamp = Timestamp.fromDate(DateTime.now());
      
      for (final entry in avatarCustomizations.entries) {
        final avatarId = entry.key;
        final customizations = entry.value;
        
        if (!doesUserOwnAvatar(avatarId)) continue;
        
        final ownershipRef = _firestore.collection(_userAvatarOwnershipsCollection)
            .doc('${currentUserId}_$avatarId');
        
        batch.update(ownershipRef, {
          'customizations': customizations,
          'lastUsed': timestamp,
        });
        
        // Update local cache
        final ownershipKey = '${currentUserId}_$avatarId';
        if (_ownershipCache.containsKey(ownershipKey)) {
          final currentOwnership = _ownershipCache[ownershipKey]!;
          _ownershipCache[ownershipKey] = currentOwnership.copyWith(
            customizations: customizations,
            lastUsed: DateTime.now(),
          );
        }
      }
      
      await batch.commit().timeout(const Duration(seconds: 15));
      log.info('✅ Batch updated customizations for ${avatarCustomizations.length} avatars');
    } catch (e) {
      log.warning('⚠️ Failed to batch update customizations: $e');
      // Don't rethrow - local cache is updated
    }
  }

  /// Get avatar customizations for user
  Map<String, dynamic> getAvatarCustomizations(String avatarId) {
    if (currentUserId == null) return {};
    final ownership = _ownershipCache['${currentUserId}_$avatarId'];
    return ownership?.customizations ?? {};
  }

  /// Public method to force create default avatars (for debug/admin use)
  Future<void> forceCreateDefaultAvatars() async {
    await _ensureDefaultAvatarsExist();
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
          requiredAchievements: [], // Made free for demo purposes
          releaseDate: DateTime(2024, 6, 1),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        FirebaseAvatar(
          avatarId: 'director_coach',
          name: 'Director Coach',
          description: 'Charismatic fitness director with Hollywood style. Commands your workout like an epic movie scene. Features full customization and professional animations.',
          rivAssetPath: 'assets/rive/director_coach.riv',
          availableAnimations: ['Idle', 'walk', 'walk 2', 'jump', 'Act_1', 'Act_Touch', 'starAct_Touch', 'win'],
          customProperties: {
            'hasComplexSequence': true,
            'supportsTeleport': false,
            'hasCustomization': true,
            'customizationTypes': ['eyes', 'face', 'skin', 'clothing', 'accessories', 'hair'],
            'sequenceOrder': ['Idle', 'walk', 'jump', 'Act_1'],
            'theme': 'movie_director',
            'eyeColors': 10, // eye 0 through eye 9
            'useStateMachine': true,
          },
          price: 0, // Free for testing
          rarity: 'legendary', // Upgraded to legendary due to customization features
          isPurchasable: true,
          requiredAchievements: [],
          releaseDate: DateTime(2024, 8, 14),
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
            'equippedAvatarId': null,
            'lastUpdate': FieldValue.serverTimestamp(),
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
  
  /// Force refresh all providers to ensure immediate state synchronization
  Future<void> _forceRefreshProviders(String avatarId) async {
    try {
      log.info('🔄 Force refreshing providers for equipped avatar: $avatarId');
      
      // Force refresh all streams to ensure UI updates immediately
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Update the current user state immediately in cache
      if (_currentUserState != null) {
        _currentUserState = _currentUserState!.copyWith(
          equippedAvatarId: avatarId,
          lastUpdate: DateTime.now(),
        );
        _userStateController.add(_currentUserState!);
        log.info('✅ Updated local user state cache with equipped avatar: $avatarId');
      }
      
      // Force update ownership cache to mark correct avatar as equipped
      final ownershipKey = '${currentUserId}_$avatarId';
      if (_ownershipCache.containsKey(ownershipKey)) {
        _ownershipCache[ownershipKey] = _ownershipCache[ownershipKey]!.copyWith(
          isEquipped: true,
          lastUsed: DateTime.now(),
        );
      }
      
      // Unequip all other avatars in local cache
      for (final key in _ownershipCache.keys) {
        if (key != ownershipKey && key.startsWith('${currentUserId}_')) {
          _ownershipCache[key] = _ownershipCache[key]!.copyWith(
            isEquipped: false,
            lastUsed: DateTime.now(),
          );
        }
      }
      
      // Emit updated ownerships
      _ownershipsController.add(_ownershipCache.values.toList());
      
      log.info('✅ Successfully refreshed providers for equipped avatar: $avatarId');
      
    } catch (e) {
      log.warning('⚠️ Failed to refresh providers: $e');
      // Don\'t rethrow - equipment still succeeded
    }
  }
}