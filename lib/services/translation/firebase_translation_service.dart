import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

final log = Logger('FirebaseTranslationService');

/// Service for managing translations stored in Firebase Firestore
/// Handles dynamic content that can't be stored in static translation files
class FirebaseTranslationService {
  static const String _translationsCollection = 'translations';
  static const String _avatarTranslationsCollection = 'avatar_translations';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cache for better performance
  final Map<String, Map<String, String>> _translationCache = {};
  final Map<String, Map<String, LocalizedAvatarData>> _avatarTranslationCache = {};
  
  // Stream controllers for reactive updates
  final StreamController<Map<String, Map<String, String>>> _translationsController = 
      StreamController.broadcast();
  final StreamController<Map<String, Map<String, LocalizedAvatarData>>> _avatarTranslationsController = 
      StreamController.broadcast();
  
  /// Stream of all translations
  Stream<Map<String, Map<String, String>>> get translationsStream => 
      _translationsController.stream;
  
  /// Stream of avatar translations
  Stream<Map<String, Map<String, LocalizedAvatarData>>> get avatarTranslationsStream => 
      _avatarTranslationsController.stream;

  /// Initialize the service and start listening to Firebase updates
  Future<void> initialize() async {
    log.info('🌐 Initializing Firebase Translation Service');
    
    try {
      // Listen to general translations
      _firestore.collection(_translationsCollection)
          .snapshots()
          .listen(_handleTranslationsUpdate);
      
      // Listen to avatar translations
      _firestore.collection(_avatarTranslationsCollection)
          .snapshots()
          .listen(_handleAvatarTranslationsUpdate);
      
      log.info('✅ Firebase Translation Service initialized successfully');
    } catch (e, stackTrace) {
      log.severe('❌ Failed to initialize Firebase Translation Service: \$e', e, stackTrace);
      rethrow;
    }
  }

  /// Handle general translations updates from Firebase
  void _handleTranslationsUpdate(QuerySnapshot snapshot) {
    try {
      _translationCache.clear();
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final translations = <String, String>{};
        
        for (final entry in data.entries) {
          if (entry.value is String) {
            translations[entry.key] = entry.value as String;
          }
        }
        
        _translationCache[doc.id] = translations;
      }
      
      _translationsController.add(Map.from(_translationCache));
      log.info('🔄 Updated general translations: \${_translationCache.length} languages');
    } catch (e) {
      log.severe('❌ Error handling translations update: \$e');
    }
  }

  /// Handle avatar translations updates from Firebase
  void _handleAvatarTranslationsUpdate(QuerySnapshot snapshot) {
    try {
      _avatarTranslationCache.clear();
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final languageTranslations = <String, LocalizedAvatarData>{};
        
        for (final entry in data.entries) {
          if (entry.value is Map<String, dynamic>) {
            final avatarData = entry.value as Map<String, dynamic>;
            languageTranslations[entry.key] = LocalizedAvatarData.fromMap(avatarData);
          }
        }
        
        _avatarTranslationCache[doc.id] = languageTranslations;
      }
      
      _avatarTranslationsController.add(Map.from(_avatarTranslationCache));
      log.info('🔄 Updated avatar translations: \${_avatarTranslationCache.length} avatars');
    } catch (e) {
      log.severe('❌ Error handling avatar translations update: \$e');
    }
  }

  /// Get translation for a specific key and language
  String translate(String key, String languageCode, {String? fallback}) {
    final translations = _translationCache[languageCode];
    if (translations != null && translations.containsKey(key)) {
      return translations[key]!;
    }
    
    // Fallback to English if translation not found
    final englishTranslations = _translationCache['en'];
    if (englishTranslations != null && englishTranslations.containsKey(key)) {
      return englishTranslations[key]!;
    }
    
    return fallback ?? key;
  }

  /// Get localized avatar data
  LocalizedAvatarData? getLocalizedAvatarData(String avatarId, String languageCode) {
    final avatarTranslations = _avatarTranslationCache[avatarId];
    if (avatarTranslations != null) {
      // Try to get translation for requested language
      if (avatarTranslations.containsKey(languageCode)) {
        return avatarTranslations[languageCode];
      }
      
      // Fallback to English
      if (avatarTranslations.containsKey('en')) {
        return avatarTranslations['en'];
      }
    }
    
    return null;
  }

  /// Add or update a translation
  Future<void> setTranslation(String languageCode, String key, String value) async {
    try {
      await _firestore.collection(_translationsCollection)
          .doc(languageCode)
          .set({key: value}, SetOptions(merge: true));
      
      log.info('✅ Updated translation for \$languageCode.\$key');
    } catch (e) {
      log.severe('❌ Failed to set translation: \$e');
      rethrow;
    }
  }

  /// Add or update avatar translation
  Future<void> setAvatarTranslation(String avatarId, String languageCode, LocalizedAvatarData data) async {
    try {
      await _firestore.collection(_avatarTranslationsCollection)
          .doc(avatarId)
          .set({languageCode: data.toMap()}, SetOptions(merge: true));
      
      log.info('✅ Updated avatar translation for \$avatarId (\$languageCode)');
    } catch (e) {
      log.severe('❌ Failed to set avatar translation: \$e');
      rethrow;
    }
  }

  /// Batch add avatar translations for all languages
  Future<void> addAvatarTranslations(String avatarId, Map<String, LocalizedAvatarData> translations) async {
    try {
      final batch = _firestore.batch();
      final docRef = _firestore.collection(_avatarTranslationsCollection).doc(avatarId);
      
      final data = <String, Map<String, dynamic>>{};
      for (final entry in translations.entries) {
        data[entry.key] = entry.value.toMap();
      }
      
      batch.set(docRef, data, SetOptions(merge: true));
      await batch.commit();
      
      log.info('✅ Batch updated avatar translations for \$avatarId (\${translations.length} languages)');
    } catch (e) {
      log.severe('❌ Failed to batch set avatar translations: \$e');
      rethrow;
    }
  }

  /// Dispose the service
  Future<void> dispose() async {
    await _translationsController.close();
    await _avatarTranslationsController.close();
    _translationCache.clear();
    _avatarTranslationCache.clear();
  }
}

/// Data class for localized avatar information
class LocalizedAvatarData {
  final String name;
  final String description;
  final String personality;
  final String speciality;

  const LocalizedAvatarData({
    required this.name,
    required this.description,
    required this.personality,
    required this.speciality,
  });

  factory LocalizedAvatarData.fromMap(Map<String, dynamic> map) {
    return LocalizedAvatarData(
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      personality: map['personality'] as String? ?? '',
      speciality: map['speciality'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'personality': personality,
      'speciality': speciality,
    };
  }

  LocalizedAvatarData copyWith({
    String? name,
    String? description,
    String? personality,
    String? speciality,
  }) {
    return LocalizedAvatarData(
      name: name ?? this.name,
      description: description ?? this.description,
      personality: personality ?? this.personality,
      speciality: speciality ?? this.speciality,
    );
  }
}

