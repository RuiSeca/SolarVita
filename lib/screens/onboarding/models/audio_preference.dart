import 'package:shared_preferences/shared_preferences.dart';

/// Audio experience preference for the SolarVita app
enum AudioPreference {
  /// Full audio experience with background music and sound effects throughout the entire app
  full,

  /// Background music only during onboarding experience
  backgroundOnly,

  /// Silent experience with no audio at all
  silent,
}

/// Utility class for managing audio preferences
class AudioPreferences {
  static const String _audioPreferenceKey = 'audio_preference';
  static const String _hasSetPreferenceKey = 'has_set_audio_preference';

  /// Save user's audio preference
  static Future<void> setAudioPreference(AudioPreference preference) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_audioPreferenceKey, preference.name);
    await prefs.setBool(_hasSetPreferenceKey, true);
  }

  /// Get user's audio preference (defaults to full if not set)
  static Future<AudioPreference> getAudioPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final preferenceString = prefs.getString(_audioPreferenceKey);

    if (preferenceString == null) {
      return AudioPreference.full; // Default
    }

    switch (preferenceString) {
      case 'full':
        return AudioPreference.full;
      case 'backgroundOnly':
        return AudioPreference.backgroundOnly;
      case 'silent':
        return AudioPreference.silent;
      default:
        return AudioPreference.full;
    }
  }

  /// Check if user has set their audio preference
  static Future<bool> hasSetPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSetPreferenceKey) ?? false;
  }

  /// Clear audio preference (for testing/reset purposes)
  static Future<void> clearPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_audioPreferenceKey);
    await prefs.remove(_hasSetPreferenceKey);
  }

  /// Get display name for audio preference
  static String getDisplayName(AudioPreference preference) {
    switch (preference) {
      case AudioPreference.full:
        return 'Full Audio Experience';
      case AudioPreference.backgroundOnly:
        return 'Background Music Only';
      case AudioPreference.silent:
        return 'Silent Experience';
    }
  }

  /// Get description for audio preference
  static String getDescription(AudioPreference preference) {
    switch (preference) {
      case AudioPreference.full:
        return 'Immersive sounds throughout the entire SolarVita app';
      case AudioPreference.backgroundOnly:
        return 'Ambient music during onboarding experience only';
      case AudioPreference.silent:
        return 'Pure visual experience with no audio';
    }
  }

  /// Get emoji icon for audio preference
  static String getEmoji(AudioPreference preference) {
    switch (preference) {
      case AudioPreference.full:
        return '🎵';
      case AudioPreference.backgroundOnly:
        return '🎶';
      case AudioPreference.silent:
        return '🔇';
    }
  }
}