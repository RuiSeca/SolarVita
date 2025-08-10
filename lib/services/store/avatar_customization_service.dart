import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import 'package:rive/rive.dart' as rive;
import '../../models/store/avatar_customization.dart';

/// Service for managing avatar customization persistence and operations
class AvatarCustomizationService {
  static const String _customizationKey = 'avatar_customizations';
  
  final Logger _log = Logger('AvatarCustomizationService');
  SharedPreferences? _prefs;
  AvatarCustomizationManager _manager = AvatarCustomizationManager();

  /// Initialize the service
  Future<void> initialize() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
      await _loadCustomizations();
      _log.info('🎨 Avatar customization service initialized');
    }
  }

  /// Load customizations from persistence
  Future<void> _loadCustomizations() async {
    try {
      final customizationJson = _prefs!.getString(_customizationKey);
      if (customizationJson != null) {
        _manager = AvatarCustomizationManager.fromJsonString(customizationJson);
        _log.info('📱 Loaded customizations for ${_manager.customizedAvatars.length} avatars');
      } else {
        _log.info('🆕 No saved customizations found, using defaults');
      }
    } catch (e) {
      _log.warning('⚠️ Failed to load customizations: $e');
      _manager = AvatarCustomizationManager(); // Reset to default
    }
  }

  /// Save customizations to persistence
  Future<bool> _saveCustomizations() async {
    await initialize();
    
    try {
      final customizationJson = _manager.toJsonString();
      await _prefs!.setString(_customizationKey, customizationJson);
      _log.fine('💾 Saved avatar customizations');
      return true;
    } catch (e) {
      _log.warning('⚠️ Failed to save customizations: $e');
      return false;
    }
  }

  /// Get customization for an avatar
  Future<AvatarCustomization> getCustomization(String avatarId) async {
    await initialize();
    return _manager.getCustomization(avatarId);
  }

  /// Update a number value for an avatar
  Future<bool> updateNumber(String avatarId, String key, double value) async {
    try {
      _manager.updateNumber(avatarId, key, value);
      final saved = await _saveCustomizations();
      if (saved) {
        _log.info('🎨 Updated $avatarId.$key = $value');
      }
      return saved;
    } catch (e) {
      _log.warning('⚠️ Failed to update number value: $e');
      return false;
    }
  }

  /// Update a boolean value for an avatar
  Future<bool> updateBoolean(String avatarId, String key, bool value) async {
    try {
      _manager.updateBoolean(avatarId, key, value);
      final saved = await _saveCustomizations();
      if (saved) {
        _log.info('🎨 Updated $avatarId.$key = $value');
      }
      return saved;
    } catch (e) {
      _log.warning('⚠️ Failed to update boolean value: $e');
      return false;
    }
  }

  /// Batch update multiple values for an avatar
  Future<bool> batchUpdate(
    String avatarId, {
    Map<String, double>? numberValues,
    Map<String, bool>? booleanValues,
  }) async {
    try {
      var customization = _manager.getCustomization(avatarId);
      
      if (numberValues != null) {
        for (final entry in numberValues.entries) {
          customization = customization.updateNumber(entry.key, entry.value);
        }
      }
      
      if (booleanValues != null) {
        for (final entry in booleanValues.entries) {
          customization = customization.updateBoolean(entry.key, entry.value);
        }
      }
      
      _manager.setCustomization(customization);
      final saved = await _saveCustomizations();
      if (saved) {
        _log.info('🎨 Batch updated $avatarId customization');
      }
      return saved;
    } catch (e) {
      _log.warning('⚠️ Failed to batch update: $e');
      return false;
    }
  }

  /// Check if avatar has customizations
  Future<bool> hasCustomizations(String avatarId) async {
    await initialize();
    return _manager.hasCustomizations(avatarId);
  }

  /// Reset customizations for an avatar
  Future<bool> resetCustomizations(String avatarId) async {
    try {
      _manager.resetCustomizations(avatarId);
      final saved = await _saveCustomizations();
      if (saved) {
        _log.info('🔄 Reset customizations for $avatarId');
      }
      return saved;
    } catch (e) {
      _log.warning('⚠️ Failed to reset customizations: $e');
      return false;
    }
  }

  /// Get all customized avatars
  Future<List<String>> getCustomizedAvatars() async {
    await initialize();
    return _manager.customizedAvatars;
  }

  /// Apply customization to RIVE inputs
  Future<void> applyToRiveInputs(
    String avatarId, 
    List<rive.SMIInput> inputs,
  ) async {
    final customization = await getCustomization(avatarId);
    
    for (final input in inputs) {
      try {
        if (input is rive.SMINumber) {
          final value = customization.numberValues[input.name];
          if (value != null) {
            input.value = value;
            _log.fine('Applied ${input.name} = $value');
          }
        } else if (input is rive.SMIBool) {
          final value = customization.booleanValues[input.name];
          if (value != null) {
            input.value = value;
            _log.fine('Applied ${input.name} = $value');
          }
        }
      } catch (e) {
        _log.warning('⚠️ Failed to apply ${input.name}: $e (possibly missing asset)');
      }
    }
  }

  /// Export customizations as JSON
  Future<String> exportCustomizations() async {
    await initialize();
    return _manager.toJsonString();
  }

  /// Import customizations from JSON
  Future<bool> importCustomizations(String jsonString) async {
    try {
      _manager = AvatarCustomizationManager.fromJsonString(jsonString);
      final saved = await _saveCustomizations();
      if (saved) {
        _log.info('📥 Imported customizations for ${_manager.customizedAvatars.length} avatars');
      }
      return saved;
    } catch (e) {
      _log.warning('⚠️ Failed to import customizations: $e');
      return false;
    }
  }

  /// Get customization statistics
  Map<String, dynamic> getStatistics() {
    final stats = <String, dynamic>{
      'totalCustomizedAvatars': _manager.customizedAvatars.length,
      'avatarBreakdown': <String, dynamic>{},
    };

    for (final avatarId in _manager.customizedAvatars) {
      final customization = _manager.getCustomization(avatarId);
      stats['avatarBreakdown'][avatarId] = {
        'numberValues': customization.numberValues.length,
        'booleanValues': customization.booleanValues.length,
        'lastUpdated': customization.lastUpdated.toIso8601String(),
      };
    }

    return stats;
  }

  /// Clear all customizations
  Future<bool> clearAll() async {
    try {
      _manager = AvatarCustomizationManager();
      await _prefs?.remove(_customizationKey);
      _log.info('🗑️ Cleared all avatar customizations');
      return true;
    } catch (e) {
      _log.warning('⚠️ Failed to clear customizations: $e');
      return false;
    }
  }
}