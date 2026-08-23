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
        child: MobileFrame(child: child),
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
    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0),
      body: Center(
        child: Container(
          width: 390,
          height: 844,
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(44),
            border: Border.all(
              color: const Color(0xFF30363D),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.08),
                blurRadius: 60,
                spreadRadius: 10,
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: child,
        ),
      ),
    );
  }
}