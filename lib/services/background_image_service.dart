import 'package:shared_preferences/shared_preferences.dart';

class BackgroundImageService {
  static const _prefsKeyPrefix = 'bg_image_';

  static Future<void> setBackgroundImage(String id, String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefsKeyPrefix$id', path);
  }

  static Future<String?> getBackgroundImage(String id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_prefsKeyPrefix$id');
  }

  static Future<void> removeBackgroundImage(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefsKeyPrefix$id');
  }
}
