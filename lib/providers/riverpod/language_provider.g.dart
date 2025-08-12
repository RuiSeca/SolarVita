// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'language_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$supportedLanguagesHash() =>
    r'483b7d1ac72d4499b91e974f71a34e5c1d0e4b7f';

/// See also [supportedLanguages].
@ProviderFor(supportedLanguages)
final supportedLanguagesProvider = AutoDisposeProvider<List<Language>>.internal(
  supportedLanguages,
  name: r'supportedLanguagesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$supportedLanguagesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SupportedLanguagesRef = AutoDisposeProviderRef<List<Language>>;

String _$currentLanguageHash() => r'1e45842dcbc32ee7248f921e435e30f108ed87cb';

/// See also [currentLanguage].
@ProviderFor(currentLanguage)
final currentLanguageProvider = AutoDisposeProvider<Language>.internal(
  currentLanguage,
  name: r'currentLanguageProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentLanguageHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentLanguageRef = AutoDisposeProviderRef<Language>;

String _$languageNotifierHash() => r'6de1a77bb66232bba3dd13c0aa013d6c33ea7ff2';

/// See also [LanguageNotifier].
@ProviderFor(LanguageNotifier)
final languageNotifierProvider =
    AutoDisposeAsyncNotifierProvider<LanguageNotifier, Locale>.internal(
      LanguageNotifier.new,
      name: r'languageNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$languageNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$LanguageNotifier = AutoDisposeAsyncNotifier<Locale>;

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package