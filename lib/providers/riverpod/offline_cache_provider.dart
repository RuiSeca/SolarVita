// lib/providers/riverpod/offline_cache_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../../services/offline_cache_service.dart';
import '../../models/social_post.dart';
import '../../models/chat_message.dart';
import '../../models/chat_conversation.dart';
import '../../models/user_profile.dart';

part 'offline_cache_provider.g.dart';

// CACHE SERVICE PROVIDER

@riverpod
OfflineCacheService offlineCacheService(Ref ref) {
  return OfflineCacheService();
}

// CONNECTIVITY PROVIDERS

@riverpod
class ConnectivityStatus extends _$ConnectivityStatus {
  @override
  bool build() {
    final cacheService = ref.watch(offlineCacheServiceProvider);
    return cacheService.isOnline;
  }

  void updateStatus(bool isOnline) {
    state = isOnline;
  }
}

// CACHE DATA PROVIDERS

@riverpod
Future<List<SocialPost>?> cachedSocialPosts(Ref ref, {String? feedType}) async {
  final cacheService = ref.watch(offlineCacheServiceProvider);
  return await cacheService.getCachedSocialPosts(feedType: feedType);
}

@riverpod
Future<List<ChatConversation>?> cachedChatConversations(Ref ref) async {
  final cacheService = ref.watch(offlineCacheServiceProvider);
  return await cacheService.getCachedChatConversations();
}

@riverpod
Future<List<ChatMessage>?> cachedChatMessages(Ref ref, String conversationId) async {
  final cacheService = ref.watch(offlineCacheServiceProvider);
  return await cacheService.getCachedChatMessages(conversationId);
}

@riverpod
Future<UserProfile?> cachedUserProfile(Ref ref, String userId) async {
  final cacheService = ref.watch(offlineCacheServiceProvider);
  return await cacheService.getCachedUserProfile(userId);
}

@riverpod
Future<String?> cachedMediaFile(Ref ref, String url) async {
  final cacheService = ref.watch(offlineCacheServiceProvider);
  return await cacheService.getCachedMediaFile(url);
}

// CACHE MANAGEMENT PROVIDERS

@riverpod
class CacheManager extends _$CacheManager {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<void> cacheSocialPosts(List<SocialPost> posts, {String? feedType}) async {
    try {
      final cacheService = ref.read(offlineCacheServiceProvider);
      await cacheService.cacheSocialPosts(posts, feedType: feedType);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> cacheChatConversations(List<ChatConversation> conversations) async {
    try {
      final cacheService = ref.read(offlineCacheServiceProvider);
      await cacheService.cacheChatConversations(conversations);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> cacheChatMessages(String conversationId, List<ChatMessage> messages) async {
    try {
      final cacheService = ref.read(offlineCacheServiceProvider);
      await cacheService.cacheChatMessages(conversationId, messages);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> cacheUserProfile(UserProfile profile) async {
    try {
      final cacheService = ref.read(offlineCacheServiceProvider);
      await cacheService.cacheUserProfile(profile);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> cacheMediaFile(String url) async {
    try {
      final cacheService = ref.read(offlineCacheServiceProvider);
      await cacheService.cacheMediaFile(url);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> clearAllCache() async {
    state = const AsyncValue.loading();
    
    try {
      final cacheService = ref.read(offlineCacheServiceProvider);
      await cacheService.clearAllCache();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// OFFLINE SYNC PROVIDERS

@riverpod
class OfflineSyncManager extends _$OfflineSyncManager {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<void> queuePostCreation(Map<String, dynamic> postData) async {
    try {
      final cacheService = ref.read(offlineCacheServiceProvider);
      await cacheService.queueForSync(
        operation: 'create_post',
        data: postData,
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> queueMessageSend(Map<String, dynamic> messageData) async {
    try {
      final cacheService = ref.read(offlineCacheServiceProvider);
      await cacheService.queueForSync(
        operation: 'send_message',
        data: messageData,
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> queueProfileUpdate(Map<String, dynamic> profileData) async {
    try {
      final cacheService = ref.read(offlineCacheServiceProvider);
      await cacheService.queueForSync(
        operation: 'update_profile',
        data: profileData,
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// CACHE STATISTICS PROVIDER

@riverpod
Future<Map<String, dynamic>> cacheStats(Ref ref) async {
  final cacheService = ref.watch(offlineCacheServiceProvider);
  return await cacheService.getCacheStats();
}

// HYBRID DATA PROVIDERS (Online + Offline)

@riverpod
class HybridDataManager extends _$HybridDataManager {
  final _logger = Logger('HybridDataManager');

  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  /// Get social posts with offline fallback
  Future<List<SocialPost>> getSocialPostsWithFallback({
    String? feedType,
    required Future<List<SocialPost>> Function() onlineLoader,
  }) async {
    final isOnline = ref.read(connectivityStatusProvider);
    
    if (isOnline) {
      try {
        // Try to load from online source
        final posts = await onlineLoader();
        
        // Cache the results
        await ref.read(cacheManagerProvider.notifier).cacheSocialPosts(posts, feedType: feedType);
        
        return posts;
      } catch (e) {
        _logger.warning('Online load failed, falling back to cache: $e');
      }
    }
    
    // Fallback to cached data
    final cachedPosts = await ref.read(cachedSocialPostsProvider(feedType: feedType).future);
    return cachedPosts ?? [];
  }

  /// Get chat conversations with offline fallback
  Future<List<ChatConversation>> getChatConversationsWithFallback({
    required Future<List<ChatConversation>> Function() onlineLoader,
  }) async {
    final isOnline = ref.read(connectivityStatusProvider);
    
    if (isOnline) {
      try {
        final conversations = await onlineLoader();
        await ref.read(cacheManagerProvider.notifier).cacheChatConversations(conversations);
        return conversations;
      } catch (e) {
        _logger.warning('Online load failed, falling back to cache: $e');
      }
    }
    
    final cachedConversations = await ref.read(cachedChatConversationsProvider.future);
    return cachedConversations ?? [];
  }

  /// Get chat messages with offline fallback
  Future<List<ChatMessage>> getChatMessagesWithFallback({
    required String conversationId,
    required Future<List<ChatMessage>> Function() onlineLoader,
  }) async {
    final isOnline = ref.read(connectivityStatusProvider);
    
    if (isOnline) {
      try {
        final messages = await onlineLoader();
        await ref.read(cacheManagerProvider.notifier).cacheChatMessages(conversationId, messages);
        return messages;
      } catch (e) {
        _logger.warning('Online load failed, falling back to cache: $e');
      }
    }
    
    final cachedMessages = await ref.read(cachedChatMessagesProvider(conversationId).future);
    return cachedMessages ?? [];
  }

  /// Get user profile with offline fallback
  Future<UserProfile?> getUserProfileWithFallback({
    required String userId,
    required Future<UserProfile?> Function() onlineLoader,
  }) async {
    final isOnline = ref.read(connectivityStatusProvider);
    
    if (isOnline) {
      try {
        final profile = await onlineLoader();
        if (profile != null) {
          await ref.read(cacheManagerProvider.notifier).cacheUserProfile(profile);
        }
        return profile;
      } catch (e) {
        _logger.warning('Online load failed, falling back to cache: $e');
      }
    }
    
    return await ref.read(cachedUserProfileProvider(userId).future);
  }
}

// OFFLINE INDICATOR PROVIDERS

@riverpod
bool shouldShowOfflineIndicator(Ref ref) {
  return !ref.watch(connectivityStatusProvider);
}

@riverpod
String offlineStatusMessage(Ref ref) {
  final isOnline = ref.watch(connectivityStatusProvider);
  
  if (isOnline) {
    return 'Online';
  } else {
    return 'Offline - Some features may be limited';
  }
}

@riverpod
Future<int> pendingSyncItemsCount(Ref ref) async {
  final stats = await ref.watch(cacheStatsProvider.future);
  return stats['pendingSyncItems'] as int? ?? 0;
}

// CACHE INITIALIZATION PROVIDER

@riverpod
class CacheInitializer extends _$CacheInitializer {
  @override
  AsyncValue<bool> build() {
    return const AsyncValue.data(false);
  }

  Future<void> initialize() async {
    state = const AsyncValue.loading();
    
    try {
      final cacheService = ref.read(offlineCacheServiceProvider);
      await cacheService.initialize();
      state = const AsyncValue.data(true);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// PRELOADING PROVIDERS

@riverpod
class DataPreloader extends _$DataPreloader {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  /// Preload essential data for offline access
  Future<void> preloadEssentialData() async {
    state = const AsyncValue.loading();
    
    try {
      // This would be called when user has good connectivity
      // to prepare for potential offline usage
      
      // Preload recent social posts
      // Preload recent conversations
      // Preload user profile
      // Preload media files for recent content
      
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Preload media files for offline viewing
  Future<void> preloadMediaFiles(List<String> urls) async {
    try {
      final cacheService = ref.read(offlineCacheServiceProvider);
      
      for (final url in urls) {
        await cacheService.cacheMediaFile(url);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}