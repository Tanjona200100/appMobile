import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kartstat/services/connection_service.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/offline_screen.dart';
import 'screens/side_menu.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialiser le service de connexion
  await ConnectionService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KARTSTAT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/offline': (context) => const OfflineScreen(),
        '/side-menu': (context) => const SideMenu(),
      },
    );
  }
}
