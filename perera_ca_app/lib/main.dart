import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'chalani_screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBaOIOHdDBhftD66uSiz41qmxC2aRMHepQ",
      authDomain: "rubberquality-33cab.firebaseapp.com",
      projectId: "rubberquality-33cab",
      storageBucket: "rubberquality-33cab.firebasestorage.app",
      messagingSenderId: "1039456219056",
      appId: "1:1039456219056:web:7a6432b5805e28f94d3075",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rubber App',
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}