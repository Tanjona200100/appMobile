import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
// Ajout des imports Flutter manquants
import 'package:flutter/material.dart';

class ConnectionService {
  static final ConnectionService _instance = ConnectionService._internal();
  factory ConnectionService() => _instance;
  ConnectionService._internal();

  final Connectivity _connectivity = Connectivity();
  ConnectivityResult _connectionType = ConnectivityResult.none;
  bool _hasInternetPlan = false;
  bool _isChecking = false;

  // Getters pour l'état actuel
  ConnectivityResult get connectionType => _connectionType;
  bool get hasInternetPlan => _hasInternetPlan;
  bool get isChecking => _isChecking;
  bool get isMobileData => _connectionType == ConnectivityResult.mobile;
  bool get isWifi => _connectionType == ConnectivityResult.wifi;

  // Stream pour écouter les changements
  Stream<Map<String, dynamic>> get connectionStream async* {
    // Émettre l'état initial
    final initialStatus = await getCurrentStatus();
    yield initialStatus;

    // Écouter les changements
    await for (final result in _connectivity.onConnectivityChanged) {
      final newStatus = await _updateStatus(result);
      yield newStatus;
    }
  }

  // Obtenir le statut actuel
  Future<Map<String, dynamic>> getCurrentStatus() async {
    await _checkConnectionType();
    await _testInternetAccess();

    return _buildStatusMap();
  }

  // Vérifier le type de connexion
  Future<void> _checkConnectionType() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _connectionType = result;
    } catch (e) {
      _connectionType = ConnectivityResult.none;
    }
  }

  // Tester l'accès internet
  Future<void> _testInternetAccess() async {
    if (_isChecking) return;

    _isChecking = true;

    bool hasAccess = false;
    final testServers = ['google.com', 'cloudflare.com', 'github.com'];

    for (final server in testServers) {
      try {
        final hasPing = await _testPing(server);
        if (hasPing) {
          final hasHttp = await _testHttpAccess('https://$server');
          if (hasHttp) {
            hasAccess = true;
            break;
          }
        }
      } catch (e) {
        // Continuer avec le serveur suivant
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }

    _hasInternetPlan = hasAccess;
    _isChecking = false;
  }

  // Mettre à jour le statut
  Future<Map<String, dynamic>> _updateStatus(ConnectivityResult result) async {
    _connectionType = result;
    await _testInternetAccess();

    return _buildStatusMap();
  }

  // Construire le map de statut
  Map<String, dynamic> _buildStatusMap() {
    return {
      'connectionType': _connectionType,
      'hasInternetPlan': _hasInternetPlan,
      'isMobileData': isMobileData,
      'isWifi': isWifi,
      'isChecking': _isChecking,
      'statusText': _getStatusText(),
      'statusColor': _getStatusColor(),
      'statusIcon': _getStatusIcon(),
    };
  }

  // Rafraîchir manuellement
  Future<Map<String, dynamic>> refreshStatus() async {
    return await getCurrentStatus();
  }

  // Méthodes de test réseau
  Future<bool> _testPing(String host) async {
    try {
      final result = await InternetAddress.lookup(host);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<bool> _testHttpAccess(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Méthodes d'helpers pour l'UI
  String _getStatusText() {
    if (_isChecking) return 'Vérification...';
    if (!_hasInternetPlan) {
      return _connectionType == ConnectivityResult.none
          ? 'Hors ligne'
          : 'Pas d\'internet';
    }
    return isMobileData ? 'Données mobiles' : 'WiFi';
  }

  Color _getStatusColor() {
    if (_isChecking) return Colors.blue;
    if (!_hasInternetPlan) return Colors.red;
    return isMobileData ? Colors.orange : Colors.green;
  }

  IconData _getStatusIcon() {
    if (_isChecking) return Icons.search;
    if (!_hasInternetPlan) return Icons.wifi_off;
    return isMobileData ? Icons.network_cell : Icons.wifi;
  }
}