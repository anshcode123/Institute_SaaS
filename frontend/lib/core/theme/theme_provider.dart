import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';

const _themePreferenceKey = 'theme_mode';

final StateNotifierProvider<ThemeController, ThemeMode> themeProvider =
    StateNotifierProvider<ThemeController, ThemeMode>((ref) {
  return ThemeController(SecureStorage.instance);
});

class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController(this._storage) : super(ThemeMode.light) {
    _loadSavedTheme();
  }

  final SecureStorage _storage;
  bool _hasUserSelectedTheme = false;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == ThemeMode.system) {
      throw ArgumentError.value(
          mode, 'mode', 'Only light and dark themes are supported.');
    }

    _hasUserSelectedTheme = true;
    state = mode;
    await _storage.write(_themePreferenceKey, mode.name);
  }

  Future<void> _loadSavedTheme() async {
    final savedTheme = await _storage.read(_themePreferenceKey);
    if (_hasUserSelectedTheme) return;

    state = switch (savedTheme) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.light,
    };
  }
}
