abstract class TranslationServiceInterface {
  Future<String> translate(String text, String targetLanguage, {String sourceLanguage = 'en'});

  Future<List<String>> translateBatch(
    List<String> texts,
    String targetLanguage, {
    String sourceLanguage = 'en'
  });

  bool get isAvailable;
  String get serviceName;
  int get maxTextLength;
  int get maxBatchSize;
}