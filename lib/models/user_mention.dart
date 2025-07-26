// lib/models/user_mention.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserMention {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String displayName;
  final String postId;
  final String? commentId;
  final DateTime timestamp;
  final bool isRead;

  UserMention({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.displayName,
    required this.postId,
    this.commentId,
    required this.timestamp,
    required this.isRead,
  });

  factory UserMention.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserMention(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userAvatarUrl: data['userAvatarUrl'],
      displayName: data['displayName'] ?? '',
      postId: data['postId'] ?? '',
      commentId: data['commentId'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'displayName': displayName,
      'postId': postId,
      'commentId': commentId,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }

  UserMention copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    String? displayName,
    String? postId,
    String? commentId,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return UserMention(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      displayName: displayName ?? this.displayName,
      postId: postId ?? this.postId,
      commentId: commentId ?? this.commentId,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

class MentionableUser {
  final String userId;
  final String userName;
  final String displayName;
  final String? avatarUrl;
  final bool isFollowing;
  final bool isSupporter;

  MentionableUser({
    required this.userId,
    required this.userName,
    required this.displayName,
    this.avatarUrl,
    required this.isFollowing,
    required this.isSupporter,
  });

  factory MentionableUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return MentionableUser(
      userId: doc.id,
      userName: data['userName'] ?? '',
      displayName: data['displayName'] ?? '',
      avatarUrl: data['avatarUrl'],
      isFollowing: data['isFollowing'] ?? false,
      isSupporter: data['isSupporter'] ?? false,
    );
  }

  // For local search and filtering
  bool matchesQuery(String query) {
    final lowerQuery = query.toLowerCase();
    return userName.toLowerCase().contains(lowerQuery) ||
           displayName.toLowerCase().contains(lowerQuery);
  }
}

class MentionInfo {
  final int startIndex;
  final int endIndex;
  final String userId;
  final String userName;
  final String displayName;

  MentionInfo({
    required this.startIndex,
    required this.endIndex,
    required this.userId,
    required this.userName,
    required this.displayName,
  });

  String get mentionText => '@$userName';
  int get length => endIndex - startIndex;
  
  Map<String, dynamic> toJson() {
    return {
      'startIndex': startIndex,
      'endIndex': endIndex,
      'userId': userId,
      'userName': userName,
      'displayName': displayName,
    };
  }

  factory MentionInfo.fromJson(Map<String, dynamic> json) {
    return MentionInfo(
      startIndex: json['startIndex'],
      endIndex: json['endIndex'],
      userId: json['userId'],
      userName: json['userName'],
      displayName: json['displayName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startIndex': startIndex,
      'endIndex': endIndex,
      'userId': userId,
      'userName': userName,
      'displayName': displayName,
    };
  }

  factory MentionInfo.fromMap(Map<String, dynamic> map) {
    return MentionInfo(
      startIndex: map['startIndex'] ?? 0,
      endIndex: map['endIndex'] ?? 0,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      displayName: map['displayName'] ?? '',
    );
  }
}