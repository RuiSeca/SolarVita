// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firebase_user_profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$firebaseUserProfileServiceHash() =>
    r'c61fbe0f79827ce4a4117909148f6bd8562e3fb1';

/// See also [firebaseUserProfileService].
@ProviderFor(firebaseUserProfileService)
final firebaseUserProfileServiceProvider =
    AutoDisposeProvider<FirebaseUserProfileService>.internal(
      firebaseUserProfileService,
      name: r'firebaseUserProfileServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$firebaseUserProfileServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FirebaseUserProfileServiceRef =
    AutoDisposeProviderRef<FirebaseUserProfileService>;
String _$currentUserProfileHash() =>
    r'f4fe9f4e29195ab7992f121ac133be865c3180aa';

/// See also [currentUserProfile].
@ProviderFor(currentUserProfile)
final currentUserProfileProvider =
    AutoDisposeFutureProvider<UserProfile?>.internal(
      currentUserProfile,
      name: r'currentUserProfileProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$currentUserProfileHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserProfileRef = AutoDisposeFutureProviderRef<UserProfile?>;
String _$userProfileHash() => r'8376fb9a49dfedce58cb68897e61e6dc53d53fcb';

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

/// See also [userProfile].
@ProviderFor(userProfile)
const userProfileProvider = UserProfileFamily();

/// See also [userProfile].
class UserProfileFamily extends Family<AsyncValue<UserProfile?>> {
  /// See also [userProfile].
  const UserProfileFamily();

  /// See also [userProfile].
  UserProfileProvider call(String userId) {
    return UserProfileProvider(userId);
  }

  @override
  UserProfileProvider getProviderOverride(
    covariant UserProfileProvider provider,
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
  String? get name => r'userProfileProvider';
}

/// See also [userProfile].
class UserProfileProvider extends AutoDisposeFutureProvider<UserProfile?> {
  /// See also [userProfile].
  UserProfileProvider(String userId)
    : this._internal(
        (ref) => userProfile(ref as UserProfileRef, userId),
        from: userProfileProvider,
        name: r'userProfileProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$userProfileHash,
        dependencies: UserProfileFamily._dependencies,
        allTransitiveDependencies: UserProfileFamily._allTransitiveDependencies,
        userId: userId,
      );

  UserProfileProvider._internal(
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
    FutureOr<UserProfile?> Function(UserProfileRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserProfileProvider._internal(
        (ref) => create(ref as UserProfileRef),
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
    return _UserProfileProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserProfileProvider && other.userId == userId;
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
mixin UserProfileRef on AutoDisposeFutureProviderRef<UserProfile?> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserProfileProviderElement
    extends AutoDisposeFutureProviderElement<UserProfile?>
    with UserProfileRef {
  _UserProfileProviderElement(super.provider);

  @override
  String get userId => (origin as UserProfileProvider).userId;
}

String _$userSocialStatsHash() => r'5b570a5b42deb09fb74d766416624fc8f704490b';

/// See also [userSocialStats].
@ProviderFor(userSocialStats)
const userSocialStatsProvider = UserSocialStatsFamily();

/// See also [userSocialStats].
class UserSocialStatsFamily extends Family<AsyncValue<Map<String, int>>> {
  /// See also [userSocialStats].
  const UserSocialStatsFamily();

  /// See also [userSocialStats].
  UserSocialStatsProvider call(String userId) {
    return UserSocialStatsProvider(userId);
  }

  @override
  UserSocialStatsProvider getProviderOverride(
    covariant UserSocialStatsProvider provider,
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
  String? get name => r'userSocialStatsProvider';
}

/// See also [userSocialStats].
class UserSocialStatsProvider
    extends AutoDisposeFutureProvider<Map<String, int>> {
  /// See also [userSocialStats].
  UserSocialStatsProvider(String userId)
    : this._internal(
        (ref) => userSocialStats(ref as UserSocialStatsRef, userId),
        from: userSocialStatsProvider,
        name: r'userSocialStatsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$userSocialStatsHash,
        dependencies: UserSocialStatsFamily._dependencies,
        allTransitiveDependencies:
            UserSocialStatsFamily._allTransitiveDependencies,
        userId: userId,
      );

  UserSocialStatsProvider._internal(
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
    FutureOr<Map<String, int>> Function(UserSocialStatsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserSocialStatsProvider._internal(
        (ref) => create(ref as UserSocialStatsRef),
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
  AutoDisposeFutureProviderElement<Map<String, int>> createElement() {
    return _UserSocialStatsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserSocialStatsProvider && other.userId == userId;
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
mixin UserSocialStatsRef on AutoDisposeFutureProviderRef<Map<String, int>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserSocialStatsProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, int>>
    with UserSocialStatsRef {
  _UserSocialStatsProviderElement(super.provider);

  @override
  String get userId => (origin as UserSocialStatsProvider).userId;
}

String _$isFollowingUserHash() => r'd89510b462429ff93a04d05b2ca2adbaafd57330';

/// See also [isFollowingUser].
@ProviderFor(isFollowingUser)
const isFollowingUserProvider = IsFollowingUserFamily();

/// See also [isFollowingUser].
class IsFollowingUserFamily extends Family<AsyncValue<bool>> {
  /// See also [isFollowingUser].
  const IsFollowingUserFamily();

  /// See also [isFollowingUser].
  IsFollowingUserProvider call(String targetUserId) {
    return IsFollowingUserProvider(targetUserId);
  }

  @override
  IsFollowingUserProvider getProviderOverride(
    covariant IsFollowingUserProvider provider,
  ) {
    return call(provider.targetUserId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'isFollowingUserProvider';
}

/// See also [isFollowingUser].
class IsFollowingUserProvider extends AutoDisposeFutureProvider<bool> {
  /// See also [isFollowingUser].
  IsFollowingUserProvider(String targetUserId)
    : this._internal(
        (ref) => isFollowingUser(ref as IsFollowingUserRef, targetUserId),
        from: isFollowingUserProvider,
        name: r'isFollowingUserProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$isFollowingUserHash,
        dependencies: IsFollowingUserFamily._dependencies,
        allTransitiveDependencies:
            IsFollowingUserFamily._allTransitiveDependencies,
        targetUserId: targetUserId,
      );

  IsFollowingUserProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.targetUserId,
  }) : super.internal();

  final String targetUserId;

  @override
  Override overrideWith(
    FutureOr<bool> Function(IsFollowingUserRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsFollowingUserProvider._internal(
        (ref) => create(ref as IsFollowingUserRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        targetUserId: targetUserId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _IsFollowingUserProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsFollowingUserProvider &&
        other.targetUserId == targetUserId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, targetUserId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsFollowingUserRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `targetUserId` of this provider.
  String get targetUserId;
}

class _IsFollowingUserProviderElement
    extends AutoDisposeFutureProviderElement<bool>
    with IsFollowingUserRef {
  _IsFollowingUserProviderElement(super.provider);

  @override
  String get targetUserId => (origin as IsFollowingUserProvider).targetUserId;
}

String _$recommendedUsersHash() => r'485a1c2d30103a8037bc3782371abded88916959';

/// See also [recommendedUsers].
@ProviderFor(recommendedUsers)
const recommendedUsersProvider = RecommendedUsersFamily();

/// See also [recommendedUsers].
class RecommendedUsersFamily extends Family<AsyncValue<List<UserProfile>>> {
  /// See also [recommendedUsers].
  const RecommendedUsersFamily();

  /// See also [recommendedUsers].
  RecommendedUsersProvider call({int limit = 10}) {
    return RecommendedUsersProvider(limit: limit);
  }

  @override
  RecommendedUsersProvider getProviderOverride(
    covariant RecommendedUsersProvider provider,
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
  String? get name => r'recommendedUsersProvider';
}

/// See also [recommendedUsers].
class RecommendedUsersProvider
    extends AutoDisposeFutureProvider<List<UserProfile>> {
  /// See also [recommendedUsers].
  RecommendedUsersProvider({int limit = 10})
    : this._internal(
        (ref) => recommendedUsers(ref as RecommendedUsersRef, limit: limit),
        from: recommendedUsersProvider,
        name: r'recommendedUsersProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$recommendedUsersHash,
        dependencies: RecommendedUsersFamily._dependencies,
        allTransitiveDependencies:
            RecommendedUsersFamily._allTransitiveDependencies,
        limit: limit,
      );

  RecommendedUsersProvider._internal(
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
    FutureOr<List<UserProfile>> Function(RecommendedUsersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RecommendedUsersProvider._internal(
        (ref) => create(ref as RecommendedUsersRef),
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
  AutoDisposeFutureProviderElement<List<UserProfile>> createElement() {
    return _RecommendedUsersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RecommendedUsersProvider && other.limit == limit;
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
mixin RecommendedUsersRef on AutoDisposeFutureProviderRef<List<UserProfile>> {
  /// The parameter `limit` of this provider.
  int get limit;
}

class _RecommendedUsersProviderElement
    extends AutoDisposeFutureProviderElement<List<UserProfile>>
    with RecommendedUsersRef {
  _RecommendedUsersProviderElement(super.provider);

  @override
  int get limit => (origin as RecommendedUsersProvider).limit;
}

String _$searchUsersHash() => r'ea3aacd99bd74dfeb6596cadf98049c9e56de2e9';

/// See also [searchUsers].
@ProviderFor(searchUsers)
const searchUsersProvider = SearchUsersFamily();

/// See also [searchUsers].
class SearchUsersFamily extends Family<AsyncValue<List<UserProfile>>> {
  /// See also [searchUsers].
  const SearchUsersFamily();

  /// See also [searchUsers].
  SearchUsersProvider call(String query, {int limit = 20}) {
    return SearchUsersProvider(query, limit: limit);
  }

  @override
  SearchUsersProvider getProviderOverride(
    covariant SearchUsersProvider provider,
  ) {
    return call(provider.query, limit: provider.limit);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'searchUsersProvider';
}

/// See also [searchUsers].
class SearchUsersProvider extends AutoDisposeFutureProvider<List<UserProfile>> {
  /// See also [searchUsers].
  SearchUsersProvider(String query, {int limit = 20})
    : this._internal(
        (ref) => searchUsers(ref as SearchUsersRef, query, limit: limit),
        from: searchUsersProvider,
        name: r'searchUsersProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$searchUsersHash,
        dependencies: SearchUsersFamily._dependencies,
        allTransitiveDependencies: SearchUsersFamily._allTransitiveDependencies,
        query: query,
        limit: limit,
      );

  SearchUsersProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
    required this.limit,
  }) : super.internal();

  final String query;
  final int limit;

  @override
  Override overrideWith(
    FutureOr<List<UserProfile>> Function(SearchUsersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SearchUsersProvider._internal(
        (ref) => create(ref as SearchUsersRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<UserProfile>> createElement() {
    return _SearchUsersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SearchUsersProvider &&
        other.query == query &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SearchUsersRef on AutoDisposeFutureProviderRef<List<UserProfile>> {
  /// The parameter `query` of this provider.
  String get query;

  /// The parameter `limit` of this provider.
  int get limit;
}

class _SearchUsersProviderElement
    extends AutoDisposeFutureProviderElement<List<UserProfile>>
    with SearchUsersRef {
  _SearchUsersProviderElement(super.provider);

  @override
  String get query => (origin as SearchUsersProvider).query;
  @override
  int get limit => (origin as SearchUsersProvider).limit;
}

String _$userFollowersHash() => r'88c8e51e0a06ebb6f679f5fdf92ea5a3c527420e';

/// See also [userFollowers].
@ProviderFor(userFollowers)
const userFollowersProvider = UserFollowersFamily();

/// See also [userFollowers].
class UserFollowersFamily extends Family<AsyncValue<List<UserProfile>>> {
  /// See also [userFollowers].
  const UserFollowersFamily();

  /// See also [userFollowers].
  UserFollowersProvider call(String userId) {
    return UserFollowersProvider(userId);
  }

  @override
  UserFollowersProvider getProviderOverride(
    covariant UserFollowersProvider provider,
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
  String? get name => r'userFollowersProvider';
}

/// See also [userFollowers].
class UserFollowersProvider
    extends AutoDisposeStreamProvider<List<UserProfile>> {
  /// See also [userFollowers].
  UserFollowersProvider(String userId)
    : this._internal(
        (ref) => userFollowers(ref as UserFollowersRef, userId),
        from: userFollowersProvider,
        name: r'userFollowersProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$userFollowersHash,
        dependencies: UserFollowersFamily._dependencies,
        allTransitiveDependencies:
            UserFollowersFamily._allTransitiveDependencies,
        userId: userId,
      );

  UserFollowersProvider._internal(
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
    Stream<List<UserProfile>> Function(UserFollowersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserFollowersProvider._internal(
        (ref) => create(ref as UserFollowersRef),
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
  AutoDisposeStreamProviderElement<List<UserProfile>> createElement() {
    return _UserFollowersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserFollowersProvider && other.userId == userId;
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
mixin UserFollowersRef on AutoDisposeStreamProviderRef<List<UserProfile>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserFollowersProviderElement
    extends AutoDisposeStreamProviderElement<List<UserProfile>>
    with UserFollowersRef {
  _UserFollowersProviderElement(super.provider);

  @override
  String get userId => (origin as UserFollowersProvider).userId;
}

String _$userFollowingHash() => r'd0628ed49e1d574790141911ea2aff92ba05db8b';

/// See also [userFollowing].
@ProviderFor(userFollowing)
const userFollowingProvider = UserFollowingFamily();

/// See also [userFollowing].
class UserFollowingFamily extends Family<AsyncValue<List<UserProfile>>> {
  /// See also [userFollowing].
  const UserFollowingFamily();

  /// See also [userFollowing].
  UserFollowingProvider call(String userId) {
    return UserFollowingProvider(userId);
  }

  @override
  UserFollowingProvider getProviderOverride(
    covariant UserFollowingProvider provider,
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
  String? get name => r'userFollowingProvider';
}

/// See also [userFollowing].
class UserFollowingProvider
    extends AutoDisposeStreamProvider<List<UserProfile>> {
  /// See also [userFollowing].
  UserFollowingProvider(String userId)
    : this._internal(
        (ref) => userFollowing(ref as UserFollowingRef, userId),
        from: userFollowingProvider,
        name: r'userFollowingProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$userFollowingHash,
        dependencies: UserFollowingFamily._dependencies,
        allTransitiveDependencies:
            UserFollowingFamily._allTransitiveDependencies,
        userId: userId,
      );

  UserFollowingProvider._internal(
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
    Stream<List<UserProfile>> Function(UserFollowingRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserFollowingProvider._internal(
        (ref) => create(ref as UserFollowingRef),
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
  AutoDisposeStreamProviderElement<List<UserProfile>> createElement() {
    return _UserFollowingProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserFollowingProvider && other.userId == userId;
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
mixin UserFollowingRef on AutoDisposeStreamProviderRef<List<UserProfile>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserFollowingProviderElement
    extends AutoDisposeStreamProviderElement<List<UserProfile>>
    with UserFollowingRef {
  _UserFollowingProviderElement(super.provider);

  @override
  String get userId => (origin as UserFollowingProvider).userId;
}

String _$userPostsHash() => r'c86e4c0bd112b106e9ae089af3164dc292a13979';

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

String _$currentUserPostsHash() => r'5b32842d5f02c75d3ae575692bfb230bb49631f3';

/// See also [currentUserPosts].
@ProviderFor(currentUserPosts)
const currentUserPostsProvider = CurrentUserPostsFamily();

/// See also [currentUserPosts].
class CurrentUserPostsFamily extends Family<AsyncValue<List<SocialPost>>> {
  /// See also [currentUserPosts].
  const CurrentUserPostsFamily();

  /// See also [currentUserPosts].
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

/// See also [currentUserPosts].
class CurrentUserPostsProvider
    extends AutoDisposeStreamProvider<List<SocialPost>> {
  /// See also [currentUserPosts].
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

String _$savedPostsHash() => r'311fd81053f4bfed7aa1eeab50612a68b5e75e99';

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

String _$currentUserSocialStatsHash() =>
    r'49e729e89052eeb0f9fb5e0304ed55a3480bc2c7';

/// Current user social stats
///
/// Copied from [currentUserSocialStats].
@ProviderFor(currentUserSocialStats)
final currentUserSocialStatsProvider =
    AutoDisposeFutureProvider<Map<String, int>>.internal(
      currentUserSocialStats,
      name: r'currentUserSocialStatsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$currentUserSocialStatsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserSocialStatsRef =
    AutoDisposeFutureProviderRef<Map<String, int>>;
String _$isUsernameAvailableHash() =>
    r'f8ec3b227445c0786ed7bde1c0651e7ce9d839b7';

/// Check if username is available
///
/// Copied from [isUsernameAvailable].
@ProviderFor(isUsernameAvailable)
const isUsernameAvailableProvider = IsUsernameAvailableFamily();

/// Check if username is available
///
/// Copied from [isUsernameAvailable].
class IsUsernameAvailableFamily extends Family<AsyncValue<bool>> {
  /// Check if username is available
  ///
  /// Copied from [isUsernameAvailable].
  const IsUsernameAvailableFamily();

  /// Check if username is available
  ///
  /// Copied from [isUsernameAvailable].
  IsUsernameAvailableProvider call(String username) {
    return IsUsernameAvailableProvider(username);
  }

  @override
  IsUsernameAvailableProvider getProviderOverride(
    covariant IsUsernameAvailableProvider provider,
  ) {
    return call(provider.username);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'isUsernameAvailableProvider';
}

/// Check if username is available
///
/// Copied from [isUsernameAvailable].
class IsUsernameAvailableProvider extends AutoDisposeFutureProvider<bool> {
  /// Check if username is available
  ///
  /// Copied from [isUsernameAvailable].
  IsUsernameAvailableProvider(String username)
    : this._internal(
        (ref) => isUsernameAvailable(ref as IsUsernameAvailableRef, username),
        from: isUsernameAvailableProvider,
        name: r'isUsernameAvailableProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$isUsernameAvailableHash,
        dependencies: IsUsernameAvailableFamily._dependencies,
        allTransitiveDependencies:
            IsUsernameAvailableFamily._allTransitiveDependencies,
        username: username,
      );

  IsUsernameAvailableProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.username,
  }) : super.internal();

  final String username;

  @override
  Override overrideWith(
    FutureOr<bool> Function(IsUsernameAvailableRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsUsernameAvailableProvider._internal(
        (ref) => create(ref as IsUsernameAvailableRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        username: username,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _IsUsernameAvailableProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsUsernameAvailableProvider && other.username == username;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, username.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsUsernameAvailableRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `username` of this provider.
  String get username;
}

class _IsUsernameAvailableProviderElement
    extends AutoDisposeFutureProviderElement<bool>
    with IsUsernameAvailableRef {
  _IsUsernameAvailableProviderElement(super.provider);

  @override
  String get username => (origin as IsUsernameAvailableProvider).username;
}

String _$userDisplayInfoHash() => r'b3649120dd8c1689b06f10aaec6c1aaa2faa4e73';

/// Get user display info (for mentions, etc.)
///
/// Copied from [userDisplayInfo].
@ProviderFor(userDisplayInfo)
const userDisplayInfoProvider = UserDisplayInfoFamily();

/// Get user display info (for mentions, etc.)
///
/// Copied from [userDisplayInfo].
class UserDisplayInfoFamily extends Family<AsyncValue<Map<String, String>>> {
  /// Get user display info (for mentions, etc.)
  ///
  /// Copied from [userDisplayInfo].
  const UserDisplayInfoFamily();

  /// Get user display info (for mentions, etc.)
  ///
  /// Copied from [userDisplayInfo].
  UserDisplayInfoProvider call(String userId) {
    return UserDisplayInfoProvider(userId);
  }

  @override
  UserDisplayInfoProvider getProviderOverride(
    covariant UserDisplayInfoProvider provider,
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
  String? get name => r'userDisplayInfoProvider';
}

/// Get user display info (for mentions, etc.)
///
/// Copied from [userDisplayInfo].
class UserDisplayInfoProvider
    extends AutoDisposeFutureProvider<Map<String, String>> {
  /// Get user display info (for mentions, etc.)
  ///
  /// Copied from [userDisplayInfo].
  UserDisplayInfoProvider(String userId)
    : this._internal(
        (ref) => userDisplayInfo(ref as UserDisplayInfoRef, userId),
        from: userDisplayInfoProvider,
        name: r'userDisplayInfoProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$userDisplayInfoHash,
        dependencies: UserDisplayInfoFamily._dependencies,
        allTransitiveDependencies:
            UserDisplayInfoFamily._allTransitiveDependencies,
        userId: userId,
      );

  UserDisplayInfoProvider._internal(
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
    FutureOr<Map<String, String>> Function(UserDisplayInfoRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserDisplayInfoProvider._internal(
        (ref) => create(ref as UserDisplayInfoRef),
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
  AutoDisposeFutureProviderElement<Map<String, String>> createElement() {
    return _UserDisplayInfoProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserDisplayInfoProvider && other.userId == userId;
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
mixin UserDisplayInfoRef on AutoDisposeFutureProviderRef<Map<String, String>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserDisplayInfoProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, String>>
    with UserDisplayInfoRef {
  _UserDisplayInfoProviderElement(super.provider);

  @override
  String get userId => (origin as UserDisplayInfoProvider).userId;
}

String _$profileCompletionStatusHash() =>
    r'a298b25f375f77a74f215538ce934912d8c5ba38';

/// Profile completion status
///
/// Copied from [profileCompletionStatus].
@ProviderFor(profileCompletionStatus)
final profileCompletionStatusProvider =
    AutoDisposeFutureProvider<ProfileCompletionStatus>.internal(
      profileCompletionStatus,
      name: r'profileCompletionStatusProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$profileCompletionStatusHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProfileCompletionStatusRef =
    AutoDisposeFutureProviderRef<ProfileCompletionStatus>;
String _$userProfileActionsHash() =>
    r'3723c6e8f5be5714ec1b9a9ced2463c06250ec87';

/// User Profile Actions State Notifier
///
/// Copied from [UserProfileActions].
@ProviderFor(UserProfileActions)
final userProfileActionsProvider =
    AutoDisposeNotifierProvider<UserProfileActions, AsyncValue<void>>.internal(
      UserProfileActions.new,
      name: r'userProfileActionsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$userProfileActionsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$UserProfileActions = AutoDisposeNotifier<AsyncValue<void>>;
String _$activityTrackerHash() => r'c45b0e746a856e31c04c9d7f7bb1aa61c17a476d';

/// Auto-refresh user activity
///
/// Copied from [ActivityTracker].
@ProviderFor(ActivityTracker)
final activityTrackerProvider =
    AutoDisposeNotifierProvider<ActivityTracker, void>.internal(
      ActivityTracker.new,
      name: r'activityTrackerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$activityTrackerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ActivityTracker = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
