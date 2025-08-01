// lib/providers/riverpod/firebase_social_provider.dart

import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/database/firebase_social_posts_service.dart';
import '../../services/database/firebase_comments_service.dart';
import '../../models/social/social_post.dart';
import '../../models/posts/post_comment.dart';
import '../../models/user/user_mention.dart';
import 'auth_provider.dart';

part 'firebase_social_provider.g.dart';

// FIREBASE SERVICES PROVIDERS

@riverpod
FirebaseSocialPostsService firebaseSocialPostsService(Ref ref) {
  return FirebaseSocialPostsService();
}

@riverpod
FirebaseCommentsService firebaseCommentsService(Ref ref) {
  return FirebaseCommentsService();
}

// SOCIAL POSTS PROVIDERS

@riverpod
Stream<List<SocialPost>> socialPostsFeed(
  Ref ref, {
  int limit = 20,
  PostVisibility? visibility,
  List<PostPillar>? pillars,
  String? userId,
}) {
  final service = ref.watch(firebaseSocialPostsServiceProvider);
  return service.getPostsFeed(
    limit: limit,
    visibility: visibility,
    pillars: pillars,
    userId: userId,
  );
}

@riverpod
Stream<List<SocialPost>> userPosts(Ref ref, String userId, {int limit = 20}) {
  final service = ref.watch(firebaseSocialPostsServiceProvider);
  return service.getUserPosts(userId, limit: limit);
}

@riverpod
Stream<List<SocialPost>> savedPosts(Ref ref, {int limit = 20}) {
  final service = ref.watch(firebaseSocialPostsServiceProvider);
  return service.getSavedPosts(limit: limit);
}

@riverpod
Future<SocialPost?> socialPost(Ref ref, String postId) async {
  final service = ref.watch(firebaseSocialPostsServiceProvider);
  return service.getPostById(postId);
}

@riverpod
Future<List<SocialPost>> trendingPosts(Ref ref, {int limit = 20}) async {
  final service = ref.watch(firebaseSocialPostsServiceProvider);
  return service.getTrendingPosts(limit: limit);
}

@riverpod
Future<List<SocialPost>> searchPosts(
  Ref ref, {
  required String query,
  List<PostPillar>? pillars,
  PostVisibility? visibility,
  int limit = 20,
}) async {
  final service = ref.watch(firebaseSocialPostsServiceProvider);
  return service.searchPosts(
    query: query,
    pillars: pillars,
    visibility: visibility,
    limit: limit,
  );
}

// COMMENTS PROVIDERS

@riverpod
Stream<List<PostComment>> postComments(
  Ref ref,
  String postId, {
  int limit = 50,
}) {
  final service = ref.watch(firebaseCommentsServiceProvider);
  return service.getPostComments(postId, limit: limit);
}

@riverpod
Stream<List<CommentThread>> commentThreads(
  Ref ref,
  String postId, {
  int limit = 20,
}) {
  final service = ref.watch(firebaseCommentsServiceProvider);
  return service.getCommentThreads(postId, limit: limit);
}

@riverpod
Stream<List<PostComment>> commentReplies(
  Ref ref,
  String commentId, {
  int limit = 20,
}) {
  final service = ref.watch(firebaseCommentsServiceProvider);
  return service.getCommentReplies(commentId, limit: limit);
}

@riverpod
Future<PostComment?> postComment(Ref ref, String commentId) async {
  final service = ref.watch(firebaseCommentsServiceProvider);
  return service.getCommentById(commentId);
}

// STATE MANAGEMENT PROVIDERS

/// Social Post Actions State Notifier
@riverpod
class SocialPostActions extends _$SocialPostActions {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<SocialPost> createPost({
    required String content,
    required List<PostPillar> pillars,
    required PostVisibility visibility,
    required PostType type,
    List<File>? mediaFiles,
    List<File>? videoFiles,
    List<String>? tags,
    bool autoGenerated = false,
    String? templateId,
    Map<String, dynamic>? templateData,
  }) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(firebaseSocialPostsServiceProvider);
      final post = await service.createPost(
        content: content,
        pillars: pillars,
        visibility: visibility,
        type: type,
        mediaFiles: mediaFiles,
        videoFiles: videoFiles,
        tags: tags,
        autoGenerated: autoGenerated,
        templateId: templateId,
        templateData: templateData,
      );

      state = const AsyncValue.data(null);
      return post;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<SocialPost> updatePost({
    required String postId,
    String? content,
    List<PostPillar>? pillars,
    PostVisibility? visibility,
    List<File>? newMediaFiles,
    List<String>? removedMediaUrls,
    List<File>? newVideoFiles,
    List<String>? removedVideoUrls,
    List<String>? tags,
    String? editReason,
  }) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(firebaseSocialPostsServiceProvider);
      final post = await service.updatePost(
        postId: postId,
        content: content,
        pillars: pillars,
        visibility: visibility,
        newMediaFiles: newMediaFiles,
        removedMediaUrls: removedMediaUrls,
        newVideoFiles: newVideoFiles,
        removedVideoUrls: removedVideoUrls,
        tags: tags,
        editReason: editReason,
      );

      state = const AsyncValue.data(null);
      return post;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deletePost(String postId) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(firebaseSocialPostsServiceProvider);
      await service.deletePost(postId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> reactToPost(String postId, ReactionType reaction) async {
    try {
      final service = ref.read(firebaseSocialPostsServiceProvider);
      await service.reactToPost(postId, reaction);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> toggleSavePost(String postId) async {
    try {
      final service = ref.read(firebaseSocialPostsServiceProvider);
      await service.toggleSavePost(postId);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> reportPost({
    required String postId,
    required String reason,
    String? details,
  }) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(firebaseSocialPostsServiceProvider);
      await service.reportPost(
        postId: postId,
        reason: reason,
        details: details,
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<bool> isPostSaved(String postId) async {
    try {
      final service = ref.read(firebaseSocialPostsServiceProvider);
      return await service.isPostSaved(postId);
    } catch (error) {
      return false;
    }
  }
}

/// Comment Actions State Notifier
@riverpod
class CommentActions extends _$CommentActions {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<PostComment> createComment({
    required String postId,
    required String content,
    String? parentCommentId,
    File? mediaFile,
    List<MentionInfo>? mentions,
  }) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(firebaseCommentsServiceProvider);
      final comment = await service.createComment(
        postId: postId,
        content: content,
        parentCommentId: parentCommentId,
        mediaFile: mediaFile,
        mentions: mentions,
      );

      state = const AsyncValue.data(null);
      return comment;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<PostComment> updateComment({
    required String commentId,
    required String newContent,
    File? newMediaFile,
    bool removeMedia = false,
    List<MentionInfo>? mentions,
  }) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(firebaseCommentsServiceProvider);
      final comment = await service.updateComment(
        commentId: commentId,
        newContent: newContent,
        newMediaFile: newMediaFile,
        removeMedia: removeMedia,
        mentions: mentions,
      );

      state = const AsyncValue.data(null);
      return comment;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteComment(String commentId) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(firebaseCommentsServiceProvider);
      await service.deleteComment(commentId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> reactToComment(String commentId, ReactionType reaction) async {
    try {
      final service = ref.read(firebaseCommentsServiceProvider);
      await service.reactToComment(commentId, reaction);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> togglePinComment(String commentId, String postId) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(firebaseCommentsServiceProvider);
      await service.togglePinComment(commentId, postId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> reportComment({
    required String commentId,
    required String reason,
    String? details,
  }) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(firebaseCommentsServiceProvider);
      await service.reportComment(
        commentId: commentId,
        reason: reason,
        details: details,
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<List<PostComment>> loadMoreReplies(
    String commentId, {
    int limit = 10,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      final service = ref.read(firebaseCommentsServiceProvider);
      return await service.loadMoreReplies(
        commentId,
        limit: limit,
        lastDoc: lastDoc,
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<List<MentionInfo>> searchMentionUsers(String query) async {
    try {
      final service = ref.read(firebaseCommentsServiceProvider);
      return await service.searchMentionUsers(query);
    } catch (error) {
      return [];
    }
  }
}

// UTILITY PROVIDERS

/// Post save status provider
@riverpod
Future<bool> isPostSaved(Ref ref, String postId) async {
  final actions = ref.read(socialPostActionsProvider.notifier);
  return await actions.isPostSaved(postId);
}

/// User's own posts provider
@riverpod
Stream<List<SocialPost>> currentUserPosts(Ref ref, {int limit = 20}) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return Stream.value([]);
  }

  final service = ref.watch(firebaseSocialPostsServiceProvider);
  return service.getUserPosts(currentUser.uid, limit: limit);
}

/// Post by pillar filter
@riverpod
Stream<List<SocialPost>> postsByPillar(
  Ref ref,
  PostPillar pillar, {
  int limit = 20,
}) {
  final service = ref.watch(firebaseSocialPostsServiceProvider);
  return service.getPostsFeed(limit: limit, pillars: [pillar]);
}

/// Public posts only
@riverpod
Stream<List<SocialPost>> publicPosts(Ref ref, {int limit = 20}) {
  final service = ref.watch(firebaseSocialPostsServiceProvider);
  return service.getPostsFeed(limit: limit, visibility: PostVisibility.public);
}

/// Convenience provider for comment count
@riverpod
Future<int> postCommentCount(Ref ref, String postId) async {
  final post = await ref.watch(socialPostProvider(postId).future);
  return post?.commentCount ?? 0;
}

/// Convenience provider for reaction count
@riverpod
Future<int> postReactionCount(Ref ref, String postId) async {
  final post = await ref.watch(socialPostProvider(postId).future);
  return post?.totalReactions ?? 0;
}

/// User reaction on post provider
@riverpod
Future<ReactionType?> userPostReaction(Ref ref, String postId) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return null;

  final post = await ref.watch(socialPostProvider(postId).future);
  return post?.getUserReaction(currentUser.uid);
}

/// User reaction on comment provider
@riverpod
Future<ReactionType?> userCommentReaction(Ref ref, String commentId) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return null;

  final comment = await ref.watch(postCommentProvider(commentId).future);
  return comment?.getUserReaction(currentUser.uid);
}
