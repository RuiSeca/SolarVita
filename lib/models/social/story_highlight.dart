import 'package:cloud_firestore/cloud_firestore.dart';

enum StoryContentType {
  image,
  video,
  textWithImage,
}

enum StoryHighlightCategory {
  workouts,
  progress,
  challenges,
  recovery,
  meals,
  cooking,
  hydration,
  ecoActions,
  nature,
  greenLiving,
  dailyLife,
  travel,
  community,
  motivation,
  custom, // For user-created categories
}

class StoryContent {
  final String id;
  final String userId;
  final String? mediaUrl; // Image or video URL
  final String? thumbnailUrl; // For videos
  final String? text; // For text content
  final StoryContentType contentType;
  final DateTime createdAt;
  final DateTime expiresAt; // Stories expire after 24 hours
  final Map<String, dynamic> metadata; // Additional data
  final bool isActive; // Whether story is still active (not expired)

  const StoryContent({
    required this.id,
    required this.userId,
    this.mediaUrl,
    this.thumbnailUrl,
    this.text,
    required this.contentType,
    required this.createdAt,
    required this.expiresAt,
    this.metadata = const {},
    required this.isActive,
  });

  factory StoryContent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoryContent(
      id: doc.id,
      userId: data['userId'] ?? '',
      mediaUrl: data['mediaUrl'],
      thumbnailUrl: data['thumbnailUrl'],
      text: data['text'],
      contentType: StoryContentType.values[data['contentType'] ?? 0],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      isActive: data['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'text': text,
      'contentType': contentType.index,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'metadata': metadata,
      'isActive': isActive,
    };
  }

  StoryContent copyWith({
    String? mediaUrl,
    String? thumbnailUrl,
    String? text,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return StoryContent(
      id: id,
      userId: userId,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      text: text ?? this.text,
      contentType: contentType,
      createdAt: createdAt,
      expiresAt: expiresAt,
      metadata: metadata ?? this.metadata,
      isActive: isActive ?? this.isActive,
    );
  }

  // Check if story is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class StoryHighlight {
  final String id;
  final String userId;
  final String title; // Display name for the highlight
  final String? customTitle; // For custom categories
  final StoryHighlightCategory category;
  final String coverImageUrl; // Thumbnail for the highlight circle
  final List<String> storyContentIds; // References to StoryContent
  final DateTime createdAt;
  final DateTime lastUpdated;
  final bool isVisible; // Privacy control
  final Map<String, dynamic> metadata;
  final int viewCount; // Number of times viewed
  final String? iconName; // Custom icon for highlight

  const StoryHighlight({
    required this.id,
    required this.userId,
    required this.title,
    this.customTitle,
    required this.category,
    required this.coverImageUrl,
    required this.storyContentIds,
    required this.createdAt,
    required this.lastUpdated,
    this.isVisible = true,
    this.metadata = const {},
    this.viewCount = 0,
    this.iconName,
  });

  factory StoryHighlight.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoryHighlight(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      customTitle: data['customTitle'],
      category: StoryHighlightCategory.values[data['category'] ?? 0],
      coverImageUrl: data['coverImageUrl'] ?? '',
      storyContentIds: List<String>.from(data['storyContentIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      isVisible: data['isVisible'] ?? true,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      viewCount: data['viewCount'] ?? 0,
      iconName: data['iconName'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'customTitle': customTitle,
      'category': category.index,
      'coverImageUrl': coverImageUrl,
      'storyContentIds': storyContentIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'isVisible': isVisible,
      'metadata': metadata,
      'viewCount': viewCount,
      'iconName': iconName,
    };
  }

  StoryHighlight copyWith({
    String? title,
    String? customTitle,
    String? coverImageUrl,
    List<String>? storyContentIds,
    DateTime? lastUpdated,
    bool? isVisible,
    Map<String, dynamic>? metadata,
    int? viewCount,
    String? iconName,
  }) {
    return StoryHighlight(
      id: id,
      userId: userId,
      title: title ?? this.title,
      customTitle: customTitle ?? this.customTitle,
      category: category,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      storyContentIds: storyContentIds ?? this.storyContentIds,
      createdAt: createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isVisible: isVisible ?? this.isVisible,
      metadata: metadata ?? this.metadata,
      viewCount: viewCount ?? this.viewCount,
      iconName: iconName ?? this.iconName,
    );
  }

  // Get display title (custom title if available, otherwise default title)
  String get displayTitle => customTitle?.isNotEmpty == true ? customTitle! : title;
}

// Story highlight category extensions
extension StoryHighlightCategoryExtension on StoryHighlightCategory {
  String get title {
    switch (this) {
      case StoryHighlightCategory.workouts:
        return 'Workouts';
      case StoryHighlightCategory.progress:
        return 'Progress';
      case StoryHighlightCategory.challenges:
        return 'Challenges';
      case StoryHighlightCategory.recovery:
        return 'Recovery';
      case StoryHighlightCategory.meals:
        return 'Meals';
      case StoryHighlightCategory.cooking:
        return 'Cooking';
      case StoryHighlightCategory.hydration:
        return 'Hydration';
      case StoryHighlightCategory.ecoActions:
        return 'Eco Actions';
      case StoryHighlightCategory.nature:
        return 'Nature';
      case StoryHighlightCategory.greenLiving:
        return 'Green Living';
      case StoryHighlightCategory.dailyLife:
        return 'Daily Life';
      case StoryHighlightCategory.travel:
        return 'Travel';
      case StoryHighlightCategory.community:
        return 'Community';
      case StoryHighlightCategory.motivation:
        return 'Motivation';
      case StoryHighlightCategory.custom:
        return 'Custom';
    }
  }

  String get iconName {
    switch (this) {
      case StoryHighlightCategory.workouts:
        return 'fitness_center';
      case StoryHighlightCategory.progress:
        return 'trending_up';
      case StoryHighlightCategory.challenges:
        return 'emoji_events';
      case StoryHighlightCategory.recovery:
        return 'spa';
      case StoryHighlightCategory.meals:
        return 'restaurant';
      case StoryHighlightCategory.cooking:
        return 'kitchen';
      case StoryHighlightCategory.hydration:
        return 'local_drink';
      case StoryHighlightCategory.ecoActions:
        return 'eco';
      case StoryHighlightCategory.nature:
        return 'nature';
      case StoryHighlightCategory.greenLiving:
        return 'park';
      case StoryHighlightCategory.dailyLife:
        return 'today';
      case StoryHighlightCategory.travel:
        return 'flight';
      case StoryHighlightCategory.community:
        return 'people';
      case StoryHighlightCategory.motivation:
        return 'psychology';
      case StoryHighlightCategory.custom:
        return 'star';
    }
  }

  List<int> get colorGradient {
    switch (this) {
      case StoryHighlightCategory.workouts:
        return [0xFFFF6B6B, 0xFFEE5A24]; // Red gradient
      case StoryHighlightCategory.progress:
        return [0xFF4ECDC4, 0xFF44A08D]; // Teal gradient
      case StoryHighlightCategory.challenges:
        return [0xFFFFC048, 0xFFFF9500]; // Orange gradient
      case StoryHighlightCategory.recovery:
        return [0xFF667EEA, 0xFF764BA2]; // Purple gradient
      case StoryHighlightCategory.meals:
        return [0xFF56AB2F, 0xFFA8E6CF]; // Green gradient
      case StoryHighlightCategory.cooking:
        return [0xFFFF8A80, 0xFFFFAB40]; // Pink-orange gradient
      case StoryHighlightCategory.hydration:
        return [0xFF36D1DC, 0xFF5B86E5]; // Blue gradient
      case StoryHighlightCategory.ecoActions:
        return [0xFF11998E, 0xFF38EF7D]; // Eco green gradient
      case StoryHighlightCategory.nature:
        return [0xFF134E5E, 0xFF71B280]; // Forest gradient
      case StoryHighlightCategory.greenLiving:
        return [0xFF7B920A, 0xFF8BC34A]; // Nature green gradient
      case StoryHighlightCategory.dailyLife:
        return [0xFF9D50BB, 0xFF6E48AA]; // Purple gradient
      case StoryHighlightCategory.travel:
        return [0xFF1E3C72, 0xFF2A5298]; // Travel blue gradient
      case StoryHighlightCategory.community:
        return [0xFFF093FB, 0xFFF5576C]; // Community pink gradient
      case StoryHighlightCategory.motivation:
        return [0xFF4FACFE, 0xFF00F2FE]; // Motivation cyan gradient
      case StoryHighlightCategory.custom:
        return [0xFF8E2DE2, 0xFF4A00E0]; // Custom purple gradient
    }
  }
}

// Story view record for analytics
class StoryView {
  final String id;
  final String storyContentId;
  final String viewerId;
  final String storyOwnerId;
  final DateTime viewedAt;
  final Duration viewDuration; // How long they viewed it
  final Map<String, dynamic> metadata;

  const StoryView({
    required this.id,
    required this.storyContentId,
    required this.viewerId,
    required this.storyOwnerId,
    required this.viewedAt,
    required this.viewDuration,
    this.metadata = const {},
  });

  factory StoryView.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoryView(
      id: doc.id,
      storyContentId: data['storyContentId'] ?? '',
      viewerId: data['viewerId'] ?? '',
      storyOwnerId: data['storyOwnerId'] ?? '',
      viewedAt: (data['viewedAt'] as Timestamp).toDate(),
      viewDuration: Duration(milliseconds: data['viewDurationMs'] ?? 0),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'storyContentId': storyContentId,
      'viewerId': viewerId,
      'storyOwnerId': storyOwnerId,
      'viewedAt': Timestamp.fromDate(viewedAt),
      'viewDurationMs': viewDuration.inMilliseconds,
      'metadata': metadata,
    };
  }
}