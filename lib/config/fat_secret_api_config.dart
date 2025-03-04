// lib/config/fat_secret_api_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:logger/logger.dart';

class FatSecretApiConfig {
  static final Logger _logger = Logger();
  static final String apiKey = dotenv.env['FATSECRET_API_KEY'] ?? '';
  static final String apiSecret = dotenv.env['FATSECRET_API_SECRET'] ?? '';
  static const String baseUrl =
      'https://platform.fatsecret.com/rest/server.api';
  static const String oauthUrl = 'https://oauth.fatsecret.com/connect/token';

  // OAuth token request headers - multiple versions to try
  static Map<String, String> get oauthHeaders => {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization':
            'Basic ${base64Encode(utf8.encode("$apiKey:$apiSecret"))}',
      };

  // Alternative headers without auth (for when auth is in body)
  static Map<String, String> get altOauthHeaders => {
        'Content-Type': 'application/x-www-form-urlencoded',
      };

  // Standard headers for API requests after authentication
  static Map<String, String> getAuthenticatedHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  // OAuth body parameters - standard version
  static String get oauthBody => 'grant_type=client_credentials&scope=basic';

  // Alternative OAuth body with credentials in body
  static String get altOauthBody =>
      'grant_type=client_credentials&scope=basic&client_id=$apiKey&client_secret=$apiSecret';

  // Alternative OAuth body with redirect URI
  static String get altOauthBodyWithRedirect =>
      '${oauthBody}&redirect_uri=https://example.com/callback';

  // Strict validation that will return false if API credentials are missing
  static bool isConfigured() {
    if (apiKey.isEmpty) {
      _logger.e('FATSECRET_API_KEY is not set in .env file');
      return false;
    }
    if (apiSecret.isEmpty) {
      _logger.e('FATSECRET_API_SECRET is not set in .env file');
      return false;
    }
    return true;
  }

  // Debug helper for troubleshooting API credentials
  static void logKeyInfo() {
    if (apiKey.isNotEmpty) {
      _logger.d('API Key length: ${apiKey.length}');
      _logger.d(
          'API Key first/last chars: ${apiKey.substring(0, 2)}...${apiKey.substring(apiKey.length - 2)}');
    } else {
      _logger.e('API Key is empty!');
    }

    if (apiSecret.isNotEmpty) {
      _logger.d('API Secret length: ${apiSecret.length}');
      _logger.d(
          'API Secret first/last chars: ${apiSecret.substring(0, 2)}...${apiSecret.substring(apiSecret.length - 2)}');
    } else {
      _logger.e('API Secret is empty!');
    }
  }

  // Debug helper specifically for OAuth headers
  static void debugOAuthRequest() {
    _logger.d('OAuth URL: $oauthUrl');
    _logger.d('OAuth Headers: $oauthHeaders');
    _logger.d('OAuth Body: $oauthBody');
    _logger.d('Authorization Header Content: ${oauthHeaders['Authorization']}');
    _logger.d('Alternative OAuth Body: $altOauthBody');
  }
}
