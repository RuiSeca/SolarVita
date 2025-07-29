// lib/models/post_revision.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'social_post.dart';

enum RevisionType {
  contentEdit,
  mediaAdd,
  mediaRemove,
  mediaReorder,
  pillarChange,
  visibilityChange,
  creation,
}

class PostRevision {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final DateTime timestamp;
  final RevisionType type;
  final String? previousContent;
  final String? newContent;
  final Map<String, dynamic>? previousData;
  final Map<String, dynamic>? newData;
  final String? editReason;
  final List<String>? changedFields;

  PostRevision({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.timestamp,
    required this.type,
    this.previousContent,
    this.newContent,
    this.previousData,
    this.newData,
    this.editReason,
    this.changedFields,
  });

  factory PostRevision.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return PostRevision(
      id: doc.id,
      postId: data['postId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: RevisionType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => RevisionType.contentEdit,
      ),
      previousContent: data['previousContent'],
      newContent: data['newContent'],
      previousData: data['previousData'],
      newData: data['newData'],
      editReason: data['editReason'],
      changedFields: data['changedFields'] != null 
          ? List<String>.from(data['changedFields']) 
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.toString(),
      'previousContent': previousContent,
      'newContent': newContent,
      'previousData': previousData,
      'newData': newData,
      'editReason': editReason,
      'changedFields': changedFields,
    };
  }

  // Alias methods for compatibility
  Map<String, dynamic> toMap() => toFirestore();

  factory PostRevision.fromMap(Map<String, dynamic> data, String id) {
    return PostRevision(
      id: id,
      postId: data['postId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: RevisionType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => RevisionType.contentEdit,
      ),
      previousContent: data['previousContent'],
      newContent: data['newContent'],
      previousData: data['previousData'],
      newData: data['newData'],
      editReason: data['editReason'],
      changedFields: data['changedFields'] != null 
          ? List<String>.from(data['changedFields']) 
          : null,
    );
  }

  // Helper methods
  String getRevisionSummary() {
    switch (type) {
      case RevisionType.creation:
        return 'Post created';
      case RevisionType.contentEdit:
        return 'Content updated';
      case RevisionType.mediaAdd:
        return 'Media added';
      case RevisionType.mediaRemove:
        return 'Media removed';
      case RevisionType.mediaReorder:
        return 'Media reordered';
      case RevisionType.pillarChange:
        return 'Categories updated';
      case RevisionType.visibilityChange:
        return 'Privacy settings changed';
    }
  }

  IconData getRevisionIcon() {
    switch (type) {
      case RevisionType.creation:
        return Icons.add_circle;
      case RevisionType.contentEdit:
        return Icons.edit;
      case RevisionType.mediaAdd:
        return Icons.add_photo_alternate;
      case RevisionType.mediaRemove:
        return Icons.remove_circle;
      case RevisionType.mediaReorder:
        return Icons.swap_vert;
      case RevisionType.pillarChange:
        return Icons.category;
      case RevisionType.visibilityChange:
        return Icons.visibility;
    }
  }

  Color getRevisionColor() {
    switch (type) {
      case RevisionType.creation:
        return Colors.green;
      case RevisionType.contentEdit:
        return Colors.blue;
      case RevisionType.mediaAdd:
        return Colors.purple;
      case RevisionType.mediaRemove:
        return Colors.red;
      case RevisionType.mediaReorder:
        return Colors.orange;
      case RevisionType.pillarChange:
        return Colors.teal;
      case RevisionType.visibilityChange:
        return Colors.indigo;
    }
  }

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

  // Create revision for different types of edits
  static PostRevision createContentEdit({
    required String postId,
    required String userId,
    required String userName,
    required String previousContent,
    required String newContent,
    String? editReason,
  }) {
    return PostRevision(
      id: '',
      postId: postId,
      userId: userId,
      userName: userName,
      timestamp: DateTime.now(),
      type: RevisionType.contentEdit,
      previousContent: previousContent,
      newContent: newContent,
      editReason: editReason,
      changedFields: ['content'],
    );
  }

  static PostRevision createMediaEdit({
    required String postId,
    required String userId,
    required String userName,
    required RevisionType type,
    required Map<String, dynamic> previousData,
    required Map<String, dynamic> newData,
    String? editReason,
  }) {
    return PostRevision(
      id: '',
      postId: postId,
      userId: userId,
      userName: userName,
      timestamp: DateTime.now(),
      type: type,
      previousData: previousData,
      newData: newData,
      editReason: editReason,
      changedFields: ['media'],
    );
  }

  static PostRevision createPillarEdit({
    required String postId,
    required String userId,
    required String userName,
    required List<PostPillar> previousPillars,
    required List<PostPillar> newPillars,
    String? editReason,
  }) {
    return PostRevision(
      id: '',
      postId: postId,
      userId: userId,
      userName: userName,
      timestamp: DateTime.now(),
      type: RevisionType.pillarChange,
      previousData: {
        'pillars': previousPillars.map((p) => p.toString()).toList(),
      },
      newData: {
        'pillars': newPillars.map((p) => p.toString()).toList(),
      },
      editReason: editReason,
      changedFields: ['pillars'],
    );
  }

  static PostRevision createVisibilityEdit({
    required String postId,
    required String userId,
    required String userName,
    required PostVisibility previousVisibility,
    required PostVisibility newVisibility,
    String? editReason,
  }) {
    return PostRevision(
      id: '',
      postId: postId,
      userId: userId,
      userName: userName,
      timestamp: DateTime.now(),
      type: RevisionType.visibilityChange,
      previousData: {
        'visibility': previousVisibility.toString(),
      },
      newData: {
        'visibility': newVisibility.toString(),
      },
      editReason: editReason,
      changedFields: ['visibility'],
    );
  }
}