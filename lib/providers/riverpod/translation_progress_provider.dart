import 'package:flutter_riverpod/flutter_riverpod.dart';

class TranslationProgress {
  final String language;
  final String category;
  final int totalItems;
  final int translatedItems;
  final bool isActive;
  final String? errorMessage;

  const TranslationProgress({
    required this.language,
    required this.category,
    required this.totalItems,
    required this.translatedItems,
    required this.isActive,
    this.errorMessage,
  });

  TranslationProgress copyWith({
    String? language,
    String? category,
    int? totalItems,
    int? translatedItems,
    bool? isActive,
    String? errorMessage,
  }) {
    return TranslationProgress(
      language: language ?? this.language,
      category: category ?? this.category,
      totalItems: totalItems ?? this.totalItems,
      translatedItems: translatedItems ?? this.translatedItems,
      isActive: isActive ?? this.isActive,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  double get progress => totalItems > 0 ? translatedItems / totalItems : 0.0;
  bool get isCompleted => translatedItems >= totalItems && totalItems > 0;
  bool get hasError => errorMessage != null;
}

class TranslationProgressNotifier extends StateNotifier<TranslationProgress> {
  TranslationProgressNotifier()
      : super(const TranslationProgress(
          language: '',
          category: '',
          totalItems: 0,
          translatedItems: 0,
          isActive: false,
        ));

  void startProgress({
    required String language,
    required String category,
    required int totalItems,
  }) {
    state = TranslationProgress(
      language: language,
      category: category,
      totalItems: totalItems,
      translatedItems: 0,
      isActive: true,
    );
  }

  void updateProgress(int translatedItems) {
    if (state.isActive) {
      state = state.copyWith(translatedItems: translatedItems);
    }
  }

  void completeProgress() {
    state = state.copyWith(
      isActive: false,
      translatedItems: state.totalItems,
    );
  }

  void errorProgress(String errorMessage) {
    state = state.copyWith(
      isActive: false,
      errorMessage: errorMessage,
    );
  }

  void resetProgress() {
    state = const TranslationProgress(
      language: '',
      category: '',
      totalItems: 0,
      translatedItems: 0,
      isActive: false,
    );
  }
}

final translationProgressProvider =
    StateNotifierProvider<TranslationProgressNotifier, TranslationProgress>(
  (ref) => TranslationProgressNotifier(),
);