// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firebase_social_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$firebaseSocialPostsServiceHash() =>
    r'0745e614408c3fe10f2df640b23592596ad8ab44';

/// See also [firebaseSocialPostsService].
@ProviderFor(firebaseSocialPostsService)
final firebaseSocialPostsServiceProvider =
    AutoDisposeProvider<FirebaseSocialPostsService>.internal(
      firebaseSocialPostsService,
      name: r'firebaseSocialPostsServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$firebaseSocialPostsServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FirebaseSocialPostsServiceRef =
    AutoDisposeProviderRef<FirebaseSocialPostsService>;
String _$firebaseCommentsServiceHash() =>
    r'bf009336021cb37e819eacde3e885c2242df8cc1';

/// See also [firebaseCommentsService].
@ProviderFor(firebaseCommentsService)
final firebaseCommentsServiceProvider =
    AutoDisposeProvider<FirebaseCommentsService>.internal(
      firebaseCommentsService,
      name: r'firebaseCommentsServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$firebaseCommentsServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FirebaseCommentsServiceRef =
    AutoDisposeProviderRef<FirebaseCommentsService>;
String _$socialPostsFeedHash() => r'db1dc0aa78041f079a451d314f95c05fd6e1c5eb';

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

/// See also [socialPostsFeed].
@ProviderFor(socialPostsFeed)
const socialPostsFeedProvider = SocialPostsFeedFamily();

/// See also [socialPostsFeed].
class SocialPostsFeedFamily extends Family<AsyncValue<List<SocialPost>>> {
  /// See also [socialPostsFeed].
  const SocialPostsFeedFamily();

  /// See also [socialPostsFeed].
  SocialPostsFeedProvider call({
    int limit = 20,
    PostVisibility? visibility,
    List<PostPillar>? pillars,
    String? userId,
  }) {
    return SocialPostsFeedProvider(
      limit: limit,
      visibility: visibility,
      pillars: pillars,
      userId: userId,
    );
  }

  @override
  SocialPostsFeedProvider getProviderOverride(
    covariant SocialPostsFeedProvider provider,
  ) {
    return call(
      limit: provider.limit,
      visibility: provider.visibility,
      pillars: provider.pillars,
      userId: provider.userId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'socialPostsFeedProvider';
}

/// See also [socialPostsFeed].
class SocialPostsFeedProvider
    extends AutoDisposeStreamProvider<List<SocialPost>> {
  /// See also [socialPostsFeed].
  SocialPostsFeedProvider({
    int limit = 20,
    PostVisibility? visibility,
    List<PostPillar>? pillars,
    String? userId,
  }) : this._internal(
         (ref) => socialPostsFeed(
           ref as SocialPostsFeedRef,
           limit: limit,
           visibility: visibility,
           pillars: pillars,
           userId: userId,
         ),
         from: socialPostsFeedProvider,
         name: r'socialPostsFeedProvider',
         debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
             ? null
             : _$socialPostsFeedHash,
         dependencies: SocialPostsFeedFamily._dependencies,
         allTransitiveDependencies:
             SocialPostsFeedFamily._allTransitiveDependencies,
         limit: limit,
         visibility: visibility,
         pillars: pillars,
         userId: userId,
       );

  SocialPostsFeedProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.limit,
    required this.visibility,
    required this.pillars,
    required this.userId,
  }) : super.internal();

  final int limit;
  final PostVisibility? visibility;
  final List<PostPillar>? pillars;
  final String? userId;

  @override
  Override overrideWith(
    Stream<List<SocialPost>> Function(SocialPostsFeedRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SocialPostsFeedProvider._internal(
        (ref) => create(ref as SocialPostsFeedRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        limit: limit,
        visibility: visibility,
        pillars: pillars,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<SocialPost>> createElement() {
    return _SocialPostsFeedProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SocialPostsFeedProvider &&
        other.limit == limit &&
        other.visibility == visibility &&
        other.pillars == pillars &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);
    hash = _SystemHash.combine(hash, visibility.hashCode);
    hash = _SystemHash.combine(hash, pillars.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SocialPostsFeedRef on AutoDisposeStreamProviderRef<List<SocialPost>> {
  /// The parameter `limit` of this provider.
  int get limit;

  /// The parameter `visibility` of this provider.
  PostVisibility? get visibility;

  /// The parameter `pillars` of this provider.
  List<PostPillar>? get pillars;

  /// The parameter `userId` of this provider.
  String? get userId;
}

class _SocialPostsFeedProviderElement
    extends AutoDisposeStreamProviderElement<List<SocialPost>>
    with SocialPostsFeedRef {
  _SocialPostsFeedProviderElement(super.provider);

  @override
  int get limit => (origin as SocialPostsFeedProvider).limit;
  @override
  PostVisibility? get visibility =>
      (origin as SocialPostsFeedProvider).visibility;
  @override
  List<PostPillar>? get pillars => (origin as SocialPostsFeedProvider).pillars;
  @override
  String? get userId => (origin as SocialPostsFeedProvider).userId;
}

String _$userPostsHash() => r'9290830a5a849c5b430fdfcbe997846165e1aef9';

/// See also [userPosts].
@ProviderFor(userPosts)
const userPostsProvider = UserPostsFamily();

/// See also [userPosts].
class UserPostsFamily extends Family<AsyncValue<List<SocialPost>>> {
  /// See also [userPosts].
  const UserPostsFamily();

  /// See also [userPosts].
  UserPostsProvider call(String userId, {int limit = 20}) {
    return UserPostsProvider(userId, limit: limit);
  }

  @override
  UserPostsProvider getProviderOverride(covariant UserPostsProvider provider) {
    return call(provider.userId, limit: provider.limit);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'userPostsProvider';
}

/// See also [userPosts].
class UserPostsProvider extends AutoDisposeStreamProvider<List<SocialPost>> {
  /// See also [userPosts].
  UserPostsProvider(String userId, {int limit = 20})
    : this._internal(
        (ref) => userPosts(ref as UserPostsRef, userId, limit: limit),
        from: userPostsProvider,
        name: r'userPostsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$userPostsHash,
        dependencies: UserPostsFamily._dependencies,
        allTransitiveDependencies: UserPostsFamily._allTransitiveDependencies,
        userId: userId,
        limit: limit,
      );

  UserPostsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
    required this.limit,
  }) : super.internal();

  final String userId;
  final int limit;

  @override
  Override overrideWith(
    Stream<List<SocialPost>> Function(UserPostsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserPostsProvider._internal(
        (ref) => create(ref as UserPostsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<SocialPost>> createElement() {
    return _UserPostsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserPostsProvider &&
        other.userId == userId &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UserPostsRef on AutoDisposeStreamProviderRef<List<SocialPost>> {
  /// The parameter `userId` of this provider.
  String get userId;

  /// The parameter `limit` of this provider.
  int get limit;
}

class _UserPostsProviderElement
    extends AutoDisposeStreamProviderElement<List<SocialPost>>
    with UserPostsRef {
  _UserPostsProviderElement(super.provider);

  @override
  String get userId => (origin as UserPostsProvider).userId;
  @override
  int get limit => (origin as UserPostsProvider).limit;
}

String _$savedPostsHash() => r'eb93e3553a111390d5a1b2d81273f1773d1b0520';

/// See also [savedPosts].
@ProviderFor(savedPosts)
const savedPostsProvider = SavedPostsFamily();

/// See also [savedPosts].
class SavedPostsFamily extends Family<AsyncValue<List<SocialPost>>> {
  /// See also [savedPosts].
  const SavedPostsFamily();

  /// See also [savedPosts].
  SavedPostsProvider call({int limit = 20}) {
    return SavedPostsProvider(limit: limit);
  }

  @override
  SavedPostsProvider getProviderOverride(
    covariant SavedPostsProvider provider,
  ) {
    return call(limit: provider.limit);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'savedPostsProvider';
}

/// See also [savedPosts].
class SavedPostsProvider extends AutoDisposeStreamProvider<List<SocialPost>> {
  /// See also [savedPosts].
  SavedPostsProvider({int limit = 20})
    : this._internal(
        (ref) => savedPosts(ref as SavedPostsRef, limit: limit),
        from: savedPostsProvider,
        name: r'savedPostsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$savedPostsHash,
        dependencies: SavedPostsFamily._dependencies,
        allTransitiveDependencies: SavedPostsFamily._allTransitiveDependencies,
        limit: limit,
      );

  SavedPostsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.limit,
  }) : super.internal();

  final int limit;

  @override
  Override overrideWith(
    Stream<List<SocialPost>> Function(SavedPostsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SavedPostsProvider._internal(
        (ref) => create(ref as SavedPostsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<SocialPost>> createElement() {
    return _SavedPostsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SavedPostsProvider && other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SavedPostsRef on AutoDisposeStreamProviderRef<List<SocialPost>> {
  /// The parameter `limit` of this provider.
  int get limit;
}

class _SavedPostsProviderElement
    extends AutoDisposeStreamProviderElement<List<SocialPost>>
    with SavedPostsRef {
  _SavedPostsProviderElement(super.provider);

  @override
  int get limit => (origin as SavedPostsProvider).limit;
}

String _$socialPostHash() => r'4e8d4846bc9ea0c0095bb63755301b1769ba0daa';

/// See also [socialPost].
@ProviderFor(socialPost)
const socialPostProvider = SocialPostFamily();

/// See also [socialPost].
class SocialPostFamily extends Family<AsyncValue<SocialPost?>> {
  /// See also [socialPost].
  const SocialPostFamily();

  /// See also [socialPost].
  SocialPostProvider call(String postId) {
    return SocialPostProvider(postId);
  }

  @override
  SocialPostProvider getProviderOverride(
    covariant SocialPostProvider provider,
  ) {
    return call(provider.postId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'socialPostProvider';
}

/// See also [socialPost].
class SocialPostProvider extends AutoDisposeFutureProvider<SocialPost?> {
  /// See also [socialPost].
  SocialPostProvider(String postId)
    : this._internal(
        (ref) => socialPost(ref as SocialPostRef, postId),
        from: socialPostProvider,
        name: r'socialPostProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$socialPostHash,
        dependencies: SocialPostFamily._dependencies,
        allTransitiveDependencies: SocialPostFamily._allTransitiveDependencies,
        postId: postId,
      );

  SocialPostProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.postId,
  }) : super.internal();

  final String postId;

  @override
  Override overrideWith(
    FutureOr<SocialPost?> Function(SocialPostRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SocialPostProvider._internal(
        (ref) => create(ref as SocialPostRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        postId: postId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<SocialPost?> createElement() {
    return _SocialPostProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SocialPostProvider && other.postId == postId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, postId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SocialPostRef on AutoDisposeFutureProviderRef<SocialPost?> {
  /// The parameter `postId` of this provider.
  String get postId;
}

class _SocialPostProviderElement
    extends AutoDisposeFutureProviderElement<SocialPost?>
    with SocialPostRef {
  _SocialPostProviderElement(super.provider);

  @override
  String get postId => (origin as SocialPostProvider).postId;
}

String _$trendingPostsHash() => r'770de8e51e772d4fed5530c241cbae6c2210cb89';

/// See also [trendingPosts].
@ProviderFor(trendingPosts)
const trendingPostsProvider = TrendingPostsFamily();

/// See also [trendingPosts].
class TrendingPostsFamily extends Family<AsyncValue<List<SocialPost>>> {
  /// See also [trendingPosts].
  const TrendingPostsFamily();

  /// See also [trendingPosts].
  TrendingPostsProvider call({int limit = 20}) {
    return TrendingPostsProvider(limit: limit);
  }

  @override
  TrendingPostsProvider getProviderOverride(
    covariant TrendingPostsProvider provider,
  ) {
    return call(limit: provider.limit);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'trendingPostsProvider';
}

/// See also [trendingPosts].
class TrendingPostsProvider
    extends AutoDisposeFutureProvider<List<SocialPost>> {
  /// See also [trendingPosts].
  TrendingPostsProvider({int limit = 20})
    : this._internal(
        (ref) => trendingPosts(ref as TrendingPostsRef, limit: limit),
        from: trendingPostsProvider,
        name: r'trendingPostsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$trendingPostsHash,
        dependencies: TrendingPostsFamily._dependencies,
        allTransitiveDependencies:
            TrendingPostsFamily._allTransitiveDependencies,
        limit: limit,
      );

  TrendingPostsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.limit,
  }) : super.internal();

  final int limit;

  @override
  Override overrideWith(
    FutureOr<List<SocialPost>> Function(TrendingPostsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TrendingPostsProvider._internal(
        (ref) => create(ref as TrendingPostsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<SocialPost>> createElement() {
    return _TrendingPostsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TrendingPostsProvider && other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TrendingPostsRef on AutoDisposeFutureProviderRef<List<SocialPost>> {
  /// The parameter `limit` of this provider.
  int get limit;
}

class _TrendingPostsProviderElement
    extends AutoDisposeFutureProviderElement<List<SocialPost>>
    with TrendingPostsRef {
  _TrendingPostsProviderElement(super.provider);

  @override
  int get limit => (origin as TrendingPostsProvider).limit;
}

String _$searchPostsHash() => r'b6de33ef570343082247be25a8b3e02c63486910';

/// See also [searchPosts].
@ProviderFor(searchPosts)
const searchPostsProvider = SearchPostsFamily();

/// See also [searchPosts].
class SearchPostsFamily extends Family<AsyncValue<List<SocialPost>>> {
  /// See also [searchPosts].
  const SearchPostsFamily();

  /// See also [searchPosts].
  SearchPostsProvider call({
    required String query,
    List<PostPillar>? pillars,
    PostVisibility? visibility,
    int limit = 20,
  }) {
    return SearchPostsProvider(
      query: query,
      pillars: pillars,
      visibility: visibility,
      limit: limit,
    );
  }

  @override
  SearchPostsProvider getProviderOverride(
    covariant SearchPostsProvider provider,
  ) {
    return call(
      query: provider.query,
      pillars: provider.pillars,
      visibility: provider.visibility,
      limit: provider.limit,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'searchPostsProvider';
}

/// See also [searchPosts].
class SearchPostsProvider extends AutoDisposeFutureProvider<List<SocialPost>> {
  /// See also [searchPosts].
  SearchPostsProvider({
    required String query,
    List<PostPillar>? pillars,
    PostVisibility? visibility,
    int limit = 20,
  }) : this._internal(
         (ref) => searchPosts(
           ref as SearchPostsRef,
           query: query,
           pillars: pillars,
           visibility: visibility,
           limit: limit,
         ),
         from: searchPostsProvider,
         name: r'searchPostsProvider',
         debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
             ? null
             : _$searchPostsHash,
         dependencies: SearchPostsFamily._dependencies,
         allTransitiveDependencies:
             SearchPostsFamily._allTransitiveDependencies,
         query: query,
         pillars: pillars,
         visibility: visibility,
         limit: limit,
       );

  SearchPostsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
    required this.pillars,
    required this.visibility,
    required this.limit,
  }) : super.internal();

  final String query;
  final List<PostPillar>? pillars;
  final PostVisibility? visibility;
  final int limit;

  @override
  Override overrideWith(
    FutureOr<List<SocialPost>> Function(SearchPostsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SearchPostsProvider._internal(
        (ref) => create(ref as SearchPostsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
        pillars: pillars,
        visibility: visibility,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<SocialPost>> createElement() {
    return _SearchPostsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SearchPostsProvider &&
        other.query == query &&
        other.pillars == pillars &&
        other.visibility == visibility &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);
    hash = _SystemHash.combine(hash, pillars.hashCode);
    hash = _SystemHash.combine(hash, visibility.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SearchPostsRef on AutoDisposeFutureProviderRef<List<SocialPost>> {
  /// The parameter `query` of this provider.
  String get query;

  /// The parameter `pillars` of this provider.
  List<PostPillar>? get pillars;

  /// The parameter `visibility` of this provider.
  PostVisibility? get visibility;

  /// The parameter `limit` of this provider.
  int get limit;
}

class _SearchPostsProviderElement
    extends AutoDisposeFutureProviderElement<List<SocialPost>>
    with SearchPostsRef {
  _SearchPostsProviderElement(super.provider);

  @override
  String get query => (origin as SearchPostsProvider).query;
  @override
  List<PostPillar>? get pillars => (origin as SearchPostsProvider).pillars;
  @override
  PostVisibility? get visibility => (origin as SearchPostsProvider).visibility;
  @override
  int get limit => (origin as SearchPostsProvider).limit;
}

String _$postCommentsHash() => r'a9402794e863b83b45c3b78c1ea97fa1d2f68dab';

/// See also [postComments].
@ProviderFor(postComments)
const postCommentsProvider = PostCommentsFamily();

/// See also [postComments].
class PostCommentsFamily extends Family<AsyncValue<List<PostComment>>> {
  /// See also [postComments].
  const PostCommentsFamily();

  /// See also [postComments].
  PostCommentsProvider call(String postId, {int limit = 50}) {
    return PostCommentsProvider(postId, limit: limit);
  }

  @override
  PostCommentsProvider getProviderOverride(
    covariant PostCommentsProvider provider,
  ) {
    return call(provider.postId, limit: provider.limit);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'postCommentsProvider';
}

/// See also [postComments].
class PostCommentsProvider
    extends AutoDisposeStreamProvider<List<PostComment>> {
  /// See also [postComments].
  PostCommentsProvider(String postId, {int limit = 50})
    : this._internal(
        (ref) => postComments(ref as PostCommentsRef, postId, limit: limit),
        from: postCommentsProvider,
        name: r'postCommentsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$postCommentsHash,
        dependencies: PostCommentsFamily._dependencies,
        allTransitiveDependencies:
            PostCommentsFamily._allTransitiveDependencies,
        postId: postId,
        limit: limit,
      );

  PostCommentsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.postId,
    required this.limit,
  }) : super.internal();

  final String postId;
  final int limit;

  @override
  Override overrideWith(
    Stream<List<PostComment>> Function(PostCommentsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PostCommentsProvider._internal(
        (ref) => create(ref as PostCommentsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        postId: postId,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<PostComment>> createElement() {
    return _PostCommentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PostCommentsProvider &&
        other.postId == postId &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, postId.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PostCommentsRef on AutoDisposeStreamProviderRef<List<PostComment>> {
  /// The parameter `postId` of this provider.
  String get postId;

  /// The parameter `limit` of this provider.
  int get limit;
}

class _PostCommentsProviderElement
    extends AutoDisposeStreamProviderElement<List<PostComment>>
    with PostCommentsRef {
  _PostCommentsProviderElement(super.provider);

  @override
  String get postId => (origin as PostCommentsProvider).postId;
  @override
  int get limit => (origin as PostCommentsProvider).limit;
}

String _$commentThreadsHash() => r'873fa05b8d94bac5a39c8ee0e396856b4917e153';

/// See also [commentThreads].
@ProviderFor(commentThreads)
const commentThreadsProvider = CommentThreadsFamily();

/// See also [commentThreads].
class CommentThreadsFamily extends Family<AsyncValue<List<CommentThread>>> {
  /// See also [commentThreads].
  const CommentThreadsFamily();

  /// See also [commentThreads].
  CommentThreadsProvider call(String postId, {int limit = 20}) {
    return CommentThreadsProvider(postId, limit: limit);
  }

  @override
  CommentThreadsProvider getProviderOverride(
    covariant CommentThreadsProvider provider,
  ) {
    return call(provider.postId, limit: provider.limit);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'commentThreadsProvider';
}

/// See also [commentThreads].
class CommentThreadsProvider
    extends AutoDisposeStreamProvider<List<CommentThread>> {
  /// See also [commentThreads].
  CommentThreadsProvider(String postId, {int limit = 20})
    : this._internal(
        (ref) => commentThreads(ref as CommentThreadsRef, postId, limit: limit),
        from: commentThreadsProvider,
        name: r'commentThreadsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$commentThreadsHash,
        dependencies: CommentThreadsFamily._dependencies,
        allTransitiveDependencies:
            CommentThreadsFamily._allTransitiveDependencies,
        postId: postId,
        limit: limit,
      );

  CommentThreadsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.postId,
    required this.limit,
  }) : super.internal();

  final String postId;
  final int limit;

  @override
  Override overrideWith(
    Stream<List<CommentThread>> Function(CommentThreadsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CommentThreadsProvider._internal(
        (ref) => create(ref as CommentThreadsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        postId: postId,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<CommentThread>> createElement() {
    return _CommentThreadsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CommentThreadsProvider &&
        other.postId == postId &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, postId.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CommentThreadsRef on AutoDisposeStreamProviderRef<List<CommentThread>> {
  /// The parameter `postId` of this provider.
  String get postId;

  /// The parameter `limit` of this provider.
  int get limit;
}

class _CommentThreadsProviderElement
    extends AutoDisposeStreamProviderElement<List<CommentThread>>
    with CommentThreadsRef {
  _CommentThreadsProviderElement(super.provider);

  @override
  String get postId => (origin as CommentThreadsProvider).postId;
  @override
  int get limit => (origin as CommentThreadsProvider).limit;
}

String _$commentRepliesHash() => r'5a28ef76ca96eb6a356ea1235e4d75f6521e7e78';

/// See also [commentReplies].
@ProviderFor(commentReplies)
const commentRepliesProvider = CommentRepliesFamily();

/// See also [commentReplies].
class CommentRepliesFamily extends Family<AsyncValue<List<PostComment>>> {
  /// See also [commentReplies].
  const CommentRepliesFamily();

  /// See also [commentReplies].
  CommentRepliesProvider call(String commentId, {int limit = 20}) {
    return CommentRepliesProvider(commentId, limit: limit);
  }

  @override
  CommentRepliesProvider getProviderOverride(
    covariant CommentRepliesProvider provider,
  ) {
    return call(provider.commentId, limit: provider.limit);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'commentRepliesProvider';
}

/// See also [commentReplies].
class CommentRepliesProvider
    extends AutoDisposeStreamProvider<List<PostComment>> {
  /// See also [commentReplies].
  CommentRepliesProvider(String commentId, {int limit = 20})
    : this._internal(
        (ref) =>
            commentReplies(ref as CommentRepliesRef, commentId, limit: limit),
        from: commentRepliesProvider,
        name: r'commentRepliesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$commentRepliesHash,
        dependencies: CommentRepliesFamily._dependencies,
        allTransitiveDependencies:
            CommentRepliesFamily._allTransitiveDependencies,
        commentId: commentId,
        limit: limit,
      );

  CommentRepliesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.commentId,
    required this.limit,
  }) : super.internal();

  final String commentId;
  final int limit;

  @override
  Override overrideWith(
    Stream<List<PostComment>> Function(CommentRepliesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CommentRepliesProvider._internal(
        (ref) => create(ref as CommentRepliesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        commentId: commentId,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<PostComment>> createElement() {
    return _CommentRepliesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CommentRepliesProvider &&
        other.commentId == commentId &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, commentId.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CommentRepliesRef on AutoDisposeStreamProviderRef<List<PostComment>> {
  /// The parameter `commentId` of this provider.
  String get commentId;

  /// The parameter `limit` of this provider.
  int get limit;
}

class _CommentRepliesProviderElement
    extends AutoDisposeStreamProviderElement<List<PostComment>>
    with CommentRepliesRef {
  _CommentRepliesProviderElement(super.provider);

  @override
  String get commentId => (origin as CommentRepliesProvider).commentId;
  @override
  int get limit => (origin as CommentRepliesProvider).limit;
}

String _$postCommentHash() => r'2b7275cbc20091da500b2f348765e4836702dd03';

/// See also [postComment].
@ProviderFor(postComment)
const postCommentProvider = PostCommentFamily();

/// See also [postComment].
class PostCommentFamily extends Family<AsyncValue<PostComment?>> {
  /// See also [postComment].
  const PostCommentFamily();

  /// See also [postComment].
  PostCommentProvider call(String commentId) {
    return PostCommentProvider(commentId);
  }

  @override
  PostCommentProvider getProviderOverride(
    covariant PostCommentProvider provider,
  ) {
    return call(provider.commentId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'postCommentProvider';
}

/// See also [postComment].
class PostCommentProvider extends AutoDisposeFutureProvider<PostComment?> {
  /// See also [postComment].
  PostCommentProvider(String commentId)
    : this._internal(
        (ref) => postComment(ref as PostCommentRef, commentId),
        from: postCommentProvider,
        name: r'postCommentProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$postCommentHash,
        dependencies: PostCommentFamily._dependencies,
        allTransitiveDependencies: PostCommentFamily._allTransitiveDependencies,
        commentId: commentId,
      );

  PostCommentProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.commentId,
  }) : super.internal();

  final String commentId;

  @override
  Override overrideWith(
    FutureOr<PostComment?> Function(PostCommentRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PostCommentProvider._internal(
        (ref) => create(ref as PostCommentRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        commentId: commentId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<PostComment?> createElement() {
    return _PostCommentProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PostCommentProvider && other.commentId == commentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, commentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PostCommentRef on AutoDisposeFutureProviderRef<PostComment?> {
  /// The parameter `commentId` of this provider.
  String get commentId;
}

class _PostCommentProviderElement
    extends AutoDisposeFutureProviderElement<PostComment?>
    with PostCommentRef {
  _PostCommentProviderElement(super.provider);

  @override
  String get commentId => (origin as PostCommentProvider).commentId;
}

String _$isPostSavedHash() => r'108d0c9a127072514012f8d497132dc02e648fbd';

/// Post save status provider
///
/// Copied from [isPostSaved].
@ProviderFor(isPostSaved)
const isPostSavedProvider = IsPostSavedFamily();

/// Post save status provider
///
/// Copied from [isPostSaved].
class IsPostSavedFamily extends Family<AsyncValue<bool>> {
  /// Post save status provider
  ///
  /// Copied from [isPostSaved].
  const IsPostSavedFamily();

  /// Post save status provider
  ///
  /// Copied from [isPostSaved].
  IsPostSavedProvider call(String postId) {
    return IsPostSavedProvider(postId);
  }

  @override
  IsPostSavedProvider getProviderOverride(
    covariant IsPostSavedProvider provider,
  ) {
    return call(provider.postId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'isPostSavedProvider';
}

/// Post save status provider
///
/// Copied from [isPostSaved].
class IsPostSavedProvider extends AutoDisposeFutureProvider<bool> {
  /// Post save status provider
  ///
  /// Copied from [isPostSaved].
  IsPostSavedProvider(String postId)
    : this._internal(
        (ref) => isPostSaved(ref as IsPostSavedRef, postId),
        from: isPostSavedProvider,
        name: r'isPostSavedProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$isPostSavedHash,
        dependencies: IsPostSavedFamily._dependencies,
        allTransitiveDependencies: IsPostSavedFamily._allTransitiveDependencies,
        postId: postId,
      );

  IsPostSavedProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.postId,
  }) : super.internal();

  final String postId;

  @override
  Override overrideWith(
    FutureOr<bool> Function(IsPostSavedRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsPostSavedProvider._internal(
        (ref) => create(ref as IsPostSavedRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        postId: postId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _IsPostSavedProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsPostSavedProvider && other.postId == postId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, postId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsPostSavedRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `postId` of this provider.
  String get postId;
}

class _IsPostSavedProviderElement extends AutoDisposeFutureProviderElement<bool>
    with IsPostSavedRef {
  _IsPostSavedProviderElement(super.provider);

  @override
  String get postId => (origin as IsPostSavedProvider).postId;
}

String _$currentUserPostsHash() => r'03e5ea510ea36cbd00601f250af21abfa21cd809';

/// User's own posts provider
///
/// Copied from [currentUserPosts].
@ProviderFor(currentUserPosts)
const currentUserPostsProvider = CurrentUserPostsFamily();

/// User's own posts provider
///
/// Copied from [currentUserPosts].
class CurrentUserPostsFamily extends Family<AsyncValue<List<SocialPost>>> {
  /// User's own posts provider
  ///
  /// Copied from [currentUserPosts].
  const CurrentUserPostsFamily();

  /// User's own posts provider
  ///
  /// Copied from [currentUserPosts].
  CurrentUserPostsProvider call({int limit = 20}) {
    return CurrentUserPostsProvider(limit: limit);
  }

  @override
  CurrentUserPostsProvider getProviderOverride(
    covariant CurrentUserPostsProvider provider,
  ) {
    return call(limit: provider.limit);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'currentUserPostsProvider';
}

/// User's own posts provider
///
/// Copied from [currentUserPosts].
class CurrentUserPostsProvider
    extends AutoDisposeStreamProvider<List<SocialPost>> {
  /// User's own posts provider
  ///
  /// Copied from [currentUserPosts].
  CurrentUserPostsProvider({int limit = 20})
    : this._internal(
        (ref) => currentUserPosts(ref as CurrentUserPostsRef, limit: limit),
        from: currentUserPostsProvider,
        name: r'currentUserPostsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$currentUserPostsHash,
        dependencies: CurrentUserPostsFamily._dependencies,
        allTransitiveDependencies:
            CurrentUserPostsFamily._allTransitiveDependencies,
        limit: limit,
      );

  CurrentUserPostsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.limit,
  }) : super.internal();

  final int limit;

  @override
  Override overrideWith(
    Stream<List<SocialPost>> Function(CurrentUserPostsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CurrentUserPostsProvider._internal(
        (ref) => create(ref as CurrentUserPostsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<SocialPost>> createElement() {
    return _CurrentUserPostsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentUserPostsProvider && other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CurrentUserPostsRef on AutoDisposeStreamProviderRef<List<SocialPost>> {
  /// The parameter `limit` of this provider.
  int get limit;
}

class _CurrentUserPostsProviderElement
    extends AutoDisposeStreamProviderElement<List<SocialPost>>
    with CurrentUserPostsRef {
  _CurrentUserPostsProviderElement(super.provider);

  @override
  int get limit => (origin as CurrentUserPostsProvider).limit;
}

String _$postsByPillarHash() => r'76ae52d6980e2600b42acd6db018a38f58bf46f5';

/// Post by pillar filter
///
/// Copied from [postsByPillar].
@ProviderFor(postsByPillar)
const postsByPillarProvider = PostsByPillarFamily();

/// Post by pillar filter
///
/// Copied from [postsByPillar].
class PostsByPillarFamily extends Family<AsyncValue<List<SocialPost>>> {
  /// Post by pillar filter
  ///
  /// Copied from [postsByPillar].
  const PostsByPillarFamily();

  /// Post by pillar filter
  ///
  /// Copied from [postsByPillar].
  PostsByPillarProvider call(PostPillar pillar, {int limit = 20}) {
    return PostsByPillarProvider(pillar, limit: limit);
  }

  @override
  PostsByPillarProvider getProviderOverride(
    covariant PostsByPillarProvider provider,
  ) {
    return call(provider.pillar, limit: provider.limit);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'postsByPillarProvider';
}

/// Post by pillar filter
///
/// Copied from [postsByPillar].
class PostsByPillarProvider
    extends AutoDisposeStreamProvider<List<SocialPost>> {
  /// Post by pillar filter
  ///
  /// Copied from [postsByPillar].
  PostsByPillarProvider(PostPillar pillar, {int limit = 20})
    : this._internal(
        (ref) => postsByPillar(ref as PostsByPillarRef, pillar, limit: limit),
        from: postsByPillarProvider,
        name: r'postsByPillarProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$postsByPillarHash,
        dependencies: PostsByPillarFamily._dependencies,
        allTransitiveDependencies:
            PostsByPillarFamily._allTransitiveDependencies,
        pillar: pillar,
        limit: limit,
      );

  PostsByPillarProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.pillar,
    required this.limit,
  }) : super.internal();

  final PostPillar pillar;
  final int limit;

  @override
  Override overrideWith(
    Stream<List<SocialPost>> Function(PostsByPillarRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PostsByPillarProvider._internal(
        (ref) => create(ref as PostsByPillarRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        pillar: pillar,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<SocialPost>> createElement() {
    return _PostsByPillarProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PostsByPillarProvider &&
        other.pillar == pillar &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, pillar.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PostsByPillarRef on AutoDisposeStreamProviderRef<List<SocialPost>> {
  /// The parameter `pillar` of this provider.
  PostPillar get pillar;

  /// The parameter `limit` of this provider.
  int get limit;
}

class _PostsByPillarProviderElement
    extends AutoDisposeStreamProviderElement<List<SocialPost>>
    with PostsByPillarRef {
  _PostsByPillarProviderElement(super.provider);

  @override
  PostPillar get pillar => (origin as PostsByPillarProvider).pillar;
  @override
  int get limit => (origin as PostsByPillarProvider).limit;
}

String _$publicPostsHash() => r'0dd98dc1e6d0982a778308a7a4b542c5b06e3c60';

/// Public posts only
///
/// Copied from [publicPosts].
@ProviderFor(publicPosts)
const publicPostsProvider = PublicPostsFamily();

/// Public posts only
///
/// Copied from [publicPosts].
class PublicPostsFamily extends Family<AsyncValue<List<SocialPost>>> {
  /// Public posts only
  ///
  /// Copied from [publicPosts].
  const PublicPostsFamily();

  /// Public posts only
  ///
  /// Copied from [publicPosts].
  PublicPostsProvider call({int limit = 20}) {
    return PublicPostsProvider(limit: limit);
  }

  @override
  PublicPostsProvider getProviderOverride(
    covariant PublicPostsProvider provider,
  ) {
    return call(limit: provider.limit);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'publicPostsProvider';
}

/// Public posts only
///
/// Copied from [publicPosts].
class PublicPostsProvider extends AutoDisposeStreamProvider<List<SocialPost>> {
  /// Public posts only
  ///
  /// Copied from [publicPosts].
  PublicPostsProvider({int limit = 20})
    : this._internal(
        (ref) => publicPosts(ref as PublicPostsRef, limit: limit),
        from: publicPostsProvider,
        name: r'publicPostsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$publicPostsHash,
        dependencies: PublicPostsFamily._dependencies,
        allTransitiveDependencies: PublicPostsFamily._allTransitiveDependencies,
        limit: limit,
      );

  PublicPostsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.limit,
  }) : super.internal();

  final int limit;

  @override
  Override overrideWith(
    Stream<List<SocialPost>> Function(PublicPostsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PublicPostsProvider._internal(
        (ref) => create(ref as PublicPostsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<SocialPost>> createElement() {
    return _PublicPostsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PublicPostsProvider && other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PublicPostsRef on AutoDisposeStreamProviderRef<List<SocialPost>> {
  /// The parameter `limit` of this provider.
  int get limit;
}

class _PublicPostsProviderElement
    extends AutoDisposeStreamProviderElement<List<SocialPost>>
    with PublicPostsRef {
  _PublicPostsProviderElement(super.provider);

  @override
  int get limit => (origin as PublicPostsProvider).limit;
}

String _$postCommentCountHash() => r'75de6b8ddb68fef4ca072ec28089787889bc5ca1';

/// Convenience provider for comment count
///
/// Copied from [postCommentCount].
@ProviderFor(postCommentCount)
const postCommentCountProvider = PostCommentCountFamily();

/// Convenience provider for comment count
///
/// Copied from [postCommentCount].
class PostCommentCountFamily extends Family<AsyncValue<int>> {
  /// Convenience provider for comment count
  ///
  /// Copied from [postCommentCount].
  const PostCommentCountFamily();

  /// Convenience provider for comment count
  ///
  /// Copied from [postCommentCount].
  PostCommentCountProvider call(String postId) {
    return PostCommentCountProvider(postId);
  }

  @override
  PostCommentCountProvider getProviderOverride(
    covariant PostCommentCountProvider provider,
  ) {
    return call(provider.postId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'postCommentCountProvider';
}

/// Convenience provider for comment count
///
/// Copied from [postCommentCount].
class PostCommentCountProvider extends AutoDisposeFutureProvider<int> {
  /// Convenience provider for comment count
  ///
  /// Copied from [postCommentCount].
  PostCommentCountProvider(String postId)
    : this._internal(
        (ref) => postCommentCount(ref as PostCommentCountRef, postId),
        from: postCommentCountProvider,
        name: r'postCommentCountProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$postCommentCountHash,
        dependencies: PostCommentCountFamily._dependencies,
        allTransitiveDependencies:
            PostCommentCountFamily._allTransitiveDependencies,
        postId: postId,
      );

  PostCommentCountProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.postId,
  }) : super.internal();

  final String postId;

  @override
  Override overrideWith(
    FutureOr<int> Function(PostCommentCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PostCommentCountProvider._internal(
        (ref) => create(ref as PostCommentCountRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        postId: postId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<int> createElement() {
    return _PostCommentCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PostCommentCountProvider && other.postId == postId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, postId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PostCommentCountRef on AutoDisposeFutureProviderRef<int> {
  /// The parameter `postId` of this provider.
  String get postId;
}

class _PostCommentCountProviderElement
    extends AutoDisposeFutureProviderElement<int>
    with PostCommentCountRef {
  _PostCommentCountProviderElement(super.provider);

  @override
  String get postId => (origin as PostCommentCountProvider).postId;
}

String _$postReactionCountHash() => r'77b710d7ce57516863d7a409a83df45e61a8003b';

/// Convenience provider for reaction count
///
/// Copied from [postReactionCount].
@ProviderFor(postReactionCount)
const postReactionCountProvider = PostReactionCountFamily();

/// Convenience provider for reaction count
///
/// Copied from [postReactionCount].
class PostReactionCountFamily extends Family<AsyncValue<int>> {
  /// Convenience provider for reaction count
  ///
  /// Copied from [postReactionCount].
  const PostReactionCountFamily();

  /// Convenience provider for reaction count
  ///
  /// Copied from [postReactionCount].
  PostReactionCountProvider call(String postId) {
    return PostReactionCountProvider(postId);
  }

  @override
  PostReactionCountProvider getProviderOverride(
    covariant PostReactionCountProvider provider,
  ) {
    return call(provider.postId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'postReactionCountProvider';
}

/// Convenience provider for reaction count
///
/// Copied from [postReactionCount].
class PostReactionCountProvider extends AutoDisposeFutureProvider<int> {
  /// Convenience provider for reaction count
  ///
  /// Copied from [postReactionCount].
  PostReactionCountProvider(String postId)
    : this._internal(
        (ref) => postReactionCount(ref as PostReactionCountRef, postId),
        from: postReactionCountProvider,
        name: r'postReactionCountProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$postReactionCountHash,
        dependencies: PostReactionCountFamily._dependencies,
        allTransitiveDependencies:
            PostReactionCountFamily._allTransitiveDependencies,
        postId: postId,
      );

  PostReactionCountProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.postId,
  }) : super.internal();

  final String postId;

  @override
  Override overrideWith(
    FutureOr<int> Function(PostReactionCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PostReactionCountProvider._internal(
        (ref) => create(ref as PostReactionCountRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        postId: postId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<int> createElement() {
    return _PostReactionCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PostReactionCountProvider && other.postId == postId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, postId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PostReactionCountRef on AutoDisposeFutureProviderRef<int> {
  /// The parameter `postId` of this provider.
  String get postId;
}

class _PostReactionCountProviderElement
    extends AutoDisposeFutureProviderElement<int>
    with PostReactionCountRef {
  _PostReactionCountProviderElement(super.provider);

  @override
  String get postId => (origin as PostReactionCountProvider).postId;
}

String _$userPostReactionHash() => r'caa1850e1b3559c14f6e13977c9cef740105ce59';

/// User reaction on post provider
///
/// Copied from [userPostReaction].
@ProviderFor(userPostReaction)
const userPostReactionProvider = UserPostReactionFamily();

/// User reaction on post provider
///
/// Copied from [userPostReaction].
class UserPostReactionFamily extends Family<AsyncValue<ReactionType?>> {
  /// User reaction on post provider
  ///
  /// Copied from [userPostReaction].
  const UserPostReactionFamily();

  /// User reaction on post provider
  ///
  /// Copied from [userPostReaction].
  UserPostReactionProvider call(String postId) {
    return UserPostReactionProvider(postId);
  }

  @override
  UserPostReactionProvider getProviderOverride(
    covariant UserPostReactionProvider provider,
  ) {
    return call(provider.postId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'userPostReactionProvider';
}

/// User reaction on post provider
///
/// Copied from [userPostReaction].
class UserPostReactionProvider
    extends AutoDisposeFutureProvider<ReactionType?> {
  /// User reaction on post provider
  ///
  /// Copied from [userPostReaction].
  UserPostReactionProvider(String postId)
    : this._internal(
        (ref) => userPostReaction(ref as UserPostReactionRef, postId),
        from: userPostReactionProvider,
        name: r'userPostReactionProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$userPostReactionHash,
        dependencies: UserPostReactionFamily._dependencies,
        allTransitiveDependencies:
            UserPostReactionFamily._allTransitiveDependencies,
        postId: postId,
      );

  UserPostReactionProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.postId,
  }) : super.internal();

  final String postId;

  @override
  Override overrideWith(
    FutureOr<ReactionType?> Function(UserPostReactionRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserPostReactionProvider._internal(
        (ref) => create(ref as UserPostReactionRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        postId: postId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ReactionType?> createElement() {
    return _UserPostReactionProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserPostReactionProvider && other.postId == postId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, postId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UserPostReactionRef on AutoDisposeFutureProviderRef<ReactionType?> {
  /// The parameter `postId` of this provider.
  String get postId;
}

class _UserPostReactionProviderElement
    extends AutoDisposeFutureProviderElement<ReactionType?>
    with UserPostReactionRef {
  _UserPostReactionProviderElement(super.provider);

  @override
  String get postId => (origin as UserPostReactionProvider).postId;
}

String _$userCommentReactionHash() =>
    r'54ab7ad5418d1fc1dd2265cb12982a93f3eaeb3d';

/// User reaction on comment provider
///
/// Copied from [userCommentReaction].
@ProviderFor(userCommentReaction)
const userCommentReactionProvider = UserCommentReactionFamily();

/// User reaction on comment provider
///
/// Copied from [userCommentReaction].
class UserCommentReactionFamily extends Family<AsyncValue<ReactionType?>> {
  /// User reaction on comment provider
  ///
  /// Copied from [userCommentReaction].
  const UserCommentReactionFamily();

  /// User reaction on comment provider
  ///
  /// Copied from [userCommentReaction].
  UserCommentReactionProvider call(String commentId) {
    return UserCommentReactionProvider(commentId);
  }

  @override
  UserCommentReactionProvider getProviderOverride(
    covariant UserCommentReactionProvider provider,
  ) {
    return call(provider.commentId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'userCommentReactionProvider';
}

/// User reaction on comment provider
///
/// Copied from [userCommentReaction].
class UserCommentReactionProvider
    extends AutoDisposeFutureProvider<ReactionType?> {
  /// User reaction on comment provider
  ///
  /// Copied from [userCommentReaction].
  UserCommentReactionProvider(String commentId)
    : this._internal(
        (ref) => userCommentReaction(ref as UserCommentReactionRef, commentId),
        from: userCommentReactionProvider,
        name: r'userCommentReactionProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$userCommentReactionHash,
        dependencies: UserCommentReactionFamily._dependencies,
        allTransitiveDependencies:
            UserCommentReactionFamily._allTransitiveDependencies,
        commentId: commentId,
      );

  UserCommentReactionProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.commentId,
  }) : super.internal();

  final String commentId;

  @override
  Override overrideWith(
    FutureOr<ReactionType?> Function(UserCommentReactionRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserCommentReactionProvider._internal(
        (ref) => create(ref as UserCommentReactionRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        commentId: commentId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ReactionType?> createElement() {
    return _UserCommentReactionProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserCommentReactionProvider && other.commentId == commentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, commentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UserCommentReactionRef on AutoDisposeFutureProviderRef<ReactionType?> {
  /// The parameter `commentId` of this provider.
  String get commentId;
}

class _UserCommentReactionProviderElement
    extends AutoDisposeFutureProviderElement<ReactionType?>
    with UserCommentReactionRef {
  _UserCommentReactionProviderElement(super.provider);

  @override
  String get commentId => (origin as UserCommentReactionProvider).commentId;
}

String _$socialPostActionsHash() => r'34d7c25b86afcc1288783b1ea3e56ee6a08a07f0';

/// Social Post Actions State Notifier
///
/// Copied from [SocialPostActions].
@ProviderFor(SocialPostActions)
final socialPostActionsProvider =
    AutoDisposeNotifierProvider<SocialPostActions, AsyncValue<void>>.internal(
      SocialPostActions.new,
      name: r'socialPostActionsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$socialPostActionsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SocialPostActions = AutoDisposeNotifier<AsyncValue<void>>;
String _$commentActionsHash() => r'764c5871cd01178671aaf8b0ce0284a2636a6a95';

/// Comment Actions State Notifier
///
/// Copied from [CommentActions].
@ProviderFor(CommentActions)
final commentActionsProvider =
    AutoDisposeNotifierProvider<CommentActions, AsyncValue<void>>.internal(
      CommentActions.new,
      name: r'commentActionsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$commentActionsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CommentActions = AutoDisposeNotifier<AsyncValue<void>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
