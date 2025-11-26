import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

/// Mixin pour gérer la connexion Internet de manière fiable
mixin ConnectionMixin<T extends StatefulWidget> on State<T> {
  final Connectivity _connectivity = Connectivity();

  bool _hasInternet = false;
  bool _isMobileData = false;
  ConnectivityResult _connectionType = ConnectivityResult.none;
  StreamSubscription? _connectionSubscription;
  Timer? _periodicCheckTimer;

  @override
  void initState() {
    super.initState();
    _initConnectionListener();
  }

  void _initConnectionListener() async {
    // Vérifier le statut initial immédiatement
    await _checkRealConnection();

    // Écouter les changements de connectivité
    _connectionSubscription = _connectivity.onConnectivityChanged.listen((result) async {
      print('🔔 Changement de connectivité: $result');
      _connectionType = result;
      await _checkRealConnection();
    });

    // Vérifications périodiques (toutes les 30 secondes)
    _startPeriodicCheck();
  }

  /// Vérifier périodiquement la connexion
  void _startPeriodicCheck() {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _checkRealConnection(silent: true);
    });
  }

  /// Vérifier la connexion Internet réelle
  Future<void> _checkRealConnection({bool silent = false}) async {
    final previousStatus = _hasInternet;

    // 1. Vérifier la connectivité de base
    final connectivityResult = await _connectivity.checkConnectivity();
    _connectionType = connectivityResult;

    if (!silent) {
      print('📡 Type de connexion: $connectivityResult');
    }

    // 2. Si aucune connectivité réseau
    if (connectivityResult == ConnectivityResult.none) {
      if (mounted) {
        setState(() {
          _hasInternet = false;
          _isMobileData = false;
        });
      }

      if (!silent && previousStatus != _hasInternet) {
        onConnectionStatusChanged({
          'hasInternetPlan': false,
          'isMobileData': false,
          'connectionType': connectivityResult,
        });
      }
      return;
    }

    // 3. Déterminer le type de connexion
    _isMobileData = connectivityResult == ConnectivityResult.mobile;

    // 4. Tester l'accès Internet réel
    final hasRealInternet = await _testInternetConnection();

    if (mounted) {
      setState(() {
        _hasInternet = hasRealInternet;
      });
    }

    if (!silent) {
      print('🌐 Internet disponible: $hasRealInternet');
    }

    // 5. Notifier si changement de statut
    if (!silent && previousStatus != _hasInternet) {
      onConnectionStatusChanged({
        'hasInternetPlan': _hasInternet,
        'isMobileData': _isMobileData,
        'connectionType': connectivityResult,
      });
    }
  }

  /// Tester la connexion Internet avec plusieurs méthodes
  Future<bool> _testInternetConnection() async {
    // Méthode 1 : Test DNS (le plus rapide)
    try {
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 3),
      );
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('✅ Test DNS réussi');
        return true;
      }
    } catch (e) {
      print('⚠️ Test DNS échoué: ${e.runtimeType}');
    }

    // Méthode 2 : Requête HTTP HEAD (plus léger que GET)
    final testUrls = [
      'https://www.google.com',
      'https://www.cloudflare.com',
      'https://1.1.1.1',
    ];

    for (final url in testUrls) {
      try {
        final response = await http.head(Uri.parse(url)).timeout(
          const Duration(seconds: 5),
        );

        // Accepter tout code de statut valide (même 4xx)
        if (response.statusCode >= 200 && response.statusCode < 500) {
          print('✅ Test HTTP réussi sur $url');
          return true;
        }
      } catch (e) {
        print('⚠️ Échec sur $url: ${e.runtimeType}');
        continue;
      }
    }

    // Méthode 3 : Test socket direct (dernier recours)
    try {
      final socket = await Socket.connect(
        '8.8.8.8',
        53,
        timeout: const Duration(seconds: 3),
      );
      socket.destroy();
      print('✅ Test socket réussi');
      return true;
    } catch (e) {
      print('⚠️ Test socket échoué: ${e.runtimeType}');
    }

    return false;
  }

  /// Méthode à override pour réagir aux changements
  void onConnectionStatusChanged(Map<String, dynamic> status) {
    // À implémenter dans les classes qui utilisent le mixin
  }

  /// Getters pratiques
  bool get hasInternet => _hasInternet;
  bool get isMobileData => _isMobileData;
  bool get isWifi => _hasInternet && !_isMobileData;
  bool get isOffline => !_hasInternet;
  ConnectivityResult get connectionType => _connectionType;

  /// Forcer une nouvelle vérification
  Future<void> recheckConnection() async {
    print('🔄 Vérification forcée de la connexion...');
    await _checkRealConnection();
  }

  /// Afficher un snackbar de statut
  void showConnectionSnackbar(BuildContext context, {String? customMessage}) {
    final message = customMessage ?? (
        _hasInternet
            ? (_isMobileData
            ? '📱 Connecté en données mobiles'
            : '📶 Connecté en WiFi')
            : '📵 Pas de connexion internet'
    );

    final color = _hasInternet
        ? (_isMobileData ? Colors.orange : Colors.green)
        : Colors.red;

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _hasInternet
                  ? (_isMobileData ? Icons.network_cell : Icons.wifi)
                  : Icons.wifi_off,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Vérifier la connexion avant une action
  Future<bool> checkConnectionBeforeAction(
      BuildContext context, {
        String? actionName,
        bool showDialog = true,
      }) async {
    // Forcer une vérification fraîche
    await recheckConnection();

    if (!_hasInternet) {
      if (showDialog) {
        _showNoConnectionDialog(context, actionName);
      }
      return false;
    }

    return true;
  }

  void _showNoConnectionDialog(BuildContext context, String? actionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.red),
            SizedBox(width: 8),
            Text('Connexion requise'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              actionName != null
                  ? 'Une connexion internet est nécessaire pour $actionName'
                  : 'Une connexion internet est nécessaire pour cette action',
            ),
            const SizedBox(height: 12),
            const Text(
              'Vérifiez que :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Le WiFi ou les données mobiles sont activés'),
            const Text('• Vous avez un forfait internet actif'),
            const Text('• Le mode avion est désactivé'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await recheckConnection();

              if (_hasInternet && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Connexion rétablie !'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⚠️ Toujours pas de connexion'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  /// Attendre qu'une connexion soit disponible
  Future<bool> waitForConnection({
    Duration timeout = const Duration(seconds: 30),
    Duration checkInterval = const Duration(seconds: 2),
  }) async {
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < timeout) {
      await _checkRealConnection(silent: true);

      if (_hasInternet) {
        return true;
      }

      await Future.delayed(checkInterval);
    }

    return false;
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _periodicCheckTimer?.cancel();
    super.dispose();
  }
}