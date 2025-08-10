import 'dart:convert';

/// Represents the persistent state of user's avatar ownership and equipped status
class UserAvatarState {
  final Map<String, bool> ownedAvatars;
  final String? equippedAvatarId;
  final DateTime lastUpdated;

  const UserAvatarState({
    required this.ownedAvatars,
    this.equippedAvatarId,
    required this.lastUpdated,
  });

  /// Create initial state with default avatar unlocked and equipped
  factory UserAvatarState.initial() {
    return UserAvatarState(
      ownedAvatars: {
        'classic_coach': true,  // Default avatar is always owned
        'mummy_coach': true,    // Free avatar is always owned
      },
      equippedAvatarId: 'classic_coach',
      lastUpdated: DateTime.now(),
    );
  }

  /// Check if user owns a specific avatar
  bool isAvatarOwned(String avatarId) {
    return ownedAvatars[avatarId] ?? false;
  }

  /// Check if a specific avatar is currently equipped
  bool isAvatarEquipped(String avatarId) {
    return equippedAvatarId == avatarId;
  }

  /// Get list of owned avatar IDs
  List<String> get ownedAvatarIds {
    return ownedAvatars.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get count of owned avatars
  int get ownedAvatarsCount {
    return ownedAvatarIds.length;
  }

  /// Unlock a new avatar (mark as owned)
  UserAvatarState unlockAvatar(String avatarId) {
    final updatedOwned = Map<String, bool>.from(ownedAvatars);
    updatedOwned[avatarId] = true;
    
    return UserAvatarState(
      ownedAvatars: updatedOwned,
      equippedAvatarId: equippedAvatarId,
      lastUpdated: DateTime.now(),
    );
  }

  /// Equip an avatar (only if owned)
  UserAvatarState? equipAvatar(String avatarId) {
    if (!isAvatarOwned(avatarId)) {
      return null; // Can't equip an avatar that's not owned
    }

    return UserAvatarState(
      ownedAvatars: ownedAvatars,
      equippedAvatarId: avatarId,
      lastUpdated: DateTime.now(),
    );
  }

  /// Create copy with updated values
  UserAvatarState copyWith({
    Map<String, bool>? ownedAvatars,
    String? equippedAvatarId,
    DateTime? lastUpdated,
  }) {
    return UserAvatarState(
      ownedAvatars: ownedAvatars ?? this.ownedAvatars,
      equippedAvatarId: equippedAvatarId ?? this.equippedAvatarId,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'ownedAvatars': ownedAvatars,
      'equippedAvatarId': equippedAvatarId,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Create from JSON for persistence
  factory UserAvatarState.fromJson(Map<String, dynamic> json) {
    return UserAvatarState(
      ownedAvatars: Map<String, bool>.from(json['ownedAvatars'] ?? {}),
      equippedAvatarId: json['equippedAvatarId'] as String?,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  /// Convert to JSON string for SharedPreferences
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create from JSON string from SharedPreferences
  factory UserAvatarState.fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return UserAvatarState.fromJson(json);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAvatarState &&
          runtimeType == other.runtimeType &&
          ownedAvatars.toString() == other.ownedAvatars.toString() &&
          equippedAvatarId == other.equippedAvatarId;

  @override
  int get hashCode =>
      ownedAvatars.hashCode ^ 
      equippedAvatarId.hashCode ^ 
      lastUpdated.hashCode;

  @override
  String toString() {
    return 'UserAvatarState('
        'owned: $ownedAvatarsCount, '
        'equipped: $equippedAvatarId, '
        'updated: ${lastUpdated.toIso8601String()}'
        ')';
  }
}

/// Represents an avatar purchase transaction
class AvatarPurchaseResult {
  final bool success;
  final String message;
  final String? avatarId;
  final UserAvatarState? newState;

  const AvatarPurchaseResult({
    required this.success,
    required this.message,
    this.avatarId,
    this.newState,
  });

  factory AvatarPurchaseResult.success(String message, String avatarId, UserAvatarState newState) {
    return AvatarPurchaseResult(
      success: true,
      message: message,
      avatarId: avatarId,
      newState: newState,
    );
  }

  factory AvatarPurchaseResult.failure(String message) {
    return AvatarPurchaseResult(
      success: false,
      message: message,
    );
  }
}

/// Represents an avatar equip transaction
class AvatarEquipResult {
  final bool success;
  final String message;
  final String? avatarId;
  final UserAvatarState? newState;

  const AvatarEquipResult({
    required this.success,
    required this.message,
    this.avatarId,
    this.newState,
  });

  factory AvatarEquipResult.success(String message, String avatarId, UserAvatarState newState) {
    return AvatarEquipResult(
      success: true,
      message: message,
      avatarId: avatarId,
      newState: newState,
    );
  }

  factory AvatarEquipResult.failure(String message) {
    return AvatarEquipResult(
      success: false,
      message: message,
    );
  }
}