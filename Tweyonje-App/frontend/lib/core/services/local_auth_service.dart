import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../storage/storage_service.dart';
import '../../models/models.dart';
import 'biometric_service.dart';
import 'error_handler.dart';
import 'logger.dart';
import 'password_hasher.dart';

/// Auth events published by [LocalAuthService].
enum AuthEventType { signedIn, signedOut, tokenRefreshed, userUpdated }

/// A single local auth state change, mirroring the shape the app consumed
/// from Supabase so callers keep working after the swap.
class AuthEvent {
  final AuthEventType type;
  final AuthSession? session;

  const AuthEvent(this.type, [this.session]);
}

/// Local authentication backed by the shared SQLite database.
///
/// Replaces Supabase auth entirely: accounts and sessions live in the local
/// `users` / `auth_sessions` tables, and passwords are stored as salted
/// PBKDF2-HMAC-SHA256 hashes (legacy SHA-256 hashes are upgraded on next
/// sign-in). The public surface matches the previous `SupabaseAuthService` so
/// the rest of the app is wired unchanged.
class LocalAuthService {
  final StorageService _storageService;
  final BiometricService _biometricService;
  final PasswordHasher _passwordHasher;

  final _authStateController = StreamController<AuthEvent>.broadcast();

  User? _currentUser;

  LocalAuthService(
    this._storageService,
    this._biometricService, {
    PasswordHasher? passwordHasher,
  }) : _passwordHasher = passwordHasher ?? PasswordHasher();

  /// Stream of local auth state changes.
  Stream<AuthEvent> get authStateChanges => _authStateController.stream;

  /// Currently signed-in user (from memory), or null.
  User? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;

  /// Sign in with email (or phone) and password against the local database.
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      Logger.info('Attempting local login for: $email');

      final db = await AppDatabase.instance.database;
      final identifier = email.trim();
      final rows = await db.query(
        'users',
        where: 'LOWER(email) = LOWER(?) OR phone = ?',
        whereArgs: [identifier, identifier],
        limit: 1,
      );

      if (rows.isEmpty) {
        throw AuthenticationException(
          message: 'Invalid credentials. Please verify your email and password.',
        );
      }

      final storedHash = rows.first['password_hash'] as String?;
      if (storedHash == null) {
        throw AuthenticationException(
          message: 'Invalid credentials. Please verify your email and password.',
        );
      }

      final verification = _passwordHasher.verify(password, storedHash);
      if (!verification.verified) {
        throw AuthenticationException(
          message: 'Invalid credentials. Please verify your email and password.',
        );
      }

      final user = _userFromRow(rows.first);

      // Transparently rehash legacy/weak hashes with the current work factor.
      if (verification.needsUpgrade) {
        await db.update(
          'users',
          {'password_hash': _passwordHasher.hash(password)},
          where: 'id = ?',
          whereArgs: [user.id],
        );
        Logger.info('Upgraded password hash for: $email');
      }

      final session = await _createSession(user, db);

      _currentUser = user;
      _emit(AuthEvent(AuthEventType.signedIn, session));

      await _storageService.saveTokens(access: session.access, refresh: session.refresh);
      await _storageService.saveUser(user);

      Logger.info('Local login successful for: $email');
      return session;
    } catch (e) {
      Logger.error('Local login failed', error: e);

      if (e is AuthenticationException) {
        rethrow;
      }

      throw AuthenticationException(message: 'Login failed: $e');
    }
  }

  /// Register a new local account and sign the user in.
  Future<AuthSession> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required UserRole role,
  }) async {
    try {
      Logger.info('Attempting local registration for: $email');

      final db = await AppDatabase.instance.database;
      final normalizedEmail = email.trim();

      final existing = await db.query(
        'users',
        where: 'LOWER(email) = LOWER(?)',
        whereArgs: [normalizedEmail],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        throw AuthenticationException(
          message: 'An account with this email already exists.',
        );
      }

      final now = DateTime.now().toIso8601String();
      final id = await db.insert('users', {
        'email': normalizedEmail,
        'password_hash': _passwordHasher.hash(password),
        'full_name': fullName,
        'first_name': fullName.split(' ').first,
        'last_name': fullName.split(' ').length > 1 ? fullName.split(' ').last : null,
        'phone': phone,
        'role': role.value,
        'phone_verified': 0,
        'email_verified': 0,
        'date_joined': now,
        'created_at': now,
      });

      final user = User(
        id: id,
        email: normalizedEmail,
        fullName: fullName,
        firstName: fullName.split(' ').first,
        lastName: fullName.split(' ').length > 1 ? fullName.split(' ').last : null,
        phone: phone,
        role: role,
      );

      final session = await _createSession(user, db);

      _currentUser = user;
      _emit(AuthEvent(AuthEventType.signedIn, session));

      await _storageService.saveTokens(access: session.access, refresh: session.refresh);
      await _storageService.saveUser(user);

      Logger.info('Local registration successful for: $email');
      return session;
    } catch (e) {
      Logger.error('Local registration failed', error: e);

      if (e is AuthenticationException) {
        rethrow;
      }

      throw AuthenticationException(message: 'Registration failed: $e');
    }
  }

  /// Sign out and clear the local session.
  Future<bool> logout() async {
    try {
      Logger.info('Attempting local logout');

      try {
        final db = await AppDatabase.instance.database;
        await db.delete('auth_sessions');
      } catch (e) {
        Logger.error('Local logout: failed to clear sessions', error: e);
      }

      _currentUser = null;
      await _storageService.clearAuthData();
      await _biometricService.disableBiometric();
      _emit(const AuthEvent(AuthEventType.signedOut));

      Logger.info('Local logout successful');
      return true;
    } catch (e) {
      Logger.error('Local logout failed', error: e);

      try {
        await _storageService.clearAuthData();
        await _biometricService.disableBiometric();
      } catch (_) {}
      _currentUser = null;

      return true;
    }
  }

  /// Refresh the local session token.
  Future<bool> refreshToken() async {
    try {
      Logger.info('Attempting local token refresh');

      final user = _currentUser;
      if (user == null) {
        Logger.warning('Local token refresh failed: no active user');
        return false;
      }

      _emit(
        AuthEvent(
          AuthEventType.tokenRefreshed,
          AuthSession(access: _randomHex(24), refresh: _randomHex(24), user: user),
        ),
      );

      Logger.info('Local token refresh successful');
      return true;
    } catch (e) {
      Logger.error('Local token refresh failed', error: e);
      return false;
    }
  }

  /// No email infrastructure is available on a fully local app.
  Future<bool> requestPasswordReset({required String email}) async {
    Logger.warning('Password reset is not available in offline mode');
    return false;
  }

  /// Update the current user's local password.
  Future<bool> updatePassword({required String newPassword}) async {
    try {
      Logger.info('Attempting to update password');

      final db = await AppDatabase.instance.database;
      final user = _currentUser;
      if (user == null) {
        Logger.warning('Password update failed: no active user');
        return false;
      }

      await db.update(
        'users',
        {'password_hash': _passwordHasher.hash(newPassword)},
        where: 'id = ?',
        whereArgs: [user.id],
      );

      _emit(const AuthEvent(AuthEventType.userUpdated));
      Logger.info('Password update successful');
      return true;
    } catch (e) {
      Logger.error('Password update failed', error: e);
      return false;
    }
  }

  /// Update the current user's profile in the local database.
  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? preferredLanguage,
  }) async {
    try {
      Logger.info('Attempting to update profile');

      final db = await AppDatabase.instance.database;
      final cachedUser = _currentUser;
      if (cachedUser == null) {
        Logger.warning('Profile update failed: no active user');
        return false;
      }

      final updates = <String, Object?>{
        'full_name': ?fullName,
        'phone': ?phone,
        'preferred_language': ?preferredLanguage,
      };
      await db.update(
        'users',
        updates,
        where: 'id = ?',
        whereArgs: [cachedUser.id],
      );

      final updatedUser = User(
        id: cachedUser.id,
        email: cachedUser.email,
        fullName: fullName ?? cachedUser.fullName,
        firstName:
            fullName?.split(' ').first ?? cachedUser.firstName,
        lastName: (fullName?.split(' ').length ?? 0) > 1
            ? fullName!.split(' ').last
            : cachedUser.lastName,
        phone: phone ?? cachedUser.phone,
        role: cachedUser.role,
        preferredLanguage: preferredLanguage ?? cachedUser.preferredLanguage,
        phoneVerified: cachedUser.phoneVerified,
        emailVerified: cachedUser.emailVerified,
        dateJoined: cachedUser.dateJoined,
      );
      _currentUser = updatedUser;
      await _storageService.saveUser(updatedUser);

      _emit(
        AuthEvent(
          AuthEventType.userUpdated,
          AuthSession(
            access: _randomHex(24),
            refresh: _randomHex(24),
            user: updatedUser,
          ),
        ),
      );

      Logger.info('Profile update successful');
      return true;
    } catch (e) {
      Logger.error('Profile update failed', error: e);
      return false;
    }
  }

  /// Phone OTP requires an SMS provider, which is unavailable offline.
  Future<bool> sendOTP({required String phone}) async {
    Logger.warning('Phone OTP is not available in offline mode');
    return false;
  }

  /// Phone OTP requires an SMS provider, which is unavailable offline.
  Future<bool> verifyOTP({
    required String phone,
    required String token,
  }) async {
    Logger.warning('Phone OTP is not available in offline mode');
    return false;
  }

  /// Enable biometric authentication.
  Future<bool> enableBiometricAuth() async {
    try {
      Logger.info('Attempting to enable biometric auth');

      final isAvailable = await _biometricService.isBiometricAvailable();
      if (!isAvailable) {
        Logger.warning('Biometric authentication not available');
        return false;
      }

      final isAuthenticated = await _biometricService.authenticate();
      if (!isAuthenticated) {
        Logger.warning('Biometric authentication failed');
        return false;
      }

      await _biometricService.enableBiometric();

      Logger.info('Biometric authentication enabled');
      return true;
    } catch (e) {
      Logger.error('Failed to enable biometric auth', error: e);
      return false;
    }
  }

  /// Disable biometric authentication.
  Future<bool> disableBiometricAuth() async {
    try {
      await _biometricService.disableBiometric();
      Logger.info('Biometric authentication disabled');
      return true;
    } catch (e) {
      Logger.error('Failed to disable biometric auth', error: e);
      return false;
    }
  }

  /// Check if biometric is enabled.
  Future<bool> isBiometricEnabled() async {
    return await _biometricService.isBiometricEnabled();
  }

  /// Authenticate with biometric.
  Future<bool> authenticateWithBiometric() async {
    try {
      Logger.info('Attempting biometric authentication');

      final isEnabled = await _biometricService.isBiometricEnabled();
      if (!isEnabled) {
        Logger.warning('Biometric authentication not enabled');
        return false;
      }

      final isAuthenticated = await _biometricService.authenticate();

      if (isAuthenticated) {
        Logger.info('Biometric authentication successful');
        return true;
      } else {
        Logger.warning('Biometric authentication failed');
        return false;
      }
    } catch (e) {
      Logger.error('Biometric authentication error', error: e);
      return false;
    }
  }

  /// Get the current user from the local session (or memory).
  Future<User?> getCurrentUser() async {
    try {
      final db = await AppDatabase.instance.database;
      final rows = await db.rawQuery('''
        SELECT u.* FROM auth_sessions s
        JOIN users u ON u.id = s.user_id
        ORDER BY s.created_at DESC LIMIT 1
      ''');
      if (rows.isEmpty) return _currentUser;

      final user = _userFromRow(rows.first);
      _currentUser = user;
      return user;
    } catch (e) {
      Logger.error('Failed to get current user', error: e);
      return _currentUser;
    }
  }

  /// Check if the user is signed in.
  Future<bool> isAuthenticatedAsync() async {
    final user = await getCurrentUser();
    return user != null;
  }

  User _userFromRow(Map<String, Object?> row) {
    return User(
      id: row['id'] as int,
      email: row['email'] as String,
      phone: row['phone'] as String?,
      fullName: row['full_name'] as String,
      firstName: row['first_name'] as String?,
      lastName: row['last_name'] as String?,
      role: UserRole.fromString(row['role'] as String? ?? 'RESIDENT'),
      preferredLanguage: row['preferred_language'] as String?,
      phoneVerified: (row['phone_verified'] as int? ?? 0) == 1,
      emailVerified: (row['email_verified'] as int? ?? 0) == 1,
      dateJoined: row['date_joined'] as String?,
    );
  }

  Future<AuthSession> _createSession(User user, Database db) async {
    final access = _randomHex(24);
    final refresh = _randomHex(24);
    await db.insert('auth_sessions', {
      'access': access,
      'refresh': refresh,
      'user_id': user.id,
      'created_at': DateTime.now().toIso8601String(),
    });
    return AuthSession(access: access, refresh: refresh, user: user);
  }

  String _randomHex(int bytes) {
    final random = Random.secure();
    final buffer = StringBuffer();
    for (int i = 0; i < bytes; i++) {
      buffer.write(random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  void _emit(AuthEvent event) {
    if (!_authStateController.isClosed) {
      _authStateController.add(event);
    }
  }
}

final localAuthServiceProvider = Provider<LocalAuthService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final biometricService = ref.watch(biometricServiceProvider);

  return LocalAuthService(storageService, biometricService);
});