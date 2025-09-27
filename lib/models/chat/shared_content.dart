import 'package:cloud_firestore/cloud_firestore.dart';

enum SharedContentType {
  meal,
  workout,
  ecoTip,
  challengeInvite,
  achievement,
}

class SharedContent {
  final String id;
  final SharedContentType type;
  final String title;
  final String description;
  final String? imageUrl;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final String? actionText;
  final String? actionUrl;

  const SharedContent({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.data,
    required this.createdAt,
    this.imageUrl,
    this.actionText,
    this.actionUrl,
  });

  factory SharedContent.fromMap(Map<String, dynamic> map) {
    return SharedContent(
      id: map['id'] ?? '',
      type: SharedContentType.values[map['type'] ?? 0],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      actionText: map['actionText'],
      actionUrl: map['actionUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'actionText': actionText,
      'actionUrl': actionUrl,
    };
  }

  // Factory constructors for specific content types

  factory SharedContent.meal({
    required String mealId,
    required String mealName,
    required String description,
    required int calories,
    required Map<String, dynamic> nutrients,
    String? imageUrl,
    List<String>? ingredients,
  }) {
    return SharedContent(
      id: mealId,
      type: SharedContentType.meal,
      title: mealName,
      description: description,
      imageUrl: imageUrl,
      data: {
        'calories': calories,
        'nutrients': nutrients,
        'ingredients': ingredients ?? [],
        'mealId': mealId,
      },
      createdAt: DateTime.now(),
      actionText: 'View Meal',
    );
  }

  factory SharedContent.workout({
    required String workoutId,
    required String workoutName,
    required String description,
    required int duration,
    required List<Map<String, dynamic>> exercises,
    String? imageUrl,
    String? difficulty,
  }) {
    return SharedContent(
      id: workoutId,
      type: SharedContentType.workout,
      title: workoutName,
      description: description,
      imageUrl: imageUrl,
      data: {
        'duration': duration,
        'exercises': exercises,
        'difficulty': difficulty,
        'workoutId': workoutId,
      },
      createdAt: DateTime.now(),
      actionText: 'Try Workout',
    );
  }

  factory SharedContent.ecoTip({
    required String tipId,
    required String title,
    required String description,
    required String category,
    String? imageUrl,
    Map<String, dynamic>? impactData,
  }) {
    return SharedContent(
      id: tipId,
      type: SharedContentType.ecoTip,
      title: title,
      description: description,
      imageUrl: imageUrl,
      data: {
        'category': category,
        'impact': impactData ?? {},
        'tipId': tipId,
      },
      createdAt: DateTime.now(),
      actionText: 'Learn More',
    );
  }

  factory SharedContent.challengeInvite({
    required String challengeId,
    required String challengeName,
    required String description,
    required DateTime endDate,
    String? imageUrl,
    int? currentParticipants,
    String? prize,
  }) {
    return SharedContent(
      id: challengeId,
      type: SharedContentType.challengeInvite,
      title: challengeName,
      description: description,
      imageUrl: imageUrl,
      data: {
        'endDate': endDate.toIso8601String(),
        'currentParticipants': currentParticipants ?? 0,
        'prize': prize,
        'challengeId': challengeId,
      },
      createdAt: DateTime.now(),
      actionText: 'Join Challenge',
    );
  }

  factory SharedContent.achievement({
    required String achievementId,
    required String title,
    required String description,
    required String badge,
    String? imageUrl,
    Map<String, dynamic>? stats,
  }) {
    return SharedContent(
      id: achievementId,
      type: SharedContentType.achievement,
      title: title,
      description: description,
      imageUrl: imageUrl,
      data: {
        'badge': badge,
        'stats': stats ?? {},
        'achievementId': achievementId,
      },
      createdAt: DateTime.now(),
      actionText: 'View Achievement',
    );
  }

  // Getters for specific data types
  int? get calories => data['calories'];
  int? get duration => data['duration'];
  String? get category => data['category'];
  String? get difficulty => data['difficulty'];
  List<String>? get ingredients => List<String>.from(data['ingredients'] ?? []);
  List<Map<String, dynamic>>? get exercises =>
      List<Map<String, dynamic>>.from(data['exercises'] ?? []);
  Map<String, dynamic>? get nutrients =>
      Map<String, dynamic>.from(data['nutrients'] ?? {});
  Map<String, dynamic>? get impact =>
      Map<String, dynamic>.from(data['impact'] ?? {});

  DateTime? get endDate {
    final endDateStr = data['endDate'];
    return endDateStr != null ? DateTime.parse(endDateStr) : null;
  }

  int get currentParticipants => data['currentParticipants'] ?? 0;
  String? get prize => data['prize'];
  String? get badge => data['badge'];
  Map<String, dynamic>? get stats =>
      Map<String, dynamic>.from(data['stats'] ?? {});

  // Helper methods
  bool get isMeal => type == SharedContentType.meal;
  bool get isWorkout => type == SharedContentType.workout;
  bool get isEcoTip => type == SharedContentType.ecoTip;
  bool get isChallengeInvite => type == SharedContentType.challengeInvite;
  bool get isAchievement => type == SharedContentType.achievement;

  String get displayText {
    switch (type) {
      case SharedContentType.meal:
        return '🍽️ Shared a meal: $title';
      case SharedContentType.workout:
        return '💪 Shared a workout: $title';
      case SharedContentType.ecoTip:
        return '🌱 Eco tip: $title';
      case SharedContentType.challengeInvite:
        return '🏆 Challenge invitation: $title';
      case SharedContentType.achievement:
        return '🎉 Achievement unlocked: $title';
    }
  }
}