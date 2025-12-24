import 'package:flutter/material.dart';

class LineColors {
  static const Color lineGreen = Color(0xFF00C300);
  
  // Light Mode Colors
  static const Color backgroundPrimaryLight = Colors.white;
  static const Color backgroundSecondaryLight = Color(0xFFF4F4F4);
  static const Color textPrimaryLight = Color(0xFF111111);
  static const Color textSecondaryLight = Color(0xFF888888);
  static const Color textTertiaryLight = Color(0xFFAAAAAA);
  static const Color iconPrimaryLight = Color(0xFF111111);
  static const Color iconSecondaryLight = Color(0xFF888888);
  static const Color borderLightLight = Color(0xFFEEEEEE);
  
  // Dark Mode Colors
  static const Color backgroundPrimaryDark = Color(0xFF111111);
  static const Color backgroundSecondaryDark = Color(0xFF1A1A1A);
  static const Color textPrimaryDark = Color(0xFFEEEEEE);
  static const Color textSecondaryDark = Color(0xFFAAAAAA);
  static const Color textTertiaryDark = Color(0xFF777777);
  static const Color iconPrimaryDark = Color(0xFFEEEEEE);
  static const Color iconSecondaryDark = Color(0xFFAAAAAA);
  static const Color borderLightDark = Color(0xFF333333);

  // Legacy / Shared
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

  static Color getBackgroundPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? backgroundPrimaryDark
        : backgroundPrimaryLight;
  }

  static Color getBackgroundSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? backgroundSecondaryDark
        : backgroundSecondaryLight;
  }

  static Color getTextPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textPrimaryDark
        : textPrimaryLight;
  }

  static Color getTextSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textSecondaryDark
        : textSecondaryLight;
  }

  static Color getTextTertiary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textTertiaryDark
        : textTertiaryLight;
  }

  static Color getBorderLight(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? borderLightDark
        : borderLightLight;
  }
}

class LineTextStyles {
  static TextStyle appBarTitle(BuildContext context) => TextStyle(
        color: LineColors.getTextPrimary(context),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      );

  static TextStyle headline3(BuildContext context) => TextStyle(
        color: LineColors.getTextPrimary(context),
        fontSize: 16,
        fontWeight: FontWeight.bold,
      );

  static TextStyle bodyText1(BuildContext context) => TextStyle(
        color: LineColors.getTextPrimary(context),
        fontSize: 15,
      );

  static TextStyle bodyText2(BuildContext context) => TextStyle(
        color: LineColors.getTextSecondary(context),
        fontSize: 13,
      );
}
