import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_strings.dart';
import '../core/storage/storage_service.dart';

class AppSettingsState {
  final ThemeMode themeMode;
  final AppLanguage language;

  const AppSettingsState({
    this.themeMode = ThemeMode.light,
    this.language = AppLanguage.english,
  });

  AppSettingsState copyWith({ThemeMode? themeMode, AppLanguage? language}) {
    return AppSettingsState(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
    );
  }
}

class AppSettingsController extends StateNotifier<AppSettingsState> {
  final StorageService _storage;

  AppSettingsController(this._storage) : super(const AppSettingsState()) {
    hydrate();
  }

  Future<void> hydrate() async {
    final themeRaw = await _storage.getThemeMode();
    final langRaw = await _storage.getLanguage();
    state = AppSettingsState(
      themeMode: _parseThemeMode(themeRaw),
      language: AppLanguage.fromCode(langRaw),
    );
  }

  ThemeMode _parseThemeMode(String? raw) {
    switch (raw) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final label = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
      ThemeMode.light => 'light',
    };
    state = state.copyWith(themeMode: mode);
    await _storage.setThemeMode(label);
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = state.copyWith(language: language);
    await _storage.setLanguage(language.code);
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsController, AppSettingsState>((ref) {
  return AppSettingsController(ref.watch(storageServiceProvider));
});

/// Convenience: localized translation for the current app language.
final appLanguageProvider = Provider<AppLanguage>((ref) {
  return ref.watch(appSettingsProvider).language;
});

/// Whether the onboarding welcome flow has been completed.
final appOnboardingProvider = FutureProvider<bool>((ref) async {
  return await ref.watch(storageServiceProvider).isOnboardingComplete();
});