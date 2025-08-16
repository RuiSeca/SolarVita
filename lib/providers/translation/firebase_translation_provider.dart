import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../../services/translation/firebase_translation_service.dart';

final log = Logger('FirebaseTranslationProvider');

/// Provider for Firebase Translation Service
final firebaseTranslationServiceProvider = Provider<FirebaseTranslationService>((ref) {
  final service = FirebaseTranslationService();
  
  // Initialize the service
  service.initialize().catchError((error) {
    log.severe('Failed to initialize Firebase Translation Service: $error');
  });
  
  return service;
});

/// Provider for general translations stream
final translationsStreamProvider = StreamProvider<Map<String, Map<String, String>>>((ref) {
  final service = ref.watch(firebaseTranslationServiceProvider);
  return service.translationsStream;
});

/// Provider for avatar translations stream
final avatarTranslationsStreamProvider = StreamProvider<Map<String, Map<String, LocalizedAvatarData>>>((ref) {
  final service = ref.watch(firebaseTranslationServiceProvider);
  return service.avatarTranslationsStream;
});

/// Provider for a specific translation
final translationProvider = Provider.family<String, TranslationParams>((ref, params) {
  final service = ref.watch(firebaseTranslationServiceProvider);
  return service.translate(params.key, params.languageCode, fallback: params.fallback);
});

/// Provider for localized avatar data
final localizedAvatarProvider = Provider.family<LocalizedAvatarData?, LocalizedAvatarParams>((ref, params) {
  final service = ref.watch(firebaseTranslationServiceProvider);
  return service.getLocalizedAvatarData(params.avatarId, params.languageCode);
});

/// Parameters for translation provider
class TranslationParams {
  final String key;
  final String languageCode;
  final String? fallback;

  const TranslationParams({
    required this.key,
    required this.languageCode,
    this.fallback,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranslationParams &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          languageCode == other.languageCode &&
          fallback == other.fallback;

  @override
  int get hashCode => key.hashCode ^ languageCode.hashCode ^ (fallback?.hashCode ?? 0);
}

/// Parameters for localized avatar provider
class LocalizedAvatarParams {
  final String avatarId;
  final String languageCode;

  const LocalizedAvatarParams({
    required this.avatarId,
    required this.languageCode,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalizedAvatarParams &&
          runtimeType == other.runtimeType &&
          avatarId == other.avatarId &&
          languageCode == other.languageCode;

  @override
  int get hashCode => avatarId.hashCode ^ languageCode.hashCode;
}