import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../../models/store/avatar_state.dart';
import '../../models/store/avatar_item.dart';
import '../../services/store/avatar_repository.dart';
import 'coin_provider.dart';

final log = Logger('AvatarStateProvider');

// Avatar repository provider
final avatarRepositoryProvider = Provider<AvatarRepository>((ref) {
  return AvatarRepository();
});

// Main avatar state notifier
class AvatarStateNotifier extends AsyncNotifier<UserAvatarState> {
  late AvatarRepository _avatarRepository;

  @override
  Future<UserAvatarState> build() async {
    _avatarRepository = ref.read(avatarRepositoryProvider);
    
    // Load and validate avatar state
    final state = await _avatarRepository.getAvatarState();
    final validatedState = await _avatarRepository.validateAndFixState(state);
    
    log.info('🎭 Avatar state loaded: ${validatedState.ownedAvatarsCount} owned, equipped: ${validatedState.equippedAvatarId}');
    
    return validatedState;
  }

  /// Purchase an avatar with coins
  Future<AvatarPurchaseResult> purchaseAvatar(AvatarItem avatar) async {
    try {
      final currentState = state.valueOrNull;
      if (currentState == null) {
        return AvatarPurchaseResult.failure('Avatar state not loaded');
      }

      // Check if already owned
      if (currentState.isAvatarOwned(avatar.id)) {
        return AvatarPurchaseResult.failure('Avatar already owned');
      }

      // Check if user can afford it
      final canAfford = ref.read(canAffordProvider((avatar.coinType, avatar.cost)));
      if (!canAfford) {
        return AvatarPurchaseResult.failure('Insufficient ${avatar.coinName}');
      }

      // Attempt to spend coins (only if avatar costs something)
      bool coinSuccess = true;
      if (avatar.cost > 0) {
        coinSuccess = await ref.read(coinBalanceProvider.notifier)
            .spendCoins(avatar.coinType, avatar.cost, 'Avatar: ${avatar.name}');
        
        if (!coinSuccess) {
          return AvatarPurchaseResult.failure('Failed to spend ${avatar.coinName}');
        }
      }

      // Purchase the avatar
      final result = await _avatarRepository.purchaseAvatar(avatar.id, currentState);
      
      if (result.success && result.newState != null) {
        // Update state
        state = AsyncValue.data(result.newState!);
        log.info('🛒 Successfully purchased ${avatar.name}');
      } else {
        // Refund coins if avatar purchase failed but coin spending succeeded (and avatar wasn't free)
        if (avatar.cost > 0 && coinSuccess) {
          await ref.read(coinBalanceProvider.notifier)
              .manualAwardCoins(avatar.coinType, avatar.cost, 'Refund: ${avatar.name}');
          log.warning('⚠️ Avatar purchase failed, refunded coins');
        }
      }

      return result;

    } catch (e) {
      log.warning('⚠️ Purchase error for ${avatar.name}: $e');
      return AvatarPurchaseResult.failure('Purchase failed: ${e.toString()}');
    }
  }

  /// Equip an avatar (if owned)
  Future<AvatarEquipResult> equipAvatar(String avatarId) async {
    try {
      final currentState = state.valueOrNull;
      if (currentState == null) {
        return AvatarEquipResult.failure('Avatar state not loaded');
      }

      // Attempt to equip
      final result = await _avatarRepository.equipAvatar(avatarId, currentState);
      
      if (result.success && result.newState != null) {
        // Update state
        state = AsyncValue.data(result.newState!);
        log.info('👕 Successfully equipped avatar: $avatarId');
      }

      return result;

    } catch (e) {
      log.warning('⚠️ Equip error for $avatarId: $e');
      return AvatarEquipResult.failure('Equip failed: ${e.toString()}');
    }
  }

  /// Unlock avatar without purchase (for rewards, etc.)
  Future<bool> unlockAvatar(String avatarId, String reason) async {
    try {
      final currentState = state.valueOrNull;
      if (currentState == null) return false;

      if (currentState.isAvatarOwned(avatarId)) {
        log.info('Avatar $avatarId already owned');
        return true;
      }

      final newState = currentState.unlockAvatar(avatarId);
      state = AsyncValue.data(newState);
      
      log.info('🎁 Unlocked avatar $avatarId: $reason');
      return true;

    } catch (e) {
      log.warning('⚠️ Failed to unlock avatar $avatarId: $e');
      return false;
    }
  }

  /// Get avatar statistics
  Map<String, dynamic> getAvatarStats() {
    final currentState = state.valueOrNull;
    if (currentState == null) return {};
    
    return _avatarRepository.getAvatarStats(currentState);
  }

  /// Refresh avatar state from repository
  Future<void> refresh() async {
    try {
      state = const AsyncValue.loading();
      final newState = await _avatarRepository.getAvatarState();
      final validatedState = await _avatarRepository.validateAndFixState(newState);
      state = AsyncValue.data(validatedState);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Reset avatar state to initial (for testing)
  Future<void> resetToInitial() async {
    try {
      final initialState = await _avatarRepository.resetToInitialState();
      state = AsyncValue.data(initialState);
      log.info('🔄 Reset avatar state to initial');
    } catch (e) {
      log.warning('⚠️ Failed to reset avatar state: $e');
    }
  }

  /// Clear all avatar data (for testing)
  Future<void> clearAllData() async {
    try {
      await _avatarRepository.clearAvatarData();
      final initialState = UserAvatarState.initial();
      state = AsyncValue.data(initialState);
      log.info('🗑️ Cleared all avatar data');
    } catch (e) {
      log.warning('⚠️ Failed to clear avatar data: $e');
    }
  }
}

// Main provider instance
final avatarStateProvider = AsyncNotifierProvider<AvatarStateNotifier, UserAvatarState>(
  () => AvatarStateNotifier(),
);

// Convenience providers for UI access

/// Get all avatars with current state applied
final avatarsWithStateProvider = Provider<List<AvatarItem>>((ref) {
  final avatarStateAsync = ref.watch(avatarStateProvider);
  final repository = ref.read(avatarRepositoryProvider);
  
  return avatarStateAsync.when(
    data: (state) => repository.getAvatarsWithState(state),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Get avatars filtered by access type with state
final avatarsByAccessTypeProvider = Provider.family<List<AvatarItem>, AvatarAccessType>((ref, accessType) {
  final avatarStateAsync = ref.watch(avatarStateProvider);
  final repository = ref.read(avatarRepositoryProvider);
  
  return avatarStateAsync.when(
    data: (state) => repository.getAvatarsByAccessType(accessType, state),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Get only owned avatars
final ownedAvatarsProvider = Provider<List<AvatarItem>>((ref) {
  final avatarStateAsync = ref.watch(avatarStateProvider);
  final repository = ref.read(avatarRepositoryProvider);
  
  return avatarStateAsync.when(
    data: (state) => repository.getOwnedAvatars(state),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Get currently equipped avatar
final equippedAvatarProvider = Provider<AvatarItem?>((ref) {
  final avatarStateAsync = ref.watch(avatarStateProvider);
  final repository = ref.read(avatarRepositoryProvider);
  
  return avatarStateAsync.when(
    data: (state) => repository.getEquippedAvatar(state),
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Check if specific avatar is owned
final isAvatarOwnedProvider = Provider.family<bool, String>((ref, avatarId) {
  final avatarStateAsync = ref.watch(avatarStateProvider);
  
  return avatarStateAsync.when(
    data: (state) => state.isAvatarOwned(avatarId),
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Check if specific avatar is equipped
final isAvatarEquippedProvider = Provider.family<bool, String>((ref, avatarId) {
  final avatarStateAsync = ref.watch(avatarStateProvider);
  
  return avatarStateAsync.when(
    data: (state) => state.isAvatarEquipped(avatarId),
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Get specific avatar with state
final avatarWithStateProvider = Provider.family<AvatarItem?, String>((ref, avatarId) {
  final avatarStateAsync = ref.watch(avatarStateProvider);
  final repository = ref.read(avatarRepositoryProvider);
  
  return avatarStateAsync.when(
    data: (state) => repository.getAvatarWithState(avatarId, state),
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Get owned avatars count
final ownedAvatarsCountProvider = Provider<int>((ref) {
  final avatarStateAsync = ref.watch(avatarStateProvider);
  
  return avatarStateAsync.when(
    data: (state) => state.ownedAvatarsCount,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Get avatar completion percentage
final avatarCompletionProvider = Provider<double>((ref) {
  final avatarStateAsync = ref.watch(avatarStateProvider);
  final allAvatars = ref.read(avatarsWithStateProvider);
  
  return avatarStateAsync.when(
    data: (state) {
      if (allAvatars.isEmpty) return 0.0;
      return (state.ownedAvatarsCount / allAvatars.length) * 100;
    },
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

/// Get avatar statistics
final avatarStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final avatarNotifier = ref.read(avatarStateProvider.notifier);
  return avatarNotifier.getAvatarStats();
});