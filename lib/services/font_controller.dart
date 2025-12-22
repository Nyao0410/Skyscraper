import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontController {
  static final ValueNotifier<double> fontScale = ValueNotifier<double>(1.0);
  static const _prefsFontSizeKey = 'font_size_scale';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getDouble(_prefsFontSizeKey) ?? 1.0;
    fontScale.value = value;
  }

  static Future<void> setScale(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefsFontSizeKey, value);
    fontScale.value = value;
  }
}
