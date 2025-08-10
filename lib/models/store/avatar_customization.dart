import 'dart:convert';

/// Represents customization settings for an avatar
class AvatarCustomization {
  final String avatarId;
  final Map<String, double> numberValues;
  final Map<String, bool> booleanValues;
  final DateTime lastUpdated;

  const AvatarCustomization({
    required this.avatarId,
    required this.numberValues,
    required this.booleanValues,
    required this.lastUpdated,
  });

  /// Create default customization for an avatar
  factory AvatarCustomization.defaultFor(String avatarId) {
    return AvatarCustomization(
      avatarId: avatarId,
      numberValues: {},
      booleanValues: {},
      lastUpdated: DateTime.now(),
    );
  }

  /// Create a copy with updated values
  AvatarCustomization copyWith({
    Map<String, double>? numberValues,
    Map<String, bool>? booleanValues,
    DateTime? lastUpdated,
  }) {
    return AvatarCustomization(
      avatarId: avatarId,
      numberValues: numberValues ?? this.numberValues,
      booleanValues: booleanValues ?? this.booleanValues,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Update a single number value
  AvatarCustomization updateNumber(String key, double value) {
    final newNumbers = Map<String, double>.from(numberValues);
    newNumbers[key] = value;
    return copyWith(
      numberValues: newNumbers,
      lastUpdated: DateTime.now(),
    );
  }

  /// Update a single boolean value
  AvatarCustomization updateBoolean(String key, bool value) {
    final newBooleans = Map<String, bool>.from(booleanValues);
    newBooleans[key] = value;
    return copyWith(
      booleanValues: newBooleans,
      lastUpdated: DateTime.now(),
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'avatarId': avatarId,
      'numberValues': numberValues,
      'booleanValues': booleanValues,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Create from JSON
  factory AvatarCustomization.fromJson(Map<String, dynamic> json) {
    return AvatarCustomization(
      avatarId: json['avatarId'] as String,
      numberValues: Map<String, double>.from(json['numberValues'] ?? {}),
      booleanValues: Map<String, bool>.from(json['booleanValues'] ?? {}),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  /// Convert to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create from JSON string
  factory AvatarCustomization.fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return AvatarCustomization.fromJson(json);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvatarCustomization &&
          runtimeType == other.runtimeType &&
          avatarId == other.avatarId &&
          numberValues.toString() == other.numberValues.toString() &&
          booleanValues.toString() == other.booleanValues.toString();

  @override
  int get hashCode =>
      avatarId.hashCode ^
      numberValues.hashCode ^
      booleanValues.hashCode;

  @override
  String toString() {
    return 'AvatarCustomization('
        'avatarId: $avatarId, '
        'numbers: ${numberValues.length}, '
        'booleans: ${booleanValues.length}, '
        'updated: ${lastUpdated.toIso8601String()}'
        ')';
  }
}

/// Manages all avatar customizations
class AvatarCustomizationManager {
  final Map<String, AvatarCustomization> _customizations = {};

  /// Default constructor
  AvatarCustomizationManager();

  /// Get customization for an avatar
  AvatarCustomization getCustomization(String avatarId) {
    return _customizations[avatarId] ?? AvatarCustomization.defaultFor(avatarId);
  }

  /// Set customization for an avatar
  void setCustomization(AvatarCustomization customization) {
    _customizations[customization.avatarId] = customization;
  }

  /// Update a number value for an avatar
  void updateNumber(String avatarId, String key, double value) {
    final current = getCustomization(avatarId);
    final updated = current.updateNumber(key, value);
    setCustomization(updated);
  }

  /// Update a boolean value for an avatar
  void updateBoolean(String avatarId, String key, bool value) {
    final current = getCustomization(avatarId);
    final updated = current.updateBoolean(key, value);
    setCustomization(updated);
  }

  /// Get all customized avatars
  List<String> get customizedAvatars => _customizations.keys.toList();

  /// Check if avatar has customizations
  bool hasCustomizations(String avatarId) {
    final customization = _customizations[avatarId];
    return customization != null && 
           (customization.numberValues.isNotEmpty || 
            customization.booleanValues.isNotEmpty);
  }

  /// Reset customizations for an avatar
  void resetCustomizations(String avatarId) {
    _customizations.remove(avatarId);
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'customizations': _customizations.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    };
  }

  /// Create from JSON
  factory AvatarCustomizationManager.fromJson(Map<String, dynamic> json) {
    final manager = AvatarCustomizationManager();
    final customizations = json['customizations'] as Map<String, dynamic>? ?? {};
    
    for (final entry in customizations.entries) {
      final customization = AvatarCustomization.fromJson(entry.value as Map<String, dynamic>);
      manager.setCustomization(customization);
    }
    
    return manager;
  }

  /// Convert to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create from JSON string
  factory AvatarCustomizationManager.fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return AvatarCustomizationManager.fromJson(json);
  }
}