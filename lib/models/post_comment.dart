// lib/models/post_comment.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'social_post.dart';
import 'user_mention.dart';

class PostComment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String content;
  final String? mediaUrl;
  final String? parentCommentId; // For threaded comments
  final List<String> childCommentIds; // Track reply IDs
  final Map<String, ReactionType> reactions;
  final DateTime timestamp;
  final DateTime? editedAt;
  final bool isEdited;
  final int replyCount;
  final List<MentionInfo> mentions;
  final bool isPinned;

  PostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.content,
    this.mediaUrl,
    this.parentCommentId,
    required this.childCommentIds,
    required this.reactions,
    required this.timestamp,
    this.editedAt,
    required this.isEdited,
    required this.replyCount,
    this.mentions = const [],
    this.isPinned = false,
  });

  factory PostComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return PostComment(
      id: doc.id,
      postId: data['postId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userAvatarUrl: data['userAvatarUrl'],
      content: data['content'] ?? '',
      mediaUrl: data['mediaUrl'],
      parentCommentId: data['parentCommentId'],
      childCommentIds: List<String>.from(data['childCommentIds'] ?? []),
      reactions: Map<String, ReactionType>.from(
        (data['reactions'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(
            key,
            ReactionType.values.firstWhere(
              (e) => e.toString() == value,
              orElse: () => ReactionType.like,
            ),
          ),
        ) ?? {},
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
      isEdited: data['isEdited'] ?? false,
      replyCount: data['replyCount'] ?? 0,
      mentions: (data['mentions'] as List<dynamic>?)
          ?.map((m) => MentionInfo.fromMap(m))
          .toList() ?? [],
      isPinned: data['isPinned'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'content': content,
      'mediaUrl': mediaUrl,
      'parentCommentId': parentCommentId,
      'childCommentIds': childCommentIds,
      'reactions': reactions.map((key, value) => MapEntry(key, value.toString())),
      'timestamp': Timestamp.fromDate(timestamp),
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'isEdited': isEdited,
      'replyCount': replyCount,
      'mentions': mentions.map((m) => m.toMap()).toList(),
      'isPinned': isPinned,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'content': content,
      'mediaUrl': mediaUrl,
      'parentCommentId': parentCommentId,
      'childCommentIds': childCommentIds,
      'reactions': reactions.map((key, value) => MapEntry(key, value.toString())),
      'timestamp': timestamp.toIso8601String(),
      'editedAt': editedAt?.toIso8601String(),
      'isEdited': isEdited,
      'replyCount': replyCount,
      'mentions': mentions.map((m) => m.toMap()).toList(),
      'isPinned': isPinned,
    };
  }

  factory PostComment.fromMap(Map<String, dynamic> map) {
    return PostComment(
      id: map['id'] ?? '',
      postId: map['postId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userAvatarUrl: map['userAvatarUrl'],
      content: map['content'] ?? '',
      mediaUrl: map['mediaUrl'],
      parentCommentId: map['parentCommentId'],
      childCommentIds: List<String>.from(map['childCommentIds'] ?? []),
      reactions: Map<String, ReactionType>.from(
        (map['reactions'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(
            key,
            ReactionType.values.firstWhere(
              (e) => e.toString() == value,
              orElse: () => ReactionType.like,
            ),
          ),
        ) ?? {},
      ),
      timestamp: map['timestamp'] is String 
          ? DateTime.parse(map['timestamp'])
          : (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      editedAt: map['editedAt'] != null 
          ? (map['editedAt'] is String 
              ? DateTime.parse(map['editedAt'])
              : (map['editedAt'] as Timestamp?)?.toDate())
          : null,
      isEdited: map['isEdited'] ?? false,
      replyCount: map['replyCount'] ?? 0,
      mentions: (map['mentions'] as List<dynamic>?)
          ?.map((m) => MentionInfo.fromMap(m))
          .toList() ?? [],
      isPinned: map['isPinned'] ?? false,
    );
  }

  // Helper methods
  bool get hasReplies => replyCount > 0;
  bool get isReply => parentCommentId != null;
  int get totalReactions => reactions.length;
  
  bool hasUserReacted(String userId) => reactions.containsKey(userId);
  ReactionType? getUserReaction(String userId) => reactions[userId];

  // Get formatted timestamp
  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Copy with method for updates
  PostComment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    String? content,
    String? mediaUrl,
    String? parentCommentId,
    List<String>? childCommentIds,
    Map<String, ReactionType>? reactions,
    DateTime? timestamp,
    DateTime? editedAt,
    bool? isEdited,
    int? replyCount,
    List<MentionInfo>? mentions,
    bool? isPinned,
  }) {
    return PostComment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      childCommentIds: childCommentIds ?? this.childCommentIds,
      reactions: reactions ?? this.reactions,
      timestamp: timestamp ?? this.timestamp,
      editedAt: editedAt ?? this.editedAt,
      isEdited: isEdited ?? this.isEdited,
      replyCount: replyCount ?? this.replyCount,
      mentions: mentions ?? this.mentions,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}

// Comment thread structure for organizing nested comments
class CommentThread {
  final PostComment comment;
  final List<PostComment> replies;
  final bool hasMoreReplies;
  final int totalReplies;

  CommentThread({
    required this.comment,
    required this.replies,
    required this.hasMoreReplies,
    required this.totalReplies,
  });
}