import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController {
  static final ValueNotifier<Locale?> locale = ValueNotifier<Locale?>(null);
  static const _prefsLocaleKey = 'locale';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsLocaleKey);
    if (code != null && code.isNotEmpty) {
      locale.value = Locale(code);
    }
  }

  static Future<void> setLocale(Locale? l) async {
    final prefs = await SharedPreferences.getInstance();
    if (l == null) {
      await prefs.remove(_prefsLocaleKey);
      locale.value = null;
    } else {
      await prefs.setString(_prefsLocaleKey, l.languageCode);
      locale.value = l;
    }
  }
}
