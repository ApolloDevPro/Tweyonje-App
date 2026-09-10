import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

enum LogLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}

class Logger {
  static const String _tag = 'Tweyonje';
  static bool _enabled = true;
  static LogLevel _minLevel = LogLevel.debug;

  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  static void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, error: error, stackTrace: stackTrace);
  }

  static void info(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, error: error, stackTrace: stackTrace);
  }

  static void warning(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message, error: error, stackTrace: stackTrace);
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, error: error, stackTrace: stackTrace);
  }

  static void fatal(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.fatal, message, error: error, stackTrace: stackTrace);
  }

  static void _log(LogLevel level, String message, {Object? error, StackTrace? stackTrace}) {
    if (!_enabled || level.index < _minLevel.index) {
      return;
    }

    final timestamp = DateTime.now().toIso8601String();

    if (kDebugMode) {
      developer.log(
        '[$timestamp] [${level.name.toUpperCase()}] $_tag: $message',
        name: _tag,
        time: DateTime.now(),
        level: level.index, // Use index instead of name
        error: error,
        stackTrace: stackTrace,
      );
    }

    // In production, you might want to send logs to a service like Sentry
    if (level == LogLevel.error || level == LogLevel.fatal) {
      // Send to error tracking service
      _sendToErrorTracking(level, message, error, stackTrace);
    }
  }

  static void _sendToErrorTracking(LogLevel level, String message, Object? error, StackTrace? stackTrace) {
    // Integration with error tracking services like Sentry can be added here
    // For now, we'll just log to console in debug mode
    if (kDebugMode) {
      developer.log(
        'Error Tracking: $message',
        name: _tag,
        error: error,
        stackTrace: stackTrace,
      );
    }
    
    // In production, integrate with MonitoringService
    if (!kDebugMode && (level == LogLevel.error || level == LogLevel.fatal)) {
      // This would require access to MonitoringService instance
      // For now, we'll keep it as a placeholder
    }
  }

  // Specific logging methods for common scenarios
  static void logApiCall(String method, String endpoint, {Map<String, dynamic>? params}) {
    info('API Call: $method $endpoint', error: params);
  }

  static void logApiResponse(String endpoint, int statusCode, {dynamic data}) {
    info('API Response: $endpoint - Status: $statusCode', error: data);
  }

  static void logApiError(String endpoint, int statusCode, {String? errorMessage}) {
    error('API Error: $endpoint - Status: $statusCode - Message: $errorMessage');
  }

  static void logUserAction(String action, {Map<String, dynamic>? properties}) {
    info('User Action: $action', error: properties);
  }

  static void logScreenView(String screenName) {
    info('Screen View: $screenName');
  }

  static void logPerformance(String operation, Duration duration) {
    info('Performance: $operation took ${duration.inMilliseconds}ms');
  }
}