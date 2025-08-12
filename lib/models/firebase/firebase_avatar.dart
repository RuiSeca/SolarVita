import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase data model for avatar information
class FirebaseAvatar {
  final String avatarId;
  final String name;
  final String description;
  final String rivAssetPath;
  final List<String> availableAnimations;
  final Map<String, dynamic> customProperties;
  final int price;
  final String rarity; // common, rare, epic, legendary
  final bool isPurchasable;
  final List<String> requiredAchievements;
  final DateTime? releaseDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FirebaseAvatar({
    required this.avatarId,
    required this.name,
    required this.description,
    required this.rivAssetPath,
    required this.availableAnimations,
    required this.customProperties,
    required this.price,
    required this.rarity,
    required this.isPurchasable,
    required this.requiredAchievements,
    this.releaseDate,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert from Firestore document
  factory FirebaseAvatar.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return FirebaseAvatar(
      avatarId: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      rivAssetPath: data['rivAssetPath'] as String? ?? '',
      availableAnimations: List<String>.from(data['availableAnimations'] as List? ?? []),
      customProperties: Map<String, dynamic>.from(data['customProperties'] as Map? ?? {}),
      price: data['price'] as int? ?? 0,
      rarity: data['rarity'] as String? ?? 'common',
      isPurchasable: data['isPurchasable'] as bool? ?? true,
      requiredAchievements: List<String>.from(data['requiredAchievements'] as List? ?? []),
      releaseDate: (data['releaseDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'rivAssetPath': rivAssetPath,
      'availableAnimations': availableAnimations,
      'customProperties': customProperties,
      'price': price,
      'rarity': rarity,
      'isPurchasable': isPurchasable,
      'requiredAchievements': requiredAchievements,
      'releaseDate': releaseDate != null ? Timestamp.fromDate(releaseDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with modified properties
  FirebaseAvatar copyWith({
    String? avatarId,
    String? name,
    String? description,
    String? rivAssetPath,
    List<String>? availableAnimations,
    Map<String, dynamic>? customProperties,
    int? price,
    String? rarity,
    bool? isPurchasable,
    List<String>? requiredAchievements,
    DateTime? releaseDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FirebaseAvatar(
      avatarId: avatarId ?? this.avatarId,
      name: name ?? this.name,
      description: description ?? this.description,
      rivAssetPath: rivAssetPath ?? this.rivAssetPath,
      availableAnimations: availableAnimations ?? this.availableAnimations,
      customProperties: customProperties ?? this.customProperties,
      price: price ?? this.price,
      rarity: rarity ?? this.rarity,
      isPurchasable: isPurchasable ?? this.isPurchasable,
      requiredAchievements: requiredAchievements ?? this.requiredAchievements,
      releaseDate: releaseDate ?? this.releaseDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FirebaseAvatar &&
          runtimeType == other.runtimeType &&
          avatarId == other.avatarId;

  @override
  int get hashCode => avatarId.hashCode;

  @override
  String toString() {
    return 'FirebaseAvatar{avatarId: $avatarId, name: $name, rarity: $rarity}';
  }
}

/// Firebase data model for user avatar ownership
class UserAvatarOwnership {
  final String userId;
  final String avatarId;
  final DateTime purchaseDate;
  final bool isEquipped;
  final Map<String, dynamic> customizations; // Eye color, skin tone, etc.
  final int timesUsed;
  final DateTime lastUsed;
  final Map<String, dynamic> metadata; // Purchase source, price paid, etc.

  const UserAvatarOwnership({
    required this.userId,
    required this.avatarId,
    required this.purchaseDate,
    required this.isEquipped,
    required this.customizations,
    required this.timesUsed,
    required this.lastUsed,
    required this.metadata,
  });

  /// Convert from Firestore document
  factory UserAvatarOwnership.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserAvatarOwnership(
      userId: data['userId'] as String? ?? '',
      avatarId: data['avatarId'] as String? ?? '',
      purchaseDate: (data['purchaseDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isEquipped: data['isEquipped'] as bool? ?? false,
      customizations: Map<String, dynamic>.from(data['customizations'] as Map? ?? {}),
      timesUsed: data['timesUsed'] as int? ?? 0,
      lastUsed: (data['lastUsed'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'avatarId': avatarId,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'isEquipped': isEquipped,
      'customizations': customizations,
      'timesUsed': timesUsed,
      'lastUsed': Timestamp.fromDate(lastUsed),
      'metadata': metadata,
    };
  }

  /// Create a copy with modified properties
  UserAvatarOwnership copyWith({
    String? userId,
    String? avatarId,
    DateTime? purchaseDate,
    bool? isEquipped,
    Map<String, dynamic>? customizations,
    int? timesUsed,
    DateTime? lastUsed,
    Map<String, dynamic>? metadata,
  }) {
    return UserAvatarOwnership(
      userId: userId ?? this.userId,
      avatarId: avatarId ?? this.avatarId,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      isEquipped: isEquipped ?? this.isEquipped,
      customizations: customizations ?? this.customizations,
      timesUsed: timesUsed ?? this.timesUsed,
      lastUsed: lastUsed ?? this.lastUsed,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAvatarOwnership &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          avatarId == other.avatarId;

  @override
  int get hashCode => userId.hashCode ^ avatarId.hashCode;

  @override
  String toString() {
    return 'UserAvatarOwnership{userId: $userId, avatarId: $avatarId, isEquipped: $isEquipped}';
  }
}

/// Firebase data model for user avatar state
class FirebaseAvatarState {
  final String userId;
  final String? equippedAvatarId;
  final Map<String, dynamic> globalCustomizations; // User-wide settings
  final List<String> ownedAvatarIds;
  final int totalPurchases;
  final int totalSpent;
  final DateTime lastUpdate;
  final Map<String, dynamic> achievements; // Avatar-related achievements

  const FirebaseAvatarState({
    required this.userId,
    this.equippedAvatarId,
    required this.globalCustomizations,
    required this.ownedAvatarIds,
    required this.totalPurchases,
    required this.totalSpent,
    required this.lastUpdate,
    required this.achievements,
  });

  /// Convert from Firestore document
  factory FirebaseAvatarState.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return FirebaseAvatarState(
      userId: doc.id,
      equippedAvatarId: data['equippedAvatarId'] as String?,
      globalCustomizations: Map<String, dynamic>.from(data['globalCustomizations'] as Map? ?? {}),
      ownedAvatarIds: List<String>.from(data['ownedAvatarIds'] as List? ?? []),
      totalPurchases: data['totalPurchases'] as int? ?? 0,
      totalSpent: data['totalSpent'] as int? ?? 0,
      lastUpdate: (data['lastUpdate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      achievements: Map<String, dynamic>.from(data['achievements'] as Map? ?? {}),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'equippedAvatarId': equippedAvatarId,
      'globalCustomizations': globalCustomizations,
      'ownedAvatarIds': ownedAvatarIds,
      'totalPurchases': totalPurchases,
      'totalSpent': totalSpent,
      'lastUpdate': Timestamp.fromDate(lastUpdate),
      'achievements': achievements,
    };
  }

  /// Create a copy with modified properties
  FirebaseAvatarState copyWith({
    String? userId,
    String? equippedAvatarId,
    Map<String, dynamic>? globalCustomizations,
    List<String>? ownedAvatarIds,
    int? totalPurchases,
    int? totalSpent,
    DateTime? lastUpdate,
    Map<String, dynamic>? achievements,
  }) {
    return FirebaseAvatarState(
      userId: userId ?? this.userId,
      equippedAvatarId: equippedAvatarId ?? this.equippedAvatarId,
      globalCustomizations: globalCustomizations ?? this.globalCustomizations,
      ownedAvatarIds: ownedAvatarIds ?? this.ownedAvatarIds,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      totalSpent: totalSpent ?? this.totalSpent,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      achievements: achievements ?? this.achievements,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FirebaseAvatarState &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() {
    return 'FirebaseAvatarState{userId: $userId, equippedAvatarId: $equippedAvatarId, ownedAvatars: ${ownedAvatarIds.length}}';
  }
}