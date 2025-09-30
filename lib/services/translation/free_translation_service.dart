import 'package:translator/translator.dart';
import 'package:logging/logging.dart';
import 'translation_service_interface.dart';

final log = Logger('FreeTranslationService');

class FreeTranslationService implements TranslationServiceInterface {
  final GoogleTranslator _translator = GoogleTranslator();

  @override
  String get serviceName => 'Google Translator (Free)';

  @override
  bool get isAvailable => true;

  @override
  int get maxTextLength => 5000; // Conservative limit for free service

  @override
  int get maxBatchSize => 10; // Process in smaller batches for free service

  @override
  Future<String> translate(
    String text,
    String targetLanguage, {
    String sourceLanguage = 'en'
  }) async {
    if (text.trim().isEmpty) return text;

    // Handle long text by chunking
    if (text.length > maxTextLength) {
      return await _translateLongText(text, targetLanguage, sourceLanguage);
    }

    try {
      final translation = await _translator.translate(
        text,
        from: sourceLanguage,
        to: targetLanguage,
      );

      log.fine('Translated: "${text.substring(0, text.length.clamp(0, 50))}..." -> "${translation.text}"');
      return translation.text;
    } catch (e) {
      log.warning('Translation failed for text: ${text.substring(0, text.length.clamp(0, 50))}... Error: $e');
      return text; // Return original text on failure
    }
  }

  Future<String> _translateLongText(
    String text,
    String targetLanguage,
    String sourceLanguage,
  ) async {
    // Split text into sentences to maintain context
    final sentences = text.split(RegExp(r'(?<=[.!?])\s+'));
    final translatedSentences = <String>[];

    for (final sentence in sentences) {
      if (sentence.trim().isNotEmpty) {
        final translated = await translate(
          sentence.trim(),
          targetLanguage,
          sourceLanguage: sourceLanguage,
        );
        translatedSentences.add(translated);

        // Add delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    return translatedSentences.join(' ');
  }

  @override
  Future<List<String>> translateBatch(
    List<String> texts,
    String targetLanguage, {
    String sourceLanguage = 'en'
  }) async {
    final translations = <String>[];

    // Process in chunks to avoid overwhelming the service
    for (int i = 0; i < texts.length; i += maxBatchSize) {
      final chunk = texts.skip(i).take(maxBatchSize).toList();
      final chunkTranslations = <String>[];

      for (final text in chunk) {
        final translation = await translate(
          text,
          targetLanguage,
          sourceLanguage: sourceLanguage,
        );
        chunkTranslations.add(translation);

        // Rate limiting for free service
        await Future.delayed(const Duration(milliseconds: 150));
      }

      translations.addAll(chunkTranslations);

      // Longer delay between chunks
      if (i + maxBatchSize < texts.length) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    return translations;
  }
}