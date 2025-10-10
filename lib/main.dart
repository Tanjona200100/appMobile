import 'package:flutter/material.dart';
import 'pages/login_screen.dart'; // Importez LoginScreen

void main() {
  runApp(const KarStatApp());
}

class KarStatApp extends StatelessWidget {
  const KarStatApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KarStat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const LoginScreen(), // Page de login comme écran initial
    );
  }
}