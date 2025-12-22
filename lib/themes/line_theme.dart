import 'package:flutter/material.dart';

class LineColors {
  static const Color lineGreen = Color(0xFF00C300);
  static const Color backgroundPrimary = Colors.white;
  static const Color backgroundSecondary = Color(0xFFF4F4F4);
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF888888);
  static const Color textTertiary = Color(0xFFAAAAAA);
  static const Color iconPrimary = Color(0xFF111111);
  static const Color iconSecondary = Color(0xFF888888);
  static const Color borderLight = Color(0xFFEEEEEE);
  static const Color shadow = Color(0x1A000000);
  static const Color error = Color(0xFFFF3B30);
  static const Color bubbleSelf = Color(0xFFD6F5D6);
}

class LineTextStyles {
  static const TextStyle appBarTitle = TextStyle(
    color: LineColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle headline3 = TextStyle(
    color: LineColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle bodyText1 = TextStyle(
    color: LineColors.textPrimary,
    fontSize: 15,
  );

  static const TextStyle bodyText2 = TextStyle(
    color: LineColors.textSecondary,
    fontSize: 13,
  );
}
