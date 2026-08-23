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
    background: Color(0xFFF7FAF7),
    surface: Colors.white,
    surfaceAlt: Color(0xFFE7F4EA),
    primary: Color(0xFF12613A),
    primaryDark: Color(0xFF093D25),
    onPrimary: Colors.white,
    textPrimary: Color(0xFF14251A),
    textSecondary: Color(0xFF586B5F),
    textMuted: Color(0xFF84958A),
    border: Color(0xFFDCE8DF),
    success: Color(0xFF258957),
    warning: Color(0xFFD98218),
    danger: Color(0xFFC83C42),
    info: Color(0xFF187CB8),
    shadow: Color(0x12233A2A),
  );

  static const FarmerPalette dark = FarmerPalette(
    isDark: true,
    background: Color(0xFF0B120E),
    surface: Color(0xFF141E17),
    surfaceAlt: Color(0xFF1C2A20),
    primary: Color(0xFF46B978),
    primaryDark: Color(0xFF2A8051),
    onPrimary: Colors.white,
    textPrimary: Color(0xFFF1F7F2),
    textSecondary: Color(0xFFB0C0B6),
    textMuted: Color(0xFF7E9185),
    border: Color(0xFF293A2E),
    success: Color(0xFF46B978),
    warning: Color(0xFFF0AA45),
    danger: Color(0xFFEE7770),
    info: Color(0xFF58ACE0),
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
