import 'package:flutter/material.dart';

// ================================================================
// FARMER APP DESIGN SYSTEM
// ================================================================
//
// Single source of truth for every color, radius and shadow used
// across the farmer-facing screens. Every screen reads its palette
// from `FarmerTheme.of(context)` (via FarmerSettingsScope) so that
// toggling dark mode in the profile page instantly re-skins the
// whole farmer app instead of just the profile screen.
// ================================================================

class FarmerPalette {
  const FarmerPalette({
    required this.isDark,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.primary,
    required this.primaryDark,
    required this.onPrimary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.shadow,
  });

  final bool isDark;

  final Color background;
  final Color surface;
  final Color surfaceAlt;

  final Color primary;
  final Color primaryDark;
  final Color onPrimary;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  final Color border;

  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  final Color shadow;

  static const FarmerPalette light = FarmerPalette(
    isDark: false,
    background: Color(0xFFF4F8F5),
    surface: Colors.white,
    surfaceAlt: Color(0xFFEAF4EC),
    primary: Color(0xFF17663A),
    primaryDark: Color(0xFF0C4326),
    onPrimary: Colors.white,
    textPrimary: Color(0xFF15201A),
    textSecondary: Color(0xFF60706A),
    textMuted: Color(0xFF9AA9A3),
    border: Color(0xFFE1EAE3),
    success: Color(0xFF2E9E5B),
    warning: Color(0xFFE08A1E),
    danger: Color(0xFFDA4B4B),
    info: Color(0xFF1D7FBF),
    shadow: Color(0x142A3B2F),
  );

  static const FarmerPalette dark = FarmerPalette(
    isDark: true,
    background: Color(0xFF0D1210),
    surface: Color(0xFF161D1A),
    surfaceAlt: Color(0xFF1E2822),
    primary: Color(0xFF3FAE72),
    primaryDark: Color(0xFF2C7E52),
    onPrimary: Colors.white,
    textPrimary: Color(0xFFF3F7F4),
    textSecondary: Color(0xFFAAB8B1),
    textMuted: Color(0xFF74847D),
    border: Color(0xFF283530),
    success: Color(0xFF3FAE72),
    warning: Color(0xFFEDA23F),
    danger: Color(0xFFE5716B),
    info: Color(0xFF4FA6DE),
    shadow: Color(0x66000000),
  );

  static FarmerPalette of({required bool dark}) => dark ? FarmerPalette.dark : FarmerPalette.light;
}

/// Consistent spacing / radius scale used everywhere in the farmer app.
class FarmerMetrics {
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 26;

  static const double gap4 = 4;
  static const double gap8 = 8;
  static const double gap12 = 12;
  static const double gap16 = 16;
  static const double gap20 = 20;
  static const double gap24 = 24;
}

extension FarmerPaletteShadow on FarmerPalette {
  List<BoxShadow> get cardShadow => <BoxShadow>[
        BoxShadow(
          color: shadow,
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];
}

/// Displays the farmer app's shared image background behind a screen.
class FarmerScreenBackground extends StatelessWidget {
  const FarmerScreenBackground({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Opacity(
          opacity: 0.05,
          child: Image.asset(
            'assets/rubber_tree.jpg',
            fit: BoxFit.cover,
          ),
        ),
        child,
      ],
    );
  }
}
