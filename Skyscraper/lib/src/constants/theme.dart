import 'package:flutter/material.dart';

/// Defines the light theme for the application.
final lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
  ),
  // TODO(username): Integrate typography (text styles) here later.
);

/// Defines the dark theme for the application.
final darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
  ),
  // TODO(username): Integrate typography (text styles) here later.
);