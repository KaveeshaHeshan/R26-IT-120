import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared visual system for every standard Material control in the app.
///
/// Surface and text colours resolve through [isDark] rather than being
/// constants. The supervisor screens reference `AppTheme.background` and
/// friends directly in ~100 places, so switching them here avoids rewriting
/// every call site to `Theme.of(context)`.
///
/// Set [isDark] only from the widget that also rebuilds the app (see
/// `LatexGuardApp`), otherwise the tree will not repaint.
class AppTheme {
  static bool _dark = false;

  static bool get isDark => _dark;
  static set isDark(bool value) => _dark = value;

  // Brand and semantic colours read the same in both modes — a risk colour
  // that shifted between themes would undermine the whole point of it.
  static const Color primary = Color(0xFF12613A);
  static const Color primaryGlow = Color(0xFF31A568);
  static const Color accent = Color(0xFFD8F0E0);

  static const Color riskHigh = Color(0xFFC83C42);
  static const Color riskMedium = Color(0xFFD98218);
  static const Color riskSafe = Color(0xFF258957);
  // Pending readings must remain visually distinct from verified-safe latex.
  static const Color riskPending = Color(0xFF757575);

  static const Color error = riskHigh;
  static const Color success = riskSafe;

  // Surfaces and text follow the selected mode.
  static Color get background =>
      _dark ? const Color(0xFF10150F) : const Color(0xFFF4F8F4);
  static Color get surface =>
      _dark ? const Color(0xFF1A211B) : const Color(0xFFFFFFFF);
  static Color get surfaceLight =>
      _dark ? const Color(0xFF1E3527) : const Color(0xFFE5F2E8);

  static Color get textPrimary =>
      _dark ? const Color(0xFFE8EFE9) : const Color(0xFF15231A);
  static Color get textSecondary =>
      _dark ? const Color(0xFFA8B8AC) : const Color(0xFF5C6F63);
  static Color get textMuted =>
      _dark ? const Color(0xFF77877C) : const Color(0xFF8A9B90);

  static Color get divider =>
      _dark ? const Color(0xFF2A342C) : const Color(0xFFDDE8DF);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.light(
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
      iconTheme: IconThemeData(color: textPrimary),
    ),
    cardTheme: CardThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: divider),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      labelStyle: TextStyle(color: textSecondary),
      hintStyle: TextStyle(color: textMuted),
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
    dividerTheme: DividerThemeData(color: divider, space: 1),
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
