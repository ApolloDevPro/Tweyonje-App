import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import '../storage/storage_service.dart';
import '../../models/models.dart';
import '../constants/api_endpoints.dart';
import 'biometric_service.dart';
import 'error_handler.dart';
import 'logger.dart';

class AuthService {
  final ApiClient _apiClient;
  final StorageService _storageService;
  final BiometricService _biometricService;

  AuthService(this._apiClient, this._storageService, this._biometricService);

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      Logger.info('Attempting login for: $email');

      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final authSession = AuthSession.fromJson(response.data);
        
        // Save tokens and user data
        await _storageService.saveTokens(
          access: authSession.access,
          refresh: authSession.refresh,
        );
        await _storageService.saveUser(authSession.user);
        
        Logger.info('Login successful for: $email');
        return authSession;
      } else {
        throw AuthenticationException(message: 'Login failed');
      }
    } catch (e) {
      Logger.error('Login failed', error: e);
      
      if (e is AuthenticationException) {
        rethrow;
      }
      
      throw AuthenticationException(message: 'Login failed: $e');
    }
  }

  Future<AuthSession> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required UserRole role,
  }) async {
    try {
      Logger.info('Attempting registration for: $email');

      final response = await _apiClient.post(
        ApiEndpoints.register,
        data: {
          'email': email,
          'password': password,
          'full_name': fullName,
          'phone': phone,
          'role': role.value,
        },
      );

      if (response.statusCode == 201) {
        final authSession = AuthSession.fromJson(response.data);
        
        // Save tokens and user data
        await _storageService.saveTokens(
          access: authSession.access,
          refresh: authSession.refresh,
        );
        await _storageService.saveUser(authSession.user);
        
        Logger.info('Registration successful for: $email');
        return authSession;
      } else {
        throw AuthenticationException(message: 'Registration failed');
      }
    } catch (e) {
      Logger.error('Registration failed', error: e);
      
      if (e is AuthenticationException) {
        rethrow;
      }
      
      throw AuthenticationException(message: 'Registration failed: $e');
    }
  }

  Future<bool> logout() async {
    try {
      Logger.info('Attempting logout');

      // Call backend logout endpoint
      await _apiClient.post(ApiEndpoints.logout);

      // Clear local storage
      await _storageService.clearAuthData();
      
      // Disable biometric if enabled
      await _biometricService.disableBiometric();

      Logger.info('Logout successful');
      return true;
    } catch (e) {
      Logger.error('Logout failed', error: e);
      
      // Even if backend call fails, clear local data
      await _storageService.clearAuthData();
      await _biometricService.disableBiometric();
      
      return true;
    }
  }

  Future<bool> refreshToken() async {
    try {
      Logger.info('Attempting token refresh');

      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken == null) {
        Logger.warning('No refresh token available');
        return false;
      }

      final response = await _apiClient.post(
        ApiEndpoints.tokenRefresh,
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['access'];
        await _storageService.saveAccessToken(newAccessToken);
        
        Logger.info('Token refresh successful');
        return true;
      } else {
        Logger.warning('Token refresh failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      Logger.error('Token refresh failed', error: e);
      return false;
    }
  }

  Future<bool> enableBiometricAuth() async {
    try {
      Logger.info('Attempting to enable biometric auth');

      // Check if biometric is available
      final isAvailable = await _biometricService.isBiometricAvailable();
      if (!isAvailable) {
        Logger.warning('Biometric authentication not available');
        return false;
      }

      // Authenticate with biometrics
      final isAuthenticated = await _biometricService.authenticate();
      if (!isAuthenticated) {
        Logger.warning('Biometric authentication failed');
        return false;
      }

      // Enable biometric
      await _biometricService.enableBiometric();
      
      Logger.info('Biometric authentication enabled');
      return true;
    } catch (e) {
      Logger.error('Failed to enable biometric auth', error: e);
      return false;
    }
  }

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

  Future<bool> isBiometricEnabled() async {
    return await _biometricService.isBiometricEnabled();
  }

  Future<bool> authenticateWithBiometric() async {
    try {
      Logger.info('Attempting biometric authentication');

      // Check if biometric is enabled
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

  Future<User?> getCurrentUser() async {
    try {
      return await _storageService.getUser();
    } catch (e) {
      Logger.error('Failed to get current user', error: e);
      return null;
    }
  }

  Future<bool> isAuthenticated() async {
    final token = await _storageService.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? preferredLanguage,
  }) async {
    try {
      Logger.info('Attempting to update profile');

      final response = await _apiClient.patch(
        ApiEndpoints.profile,
        data: {
          'full_name': ?fullName,
          'phone': ?phone,
          'preferred_language': ?preferredLanguage,
        },
      );

      if (response.statusCode == 200) {
        final updatedUser = User.fromJson(response.data);
        await _storageService.saveUser(updatedUser);
        
        Logger.info('Profile update successful');
        return true;
      } else {
        Logger.warning('Profile update failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      Logger.error('Profile update failed', error: e);
      return false;
    }
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      Logger.info('Attempting to change password');

      final response = await _apiClient.post(
        ApiEndpoints.changePassword,
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );

      if (response.statusCode == 200) {
        Logger.info('Password change successful');
        return true;
      } else {
        Logger.warning('Password change failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      Logger.error('Password change failed', error: e);
      return false;
    }
  }

  Future<bool> requestPasswordReset({required String email}) async {
    try {
      Logger.info('Attempting to request password reset for: $email');

      final response = await _apiClient.post(
        ApiEndpoints.passwordReset,
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        Logger.info('Password reset request successful');
        return true;
      } else {
        Logger.warning('Password reset request failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      Logger.error('Password reset request failed', error: e);
      return false;
    }
  }

  Future<bool> confirmPasswordReset({
    required String token,
    required String newPassword,
  }) async {
    try {
      Logger.info('Attempting to confirm password reset');

      final response = await _apiClient.post(
        ApiEndpoints.passwordResetConfirm,
        data: {
          'token': token,
          'new_password': newPassword,
        },
      );

      if (response.statusCode == 200) {
        Logger.info('Password reset confirmation successful');
        return true;
      } else {
        Logger.warning('Password reset confirmation failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      Logger.error('Password reset confirmation failed', error: e);
      return false;
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storageService = ref.watch(storageServiceProvider);
  final biometricService = ref.watch(biometricServiceProvider);
  
  return AuthService(apiClient, storageService, biometricService);
});