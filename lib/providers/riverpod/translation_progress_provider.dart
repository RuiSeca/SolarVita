import 'package:flutter_riverpod/flutter_riverpod.dart';

class TranslationProgress {
  final String language;
  final String category;
  final int totalItems;
  final int translatedItems;
  final bool isActive;
  final String? errorMessage;

  // Separate tracking for meals and exercises
  final int totalMeals;
  final int completedMeals;
  final int totalExercises;
  final int completedExercises;
  final String currentPhase; // 'meals' or 'exercises'

  const TranslationProgress({
    required this.language,
    required this.category,
    required this.totalItems,
    required this.translatedItems,
    required this.isActive,
    this.errorMessage,
    this.totalMeals = 0,
    this.completedMeals = 0,
    this.totalExercises = 0,
    this.completedExercises = 0,
    this.currentPhase = '',
  });

  TranslationProgress copyWith({
    String? language,
    String? category,
    int? totalItems,
    int? translatedItems,
    bool? isActive,
    String? errorMessage,
    int? totalMeals,
    int? completedMeals,
    int? totalExercises,
    int? completedExercises,
    String? currentPhase,
  }) {
    return TranslationProgress(
      language: language ?? this.language,
      category: category ?? this.category,
      totalItems: totalItems ?? this.totalItems,
      translatedItems: translatedItems ?? this.translatedItems,
      isActive: isActive ?? this.isActive,
      errorMessage: errorMessage ?? this.errorMessage,
      totalMeals: totalMeals ?? this.totalMeals,
      completedMeals: completedMeals ?? this.completedMeals,
      totalExercises: totalExercises ?? this.totalExercises,
      completedExercises: completedExercises ?? this.completedExercises,
      currentPhase: currentPhase ?? this.currentPhase,
    );
  }

  double get progress => totalItems > 0 ? translatedItems / totalItems : 0.0;
  double get mealProgress => totalMeals > 0 ? completedMeals / totalMeals : 0.0;
  double get exerciseProgress => totalExercises > 0 ? completedExercises / totalExercises : 0.0;
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
    int totalMeals = 0,
    int totalExercises = 0,
  }) {
    state = TranslationProgress(
      language: language,
      category: category,
      totalItems: totalItems,
      translatedItems: 0,
      isActive: true,
      totalMeals: totalMeals,
      totalExercises: totalExercises,
      completedMeals: 0,
      completedExercises: 0,
      currentPhase: totalMeals > 0 ? 'meals' : 'exercises',
    );
  }

  void updateProgress(int translatedItems) {
    if (state.isActive) {
      state = state.copyWith(translatedItems: translatedItems);
    }
  }

  void updateMealProgress(int completedMeals) {
    if (state.isActive) {
      state = state.copyWith(
        completedMeals: completedMeals,
        currentPhase: 'meals',
        translatedItems: completedMeals,
      );
    }
  }

  void updateExerciseProgress(int completedExercises) {
    if (state.isActive) {
      state = state.copyWith(
        completedExercises: completedExercises,
        currentPhase: 'exercises',
        translatedItems: state.totalMeals + completedExercises,
      );
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