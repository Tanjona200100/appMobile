import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/connection_service.dart';

mixin ConnectionMixin<T extends StatefulWidget> on State<T> {
  final ConnectionService _connectionService = ConnectionService();
  bool _hasInternet = false;
  bool _isMobileData = false;
  ConnectivityResult _connectionType = ConnectivityResult.none;
  StreamSubscription? _connectionSubscription;

  @override
  void initState() {
    super.initState();
    _initConnectionListener();
  }

  void _initConnectionListener() async {
    // Obtenir le statut initial
    final initialStatus = await _connectionService.getCurrentStatus();
    if (mounted) {
      setState(() {
        _updateStateFromStatus(initialStatus);
      });
    }

    // Écouter les changements
    _connectionSubscription = _connectionService.connectionStream.listen((status) {
      if (mounted) {
        setState(() {
          _updateStateFromStatus(status);
        });
        onConnectionStatusChanged(status);
      }
    });
  }

  void _updateStateFromStatus(Map<String, dynamic> status) {
    _hasInternet = status['hasInternetPlan'] ?? false;
    _isMobileData = status['isMobileData'] ?? false;
    _connectionType = status['connectionType'] ?? ConnectivityResult.none;
  }

  // Méthode overrideable pour réagir aux changements
  void onConnectionStatusChanged(Map<String, dynamic> status) {
    // À override dans les pages qui utilisent le mixin
  }

  // Getters pratiques
  bool get hasInternet => _hasInternet;
  bool get isMobileData => _isMobileData;
  bool get isWifi => _hasInternet && !_isMobileData;
  bool get isOffline => !_hasInternet;
  ConnectivityResult get connectionType => _connectionType;

  // Méthode pour afficher un snackbar de statut
  void showConnectionSnackbar(BuildContext context, {String? customMessage}) {
    final message = customMessage ?? (
        _hasInternet
            ? (_isMobileData
            ? 'Connecté en données mobiles'
            : 'Connecté en WiFi')
            : 'Pas de connexion internet'
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

  // Vérifier la connexion avant une action
  Future<bool> checkConnectionBeforeAction(BuildContext context, {String? actionName}) async {
    final status = await _connectionService.getCurrentStatus();

    if (!status['hasInternetPlan']) {
      _showNoConnectionDialog(context, actionName);
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
        content: Text(
          actionName != null
              ? 'Une connexion internet est nécessaire pour $actionName'
              : 'Une connexion internet est nécessaire pour cette action',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _connectionService.refreshStatus();
            },
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }
}