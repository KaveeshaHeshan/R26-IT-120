// TEMPORARY preview entrypoint used only to visually verify the
// farmer_screens redesign in a browser. Not part of the app; safe to delete.
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/app_theme.dart';
import 'screens/farmer_screens/core/farmer_settings.dart';
import 'screens/farmer_screens/farmer_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const _PreviewApp());
}

class _PreviewApp extends StatefulWidget {
  const _PreviewApp();

  @override
  State<_PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<_PreviewApp> {
  final FarmerSettings _settings = FarmerSettings();

  @override
  void initState() {
    super.initState();
    _settings.load();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farmer Preview',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      builder: (context, child) => FarmerSettingsScope(settings: _settings, child: child!),
      home: Scaffold(
        backgroundColor: const Color(0xFFE0E0E0),
        body: Center(
          child: Container(
            width: 390,
            height: 844,
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(44),
              border: Border.all(color: const Color(0xFF30363D), width: 2),
            ),
            clipBehavior: Clip.hardEdge,
            child: const FarmerDashboardScreen(
              userId: 'preview-debug-user',
              welcomeMessage: 'Preview',
            ),
          ),
        ),
      ),
    );
  }
}
