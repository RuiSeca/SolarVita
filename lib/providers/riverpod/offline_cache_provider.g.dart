// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_cache_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$offlineCacheServiceHash() =>
    r'32098879c7aa8b5d39529be6ad2d43d32e132eb4';

/// See also [offlineCacheService].
@ProviderFor(offlineCacheService)
final offlineCacheServiceProvider =
    AutoDisposeProvider<OfflineCacheService>.internal(
      offlineCacheService,
      name: r'offlineCacheServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$offlineCacheServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OfflineCacheServiceRef = AutoDisposeProviderRef<OfflineCacheService>;
String _$cachedSocialPostsHash() => r'35c7937463e483576ea596c7fff8c00141e37ac2';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [cachedSocialPosts].
@ProviderFor(cachedSocialPosts)
const cachedSocialPostsProvider = CachedSocialPostsFamily();

/// See also [cachedSocialPosts].
class CachedSocialPostsFamily extends Family<AsyncValue<List<SocialPost>?>> {
  /// See also [cachedSocialPosts].
  const CachedSocialPostsFamily();

  /// See also [cachedSocialPosts].
  CachedSocialPostsProvider call({String? feedType}) {
    return CachedSocialPostsProvider(feedType: feedType);
  }

  @override
  CachedSocialPostsProvider getProviderOverride(
    covariant CachedSocialPostsProvider provider,
  ) {
    return call(feedType: provider.feedType);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'cachedSocialPostsProvider';
}

/// See also [cachedSocialPosts].
class CachedSocialPostsProvider
    extends AutoDisposeFutureProvider<List<SocialPost>?> {
  /// See also [cachedSocialPosts].
  CachedSocialPostsProvider({String? feedType})
    : this._internal(
        (ref) =>
            cachedSocialPosts(ref as CachedSocialPostsRef, feedType: feedType),
        from: cachedSocialPostsProvider,
        name: r'cachedSocialPostsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$cachedSocialPostsHash,
        dependencies: CachedSocialPostsFamily._dependencies,
        allTransitiveDependencies:
            CachedSocialPostsFamily._allTransitiveDependencies,
        feedType: feedType,
      );

  CachedSocialPostsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.feedType,
  }) : super.internal();

  final String? feedType;

  @override
  Override overrideWith(
    FutureOr<List<SocialPost>?> Function(CachedSocialPostsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CachedSocialPostsProvider._internal(
        (ref) => create(ref as CachedSocialPostsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        feedType: feedType,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<SocialPost>?> createElement() {
    return _CachedSocialPostsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CachedSocialPostsProvider && other.feedType == feedType;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, feedType.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CachedSocialPostsRef on AutoDisposeFutureProviderRef<List<SocialPost>?> {
  /// The parameter `feedType` of this provider.
  String? get feedType;
}

class _CachedSocialPostsProviderElement
    extends AutoDisposeFutureProviderElement<List<SocialPost>?>
    with CachedSocialPostsRef {
  _CachedSocialPostsProviderElement(super.provider);

  @override
  String? get feedType => (origin as CachedSocialPostsProvider).feedType;
}

String _$cachedChatConversationsHash() =>
    r'bf2802e579a1f9b80d5c23f015cbd05609326154';

/// See also [cachedChatConversations].
@ProviderFor(cachedChatConversations)
final cachedChatConversationsProvider =
    AutoDisposeFutureProvider<List<ChatConversation>?>.internal(
      cachedChatConversations,
      name: r'cachedChatConversationsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$cachedChatConversationsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CachedChatConversationsRef =
    AutoDisposeFutureProviderRef<List<ChatConversation>?>;
String _$cachedChatMessagesHash() =>
    r'4fc5bce263bccd98e48cbded0dadd06ee1fa9171';

/// See also [cachedChatMessages].
@ProviderFor(cachedChatMessages)
const cachedChatMessagesProvider = CachedChatMessagesFamily();

/// See also [cachedChatMessages].
class CachedChatMessagesFamily extends Family<AsyncValue<List<ChatMessage>?>> {
  /// See also [cachedChatMessages].
  const CachedChatMessagesFamily();

  /// See also [cachedChatMessages].
  CachedChatMessagesProvider call(String conversationId) {
    return CachedChatMessagesProvider(conversationId);
  }

  @override
  CachedChatMessagesProvider getProviderOverride(
    covariant CachedChatMessagesProvider provider,
  ) {
    return call(provider.conversationId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'cachedChatMessagesProvider';
}

/// See also [cachedChatMessages].
class CachedChatMessagesProvider
    extends AutoDisposeFutureProvider<List<ChatMessage>?> {
  /// See also [cachedChatMessages].
  CachedChatMessagesProvider(String conversationId)
    : this._internal(
        (ref) =>
            cachedChatMessages(ref as CachedChatMessagesRef, conversationId),
        from: cachedChatMessagesProvider,
        name: r'cachedChatMessagesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$cachedChatMessagesHash,
        dependencies: CachedChatMessagesFamily._dependencies,
        allTransitiveDependencies:
            CachedChatMessagesFamily._allTransitiveDependencies,
        conversationId: conversationId,
      );

  CachedChatMessagesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.conversationId,
  }) : super.internal();

  final String conversationId;

  @override
  Override overrideWith(
    FutureOr<List<ChatMessage>?> Function(CachedChatMessagesRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CachedChatMessagesProvider._internal(
        (ref) => create(ref as CachedChatMessagesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        conversationId: conversationId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<ChatMessage>?> createElement() {
    return _CachedChatMessagesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CachedChatMessagesProvider &&
        other.conversationId == conversationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, conversationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CachedChatMessagesRef
    on AutoDisposeFutureProviderRef<List<ChatMessage>?> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;
}

class _CachedChatMessagesProviderElement
    extends AutoDisposeFutureProviderElement<List<ChatMessage>?>
    with CachedChatMessagesRef {
  _CachedChatMessagesProviderElement(super.provider);

  @override
  String get conversationId =>
      (origin as CachedChatMessagesProvider).conversationId;
}

String _$cachedUserProfileHash() => r'c48e61b99203d2cfbf88cdc7fe9e9508cccc989d';

/// See also [cachedUserProfile].
@ProviderFor(cachedUserProfile)
const cachedUserProfileProvider = CachedUserProfileFamily();

/// See also [cachedUserProfile].
class CachedUserProfileFamily extends Family<AsyncValue<UserProfile?>> {
  /// See also [cachedUserProfile].
  const CachedUserProfileFamily();

  /// See also [cachedUserProfile].
  CachedUserProfileProvider call(String userId) {
    return CachedUserProfileProvider(userId);
  }

  @override
  CachedUserProfileProvider getProviderOverride(
    covariant CachedUserProfileProvider provider,
  ) {
    return call(provider.userId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'cachedUserProfileProvider';
}

/// See also [cachedUserProfile].
class CachedUserProfileProvider
    extends AutoDisposeFutureProvider<UserProfile?> {
  /// See also [cachedUserProfile].
  CachedUserProfileProvider(String userId)
    : this._internal(
        (ref) => cachedUserProfile(ref as CachedUserProfileRef, userId),
        from: cachedUserProfileProvider,
        name: r'cachedUserProfileProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$cachedUserProfileHash,
        dependencies: CachedUserProfileFamily._dependencies,
        allTransitiveDependencies:
            CachedUserProfileFamily._allTransitiveDependencies,
        userId: userId,
      );

  CachedUserProfileProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    FutureOr<UserProfile?> Function(CachedUserProfileRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CachedUserProfileProvider._internal(
        (ref) => create(ref as CachedUserProfileRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<UserProfile?> createElement() {
    return _CachedUserProfileProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CachedUserProfileProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CachedUserProfileRef on AutoDisposeFutureProviderRef<UserProfile?> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _CachedUserProfileProviderElement
    extends AutoDisposeFutureProviderElement<UserProfile?>
    with CachedUserProfileRef {
  _CachedUserProfileProviderElement(super.provider);

  @override
  String get userId => (origin as CachedUserProfileProvider).userId;
}

String _$cachedMediaFileHash() => r'7b0f3386cfbff5681c56db2a940d622a27747433';

/// See also [cachedMediaFile].
@ProviderFor(cachedMediaFile)
const cachedMediaFileProvider = CachedMediaFileFamily();

/// See also [cachedMediaFile].
class CachedMediaFileFamily extends Family<AsyncValue<String?>> {
  /// See also [cachedMediaFile].
  const CachedMediaFileFamily();

  /// See also [cachedMediaFile].
  CachedMediaFileProvider call(String url) {
    return CachedMediaFileProvider(url);
  }

  @override
  CachedMediaFileProvider getProviderOverride(
    covariant CachedMediaFileProvider provider,
  ) {
    return call(provider.url);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'cachedMediaFileProvider';
}

/// See also [cachedMediaFile].
class CachedMediaFileProvider extends AutoDisposeFutureProvider<String?> {
  /// See also [cachedMediaFile].
  CachedMediaFileProvider(String url)
    : this._internal(
        (ref) => cachedMediaFile(ref as CachedMediaFileRef, url),
        from: cachedMediaFileProvider,
        name: r'cachedMediaFileProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$cachedMediaFileHash,
        dependencies: CachedMediaFileFamily._dependencies,
        allTransitiveDependencies:
            CachedMediaFileFamily._allTransitiveDependencies,
        url: url,
      );

  CachedMediaFileProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.url,
  }) : super.internal();

  final String url;

  @override
  Override overrideWith(
    FutureOr<String?> Function(CachedMediaFileRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CachedMediaFileProvider._internal(
        (ref) => create(ref as CachedMediaFileRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        url: url,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<String?> createElement() {
    return _CachedMediaFileProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CachedMediaFileProvider && other.url == url;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, url.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CachedMediaFileRef on AutoDisposeFutureProviderRef<String?> {
  /// The parameter `url` of this provider.
  String get url;
}

class _CachedMediaFileProviderElement
    extends AutoDisposeFutureProviderElement<String?>
    with CachedMediaFileRef {
  _CachedMediaFileProviderElement(super.provider);

  @override
  String get url => (origin as CachedMediaFileProvider).url;
}

String _$cacheStatsHash() => r'8edf5e1d2c4459f8d15f0df43d7a77a2151f9978';

/// See also [cacheStats].
@ProviderFor(cacheStats)
final cacheStatsProvider =
    AutoDisposeFutureProvider<Map<String, dynamic>>.internal(
      cacheStats,
      name: r'cacheStatsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$cacheStatsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CacheStatsRef = AutoDisposeFutureProviderRef<Map<String, dynamic>>;
String _$shouldShowOfflineIndicatorHash() =>
    r'af54fd20c0d0ebfa8f4ea6052be6d548b0ac710d';

/// See also [shouldShowOfflineIndicator].
@ProviderFor(shouldShowOfflineIndicator)
final shouldShowOfflineIndicatorProvider = AutoDisposeProvider<bool>.internal(
  shouldShowOfflineIndicator,
  name: r'shouldShowOfflineIndicatorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$shouldShowOfflineIndicatorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ShouldShowOfflineIndicatorRef = AutoDisposeProviderRef<bool>;
String _$offlineStatusMessageHash() =>
    r'5b7daafd1a8bb5b59307b0aca006402bc0232aaa';

/// See also [offlineStatusMessage].
@ProviderFor(offlineStatusMessage)
final offlineStatusMessageProvider = AutoDisposeProvider<String>.internal(
  offlineStatusMessage,
  name: r'offlineStatusMessageProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$offlineStatusMessageHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OfflineStatusMessageRef = AutoDisposeProviderRef<String>;
String _$pendingSyncItemsCountHash() =>
    r'2e4a269b4618e67a9f027de2b70ba009dd20d79b';

/// See also [pendingSyncItemsCount].
@ProviderFor(pendingSyncItemsCount)
final pendingSyncItemsCountProvider = AutoDisposeFutureProvider<int>.internal(
  pendingSyncItemsCount,
  name: r'pendingSyncItemsCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingSyncItemsCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PendingSyncItemsCountRef = AutoDisposeFutureProviderRef<int>;
String _$connectivityStatusHash() =>
    r'66b7bdbbaa23064c1bb50228f3474d65f82d376e';

/// See also [ConnectivityStatus].
@ProviderFor(ConnectivityStatus)
final connectivityStatusProvider =
    AutoDisposeNotifierProvider<ConnectivityStatus, bool>.internal(
      ConnectivityStatus.new,
      name: r'connectivityStatusProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$connectivityStatusHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ConnectivityStatus = AutoDisposeNotifier<bool>;
String _$cacheManagerHash() => r'03606c05629e9d37d56eb0aa1c64043865c68bfc';

/// See also [CacheManager].
@ProviderFor(CacheManager)
final cacheManagerProvider =
    AutoDisposeNotifierProvider<CacheManager, AsyncValue<void>>.internal(
      CacheManager.new,
      name: r'cacheManagerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$cacheManagerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CacheManager = AutoDisposeNotifier<AsyncValue<void>>;
String _$offlineSyncManagerHash() =>
    r'dc8534e56451b3d815c8cacd2ed9a01cff6faf95';

/// See also [OfflineSyncManager].
@ProviderFor(OfflineSyncManager)
final offlineSyncManagerProvider =
    AutoDisposeNotifierProvider<OfflineSyncManager, AsyncValue<void>>.internal(
      OfflineSyncManager.new,
      name: r'offlineSyncManagerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$offlineSyncManagerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$OfflineSyncManager = AutoDisposeNotifier<AsyncValue<void>>;
String _$hybridDataManagerHash() => r'2eb9f3e93f2c4d828f4fc3b9a609fe2321201edb';

/// See also [HybridDataManager].
@ProviderFor(HybridDataManager)
final hybridDataManagerProvider =
    AutoDisposeNotifierProvider<HybridDataManager, AsyncValue<void>>.internal(
      HybridDataManager.new,
      name: r'hybridDataManagerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$hybridDataManagerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$HybridDataManager = AutoDisposeNotifier<AsyncValue<void>>;
String _$cacheInitializerHash() => r'de8566aa42afe205d497d028514667f0daa22bb4';

/// See also [CacheInitializer].
@ProviderFor(CacheInitializer)
final cacheInitializerProvider =
    AutoDisposeNotifierProvider<CacheInitializer, AsyncValue<bool>>.internal(
      CacheInitializer.new,
      name: r'cacheInitializerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$cacheInitializerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CacheInitializer = AutoDisposeNotifier<AsyncValue<bool>>;
String _$dataPreloaderHash() => r'c116ec4e170b1d83e2fe81d783acd34d154a39fe';

/// See also [DataPreloader].
@ProviderFor(DataPreloader)
final dataPreloaderProvider =
    AutoDisposeNotifierProvider<DataPreloader, AsyncValue<void>>.internal(
      DataPreloader.new,
      name: r'dataPreloaderProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$dataPreloaderHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DataPreloader = AutoDisposeNotifier<AsyncValue<void>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
