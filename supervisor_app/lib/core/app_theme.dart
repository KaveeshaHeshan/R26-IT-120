import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared visual system for every standard Material control in the app.
class AppTheme {
  static const Color background = Color(0xFFF4F8F4);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFE5F2E8);
  static const Color primary = Color(0xFF12613A);
  static const Color primaryGlow = Color(0xFF31A568);
  static const Color accent = Color(0xFFD8F0E0);

  static const Color riskHigh = Color(0xFFC83C42);
  static const Color riskMedium = Color(0xFFD98218);
  static const Color riskSafe = Color(0xFF258957);
  // Pending readings must remain visually distinct from verified-safe latex.
  static const Color riskPending = Color(0xFF757575);

  static const Color textPrimary = Color(0xFF15231A);
  static const Color textSecondary = Color(0xFF5C6F63);
  static const Color textMuted = Color(0xFF8A9B90);

  static const Color error = riskHigh;
  static const Color success = riskSafe;
  static const Color divider = Color(0xFFDDE8DF);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.light(
      surface: surface,
      primary: primary,
      onPrimary: Colors.white,
      secondary: primaryGlow,
      error: error,
    ),
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
      iconTheme: const IconThemeData(color: textPrimary),
    ),
    cardTheme: CardThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: divider),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      labelStyle: const TextStyle(color: textSecondary),
      hintStyle: const TextStyle(color: textMuted),
      border: _inputBorder(divider),
      enabledBorder: _inputBorder(divider),
      focusedBorder: _inputBorder(primary, width: 1.8),
      errorBorder: _inputBorder(error),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        minimumSize: const Size(0, 52),
        side: const BorderSide(color: primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF20352A),
      contentTextStyle: GoogleFonts.inter(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    dividerTheme: const DividerThemeData(color: divider, space: 1),
  );

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  static Color riskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return riskHigh;
      case 'medium':
        return riskMedium;
      case 'safe':
        return riskSafe;
      case 'pending':
      default:
        return riskPending;
    }
  }

  static String riskLabel(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return 'URGENT';
      case 'medium':
        return 'WATCH';
      case 'safe':
        return 'SAFE';
      case 'pending':
      default:
        return 'AWAITING READING';
    }
  }
}
