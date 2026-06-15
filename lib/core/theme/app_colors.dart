import 'package:flutter/material.dart';

/// Centralized color palette for the app.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryDark = Color(0xFF5343C4);
  static const Color secondary = Color(0xFF00CEC9);
  static const Color accent = Color(0xFFFD79A8);

  // Light theme surfaces.
  static const Color lightBackground = Color(0xFFF6F6FB);
  static const Color lightSurface = Colors.white;

  // Dark theme surfaces.
  static const Color darkBackground = Color(0xFF121218);
  static const Color darkSurface = Color(0xFF1E1E29);

  static const Color userBubble = primary;
  static const Color aiBubbleLight = Color(0xFFECEAFB);
  static const Color aiBubbleDark = Color(0xFF2A2A3C);

  static const Color error = Color(0xFFE74C3C);
  static const Color success = Color(0xFF2ECC71);
}
