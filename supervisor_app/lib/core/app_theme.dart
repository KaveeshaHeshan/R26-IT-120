import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color background   = Color(0xFFF5F5F5); // Light Grey
  static const Color surface      = Color(0xFFFFFFFF); // White cards
  static const Color surfaceLight = Color(0xFFE8F5E9); // Light Green accent
  static const Color primary      = Color(0xFF2E7D32); // Dark Green
  static const Color primaryGlow  = Color(0xFF4CAF50); // Success Green
  static const Color accent       = Color(0xFFE8F5E9); // Light Green

  // VFA Risk Colors
  static const Color riskHigh   = Color(0xFFF44336); // Red — urgent
  static const Color riskMedium = Color(0xFFFF9800); // Orange — watch
  static const Color riskSafe   = Color(0xFF4CAF50); // Green — safe

  // Text Colors
  static const Color textPrimary   = Color(0xFF1B1B1B); // Dark text
  static const Color textSecondary = Color(0xFF616161); // Grey text
  static const Color textMuted     = Color(0xFF9E9E9E); // Light grey text

  // Extra
  static const Color error        = Color(0xFFF44336); // Red
  static const Color success      = Color(0xFF4CAF50); // Green
  static const Color divider      = Color(0xFFE0E0E0); // Divider line

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        surface: surface,
        primary: primary,
        error: error,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: textPrimary),
          bodyLarge:    TextStyle(color: textPrimary),
          bodyMedium:   TextStyle(color: textSecondary),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    );
  }

  // Get color based on risk level
  static Color riskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':   return riskHigh;
      case 'medium': return riskMedium;
      default:       return riskSafe;
    }
  }

  // Get label based on risk level
  static String riskLabel(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':   return 'URGENT';
      case 'medium': return 'WATCH';
      default:       return 'SAFE';
    }
  }
}