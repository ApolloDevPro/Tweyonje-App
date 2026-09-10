import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../storage/storage_service.dart';
import '../../models/models.dart';
import '../constants/api_endpoints.dart';
import 'biometric_service.dart';
import 'error_handler.dart';
import 'logger.dart';

/// Supabase Auth Service - handles authentication via Supabase
/// while keeping Django backend for business logic
class SupabaseAuthService {
  final SupabaseClient _supabase;
  final StorageService _storageService;
  final BiometricService _biometricService;

  SupabaseAuthService(this._supabase, this._storageService, this._biometricService);

  /// Get current Supabase user
  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;
  bool get isAuthenticated => currentUser != null;

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange.map(
        (event) => AuthState(
          event.event,
          event.session,
        ),
      );

  /// Sign in with email/password via Supabase
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      Logger.info('Attempting Supabase login for: $email');

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null && response.session != null) {
        // Create user model from Supabase user
        final user = User(
          id: int.parse(response.user!.id.hashCode.toString().substring(0, 8)),
          email: response.user!.email ?? '',
          fullName: response.user!.userMetadata?['full_name'] as String? ?? '',
          firstName: response.user!.userMetadata?['first_name'] as String?,
          lastName: response.user!.userMetadata?['last_name'] as String?,
          phone: response.user!.phone,
          role: UserRole.values.firstWhere(
            (r) => r.value == (response.user!.userMetadata?['role'] ?? 'RESIDENT'),
            orElse: () => UserRole.resident,
          ),
          phoneVerified: response.user!.phoneConfirmedAt != null,
          emailVerified: response.user!.emailConfirmedAt != null,
        );

        // Create auth session
        final authSession = AuthSession(
          access: response.session!.accessToken,
          refresh: response.session!.refreshToken,
          user: user,
        );

        // Save to local storage for offline access
        await _storageService.saveTokens(
          access: authSession.access,
          refresh: authSession.refresh,
        );
        await _storageService.saveUser(authSession.user);

        Logger.info('Supabase login successful for: $email');
        return authSession;
      } else {
        throw AuthenticationException(message: 'Login failed');
      }
    } catch (e) {
      Logger.error('Supabase login failed', error: e);
      
      if (e is AuthenticationException) {
        rethrow;
      }
      
      throw AuthenticationException(message: 'Login failed: $e');
    }
  }

  /// Sign up with email/password via Supabase
  Future<AuthSession> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required UserRole role,
  }) async {
    try {
      Logger.info('Attempting Supabase registration for: $email');

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'first_name': fullName.split(' ').first,
          'last_name': fullName.split(' ').length > 1 ? fullName.split(' ').last : null,
          'phone': phone,
          'role': role.value,
        },
      );

      if (response.user != null) {
        // Create user model
        final user = User(
          id: int.parse(response.user!.id.hashCode.toString().substring(0, 8)),
          email: response.user!.email ?? '',
          fullName: fullName,
          firstName: fullName.split(' ').first,
          lastName: fullName.split(' ').length > 1 ? fullName.split(' ').last : null,
          phone: phone,
          role: role,
          phoneVerified: false,
          emailVerified: false,
        );

        // Create auth session (may need email confirmation)
        final authSession = AuthSession(
          access: response.session?.accessToken ?? '',
          refresh: response.session?.refreshToken ?? '',
          user: user,
        );

        // Save to local storage if session exists
        if (response.session != null) {
          await _storageService.saveTokens(
            access: authSession.access,
            refresh: authSession.refresh,
          );
          await _storageService.saveUser(authSession.user);
        }

        Logger.info('Supabase registration successful for: $email');
        return authSession;
      } else {
        throw AuthenticationException(message: 'Registration failed');
      }
    } catch (e) {
      Logger.error('Supabase registration failed', error: e);
      
      if (e is AuthenticationException) {
        rethrow;
      }
      
      throw AuthenticationException(message: 'Registration failed: $e');
    }
  }

  /// Sign out from Supabase
  Future<bool> logout() async {
    try {
      Logger.info('Attempting Supabase logout');

      await _supabase.auth.signOut();

      // Clear local storage
      await _storageService.clearAuthData();
      
      // Disable biometric if enabled
      await _biometricService.disableBiometric();

      Logger.info('Supabase logout successful');
      return true;
    } catch (e) {
      Logger.error('Supabase logout failed', error: e);
      
      // Even if Supabase call fails, clear local data
      await _storageService.clearAuthData();
      await _biometricService.disableBiometric();
      
      return true;
    }
  }

  /// Refresh Supabase session
  Future<bool> refreshToken() async {
    try {
      Logger.info('Attempting Supabase token refresh');

      final response = await _supabase.auth.refreshSession();

      if (response.session != null) {
        await _storageService.saveAccessToken(response.session!.accessToken);
        
        Logger.info('Supabase token refresh successful');
        return true;
      } else {
        Logger.warning('Supabase token refresh failed');
        return false;
      }
    } catch (e) {
      Logger.error('Supabase token refresh failed', error: e);
      return false;
    }
  }

  /// Send password reset email via Supabase
  Future<bool> requestPasswordReset({required String email}) async {
    try {
      Logger.info('Attempting to request password reset for: $email');

      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.tweyonje://reset-password',
      );

      Logger.info('Password reset request successful');
      return true;
    } catch (e) {
      Logger.error('Password reset request failed', error: e);
      return false;
    }
  }

  /// Update password via Supabase
  Future<bool> updatePassword({required String newPassword}) async {
    try {
      Logger.info('Attempting to update password');

      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user != null) {
        Logger.info('Password update successful');
        return true;
      } else {
        Logger.warning('Password update failed');
        return false;
      }
    } catch (e) {
      Logger.error('Password update failed', error: e);
      return false;
    }
  }

  /// Update user metadata via Supabase
  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? preferredLanguage,
  }) async {
    try {
      Logger.info('Attempting to update profile');

      final response = await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            if (fullName != null) 'full_name': fullName,
            if (phone != null) 'phone': phone,
            if (preferredLanguage != null) 'preferred_language': preferredLanguage,
          },
        ),
      );

      if (response.user != null) {
        // Update local storage
        final cachedUser = await _storageService.getUser();
        if (cachedUser != null) {
          final updatedUser = User(
            id: cachedUser.id,
            email: response.user!.email ?? cachedUser.email,
            fullName: fullName ?? cachedUser.fullName,
            firstName: fullName?.split(' ').first ?? cachedUser.firstName,
            lastName: fullName?.split(' ').length > 1 ? fullName!.split(' ').last : cachedUser.lastName,
            phone: phone ?? cachedUser.phone,
            role: cachedUser.role,
            phoneVerified: cachedUser.phoneVerified,
            emailVerified: cachedUser.emailVerified,
          );
          await _storageService.saveUser(updatedUser);
        }

        Logger.info('Profile update successful');
        return true;
      } else {
        Logger.warning('Profile update failed');
        return false;
      }
    } catch (e) {
      Logger.error('Profile update failed', error: e);
      return false;
    }
  }

  /// Send OTP for phone verification
  Future<bool> sendOTP({required String phone}) async {
    try {
      Logger.info('Sending OTP to: $phone');

      await _supabase.auth.signInWithOtp(
        phone: phone,
      );

      Logger.info('OTP sent successfully');
      return true;
    } catch (e) {
      Logger.error('Failed to send OTP', error: e);
      return false;
    }
  }

  /// Verify OTP
  Future<bool> verifyOTP({
    required String phone,
    required String token,
  }) async {
    try {
      Logger.info('Verifying OTP for: $phone');

      final response = await _supabase.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );

      if (response.user != null) {
        Logger.info('OTP verified successfully');
        return true;
      } else {
        Logger.warning('OTP verification failed');
        return false;
      }
    } catch (e) {
      Logger.error('OTP verification failed', error: e);
      return false;
    }
  }

  /// Enable biometric authentication
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

  /// Disable biometric authentication
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

  /// Check if biometric is enabled
  Future<bool> isBiometricEnabled() async {
    return await _biometricService.isBiometricEnabled();
  }

  /// Authenticate with biometric
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

  /// Get current user from Supabase or local storage
  Future<User?> getCurrentUser() async {
    try {
      // First try Supabase
      if (currentUser != null) {
        return User(
          id: int.parse(currentUser!.id.hashCode.toString().substring(0, 8)),
          email: currentUser!.email ?? '',
          fullName: currentUser!.userMetadata?['full_name'] as String? ?? '',
          firstName: currentUser!.userMetadata?['first_name'] as String?,
          lastName: currentUser!.userMetadata?['last_name'] as String?,
          phone: currentUser!.phone,
          role: UserRole.values.firstWhere(
            (r) => r.value == (currentUser!.userMetadata?['role'] ?? 'RESIDENT'),
            orElse: () => UserRole.resident,
          ),
          phoneVerified: currentUser!.phoneConfirmedAt != null,
          emailVerified: currentUser!.emailConfirmedAt != null,
        );
      }
      
      // Fallback to local storage
      return await _storageService.getUser();
    } catch (e) {
      Logger.error('Failed to get current user', error: e);
      return null;
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticatedAsync() async {
    return currentUser != null;
  }
}

final supabaseAuthServiceProvider = Provider<SupabaseAuthService>((ref) {
  final supabase = Supabase.instance.client;
  final storageService = ref.watch(storageServiceProvider);
  final biometricService = ref.watch(biometricServiceProvider);
  
  return SupabaseAuthService(supabase, storageService, biometricService);
});
