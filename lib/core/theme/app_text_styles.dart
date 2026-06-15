import 'package:flutter/material.dart';

/// Shared text styles. Color is intentionally left to the active theme.
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Roboto';

  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyLarge = TextStyle(fontSize: 16);

  static const TextStyle bodyMedium = TextStyle(fontSize: 14);

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: Colors.grey,
  );
}
