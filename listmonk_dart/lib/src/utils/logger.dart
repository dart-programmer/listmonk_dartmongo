import 'dart:developer' as developer;

/// Logging utility for the Listmonk Dart package
class Logger {
  static const String _name = 'Listmonk';

  /// Log debug messages
  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: _name,
      level: 500, // Debug level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log info messages
  static void info(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: _name,
      level: 800, // Info level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log warning messages
  static void warning(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: _name,
      level: 900, // Warning level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log error messages
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: _name,
      level: 1000, // Error level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log fatal messages
  static void fatal(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: _name,
      level: 1200, // Fatal level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log database operations
  static void db(String operation, {Map<String, dynamic>? data}) {
    debug('DB Operation: $operation', error: data);
  }

  /// Log email operations
  static void email(String operation, {String? recipient, String? subject}) {
    info('Email Operation: $operation', error: {'recipient': recipient, 'subject': subject});
  }

  /// Log validation errors
  static void validation(String field, String error) {
    warning('Validation Error: $field - $error');
  }

  /// Log performance metrics
  static void performance(String operation, Duration duration) {
    info('Performance: $operation took ${duration.inMilliseconds}ms');
  }
}