import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'dart:convert';
import 'scalable_avatar_system.dart';

final log = Logger('AvatarConfigLoader');

/// Helper class to load avatar configuration from assets
class AvatarConfigLoader {
  static bool _isLoaded = false;
  
  /// Load avatar configuration from assets
  static Future<void> loadConfiguration() async {
    if (_isLoaded) return;
    
    try {
      log.info('📥 Loading avatar configuration from assets...');
      
      // Load JSON from assets
      final String configString = await rootBundle.loadString('assets/config/avatars.json');
      final Map<String, dynamic> config = json.decode(configString);
      
      // Initialize configuration manager
      final configManager = AvatarConfigurationManager();
      await configManager.loadConfiguration(inlineConfig: config);
      
      _isLoaded = true;
      log.info('✅ Avatar configuration loaded successfully');
      
    } catch (e) {
      log.severe('❌ Failed to load avatar configuration: $e');
      
      // Fallback to default configuration
      log.info('🔄 Loading default configuration...');
      final configManager = AvatarConfigurationManager();
      await configManager.loadConfiguration(); // Uses default config
      
      _isLoaded = true;
    }
  }
  
  /// Check if configuration is loaded
  static bool get isLoaded => _isLoaded;
  
  /// Reset loaded state (useful for testing)
  static void reset() {
    _isLoaded = false;
  }
}