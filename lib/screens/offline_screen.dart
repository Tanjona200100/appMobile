import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

class OfflineScreen extends StatefulWidget {
  const OfflineScreen({Key? key}) : super(key: key);

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  bool _isCheckingConnection = false;

  Future<void> _checkConnection() async {
    setState(() => _isCheckingConnection = true);

    try {
      final connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult != ConnectivityResult.none) {
        // Tester l'accès internet
        final hasInternet = await _testInternetAccess();

        if (hasInternet) {
          Navigator.pushReplacementNamed(context, '/login');
          return;
        }
      }

      setState(() => _isCheckingConnection = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toujours pas de connexion internet'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      setState(() => _isCheckingConnection = false);
    }
  }

  Future<bool> _testInternetAccess() async {
    try {
      final response = await http.get(Uri.parse('https://google.com'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône d'alerte
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off,
                  size: 60,
                  color: Colors.orange,
                ),
              ),

              const SizedBox(height: 32),

              // Titre
              const Text(
                'Hors ligne',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003D82),
                ),
              ),

              const SizedBox(height: 16),

              // Description
              const Text(
                'Une connexion internet est requise pour accéder à l\'application',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Veuillez vérifier votre connexion Wi-Fi ou données mobiles',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 40),

              // Actions
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isCheckingConnection ? null : _checkConnection,
                    icon: _isCheckingConnection
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.refresh),
                    label: Text(
                      _isCheckingConnection ? 'Vérification...' : 'Réessayer',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4B8C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      minimumSize: const Size(200, 50),
                    ),
                  ),

                  const SizedBox(height: 16),


                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}