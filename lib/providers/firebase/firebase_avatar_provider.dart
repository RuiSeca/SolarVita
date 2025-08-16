import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../../models/firebase/firebase_avatar.dart';
import '../../services/firebase/firebase_avatar_service.dart';
import '../../services/avatar/unified_avatar_bridge.dart';

final log = Logger('FirebaseAvatarProvider');

/// Provider for Firebase Avatar Service
final firebaseAvatarServiceProvider = Provider<FirebaseAvatarService>((ref) {
  final service = FirebaseAvatarService();
  
  // Force initialization immediately - don't wait for auth state
  // The service will handle null user gracefully and initialize when ready
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await service.initialize();
      log.info('✅ Firebase Avatar Service force initialized on startup');
    } catch (error) {
      log.severe('❌ Failed to force initialize Firebase Avatar Service: $error');
    }
  });
  
  // Also initialize immediately if user is already authenticated
  final authState = ref.read(authStateProvider);
  if (authState.hasValue && authState.value != null) {
    service.initialize().catchError((error) {
      log.severe('Failed to initialize Firebase Avatar Service immediately: $error');
    });
  }
  
  // Listen to auth state changes and reinitialize service when needed
  ref.listen(authStateProvider, (previous, next) {
    if (next.hasValue) {
      final user = next.value;
      if (user != null) {
        // User signed in, initialize service
        service.initialize().catchError((error) {
          log.severe('Failed to initialize Firebase Avatar Service: $error');
        });
      } else {
        // User signed out, dispose service
        service.dispose().catchError((error) {
          log.warning('Error disposing Firebase Avatar Service: $error');
        });
      }
    }
  });

  // Dispose service when provider is disposed
  ref.onDispose(() {
    service.dispose().catchError((error) {
      log.warning('Error disposing Firebase Avatar Service: $error');
    });
  });

  return service;
});

/// Provider for Firebase Auth state
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Provider for all available avatars from Firebase
final availableAvatarsProvider = StreamProvider<List<FirebaseAvatar>>((ref) {
  final service = ref.read(firebaseAvatarServiceProvider);
  return service.avatarsStream.map((avatars) {
    // If no avatars exist in Firebase, provide fallback mock avatars
    if (avatars.isEmpty) {
      log.info('💡 No avatars in Firebase, providing fallback avatars');
      return _createFallbackAvatars();
    }
    return avatars;
  });
});

/// Provider for current user's avatar state from Firebase
final firebaseAvatarStateProvider = StreamProvider<FirebaseAvatarState?>((ref) {
  final service = ref.read(firebaseAvatarServiceProvider);
  return service.userStateStream.handleError((error) {
    log.severe('❌ Avatar state stream error: $error');
    return null;
  });
});

/// Provider for current user's avatar ownerships from Firebase
final userAvatarOwnershipsProvider = StreamProvider<List<UserAvatarOwnership>>((ref) {
  final service = ref.read(firebaseAvatarServiceProvider);
  return service.ownershipsStream.handleError((error) {
    log.severe('❌ Ownerships stream error: $error');
    return <UserAvatarOwnership>[];
  });
});

/// Stable provider for currently equipped avatar that prevents cycling during loading
final equippedAvatarProvider = StateNotifierProvider<EquippedAvatarNotifier, FirebaseAvatar?>((ref) {
  return EquippedAvatarNotifier(ref);
});

/// Notifier that maintains stable equipped avatar state during provider loading cycles
class EquippedAvatarNotifier extends StateNotifier<FirebaseAvatar?> {
  final Ref _ref;
  FirebaseAvatar? _lastKnownAvatar;
  Timer? _refreshTimer;
  
  EquippedAvatarNotifier(this._ref) : super(null) {
    _initialize();
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
  
  void _initialize() {
    // Watch for changes in avatar state and available avatars
    _ref.listen(firebaseAvatarStateProvider, (previous, next) {
      _updateEquippedAvatar();
    });
    
    _ref.listen(availableAvatarsProvider, (previous, next) {
      _updateEquippedAvatar();
    });
    
    // Initial update
    _updateEquippedAvatar();
  }
  
  void _updateEquippedAvatar() {
    final avatarState = _ref.read(firebaseAvatarStateProvider);
    final availableAvatars = _ref.read(availableAvatarsProvider);
    
    FirebaseAvatar? newEquippedAvatar;
    
    // Only update if we have both avatar state and available avatars loaded
    if (avatarState.hasValue && availableAvatars.hasValue) {
      final stateValue = avatarState.value;
      final avatars = availableAvatars.value;
      
      if (avatars?.isNotEmpty == true) {
        if (stateValue?.equippedAvatarId != null) {
          newEquippedAvatar = avatars!.firstWhere(
            (avatar) => avatar.avatarId == stateValue!.equippedAvatarId,
            orElse: () => avatars.first,
          );
        } else {
          newEquippedAvatar = avatars!.first;
        }
        
        _lastKnownAvatar = newEquippedAvatar;
        log.info('🎭 STABLE: Updated equipped avatar to: ${newEquippedAvatar.avatarId}');
      }
    }
    
    // Determine the final avatar to use
    FirebaseAvatar? finalAvatar;
    if (newEquippedAvatar != null) {
      finalAvatar = newEquippedAvatar;
    } else if (_lastKnownAvatar != null) {
      finalAvatar = _lastKnownAvatar;
      log.info('🎭 STABLE: Using cached equipped avatar during loading: ${_lastKnownAvatar!.avatarId}');
    } else {
      // Only fall back to default if we have no cached avatar
      finalAvatar = _createFallbackAvatar();
      log.info('🎭 STABLE: Using fallback avatar: ${finalAvatar.avatarId}');
    }
    
    // Update the state if it's different
    if (state?.avatarId != finalAvatar?.avatarId) {
      state = finalAvatar;
      log.info('✅ EQUIPPED AVATAR STATE UPDATED: ${finalAvatar?.avatarId}');
    }
  }
  
  /// Force refresh equipped avatar state (for debugging sync issues)
  void forceRefresh() {
    log.info('🔄 FORCE REFRESH: Equipped avatar provider');
    _updateEquippedAvatar();
  }
}

/// Provider for owned avatars (with ownership details)
final ownedAvatarsProvider = Provider<List<AvatarWithOwnership>>((ref) {
  final avatars = ref.watch(availableAvatarsProvider);
  final ownerships = ref.watch(userAvatarOwnershipsProvider);
  
  return avatars.when(
    data: (avatarList) => ownerships.when(
      data: (ownershipList) {
        return avatarList
            .where((avatar) => 
              // Include if in ownership list OR is a free avatar
              ownershipList.any((ownership) => ownership.avatarId == avatar.avatarId) ||
              avatar.price == 0)
            .map((avatar) {
              // Try to find actual ownership record  
              UserAvatarOwnership? actualOwnership;
              try {
                actualOwnership = ownershipList.firstWhere((o) => o.avatarId == avatar.avatarId);
              } catch (e) {
                actualOwnership = null;
              }
              
              if (actualOwnership != null) {
                return AvatarWithOwnership(avatar: avatar, ownership: actualOwnership);
              } else {
                // Create placeholder ownership for free avatars
                final placeholderOwnership = UserAvatarOwnership(
                  userId: '', // Will be filled by service
                  avatarId: avatar.avatarId,
                  purchaseDate: DateTime.now(),
                  isEquipped: false,
                  customizations: {},
                  timesUsed: 0,
                  lastUsed: DateTime.now(),
                  metadata: {'type': 'free_avatar'},
                );
                return AvatarWithOwnership(avatar: avatar, ownership: placeholderOwnership);
              }
            })
            .toList();
      },
      loading: () => <AvatarWithOwnership>[],
      error: (_, __) => <AvatarWithOwnership>[],
    ),
    loading: () => <AvatarWithOwnership>[],
    error: (_, __) => <AvatarWithOwnership>[],
  );
});

/// Provider for purchasable avatars (not owned by user)
final purchasableAvatarsProvider = Provider<List<FirebaseAvatar>>((ref) {
  final avatars = ref.watch(availableAvatarsProvider);
  final ownerships = ref.watch(userAvatarOwnershipsProvider);
  
  return avatars.when(
    data: (avatarList) => ownerships.when(
      data: (ownershipList) {
        final ownedIds = ownershipList.map((o) => o.avatarId).toSet();
        return avatarList
            .where((avatar) => 
              avatar.isPurchasable && 
              !ownedIds.contains(avatar.avatarId) && 
              avatar.price > 0) // Exclude free avatars from purchasable list
            .toList();
      },
      loading: () => <FirebaseAvatar>[],
      error: (_, __) => <FirebaseAvatar>[],
    ),
    loading: () => <FirebaseAvatar>[],
    error: (_, __) => <FirebaseAvatar>[],
  );
});

/// Provider for avatar purchase functionality
final avatarPurchaseProvider = Provider<AvatarPurchaseService>((ref) {
  final service = ref.read(firebaseAvatarServiceProvider);
  return AvatarPurchaseService(service);
});

/// Provider for avatar equipment functionality
final avatarEquipmentProvider = Provider<AvatarEquipmentService>((ref) {
  final service = ref.read(firebaseAvatarServiceProvider);
  return AvatarEquipmentService(service);
});

/// Provider for avatar customization functionality
final avatarCustomizationProvider = Provider<AvatarCustomizationService>((ref) {
  final service = ref.read(firebaseAvatarServiceProvider);
  return AvatarCustomizationService(service);
});

/// Combined avatar with ownership information
class AvatarWithOwnership {
  final FirebaseAvatar avatar;
  final UserAvatarOwnership ownership;

  const AvatarWithOwnership({
    required this.avatar,
    required this.ownership,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvatarWithOwnership &&
          runtimeType == other.runtimeType &&
          avatar == other.avatar &&
          ownership == other.ownership;

  @override
  int get hashCode => avatar.hashCode ^ ownership.hashCode;

  @override
  String toString() => 'AvatarWithOwnership{avatar: ${avatar.avatarId}, equipped: ${ownership.isEquipped}}';
}

/// Service for avatar purchase operations
class AvatarPurchaseService {
  final FirebaseAvatarService _service;

  const AvatarPurchaseService(this._service);

  Future<bool> purchaseAvatar(String avatarId, {Map<String, dynamic>? metadata}) async {
    try {
      log.info('🛒 Attempting to purchase avatar: $avatarId');
      final result = await _service.purchaseAvatar(avatarId, metadata: metadata);
      
      if (result) {
        log.info('✅ Successfully purchased avatar: $avatarId');
      } else {
        log.warning('⚠️ Avatar purchase failed or already owned: $avatarId');
      }
      
      return result;
    } catch (e) {
      log.severe('❌ Error purchasing avatar $avatarId: $e');
      rethrow;
    }
  }

  bool canPurchase(FirebaseAvatar avatar, List<UserAvatarOwnership> ownerships) {
    // Check if already owned (including free avatars)
    final alreadyOwned = ownerships.any((o) => o.avatarId == avatar.avatarId) || avatar.price == 0;
    if (alreadyOwned) return false;

    // Check if purchasable
    if (!avatar.isPurchasable) return false;

    // Free avatars cannot be purchased, they are auto-obtained
    if (avatar.price == 0) return false;

    // Add additional checks here (user coins, achievements, etc.)
    return true;
  }
}

/// Service for avatar equipment operations
class AvatarEquipmentService {
  final FirebaseAvatarService _service;
  final UnifiedAvatarBridge? _bridge;

  const AvatarEquipmentService(this._service, [this._bridge]);

  Future<void> equipAvatar(String avatarId) async {
    try {
      log.info('👕 Attempting to equip avatar: $avatarId');
      
      // Use unified bridge if available, otherwise use Firebase service directly
      if (_bridge != null) {
        await _bridge.equipAvatar(avatarId);
        log.info('✅ Successfully equipped avatar via unified bridge: $avatarId');
      } else {
        await _service.equipAvatar(avatarId);
        log.info('✅ Successfully equipped avatar via Firebase service: $avatarId');
      }
    } catch (e) {
      log.severe('❌ Error equipping avatar $avatarId: $e');
      rethrow;
    }
  }

  bool canEquip(String avatarId, List<UserAvatarOwnership> ownerships, List<FirebaseAvatar> avatars) {
    // Check if user has ownership record OR if it's a free avatar
    final hasOwnership = ownerships.any((o) => o.avatarId == avatarId);
    if (hasOwnership) return true;
    
    // Check if it's a free avatar
    try {
      final avatar = avatars.firstWhere((a) => a.avatarId == avatarId);
      return avatar.price == 0;
    } catch (e) {
      return false;
    }
  }
}

/// Service for avatar customization operations
class AvatarCustomizationService {
  final FirebaseAvatarService _service;

  const AvatarCustomizationService(this._service);

  Future<void> updateCustomizations(String avatarId, Map<String, dynamic> customizations) async {
    try {
      log.info('🎨 Updating customizations for avatar: $avatarId');
      await _service.updateAvatarCustomizations(avatarId, customizations);
      log.info('✅ Successfully updated customizations for: $avatarId');
    } catch (e) {
      log.severe('❌ Error updating customizations for $avatarId: $e');
      rethrow;
    }
  }

  Map<String, dynamic> getCustomizations(String avatarId) {
    return _service.getAvatarCustomizations(avatarId);
  }

  bool supportsCustomization(FirebaseAvatar avatar) {
    return avatar.customProperties['hasCustomization'] == true;
  }

  List<String> getCustomizationTypes(FirebaseAvatar avatar) {
    final types = avatar.customProperties['customizationTypes'];
    if (types is List) {
      return List<String>.from(types);
    }
    return [];
  }
}

/// Create fallback avatar for error cases
FirebaseAvatar _createFallbackAvatar() {
  return FirebaseAvatar(
    avatarId: 'mummy_coach',
    name: 'Mummy Coach',
    description: 'Default avatar',
    rivAssetPath: 'assets/rive/mummy.riv',
    availableAnimations: ['Idle', 'Jump', 'Run', 'Attack'],
    customProperties: {
      'hasComplexSequence': true,
      'supportsTeleport': true,
    },
    price: 0,
    rarity: 'common',
    isPurchasable: false,
    requiredAchievements: [],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

/// Create fallback avatars when Firebase collection is empty
List<FirebaseAvatar> _createFallbackAvatars() {
  return [
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
    // Note: Ninja Coach removed - no ninja.riv file exists
    // Only include avatars that have actual Rive files
  ];
}