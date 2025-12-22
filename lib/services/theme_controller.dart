import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  static final ValueNotifier<ThemeMode> mode = ValueNotifier<ThemeMode>(ThemeMode.system);
  static const _prefsThemeKey = 'app_theme';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString(_prefsThemeKey) ?? 'system';
    switch (t) {
      case 'light':
        mode.value = ThemeMode.light;
        break;
      case 'dark':
        mode.value = ThemeMode.dark;
        break;
      case 'system':
      default:
        mode.value = ThemeMode.system;
        break;
    }
  }

  static Future<void> setTheme(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsThemeKey, value);
    switch (value) {
      case 'light':
        mode.value = ThemeMode.light;
        break;
      case 'dark':
        mode.value = ThemeMode.dark;
        break;
      case 'system':
      default:
        mode.value = ThemeMode.system;
        break;
    }
  }
}
