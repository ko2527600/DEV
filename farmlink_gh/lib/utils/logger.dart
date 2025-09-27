import 'dart:developer' as developer;

class AppLogger {
  static void d(String message, [dynamic error, StackTrace? stackTrace]) {
    developer.log(
      'DEBUG: $message',
      level: 500,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void i(String message, [dynamic error, StackTrace? stackTrace]) {
    developer.log(
      'INFO: $message',
      level: 800,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void w(String message, [dynamic error, StackTrace? stackTrace]) {
    developer.log(
      'WARNING: $message',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    developer.log(
      'ERROR: $message',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
