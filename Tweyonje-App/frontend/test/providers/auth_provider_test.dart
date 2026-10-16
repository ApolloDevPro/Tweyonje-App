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
  Future<Response> Function({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
    String? consentPolicyVersion,
    String preferredLanguage,
  })? onRegister;
  Future<Response> Function(String refreshToken)? onLogout;
  Future<Response> Function(String token)? onRegisterDevice;
  Future<Response> Function(String token)? onUnregisterDevice;

  @override
  Future<void> Function()? onSessionExpired;

  @override
  Future<Response> login(String emailOrPhone, String password) {
    return onLogin!(emailOrPhone, password);
  }

  @override
  Future<Response> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
    String? consentPolicyVersion,
    String preferredLanguage = 'en',
  }) {
    return onRegister!(
      email: email,
      password: password,
      fullName: fullName,
      role: role,
      phone: phone,
      consentPolicyVersion: consentPolicyVersion,
      preferredLanguage: preferredLanguage,
    );
  }

  @override
  Future<Response> logout(String refreshToken) {
    return onLogout!(refreshToken);
  }

  @override
  Future<Response> registerDevice(String token) {
    return onRegisterDevice!(token);
  }

  @override
  Future<Response> unregisterDevice(String token) {
    return onUnregisterDevice!(token);
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
      final success = await notifier.login(
        'resident@tweyonje.ug',
        'Password123!',
      );

      expect(success, isTrue);
      expect(notifier.state.status, AuthStatus.authenticated);
      expect(notifier.state.user?.email, 'resident@tweyonje.ug');
      expect(notifier.state.errorMessage, isNull);
      expect(await storage.getAccessToken(), 'access-token');
      expect(await storage.getRefreshToken(), 'refresh-token');
    });

    test('login failure surfaces the API detail message', () async {
      api.onLogin = (_, _) => Future.error(
        DioException(
          requestOptions: RequestOptions(path: '/auth/login/'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/auth/login/'),
            statusCode: 400,
            data: {'detail': 'Invalid credentials'},
          ),
        ),
      );

      final notifier = AuthNotifier(api, storage, auth);
      final success = await notifier.login('resident@tweyonje.ug', 'wrong');

      expect(success, isFalse);
      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.errorMessage, 'Invalid credentials');
    });

    test('login registers a push token captured before authentication', () async {
      await storage.saveFCMToken('device-token');
      api.onLogin = (_, _) async => _okResponse(_sessionJson);
      String? registeredToken;
      api.onRegisterDevice = (token) async {
        registeredToken = token;
        return Response(
          requestOptions: RequestOptions(path: '/notifications/register_device/'),
          statusCode: 201,
        );
      };

      final notifier = AuthNotifier(api, storage, auth);
      final success = await notifier.login('resident@tweyonje.ug', 'Password123!');

      expect(success, isTrue);
      expect(registeredToken, 'device-token');
    });

    test('registration creates the backend session and persists it', () async {
      api.onRegister = ({
        required email,
        required password,
        required fullName,
        required role,
        phone,
        consentPolicyVersion,
        preferredLanguage = 'en',
      }) async =>
          _okResponse(_sessionJson);

      final notifier = AuthNotifier(api, storage, auth);
      final success = await notifier.register(
        email: 'resident@tweyonje.ug',
        password: 'Password123!',
        fullName: 'Resident Tester',
        role: 'RESIDENT',
      );

      expect(success, isTrue);
      expect(notifier.state.status, AuthStatus.authenticated);
      expect(await storage.getAccessToken(), 'access-token');
      expect(await storage.getRefreshToken(), 'refresh-token');
    });

    test('hydrate restores a stored session', () async {
      await storage.saveTokens(
        access: 'stored-access',
        refresh: 'stored-refresh',
      );
      await storage.saveUser(User.fromJson(_userJson));

      final notifier = AuthNotifier(api, storage, auth);
      await notifier.hydrate();

      expect(notifier.state.status, AuthStatus.authenticated);
      expect(notifier.state.user?.fullName, 'Resident Tester');
      expect(await storage.getAccessToken(), 'stored-access');
    });

    test('logout clears the session', () async {
      api.onLogin = (_, _) async => _okResponse(_sessionJson);
      String? revokedRefreshToken;
      api.onLogout = (refreshToken) async {
        revokedRefreshToken = refreshToken;
        return Response(
          requestOptions: RequestOptions(path: '/auth/logout/'),
          statusCode: 204,
        );
      };

      final notifier = AuthNotifier(api, storage, auth);
      await notifier.login('resident@tweyonje.ug', 'Password123!');

      await notifier.logout();

      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.user, isNull);
      expect(await storage.getAccessToken(), isNull);
      expect(revokedRefreshToken, 'refresh-token');
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
