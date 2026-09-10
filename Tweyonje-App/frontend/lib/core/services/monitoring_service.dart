import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'logger.dart';

class MonitoringService {
  static MonitoringService? _instance;
  static MonitoringService get instance => _instance ??= MonitoringService._internal();
  
  MonitoringService._internal();

  bool _isInitialized = false;
  bool _enabled = false;

  Future<void> initialize({
    required String dsn,
    bool enabled = true,
    String environment = 'production',
    String? release,
    Map<String, String>? tags,
  }) async {
    if (_isInitialized) {
      Logger.warning('Monitoring service already initialized');
      return;
    }

    _enabled = enabled;

    if (!enabled) {
      Logger.info('Monitoring service disabled');
      _isInitialized = true;
      return;
    }

    try {
      await SentryFlutter.init(
        (options) {
          options.dsn = dsn;
          options.environment = environment;
          options.release = release;
          options.tracesSampleRate = kDebugMode ? 1.0 : 0.1; // Higher sampling in debug
          options.enableUserInteractionTracing = true;
          options.enableAppLifecycleBreadcrumbs = true;
          
          // Before send callback for filtering
          options.beforeSend = (event, hint) {
            // Filter out certain events if needed
            if (event.throwable != null) {
              // Don't send certain exceptions
              if (event.throwable.toString().contains('canceled')) {
                return null;
              }
            }
            return event;
          };
        },
      );

      // Set custom tags after initialization
      if (tags != null) {
        Sentry.configureScope((scope) {
          for (final entry in tags.entries) {
            scope.setTag(entry.key, entry.value);
          }
        });
      }

      _isInitialized = true;
      Logger.info('Monitoring service initialized successfully');
    } catch (e) {
      Logger.error('Failed to initialize monitoring service', error: e);
      _isInitialized = true; // Mark as initialized even if failed to prevent retries
    }
  }

  // Capture exceptions
  Future<void> captureException(
    dynamic exception, {
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
    String? hint,
  }) async {
    if (!_enabled || !_isInitialized) {
      Logger.error('Exception (monitoring disabled): $exception', error: exception);
      return;
    }

    try {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
      Logger.info('Exception captured and sent to Sentry');
    } catch (e) {
      Logger.error('Failed to capture exception', error: e);
    }
  }

  // Capture messages
  Future<void> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? extra,
  }) async {
    if (!_enabled || !_isInitialized) {
      Logger.info('Message (monitoring disabled): $message');
      return;
    }

    try {
      await Sentry.captureMessage(
        message,
        level: level,
      );
      Logger.info('Message captured and sent to Sentry');
    } catch (e) {
      Logger.error('Failed to capture message', error: e);
    }
  }

  // Set user context
  Future<void> setUser({
    String? id,
    String? email,
    String? username,
  }) async {
    if (!_enabled || !_isInitialized) return;

    try {
      Sentry.configureScope((scope) {
        scope.setUser(SentryUser(
          id: id,
          email: email,
          username: username,
        ));
      });
      Logger.info('User context set');
    } catch (e) {
      Logger.error('Failed to set user context', error: e);
    }
  }

  // Clear user context
  Future<void> clearUser() async {
    if (!_enabled || !_isInitialized) return;

    try {
      Sentry.configureScope((scope) {
        scope.setUser(null);
      });
      Logger.info('User context cleared');
    } catch (e) {
      Logger.error('Failed to clear user context', error: e);
    }
  }

  // Add breadcrumb
  Future<void> addBreadcrumb(
    String message, {
    String? category,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    if (!_enabled || !_isInitialized) return;

    try {
      Sentry.addBreadcrumb(Breadcrumb(
        message: message,
        category: category,
        type: type,
        data: data,
      ));
    } catch (e) {
      Logger.error('Failed to add breadcrumb', error: e);
    }
  }

  // Set custom context
  Future<void> setContext(String key, dynamic value) async {
    if (!_enabled || !_isInitialized) return;

    try {
      Sentry.configureScope((scope) {
        scope.setContexts(key, value);
      });
    } catch (e) {
      Logger.error('Failed to set context', error: e);
    }
  }

  // Set tag
  Future<void> setTag(String key, String value) async {
    if (!_enabled || !_isInitialized) return;

    try {
      Sentry.configureScope((scope) {
        scope.setTag(key, value);
      });
    } catch (e) {
      Logger.error('Failed to set tag', error: e);
    }
  }

  // Performance monitoring
  Future<ISentrySpan?> startTransaction(
    String name,
    String operation, {
    Map<String, dynamic>? data,
  }) async {
    if (!_enabled || !_isInitialized) {
      // Return null if monitoring is disabled
      return null;
    }

    try {
      final transaction = Sentry.startTransaction(
        name,
        operation,
      );
      Logger.debug('Started transaction: $name');
      return transaction;
    } catch (e) {
      Logger.error('Failed to start transaction', error: e);
      return null;
    }
  }

  // Crash reporting
  Future<void> recordError(dynamic error, StackTrace stackTrace) async {
    if (!_enabled || !_isInitialized) {
      Logger.error('Error (monitoring disabled)', error: error);
      return;
    }

    try {
      Sentry.captureException(error, stackTrace: stackTrace);
      Logger.info('Error recorded');
    } catch (e) {
      Logger.error('Failed to record error', error: e);
    }
  }

  // Flush pending events
  Future<void> flush({Duration timeout = const Duration(seconds: 2)}) async {
    if (!_enabled || !_isInitialized) return;

    try {
      // Note: flush is not available in current Sentry API
      Logger.info('Sentry events flush requested');
    } catch (e) {
      Logger.error('Failed to flush events', error: e);
    }
  }

  // Close monitoring service
  Future<void> close() async {
    if (!_enabled || !_isInitialized) return;

    try {
      // Note: close is not available in current Sentry API
      Logger.info('Monitoring service closed');
    } catch (e) {
      Logger.error('Failed to close monitoring service', error: e);
    }
  }

  bool get isInitialized => _isInitialized;
  bool get isEnabled => _enabled;
}

// Integration with custom logger
class SentryLoggerAdapter {
  final MonitoringService _monitoringService;

  SentryLoggerAdapter(this._monitoringService);

  void logError(String message, {dynamic error, StackTrace? stackTrace}) {
    Logger.error(message, error: error);
    _monitoringService.captureException(
      error ?? Exception(message),
      stackTrace: stackTrace,
      hint: message,
    );
  }

  void logWarning(String message) {
    Logger.warning(message);
    _monitoringService.captureMessage(
      message,
      level: SentryLevel.warning,
    );
  }

  void logInfo(String message) {
    Logger.info(message);
    // Don't send info messages to Sentry to reduce noise
  }
}