import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/app_theme.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const LatexGuardApp());
}

class LatexGuardApp extends StatelessWidget {
  const LatexGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LatexGuard — Supervisor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const MobileFrame(),
    );
  }
}

// Wraps the app in a phone-sized frame in the browser
class MobileFrame extends StatelessWidget {
  const MobileFrame({super.key});

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
          child: const LoginScreen(),
        ),
      ),
    );
  }
}