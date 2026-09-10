import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'logger.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  static const String _biometricEnabledKey = 'biometric_enabled';

  Future<bool> isBiometricAvailable() async {
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      Logger.info('Biometric availability: $canAuthenticate');
      return canAuthenticate;
    } catch (e) {
      Logger.error('Failed to check biometric availability', error: e);
      return false;
    }
  }

  Future<bool> authenticate({String reason = 'Authenticate to sign in to Tweyonje'}) async {
    try {
      Logger.info('Attempting biometric authentication');
      final result = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      Logger.info('Biometric authentication result: $result');
      return result;
    } catch (e) {
      Logger.error('Biometric authentication failed', error: e);
      return false;
    }
  }

  Future<void> enableBiometric() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, true);
      Logger.info('Biometric authentication enabled');
    } catch (e) {
      Logger.error('Failed to enable biometric authentication', error: e);
    }
  }

  Future<void> disableBiometric() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, false);
      Logger.info('Biometric authentication disabled');
    } catch (e) {
      Logger.error('Failed to disable biometric authentication', error: e);
    }
  }

  Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_biometricEnabledKey) ?? false;
    } catch (e) {
      Logger.error('Failed to check biometric enabled status', error: e);
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      Logger.error('Failed to get available biometrics', error: e);
      return [];
    }
  }

  Future<bool> stopAuthentication() async {
    try {
      return await _auth.stopAuthentication();
    } catch (e) {
      Logger.error('Failed to stop authentication', error: e);
      return false;
    }
  }
}

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});
