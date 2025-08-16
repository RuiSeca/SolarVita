import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/translation/firebase_translation_service.dart';
import '../../providers/translation/firebase_translation_provider.dart';
import 'firebase_avatar.dart';

/// Enhanced Firebase avatar model with localization support
class LocalizedFirebaseAvatar {
  final String avatarId;
  final String rivAssetPath;
  final List<String> availableAnimations;
  final Map<String, dynamic> customProperties;
  final int price;
  final String rarity;
  final bool isPurchasable;
  final List<String> requiredAchievements;
  final DateTime? releaseDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Localized data - filled from Firebase translations
  final String displayName;
  final String displayDescription;
  final String displayPersonality;
  final String displaySpeciality;

  const LocalizedFirebaseAvatar({
    required this.avatarId,
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
    required this.displayName,
    required this.displayDescription,
    required this.displayPersonality,
    required this.displaySpeciality,
  });

  /// Convert from FirebaseAvatar with localization
  static LocalizedFirebaseAvatar fromFirebaseAvatar(
    FirebaseAvatar avatar,
    LocalizedAvatarData? localizedData,
  ) {
    return LocalizedFirebaseAvatar(
      avatarId: avatar.avatarId,
      rivAssetPath: avatar.rivAssetPath,
      availableAnimations: avatar.availableAnimations,
      customProperties: avatar.customProperties,
      price: avatar.price,
      rarity: avatar.rarity,
      isPurchasable: avatar.isPurchasable,
      requiredAchievements: avatar.requiredAchievements,
      releaseDate: avatar.releaseDate,
      createdAt: avatar.createdAt,
      updatedAt: avatar.updatedAt,
      displayName: localizedData?.name ?? avatar.name,
      displayDescription: localizedData?.description ?? avatar.description,
      displayPersonality: localizedData?.personality ?? '',
      displaySpeciality: localizedData?.speciality ?? '',
    );
  }

  LocalizedFirebaseAvatar copyWith({
    String? avatarId,
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
    String? displayName,
    String? displayDescription,
    String? displayPersonality,
    String? displaySpeciality,
  }) {
    return LocalizedFirebaseAvatar(
      avatarId: avatarId ?? this.avatarId,
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
      displayName: displayName ?? this.displayName,
      displayDescription: displayDescription ?? this.displayDescription,
      displayPersonality: displayPersonality ?? this.displayPersonality,
      displaySpeciality: displaySpeciality ?? this.displaySpeciality,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalizedFirebaseAvatar &&
          runtimeType == other.runtimeType &&
          avatarId == other.avatarId;

  @override
  int get hashCode => avatarId.hashCode;

  @override
  String toString() {
    return 'LocalizedFirebaseAvatar{avatarId: $avatarId, displayName: $displayName, rarity: $rarity}';
  }
}

/// Provider for localized avatar
final localizedFirebaseAvatarProvider = Provider.family<LocalizedFirebaseAvatar?, LocalizedAvatarProviderParams>((ref, params) {
  final localizedData = ref.watch(localizedAvatarProvider(LocalizedAvatarParams(
    avatarId: params.avatar.avatarId,
    languageCode: params.languageCode,
  )));

  return LocalizedFirebaseAvatar.fromFirebaseAvatar(params.avatar, localizedData);
});

/// Provider for list of localized avatars
final localizedFirebaseAvatarListProvider = Provider.family<List<LocalizedFirebaseAvatar>, LocalizedAvatarListParams>((ref, params) {
  return params.avatars.map((avatar) {
    final localizedData = ref.watch(localizedAvatarProvider(LocalizedAvatarParams(
      avatarId: avatar.avatarId,
      languageCode: params.languageCode,
    )));

    return LocalizedFirebaseAvatar.fromFirebaseAvatar(avatar, localizedData);
  }).toList();
});

/// Parameters for localized avatar provider
class LocalizedAvatarProviderParams {
  final FirebaseAvatar avatar;
  final String languageCode;

  const LocalizedAvatarProviderParams({
    required this.avatar,
    required this.languageCode,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalizedAvatarProviderParams &&
          runtimeType == other.runtimeType &&
          avatar == other.avatar &&
          languageCode == other.languageCode;

  @override
  int get hashCode => avatar.hashCode ^ languageCode.hashCode;
}

/// Parameters for localized avatar list provider
class LocalizedAvatarListParams {
  final List<FirebaseAvatar> avatars;
  final String languageCode;

  const LocalizedAvatarListParams({
    required this.avatars,
    required this.languageCode,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalizedAvatarListParams &&
          runtimeType == other.runtimeType &&
          listEquals(avatars, other.avatars) &&
          languageCode == other.languageCode;

  @override
  int get hashCode => avatars.hashCode ^ languageCode.hashCode;
}

/// Widget extension for easy access to localized avatars
extension LocalizedAvatarWidget on BuildContext {
  /// Get localized avatar data
  LocalizedFirebaseAvatar? getLocalizedAvatar(WidgetRef ref, FirebaseAvatar avatar) {
    final languageCode = Localizations.localeOf(this).languageCode;
    return ref.watch(localizedFirebaseAvatarProvider(LocalizedAvatarProviderParams(
      avatar: avatar,
      languageCode: languageCode,
    )));
  }

  /// Get list of localized avatars
  List<LocalizedFirebaseAvatar> getLocalizedAvatars(WidgetRef ref, List<FirebaseAvatar> avatars) {
    final languageCode = Localizations.localeOf(this).languageCode;
    return ref.watch(localizedFirebaseAvatarListProvider(LocalizedAvatarListParams(
      avatars: avatars,
      languageCode: languageCode,
    )));
  }
}

