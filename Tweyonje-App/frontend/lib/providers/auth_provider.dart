import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_client.dart';
import '../core/services/error_handler.dart';
import '../core/services/local_auth_service.dart';
import '../core/storage/local_storage.dart';
import '../models/models.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);

  static const _unset = Object();

  AuthState copyWith({
    AuthStatus? status,
    Object? user = _unset,
    Object? errorMessage = _unset,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: identical(user, _unset) ? this.user : user as User?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api;
  final LocalStorage _storage;
  final LocalAuthService _auth;

  AuthNotifier(this._api, this._storage, this._auth) : super(AuthState.initial()) {
    _api.onSessionExpired = _handleSessionExpired;
    _setupAuthListener();
    hydrate();
  }

  /// Listen to local auth state changes
  void _setupAuthListener() {
    _auth.authStateChanges.listen((event) {
      switch (event.type) {
        case AuthEventType.signedIn:
          _handleSignIn(event.session);
          break;
        case AuthEventType.signedOut:
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
            user: null,
          );
          break;
        case AuthEventType.tokenRefreshed:
          _handleTokenRefresh(event.session);
          break;
        case AuthEventType.userUpdated:
          _handleUserUpdate(event.session);
          break;
      }
    });
  }

  Future<void> _handleSignIn(AuthSession? session) async {
    if (session != null) {
      final user = await _auth.getCurrentUser();
      if (user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
      }
    }
  }

  Future<void> _handleTokenRefresh(AuthSession? session) async {
    if (session != null && session.access.isNotEmpty) {
      await _storage.saveAccessToken(session.access);
    }
  }

  Future<void> _handleUserUpdate(AuthSession? session) async {
    final user = await _auth.getCurrentUser();
    if (user != null) {
      state = state.copyWith(user: user);
    }
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
      // First check a locally persisted session.
      final user = await _auth.getCurrentUser();
      if (user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );

        // Optionally refresh profile from Django backend in background
        try {
          final res = await _api.getCurrentUser();
          if (res.statusCode == 200) {
            final freshUser = User.fromJson(res.data['user'] ?? res.data);
            await _storage.saveUser(freshUser);
            state = state.copyWith(user: freshUser);
          }
        } catch (_) {}
        return;
      }

      // Fallback to local storage
      final token = await _storage.getAccessToken();
      final cachedUser = await _storage.getUser();

      if (token != null && cachedUser != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: cachedUser,
        );

        // Optionally refresh profile from API in background
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

  /// Login via local auth
  Future<bool> login(String emailOrPhone, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      // Use local SQLite-backed authentication
      final session = await _auth.login(
        email: emailOrPhone,
        password: password,
      );

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: session.user,
      );
      return true;
    } catch (e) {
      String msg = 'Invalid credentials. Please verify your email and password.';
      if (e is AuthenticationException) {
        msg = e.message;
      } else if (e is DioException) {
        final data = e.response?.data;
        if (data is Map) {
          msg = data['detail'] ??
              (data['email'] is List ? data['email'][0] : null) ??
              (data['non_field_errors'] is List ? data['non_field_errors'][0] : null) ??
              data.values.first.toString();
        }
      }
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: msg,
      );
      return false;
    }
  }

  /// Register via local auth
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      // Use local SQLite-backed registration
      final session = await _auth.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone ?? '',
        role: UserRole.values.firstWhere(
          (r) => r.value == role,
          orElse: () => UserRole.resident,
        ),
      );

      // Also register in Django backend (for business logic)
      try {
        await _api.register(
          email: email,
          password: password,
          fullName: fullName,
          role: role,
          phone: phone,
        );
      } catch (_) {
        // Django registration is optional - local auth is primary
      }

      if (session.access.isNotEmpty) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: session.user,
        );
      } else {
        // Account created but not yet usable
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
      return true;
    } catch (e) {
      String msg = 'Registration failed. Please try again.';
      if (e is AuthenticationException) {
        msg = e.message;
      } else if (e is DioException) {
        final data = e.response?.data;
        if (data is Map) {
          msg = data['detail'] ??
              (data['email'] is List ? data['email'][0] : null) ??
              (data['password'] is List ? data['password'][0] : null) ??
              (data['non_field_errors'] is List ? data['non_field_errors'][0] : null) ??
              data.values.first.toString();
        }
      }
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: msg,
      );
      return false;
    }
  }

  /// Logout from local auth
  Future<void> logout() async {
    await _auth.logout();
    await _storage.clearSession();
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      user: null,
    );
  }

  /// Send OTP for phone verification
  Future<bool> sendOTP(String phone) async {
    return await _auth.sendOTP(phone: phone);
  }

  /// Verify OTP
  Future<bool> verifyOTP(String phone, String token) async {
    return await _auth.verifyOTP(phone: phone, token: token);
  }

  /// Update password
  Future<bool> updatePassword(String newPassword) async {
    return await _auth.updatePassword(newPassword: newPassword);
  }

  /// Request password reset
  Future<bool> requestPasswordReset(String email) async {
    return await _auth.requestPasswordReset(email: email);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final api = ref.watch(apiClientProvider);
  final storage = LocalStorage();
  final auth = ref.watch(localAuthServiceProvider);
  return AuthNotifier(api, storage, auth);
});