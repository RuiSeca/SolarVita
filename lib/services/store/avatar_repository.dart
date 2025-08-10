import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import '../../models/store/avatar_state.dart';
import '../../models/store/avatar_item.dart';
import '../../data/mock_avatar_data.dart';

/// Repository for managing avatar state persistence and operations
class AvatarRepository {
  static const String _avatarStateKey = 'user_avatar_state';
  static const String _purchaseHistoryKey = 'avatar_purchase_history';
  
  final Logger _log = Logger('AvatarRepository');
  SharedPreferences? _prefs;

  /// Initialize the repository
  Future<void> initialize() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
      _log.info('🏪 Avatar repository initialized');
    }
  }

  /// Get current avatar state from persistence or create initial state
  Future<UserAvatarState> getAvatarState() async {
    await initialize();
    
    try {
      final stateJson = _prefs!.getString(_avatarStateKey);
      if (stateJson != null) {
        final state = UserAvatarState.fromJsonString(stateJson);
        _log.info('📱 Loaded avatar state: ${state.ownedAvatarsCount} owned, equipped: ${state.equippedAvatarId}');
        return state;
      }
    } catch (e) {
      _log.warning('⚠️ Failed to load avatar state: $e');
    }

    // Return initial state if no saved state or error
    final initialState = UserAvatarState.initial();
    await _saveAvatarState(initialState);
    _log.info('🆕 Created initial avatar state');
    return initialState;
  }

  /// Save avatar state to persistence
  Future<bool> _saveAvatarState(UserAvatarState state) async {
    await initialize();
    
    try {
      final stateJson = state.toJsonString();
      await _prefs!.setString(_avatarStateKey, stateJson);
      _log.fine('💾 Saved avatar state');
      return true;
    } catch (e) {
      _log.warning('⚠️ Failed to save avatar state: $e');
      return false;
    }
  }

  /// Purchase an avatar (unlock it)
  Future<AvatarPurchaseResult> purchaseAvatar(
    String avatarId,
    UserAvatarState currentState,
  ) async {
    try {
      // Check if avatar exists
      final availableAvatars = MockAvatarData.getAvatarItems();
      final avatar = availableAvatars.firstWhere(
        (item) => item.id == avatarId,
        orElse: () => throw Exception('Avatar not found'),
      );

      // Check if already owned
      if (currentState.isAvatarOwned(avatarId)) {
        return AvatarPurchaseResult.failure('Avatar already owned');
      }

      // Check if it's member-only (would be handled by membership system)
      if (avatar.isMemberOnly) {
        return AvatarPurchaseResult.failure('Membership required');
      }

      // Unlock the avatar
      final newState = currentState.unlockAvatar(avatarId);
      
      // Save new state
      final saveSuccess = await _saveAvatarState(newState);
      if (!saveSuccess) {
        return AvatarPurchaseResult.failure('Failed to save purchase');
      }

      // Record purchase history
      await _recordPurchase(avatarId, avatar.name, avatar.cost, avatar.coinType);

      _log.info('🛒 Successfully purchased avatar: $avatarId');
      return AvatarPurchaseResult.success(
        '${avatar.name} purchased successfully! 🎉',
        avatarId,
        newState,
      );

    } catch (e) {
      _log.warning('⚠️ Failed to purchase avatar $avatarId: $e');
      return AvatarPurchaseResult.failure('Purchase failed: ${e.toString()}');
    }
  }

  /// Equip an avatar (if owned)
  Future<AvatarEquipResult> equipAvatar(
    String avatarId,
    UserAvatarState currentState,
  ) async {
    try {
      // Check if avatar exists
      final availableAvatars = MockAvatarData.getAvatarItems();
      final avatar = availableAvatars.firstWhere(
        (item) => item.id == avatarId,
        orElse: () => throw Exception('Avatar not found'),
      );

      // Check if owned
      if (!currentState.isAvatarOwned(avatarId)) {
        return AvatarEquipResult.failure('Avatar not owned');
      }

      // Check if already equipped
      if (currentState.isAvatarEquipped(avatarId)) {
        return AvatarEquipResult.failure('Avatar already equipped');
      }

      // Equip the avatar
      final newState = currentState.equipAvatar(avatarId);
      if (newState == null) {
        return AvatarEquipResult.failure('Failed to equip avatar');
      }

      // Save new state
      final saveSuccess = await _saveAvatarState(newState);
      if (!saveSuccess) {
        return AvatarEquipResult.failure('Failed to save equipped state');
      }

      _log.info('👕 Successfully equipped avatar: $avatarId');
      return AvatarEquipResult.success(
        '${avatar.name} equipped! ✨',
        avatarId,
        newState,
      );

    } catch (e) {
      _log.warning('⚠️ Failed to equip avatar $avatarId: $e');
      return AvatarEquipResult.failure('Equip failed: ${e.toString()}');
    }
  }

  /// Get avatar with current state applied
  List<AvatarItem> getAvatarsWithState(UserAvatarState state) {
    final baseAvatars = MockAvatarData.getAvatarItems();
    
    return baseAvatars.map((avatar) {
      return avatar.copyWith(
        isUnlocked: state.isAvatarOwned(avatar.id),
        isEquipped: state.isAvatarEquipped(avatar.id),
      );
    }).toList();
  }

  /// Get specific avatar with current state applied
  AvatarItem? getAvatarWithState(String avatarId, UserAvatarState state) {
    final baseAvatars = MockAvatarData.getAvatarItems();
    final avatar = baseAvatars.where((item) => item.id == avatarId).firstOrNull;
    
    if (avatar == null) return null;
    
    return avatar.copyWith(
      isUnlocked: state.isAvatarOwned(avatarId),
      isEquipped: state.isAvatarEquipped(avatarId),
    );
  }

  /// Get currently equipped avatar
  AvatarItem? getEquippedAvatar(UserAvatarState state) {
    if (state.equippedAvatarId == null) return null;
    return getAvatarWithState(state.equippedAvatarId!, state);
  }

  /// Get only owned avatars
  List<AvatarItem> getOwnedAvatars(UserAvatarState state) {
    return getAvatarsWithState(state)
        .where((avatar) => avatar.isUnlocked)
        .toList();
  }

  /// Get avatars filtered by access type with state
  List<AvatarItem> getAvatarsByAccessType(
    AvatarAccessType accessType, 
    UserAvatarState state,
  ) {
    return getAvatarsWithState(state)
        .where((avatar) => avatar.accessType == accessType)
        .toList();
  }

  /// Record avatar purchase in history
  Future<void> _recordPurchase(
    String avatarId,
    String avatarName,
    int cost,
    CoinType coinType,
  ) async {
    try {
      final historyJson = _prefs!.getString(_purchaseHistoryKey) ?? '[]';
      final List<dynamic> history = List.from(
        jsonDecode(historyJson),
      );
      
      history.add({
        'avatarId': avatarId,
        'avatarName': avatarName,
        'cost': cost,
        'coinType': coinType.toString(),
        'purchaseDate': DateTime.now().toIso8601String(),
      });

      await _prefs!.setString(
        _purchaseHistoryKey, 
        jsonEncode(history),
      );
      
      _log.fine('📋 Recorded purchase: $avatarName');
    } catch (e) {
      _log.warning('⚠️ Failed to record purchase: $e');
    }
  }

  /// Get purchase history
  Future<List<Map<String, dynamic>>> getPurchaseHistory() async {
    await initialize();
    
    try {
      final historyJson = _prefs!.getString(_purchaseHistoryKey) ?? '[]';
      final List<dynamic> history = jsonDecode(historyJson);
      return history.cast<Map<String, dynamic>>();
    } catch (e) {
      _log.warning('⚠️ Failed to load purchase history: $e');
      return [];
    }
  }

  /// Clear all avatar data (for testing/reset)
  Future<bool> clearAvatarData() async {
    await initialize();
    
    try {
      await _prefs!.remove(_avatarStateKey);
      await _prefs!.remove(_purchaseHistoryKey);
      _log.info('🗑️ Cleared all avatar data');
      return true;
    } catch (e) {
      _log.warning('⚠️ Failed to clear avatar data: $e');
      return false;
    }
  }

  /// Reset to initial state (keeps purchase history)
  Future<UserAvatarState> resetToInitialState() async {
    await initialize();
    
    final initialState = UserAvatarState.initial();
    await _saveAvatarState(initialState);
    _log.info('🔄 Reset avatar state to initial');
    return initialState;
  }

  /// Validate avatar state integrity
  Future<UserAvatarState> validateAndFixState(UserAvatarState state) async {
    bool needsFix = false;
    var fixedState = state;

    // Ensure default avatars are always owned
    final requiredAvatars = ['classic_coach', 'mummy_coach'];
    for (final avatarId in requiredAvatars) {
      if (!fixedState.isAvatarOwned(avatarId)) {
        fixedState = fixedState.unlockAvatar(avatarId);
        needsFix = true;
        _log.info('🔧 Fixed missing required avatar: $avatarId');
      }
    }

    // Ensure equipped avatar is owned
    if (fixedState.equippedAvatarId != null && 
        !fixedState.isAvatarOwned(fixedState.equippedAvatarId!)) {
      fixedState = fixedState.copyWith(equippedAvatarId: 'classic_coach');
      needsFix = true;
      _log.info('🔧 Fixed equipped avatar to classic_coach');
    }

    // Save fixes if needed
    if (needsFix) {
      await _saveAvatarState(fixedState);
      _log.info('💾 Saved fixed avatar state');
    }

    return fixedState;
  }

  /// Get avatar statistics
  Map<String, dynamic> getAvatarStats(UserAvatarState state) {
    final allAvatars = MockAvatarData.getAvatarItems();
    final ownedCount = state.ownedAvatarsCount;
    final totalCount = allAvatars.length;
    
    final accessTypeCounts = <AvatarAccessType, Map<String, int>>{};
    
    for (final accessType in AvatarAccessType.values) {
      final typeAvatars = allAvatars.where((a) => a.accessType == accessType).toList();
      final ownedTypeAvatars = typeAvatars.where((a) => state.isAvatarOwned(a.id)).length;
      
      accessTypeCounts[accessType] = {
        'total': typeAvatars.length,
        'owned': ownedTypeAvatars,
      };
    }

    return {
      'totalAvatars': totalCount,
      'ownedAvatars': ownedCount,
      'completionPercentage': ((ownedCount / totalCount) * 100).round(),
      'equippedAvatar': state.equippedAvatarId,
      'accessTypeCounts': accessTypeCounts.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    };
  }
}