/// API base URL and endpoint constants.
class ApiConstants {
  ApiConstants._();

  /// Base URL. Override at build time with:
  /// `flutter run --dart-define=API_URL=https://api.tweyonje.ug`
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
  static const String apiVersion = '/api/v1';
  static const String apiBaseUrl = '$baseUrl$apiVersion';

  /// WebSocket URL. Override at build time with:
  /// `flutter run --dart-define=WS_URL=wss://api.tweyonje.ug/ws/`
  static const String wsBaseUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'ws://127.0.0.1:8000/ws/',
  );

  /// Google Maps API key (unused by the default OpenStreetMap tile layer).
  /// Set at build time with `--dart-define=GOOGLE_MAPS_API_KEY=...`.
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  /// API Documentation.
  static const String docsUrl = '$baseUrl/api/docs/';
  static const String schemaUrl = '$baseUrl/api/schema/';
}

/// App-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'Tweyonje';
  static const String appTagline = 'Together for a Cleaner Uganda';
  static const String currency = 'UGX';
  static const String countryCode = '+256';

  /// Pagination defaults.
  static const int defaultPageSize = 20;

  /// Timeouts.
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  /// Storage keys.
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String fcmTokenKey = 'fcm_token';
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String biometricEnabledKey = 'biometric_enabled';
  static const String notificationsEnabledKey = 'notifications_enabled';
  static const String themeModeKey = 'theme_mode';
  static const String languageKey = 'app_language';
}
