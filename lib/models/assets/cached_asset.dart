import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Types of assets that can be cached
enum AssetType {
  preview,        // Static preview images (PNG/WebP)
  riveAnimation,  // Rive animation files (.riv)
  customization,  // Avatar customization data
  metadata,       // Asset metadata and configuration
}

/// Represents a cached asset with metadata
class CachedAsset {
  final String id;
  final AssetType type;
  final Uint8List data;
  final String localPath;
  final bool isLocal;
  final DateTime downloadTime;
  final String? url;
  final String? checksum;
  final int? version;
  final Map<String, dynamic>? metadata;

  const CachedAsset({
    required this.id,
    required this.type,
    required this.data,
    required this.localPath,
    required this.isLocal,
    required this.downloadTime,
    this.url,
    this.checksum,
    this.version,
    this.metadata,
  });

  /// Get asset size in bytes
  int get sizeBytes => data.length;

  /// Check if asset is expired based on age
  bool isExpired({Duration maxAge = const Duration(days: 7)}) {
    return DateTime.now().difference(downloadTime) > maxAge;
  }

  /// Get formatted size string
  String get sizeFormatted {
    final bytes = sizeBytes;
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// Create a copy with updated properties
  CachedAsset copyWith({
    String? id,
    AssetType? type,
    Uint8List? data,
    String? localPath,
    bool? isLocal,
    DateTime? downloadTime,
    String? url,
    String? checksum,
    int? version,
    Map<String, dynamic>? metadata,
  }) {
    return CachedAsset(
      id: id ?? this.id,
      type: type ?? this.type,
      data: data ?? this.data,
      localPath: localPath ?? this.localPath,
      isLocal: isLocal ?? this.isLocal,
      downloadTime: downloadTime ?? this.downloadTime,
      url: url ?? this.url,
      checksum: checksum ?? this.checksum,
      version: version ?? this.version,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'localPath': localPath,
      'isLocal': isLocal,
      'downloadTime': downloadTime.millisecondsSinceEpoch,
      'url': url,
      'checksum': checksum,
      'version': version,
      'metadata': metadata,
      'sizeBytes': sizeBytes,
    };
  }

  /// Create from JSON (without data, used for metadata)
  factory CachedAsset.fromJson(Map<String, dynamic> json) {
    return CachedAsset(
      id: json['id'] as String,
      type: AssetType.values.firstWhere((t) => t.name == json['type']),
      data: Uint8List(0), // Empty data, will be loaded separately
      localPath: json['localPath'] as String,
      isLocal: json['isLocal'] as bool,
      downloadTime: DateTime.fromMillisecondsSinceEpoch(json['downloadTime'] as int),
      url: json['url'] as String?,
      checksum: json['checksum'] as String?,
      version: json['version'] as int?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedAsset &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          localPath == other.localPath;

  @override
  int get hashCode => id.hashCode ^ type.hashCode ^ localPath.hashCode;

  @override
  String toString() {
    return 'CachedAsset{id: $id, type: $type, size: $sizeFormatted, local: $isLocal, path: $localPath}';
  }
}

/// Download progress information
class AssetDownloadProgress {
  final String assetId;
  final int bytesReceived;
  final int totalBytes;
  final double progress;
  final AssetDownloadState state;
  final String? error;

  const AssetDownloadProgress({
    required this.assetId,
    required this.bytesReceived,
    required this.totalBytes,
    required this.progress,
    required this.state,
    this.error,
  });

  /// Create progress for started download
  factory AssetDownloadProgress.started(String assetId) {
    return AssetDownloadProgress(
      assetId: assetId,
      bytesReceived: 0,
      totalBytes: 0,
      progress: 0.0,
      state: AssetDownloadState.downloading,
    );
  }

  /// Create progress update
  factory AssetDownloadProgress.progress(String assetId, int received, int total) {
    return AssetDownloadProgress(
      assetId: assetId,
      bytesReceived: received,
      totalBytes: total,
      progress: total > 0 ? received / total : 0.0,
      state: AssetDownloadState.downloading,
    );
  }

  /// Create completed progress
  factory AssetDownloadProgress.completed(String assetId, int totalBytes) {
    return AssetDownloadProgress(
      assetId: assetId,
      bytesReceived: totalBytes,
      totalBytes: totalBytes,
      progress: 1.0,
      state: AssetDownloadState.completed,
    );
  }

  /// Create error progress
  factory AssetDownloadProgress.error(String assetId, String error) {
    return AssetDownloadProgress(
      assetId: assetId,
      bytesReceived: 0,
      totalBytes: 0,
      progress: 0.0,
      state: AssetDownloadState.error,
      error: error,
    );
  }

  /// Get formatted progress percentage
  String get progressPercentage => '${(progress * 100).toStringAsFixed(1)}%';

  /// Get formatted bytes received
  String get bytesReceivedFormatted => _formatBytes(bytesReceived);

  /// Get formatted total bytes
  String get totalBytesFormatted => _formatBytes(totalBytes);

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetDownloadProgress &&
          runtimeType == other.runtimeType &&
          assetId == other.assetId &&
          bytesReceived == other.bytesReceived &&
          totalBytes == other.totalBytes &&
          state == other.state;

  @override
  int get hashCode =>
      assetId.hashCode ^ bytesReceived.hashCode ^ totalBytes.hashCode ^ state.hashCode;

  @override
  String toString() {
    return 'AssetDownloadProgress{id: $assetId, progress: $progressPercentage, state: $state}';
  }
}

/// Download states for assets
enum AssetDownloadState {
  pending,     // Queued for download
  downloading, // Currently downloading
  completed,   // Successfully downloaded
  error,       // Download failed
  cached,      // Already cached locally
}

/// Asset cache metadata for persistence
class AssetCacheMetadata {
  final String id;
  final AssetType type;
  final String localPath;
  final DateTime cachedAt;
  final DateTime lastAccessed;
  final int sizeBytes;
  final String? url;
  final String? checksum;
  final int version;
  final int accessCount;

  const AssetCacheMetadata({
    required this.id,
    required this.type,
    required this.localPath,
    required this.cachedAt,
    required this.lastAccessed,
    required this.sizeBytes,
    this.url,
    this.checksum,
    required this.version,
    required this.accessCount,
  });

  /// Create from CachedAsset
  factory AssetCacheMetadata.fromAsset(CachedAsset asset) {
    return AssetCacheMetadata(
      id: asset.id,
      type: asset.type,
      localPath: asset.localPath,
      cachedAt: asset.downloadTime,
      lastAccessed: DateTime.now(),
      sizeBytes: asset.sizeBytes,
      url: asset.url,
      checksum: asset.checksum,
      version: asset.version ?? 1,
      accessCount: 1,
    );
  }

  /// Update access information
  AssetCacheMetadata updateAccess() {
    return AssetCacheMetadata(
      id: id,
      type: type,
      localPath: localPath,
      cachedAt: cachedAt,
      lastAccessed: DateTime.now(),
      sizeBytes: sizeBytes,
      url: url,
      checksum: checksum,
      version: version,
      accessCount: accessCount + 1,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'localPath': localPath,
      'cachedAt': cachedAt.millisecondsSinceEpoch,
      'lastAccessed': lastAccessed.millisecondsSinceEpoch,
      'sizeBytes': sizeBytes,
      'url': url,
      'checksum': checksum,
      'version': version,
      'accessCount': accessCount,
    };
  }

  /// Create from JSON
  factory AssetCacheMetadata.fromJson(Map<String, dynamic> json) {
    return AssetCacheMetadata(
      id: json['id'] as String,
      type: AssetType.values.firstWhere((t) => t.name == json['type']),
      localPath: json['localPath'] as String,
      cachedAt: DateTime.fromMillisecondsSinceEpoch(json['cachedAt'] as int),
      lastAccessed: DateTime.fromMillisecondsSinceEpoch(json['lastAccessed'] as int),
      sizeBytes: json['sizeBytes'] as int,
      url: json['url'] as String?,
      checksum: json['checksum'] as String?,
      version: json['version'] as int,
      accessCount: json['accessCount'] as int,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetCacheMetadata &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type;

  @override
  int get hashCode => id.hashCode ^ type.hashCode;

  @override
  String toString() {
    return 'AssetCacheMetadata{id: $id, type: $type, size: ${_formatBytes(sizeBytes)}, version: $version, accessed: $accessCount times}';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}