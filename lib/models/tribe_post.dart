import 'package:cloud_firestore/cloud_firestore.dart';

enum TribePostType {
  text,
  image,
  achievement,
  question,
  announcement,
  event
}

class TribePost {
  final String id;
  final String tribeId;
  final String authorId;
  final String authorName;
  final String? authorPhotoURL;
  final TribePostType type;
  final String content;
  final String? title;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> likes;
  final int commentCount;
  final bool isPinned;
  final bool isAnnouncement;
  final Map<String, dynamic> metadata;
  final List<String> tags;

  TribePost({
    required this.id,
    required this.tribeId,
    required this.authorId,
    required this.authorName,
    this.authorPhotoURL,
    this.type = TribePostType.text,
    required this.content,
    this.title,
    this.imageUrls = const [],
    required this.createdAt,
    this.updatedAt,
    this.likes = const [],
    this.commentCount = 0,
    this.isPinned = false,
    this.isAnnouncement = false,
    this.metadata = const {},
    this.tags = const [],
  });

  factory TribePost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TribePost(
      id: doc.id,
      tribeId: data['tribeId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorPhotoURL: data['authorPhotoURL'],
      type: TribePostType.values[data['type'] ?? 0],
      content: data['content'] ?? '',
      title: data['title'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      likes: List<String>.from(data['likes'] ?? []),
      commentCount: data['commentCount'] ?? 0,
      isPinned: data['isPinned'] ?? false,
      isAnnouncement: data['isAnnouncement'] ?? false,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tribeId': tribeId,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoURL': authorPhotoURL,
      'type': type.index,
      'content': content,
      'title': title,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'likes': likes,
      'commentCount': commentCount,
      'isPinned': isPinned,
      'isAnnouncement': isAnnouncement,
      'metadata': metadata,
      'tags': tags,
    };
  }

  String getPostTypeIcon() {
    switch (type) {
      case TribePostType.text:
        return '💬';
      case TribePostType.image:
        return '📸';
      case TribePostType.achievement:
        return '🏆';
      case TribePostType.question:
        return '❓';
      case TribePostType.announcement:
        return '📢';
      case TribePostType.event:
        return '📅';
    }
  }

  String getPostTypeText() {
    switch (type) {
      case TribePostType.text:
        return 'Text Post';
      case TribePostType.image:
        return 'Image Post';
      case TribePostType.achievement:
        return 'Achievement';
      case TribePostType.question:
        return 'Question';
      case TribePostType.announcement:
        return 'Announcement';
      case TribePostType.event:
        return 'Event';
    }
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

  bool isLikedBy(String userId) {
    return likes.contains(userId);
  }

  bool get hasImages => imageUrls.isNotEmpty;
  bool get isEdited => updatedAt != null;

  TribePost copyWith({
    String? id,
    String? tribeId,
    String? authorId,
    String? authorName,
    String? authorPhotoURL,
    TribePostType? type,
    String? content,
    String? title,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? likes,
    int? commentCount,
    bool? isPinned,
    bool? isAnnouncement,
    Map<String, dynamic>? metadata,
    List<String>? tags,
  }) {
    return TribePost(
      id: id ?? this.id,
      tribeId: tribeId ?? this.tribeId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorPhotoURL: authorPhotoURL ?? this.authorPhotoURL,
      type: type ?? this.type,
      content: content ?? this.content,
      title: title ?? this.title,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likes: likes ?? this.likes,
      commentCount: commentCount ?? this.commentCount,
      isPinned: isPinned ?? this.isPinned,
      isAnnouncement: isAnnouncement ?? this.isAnnouncement,
      metadata: metadata ?? this.metadata,
      tags: tags ?? this.tags,
    );
  }
}