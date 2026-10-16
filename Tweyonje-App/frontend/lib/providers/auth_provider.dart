import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_client.dart';
import '../core/services/error_handler.dart';
import '../core/services/logger.dart';
import '../core/services/local_auth_service.dart';
import '../core/storage/local_storage.dart';
import '../models/models.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  /// Per-field validation errors from the API, keyed by DRF field name
  /// (e.g. `email`, `phone`, `password`) so screens can render inline errors.
  final Map<String, String> fieldErrors;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.fieldErrors = const {},
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);

  static const _unset = Object();

  AuthState copyWith({
    AuthStatus? status,
    Object? user = _unset,
    Object? errorMessage = _unset,
    Map<String, String>? fieldErrors,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: identical(user, _unset) ? this.user : user as User?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api;
  final LocalStorage _storage;
  final LocalAuthService _auth;

  AuthNotifier(this._api, this._storage, this._auth)
    : super(AuthState.initial()) {
    _api.onSessionExpired = _handleSessionExpired;
    hydrate();
  }

  Future<void> _handleSessionExpired() async {
    await _storage.clearSession();
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      user: null,
      errorMessage: 'Your session has expired. Please sign in again.',
    );
  }

  /// Hydrate auth state from the local database / local storage
  Future<void> hydrate() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final token = await _storage.getAccessToken();
      final cachedUser = await _storage.getUser();

      if (token != null && cachedUser != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: cachedUser,
        );

        // Keep the cached profile available offline; a rejected token is
        // cleared by ApiClient's session-expiry callback.
        try {
          final res = await _api.getCurrentUser();
          if (res.statusCode == 200) {
            final freshUser = User.fromJson(res.data['user'] ?? res.data);
            await _storage.saveUser(freshUser);
            state = state.copyWith(user: freshUser);
          }
        } catch (_) {}
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  /// Authenticate against the Django API and persist its JWT session.
  Future<bool> login(String emailOrPhone, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _api.login(emailOrPhone, password);
      final session = AuthSession.fromJson(response.data);
      if (session.access.isEmpty || session.refresh.isEmpty) {
        throw const FormatException(
          'The server returned an incomplete login session.',
        );
      }
      await _storage.saveTokens(
        access: session.access,
        refresh: session.refresh,
      );
      await _storage.saveUser(session.user);
      await _syncPushToken();

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: session.user,
        fieldErrors: const {},
      );
      return true;
    } catch (e) {
      final msg = _errorMessage(
        e,
        fallback: 'Invalid credentials. Please verify your email and password.',
      );
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: msg,
        fieldErrors: _fieldErrors(e),
      );
      return false;
    }
  }

  /// Register an account on the Django API and persist its JWT session.
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
    String? consentPolicyVersion,
    String preferredLanguage = 'en',
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _api.register(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        phone: phone,
        consentPolicyVersion: consentPolicyVersion,
        preferredLanguage: preferredLanguage,
      );
      final session = AuthSession.fromJson(response.data);
      if (session.access.isEmpty || session.refresh.isEmpty) {
        throw const FormatException(
          'The server returned an incomplete registration session.',
        );
      }
      await _storage.saveTokens(
        access: session.access,
        refresh: session.refresh,
      );
      await _storage.saveUser(session.user);
      await _syncPushToken();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: session.user,
        fieldErrors: const {},
      );
      return true;
    } catch (e) {
      final msg = _errorMessage(
        e,
        fallback: 'Registration failed. Please try again.',
      );
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: msg,
        fieldErrors: _fieldErrors(e),
      );
      return false;
    }
  }

  /// Revoke the server refresh token, then clear both remote and local session state.
  Future<void> logout() async {
    final refreshToken = await _storage.getRefreshToken();
    final pushToken = await _storage.getFCMToken();
    try {
      if (pushToken != null && pushToken.isNotEmpty) {
        await _api.unregisterDevice(pushToken);
      }
    } catch (e, st) {
      Logger.error(
        'Could not unregister push token during logout',
        error: e,
        stackTrace: st,
      );
    }
    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _api.logout(refreshToken);
      }
    } catch (e, st) {
      Logger.error(
        'Server logout failed; clearing local session',
        error: e,
        stackTrace: st,
      );
    } finally {
      await _auth.logout();
      await _storage.clearSession();
      state = state.copyWith(status: AuthStatus.unauthenticated, user: null);
    }
  }

  /// Send an OTP to [identifier] (email or phone) for the given [purpose].
  ///
  /// Returns the response payload so callers can surface `message` and, in
  /// DEBUG builds with `OTP_DEBUG_ECHO`, the `dev_code`.
  Future<Map<String, dynamic>?> sendOtp(
    String identifier, {
    String purpose = 'PHONE_VERIFY',
  }) async {
    final res = await _api.sendOtp(identifier, purpose: purpose);
    return res.data is Map ? Map<String, dynamic>.from(res.data as Map) : null;
  }

  /// Verify an OTP previously sent to [identifier].
  Future<bool> verifyOtp(
    String identifier,
    String code, {
    String purpose = 'PHONE_VERIFY',
  }) async {
    await _api.verifyOtp(identifier, code, purpose: purpose);
    return true;
  }

  /// Request a password-reset email. Returns the server `dev_token` when the
  /// backend exposes one (DEBUG builds); `null` otherwise.
  Future<String?> requestPasswordReset(String email) async {
    final res = await _api.requestPasswordReset(email);
    final data = res.data;
    if (data is Map && data['dev_token'] is String) {
      return data['dev_token'] as String;
    }
    return null;
  }

  /// Confirm a password reset with the token emailed to the user.
  Future<bool> confirmPasswordReset({
    required String token,
    required String newPassword,
  }) async {
    await _api.confirmPasswordReset(token: token, newPassword: newPassword);
    return true;
  }

  void clearError() {
    state = state.copyWith(errorMessage: null, fieldErrors: const {});
  }

  String _errorMessage(Object error, {required String fallback}) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final detail = data['detail'];
        if (detail is String && detail.isNotEmpty) return detail;
        for (final value in data.values) {
          if (value is List && value.isNotEmpty) return value.first.toString();
          if (value is String && value.isNotEmpty) return value;
        }
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Connection timed out. Please check your network and try again.';
      }
    }
    if (error is FormatException) return error.message;
    if (error is AuthenticationException) return error.message;
    return fallback;
  }

  /// Extracts `{field: message}` pairs from a DRF validation-error payload.
  Map<String, String> _fieldErrors(Object error) {
    if (error is! DioException) return const {};
    final data = error.response?.data;
    if (data is! Map) return const {};
    final result = <String, String>{};
    data.forEach((key, value) {
      if (key is! String) return;
      if (value is List && value.isNotEmpty) {
        result[key] = value.first.toString();
      } else if (value is String && value.isNotEmpty) {
        result[key] = value;
      }
    });
    return result;
  }

  Future<void> _syncPushToken() async {
    try {
      final token = await _storage.getFCMToken();
      if (token != null && token.isNotEmpty) {
        await _api.registerDevice(token);
      }
    } catch (error, stackTrace) {
      Logger.error(
        'Could not register the saved push token after authentication',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final api = ref.watch(apiClientProvider);
  final storage = LocalStorage();
  final auth = ref.watch(localAuthServiceProvider);
  return AuthNotifier(api, storage, auth);
});
