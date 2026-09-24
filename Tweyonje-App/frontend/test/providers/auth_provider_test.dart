import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tweyonje/core/services/api_client.dart';
import 'package:tweyonje/core/services/local_auth_service.dart';
import 'package:tweyonje/core/storage/local_storage.dart';
import 'package:tweyonje/models/models.dart';
import 'package:tweyonje/providers/auth_provider.dart';

class FakeApiClient implements ApiClient {
  Future<Response> Function(String emailOrPhone, String password)? onLogin;

  @override
  Future<void> Function()? onSessionExpired;

  @override
  Future<Response> login(String emailOrPhone, String password) {
    return onLogin!(emailOrPhone, password);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}

class FakeAuthService implements LocalAuthService {
  AuthSession? sessionToReturn;
  AuthSession? sessionForCurrentUser;
  Object? loginError;

  @override
  User? get currentUser => sessionForCurrentUser?.user;

  @override
  Stream<AuthEvent> get authStateChanges => const Stream.empty();

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    if (loginError != null) {
      throw loginError!;
    }
    return sessionToReturn ??
        AuthSession(
          access: 'access-token',
          refresh: 'refresh-token',
          user: User.fromJson(_userJson),
        );
  }

  @override
  Future<bool> logout() async => true;

  @override
  Future<User?> getCurrentUser() async => sessionForCurrentUser?.user;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}

const _userJson = {
  'id': 1,
  'email': 'resident@tweyonje.ug',
  'role': 'RESIDENT',
  'full_name': 'Resident Tester',
};

const _sessionJson = {
  'access': 'access-token',
  'refresh': 'refresh-token',
  'user': _userJson,
};

Response _okResponse(Map<String, dynamic> data) => Response(
      requestOptions: RequestOptions(path: '/auth/login/'),
      statusCode: 200,
      data: data,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeApiClient api;
  late LocalStorage storage;
  late FakeAuthService auth;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    api = FakeApiClient();
    storage = LocalStorage();
    auth = FakeAuthService();
  });

  group('AuthNotifier', () {
    test('login succeeds and persists the session', () async {
      api.onLogin = (_, _) async => _okResponse(_sessionJson);

      final notifier = AuthNotifier(api, storage, auth);
      final success = await notifier.login('resident@tweyonje.ug', 'Password123!');

      expect(success, isTrue);
      expect(notifier.state.status, AuthStatus.authenticated);
      expect(notifier.state.user?.email, 'resident@tweyonje.ug');
      expect(notifier.state.errorMessage, isNull);
    });

    test('login failure surfaces the API detail message', () async {
      auth.loginError = DioException(
        requestOptions: RequestOptions(path: '/auth/login/'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login/'),
          statusCode: 400,
          data: {'detail': 'Invalid credentials'},
        ),
      );

      final notifier = AuthNotifier(api, storage, auth);
      final success = await notifier.login('resident@tweyonje.ug', 'wrong');

      expect(success, isFalse);
      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.errorMessage, 'Invalid credentials');
    });

    test('hydrate restores a stored session', () async {
      await storage.saveTokens(access: 'stored-access', refresh: 'stored-refresh');
      await storage.saveUser(User.fromJson(_userJson));

      final notifier = AuthNotifier(api, storage, auth);
      await notifier.hydrate();

      expect(notifier.state.status, AuthStatus.authenticated);
      expect(notifier.state.user?.fullName, 'Resident Tester');
      expect(await storage.getAccessToken(), 'stored-access');
    });

    test('logout clears the session', () async {
      api.onLogin = (_, _) async => _okResponse(_sessionJson);

      final notifier = AuthNotifier(api, storage, auth);
      await notifier.login('resident@tweyonje.ug', 'Password123!');

      await notifier.logout();

      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.user, isNull);
      expect(await storage.getAccessToken(), isNull);
    });

    test('session expiry signs the user out and clears storage', () async {
      api.onLogin = (_, _) async => _okResponse(_sessionJson);

      final notifier = AuthNotifier(api, storage, auth);
      await notifier.login('resident@tweyonje.ug', 'Password123!');
      expect(notifier.state.status, AuthStatus.authenticated);

      // Simulate the ApiClient interceptor invoking the callback after a
      // failed token refresh.
      await api.onSessionExpired?.call();

      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.user, isNull);
      expect(notifier.state.errorMessage, contains('expired'));
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
    });
  });

  group('User/AuthSession models', () {
    test('session parses from the login payload', () {
      final session = AuthSession.fromJson(_sessionJson);
      expect(session.access, 'access-token');
      expect(session.user.role, UserRole.resident);
    });
  });
}