import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'translation_service_interface.dart';

final log = Logger('ProductionTranslationService');

class ProductionTranslationService implements TranslationServiceInterface {
  // Google Cloud Translate API configuration
  static String get apiKey {
    const dartDefine = String.fromEnvironment('GOOGLE_TRANSLATE_API_KEY');
    if (dartDefine.isNotEmpty) return dartDefine;

    try {
      if (dotenv.isInitialized) {
        final key = dotenv.env['GOOGLE_TRANSLATE_API_KEY'];
        if (key != null && key.isNotEmpty) return key;
      }
    } catch (e) {
      log.warning('dotenv not initialized for Google Translate API key: $e');
    }

    return '';
  }

  static const String _baseUrl = 'https://translation.googleapis.com/language/translate/v2';

  @override
  String get serviceName => 'Google Cloud Translate API';

  @override
  bool get isAvailable => apiKey.isNotEmpty;

  @override
  int get maxTextLength => 30720; // Google Cloud Translate limit (30KB)

  @override
  int get maxBatchSize => 128; // Google Cloud supports larger batches

  @override
  Future<String> translate(
    String text,
    String targetLanguage, {
    String sourceLanguage = 'en'
  }) async {
    if (text.trim().isEmpty) return text;

    if (!isAvailable) {
      throw Exception('Google Cloud Translate API key not configured');
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'key': apiKey,
          'q': text,
          'source': sourceLanguage,
          'target': targetLanguage,
          'format': 'text',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translations = data['data']['translations'] as List;
        if (translations.isNotEmpty) {
          final translatedText = translations.first['translatedText'] as String;
          log.fine('Translated: "${text.substring(0, text.length.clamp(0, 50))}..." -> "$translatedText"');
          return translatedText;
        }
      } else if (response.statusCode == 400) {
        log.severe('Bad request to Google Translate API: ${response.body}');
        throw Exception('Invalid translation request');
      } else if (response.statusCode == 403) {
        log.severe('Google Translate API access denied: ${response.body}');
        throw Exception('Google Translate API access denied. Check your API key and billing.');
      } else if (response.statusCode == 429) {
        log.warning('Google Translate API rate limit exceeded');
        throw Exception('Translation rate limit exceeded. Please try again later.');
      }

      throw Exception('Translation failed with status: ${response.statusCode}');
    } catch (e) {
      log.severe('Translation error: $e');
      if (e.toString().contains('rate limit') || e.toString().contains('quota')) {
        rethrow;
      }
      return text; // Return original text on other errors
    }
  }

  @override
  Future<List<String>> translateBatch(
    List<String> texts,
    String targetLanguage, {
    String sourceLanguage = 'en'
  }) async {
    if (!isAvailable) {
      throw Exception('Google Cloud Translate API key not configured');
    }

    final translations = <String>[];

    // Process in chunks
    for (int i = 0; i < texts.length; i += maxBatchSize) {
      final chunk = texts.skip(i).take(maxBatchSize).toList();

      try {
        final response = await http.post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'key': apiKey,
            'q': chunk,
            'source': sourceLanguage,
            'target': targetLanguage,
            'format': 'text',
          }),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final apiTranslations = data['data']['translations'] as List;

          for (final translation in apiTranslations) {
            translations.add(translation['translatedText'] as String);
          }
        } else {
          // On batch failure, fall back to individual translations
          log.warning('Batch translation failed, falling back to individual requests');
          for (final text in chunk) {
            final translation = await translate(
              text,
              targetLanguage,
              sourceLanguage: sourceLanguage,
            );
            translations.add(translation);

            // Small delay to avoid rate limiting
            await Future.delayed(const Duration(milliseconds: 50));
          }
        }
      } catch (e) {
        log.warning('Batch translation chunk failed: $e');
        // Fall back to individual translations for this chunk
        for (final text in chunk) {
          try {
            final translation = await translate(
              text,
              targetLanguage,
              sourceLanguage: sourceLanguage,
            );
            translations.add(translation);
          } catch (e) {
            log.warning('Individual translation failed, using original text: $e');
            translations.add(text);
          }
        }
      }
    }

    return translations;
  }
}