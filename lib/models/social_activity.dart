import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType {
  workout,
  meal,
  ecoAction,
  achievement,
  challenge
}

enum PostVisibility {
  supportersOnly,
  community,
  public
}

class SocialActivity {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoURL;
  final ActivityType type;
  final String title;
  final String description;
  final PostVisibility visibility;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final List<String> likes;
  final int commentsCount;

  SocialActivity({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoURL,
    required this.type,
    required this.title,
    required this.description,
    this.visibility = PostVisibility.supportersOnly,
    this.metadata,
    required this.createdAt,
    this.likes = const [],
    this.commentsCount = 0,
  });

  factory SocialActivity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SocialActivity(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoURL: data['userPhotoURL'],
      type: ActivityType.values[(data['type'] is int ? data['type'] : int.tryParse(data['type']?.toString() ?? '0')) ?? 0],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      visibility: PostVisibility.values[(data['visibility'] is int ? data['visibility'] : int.tryParse(data['visibility']?.toString() ?? '0')) ?? 0],
      metadata: data['metadata'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: List<String>.from(data['likes'] ?? []),
      commentsCount: data['commentsCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoURL': userPhotoURL,
      'type': type.index,
      'title': title,
      'description': description,
      'visibility': visibility.index,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
      'commentsCount': commentsCount,
    };
  }

  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }

  String getActivityIcon() {
    switch (type) {
      case ActivityType.workout:
        return '💪';
      case ActivityType.meal:
        return '🍽️';
      case ActivityType.ecoAction:
        return '🌱';
      case ActivityType.achievement:
        return '🏆';
      case ActivityType.challenge:
        return '🎯';
    }
  }

  String getVisibilityIcon() {
    switch (visibility) {
      case PostVisibility.supportersOnly:
        return '👥';
      case PostVisibility.community:
        return '🌍';
      case PostVisibility.public:
        return '🔓';
    }
  }

  String getVisibilityText() {
    switch (visibility) {
      case PostVisibility.supportersOnly:
        return 'Friends only';
      case PostVisibility.community:
        return 'Community';
      case PostVisibility.public:
        return 'Public';
    }
  }
}