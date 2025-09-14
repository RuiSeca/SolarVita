
class WorkoutTemplate {
  final String id;
  final String name;
  final String description;
  final String category; // 'strength', 'cardio', 'flexibility', 'full_body', etc.
  final String difficulty; // 'beginner', 'intermediate', 'advanced'
  final int estimatedDuration; // in minutes
  final List<String> targetMuscles;
  final List<String> equipment; // 'none', 'dumbbells', 'barbell', etc.
  final List<TemplateExercise> exercises;
  final String? imageUrl;
  final bool isPremium;
  final bool isCustom; // User-created template
  final DateTime? createdAt;
  final int popularityScore; // For ranking templates

  const WorkoutTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.estimatedDuration,
    required this.targetMuscles,
    required this.equipment,
    required this.exercises,
    this.imageUrl,
    this.isPremium = false,
    this.isCustom = false,
    this.createdAt,
    this.popularityScore = 0,
  });

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) {
    return WorkoutTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      difficulty: json['difficulty'] as String,
      estimatedDuration: json['estimatedDuration'] as int,
      targetMuscles: List<String>.from(json['targetMuscles'] as List),
      equipment: List<String>.from(json['equipment'] as List),
      exercises: (json['exercises'] as List)
          .map((e) => TemplateExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      imageUrl: json['imageUrl'] as String?,
      isPremium: json['isPremium'] as bool? ?? false,
      isCustom: json['isCustom'] as bool? ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      popularityScore: json['popularityScore'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'estimatedDuration': estimatedDuration,
      'targetMuscles': targetMuscles,
      'equipment': equipment,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'imageUrl': imageUrl,
      'isPremium': isPremium,
      'isCustom': isCustom,
      'createdAt': createdAt?.toIso8601String(),
      'popularityScore': popularityScore,
    };
  }

  WorkoutTemplate copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? difficulty,
    int? estimatedDuration,
    List<String>? targetMuscles,
    List<String>? equipment,
    List<TemplateExercise>? exercises,
    String? imageUrl,
    bool? isPremium,
    bool? isCustom,
    DateTime? createdAt,
    int? popularityScore,
  }) {
    return WorkoutTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      targetMuscles: targetMuscles ?? this.targetMuscles,
      equipment: equipment ?? this.equipment,
      exercises: exercises ?? this.exercises,
      imageUrl: imageUrl ?? this.imageUrl,
      isPremium: isPremium ?? this.isPremium,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
      popularityScore: popularityScore ?? this.popularityScore,
    );
  }
}

class TemplateExercise {
  final String id;
  final String name;
  final String? description;
  final String category; // 'strength', 'cardio', 'flexibility'
  final List<TemplateSet> sets;
  final int? restSeconds;
  final String? notes;
  final String? videoUrl;
  final String? imageUrl;

  const TemplateExercise({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.sets,
    this.restSeconds,
    this.notes,
    this.videoUrl,
    this.imageUrl,
  });

  factory TemplateExercise.fromJson(Map<String, dynamic> json) {
    return TemplateExercise(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      sets: (json['sets'] as List)
          .map((e) => TemplateSet.fromJson(e as Map<String, dynamic>))
          .toList(),
      restSeconds: json['restSeconds'] as int?,
      notes: json['notes'] as String?,
      videoUrl: json['videoUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'sets': sets.map((e) => e.toJson()).toList(),
      'restSeconds': restSeconds,
      'notes': notes,
      'videoUrl': videoUrl,
      'imageUrl': imageUrl,
    };
  }

  TemplateExercise copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    List<TemplateSet>? sets,
    int? restSeconds,
    String? notes,
    String? videoUrl,
    String? imageUrl,
  }) {
    return TemplateExercise(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      sets: sets ?? this.sets,
      restSeconds: restSeconds ?? this.restSeconds,
      notes: notes ?? this.notes,
      videoUrl: videoUrl ?? this.videoUrl,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class TemplateSet {
  final int setNumber;
  final SetType type; // 'normal', 'warmup', 'dropset', 'superset'
  final int? targetReps;
  final int? minReps;
  final int? maxReps;
  final double? targetWeight;
  final double? targetDistance; // for cardio
  final int? targetDuration; // in seconds
  final String? notes;

  const TemplateSet({
    required this.setNumber,
    this.type = SetType.normal,
    this.targetReps,
    this.minReps,
    this.maxReps,
    this.targetWeight,
    this.targetDistance,
    this.targetDuration,
    this.notes,
  });

  factory TemplateSet.fromJson(Map<String, dynamic> json) {
    return TemplateSet(
      setNumber: json['setNumber'] as int,
      type: SetType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => SetType.normal,
      ),
      targetReps: json['targetReps'] as int?,
      minReps: json['minReps'] as int?,
      maxReps: json['maxReps'] as int?,
      targetWeight: json['targetWeight']?.toDouble(),
      targetDistance: json['targetDistance']?.toDouble(),
      targetDuration: json['targetDuration'] as int?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'setNumber': setNumber,
      'type': type.toString().split('.').last,
      'targetReps': targetReps,
      'minReps': minReps,
      'maxReps': maxReps,
      'targetWeight': targetWeight,
      'targetDistance': targetDistance,
      'targetDuration': targetDuration,
      'notes': notes,
    };
  }

  String get displayText {
    if (targetReps != null) {
      final weightText = targetWeight != null ? '${targetWeight!.toInt()}kg × ' : '';
      return '$weightText$targetReps reps';
    } else if (minReps != null && maxReps != null) {
      final weightText = targetWeight != null ? '${targetWeight!.toInt()}kg × ' : '';
      return '$weightText$minReps-$maxReps reps';
    } else if (targetDuration != null) {
      final minutes = targetDuration! ~/ 60;
      final seconds = targetDuration! % 60;
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    } else if (targetDistance != null) {
      return '${targetDistance!.toStringAsFixed(1)} km';
    }
    return 'Custom';
  }

  TemplateSet copyWith({
    int? setNumber,
    SetType? type,
    int? targetReps,
    int? minReps,
    int? maxReps,
    double? targetWeight,
    double? targetDistance,
    int? targetDuration,
    String? notes,
  }) {
    return TemplateSet(
      setNumber: setNumber ?? this.setNumber,
      type: type ?? this.type,
      targetReps: targetReps ?? this.targetReps,
      minReps: minReps ?? this.minReps,
      maxReps: maxReps ?? this.maxReps,
      targetWeight: targetWeight ?? this.targetWeight,
      targetDistance: targetDistance ?? this.targetDistance,
      targetDuration: targetDuration ?? this.targetDuration,
      notes: notes ?? this.notes,
    );
  }
}

enum SetType {
  normal,
  warmup,
  dropset,
  superset,
  amrap, // As Many Reps As Possible
  failure,
}

// Helper extensions
extension SetTypeExtension on SetType {
  String get displayName {
    switch (this) {
      case SetType.normal:
        return 'Normal';
      case SetType.warmup:
        return 'Warm-up';
      case SetType.dropset:
        return 'Drop Set';
      case SetType.superset:
        return 'Super Set';
      case SetType.amrap:
        return 'AMRAP';
      case SetType.failure:
        return 'To Failure';
    }
  }

  String get shortName {
    switch (this) {
      case SetType.normal:
        return '';
      case SetType.warmup:
        return 'W';
      case SetType.dropset:
        return 'D';
      case SetType.superset:
        return 'S';
      case SetType.amrap:
        return 'A';
      case SetType.failure:
        return 'F';
    }
  }
}