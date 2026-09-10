import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local_storage.dart';
import '../../models/models.dart';

class StorageService {
  final LocalStorage _localStorage = LocalStorage();

  Future<void> init() async {
    await _localStorage.init();
  }

  Future<void> saveAccessToken(String token) async {
    final refreshToken = await getRefreshToken() ?? '';
    await _localStorage.saveTokens(access: token, refresh: refreshToken);
  }

  Future<void> saveRefreshToken(String token) async {
    final accessToken = await getAccessToken() ?? '';
    await _localStorage.saveTokens(access: accessToken, refresh: token);
  }

  Future<void> saveTokens({required String access, required String refresh}) async {
    await _localStorage.saveTokens(access: access, refresh: refresh);
  }

  Future<String?> getAccessToken() async {
    return await _localStorage.getAccessToken();
  }

  Future<String?> getRefreshToken() async {
    return await _localStorage.getRefreshToken();
  }

  Future<void> saveUser(User user) async {
    await _localStorage.saveUser(user);
  }

  Future<User?> getUser() async {
    return await _localStorage.getUser();
  }

  Future<void> clearAuthData() async {
    await _localStorage.clearSession();
  }

  Future<void> setOnboardingComplete(bool complete) async {
    await _localStorage.setOnboardingComplete(complete);
  }

  Future<bool> isOnboardingComplete() async {
    return await _localStorage.isOnboardingComplete();
  }

  Future<void> saveFCMToken(String token) async {
    await _localStorage.saveFCMToken(token);
  }

  Future<String?> getFCMToken() async {
    return await _localStorage.getFCMToken();
  }

  Future<void> setThemeMode(String mode) async {
    await _localStorage.setThemeMode(mode);
  }

  Future<String?> getThemeMode() async {
    return await _localStorage.getThemeMode();
  }

  Future<void> setLanguage(String language) async {
    await _localStorage.setLanguage(language);
  }

  Future<String?> getLanguage() async {
    return await _localStorage.getLanguage();
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});