import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isCheckingConnection = true;
  bool _hasInternet = false;

  @override
  void initState() {
    super.initState();
    _checkInternetConnection();
  }

  // -------------------------------------------------------------
  // Vérification connexion + accès Internet réel
  // -------------------------------------------------------------
  Future<void> _checkInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        setState(() {
          _hasInternet = false;
          _isCheckingConnection = false;
        });
        await Future.delayed(const Duration(seconds: 2));
        _navigateToOfflineScreen();
        return;
      }

      final hasInternet = await _testInternetAccess();

      setState(() {
        _hasInternet = hasInternet;
        _isCheckingConnection = false;
      });

      await Future.delayed(const Duration(seconds: 1));

      if (hasInternet) {
        _navigateToLoginScreen();
      } else {
        _navigateToOfflineScreen();
      }
    } catch (_) {
      setState(() {
        _hasInternet = false;
        _isCheckingConnection = false;
      });

      await Future.delayed(const Duration(seconds: 2));
      _navigateToOfflineScreen();
    }
  }

  Future<bool> _testInternetAccess() async {
    try {
      final testServers = ['google.com', 'cloudflare.com', 'github.com'];

      for (final server in testServers) {
        try {
          final result = await InternetAddress.lookup(server);
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            final response = await http
                .get(Uri.parse('https://$server'))
                .timeout(const Duration(seconds: 5));
            if (response.statusCode == 200) return true;
          }
        } catch (_) {}
        await Future.delayed(const Duration(milliseconds: 300));
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  void _navigateToLoginScreen() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _navigateToOfflineScreen() {
    Navigator.pushReplacementNamed(context, '/offline');
  }

  // -------------------------------------------------------------
  // Animation 5 points style Facebook Lite
  // -------------------------------------------------------------
  Widget _buildFacebookDots() {
    return TweenAnimationBuilder(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1300),
      curve: Curves.linear,
      builder: (context, value, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            double activation = (value - (i * 0.18)).clamp(0.0, 1.0);
            bool isFilled = activation > 0.6;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.blue[800]!,
                  width: 2,
                ),
                color: isFilled ? Colors.blue[800] : Colors.white,
              ),
            );
          }),
        );
      },
      onEnd: () {
        setState(() {}); // boucle infinie
      },
    );
  }

  // -------------------------------------------------------------
  // UI
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ---------------- LOGO PNG ----------------
            Container(
              width: 130,
              height: 130,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  "assets/image/logo.png",
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 50),

            // Animation des 5 points
            _buildFacebookDots(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
