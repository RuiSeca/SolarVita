import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../../models/social/story_highlight.dart';
import '../../models/user/privacy_settings.dart';

class StoryService {
  static final StoryService _instance = StoryService._internal();
  factory StoryService() => _instance;
  StoryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Collections
  static const String storyHighlightsCollection = 'story_highlights';
  static const String storyContentCollection = 'story_content';
  static const String storyViewsCollection = 'story_views';
  static const String privacySettingsCollection = 'privacy_settings';

  /// Privacy Methods

  // Get user's privacy settings
  Future<PrivacySettings?> getUserPrivacySettings(String userId) async {
    try {
      final doc = await _firestore
          .collection(privacySettingsCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return PrivacySettings.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting privacy settings: $e');
      return null;
    }
  }

  // Check if current user can view another user's story highlights
  Future<bool> canViewUserStoryHighlights(String targetUserId) async {
    final currentUser = currentUserId;
    if (currentUser == null) return false;
    
    // Own stories are always visible
    if (currentUser == targetUserId) return true;

    // Check target user's privacy settings
    final privacySettings = await getUserPrivacySettings(targetUserId);
    if (privacySettings == null) return true; // Default to visible if no settings

    return privacySettings.showStoryHighlights;
  }

  // Check if current user can view individual stories
  Future<bool> canViewUserStories(String targetUserId) async {
    final currentUser = currentUserId;
    if (currentUser == null) return false;
    
    // Own stories are always visible
    if (currentUser == targetUserId) return true;

    // Check target user's privacy settings
    final privacySettings = await getUserPrivacySettings(targetUserId);
    if (privacySettings == null) return true; // Default to visible if no settings

    return privacySettings.allowStoryViews;
  }

  /// Story Highlights CRUD Operations

  // Create a new story highlight
  Future<String> createStoryHighlight({
    required String title,
    required StoryHighlightCategory category,
    required String coverImageUrl,
    String? customTitle,
    String? iconName,
    Map<String, dynamic>? metadata,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    try {
      final highlight = StoryHighlight(
        id: '', // Will be set by Firestore
        userId: userId,
        title: title,
        customTitle: customTitle,
        category: category,
        coverImageUrl: coverImageUrl,
        storyContentIds: [],
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        isVisible: true,
        metadata: metadata ?? {},
        viewCount: 0,
        iconName: iconName,
      );

      final docRef = await _firestore
          .collection(storyHighlightsCollection)
          .add(highlight.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create story highlight: $e');
    }
  }

  // Get user's story highlights
  Stream<List<StoryHighlight>> getUserStoryHighlights(String userId) {
    debugPrint('Getting story highlights for user: $userId');
    
    // First, try the simple query without orderBy to avoid index issues
    return _firestore
        .collection(storyHighlightsCollection)
        .where('userId', isEqualTo: userId)
        .where('isVisible', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          debugPrint('Received ${snapshot.docs.length} story highlights from Firestore');
          final highlights = snapshot.docs
              .map((doc) {
                try {
                  return StoryHighlight.fromFirestore(doc);
                } catch (e) {
                  debugPrint('Error parsing story highlight from doc ${doc.id}: $e');
                  return null;
                }
              })
              .where((highlight) => highlight != null)
              .cast<StoryHighlight>()
              .toList();
          
          // Sort in memory by lastUpdated
          highlights.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
          debugPrint('Returning ${highlights.length} valid story highlights');
          return highlights;
        })
        .handleError((error) {
          debugPrint('Firestore error in getUserStoryHighlights: $error');
          // Let the error bubble up so we can see it in the UI
        });
  }

  // Get specific story highlight
  Future<StoryHighlight?> getStoryHighlight(String highlightId) async {
    try {
      final doc = await _firestore
          .collection(storyHighlightsCollection)
          .doc(highlightId)
          .get();

      if (doc.exists) {
        return StoryHighlight.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting story highlight: $e');
      return null;
    }
  }

  // Update story highlight
  Future<void> updateStoryHighlight(String highlightId, StoryHighlight highlight) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection(storyHighlightsCollection)
          .doc(highlightId)
          .update(highlight.copyWith(lastUpdated: DateTime.now()).toFirestore());
    } catch (e) {
      throw Exception('Failed to update story highlight: $e');
    }
  }

  // Delete story highlight
  Future<void> deleteStoryHighlight(String highlightId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    try {
      // Get highlight to check ownership
      final highlight = await getStoryHighlight(highlightId);
      if (highlight == null || highlight.userId != userId) {
        throw Exception('Unauthorized to delete this highlight');
      }

      // Delete associated story content
      for (final contentId in highlight.storyContentIds) {
        await deleteStoryContent(contentId);
      }

      // Delete the highlight
      await _firestore
          .collection(storyHighlightsCollection)
          .doc(highlightId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete story highlight: $e');
    }
  }

  /// Story Content CRUD Operations

  // Upload media file to Firebase Storage
  Future<String> uploadStoryMedia(File file, String fileName) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    try {
      final ref = _storage
          .ref()
          .child('story_content')
          .child(userId)
          .child(fileName);

      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload story media: $e');
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
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    try {
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 24)); // Stories expire after 24 hours

      final storyContent = StoryContent(
        id: '', // Will be set by Firestore
        userId: userId,
        mediaUrl: mediaUrl,
        thumbnailUrl: thumbnailUrl,
        text: text,
        contentType: contentType,
        createdAt: now,
        expiresAt: expiresAt,
        metadata: metadata ?? {},
        isActive: true,
      );

      final docRef = await _firestore
          .collection(storyContentCollection)
          .add(storyContent.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create story content: $e');
    }
  }

  // Get story content for a highlight
  Stream<List<StoryContent>> getStoryContent(List<String> contentIds) {
    debugPrint('getStoryContent called with IDs: $contentIds');
    
    if (contentIds.isEmpty) {
      debugPrint('No content IDs provided, returning empty stream');
      return Stream.value([]);
    }

    return _firestore
        .collection(storyContentCollection)
        .where(FieldPath.documentId, whereIn: contentIds)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          debugPrint('Firestore returned ${snapshot.docs.length} story content documents');
          
          final validContent = <StoryContent>[];
          for (final doc in snapshot.docs) {
            try {
              final content = StoryContent.fromFirestore(doc);
              debugPrint('Story content ${doc.id}: active=${content.isActive}, expired=${content.isExpired}, permanent=${content.isPermanent}');
              
              // Show story if it's active AND (permanent OR not expired)
              if (content.isActive && (content.isPermanent || !content.isExpired)) {
                validContent.add(content);
                debugPrint('Added valid story content: ${doc.id}');
              } else {
                debugPrint('Skipped story content ${doc.id}: active=${content.isActive}, expired=${content.isExpired}, permanent=${content.isPermanent}');
                
                // Auto-deactivate expired non-permanent stories
                if (content.isActive && !content.isPermanent && content.isExpired) {
                  _deactivateExpiredStory(doc.id);
                }
              }
            } catch (e) {
              debugPrint('Error parsing story content ${doc.id}: $e');
            }
          }
          
          debugPrint('Returning ${validContent.length} valid story content items');
          return validContent;
        });
  }

  // Helper method to deactivate expired stories
  Future<void> _deactivateExpiredStory(String storyId) async {
    try {
      await _firestore
          .collection(storyContentCollection)
          .doc(storyId)
          .update({'isActive': false});
      debugPrint('Deactivated expired story: $storyId');
    } catch (e) {
      debugPrint('Failed to deactivate expired story $storyId: $e');
    }
  }

  // Get active stories for a user (not expired, not in highlights)
  Stream<List<StoryContent>> getActiveUserStories(String userId) {
    final now = Timestamp.now();
    return _firestore
        .collection(storyContentCollection)
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .where('expiresAt', isGreaterThan: now)
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => StoryContent.fromFirestore(doc))
              .toList();
        });
  }

  // Add story content to highlight
  Future<void> addStoryToHighlight(String highlightId, String storyContentId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    try {
      debugPrint('Adding story content $storyContentId to highlight $highlightId');
      
      final highlight = await getStoryHighlight(highlightId);
      if (highlight == null || highlight.userId != userId) {
        throw Exception('Unauthorized to modify this highlight');
      }

      debugPrint('Current story content IDs in highlight: ${highlight.storyContentIds}');
      
      final updatedStoryIds = List<String>.from(highlight.storyContentIds);
      if (!updatedStoryIds.contains(storyContentId)) {
        updatedStoryIds.add(storyContentId);
        debugPrint('Updated story content IDs: $updatedStoryIds');

        await updateStoryHighlight(
          highlightId,
          highlight.copyWith(storyContentIds: updatedStoryIds),
        );
        
        debugPrint('Successfully added story content to highlight');
      } else {
        debugPrint('Story content already exists in highlight');
      }
    } catch (e) {
      debugPrint('Error adding story to highlight: $e');
      throw Exception('Failed to add story to highlight: $e');
    }
  }

  // Remove story content from highlight
  Future<void> removeStoryFromHighlight(String highlightId, String storyContentId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    try {
      final highlight = await getStoryHighlight(highlightId);
      if (highlight == null || highlight.userId != userId) {
        throw Exception('Unauthorized to modify this highlight');
      }

      final updatedStoryIds = List<String>.from(highlight.storyContentIds);
      updatedStoryIds.remove(storyContentId);

      await updateStoryHighlight(
        highlightId,
        highlight.copyWith(storyContentIds: updatedStoryIds),
      );
    } catch (e) {
      throw Exception('Failed to remove story from highlight: $e');
    }
  }

  // Delete story content
  Future<void> deleteStoryContent(String contentId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    try {
      // Get content to check ownership and get media URLs
      final doc = await _firestore
          .collection(storyContentCollection)
          .doc(contentId)
          .get();

      if (!doc.exists) return;

      final content = StoryContent.fromFirestore(doc);
      if (content.userId != userId) {
        throw Exception('Unauthorized to delete this content');
      }

      // Delete media files from storage
      if (content.mediaUrl != null) {
        try {
          await _storage.refFromURL(content.mediaUrl!).delete();
        } catch (e) {
          debugPrint('Failed to delete media file: $e');
        }
      }

      if (content.thumbnailUrl != null) {
        try {
          await _storage.refFromURL(content.thumbnailUrl!).delete();
        } catch (e) {
          debugPrint('Failed to delete thumbnail file: $e');
        }
      }

      // Delete the document
      await _firestore
          .collection(storyContentCollection)
          .doc(contentId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete story content: $e');
    }
  }

  /// Story Views and Analytics

  // Record a story view
  Future<void> recordStoryView({
    required String storyContentId,
    required String storyOwnerId,
    required Duration viewDuration,
    Map<String, dynamic>? metadata,
  }) async {
    final userId = currentUserId;
    if (userId == null) return; // Don't record views for unauthenticated users

    // Don't record views for own stories
    if (userId == storyOwnerId) return;

    try {
      final storyView = StoryView(
        id: '', // Will be set by Firestore
        storyContentId: storyContentId,
        viewerId: userId,
        storyOwnerId: storyOwnerId,
        viewedAt: DateTime.now(),
        viewDuration: viewDuration,
        metadata: metadata ?? {},
      );

      await _firestore
          .collection(storyViewsCollection)
          .add(storyView.toFirestore());

      // Update view count on the story content
      await _firestore
          .collection(storyContentCollection)
          .doc(storyContentId)
          .update({
        'metadata.viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Failed to record story view: $e');
      // Don't throw error for analytics - it's not critical
    }
  }

  // Get story viewers for a specific story
  Future<List<StoryView>> getStoryViewers(String storyContentId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    try {
      // Check if user allows showing story viewers
      final privacySettings = await getUserPrivacySettings(userId);
      if (privacySettings != null && !privacySettings.showStoryViewers) {
        return []; // Return empty list if privacy setting disabled
      }

      final snapshot = await _firestore
          .collection(storyViewsCollection)
          .where('storyContentId', isEqualTo: storyContentId)
          .where('storyOwnerId', isEqualTo: userId) // Only show views for own stories
          .orderBy('viewedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => StoryView.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get story viewers: $e');
    }
  }

  /// Utility Methods

  // Clean up expired stories (should be called periodically)
  Future<void> cleanupExpiredStories() async {
    try {
      final now = Timestamp.now();
      
      // Only deactivate stories that are NOT permanent and have expired
      final expiredSnapshot = await _firestore
          .collection(storyContentCollection)
          .where('expiresAt', isLessThan: now)
          .where('isActive', isEqualTo: true)
          .where('isPermanent', isEqualTo: false) // Only non-permanent stories
          .get();

      final batch = _firestore.batch();
      for (final doc in expiredSnapshot.docs) {
        batch.update(doc.reference, {'isActive': false});
        debugPrint('Deactivated expired non-permanent story: ${doc.id}');
      }

      if (expiredSnapshot.docs.isNotEmpty) {
        await batch.commit();
        debugPrint('Cleaned up ${expiredSnapshot.docs.length} expired stories');
      }
    } catch (e) {
      debugPrint('Failed to cleanup expired stories: $e');
    }
  }

  // Schedule automatic cleanup of expired stories
  void scheduleExpiredStoriesCleanup() {
    // Run cleanup every hour
    Timer.periodic(const Duration(hours: 1), (timer) {
      cleanupExpiredStories();
    });
  }

  // Get available highlight categories (excluding user's existing ones)
  Future<List<StoryHighlightCategory>> getAvailableCategories() async {
    final userId = currentUserId;
    if (userId == null) return [];

    try {
      final existingHighlights = await _firestore
          .collection(storyHighlightsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final existingCategories = existingHighlights.docs
          .map((doc) => StoryHighlightCategory.values[doc.data()['category'] ?? 0])
          .where((category) => category != StoryHighlightCategory.custom)
          .toSet();

      final allCategories = StoryHighlightCategory.values
          .where((category) => category != StoryHighlightCategory.custom)
          .toList();

      return allCategories
          .where((category) => !existingCategories.contains(category))
          .toList();
    } catch (e) {
      debugPrint('Failed to get available categories: $e');
      return StoryHighlightCategory.values
          .where((category) => category != StoryHighlightCategory.custom)
          .toList();
    }
  }

  // Check if user can create more custom highlights (limit to 3)
  Future<bool> canCreateCustomHighlight() async {
    final userId = currentUserId;
    if (userId == null) return false;

    try {
      final customHighlights = await _firestore
          .collection(storyHighlightsCollection)
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: StoryHighlightCategory.custom.index)
          .get();

      return customHighlights.docs.length < 3; // Limit to 3 custom highlights
    } catch (e) {
      debugPrint('Failed to check custom highlight limit: $e');
      return false;
    }
  }

  // Search story highlights by category
  Stream<List<StoryHighlight>> getHighlightsByCategory(
    String userId,
    StoryHighlightCategory category,
  ) {
    return _firestore
        .collection(storyHighlightsCollection)
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category.index)
        .where('isVisible', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => StoryHighlight.fromFirestore(doc))
              .toList();
        });
  }

  // Get hidden story highlights
  Stream<List<StoryHighlight>> getHiddenStoryHighlights(String userId) {
    try {
      return _firestore
          .collection(storyHighlightsCollection)
          .where('userId', isEqualTo: userId)
          .where('isVisible', isEqualTo: false)
          .orderBy('lastUpdated', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => StoryHighlight.fromFirestore(doc))
                .toList();
          })
          .handleError((error) {
            debugPrint('Error getting hidden story highlights: $error');
            throw error;
          });
    } catch (e) {
      debugPrint('Error in getHiddenStoryHighlights: $e');
      return Stream.error(e);
    }
  }

  // Get temporary stories (not permanent and not expired)
  Stream<List<StoryContent>> getTemporaryStories(String userId) {
    try {
      final now = Timestamp.now();
      
      return _firestore
          .collection(storyContentCollection)
          .where('userId', isEqualTo: userId)
          .where('isPermanent', isEqualTo: false)
          .where('isActive', isEqualTo: true)
          .where('expiresAt', isGreaterThan: now)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => StoryContent.fromFirestore(doc))
                .toList();
          })
          .handleError((error) {
            debugPrint('Error getting temporary stories: $error');
            throw error;
          });
    } catch (e) {
      debugPrint('Error in getTemporaryStories: $e');
      return Stream.error(e);
    }
  }

  // Update story highlight visibility
  Future<void> updateStoryHighlightVisibility(String highlightId, bool isVisible) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    try {
      final highlightRef = _firestore
          .collection(storyHighlightsCollection)
          .doc(highlightId);

      final doc = await highlightRef.get();
      if (!doc.exists) {
        throw Exception('Highlight not found');
      }

      final highlight = StoryHighlight.fromFirestore(doc);
      if (highlight.userId != userId) {
        throw Exception('Unauthorized to modify this highlight');
      }

      await highlightRef.update({
        'isVisible': isVisible,
        'lastUpdated': Timestamp.now(),
      });

      debugPrint('Updated highlight visibility: $highlightId -> $isVisible');
    } catch (e) {
      throw Exception('Failed to update highlight visibility: $e');
    }
  }

  // Make story permanent
  Future<void> makeStoryPermanent(String storyId, String visibility) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    try {
      final storyRef = _firestore
          .collection(storyContentCollection)
          .doc(storyId);

      final doc = await storyRef.get();
      if (!doc.exists) {
        throw Exception('Story not found');
      }

      final story = StoryContent.fromFirestore(doc);
      if (story.userId != userId) {
        throw Exception('Unauthorized to modify this story');
      }

      // Update the story to be permanent
      await storyRef.update({
        'isPermanent': true,
        'visibility': visibility,
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 365 * 10))), // 10 years from now
      });

      debugPrint('Made story permanent: $storyId with visibility: $visibility');
    } catch (e) {
      throw Exception('Failed to make story permanent: $e');
    }
  }
}