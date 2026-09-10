import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_client.dart';
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

  AuthNotifier(this._api, this._storage) : super(AuthState.initial()) {
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

  Future<bool> login(String emailOrPhone, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final res = await _api.login(emailOrPhone, password);
      if (res.statusCode == 200) {
        final session = AuthSession.fromJson(res.data);
        await _storage.saveTokens(
          access: session.access,
          refresh: session.refresh,
        );
        await _storage.saveUser(session.user);

        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: session.user,
        );
        return true;
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: res.data['detail'] ?? 'Invalid credentials',
        );
        return false;
      }
    } catch (e) {
      String msg = 'Invalid credentials. Please verify your email and password.';
      if (e is DioException) {
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

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final res = await _api.register(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        phone: phone,
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        if (res.data['access'] != null) {
          final session = AuthSession.fromJson(res.data);
          await _storage.saveTokens(
            access: session.access,
            refresh: session.refresh,
          );
          await _storage.saveUser(session.user);

          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: session.user,
          );
        } else {
          state = state.copyWith(status: AuthStatus.unauthenticated);
        }
        return true;
      }
      return false;
    } catch (e) {
      String msg = 'Registration failed. Please try again.';
      if (e is DioException) {
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

  Future<void> logout() async {
    await _storage.clearSession();
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      user: null,
    );
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final api = ref.watch(apiClientProvider);
  final storage = LocalStorage();
  return AuthNotifier(api, storage);
});
