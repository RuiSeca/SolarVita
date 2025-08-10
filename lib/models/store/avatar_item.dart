import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../utils/translation_helper.dart';

enum AvatarAccessType {
  free,
  paid,
  member,
}

enum CoinType {
  streakCoin,
  coachPoints,
  fitGems,
}

enum AvatarCategory {
  skins,
  outfits,
  accessories,
  animations,
}

class AvatarItem {
  final String id;
  final String name;
  final String description;
  final String rivAssetPath;
  final String previewImagePath;
  final int cost;
  final CoinType coinType;
  final AvatarAccessType accessType;
  final AvatarCategory category;
  final bool isUnlocked;
  final bool isEquipped;
  final DateTime? releaseDate;
  final DateTime? expiryDate;
  final String previewAnimation;
  final Map<String, dynamic> metadata;
  final int rarity; // 1-5 star system
  final List<String> tags;
  final List<String> animations; // Available animations (attack, run, jump, etc.)

  const AvatarItem({
    required this.id,
    required this.name,
    required this.description,
    required this.rivAssetPath,
    required this.previewImagePath,
    required this.cost,
    required this.coinType,
    required this.accessType,
    required this.category,
    this.isUnlocked = false,
    this.isEquipped = false,
    this.releaseDate,
    this.expiryDate,
    this.previewAnimation = 'Idle',
    this.metadata = const {},
    this.rarity = 1,
    this.tags = const [],
    this.animations = const [],
  });

  // Helper getters
  bool get isFree => accessType == AvatarAccessType.free;
  bool get isPaid => accessType == AvatarAccessType.paid;
  bool get isMemberOnly => accessType == AvatarAccessType.member;
  bool get isAvailable => expiryDate == null || expiryDate!.isAfter(DateTime.now());
  bool get isNew => releaseDate != null && 
      DateTime.now().difference(releaseDate!).inDays < 7;

  String accessLabel(BuildContext context) {
    switch (accessType) {
      case AvatarAccessType.free:
        return tr(context, 'access_types_earn_with_streaks');
      case AvatarAccessType.paid:
        return tr(context, 'access_types_buy');
      case AvatarAccessType.member:
        return tr(context, 'access_types_member_only');
    }
  }

  String get coinIcon {
    switch (coinType) {
      case CoinType.streakCoin:
        return '🔥';
      case CoinType.coachPoints:
        return '⭐';
      case CoinType.fitGems:
        return '💎';
    }
  }

  String coinName(BuildContext context) {
    switch (coinType) {
      case CoinType.streakCoin:
        return tr(context, 'currencies_streak_coins');
      case CoinType.coachPoints:
        return tr(context, 'currencies_coach_points');
      case CoinType.fitGems:
        return tr(context, 'currencies_fit_gems');
    }
  }

  String translatedName(BuildContext context) {
    final key = 'avatar_${id}_name';
    final translatedName = tr(context, key);
    // If translation is not found (returns the key), use original name
    if (translatedName == key || translatedName.isEmpty) {
      return name;
    }
    return translatedName;
  }

  String translatedDescription(BuildContext context) {
    final key = 'avatar_${id}_description';
    final translatedDesc = tr(context, key);
    // If translation is not found (returns the key), use original description
    if (translatedDesc == key || translatedDesc.isEmpty) {
      return description;
    }
    return translatedDesc;
  }

  factory AvatarItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AvatarItem.fromJson(data..['id'] = doc.id);
  }

  factory AvatarItem.fromJson(Map<String, dynamic> json) {
    return AvatarItem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      rivAssetPath: json['rivAssetPath'] as String,
      previewImagePath: json['previewImagePath'] as String,
      cost: json['cost'] as int,
      coinType: CoinType.values.firstWhere(
        (e) => e.toString().split('.').last == json['coinType'],
        orElse: () => CoinType.streakCoin,
      ),
      accessType: AvatarAccessType.values.firstWhere(
        (e) => e.toString().split('.').last == json['accessType'],
        orElse: () => AvatarAccessType.free,
      ),
      category: AvatarCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => AvatarCategory.skins,
      ),
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      isEquipped: json['isEquipped'] as bool? ?? false,
      releaseDate: json['releaseDate'] != null
          ? (json['releaseDate'] as Timestamp).toDate()
          : null,
      expiryDate: json['expiryDate'] != null
          ? (json['expiryDate'] as Timestamp).toDate()
          : null,
      previewAnimation: json['previewAnimation'] as String? ?? 'Idle',
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      rarity: json['rarity'] as int? ?? 1,
      tags: List<String>.from(json['tags'] ?? []),
      animations: List<String>.from(json['animations'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'rivAssetPath': rivAssetPath,
      'previewImagePath': previewImagePath,
      'cost': cost,
      'coinType': coinType.toString().split('.').last,
      'accessType': accessType.toString().split('.').last,
      'category': category.toString().split('.').last,
      'isUnlocked': isUnlocked,
      'isEquipped': isEquipped,
      'releaseDate': releaseDate != null ? Timestamp.fromDate(releaseDate!) : null,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'previewAnimation': previewAnimation,
      'metadata': metadata,
      'rarity': rarity,
      'tags': tags,
      'animations': animations,
    };
  }

  AvatarItem copyWith({
    String? id,
    String? name,
    String? description,
    String? rivAssetPath,
    String? previewImagePath,
    int? cost,
    CoinType? coinType,
    AvatarAccessType? accessType,
    AvatarCategory? category,
    bool? isUnlocked,
    bool? isEquipped,
    DateTime? releaseDate,
    DateTime? expiryDate,
    String? previewAnimation,
    Map<String, dynamic>? metadata,
    int? rarity,
    List<String>? tags,
    List<String>? animations,
  }) {
    return AvatarItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      rivAssetPath: rivAssetPath ?? this.rivAssetPath,
      previewImagePath: previewImagePath ?? this.previewImagePath,
      cost: cost ?? this.cost,
      coinType: coinType ?? this.coinType,
      accessType: accessType ?? this.accessType,
      category: category ?? this.category,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isEquipped: isEquipped ?? this.isEquipped,
      releaseDate: releaseDate ?? this.releaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      previewAnimation: previewAnimation ?? this.previewAnimation,
      metadata: metadata ?? this.metadata,
      rarity: rarity ?? this.rarity,
      tags: tags ?? this.tags,
      animations: animations ?? this.animations,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvatarItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AvatarItem(id: $id, name: $name, accessType: $accessType)';
}