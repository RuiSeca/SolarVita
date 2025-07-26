// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firebase_chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$firebaseChatServiceHash() =>
    r'ffb651bb06d146cbb966b4e5053ddb32da48da5a';

/// See also [firebaseChatService].
@ProviderFor(firebaseChatService)
final firebaseChatServiceProvider =
    AutoDisposeProvider<FirebaseChatService>.internal(
      firebaseChatService,
      name: r'firebaseChatServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$firebaseChatServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FirebaseChatServiceRef = AutoDisposeProviderRef<FirebaseChatService>;
String _$userConversationsHash() => r'd9181980cbe31122baeaf961d05d436fb97bdcb8';

/// See also [userConversations].
@ProviderFor(userConversations)
final userConversationsProvider =
    AutoDisposeStreamProvider<List<ChatConversation>>.internal(
      userConversations,
      name: r'userConversationsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$userConversationsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserConversationsRef =
    AutoDisposeStreamProviderRef<List<ChatConversation>>;
String _$conversationMessagesHash() =>
    r'c19611ef4ee110e9d8aa991bb97a556d8735a8da';

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

/// See also [conversationMessages].
@ProviderFor(conversationMessages)
const conversationMessagesProvider = ConversationMessagesFamily();

/// See also [conversationMessages].
class ConversationMessagesFamily extends Family<AsyncValue<List<ChatMessage>>> {
  /// See also [conversationMessages].
  const ConversationMessagesFamily();

  /// See also [conversationMessages].
  ConversationMessagesProvider call(String conversationId, {int limit = 50}) {
    return ConversationMessagesProvider(conversationId, limit: limit);
  }

  @override
  ConversationMessagesProvider getProviderOverride(
    covariant ConversationMessagesProvider provider,
  ) {
    return call(provider.conversationId, limit: provider.limit);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'conversationMessagesProvider';
}

/// See also [conversationMessages].
class ConversationMessagesProvider
    extends AutoDisposeStreamProvider<List<ChatMessage>> {
  /// See also [conversationMessages].
  ConversationMessagesProvider(String conversationId, {int limit = 50})
    : this._internal(
        (ref) => conversationMessages(
          ref as ConversationMessagesRef,
          conversationId,
          limit: limit,
        ),
        from: conversationMessagesProvider,
        name: r'conversationMessagesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$conversationMessagesHash,
        dependencies: ConversationMessagesFamily._dependencies,
        allTransitiveDependencies:
            ConversationMessagesFamily._allTransitiveDependencies,
        conversationId: conversationId,
        limit: limit,
      );

  ConversationMessagesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.conversationId,
    required this.limit,
  }) : super.internal();

  final String conversationId;
  final int limit;

  @override
  Override overrideWith(
    Stream<List<ChatMessage>> Function(ConversationMessagesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ConversationMessagesProvider._internal(
        (ref) => create(ref as ConversationMessagesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        conversationId: conversationId,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<ChatMessage>> createElement() {
    return _ConversationMessagesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationMessagesProvider &&
        other.conversationId == conversationId &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, conversationId.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ConversationMessagesRef
    on AutoDisposeStreamProviderRef<List<ChatMessage>> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;

  /// The parameter `limit` of this provider.
  int get limit;
}

class _ConversationMessagesProviderElement
    extends AutoDisposeStreamProviderElement<List<ChatMessage>>
    with ConversationMessagesRef {
  _ConversationMessagesProviderElement(super.provider);

  @override
  String get conversationId =>
      (origin as ConversationMessagesProvider).conversationId;
  @override
  int get limit => (origin as ConversationMessagesProvider).limit;
}

String _$totalUnreadCountHash() => r'2dfdcfa6ce328cfd2aff84ae35bf6ea3630d25b5';

/// See also [totalUnreadCount].
@ProviderFor(totalUnreadCount)
final totalUnreadCountProvider = AutoDisposeStreamProvider<int>.internal(
  totalUnreadCount,
  name: r'totalUnreadCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$totalUnreadCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TotalUnreadCountRef = AutoDisposeStreamProviderRef<int>;
String _$typingUsersHash() => r'bbd790c2d01a50dafe9c739d8f8ebc73361e767c';

/// See also [typingUsers].
@ProviderFor(typingUsers)
const typingUsersProvider = TypingUsersFamily();

/// See also [typingUsers].
class TypingUsersFamily extends Family<AsyncValue<List<String>>> {
  /// See also [typingUsers].
  const TypingUsersFamily();

  /// See also [typingUsers].
  TypingUsersProvider call(String conversationId) {
    return TypingUsersProvider(conversationId);
  }

  @override
  TypingUsersProvider getProviderOverride(
    covariant TypingUsersProvider provider,
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
  String? get name => r'typingUsersProvider';
}

/// See also [typingUsers].
class TypingUsersProvider extends AutoDisposeStreamProvider<List<String>> {
  /// See also [typingUsers].
  TypingUsersProvider(String conversationId)
    : this._internal(
        (ref) => typingUsers(ref as TypingUsersRef, conversationId),
        from: typingUsersProvider,
        name: r'typingUsersProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$typingUsersHash,
        dependencies: TypingUsersFamily._dependencies,
        allTransitiveDependencies: TypingUsersFamily._allTransitiveDependencies,
        conversationId: conversationId,
      );

  TypingUsersProvider._internal(
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
    Stream<List<String>> Function(TypingUsersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TypingUsersProvider._internal(
        (ref) => create(ref as TypingUsersRef),
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
  AutoDisposeStreamProviderElement<List<String>> createElement() {
    return _TypingUsersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TypingUsersProvider &&
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
mixin TypingUsersRef on AutoDisposeStreamProviderRef<List<String>> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;
}

class _TypingUsersProviderElement
    extends AutoDisposeStreamProviderElement<List<String>>
    with TypingUsersRef {
  _TypingUsersProviderElement(super.provider);

  @override
  String get conversationId => (origin as TypingUsersProvider).conversationId;
}

String _$getOrCreateConversationHash() =>
    r'a72b5b4c3e700790357473c790c766a12cc44e04';

/// See also [getOrCreateConversation].
@ProviderFor(getOrCreateConversation)
const getOrCreateConversationProvider = GetOrCreateConversationFamily();

/// See also [getOrCreateConversation].
class GetOrCreateConversationFamily
    extends Family<AsyncValue<ChatConversation>> {
  /// See also [getOrCreateConversation].
  const GetOrCreateConversationFamily();

  /// See also [getOrCreateConversation].
  GetOrCreateConversationProvider call({
    required String otherUserId,
    bool isGroup = false,
    String? groupName,
    List<String>? additionalParticipants,
  }) {
    return GetOrCreateConversationProvider(
      otherUserId: otherUserId,
      isGroup: isGroup,
      groupName: groupName,
      additionalParticipants: additionalParticipants,
    );
  }

  @override
  GetOrCreateConversationProvider getProviderOverride(
    covariant GetOrCreateConversationProvider provider,
  ) {
    return call(
      otherUserId: provider.otherUserId,
      isGroup: provider.isGroup,
      groupName: provider.groupName,
      additionalParticipants: provider.additionalParticipants,
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
  String? get name => r'getOrCreateConversationProvider';
}

/// See also [getOrCreateConversation].
class GetOrCreateConversationProvider
    extends AutoDisposeFutureProvider<ChatConversation> {
  /// See also [getOrCreateConversation].
  GetOrCreateConversationProvider({
    required String otherUserId,
    bool isGroup = false,
    String? groupName,
    List<String>? additionalParticipants,
  }) : this._internal(
         (ref) => getOrCreateConversation(
           ref as GetOrCreateConversationRef,
           otherUserId: otherUserId,
           isGroup: isGroup,
           groupName: groupName,
           additionalParticipants: additionalParticipants,
         ),
         from: getOrCreateConversationProvider,
         name: r'getOrCreateConversationProvider',
         debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
             ? null
             : _$getOrCreateConversationHash,
         dependencies: GetOrCreateConversationFamily._dependencies,
         allTransitiveDependencies:
             GetOrCreateConversationFamily._allTransitiveDependencies,
         otherUserId: otherUserId,
         isGroup: isGroup,
         groupName: groupName,
         additionalParticipants: additionalParticipants,
       );

  GetOrCreateConversationProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.otherUserId,
    required this.isGroup,
    required this.groupName,
    required this.additionalParticipants,
  }) : super.internal();

  final String otherUserId;
  final bool isGroup;
  final String? groupName;
  final List<String>? additionalParticipants;

  @override
  Override overrideWith(
    FutureOr<ChatConversation> Function(GetOrCreateConversationRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GetOrCreateConversationProvider._internal(
        (ref) => create(ref as GetOrCreateConversationRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        otherUserId: otherUserId,
        isGroup: isGroup,
        groupName: groupName,
        additionalParticipants: additionalParticipants,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ChatConversation> createElement() {
    return _GetOrCreateConversationProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GetOrCreateConversationProvider &&
        other.otherUserId == otherUserId &&
        other.isGroup == isGroup &&
        other.groupName == groupName &&
        other.additionalParticipants == additionalParticipants;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, otherUserId.hashCode);
    hash = _SystemHash.combine(hash, isGroup.hashCode);
    hash = _SystemHash.combine(hash, groupName.hashCode);
    hash = _SystemHash.combine(hash, additionalParticipants.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GetOrCreateConversationRef
    on AutoDisposeFutureProviderRef<ChatConversation> {
  /// The parameter `otherUserId` of this provider.
  String get otherUserId;

  /// The parameter `isGroup` of this provider.
  bool get isGroup;

  /// The parameter `groupName` of this provider.
  String? get groupName;

  /// The parameter `additionalParticipants` of this provider.
  List<String>? get additionalParticipants;
}

class _GetOrCreateConversationProviderElement
    extends AutoDisposeFutureProviderElement<ChatConversation>
    with GetOrCreateConversationRef {
  _GetOrCreateConversationProviderElement(super.provider);

  @override
  String get otherUserId =>
      (origin as GetOrCreateConversationProvider).otherUserId;
  @override
  bool get isGroup => (origin as GetOrCreateConversationProvider).isGroup;
  @override
  String? get groupName =>
      (origin as GetOrCreateConversationProvider).groupName;
  @override
  List<String>? get additionalParticipants =>
      (origin as GetOrCreateConversationProvider).additionalParticipants;
}

String _$searchMessagesHash() => r'f7215383b44d5107d4db00f1c5c3656404629105';

/// See also [searchMessages].
@ProviderFor(searchMessages)
const searchMessagesProvider = SearchMessagesFamily();

/// See also [searchMessages].
class SearchMessagesFamily extends Family<AsyncValue<List<ChatMessage>>> {
  /// See also [searchMessages].
  const SearchMessagesFamily();

  /// See also [searchMessages].
  SearchMessagesProvider call({
    required String conversationId,
    required String query,
    int limit = 20,
  }) {
    return SearchMessagesProvider(
      conversationId: conversationId,
      query: query,
      limit: limit,
    );
  }

  @override
  SearchMessagesProvider getProviderOverride(
    covariant SearchMessagesProvider provider,
  ) {
    return call(
      conversationId: provider.conversationId,
      query: provider.query,
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
  String? get name => r'searchMessagesProvider';
}

/// See also [searchMessages].
class SearchMessagesProvider
    extends AutoDisposeFutureProvider<List<ChatMessage>> {
  /// See also [searchMessages].
  SearchMessagesProvider({
    required String conversationId,
    required String query,
    int limit = 20,
  }) : this._internal(
         (ref) => searchMessages(
           ref as SearchMessagesRef,
           conversationId: conversationId,
           query: query,
           limit: limit,
         ),
         from: searchMessagesProvider,
         name: r'searchMessagesProvider',
         debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
             ? null
             : _$searchMessagesHash,
         dependencies: SearchMessagesFamily._dependencies,
         allTransitiveDependencies:
             SearchMessagesFamily._allTransitiveDependencies,
         conversationId: conversationId,
         query: query,
         limit: limit,
       );

  SearchMessagesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.conversationId,
    required this.query,
    required this.limit,
  }) : super.internal();

  final String conversationId;
  final String query;
  final int limit;

  @override
  Override overrideWith(
    FutureOr<List<ChatMessage>> Function(SearchMessagesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SearchMessagesProvider._internal(
        (ref) => create(ref as SearchMessagesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        conversationId: conversationId,
        query: query,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<ChatMessage>> createElement() {
    return _SearchMessagesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SearchMessagesProvider &&
        other.conversationId == conversationId &&
        other.query == query &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, conversationId.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SearchMessagesRef on AutoDisposeFutureProviderRef<List<ChatMessage>> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;

  /// The parameter `query` of this provider.
  String get query;

  /// The parameter `limit` of this provider.
  int get limit;
}

class _SearchMessagesProviderElement
    extends AutoDisposeFutureProviderElement<List<ChatMessage>>
    with SearchMessagesRef {
  _SearchMessagesProviderElement(super.provider);

  @override
  String get conversationId =>
      (origin as SearchMessagesProvider).conversationId;
  @override
  String get query => (origin as SearchMessagesProvider).query;
  @override
  int get limit => (origin as SearchMessagesProvider).limit;
}

String _$activeConversationsCountHash() =>
    r'eb767946c6a52f4c6489fe8c39df32bac502d1ee';

/// Active conversations count
///
/// Copied from [activeConversationsCount].
@ProviderFor(activeConversationsCount)
final activeConversationsCountProvider =
    AutoDisposeFutureProvider<int>.internal(
      activeConversationsCount,
      name: r'activeConversationsCountProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$activeConversationsCountHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveConversationsCountRef = AutoDisposeFutureProviderRef<int>;
String _$conversationByIdHash() => r'6867e6afc093ba3a79e6ff4275553f4a0389b795';

/// Get conversation by ID
///
/// Copied from [conversationById].
@ProviderFor(conversationById)
const conversationByIdProvider = ConversationByIdFamily();

/// Get conversation by ID
///
/// Copied from [conversationById].
class ConversationByIdFamily extends Family<AsyncValue<ChatConversation?>> {
  /// Get conversation by ID
  ///
  /// Copied from [conversationById].
  const ConversationByIdFamily();

  /// Get conversation by ID
  ///
  /// Copied from [conversationById].
  ConversationByIdProvider call(String conversationId) {
    return ConversationByIdProvider(conversationId);
  }

  @override
  ConversationByIdProvider getProviderOverride(
    covariant ConversationByIdProvider provider,
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
  String? get name => r'conversationByIdProvider';
}

/// Get conversation by ID
///
/// Copied from [conversationById].
class ConversationByIdProvider
    extends AutoDisposeFutureProvider<ChatConversation?> {
  /// Get conversation by ID
  ///
  /// Copied from [conversationById].
  ConversationByIdProvider(String conversationId)
    : this._internal(
        (ref) => conversationById(ref as ConversationByIdRef, conversationId),
        from: conversationByIdProvider,
        name: r'conversationByIdProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$conversationByIdHash,
        dependencies: ConversationByIdFamily._dependencies,
        allTransitiveDependencies:
            ConversationByIdFamily._allTransitiveDependencies,
        conversationId: conversationId,
      );

  ConversationByIdProvider._internal(
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
    FutureOr<ChatConversation?> Function(ConversationByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ConversationByIdProvider._internal(
        (ref) => create(ref as ConversationByIdRef),
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
  AutoDisposeFutureProviderElement<ChatConversation?> createElement() {
    return _ConversationByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationByIdProvider &&
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
mixin ConversationByIdRef on AutoDisposeFutureProviderRef<ChatConversation?> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;
}

class _ConversationByIdProviderElement
    extends AutoDisposeFutureProviderElement<ChatConversation?>
    with ConversationByIdRef {
  _ConversationByIdProviderElement(super.provider);

  @override
  String get conversationId =>
      (origin as ConversationByIdProvider).conversationId;
}

String _$lastMessageHash() => r'596f9ac4eda551015bcd035f259774d3333b87f4';

/// Get last message for conversation
///
/// Copied from [lastMessage].
@ProviderFor(lastMessage)
const lastMessageProvider = LastMessageFamily();

/// Get last message for conversation
///
/// Copied from [lastMessage].
class LastMessageFamily extends Family<AsyncValue<ChatMessage?>> {
  /// Get last message for conversation
  ///
  /// Copied from [lastMessage].
  const LastMessageFamily();

  /// Get last message for conversation
  ///
  /// Copied from [lastMessage].
  LastMessageProvider call(String conversationId) {
    return LastMessageProvider(conversationId);
  }

  @override
  LastMessageProvider getProviderOverride(
    covariant LastMessageProvider provider,
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
  String? get name => r'lastMessageProvider';
}

/// Get last message for conversation
///
/// Copied from [lastMessage].
class LastMessageProvider extends AutoDisposeFutureProvider<ChatMessage?> {
  /// Get last message for conversation
  ///
  /// Copied from [lastMessage].
  LastMessageProvider(String conversationId)
    : this._internal(
        (ref) => lastMessage(ref as LastMessageRef, conversationId),
        from: lastMessageProvider,
        name: r'lastMessageProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$lastMessageHash,
        dependencies: LastMessageFamily._dependencies,
        allTransitiveDependencies: LastMessageFamily._allTransitiveDependencies,
        conversationId: conversationId,
      );

  LastMessageProvider._internal(
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
    FutureOr<ChatMessage?> Function(LastMessageRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LastMessageProvider._internal(
        (ref) => create(ref as LastMessageRef),
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
  AutoDisposeFutureProviderElement<ChatMessage?> createElement() {
    return _LastMessageProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LastMessageProvider &&
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
mixin LastMessageRef on AutoDisposeFutureProviderRef<ChatMessage?> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;
}

class _LastMessageProviderElement
    extends AutoDisposeFutureProviderElement<ChatMessage?>
    with LastMessageRef {
  _LastMessageProviderElement(super.provider);

  @override
  String get conversationId => (origin as LastMessageProvider).conversationId;
}

String _$hasUnreadMessagesHash() => r'101edcc3f01a594ab42c3b6895512f9b6907bd3a';

/// Check if user has unread messages
///
/// Copied from [hasUnreadMessages].
@ProviderFor(hasUnreadMessages)
final hasUnreadMessagesProvider = AutoDisposeFutureProvider<bool>.internal(
  hasUnreadMessages,
  name: r'hasUnreadMessagesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hasUnreadMessagesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HasUnreadMessagesRef = AutoDisposeFutureProviderRef<bool>;
String _$conversationParticipantsHash() =>
    r'b0c666cb590fc1b372d6463639c47b9a5eed6375';

/// Get conversation participants info
///
/// Copied from [conversationParticipants].
@ProviderFor(conversationParticipants)
const conversationParticipantsProvider = ConversationParticipantsFamily();

/// Get conversation participants info
///
/// Copied from [conversationParticipants].
class ConversationParticipantsFamily
    extends Family<AsyncValue<List<Map<String, String>>>> {
  /// Get conversation participants info
  ///
  /// Copied from [conversationParticipants].
  const ConversationParticipantsFamily();

  /// Get conversation participants info
  ///
  /// Copied from [conversationParticipants].
  ConversationParticipantsProvider call(String conversationId) {
    return ConversationParticipantsProvider(conversationId);
  }

  @override
  ConversationParticipantsProvider getProviderOverride(
    covariant ConversationParticipantsProvider provider,
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
  String? get name => r'conversationParticipantsProvider';
}

/// Get conversation participants info
///
/// Copied from [conversationParticipants].
class ConversationParticipantsProvider
    extends AutoDisposeFutureProvider<List<Map<String, String>>> {
  /// Get conversation participants info
  ///
  /// Copied from [conversationParticipants].
  ConversationParticipantsProvider(String conversationId)
    : this._internal(
        (ref) => conversationParticipants(
          ref as ConversationParticipantsRef,
          conversationId,
        ),
        from: conversationParticipantsProvider,
        name: r'conversationParticipantsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$conversationParticipantsHash,
        dependencies: ConversationParticipantsFamily._dependencies,
        allTransitiveDependencies:
            ConversationParticipantsFamily._allTransitiveDependencies,
        conversationId: conversationId,
      );

  ConversationParticipantsProvider._internal(
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
    FutureOr<List<Map<String, String>>> Function(
      ConversationParticipantsRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ConversationParticipantsProvider._internal(
        (ref) => create(ref as ConversationParticipantsRef),
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
  AutoDisposeFutureProviderElement<List<Map<String, String>>> createElement() {
    return _ConversationParticipantsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationParticipantsProvider &&
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
mixin ConversationParticipantsRef
    on AutoDisposeFutureProviderRef<List<Map<String, String>>> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;
}

class _ConversationParticipantsProviderElement
    extends AutoDisposeFutureProviderElement<List<Map<String, String>>>
    with ConversationParticipantsRef {
  _ConversationParticipantsProviderElement(super.provider);

  @override
  String get conversationId =>
      (origin as ConversationParticipantsProvider).conversationId;
}

String _$typingIndicatorTextHash() =>
    r'ecf62b2f02e3303895f429ad8015d600451a4810';

/// Typing indicator text
///
/// Copied from [typingIndicatorText].
@ProviderFor(typingIndicatorText)
const typingIndicatorTextProvider = TypingIndicatorTextFamily();

/// Typing indicator text
///
/// Copied from [typingIndicatorText].
class TypingIndicatorTextFamily extends Family<AsyncValue<String>> {
  /// Typing indicator text
  ///
  /// Copied from [typingIndicatorText].
  const TypingIndicatorTextFamily();

  /// Typing indicator text
  ///
  /// Copied from [typingIndicatorText].
  TypingIndicatorTextProvider call(String conversationId) {
    return TypingIndicatorTextProvider(conversationId);
  }

  @override
  TypingIndicatorTextProvider getProviderOverride(
    covariant TypingIndicatorTextProvider provider,
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
  String? get name => r'typingIndicatorTextProvider';
}

/// Typing indicator text
///
/// Copied from [typingIndicatorText].
class TypingIndicatorTextProvider extends AutoDisposeFutureProvider<String> {
  /// Typing indicator text
  ///
  /// Copied from [typingIndicatorText].
  TypingIndicatorTextProvider(String conversationId)
    : this._internal(
        (ref) =>
            typingIndicatorText(ref as TypingIndicatorTextRef, conversationId),
        from: typingIndicatorTextProvider,
        name: r'typingIndicatorTextProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$typingIndicatorTextHash,
        dependencies: TypingIndicatorTextFamily._dependencies,
        allTransitiveDependencies:
            TypingIndicatorTextFamily._allTransitiveDependencies,
        conversationId: conversationId,
      );

  TypingIndicatorTextProvider._internal(
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
    FutureOr<String> Function(TypingIndicatorTextRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TypingIndicatorTextProvider._internal(
        (ref) => create(ref as TypingIndicatorTextRef),
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
  AutoDisposeFutureProviderElement<String> createElement() {
    return _TypingIndicatorTextProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TypingIndicatorTextProvider &&
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
mixin TypingIndicatorTextRef on AutoDisposeFutureProviderRef<String> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;
}

class _TypingIndicatorTextProviderElement
    extends AutoDisposeFutureProviderElement<String>
    with TypingIndicatorTextRef {
  _TypingIndicatorTextProviderElement(super.provider);

  @override
  String get conversationId =>
      (origin as TypingIndicatorTextProvider).conversationId;
}

String _$chatActionsHash() => r'51471e0de4169a86743935bc3b7c665dec451d87';

/// Chat Actions State Notifier
///
/// Copied from [ChatActions].
@ProviderFor(ChatActions)
final chatActionsProvider =
    AutoDisposeNotifierProvider<ChatActions, AsyncValue<void>>.internal(
      ChatActions.new,
      name: r'chatActionsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$chatActionsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ChatActions = AutoDisposeNotifier<AsyncValue<void>>;
String _$messageSearchResultsHash() =>
    r'2f79720ad5144f5fe950ae10ee0156c30f3f4435';

/// Message search results
///
/// Copied from [MessageSearchResults].
@ProviderFor(MessageSearchResults)
final messageSearchResultsProvider =
    AutoDisposeNotifierProvider<
      MessageSearchResults,
      AsyncValue<List<ChatMessage>>
    >.internal(
      MessageSearchResults.new,
      name: r'messageSearchResultsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$messageSearchResultsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MessageSearchResults =
    AutoDisposeNotifier<AsyncValue<List<ChatMessage>>>;
String _$conversationReadTrackerHash() =>
    r'fb1b6b7609526c85ec76a8179d40e630afd3096a';

/// Auto-mark messages as read when conversation is active
///
/// Copied from [ConversationReadTracker].
@ProviderFor(ConversationReadTracker)
final conversationReadTrackerProvider =
    AutoDisposeNotifierProvider<ConversationReadTracker, void>.internal(
      ConversationReadTracker.new,
      name: r'conversationReadTrackerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$conversationReadTrackerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ConversationReadTracker = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
