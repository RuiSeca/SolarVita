import 'package:cloud_firestore/cloud_firestore.dart';

enum TribeCategory {
  fitness,
  eco,
  nutrition,
  mindfulness,
  cycling,
  running,
  yoga,
  zeroWaste,
  plantBased,
  custom
}

enum TribeVisibility {
  public,
  private
}

enum TribeMemberRole {
  member,
  admin,
  creator
}

class Tribe {
  final String id;
  final String name;
  final String description;
  final String creatorId;
  final String creatorName;
  final List<String> adminIds;
  final TribeCategory category;
  final String? customCategory;
  final TribeVisibility visibility;
  final String? inviteCode;
  final DateTime createdAt;
  final String? coverImage;
  final int memberCount;
  final Map<String, dynamic> settings;
  final List<String> tags;
  final String? location;

  Tribe({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.creatorName,
    this.adminIds = const [],
    required this.category,
    this.customCategory,
    this.visibility = TribeVisibility.public,
    this.inviteCode,
    required this.createdAt,
    this.coverImage,
    this.memberCount = 1,
    this.settings = const {},
    this.tags = const [],
    this.location,
  });

  factory Tribe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Tribe(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      creatorId: data['creatorId'] ?? '',
      creatorName: data['creatorName'] ?? '',
      adminIds: List<String>.from(data['adminIds'] ?? []),
      category: TribeCategory.values[data['category'] ?? 0],
      customCategory: data['customCategory'],
      visibility: TribeVisibility.values[data['visibility'] ?? 0],
      inviteCode: data['inviteCode'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      coverImage: data['coverImage'],
      memberCount: data['memberCount'] ?? 1,
      settings: Map<String, dynamic>.from(data['settings'] ?? {}),
      tags: List<String>.from(data['tags'] ?? []),
      location: data['location'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'adminIds': adminIds,
      'category': category.index,
      'customCategory': customCategory,
      'visibility': visibility.index,
      'inviteCode': inviteCode,
      'createdAt': Timestamp.fromDate(createdAt),
      'coverImage': coverImage,
      'memberCount': memberCount,
      'settings': settings,
      'tags': tags,
      'location': location,
    };
  }

  String getCategoryName() {
    if (category == TribeCategory.custom && customCategory != null) {
      return customCategory!;
    }
    
    switch (category) {
      case TribeCategory.fitness:
        return 'Fitness & Workouts';
      case TribeCategory.eco:
        return 'Eco & Sustainability';
      case TribeCategory.nutrition:
        return 'Plant-Based Nutrition';
      case TribeCategory.mindfulness:
        return 'Mindfulness';
      case TribeCategory.cycling:
        return 'Cycling';
      case TribeCategory.running:
        return 'Running';
      case TribeCategory.yoga:
        return 'Yoga';
      case TribeCategory.zeroWaste:
        return 'Zero Waste';
      case TribeCategory.plantBased:
        return 'Plant-Based Living';
      case TribeCategory.custom:
        return 'Custom';
    }
  }

  String getCategoryIcon() {
    switch (category) {
      case TribeCategory.fitness:
        return '💪';
      case TribeCategory.eco:
        return '🌱';
      case TribeCategory.nutrition:
        return '🥗';
      case TribeCategory.mindfulness:
        return '🧘';
      case TribeCategory.cycling:
        return '🚴';
      case TribeCategory.running:
        return '🏃';
      case TribeCategory.yoga:
        return '🧘‍♀️';
      case TribeCategory.zeroWaste:
        return '♻️';
      case TribeCategory.plantBased:
        return '🌿';
      case TribeCategory.custom:
        return '⭐';
    }
  }

  bool get isPrivate => visibility == TribeVisibility.private;
  bool get isPublic => visibility == TribeVisibility.public;
  
  String getVisibilityText() {
    return isPrivate ? 'Private' : 'Public';
  }

  Tribe copyWith({
    String? id,
    String? name,
    String? description,
    String? creatorId,
    String? creatorName,
    List<String>? adminIds,
    TribeCategory? category,
    String? customCategory,
    TribeVisibility? visibility,
    String? inviteCode,
    DateTime? createdAt,
    String? coverImage,
    int? memberCount,
    Map<String, dynamic>? settings,
    List<String>? tags,
    String? location,
  }) {
    return Tribe(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      adminIds: adminIds ?? this.adminIds,
      category: category ?? this.category,
      customCategory: customCategory ?? this.customCategory,
      visibility: visibility ?? this.visibility,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
      coverImage: coverImage ?? this.coverImage,
      memberCount: memberCount ?? this.memberCount,
      settings: settings ?? this.settings,
      tags: tags ?? this.tags,
      location: location ?? this.location,
    );
  }
}