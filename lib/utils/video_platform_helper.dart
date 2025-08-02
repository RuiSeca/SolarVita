import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper class for handling video platform URLs and preferences
class VideoPlatformHelper {
  static const String _videoPlatformKey = 'video_platform_preference';
  static const String _defaultPlatform = 'youtube';

  /// Get YouTube search URL for a meal recipe
  static String getYouTubeSearchURL(String mealName) {
    final query = Uri.encodeComponent('$mealName recipe');
    return 'https://www.youtube.com/results?search_query=$query';
  }

  /// Get Google Videos search URL for a meal recipe
  static String getGoogleVideosSearchURL(String mealName) {
    final query = Uri.encodeComponent('$mealName recipe');
    return 'https://www.google.com/search?tbm=vid&q=$query';
  }

  /// Get the user's preferred video platform
  static Future<String> getPreferredVideoPlatform() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_videoPlatformKey) ?? _defaultPlatform;
    } catch (e) {
      return _defaultPlatform;
    }
  }

  /// Set the user's preferred video platform
  static Future<void> setPreferredVideoPlatform(String platform) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_videoPlatformKey, platform);
    } catch (e) {
      // Handle error silently, use default platform
    }
  }

  /// Get the appropriate search URL based on user preference
  static Future<String> getSearchURL(String mealName) async {
    final platform = await getPreferredVideoPlatform();
    
    switch (platform) {
      case 'google':
        return getGoogleVideosSearchURL(mealName);
      case 'youtube':
      default:
        return getYouTubeSearchURL(mealName);
    }
  }

  /// Launch video search in browser or app
  static Future<bool> launchVideoSearch(String mealName) async {
    try {
      final url = await getSearchURL(mealName);
      final uri = Uri.parse(url);
      
      // Try to launch the URL
      if (await canLaunchUrl(uri)) {
        return await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // Open in external app (YouTube app if available)
        );
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get platform display name for UI
  static String getPlatformDisplayName(String platform) {
    switch (platform) {
      case 'youtube':
        return 'YouTube';
      case 'google':
        return 'Google Videos';
      default:
        return 'YouTube';
    }
  }

  /// Get available video platforms
  static List<Map<String, String>> getAvailablePlatforms() {
    return [
      {
        'value': 'youtube',
        'name': 'YouTube',
        'description': 'Search for recipe videos on YouTube'
      },
      {
        'value': 'google',
        'name': 'Google Videos',
        'description': 'Search for recipe videos using Google Videos'
      },
    ];
  }
}