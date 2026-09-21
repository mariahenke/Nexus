import 'package:flutter/material.dart';

class AppTheme {
  static const Color backgroundColor = Color(0xFFF6F8FA);
  static const Color cardColor = Colors.white;
  static const Color primaryColor = Color(0xFF5352ED);
  static const Color gradientStart = Color(0xFF3B82F6);
  static const Color gradientEnd = Color(0xFF7C3AED);
  static const Color textColor = Color(0xFF1E293B);
  static const Color subtitleColor = Color(0xFF64748B);

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        surface: cardColor,
      ),
      useMaterial3: true,
      fontFamily: 'Roboto',
    );
  }
}