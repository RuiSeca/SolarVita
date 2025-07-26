// lib/services/firebase_comments_service.dart

import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/post_comment.dart';
import '../models/user_mention.dart';
import '../models/social_post.dart';

/// Comprehensive Firebase service for handling post comments with real-time updates
class FirebaseCommentsService {
  static final FirebaseCommentsService _instance = FirebaseCommentsService._internal();
  factory FirebaseCommentsService() => _instance;
  FirebaseCommentsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  String? get currentUserId => _auth.currentUser?.uid;
  User? get currentUser => _auth.currentUser;

  /// Create a new comment on a post
  Future<PostComment> createComment({
    required String postId,
    required String content,
    String? parentCommentId,
    File? mediaFile,
    List<MentionInfo>? mentions,
  }) async {
    if (currentUserId == null) {
      throw Exception('User must be authenticated to comment');
    }

    final user = currentUser!;
    final commentId = _uuid.v4();
    
    try {
      // Upload media file if provided
      String? mediaUrl;
      if (mediaFile != null) {
        mediaUrl = await _uploadCommentMedia(commentId, mediaFile);
      }

      // Create the comment object
      final comment = PostComment(
        id: commentId,
        postId: postId,
        userId: currentUserId!,
        userName: user.displayName ?? 'Anonymous User',
        userAvatarUrl: user.photoURL,
        content: content,
        parentCommentId: parentCommentId,
        mediaUrl: mediaUrl,
        mentions: mentions ?? [],
        reactions: {},
        timestamp: DateTime.now(),
        isEdited: false,
        replyCount: 0,
        childCommentIds: [],
      );

      // Save to Firestore
      await _firestore.collection('post_comments').doc(commentId).set(comment.toFirestore());

      // Update post comment count
      await _incrementPostCommentCount(postId);

      // Update parent comment reply count if this is a reply
      if (parentCommentId != null) {
        await _incrementCommentReplyCount(parentCommentId, commentId);
      }

      // Send notifications to mentioned users
      if (mentions != null && mentions.isNotEmpty) {
        await _sendMentionNotifications(comment, mentions);
      }

      // Send notification to post author (if not commenting on own post)
      await _sendCommentNotification(comment);

      return comment;
    } catch (e) {
      // Clean up uploaded media if comment creation fails
      await _cleanupCommentMedia(commentId);
      rethrow;
    }
  }

  /// Get comments for a post with real-time updates
  Stream<List<PostComment>> getPostComments(String postId, {int limit = 50}) {
    return _firestore
        .collection('post_comments')
        .where('postId', isEqualTo: postId)
        .where('parentCommentId', isNull: true) // Only top-level comments
        .orderBy('timestamp', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PostComment.fromFirestore(doc))
          .toList();
    });
  }

  /// Get replies for a specific comment
  Stream<List<PostComment>> getCommentReplies(String commentId, {int limit = 20}) {
    return _firestore
        .collection('post_comments')
        .where('parentCommentId', isEqualTo: commentId)
        .orderBy('timestamp', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PostComment.fromFirestore(doc))
          .toList();
    });
  }

  /// Get organized comment threads (comments with their replies)
  Stream<List<CommentThread>> getCommentThreads(String postId, {int limit = 20}) {
    return getPostComments(postId, limit: limit).asyncMap((comments) async {
      final threads = <CommentThread>[];
      
      for (final comment in comments) {
        // Get replies for this comment
        final repliesSnapshot = await _firestore
            .collection('post_comments')
            .where('parentCommentId', isEqualTo: comment.id)
            .orderBy('timestamp', descending: false)
            .limit(5) // Show first 5 replies
            .get();
        
        final replies = repliesSnapshot.docs
            .map((doc) => PostComment.fromFirestore(doc))
            .toList();
        
        final thread = CommentThread(
          comment: comment,
          replies: replies,
          hasMoreReplies: comment.replyCount > replies.length,
          totalReplies: comment.replyCount,
        );
        
        threads.add(thread);
      }
      
      return threads;
    });
  }

  /// Load more replies for a comment
  Future<List<PostComment>> loadMoreReplies(String commentId, {
    int limit = 10,
    DocumentSnapshot? lastDoc,
  }) async {
    Query query = _firestore
        .collection('post_comments')
        .where('parentCommentId', isEqualTo: commentId)
        .orderBy('timestamp', descending: false)
        .limit(limit);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => PostComment.fromFirestore(doc))
        .toList();
  }

  /// Update a comment
  Future<PostComment> updateComment({
    required String commentId,
    required String newContent,
    File? newMediaFile,
    bool removeMedia = false,
    List<MentionInfo>? mentions,
  }) async {
    if (currentUserId == null) {
      throw Exception('User must be authenticated to edit comments');
    }

    final commentDoc = await _firestore.collection('post_comments').doc(commentId).get();
    if (!commentDoc.exists) {
      throw Exception('Comment not found');
    }

    final existingComment = PostComment.fromFirestore(commentDoc);
    
    // Check if user can edit this comment
    if (existingComment.userId != currentUserId) {
      throw Exception('You can only edit your own comments');
    }

    try {
      String? mediaUrl = existingComment.mediaUrl;

      // Handle media updates
      if (removeMedia && mediaUrl != null) {
        await _deleteCommentMedia(mediaUrl);
        mediaUrl = null;
      } else if (newMediaFile != null) {
        // Remove old media if exists
        if (mediaUrl != null) {
          await _deleteCommentMedia(mediaUrl);
        }
        // Upload new media
        mediaUrl = await _uploadCommentMedia(commentId, newMediaFile);
      }

      // Create updated comment
      final updatedComment = existingComment.copyWith(
        content: newContent,
        mediaUrl: mediaUrl,
        mentions: mentions ?? existingComment.mentions,
        isEdited: true,
        editedAt: DateTime.now(),
      );

      // Save updates to Firestore
      await _firestore.collection('post_comments').doc(commentId).update(updatedComment.toFirestore());

      // Send notifications to newly mentioned users
      if (mentions != null && mentions.isNotEmpty) {
        await _sendMentionNotifications(updatedComment, mentions);
      }

      return updatedComment;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a comment
  Future<void> deleteComment(String commentId) async {
    if (currentUserId == null) {
      throw Exception('User must be authenticated to delete comments');
    }

    final commentDoc = await _firestore.collection('post_comments').doc(commentId).get();
    if (!commentDoc.exists) {
      throw Exception('Comment not found');
    }

    final comment = PostComment.fromFirestore(commentDoc);
    
    // Check if user can delete this comment
    if (comment.userId != currentUserId) {
      throw Exception('You can only delete your own comments');
    }

    try {
      // Delete media file if exists
      if (comment.mediaUrl != null) {
        await _deleteCommentMedia(comment.mediaUrl!);
      }

      // Delete all replies to this comment
      if (comment.replyCount > 0) {
        await _deleteCommentReplies(commentId);
      }

      // Update parent comment reply count if this is a reply
      if (comment.parentCommentId != null) {
        await _decrementCommentReplyCount(comment.parentCommentId!, commentId);
      }

      // Delete the comment
      await _firestore.collection('post_comments').doc(commentId).delete();

      // Update post comment count
      await _decrementPostCommentCount(comment.postId);
    } catch (e) {
      rethrow;
    }
  }

  /// React to a comment
  Future<void> reactToComment(String commentId, ReactionType reaction) async {
    if (currentUserId == null) {
      throw Exception('User must be authenticated to react to comments');
    }

    final commentRef = _firestore.collection('post_comments').doc(commentId);

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(commentRef);
      if (!doc.exists) {
        throw Exception('Comment not found');
      }

      final comment = PostComment.fromFirestore(doc);
      final updatedReactions = Map<String, ReactionType>.from(comment.reactions);

      if (updatedReactions.containsKey(currentUserId!) && 
          updatedReactions[currentUserId!] == reaction) {
        // Remove reaction if same reaction is clicked
        updatedReactions.remove(currentUserId!);
      } else {
        // Add or update reaction
        updatedReactions[currentUserId!] = reaction;
      }

      transaction.update(commentRef, {'reactions': _reactionsToFirestore(updatedReactions)});
    });
  }

  /// Get a specific comment by ID
  Future<PostComment?> getCommentById(String commentId) async {
    try {
      final doc = await _firestore.collection('post_comments').doc(commentId).get();
      if (doc.exists) {
        return PostComment.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Search for users to mention in comments
  Future<List<MentionInfo>> searchMentionUsers(String query) async {
    if (query.isEmpty) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('username', isLessThan: '${query.toLowerCase()}z')
          .limit(10)
          .get();

      final mentionUsers = <MentionInfo>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final mention = MentionInfo(
          startIndex: 0,
          endIndex: 0,
          userId: doc.id,
          userName: data['username'] ?? '',
          displayName: data['displayName'] ?? 'Unknown User',
        );
        mentionUsers.add(mention);
      }

      return mentionUsers;
    } catch (e) {
      return [];
    }
  }

  /// Report a comment
  Future<void> reportComment({
    required String commentId,
    required String reason,
    String? details,
  }) async {
    if (currentUserId == null) {
      throw Exception('User must be authenticated to report comments');
    }

    final reportId = _uuid.v4();
    final report = {
      'id': reportId,
      'commentId': commentId,
      'reporterId': currentUserId!,
      'reason': reason,
      'details': details,
      'status': 'pending',
      'createdAt': Timestamp.now(),
    };

    await _firestore.collection('comment_reports').doc(reportId).set(report);
  }

  /// Pin/unpin a comment (for post authors)
  Future<void> togglePinComment(String commentId, String postId) async {
    if (currentUserId == null) {
      throw Exception('User must be authenticated to pin comments');
    }

    // Check if current user is the post author
    final postDoc = await _firestore.collection('social_posts').doc(postId).get();
    if (!postDoc.exists) {
      throw Exception('Post not found');
    }

    final postData = postDoc.data()!;
    if (postData['userId'] != currentUserId) {
      throw Exception('Only post authors can pin comments');
    }

    final commentRef = _firestore.collection('post_comments').doc(commentId);
    
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(commentRef);
      if (!doc.exists) {
        throw Exception('Comment not found');
      }

      final comment = PostComment.fromFirestore(doc);
      transaction.update(commentRef, {'isPinned': !comment.isPinned});
    });
  }

  // PRIVATE HELPER METHODS

  /// Upload comment media to Firebase Storage
  Future<String> _uploadCommentMedia(String commentId, File file) async {
    final fileName = '${_uuid.v4()}_${DateTime.now().millisecondsSinceEpoch}';
    final extension = file.path.split('.').last;
    final ref = _storage.ref().child('comments/$commentId/$fileName.$extension');
    
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Delete comment media from Firebase Storage
  Future<void> _deleteCommentMedia(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      // File might already be deleted or not exist
    }
  }

  /// Clean up comment media (used when comment creation fails)
  Future<void> _cleanupCommentMedia(String commentId) async {
    try {
      final ref = _storage.ref().child('comments/$commentId');
      final result = await ref.listAll();
      
      for (final item in result.items) {
        await item.delete();
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  /// Delete all replies to a comment
  Future<void> _deleteCommentReplies(String commentId) async {
    final snapshot = await _firestore
        .collection('post_comments')
        .where('parentCommentId', isEqualTo: commentId)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      final reply = PostComment.fromFirestore(doc);
      
      // Delete media if exists
      if (reply.mediaUrl != null) {
        await _deleteCommentMedia(reply.mediaUrl!);
      }
      
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }

  /// Increment post comment count
  Future<void> _incrementPostCommentCount(String postId) async {
    final postRef = _firestore.collection('social_posts').doc(postId);
    
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(postRef);
      if (doc.exists) {
        final currentCount = doc.data()?['commentCount'] ?? 0;
        transaction.update(postRef, {'commentCount': currentCount + 1});
      }
    });
  }

  /// Decrement post comment count
  Future<void> _decrementPostCommentCount(String postId) async {
    final postRef = _firestore.collection('social_posts').doc(postId);
    
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(postRef);
      if (doc.exists) {
        final currentCount = doc.data()?['commentCount'] ?? 0;
        final newCount = (currentCount - 1).clamp(0, double.infinity).toInt();
        transaction.update(postRef, {'commentCount': newCount});
      }
    });
  }

  /// Increment comment reply count and update child comment IDs
  Future<void> _incrementCommentReplyCount(String parentCommentId, String replyId) async {
    final commentRef = _firestore.collection('post_comments').doc(parentCommentId);
    
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(commentRef);
      if (doc.exists) {
        final comment = PostComment.fromFirestore(doc);
        final updatedChildIds = List<String>.from(comment.childCommentIds);
        
        if (!updatedChildIds.contains(replyId)) {
          updatedChildIds.add(replyId);
          
          transaction.update(commentRef, {
            'replyCount': comment.replyCount + 1,
            'childCommentIds': updatedChildIds,
          });
        }
      }
    });
  }

  /// Decrement comment reply count and update child comment IDs
  Future<void> _decrementCommentReplyCount(String parentCommentId, String replyId) async {
    final commentRef = _firestore.collection('post_comments').doc(parentCommentId);
    
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(commentRef);
      if (doc.exists) {
        final comment = PostComment.fromFirestore(doc);
        final updatedChildIds = List<String>.from(comment.childCommentIds);
        
        if (updatedChildIds.contains(replyId)) {
          updatedChildIds.remove(replyId);
          
          final newCount = (comment.replyCount - 1).clamp(0, double.infinity).toInt();
          
          transaction.update(commentRef, {
            'replyCount': newCount,
            'childCommentIds': updatedChildIds,
          });
        }
      }
    });
  }

  /// Send notifications to mentioned users
  Future<void> _sendMentionNotifications(PostComment comment, List<MentionInfo> mentions) async {
    for (final mention in mentions) {
      if (mention.userId != currentUserId) {
        final notificationId = _uuid.v4();
        final notification = {
          'id': notificationId,
          'userId': mention.userId,
          'type': 'comment_mention',
          'title': 'You were mentioned in a comment',
          'body': '${comment.userName} mentioned you: ${comment.content}',
          'data': {
            'commentId': comment.id,
            'postId': comment.postId,
            'mentionedBy': comment.userId,
            'mentionedByName': comment.userName,
          },
          'isRead': false,
          'createdAt': Timestamp.now(),
        };
        
        await _firestore.collection('notifications').doc(notificationId).set(notification);
      }
    }
  }

  /// Send notification to post author
  Future<void> _sendCommentNotification(PostComment comment) async {
    try {
      // Get the post to find the author
      final postDoc = await _firestore.collection('social_posts').doc(comment.postId).get();
      if (postDoc.exists) {
        final postData = postDoc.data()!;
        final postAuthorId = postData['userId'] as String;
        
        // Don't notify if commenting on own post
        if (postAuthorId != currentUserId) {
          final notificationId = _uuid.v4();
          final notification = {
            'id': notificationId,
            'userId': postAuthorId,
            'type': 'post_comment',
            'title': 'New comment on your post',
            'body': '${comment.userName} commented: ${comment.content}',
            'data': {
              'commentId': comment.id,
              'postId': comment.postId,
              'commentedBy': comment.userId,
              'commentedByName': comment.userName,
            },
            'isRead': false,
            'createdAt': Timestamp.now(),
          };
          
          await _firestore.collection('notifications').doc(notificationId).set(notification);
        }
      }
    } catch (e) {
      // Ignore notification errors
    }
  }

  /// Convert reactions map to Firestore format
  Map<String, String> _reactionsToFirestore(Map<String, ReactionType> reactions) {
    return reactions.map((key, value) => MapEntry(key, value.name));
  }
}

