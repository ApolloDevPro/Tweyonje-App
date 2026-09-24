import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/models.dart';
import '../constants/app_constants.dart';

class LocalStorage {
  static final LocalStorage _instance = LocalStorage._internal();
  factory LocalStorage() => _instance;
  LocalStorage._internal();

  final _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> saveTokens({required String access, required String refresh}) async {
    await init();
    try {
      await _secureStorage.write(key: AppConstants.accessTokenKey, value: access);
      await _secureStorage.write(key: AppConstants.refreshTokenKey, value: refresh);
    } catch (_) {}
    await _prefs?.setString(AppConstants.accessTokenKey, access);
    await _prefs?.setString(AppConstants.refreshTokenKey, refresh);
  }

  Future<String?> getAccessToken() async {
    await init();
    try {
      final token = await _secureStorage.read(key: AppConstants.accessTokenKey);
      if (token != null && token.isNotEmpty) return token;
    } catch (_) {}
    return _prefs?.getString(AppConstants.accessTokenKey);
  }

  Future<void> saveAccessToken(String token) async {
    await init();
    try {
      await _secureStorage.write(key: AppConstants.accessTokenKey, value: token);
    } catch (_) {}
    await _prefs?.setString(AppConstants.accessTokenKey, token);
  }

  Future<String?> getRefreshToken() async {
    await init();
    try {
      final token = await _secureStorage.read(key: AppConstants.refreshTokenKey);
      if (token != null && token.isNotEmpty) return token;
    } catch (_) {}
    return _prefs?.getString(AppConstants.refreshTokenKey);
  }

  Future<void> saveUser(User user) async {
    await init();
    await _prefs?.setString(AppConstants.userDataKey, jsonEncode(user.toJson()));
  }

  Future<User?> getUser() async {
    await init();
    final raw = _prefs?.getString(AppConstants.userDataKey);
    if (raw != null) {
      try {
        return User.fromJson(jsonDecode(raw));
      } catch (_) {}
    }
    return null;
  }

  Future<void> clearSession() async {
    await init();
    try {
      await _secureStorage.delete(key: AppConstants.accessTokenKey);
      await _secureStorage.delete(key: AppConstants.refreshTokenKey);
    } catch (_) {}
    await _prefs?.remove(AppConstants.accessTokenKey);
    await _prefs?.remove(AppConstants.refreshTokenKey);
    await _prefs?.remove(AppConstants.userDataKey);
  }

  Future<void> setOnboardingComplete(bool complete) async {
    await init();
    await _prefs?.setBool(AppConstants.onboardingCompleteKey, complete);
  }

  Future<bool> isOnboardingComplete() async {
    await init();
    return _prefs?.getBool(AppConstants.onboardingCompleteKey) ?? false;
  }

  Future<void> saveFCMToken(String token) async {
    await init();
    await _prefs?.setString(AppConstants.fcmTokenKey, token);
  }

  Future<String?> getFCMToken() async {
    await init();
    return _prefs?.getString(AppConstants.fcmTokenKey);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await init();
    await _prefs?.setBool(AppConstants.notificationsEnabledKey, enabled);
  }

  Future<bool> isNotificationsEnabled() async {
    await init();
    return _prefs?.getBool(AppConstants.notificationsEnabledKey) ?? true;
  }

  Future<void> setThemeMode(String mode) async {
    await init();
    await _prefs?.setString(AppConstants.themeModeKey, mode);
  }

  Future<String?> getThemeMode() async {
    await init();
    return _prefs?.getString(AppConstants.themeModeKey);
  }

  Future<void> setLanguage(String language) async {
    await init();
    await _prefs?.setString(AppConstants.languageKey, language);
  }

  Future<String?> getLanguage() async {
    await init();
    return _prefs?.getString(AppConstants.languageKey);
  }
}
