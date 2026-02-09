import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:habit_tracker/core/logging/app_logger.dart';

abstract final class AppErrorBoundary {
  static void bootstrap(VoidCallback appRunner) {
    FlutterError.onError = (FlutterErrorDetails details) {
      AppLogger.instance.error(
        'Unhandled Flutter framework error',
        error: details.exception,
        stackTrace: details.stack,
      );
      FlutterError.presentError(details);
    };

    ErrorWidget.builder = (FlutterErrorDetails details) {
      AppLogger.instance.error(
        'Widget build failure caught by ErrorWidget',
        error: details.exception,
        stackTrace: details.stack,
      );

      return const Material(
        color: Color(0xFFF9E0DF),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Something went wrong. Please restart the app.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      AppLogger.instance.error(
        'Unhandled platform dispatcher error',
        error: error,
        stackTrace: stack,
      );
      return true;
    };

    runZonedGuarded<void>(appRunner, (Object error, StackTrace stackTrace) {
      AppLogger.instance.error(
        'Unhandled zone error',
        error: error,
        stackTrace: stackTrace,
      );
    });
  }
}
