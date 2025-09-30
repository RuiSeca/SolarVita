import 'package:logging/logging.dart';

final log = Logger('TranslationErrorHandler');

/// Comprehensive error handling for the translation system
class TranslationErrorHandler {
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  /// Execute a function with retry logic and error handling
  static Future<T> executeWithRetry<T>(
    Future<T> Function() operation,
    String operationName, {
    int maxRetries = maxRetries,
    Duration retryDelay = retryDelay,
    T? fallbackValue,
    bool logErrors = true,
  }) async {
    Exception? lastException;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        if (logErrors && attempt > 1) {
          log.info('🔄 Retry attempt $attempt/$maxRetries for: $operationName');
        }

        final result = await operation();

        if (attempt > 1 && logErrors) {
          log.info('✅ Operation succeeded on attempt $attempt: $operationName');
        }

        return result;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());

        if (logErrors) {
          log.warning('❌ Attempt $attempt/$maxRetries failed for $operationName: $e');
        }

        if (attempt < maxRetries) {
          if (_shouldRetry(e)) {
            await Future.delayed(retryDelay * attempt); // Exponential backoff
          } else {
            if (logErrors) {
              log.info('🚫 Error not retryable, stopping attempts: $e');
            }
            break;
          }
        }
      }
    }

    // All retries failed
    if (logErrors) {
      log.severe('💥 All $maxRetries attempts failed for $operationName: $lastException');
    }

    if (fallbackValue != null) {
      if (logErrors) {
        log.info('🔄 Using fallback value for $operationName');
      }
      return fallbackValue;
    }

    throw lastException ?? Exception('Operation failed: $operationName');
  }

  /// Execute with fallback to cached data
  static Future<T> executeWithCacheFallback<T>(
    Future<T> Function() primaryOperation,
    Future<T?> Function() cacheOperation,
    String operationName, {
    T? ultimateFallback,
    bool logErrors = true,
  }) async {
    try {
      // Try primary operation first
      return await executeWithRetry(
        primaryOperation,
        operationName,
        logErrors: logErrors,
      );
    } catch (e) {
      if (logErrors) {
        log.warning('🔄 Primary operation failed, trying cache: $operationName');
      }

      try {
        final cachedResult = await cacheOperation();
        if (cachedResult != null) {
          if (logErrors) {
            log.info('✅ Using cached data for: $operationName');
          }
          return cachedResult;
        }
      } catch (cacheError) {
        if (logErrors) {
          log.warning('❌ Cache operation also failed: $cacheError');
        }
      }

      // Both primary and cache failed
      if (ultimateFallback != null) {
        if (logErrors) {
          log.info('🔄 Using ultimate fallback for: $operationName');
        }
        return ultimateFallback;
      }

      // No fallback available, rethrow original error
      rethrow;
    }
  }

  /// Check if an error should trigger a retry
  static bool _shouldRetry(dynamic error) {
    final errorMessage = error.toString().toLowerCase();

    // Network-related errors that might be temporary
    if (errorMessage.contains('socket') ||
        errorMessage.contains('timeout') ||
        errorMessage.contains('connection') ||
        errorMessage.contains('network') ||
        errorMessage.contains('rate limit') ||
        errorMessage.contains('429')) {
      return true;
    }

    // Translation service specific errors
    if (errorMessage.contains('translation') ||
        errorMessage.contains('quota') ||
        errorMessage.contains('service unavailable') ||
        errorMessage.contains('503')) {
      return true;
    }

    // API-related temporary errors
    if (errorMessage.contains('502') ||
        errorMessage.contains('503') ||
        errorMessage.contains('504')) {
      return true;
    }

    // Don't retry on permanent errors
    if (errorMessage.contains('403') ||
        errorMessage.contains('401') ||
        errorMessage.contains('404') ||
        errorMessage.contains('bad request') ||
        errorMessage.contains('invalid')) {
      return false;
    }

    // Default to retry for unknown errors
    return true;
  }

  /// Create a user-friendly error message
  static String createUserFriendlyMessage(dynamic error, String context) {
    final errorMessage = error.toString().toLowerCase();

    if (errorMessage.contains('network') || errorMessage.contains('connection')) {
      return 'Network connection issue. Please check your internet connection and try again.';
    }

    if (errorMessage.contains('rate limit') || errorMessage.contains('429')) {
      return 'Service is busy. Please wait a moment and try again.';
    }

    if (errorMessage.contains('quota') || errorMessage.contains('billing')) {
      return 'Translation service quota exceeded. Using cached data when available.';
    }

    if (errorMessage.contains('translation')) {
      return 'Translation service temporarily unavailable. Showing original content.';
    }

    if (errorMessage.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    if (errorMessage.contains('404') || errorMessage.contains('not found')) {
      return 'Content not found. It may have been removed or is temporarily unavailable.';
    }

    if (errorMessage.contains('403') || errorMessage.contains('access denied')) {
      return 'Access to the service is restricted. Please check your settings.';
    }

    // Generic fallback
    return 'Something went wrong while loading $context. Please try again.';
  }

  /// Log error with context
  static void logError(
    dynamic error,
    StackTrace? stackTrace,
    String operation, {
    Map<String, dynamic>? context,
  }) {
    final contextStr = context != null
        ? context.entries.map((e) => '${e.key}=${e.value}').join(', ')
        : '';

    log.severe(
      '💥 Error in $operation${contextStr.isNotEmpty ? ' ($contextStr)' : ''}: $error',
      error,
      stackTrace,
    );
  }

  /// Handle offline scenarios
  static Future<T> handleOffline<T>(
    Future<T> Function() onlineOperation,
    Future<T?> Function() offlineOperation,
    String operationName, {
    bool isOffline = false,
  }) async {
    if (isOffline) {
      log.info('📱 Offline mode: Using cached data for $operationName');
      final result = await offlineOperation();
      if (result != null) {
        return result;
      }
      throw Exception('No offline data available for $operationName');
    }

    try {
      return await onlineOperation();
    } catch (e) {
      // If online operation fails, try offline
      log.info('🔄 Online failed, attempting offline for $operationName');
      final result = await offlineOperation();
      if (result != null) {
        return result;
      }
      rethrow;
    }
  }
}

/// Specific error types for the translation system
class TranslationException implements Exception {
  final String message;
  final String? originalError;
  final String? language;
  final String? contentType;

  const TranslationException(
    this.message, {
    this.originalError,
    this.language,
    this.contentType,
  });

  @override
  String toString() {
    final parts = [message];
    if (language != null) parts.add('Language: $language');
    if (contentType != null) parts.add('Type: $contentType');
    if (originalError != null) parts.add('Original: $originalError');
    return 'TranslationException: ${parts.join(', ')}';
  }
}

class NetworkException implements Exception {
  final String message;
  final String? endpoint;
  final int? statusCode;

  const NetworkException(
    this.message, {
    this.endpoint,
    this.statusCode,
  });

  @override
  String toString() {
    final parts = [message];
    if (endpoint != null) parts.add('Endpoint: $endpoint');
    if (statusCode != null) parts.add('Status: $statusCode');
    return 'NetworkException: ${parts.join(', ')}';
  }
}

class CacheException implements Exception {
  final String message;
  final String? operation;

  const CacheException(this.message, {this.operation});

  @override
  String toString() {
    return 'CacheException: $message${operation != null ? ' (Operation: $operation)' : ''}';
  }
}

class QuotaExceededException implements Exception {
  final String message;
  final String service;
  final DateTime? resetTime;

  const QuotaExceededException(
    this.message,
    this.service, {
    this.resetTime,
  });

  @override
  String toString() {
    final parts = [message, 'Service: $service'];
    if (resetTime != null) {
      parts.add('Reset: ${resetTime!.toIso8601String()}');
    }
    return 'QuotaExceededException: ${parts.join(', ')}';
  }
}