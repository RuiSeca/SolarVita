import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/assets/cached_asset.dart';

final log = Logger('AssetCacheService');

/// High-performance asset caching service for avatars, images, and animations
/// Implements CDN integration, local storage, and fallback handling
class AssetCacheService {
  static const String _cacheDir = 'solar_vita_cache';
  static const String _avatarSubDir = 'avatars';
  static const String _previewSubDir = 'previews';
  static const String _rivSubDir = 'rive_files';
  
  // Cache size limits
  static const int maxCacheSizeBytes = 500 * 1024 * 1024; // 500MB
  static const int maxPreviewCacheSize = 100 * 1024 * 1024; // 100MB for previews
  static const int maxRiveCacheSize = 300 * 1024 * 1024; // 300MB for animations
  
  // CDN and Firebase Storage configuration
  static const String cdnBaseUrl = 'https://cdn.solarvita.app';
  static const String firebaseStorageBucket = 'grooves-app.firebasestorage.app';
  
  final Map<String, CachedAsset> _memoryCache = {};
  final Map<String, Future<CachedAsset>> _downloadFutures = {};
  
  Directory? _cacheDirectory;
  Directory? _avatarCacheDirectory;
  Directory? _previewCacheDirectory;
  Directory? _riveCacheDirectory;

  /// Initialize the asset cache service
  Future<void> initialize() async {
    try {
      log.info('🚀 Initializing Asset Cache Service...');
      
      // Create cache directories
      await _createCacheDirectories();
      
      // Load existing cache metadata
      await _loadCacheMetadata();
      
      // Clean up old/expired cache files
      await _performCacheCleanup();
      
      log.info('✅ Asset Cache Service initialized successfully');
    } catch (e, stackTrace) {
      log.severe('❌ Failed to initialize Asset Cache Service: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Create necessary cache directories
  Future<void> _createCacheDirectories() async {
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDirectory = Directory('${appDir.path}/$_cacheDir');
    _avatarCacheDirectory = Directory('${_cacheDirectory!.path}/$_avatarSubDir');
    _previewCacheDirectory = Directory('${_cacheDirectory!.path}/$_previewSubDir');
    _riveCacheDirectory = Directory('${_cacheDirectory!.path}/$_rivSubDir');

    // Create directories if they don't exist
    await _cacheDirectory!.create(recursive: true);
    await _avatarCacheDirectory!.create(recursive: true);
    await _previewCacheDirectory!.create(recursive: true);
    await _riveCacheDirectory!.create(recursive: true);

    log.info('📁 Cache directories created at: ${_cacheDirectory!.path}');
  }

  /// Load existing cache metadata from disk
  Future<void> _loadCacheMetadata() async {
    try {
      final metadataFile = File('${_cacheDirectory!.path}/cache_metadata.json');
      if (await metadataFile.exists()) {
        final metadataJson = await metadataFile.readAsString();
        final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;
        
        // Load cache statistics (just skip for now, we'll recalculate)
        // _cacheStats will be calculated from actual cache contents
        
        // Load cached asset entries
        final entries = metadata['entries'] as Map<String, dynamic>? ?? {};
        _memoryCache.clear();
        
        for (final entry in entries.entries) {
          try {
            final assetData = entry.value as Map<String, dynamic>;
            final cachedAsset = CachedAsset(
              id: assetData['id'] as String,
              type: AssetType.values.firstWhere(
                (t) => t.name == assetData['type'],
                orElse: () => AssetType.preview,
              ),
              data: Uint8List(0), // Will be loaded from disk when needed
              localPath: assetData['localPath'] as String? ?? '',
              isLocal: assetData['isLocal'] as bool? ?? false,
              downloadTime: assetData['downloadTime'] != null
                ? DateTime.parse(assetData['downloadTime'] as String)
                : DateTime.now(),
            );
            
            // Only add to memory cache if file still exists
            if (cachedAsset.localPath.isNotEmpty && 
                await File(cachedAsset.localPath).exists()) {
              _memoryCache[cachedAsset.id] = cachedAsset;
            }
          } catch (e) {
            log.warning('⚠️ Failed to parse cache entry ${entry.key}: $e');
          }
        }
        
        log.info('📋 Cache metadata loaded: ${_memoryCache.length} entries');
      } else {
        log.info('📋 No cache metadata found, starting fresh');
      }
    } catch (e) {
      log.warning('⚠️ Failed to load cache metadata: $e');
    }
  }

  /// Save cache metadata to disk
  Future<void> _saveCacheMetadata() async {
    try {
      final metadataFile = File('${_cacheDirectory!.path}/cache_metadata.json');
      
      final metadata = {
        'version': 1,
        'lastUpdated': DateTime.now().toIso8601String(),
        'itemCount': _memoryCache.length,
        'entries': _memoryCache.map((key, value) => MapEntry(key, {
          'id': value.id,
          'type': value.type.name,
          'localPath': value.localPath,
          'isLocal': value.isLocal,
          'downloadTime': value.downloadTime.toIso8601String(),
          'sizeBytes': value.sizeBytes,
        })),
      };
      
      await metadataFile.writeAsString(jsonEncode(metadata));
      log.info('💾 Cache metadata saved');
    } catch (e) {
      log.warning('⚠️ Failed to save cache metadata: $e');
    }
  }

  /// Perform cache cleanup to maintain size limits
  Future<void> _performCacheCleanup() async {
    try {
      log.info('🧹 Performing cache cleanup...');
      
      // Clean up preview cache
      await _cleanupDirectory(_previewCacheDirectory!, maxPreviewCacheSize);
      
      // Clean up Rive cache
      await _cleanupDirectory(_riveCacheDirectory!, maxRiveCacheSize);
      
      // Save updated metadata
      await _saveCacheMetadata();
      
      log.info('✅ Cache cleanup completed');
    } catch (e) {
      log.warning('⚠️ Cache cleanup failed: $e');
    }
  }

  /// Clean up a specific directory to stay within size limits
  Future<void> _cleanupDirectory(Directory directory, int maxSizeBytes) async {
    try {
      final files = await directory.list().where((entity) => entity is File).cast<File>().toList();
      
      // Sort files by last modified time (oldest first)
      files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
      
      int totalSize = 0;
      for (final file in files) {
        totalSize += await file.length();
      }
      
      // Remove oldest files if over size limit
      while (totalSize > maxSizeBytes && files.isNotEmpty) {
        final oldestFile = files.removeAt(0);
        final fileSize = await oldestFile.length();
        await oldestFile.delete();
        totalSize -= fileSize;
        log.info('🗑️ Removed cached file: ${oldestFile.path}');
      }
    } catch (e) {
      log.warning('⚠️ Directory cleanup failed: $e');
    }
  }

  /// Get avatar preview image (static PNG/WebP)
  Future<CachedAsset> getAvatarPreview(String avatarId, {String? customUrl}) async {
    final cacheKey = 'preview_$avatarId';
    
    // Check memory cache first
    if (_memoryCache.containsKey(cacheKey)) {
      log.info('🎯 Avatar preview cache hit: $avatarId');
      return _memoryCache[cacheKey]!;
    }

    // Check if already downloading
    if (_downloadFutures.containsKey(cacheKey)) {
      return await _downloadFutures[cacheKey]!;
    }

    // Start download process
    _downloadFutures[cacheKey] = _downloadAvatarPreview(avatarId, customUrl);
    
    try {
      final asset = await _downloadFutures[cacheKey]!;
      _memoryCache[cacheKey] = asset;
      return asset;
    } finally {
      _downloadFutures.remove(cacheKey);
    }
  }

  /// Download avatar preview with fallback strategy
  Future<CachedAsset> _downloadAvatarPreview(String avatarId, String? customUrl) async {
    log.info('⬇️ Downloading avatar preview: $avatarId');
    
    final fileName = '${avatarId}_preview.webp';
    final localFile = File('${_previewCacheDirectory!.path}/$fileName');
    
    // Check local cache first
    if (await localFile.exists()) {
      try {
        final bytes = await localFile.readAsBytes();
        final asset = CachedAsset(
          id: avatarId,
          type: AssetType.preview,
          data: bytes,
          localPath: localFile.path,
          isLocal: true,
          downloadTime: localFile.lastModifiedSync(),
        );
        log.info('📂 Avatar preview loaded from cache: $avatarId');
        return asset;
      } catch (e) {
        log.warning('⚠️ Failed to load cached preview, re-downloading: $e');
      }
    }

    // Download from CDN/Firebase with fallback strategy
    Uint8List? bytes;
    
    // Try CDN first
    if (customUrl != null) {
      bytes = await _downloadFromUrl(customUrl);
    } else {
      bytes = await _downloadFromUrl('$cdnBaseUrl/avatars/previews/$fileName');
    }
    
    // Fallback to Firebase Storage
    bytes ??= await _downloadFromFirebaseStorage('avatars/previews/$fileName');
    
    // Fallback to bundled assets
    bytes ??= await _loadBundledPreview(avatarId);
    
    if (bytes == null) {
      throw Exception('Failed to load avatar preview: $avatarId');
    }

    // Save to local cache
    try {
      await localFile.writeAsBytes(bytes);
      log.info('💾 Avatar preview cached locally: $avatarId');
    } catch (e) {
      log.warning('⚠️ Failed to cache preview locally: $e');
    }

    return CachedAsset(
      id: avatarId,
      type: AssetType.preview,
      data: bytes,
      localPath: localFile.path,
      isLocal: false,
      downloadTime: DateTime.now(),
    );
  }

  /// Get Rive animation file (.riv) with lazy loading
  Future<CachedAsset> getRiveAnimation(String avatarId, {String? customUrl, bool forceDownload = false}) async {
    final cacheKey = 'rive_$avatarId';
    
    // Check memory cache first (unless forcing download)
    if (!forceDownload && _memoryCache.containsKey(cacheKey)) {
      log.info('🎯 Rive animation cache hit: $avatarId');
      return _memoryCache[cacheKey]!;
    }

    // Check if already downloading
    if (_downloadFutures.containsKey(cacheKey)) {
      return await _downloadFutures[cacheKey]!;
    }

    // Start download process
    _downloadFutures[cacheKey] = _downloadRiveAnimation(avatarId, customUrl, forceDownload);
    
    try {
      final asset = await _downloadFutures[cacheKey]!;
      _memoryCache[cacheKey] = asset;
      return asset;
    } finally {
      _downloadFutures.remove(cacheKey);
    }
  }

  /// Download Rive animation with progressive loading
  Future<CachedAsset> _downloadRiveAnimation(String avatarId, String? customUrl, bool forceDownload) async {
    log.info('⬇️ Downloading Rive animation: $avatarId (force: $forceDownload)');
    
    final fileName = '$avatarId.riv';
    final localFile = File('${_riveCacheDirectory!.path}/$fileName');
    
    // Check local cache first (unless forcing download)
    if (!forceDownload && await localFile.exists()) {
      try {
        final bytes = await localFile.readAsBytes();
        final asset = CachedAsset(
          id: avatarId,
          type: AssetType.riveAnimation,
          data: bytes,
          localPath: localFile.path,
          isLocal: true,
          downloadTime: localFile.lastModifiedSync(),
        );
        log.info('📂 Rive animation loaded from cache: $avatarId');
        return asset;
      } catch (e) {
        log.warning('⚠️ Failed to load cached Rive file, re-downloading: $e');
      }
    }

    // Download from CDN/Firebase
    Uint8List? bytes;
    
    // Try CDN first
    if (customUrl != null) {
      bytes = await _downloadFromUrl(customUrl);
    } else {
      bytes = await _downloadFromUrl('$cdnBaseUrl/avatars/animations/$fileName');
    }
    
    // Fallback to Firebase Storage
    bytes ??= await _downloadFromFirebaseStorage('avatars/animations/$fileName');
    
    // Fallback to bundled assets
    bytes ??= await _loadBundledRive(avatarId);
    
    if (bytes == null) {
      throw Exception('Failed to load Rive animation: $avatarId');
    }

    // Save to local cache
    try {
      await localFile.writeAsBytes(bytes);
      log.info('💾 Rive animation cached locally: $avatarId');
    } catch (e) {
      log.warning('⚠️ Failed to cache Rive file locally: $e');
    }

    return CachedAsset(
      id: avatarId,
      type: AssetType.riveAnimation,
      data: bytes,
      localPath: localFile.path,
      isLocal: false,
      downloadTime: DateTime.now(),
    );
  }

  /// Download from URL with timeout and retry logic
  Future<Uint8List?> _downloadFromUrl(String url) async {
    try {
      log.info('🌐 Downloading from URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'SolarVita-Flutter-App',
          'Accept': '*/*',
        },
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        log.info('✅ Successfully downloaded from URL: ${response.bodyBytes.length} bytes');
        return response.bodyBytes;
      } else {
        log.warning('⚠️ HTTP ${response.statusCode} from URL: $url');
        return null;
      }
    } catch (e) {
      log.warning('⚠️ Failed to download from URL $url: $e');
      return null;
    }
  }

  /// Download from Firebase Storage
  Future<Uint8List?> _downloadFromFirebaseStorage(String path) async {
    try {
      log.info('🔥 Downloading from Firebase Storage: $path');
      
      final ref = FirebaseStorage.instance.ref(path);
      final bytes = await ref.getData();
      
      if (bytes != null) {
        log.info('✅ Successfully downloaded from Firebase: ${bytes.length} bytes');
        return bytes;
      } else {
        log.warning('⚠️ No data from Firebase Storage: $path');
        return null;
      }
    } catch (e) {
      log.warning('⚠️ Failed to download from Firebase Storage $path: $e');
      return null;
    }
  }

  /// Load bundled preview image
  Future<Uint8List?> _loadBundledPreview(String avatarId) async {
    try {
      // Try different preview formats
      final possiblePaths = [
        'assets/images/avatars/previews/${avatarId}_preview.webp',
        'assets/images/avatars/previews/$avatarId.webp',
        'assets/images/avatars/previews/${avatarId}_preview.png',
        'assets/images/avatars/previews/$avatarId.png',
      ];

      for (final path in possiblePaths) {
        try {
          final bytes = await rootBundle.load(path);
          log.info('📦 Loaded bundled preview: $path');
          return bytes.buffer.asUint8List();
        } catch (e) {
          // Try next path
        }
      }
      
      log.warning('⚠️ No bundled preview found for: $avatarId');
      return null;
    } catch (e) {
      log.warning('⚠️ Failed to load bundled preview: $e');
      return null;
    }
  }

  /// Load bundled Rive animation
  Future<Uint8List?> _loadBundledRive(String avatarId) async {
    try {
      // Try different Rive paths
      final possiblePaths = [
        'assets/rive/$avatarId.riv',
        'assets/rive/avatars/$avatarId.riv',
      ];

      for (final path in possiblePaths) {
        try {
          final bytes = await rootBundle.load(path);
          log.info('📦 Loaded bundled Rive: $path');
          return bytes.buffer.asUint8List();
        } catch (e) {
          // Try next path
        }
      }
      
      log.warning('⚠️ No bundled Rive found for: $avatarId');
      return null;
    } catch (e) {
      log.warning('⚠️ Failed to load bundled Rive: $e');
      return null;
    }
  }

  /// Preload purchased avatars (called after successful purchase)
  Future<void> preloadPurchasedAvatar(String avatarId, {String? riveUrl, String? previewUrl}) async {
    try {
      log.info('🎯 Preloading purchased avatar: $avatarId');
      
      // Download both preview and animation in parallel
      await Future.wait([
        getAvatarPreview(avatarId, customUrl: previewUrl),
        getRiveAnimation(avatarId, customUrl: riveUrl),
      ]);
      
      log.info('✅ Avatar preloaded successfully: $avatarId');
    } catch (e) {
      log.warning('⚠️ Failed to preload avatar $avatarId: $e');
    }
  }

  /// Clear specific avatar from cache
  Future<void> clearAvatarCache(String avatarId) async {
    try {
      // Remove from memory cache
      _memoryCache.remove('preview_$avatarId');
      _memoryCache.remove('rive_$avatarId');
      
      // Remove from disk cache
      final previewFile = File('${_previewCacheDirectory!.path}/${avatarId}_preview.webp');
      final riveFile = File('${_riveCacheDirectory!.path}/$avatarId.riv');
      
      if (await previewFile.exists()) {
        await previewFile.delete();
      }
      
      if (await riveFile.exists()) {
        await riveFile.delete();
      }
      
      log.info('🗑️ Cleared cache for avatar: $avatarId');
    } catch (e) {
      log.warning('⚠️ Failed to clear cache for avatar $avatarId: $e');
    }
  }

  /// Get cache statistics
  Future<CacheStats> getCacheStats() async {
    try {
      int previewCount = 0, previewSize = 0;
      int riveCount = 0, riveSize = 0;
      
      // Count preview files
      await for (final entity in _previewCacheDirectory!.list()) {
        if (entity is File) {
          previewCount++;
          previewSize += await entity.length();
        }
      }
      
      // Count Rive files
      await for (final entity in _riveCacheDirectory!.list()) {
        if (entity is File) {
          riveCount++;
          riveSize += await entity.length();
        }
      }
      
      return CacheStats(
        previewCount: previewCount,
        previewSizeBytes: previewSize,
        riveCount: riveCount,
        riveSizeBytes: riveSize,
        memoryCount: _memoryCache.length,
        totalSizeBytes: previewSize + riveSize,
      );
    } catch (e) {
      log.warning('⚠️ Failed to get cache stats: $e');
      return CacheStats(
        previewCount: 0,
        previewSizeBytes: 0,
        riveCount: 0,
        riveSizeBytes: 0,
        memoryCount: 0,
        totalSizeBytes: 0,
      );
    }
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    try {
      log.info('🧹 Clearing all asset cache...');
      
      // Clear memory cache
      _memoryCache.clear();
      
      // Clear disk cache
      if (await _previewCacheDirectory!.exists()) {
        await _previewCacheDirectory!.delete(recursive: true);
        await _previewCacheDirectory!.create();
      }
      
      if (await _riveCacheDirectory!.exists()) {
        await _riveCacheDirectory!.delete(recursive: true);
        await _riveCacheDirectory!.create();
      }
      
      log.info('✅ All cache cleared');
    } catch (e) {
      log.severe('❌ Failed to clear all cache: $e');
    }
  }

  /// Dispose service
  void dispose() {
    _memoryCache.clear();
    _downloadFutures.clear();
    log.info('🧹 Asset Cache Service disposed');
  }
}

/// Cache statistics
class CacheStats {
  final int previewCount;
  final int previewSizeBytes;
  final int riveCount;
  final int riveSizeBytes;
  final int memoryCount;
  final int totalSizeBytes;

  const CacheStats({
    required this.previewCount,
    required this.previewSizeBytes,
    required this.riveCount,
    required this.riveSizeBytes,
    required this.memoryCount,
    required this.totalSizeBytes,
  });

  String get previewSizeFormatted => _formatBytes(previewSizeBytes);
  String get riveSizeFormatted => _formatBytes(riveSizeBytes);
  String get totalSizeFormatted => _formatBytes(totalSizeBytes);

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  @override
  String toString() {
    return 'CacheStats{previews: $previewCount ($previewSizeFormatted), rive: $riveCount ($riveSizeFormatted), memory: $memoryCount, total: $totalSizeFormatted}';
  }
}