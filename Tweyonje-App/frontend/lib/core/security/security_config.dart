import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class SecurityConfig {
  static SecurityConfig? _instance;
  static SecurityConfig get instance => _instance ??= SecurityConfig._internal();
  
  SecurityConfig._internal();

  bool _isProduction = false;
  bool _sslPinningEnabled = false;
  List<String>? _allowedDomains;

  void initialize({
    required bool isProduction,
    bool sslPinningEnabled = true,
    List<String>? allowedDomains,
  }) {
    _isProduction = isProduction;
    _sslPinningEnabled = sslPinningEnabled && isProduction;
    _allowedDomains = allowedDomains;
    
    if (kDebugMode) {
      print('Security Config Initialized:');
      print('  Production: $_isProduction');
      print('  SSL Pinning: $_sslPinningEnabled');
      print('  Allowed Domains: $_allowedDomains');
    }
  }

  bool get isProduction => _isProduction;
  bool get sslPinningEnabled => _sslPinningEnabled;
  List<String>? get allowedDomains => _allowedDomains;

  // Validate URL to prevent open redirects
  bool isValidUrl(String url) {
    if (_allowedDomains == null || _allowedDomains!.isEmpty) {
      return true; // Allow all if no restrictions
    }

    try {
      final uri = Uri.parse(url);
      return _allowedDomains!.any((domain) => uri.host.endsWith(domain));
    } catch (e) {
      return false;
    }
  }

  // Sanitize user input
  String sanitizeInput(String input) {
    // Basic sanitization - in production use more sophisticated methods
    return input
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<[^>]+>'), '');
  }

  // Validate file type
  bool isValidFileType(String fileName, List<String> allowedExtensions) {
    final extension = fileName.split('.').last.toLowerCase();
    return allowedExtensions.contains(extension);
  }

  // Rate limiting configuration
  int getMaxRequestsPerMinute() {
    return _isProduction ? 60 : 120; // More lenient in development
  }

  int getMaxLoginAttempts() {
    return 5;
  }

  Duration getLockoutDuration() {
    return const Duration(minutes: 15);
  }
}

class SecurityInterceptor extends Interceptor {
  final SecurityConfig config;

  SecurityInterceptor(this.config);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add security headers
    options.headers['X-Requested-With'] = 'XMLHttpRequest';
    
    // Validate URL in production
    if (config.isProduction && !config.isValidUrl(options.uri.toString())) {
      handler.reject(DioException(
        requestOptions: options,
        error: 'Invalid URL detected',
      ));
      return;
    }

    // Add CSRF token if available (implement as needed)
    // options.headers['X-CSRF-Token'] = _getCsrfToken();

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Check for security headers in response
    final headers = response.headers;

    if (config.isProduction && headers.value('X-Content-Type-Options') != null) {
      // Security headers present; validation can be extended here.
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Log security-related errors
    if (err.type == DioExceptionType.badCertificate && config.sslPinningEnabled) {
      // SSL certificate error
      debugPrint('Security: SSL certificate validation failed');
    }

    handler.next(err);
  }
}