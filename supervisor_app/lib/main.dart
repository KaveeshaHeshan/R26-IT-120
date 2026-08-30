import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/app_theme.dart';
import 'screens/farmer_screens/core/farmer_settings.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const LatexGuardApp());
}

class LatexGuardApp extends StatefulWidget {
  const LatexGuardApp({super.key});

  @override
  State<LatexGuardApp> createState() => _LatexGuardAppState();
}

class _LatexGuardAppState extends State<LatexGuardApp> {
  // Owned here (above the app's Navigator) so that every route — including
  // ones pushed deep inside the farmer app, e.g. the tapping record form —
  // stays a descendant of FarmerSettingsScope and can read dark mode /
  // language. Placing this scope any lower (e.g. inside FarmerDashboardScreen
  // around just its own Scaffold) leaves routes pushed from within it outside
  // the scope, since Navigator.push targets the app's root Navigator, which
  // sits above that point in the tree.
  final FarmerSettings _farmerSettings = FarmerSettings();

  @override
  void initState() {
    super.initState();
    _farmerSettings.load();
  }

  @override
  void dispose() {
    _farmerSettings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The supervisor screens read AppTheme's static colours directly, so the
    // mode is set here — immediately before the rebuild that repaints them —
    // and the whole app is rebuilt when the setting changes.
    return ListenableBuilder(
      listenable: _farmerSettings,
      builder: (context, _) {
        AppTheme.isDark = _farmerSettings.darkMode;

        return MaterialApp(
          title: 'LatexGuard — Supervisor',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme,
          // Wrap every route, so the frame (and farmer settings) survive
          // login/logout navigation and any route pushed from within.
          builder: (context, child) => FarmerSettingsScope(
            settings: _farmerSettings,
            // Farmers who bump up their phone's system font size for
            // readability shouldn't end up with broken, overflowing layouts —
            // clamp how far text can scale instead of ignoring the setting.
            child: MediaQuery.withClampedTextScaling(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.25,
              child: MobileFrame(child: child),
            ),
          ),
          home: const LoginScreen(),
        );
      },
    );
  }
}

/// Whether to preview the app inside a phone-sized frame on wide screens.
///
/// Set to false to let desktop browsers use the full window — the farmer
/// screens carry their own adaptive layouts and are designed for that.
const bool kUseMobileFrame = true;

/// Wraps the app in a phone-sized frame when there is room for one.
///
/// Only wide windows are framed. On an actual phone the viewport is already
/// phone-sized, so framing there would letterbox the app inside itself; those
/// windows are passed straight through, which keeps the farmer screens'
/// adaptive layouts intact.
class MobileFrame extends StatelessWidget {
  final Widget? child;
  const MobileFrame({super.key, this.child});

  static const double _phoneWidth = 390;
  static const double _phoneHeight = 844;

  /// Below this the window is treated as a real device rather than a preview.
  static const double _frameFromWidth = 600;

  @override
  Widget build(BuildContext context) {
    final content = child ?? const SizedBox.shrink();
    if (!kUseMobileFrame) return content;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _frameFromWidth) return content;

        // Short windows would otherwise overflow the 844px frame.
        final height = _phoneHeight > constraints.maxHeight - 32
            ? constraints.maxHeight - 32
            : _phoneHeight;

        return Scaffold(
          backgroundColor: const Color(0xFFE0E0E0),
          body: Center(
            child: Container(
              width: _phoneWidth,
              height: height,
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(44),
                border: Border.all(color: const Color(0xFF30363D), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    blurRadius: 60,
                    spreadRadius: 10,
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              // Re-root MediaQuery so screens inside the frame size themselves
              // against the frame, not the whole browser window — otherwise
              // responsive breakpoints still see a desktop-width viewport.
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: Size(_phoneWidth, height),
                ),
                child: content,
              ),
            ),
          ),
        );
      },
    );
  }
}
