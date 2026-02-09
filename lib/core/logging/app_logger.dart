import 'package:flutter/foundation.dart';

enum AppLogLevel { debug, info, warning, error }

class AppLogger {
  AppLogger._();

  static final AppLogger instance = AppLogger._();

  void debug(String message) {
    _log(level: AppLogLevel.debug, message: message);
  }

  void info(String message) {
    _log(level: AppLogLevel.info, message: message);
  }

  void warning(String message, {Object? error, StackTrace? stackTrace}) {
    _log(
      level: AppLogLevel.warning,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _log(
      level: AppLogLevel.error,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _log({
    required AppLogLevel level,
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final levelLabel = level.name.toUpperCase();
    debugPrint('[$timestamp][$levelLabel] $message');

    if (error != null) {
      debugPrint('[$timestamp][$levelLabel] error: $error');
    }

    if (stackTrace != null) {
      debugPrint('[$timestamp][$levelLabel] stackTrace: $stackTrace');
    }
  }
}
