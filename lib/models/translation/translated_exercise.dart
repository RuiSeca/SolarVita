class TranslatedExercise {
  final String id;
  final String originalLanguage;
  final String targetLanguage;
  final String originalName;
  final String translatedName;
  final String originalDescription;
  final String translatedDescription;
  final List<String> originalInstructions;
  final List<String> translatedInstructions;
  final String? originalBodyPart;
  final String? translatedBodyPart;
  final String? originalTarget;
  final String? translatedTarget;
  final List<String> originalEquipment;
  final List<String> translatedEquipment;
  final List<String> originalTips;
  final List<String> translatedTips;
  final DateTime translatedAt;
  final String? gifUrl;
  final String? duration;
  final String? difficulty;
  final String? caloriesBurn;
  final double? rating;

  const TranslatedExercise({
    required this.id,
    required this.originalLanguage,
    required this.targetLanguage,
    required this.originalName,
    required this.translatedName,
    required this.originalDescription,
    required this.translatedDescription,
    required this.originalInstructions,
    required this.translatedInstructions,
    this.originalBodyPart,
    this.translatedBodyPart,
    this.originalTarget,
    this.translatedTarget,
    required this.originalEquipment,
    required this.translatedEquipment,
    required this.originalTips,
    required this.translatedTips,
    required this.translatedAt,
    this.gifUrl,
    this.duration,
    this.difficulty,
    this.caloriesBurn,
    this.rating,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'originalLanguage': originalLanguage,
      'targetLanguage': targetLanguage,
      'originalName': originalName,
      'translatedName': translatedName,
      'originalDescription': originalDescription,
      'translatedDescription': translatedDescription,
      'originalInstructions': originalInstructions.join('|||'),
      'translatedInstructions': translatedInstructions.join('|||'),
      'originalBodyPart': originalBodyPart,
      'translatedBodyPart': translatedBodyPart,
      'originalTarget': originalTarget,
      'translatedTarget': translatedTarget,
      'originalEquipment': originalEquipment.join('|||'),
      'translatedEquipment': translatedEquipment.join('|||'),
      'originalTips': originalTips.join('|||'),
      'translatedTips': translatedTips.join('|||'),
      'translatedAt': translatedAt.millisecondsSinceEpoch,
      'gifUrl': gifUrl,
      'duration': duration,
      'difficulty': difficulty,
      'caloriesBurn': caloriesBurn,
      'rating': rating,
    };
  }

  factory TranslatedExercise.fromMap(Map<String, dynamic> map) {
    return TranslatedExercise(
      id: map['id'] as String,
      originalLanguage: map['originalLanguage'] as String,
      targetLanguage: map['targetLanguage'] as String,
      originalName: map['originalName'] as String,
      translatedName: map['translatedName'] as String,
      originalDescription: map['originalDescription'] as String,
      translatedDescription: map['translatedDescription'] as String,
      originalInstructions: (map['originalInstructions'] as String? ?? '').split('|||'),
      translatedInstructions: (map['translatedInstructions'] as String? ?? '').split('|||'),
      originalBodyPart: map['originalBodyPart'] as String?,
      translatedBodyPart: map['translatedBodyPart'] as String?,
      originalTarget: map['originalTarget'] as String?,
      translatedTarget: map['translatedTarget'] as String?,
      originalEquipment: (map['originalEquipment'] as String? ?? '').split('|||'),
      translatedEquipment: (map['translatedEquipment'] as String? ?? '').split('|||'),
      originalTips: (map['originalTips'] as String? ?? '').split('|||'),
      translatedTips: (map['translatedTips'] as String? ?? '').split('|||'),
      translatedAt: DateTime.fromMillisecondsSinceEpoch(map['translatedAt'] as int),
      gifUrl: map['gifUrl'] as String?,
      duration: map['duration'] as String?,
      difficulty: map['difficulty'] as String?,
      caloriesBurn: map['caloriesBurn'] as String?,
      rating: (map['rating'] as num?)?.toDouble(),
    );
  }

  TranslatedExercise copyWith({
    String? id,
    String? originalLanguage,
    String? targetLanguage,
    String? originalName,
    String? translatedName,
    String? originalDescription,
    String? translatedDescription,
    List<String>? originalInstructions,
    List<String>? translatedInstructions,
    String? originalBodyPart,
    String? translatedBodyPart,
    String? originalTarget,
    String? translatedTarget,
    List<String>? originalEquipment,
    List<String>? translatedEquipment,
    List<String>? originalTips,
    List<String>? translatedTips,
    DateTime? translatedAt,
    String? gifUrl,
    String? duration,
    String? difficulty,
    String? caloriesBurn,
    double? rating,
  }) {
    return TranslatedExercise(
      id: id ?? this.id,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      originalName: originalName ?? this.originalName,
      translatedName: translatedName ?? this.translatedName,
      originalDescription: originalDescription ?? this.originalDescription,
      translatedDescription: translatedDescription ?? this.translatedDescription,
      originalInstructions: originalInstructions ?? this.originalInstructions,
      translatedInstructions: translatedInstructions ?? this.translatedInstructions,
      originalBodyPart: originalBodyPart ?? this.originalBodyPart,
      translatedBodyPart: translatedBodyPart ?? this.translatedBodyPart,
      originalTarget: originalTarget ?? this.originalTarget,
      translatedTarget: translatedTarget ?? this.translatedTarget,
      originalEquipment: originalEquipment ?? this.originalEquipment,
      translatedEquipment: translatedEquipment ?? this.translatedEquipment,
      originalTips: originalTips ?? this.originalTips,
      translatedTips: translatedTips ?? this.translatedTips,
      translatedAt: translatedAt ?? this.translatedAt,
      gifUrl: gifUrl ?? this.gifUrl,
      duration: duration ?? this.duration,
      difficulty: difficulty ?? this.difficulty,
      caloriesBurn: caloriesBurn ?? this.caloriesBurn,
      rating: rating ?? this.rating,
    );
  }
}