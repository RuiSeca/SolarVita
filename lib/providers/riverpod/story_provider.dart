import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/social/story_highlight.dart';
import '../../services/database/story_service.dart';

// Story service provider
final storyServiceProvider = Provider<StoryService>((ref) {
  return StoryService();
});

// User's story highlights stream
final userStoryHighlightsProvider = StreamProvider.family<List<StoryHighlight>, String>((ref, userId) {
  final storyService = ref.watch(storyServiceProvider);
  return storyService.getUserStoryHighlights(userId);
});

// Story content for a highlight
final storyContentProvider = StreamProvider.family<List<StoryContent>, List<String>>((ref, contentIds) {
  final storyService = ref.watch(storyServiceProvider);
  return storyService.getStoryContent(contentIds);
});

// Active user stories (not in highlights, not expired)
final activeUserStoriesProvider = StreamProvider.family<List<StoryContent>, String>((ref, userId) {
  final storyService = ref.watch(storyServiceProvider);
  return storyService.getActiveUserStories(userId);
});

// Available highlight categories for user
final availableCategoriesProvider = FutureProvider<List<StoryHighlightCategory>>((ref) {
  final storyService = ref.watch(storyServiceProvider);
  return storyService.getAvailableCategories();
});

// Check if user can create custom highlight
final canCreateCustomHighlightProvider = FutureProvider<bool>((ref) {
  final storyService = ref.watch(storyServiceProvider);
  return storyService.canCreateCustomHighlight();
});

// Story highlights by category
final highlightsByCategoryProvider = StreamProvider.family<List<StoryHighlight>, HighlightsByCategoryQuery>((ref, query) {
  final storyService = ref.watch(storyServiceProvider);
  return storyService.getHighlightsByCategory(query.userId, query.category);
});

// Privacy-aware story highlights stream
final privacyAwareStoryHighlightsProvider = StreamProvider.family<List<StoryHighlight>, String>((ref, userId) {
  final storyService = ref.watch(storyServiceProvider);
  return storyService.getUserStoryHighlights(userId);
});

// Check if user can view story highlights
final canViewStoryHighlightsProvider = FutureProvider.family<bool, String>((ref, userId) {
  final storyService = ref.watch(storyServiceProvider);
  return storyService.canViewUserStoryHighlights(userId);
});

// Check if user can view stories
final canViewStoriesProvider = FutureProvider.family<bool, String>((ref, userId) {
  final storyService = ref.watch(storyServiceProvider);
  return storyService.canViewUserStories(userId);
});

// Story actions provider
final storyActionsProvider = Provider<StoryActions>((ref) {
  final storyService = ref.watch(storyServiceProvider);
  return StoryActions(storyService, ref);
});

// Query class for highlights by category
class HighlightsByCategoryQuery {
  final String userId;
  final StoryHighlightCategory category;

  const HighlightsByCategoryQuery({
    required this.userId,
    required this.category,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HighlightsByCategoryQuery &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          category == other.category;

  @override
  int get hashCode => userId.hashCode ^ category.hashCode;
}

// Actions class for story operations
class StoryActions {
  final StoryService _storyService;
  final Ref _ref;

  StoryActions(this._storyService, this._ref);

  // Create new story highlight
  Future<String> createStoryHighlight({
    required String title,
    required StoryHighlightCategory category,
    required String coverImageUrl,
    String? customTitle,
    String? iconName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final highlightId = await _storyService.createStoryHighlight(
        title: title,
        category: category,
        coverImageUrl: coverImageUrl,
        customTitle: customTitle,
        iconName: iconName,
        metadata: metadata,
      );

      // Invalidate relevant providers
      _ref.invalidate(availableCategoriesProvider);
      if (category == StoryHighlightCategory.custom) {
        _ref.invalidate(canCreateCustomHighlightProvider);
      }

      return highlightId;
    } catch (e) {
      throw Exception('Failed to create story highlight: $e');
    }
  }

  // Update story highlight
  Future<void> updateStoryHighlight(String highlightId, StoryHighlight highlight) async {
    try {
      await _storyService.updateStoryHighlight(highlightId, highlight);
    } catch (e) {
      throw Exception('Failed to update story highlight: $e');
    }
  }

  // Delete story highlight
  Future<void> deleteStoryHighlight(String highlightId) async {
    try {
      await _storyService.deleteStoryHighlight(highlightId);

      // Invalidate relevant providers
      _ref.invalidate(availableCategoriesProvider);
      _ref.invalidate(canCreateCustomHighlightProvider);
    } catch (e) {
      throw Exception('Failed to delete story highlight: $e');
    }
  }

  // Create story content
  Future<String> createStoryContent({
    required StoryContentType contentType,
    String? mediaUrl,
    String? thumbnailUrl,
    String? text,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final contentId = await _storyService.createStoryContent(
        contentType: contentType,
        mediaUrl: mediaUrl,
        thumbnailUrl: thumbnailUrl,
        text: text,
        metadata: metadata,
      );

      return contentId;
    } catch (e) {
      throw Exception('Failed to create story content: $e');
    }
  }

  // Add story to highlight
  Future<void> addStoryToHighlight(String highlightId, String storyContentId) async {
    try {
      await _storyService.addStoryToHighlight(highlightId, storyContentId);
    } catch (e) {
      throw Exception('Failed to add story to highlight: $e');
    }
  }

  // Remove story from highlight
  Future<void> removeStoryFromHighlight(String highlightId, String storyContentId) async {
    try {
      await _storyService.removeStoryFromHighlight(highlightId, storyContentId);
    } catch (e) {
      throw Exception('Failed to remove story from highlight: $e');
    }
  }

  // Delete story content
  Future<void> deleteStoryContent(String contentId) async {
    try {
      await _storyService.deleteStoryContent(contentId);
    } catch (e) {
      throw Exception('Failed to delete story content: $e');
    }
  }

  // Upload story media
  Future<String> uploadStoryMedia(dynamic file, String fileName) async {
    try {
      return await _storyService.uploadStoryMedia(file, fileName);
    } catch (e) {
      throw Exception('Failed to upload story media: $e');
    }
  }

  // Record story view
  Future<void> recordStoryView({
    required String storyContentId,
    required String storyOwnerId,
    required Duration viewDuration,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _storyService.recordStoryView(
        storyContentId: storyContentId,
        storyOwnerId: storyOwnerId,
        viewDuration: viewDuration,
        metadata: metadata,
      );
    } catch (e) {
      // Don't throw for analytics failures
      debugPrint('Failed to record story view: $e');
    }
  }

  // Get story viewers
  Future<List<StoryView>> getStoryViewers(String storyContentId) async {
    try {
      return await _storyService.getStoryViewers(storyContentId);
    } catch (e) {
      throw Exception('Failed to get story viewers: $e');
    }
  }

  // Cleanup expired stories
  Future<void> cleanupExpiredStories() async {
    try {
      await _storyService.cleanupExpiredStories();
    } catch (e) {
      debugPrint('Failed to cleanup expired stories: $e');
    }
  }
}