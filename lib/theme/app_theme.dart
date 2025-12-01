// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  /// Gradient for scaffold background (optional use)
  static final Gradient scaffoldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF6F8FF),
      Color(0xFFEEF6FF),
      Color(0xFFFFFFFF),
    ],
  );

  /// Primary colors
  static const Color primary = Color(0xFF4B6EF6);
  static const Color accent = Color(0xFF7C4DFF);
  static const Color card = Color(0xFFFFFFFF);

  /// Light Theme configuration
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: TextTheme(
      titleLarge: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        color: Colors.black54,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: Colors.black87),
    ),
  );

  /// Default padding for pages
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
}
