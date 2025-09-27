import 'dart:developer' as developer;

class Logger {
  static const String _tag = 'SolarVita';

  /// Log an info message
  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _tag,
      level: 800, // INFO level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log an error message
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _tag,
      level: 1000, // ERROR level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log a warning message
  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _tag,
      level: 900, // WARNING level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log a debug message
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _tag,
      level: 700, // DEBUG level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log a verbose message
  static void verbose(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _tag,
      level: 500, // VERBOSE level
      error: error,
      stackTrace: stackTrace,
    );
  }
}