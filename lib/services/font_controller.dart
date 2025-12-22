import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontController {
  static final ValueNotifier<double> fontScale = ValueNotifier<double>(1.0);
  // default to Noto Sans JP for consistent Japanese-capable typography
  static final ValueNotifier<String> fontFamily = ValueNotifier<String>('NotoSansJP');
  static const _prefsFontSizeKey = 'font_size_scale';
  static const _prefsFontFamilyKey = 'font_family';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getDouble(_prefsFontSizeKey) ?? 1.0;
    fontScale.value = value;
    final fam = prefs.getString(_prefsFontFamilyKey) ?? 'system';
    fontFamily.value = fam;
  }

  static Future<void> setScale(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefsFontSizeKey, value);
    fontScale.value = value;
  }

  static Future<void> setFontFamily(String family) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsFontFamilyKey, family);
    fontFamily.value = family;
  }
}
