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
  }
}

// Wraps the app in a phone-sized frame in the browser
class MobileFrame extends StatelessWidget {
  final Widget? child;
  const MobileFrame({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // A real phone should use all available space. The decorative frame is
        // reserved for browser and desktop previews.
        if (constraints.maxWidth < 600) return child ?? const SizedBox.shrink();

        return Scaffold(
          backgroundColor: const Color(0xFFE6EEE8),
          body: Center(
            child: Container(
              width: 412,
              height: 860,
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(38),
                border: Border.all(color: const Color(0xFFCBD9CF), width: 8),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.18),
                    blurRadius: 52,
                    offset: const Offset(0, 22),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
