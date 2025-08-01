// lib/services/offline_cache_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import '../../models/social/social_post.dart';
import '../../models/chat/chat_message.dart';
import '../../models/chat/chat_conversation.dart';
import '../../models/user/user_profile.dart';
import '../../models/posts/post_comment.dart' as post_comment_model;

enum CacheType {
  socialPosts,
  comments,
  chatMessages,
  conversations,
  userProfiles,
  media,
}

class CachedItem<T> {
  final String key;
  final T data;
  final DateTime cachedAt;
  final DateTime? expiresAt;
  final Map<String, dynamic> metadata;

  CachedItem({
    required this.key,
    required this.data,
    required this.cachedAt,
    this.expiresAt,
    this.metadata = const {},
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'data': _serializeData(data),
      'cachedAt': cachedAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  static CachedItem<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) deserializer,
  ) {
    return CachedItem<T>(
      key: json['key'],
      data: deserializer(json['data']),
      cachedAt: DateTime.parse(json['cachedAt']),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  dynamic _serializeData(T data) {
    if (data is SocialPost) {
      return data.toMap();
    } else if (data is ChatMessage) {
      return data.toMap();
    } else if (data is ChatConversation) {
      return data.toMap();
    } else if (data is UserProfile) {
      return data.toMap();
    } else if (data is post_comment_model.PostComment) {
      return data.toMap();
    } else if (data is List<ChatMessage>) {
      return data.map((item) => item.toMap()).toList();
    } else if (data is List<ChatConversation>) {
      return data.map((item) => item.toMap()).toList();
    } else if (data is List<SocialPost>) {
      return data.map((item) => item.toMap()).toList();
    } else if (data is List<UserProfile>) {
      return data.map((item) => item.toMap()).toList();
    } else if (data is List<post_comment_model.PostComment>) {
      return data.map((item) => item.toMap()).toList();
    } else if (data is List) {
      return data.map((item) => item.toString()).toList();
    } else if (data is Map<String, dynamic>) {
      return data;
    } else {
      return data.toString();
    }
  }
}

class OfflineCacheService {
  static final OfflineCacheService _instance = OfflineCacheService._internal();
  factory OfflineCacheService() => _instance;
  OfflineCacheService._internal();

  final _logger = Logger('OfflineCacheService');

  // final Connectivity _connectivity = Connectivity(); // Temporarily disabled
  late SharedPreferences _prefs;
  late String _cacheDirectory;

  bool _initialized = false;
  bool _isOnline = true;
  final Map<String, dynamic> _memoryCache = {};

  // Cache settings
  static const int _maxMemoryCacheSize = 100; // items

  /// Initialize the cache service
  Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();
    _cacheDirectory = await _getCacheDirectory();

    // Check initial connectivity - temporarily assume online
    // final connectivityResult = await _connectivity.checkConnectivity();
    // _isOnline = connectivityResult != ConnectivityResult.none;
    _isOnline = true; // Temporarily assume online

    // Listen to connectivity changes
    // _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);

    // Clean up expired cache on initialization
    await _cleanExpiredCache();

    _initialized = true;
  }

  /// Get cache directory path
  Future<String> _getCacheDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${directory.path}/offline_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir.path;
  }

  /// Check if device is online
  bool get isOnline => _isOnline;

  /// Cache data with expiry
  Future<void> cacheData<T>({
    required CacheType type,
    required String key,
    required T data,
    Duration? expiry,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_initialized) await initialize();

    final cacheKey = '${type.name}_$key';
    final cachedItem = CachedItem<T>(
      key: cacheKey,
      data: data,
      cachedAt: DateTime.now(),
      expiresAt: expiry != null ? DateTime.now().add(expiry) : null,
      metadata: metadata ?? {},
    );

    // Store in memory cache
    _memoryCache[cacheKey] = cachedItem;
    _limitMemoryCache();

    // Store in disk cache
    await _saveToDisk(cacheKey, cachedItem);
  }

  /// Get cached data
  Future<T?> getCachedData<T>({
    required CacheType type,
    required String key,
    T Function(Map<String, dynamic>)? deserializer,
  }) async {
    if (!_initialized) await initialize();

    final cacheKey = '${type.name}_$key';

    // Check memory cache first
    if (_memoryCache.containsKey(cacheKey)) {
      final cachedItem = _memoryCache[cacheKey] as CachedItem<T>;
      if (!cachedItem.isExpired) {
        return cachedItem.data;
      } else {
        _memoryCache.remove(cacheKey);
      }
    }

    // Check disk cache
    final cachedItem = await _loadFromDisk<T>(cacheKey, deserializer);
    if (cachedItem != null && !cachedItem.isExpired) {
      // Move back to memory cache
      _memoryCache[cacheKey] = cachedItem;
      return cachedItem.data;
    }

    return null;
  }

  /// Cache list of items
  Future<void> cacheList<T>({
    required CacheType type,
    required String key,
    required List<T> items,
    Duration? expiry,
    Map<String, dynamic>? metadata,
  }) async {
    await cacheData<List<T>>(
      type: type,
      key: key,
      data: items,
      expiry: expiry,
      metadata: metadata,
    );
  }

  /// Get cached list
  Future<List<T>?> getCachedList<T>({
    required CacheType type,
    required String key,
    T Function(Map<String, dynamic>)? itemDeserializer,
  }) async {
    final cachedList = await getCachedData<List<dynamic>>(type: type, key: key);

    if (cachedList == null || itemDeserializer == null) return null;

    try {
      return cachedList
          .map((item) => itemDeserializer(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.warning('Error deserializing cached list: $e');
      return null;
    }
  }

  /// Cache social posts with automatic expiry
  Future<void> cacheSocialPosts(
    List<SocialPost> posts, {
    String? feedType,
  }) async {
    final key = feedType ?? 'main_feed';
    await cacheList<SocialPost>(
      type: CacheType.socialPosts,
      key: key,
      items: posts,
      expiry: const Duration(
        minutes: 30,
      ), // Posts expire quickly for fresh content
    );
  }

  /// Get cached social posts
  Future<List<SocialPost>?> getCachedSocialPosts({String? feedType}) async {
    final key = feedType ?? 'main_feed';
    return await getCachedList<SocialPost>(
      type: CacheType.socialPosts,
      key: key,
      itemDeserializer: (json) =>
          _deserializeFromCache<SocialPost>(json, 'SocialPost'),
    );
  }

  /// Cache chat conversations
  Future<void> cacheChatConversations(
    List<ChatConversation> conversations,
  ) async {
    await cacheList<ChatConversation>(
      type: CacheType.conversations,
      key: 'user_conversations',
      items: conversations,
      expiry: const Duration(hours: 1),
    );
  }

  /// Get cached chat conversations
  Future<List<ChatConversation>?> getCachedChatConversations() async {
    return await getCachedList<ChatConversation>(
      type: CacheType.conversations,
      key: 'user_conversations',
      itemDeserializer: (json) =>
          _deserializeFromCache<ChatConversation>(json, 'ChatConversation'),
    );
  }

  /// Cache chat messages for a conversation
  Future<void> cacheChatMessages(
    String conversationId,
    List<ChatMessage> messages,
  ) async {
    await cacheList<ChatMessage>(
      type: CacheType.chatMessages,
      key: conversationId,
      items: messages,
      expiry: const Duration(hours: 6),
    );
  }

  /// Get cached chat messages
  Future<List<ChatMessage>?> getCachedChatMessages(
    String conversationId,
  ) async {
    return await getCachedList<ChatMessage>(
      type: CacheType.chatMessages,
      key: conversationId,
      itemDeserializer: (json) =>
          _deserializeFromCache<ChatMessage>(json, 'ChatMessage'),
    );
  }

  /// Cache user profile
  Future<void> cacheUserProfile(UserProfile profile) async {
    await cacheData<UserProfile>(
      type: CacheType.userProfiles,
      key: profile.uid,
      data: profile,
      expiry: const Duration(hours: 2),
    );
  }

  /// Get cached user profile
  Future<UserProfile?> getCachedUserProfile(String userId) async {
    return await getCachedData<UserProfile>(
      type: CacheType.userProfiles,
      key: userId,
      deserializer: (json) =>
          _deserializeFromCache<UserProfile>(json, 'UserProfile'),
    );
  }

  /// Cache media file
  Future<String?> cacheMediaFile(String url, {Duration? expiry}) async {
    try {
      final uri = Uri.parse(url);
      final fileName = uri.pathSegments.last;
      final cacheKey = 'media_$fileName';

      // Check if already cached
      final cachedPath = await _getMediaCachePath(cacheKey);
      final file = File(cachedPath);
      if (await file.exists()) {
        return cachedPath;
      }

      // Download and cache the file
      final client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        await response.pipe(file.openWrite());

        // Store metadata
        await _prefs.setString(
          '${cacheKey}_cached_at',
          DateTime.now().toIso8601String(),
        );
        if (expiry != null) {
          await _prefs.setString(
            '${cacheKey}_expires_at',
            DateTime.now().add(expiry).toIso8601String(),
          );
        }

        return cachedPath;
      }
    } catch (e) {
      _logger.severe('Error caching media file: $e');
    }
    return null;
  }

  /// Get cached media file path
  Future<String?> getCachedMediaFile(String url) async {
    try {
      final uri = Uri.parse(url);
      final fileName = uri.pathSegments.last;
      final cacheKey = 'media_$fileName';

      final cachedPath = await _getMediaCachePath(cacheKey);
      final file = File(cachedPath);

      if (await file.exists()) {
        // Check if expired
        final expiresAtStr = _prefs.getString('${cacheKey}_expires_at');
        if (expiresAtStr != null) {
          final expiresAt = DateTime.parse(expiresAtStr);
          if (DateTime.now().isAfter(expiresAt)) {
            await file.delete();
            return null;
          }
        }
        return cachedPath;
      }
    } catch (e) {
      _logger.severe('Error getting cached media file: $e');
    }
    return null;
  }

  /// Queue data for sync when back online
  Future<void> queueForSync({
    required String operation,
    required Map<String, dynamic> data,
  }) async {
    final pendingSync = _prefs.getStringList('pending_sync') ?? [];
    final syncItem = {
      'operation': operation,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };

    pendingSync.add(jsonEncode(syncItem));
    await _prefs.setStringList('pending_sync', pendingSync);
  }

  /// Clean expired cache entries
  Future<void> _cleanExpiredCache() async {
    try {
      // Clean memory cache
      final expiredKeys = _memoryCache.keys.where((key) {
        final item = _memoryCache[key];
        return item is CachedItem && item.isExpired;
      }).toList();

      for (final key in expiredKeys) {
        _memoryCache.remove(key);
      }

      // Clean disk cache
      final cacheDir = Directory(_cacheDirectory);
      if (await cacheDir.exists()) {
        await for (final file in cacheDir.list()) {
          if (file is File && file.path.endsWith('.cache')) {
            try {
              final content = await file.readAsString();
              final json = jsonDecode(content);

              if (json['expiresAt'] != null) {
                final expiresAt = DateTime.parse(json['expiresAt']);
                if (DateTime.now().isAfter(expiresAt)) {
                  await file.delete();
                }
              }
            } catch (e) {
              // Delete corrupted cache files
              await file.delete();
            }
          }
        }
      }

      // Clean expired media files
      await _cleanExpiredMediaFiles();
    } catch (e) {
      _logger.severe('Error cleaning expired cache: $e');
    }
  }

  /// Clean expired media files
  Future<void> _cleanExpiredMediaFiles() async {
    final keys = _prefs
        .getKeys()
        .where((key) => key.endsWith('_expires_at'))
        .toList();

    for (final key in keys) {
      final expiresAtStr = _prefs.getString(key);
      if (expiresAtStr != null) {
        final expiresAt = DateTime.parse(expiresAtStr);
        if (DateTime.now().isAfter(expiresAt)) {
          final cacheKey = key.replaceAll('_expires_at', '');
          final mediaPath = await _getMediaCachePath(cacheKey);
          final file = File(mediaPath);

          if (await file.exists()) {
            await file.delete();
          }

          await _prefs.remove(key);
          await _prefs.remove('${cacheKey}_cached_at');
        }
      }
    }
  }

  /// Save cached item to disk
  Future<void> _saveToDisk<T>(String key, CachedItem<T> item) async {
    try {
      final file = File('$_cacheDirectory/$key.cache');
      await file.writeAsString(jsonEncode(item.toJson()));
    } catch (e) {
      _logger.severe('Error saving to disk cache: $e');
    }
  }

  /// Load cached item from disk
  Future<CachedItem<T>?> _loadFromDisk<T>(
    String key,
    T Function(Map<String, dynamic>)? deserializer,
  ) async {
    try {
      final file = File('$_cacheDirectory/$key.cache');
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      final json = jsonDecode(content);

      if (deserializer != null) {
        return CachedItem<T>(
          key: json['key'],
          data: deserializer(json['data']),
          cachedAt: DateTime.parse(json['cachedAt']),
          expiresAt: json['expiresAt'] != null
              ? DateTime.parse(json['expiresAt'])
              : null,
          metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
        );
      }

      return null;
    } catch (e) {
      _logger.severe('Error loading from disk cache: $e');
      return null;
    }
  }

  /// Get media cache file path
  Future<String> _getMediaCachePath(String cacheKey) async {
    return '$_cacheDirectory/media/$cacheKey';
  }

  /// Limit memory cache size
  void _limitMemoryCache() {
    if (_memoryCache.length > _maxMemoryCacheSize) {
      // Remove oldest items
      final sortedKeys = _memoryCache.keys.toList()
        ..sort((a, b) {
          final itemA = _memoryCache[a] as CachedItem;
          final itemB = _memoryCache[b] as CachedItem;
          return itemA.cachedAt.compareTo(itemB.cachedAt);
        });

      final keysToRemove = sortedKeys.take(
        _memoryCache.length - _maxMemoryCacheSize,
      );
      for (final key in keysToRemove) {
        _memoryCache.remove(key);
      }
    }
  }

  /// Create from cached data with proper deserialization
  T _deserializeFromCache<T>(Map<String, dynamic> data, String type) {
    switch (type) {
      case 'SocialPost':
        return SocialPost.fromMap(data) as T;
      case 'ChatMessage':
        return ChatMessage.fromMap(data) as T;
      case 'ChatConversation':
        return ChatConversation.fromMap(data) as T;
      case 'UserProfile':
        return UserProfile.fromMap(data) as T;
      case 'PostComment':
        return post_comment_model.PostComment.fromMap(data) as T;
      default:
        throw Exception('Unknown type for deserialization: $type');
    }
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    _memoryCache.clear();

    final cacheDir = Directory(_cacheDirectory);
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
      await cacheDir.create(recursive: true);
    }

    // Clear SharedPreferences cache keys
    final keys = _prefs
        .getKeys()
        .where(
          (key) =>
              key.startsWith('pending_sync') ||
              key.contains('_cached_at') ||
              key.contains('_expires_at'),
        )
        .toList();

    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final cacheDir = Directory(_cacheDirectory);
    int fileCount = 0;
    int totalSize = 0;

    if (await cacheDir.exists()) {
      await for (final file in cacheDir.list(recursive: true)) {
        if (file is File) {
          fileCount++;
          totalSize += await file.length();
        }
      }
    }

    return {
      'memoryItems': _memoryCache.length,
      'diskFiles': fileCount,
      'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
      'isOnline': _isOnline,
      'pendingSyncItems': (_prefs.getStringList('pending_sync') ?? []).length,
    };
  }
}

/// Extension for easier cache access
extension CacheExtensions on FirebaseFirestore {
  /// Enable offline persistence
  Future<void> enableOfflineSupport() async {
    final logger = Logger('CacheExtensions');
    try {
      // Note: Persistence should now be enabled through Settings.persistenceEnabled
      // during app initialization rather than called at runtime
      logger.info(
        'Firestore persistence should be configured during initialization',
      );
    } catch (e) {
      logger.severe('Error enabling Firestore offline persistence: $e');
    }
  }
}
