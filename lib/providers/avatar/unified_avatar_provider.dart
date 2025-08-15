import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../../services/avatar/unified_avatar_bridge.dart';
import '../firebase/firebase_avatar_provider.dart';

final log = Logger('UnifiedAvatarProvider');

/// Provider for the unified avatar bridge service
final unifiedAvatarBridgeProvider = Provider<UnifiedAvatarBridge>((ref) {
  final firebaseAvatarService = ref.watch(firebaseAvatarServiceProvider);
  return UnifiedAvatarBridge(firebaseAvatarService);
});

/// Provider for unified equipped avatar state
/// This is the single source of truth for equipped avatar across the app
final unifiedEquippedAvatarProvider = StreamProvider<String?>((ref) async* {
  try {
    log.info('🎯 Initializing unified equipped avatar provider...');
    
    final bridge = ref.watch(unifiedAvatarBridgeProvider);
    
    // Initialize the bridge
    await bridge.initialize();
    
    // Yield the stream
    yield* bridge.equippedAvatarStream;
    
  } catch (e, stackTrace) {
    log.severe('❌ Error in unified equipped avatar provider: $e', e, stackTrace);
    
    // Fallback to Firebase provider if unified bridge fails
    final firebaseState = ref.watch(firebaseAvatarStateProvider);
    yield firebaseState.valueOrNull?.equippedAvatarId;
  }
});

/// Provider for unified avatar state (combines all avatar-related state)
final unifiedAvatarStateProvider = Provider<UnifiedAvatarState>((ref) {
  final equippedAvatarAsync = ref.watch(unifiedEquippedAvatarProvider);
  final firebaseStateAsync = ref.watch(firebaseAvatarStateProvider);
  final bridge = ref.watch(unifiedAvatarBridgeProvider);
  
  return UnifiedAvatarState(
    equippedAvatarId: equippedAvatarAsync.valueOrNull,
    firebaseState: firebaseStateAsync.valueOrNull,
    isLoading: equippedAvatarAsync.isLoading || firebaseStateAsync.isLoading,
    error: equippedAvatarAsync.hasError ? equippedAvatarAsync.error : null,
    bridge: bridge,
  );
});

/// Unified avatar state that combines Firebase and legacy systems
class UnifiedAvatarState {
  final String? equippedAvatarId;
  final dynamic firebaseState; // FirebaseAvatarState
  final bool isLoading;
  final Object? error;
  final UnifiedAvatarBridge bridge;
  
  const UnifiedAvatarState({
    required this.equippedAvatarId,
    required this.firebaseState,
    required this.isLoading,
    required this.error,
    required this.bridge,
  });
  
  /// Check if an avatar is equipped
  bool isAvatarEquipped(String avatarId) {
    return equippedAvatarId == avatarId;
  }
  
  /// Get debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'equippedAvatarId': equippedAvatarId,
      'isLoading': isLoading,
      'hasError': error != null,
      'error': error?.toString(),
      'bridgeDebugInfo': bridge.getDebugInfo(),
    };
  }
  
  @override
  String toString() {
    return 'UnifiedAvatarState(equippedAvatarId: $equippedAvatarId, isLoading: $isLoading, hasError: ${error != null})';
  }
}

/// Notifier for unified avatar actions
class UnifiedAvatarNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  
  UnifiedAvatarNotifier(this.ref) : super(const AsyncValue.data(null));
  
  /// Equip avatar through unified bridge
  Future<void> equipAvatar(String avatarId) async {
    state = const AsyncValue.loading();
    
    try {
      log.info('🎯 UnifiedAvatarNotifier: Equipping avatar $avatarId');
      
      final bridge = ref.read(unifiedAvatarBridgeProvider);
      await bridge.equipAvatar(avatarId);
      
      state = const AsyncValue.data(null);
      log.info('✅ UnifiedAvatarNotifier: Successfully equipped avatar $avatarId');
      
    } catch (error, stackTrace) {
      log.severe('❌ UnifiedAvatarNotifier: Failed to equip avatar $avatarId: $error', error, stackTrace);
      state = AsyncValue.error(error, stackTrace);
    }
  }
  
  /// Refresh unified state
  Future<void> refresh() async {
    try {
      log.info('🔄 UnifiedAvatarNotifier: Refreshing state...');
      
      final bridge = ref.read(unifiedAvatarBridgeProvider);
      await bridge.refresh();
      
      log.info('✅ UnifiedAvatarNotifier: Successfully refreshed state');
      
    } catch (error) {
      log.warning('⚠️ UnifiedAvatarNotifier: Failed to refresh state: $error');
    }
  }
}

/// Provider for unified avatar actions
final unifiedAvatarNotifierProvider = StateNotifierProvider<UnifiedAvatarNotifier, AsyncValue<void>>((ref) {
  return UnifiedAvatarNotifier(ref);
});