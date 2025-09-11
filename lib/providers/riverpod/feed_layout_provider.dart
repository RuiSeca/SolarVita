import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FeedLayoutStyle { list, grid2, grid3 }
enum PostDensity { compact, normal, comfortable }

class FeedLayoutPreferences {
  final FeedLayoutStyle layoutStyle;
  final PostDensity postDensity;
  final bool showTimestamps;
  final bool showEngagementCounts;
  final bool showProfilePictures;
  final bool showPostPreviews;
  final bool autoPlayVideos;
  final bool autoExpandImages;
  final bool autoLoadMore;

  const FeedLayoutPreferences({
    this.layoutStyle = FeedLayoutStyle.list,
    this.postDensity = PostDensity.normal,
    this.showTimestamps = true,
    this.showEngagementCounts = true,
    this.showProfilePictures = true,
    this.showPostPreviews = false,
    this.autoPlayVideos = false,
    this.autoExpandImages = true,
    this.autoLoadMore = true,
  });

  FeedLayoutPreferences copyWith({
    FeedLayoutStyle? layoutStyle,
    PostDensity? postDensity,
    bool? showTimestamps,
    bool? showEngagementCounts,
    bool? showProfilePictures,
    bool? showPostPreviews,
    bool? autoPlayVideos,
    bool? autoExpandImages,
    bool? autoLoadMore,
  }) {
    return FeedLayoutPreferences(
      layoutStyle: layoutStyle ?? this.layoutStyle,
      postDensity: postDensity ?? this.postDensity,
      showTimestamps: showTimestamps ?? this.showTimestamps,
      showEngagementCounts: showEngagementCounts ?? this.showEngagementCounts,
      showProfilePictures: showProfilePictures ?? this.showProfilePictures,
      showPostPreviews: showPostPreviews ?? this.showPostPreviews,
      autoPlayVideos: autoPlayVideos ?? this.autoPlayVideos,
      autoExpandImages: autoExpandImages ?? this.autoExpandImages,
      autoLoadMore: autoLoadMore ?? this.autoLoadMore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'layoutStyle': layoutStyle.index,
      'postDensity': postDensity.index,
      'showTimestamps': showTimestamps,
      'showEngagementCounts': showEngagementCounts,
      'showProfilePictures': showProfilePictures,
      'showPostPreviews': showPostPreviews,
      'autoPlayVideos': autoPlayVideos,
      'autoExpandImages': autoExpandImages,
      'autoLoadMore': autoLoadMore,
    };
  }

  factory FeedLayoutPreferences.fromJson(Map<String, dynamic> json) {
    return FeedLayoutPreferences(
      layoutStyle: FeedLayoutStyle.values[json['layoutStyle'] ?? 0],
      postDensity: PostDensity.values[json['postDensity'] ?? 1],
      showTimestamps: json['showTimestamps'] ?? true,
      showEngagementCounts: json['showEngagementCounts'] ?? true,
      showProfilePictures: json['showProfilePictures'] ?? true,
      showPostPreviews: json['showPostPreviews'] ?? false,
      autoPlayVideos: json['autoPlayVideos'] ?? false,
      autoExpandImages: json['autoExpandImages'] ?? true,
      autoLoadMore: json['autoLoadMore'] ?? true,
    );
  }
}

class FeedLayoutNotifier extends StateNotifier<FeedLayoutPreferences> {
  static const String _prefsKey = 'feed_layout_preferences';
  
  FeedLayoutNotifier() : super(const FeedLayoutPreferences()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);
      if (jsonString != null) {
        final json = Map<String, dynamic>.from(
          Uri.splitQueryString(jsonString).map(
            (key, value) => MapEntry(key, _parseValue(value)),
          ),
        );
        state = FeedLayoutPreferences.fromJson(json);
      }
    } catch (e) {
      // If loading fails, keep default preferences
    }
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = state.toJson();
      final jsonString = Uri(queryParameters: json.map(
        (key, value) => MapEntry(key, value.toString()),
      )).query;
      await prefs.setString(_prefsKey, jsonString);
    } catch (e) {
      // Handle save error silently
    }
  }

  dynamic _parseValue(String value) {
    if (value == 'true') return true;
    if (value == 'false') return false;
    final intValue = int.tryParse(value);
    if (intValue != null) return intValue;
    return value;
  }

  Future<void> setLayoutStyle(FeedLayoutStyle style) async {
    state = state.copyWith(layoutStyle: style);
    await _savePreferences();
  }

  Future<void> setPostDensity(PostDensity density) async {
    state = state.copyWith(postDensity: density);
    await _savePreferences();
  }

  Future<void> setShowTimestamps(bool show) async {
    state = state.copyWith(showTimestamps: show);
    await _savePreferences();
  }

  Future<void> setShowEngagementCounts(bool show) async {
    state = state.copyWith(showEngagementCounts: show);
    await _savePreferences();
  }

  Future<void> setShowProfilePictures(bool show) async {
    state = state.copyWith(showProfilePictures: show);
    await _savePreferences();
  }

  Future<void> setShowPostPreviews(bool show) async {
    state = state.copyWith(showPostPreviews: show);
    await _savePreferences();
  }

  Future<void> setAutoPlayVideos(bool autoPlay) async {
    state = state.copyWith(autoPlayVideos: autoPlay);
    await _savePreferences();
  }

  Future<void> setAutoExpandImages(bool autoExpand) async {
    state = state.copyWith(autoExpandImages: autoExpand);
    await _savePreferences();
  }

  Future<void> setAutoLoadMore(bool autoLoad) async {
    state = state.copyWith(autoLoadMore: autoLoad);
    await _savePreferences();
  }
}

final feedLayoutProvider = StateNotifierProvider<FeedLayoutNotifier, FeedLayoutPreferences>(
  (ref) => FeedLayoutNotifier(),
);