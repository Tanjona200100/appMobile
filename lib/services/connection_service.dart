import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

/// Service de gestion de la connexion Internet avec détection intelligente
class ConnectionService {
  static final ConnectionService _instance = ConnectionService._internal();
  factory ConnectionService() => _instance;
  ConnectionService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<Map<String, dynamic>> _connectionController =
  StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get connectionStream => _connectionController.stream;

  bool _hasInternet = false;
  bool _isMobileData = false;
  ConnectivityResult _connectionType = ConnectivityResult.none;
  DateTime? _lastCheckTime;

  // Configuration
  static const Duration _checkInterval = Duration(seconds: 30);
  static const List<String> _testUrls = [
    'https://www.google.com',
    'https://www.cloudflare.com',
    'https://1.1.1.1',
  ];

  Timer? _periodicCheckTimer;

  /// Initialiser le service de connexion
  Future<void> initialize() async {
    // Vérifier le statut initial
    await _checkConnection();

    // Écouter les changements de connectivité
    _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);

    // Démarrer les vérifications périodiques
    _startPeriodicCheck();
  }

  /// Vérifier périodiquement la connexion
  void _startPeriodicCheck() {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = Timer.periodic(_checkInterval, (_) async {
      await _checkConnection(notify: false);
    });
  }

  /// Événement de changement de connectivité
  Future<void> _onConnectivityChanged(ConnectivityResult result) async {
    print('🔄 Changement de connectivité détecté: $result');
    _connectionType = result;
    await _checkConnection();
  }

  /// Vérifier la connexion Internet réelle
  Future<void> _checkConnection({bool notify = true}) async {
    final now = DateTime.now();

    // Éviter les vérifications trop fréquentes (minimum 5 secondes entre chaque)
    if (_lastCheckTime != null &&
        now.difference(_lastCheckTime!) < const Duration(seconds: 5)) {
      return;
    }

    _lastCheckTime = now;

    final previousStatus = _hasInternet;

    // 1. Vérifier la connectivité de base
    final connectivityResult = await _connectivity.checkConnectivity();
    _connectionType = connectivityResult;

    if (connectivityResult == ConnectivityResult.none) {
      _hasInternet = false;
      _isMobileData = false;

      if (notify && previousStatus != _hasInternet) {
        _notifyListeners();
      }
      return;
    }

    // 2. Déterminer le type de connexion
    _isMobileData = connectivityResult == ConnectivityResult.mobile;

    // 3. Tester la connexion Internet réelle
    _hasInternet = await _testInternetAccess();

    // 4. Notifier les listeners si le statut a changé
    if (notify && previousStatus != _hasInternet) {
      print('📡 Statut de connexion: ${_hasInternet ? "EN LIGNE" : "HORS LIGNE"}');
      _notifyListeners();
    }
  }

  /// Tester l'accès Internet réel avec plusieurs URLs de secours
  Future<bool> _testInternetAccess() async {
    // Test rapide d'abord avec lookup DNS
    try {
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 3),
      );
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('✅ Test DNS réussi - Internet disponible');
        return true;
      }
    } catch (e) {
      print('⚠️ Test DNS échoué: $e');
    }

    // Si DNS échoue, essayer les requêtes HTTP
    for (final url in _testUrls) {
      try {
        final response = await http.head(Uri.parse(url)).timeout(
          const Duration(seconds: 5),
        );

        if (response.statusCode >= 200 && response.statusCode < 500) {
          print('✅ Test HTTP réussi ($url) - Internet disponible');
          return true;
        }
      } on SocketException catch (e) {
        print('⚠️ SocketException sur $url: $e');
        continue;
      } on TimeoutException catch (e) {
        print('⚠️ Timeout sur $url: $e');
        continue;
      } on HttpException catch (e) {
        print('⚠️ HttpException sur $url: $e');
        continue;
      } catch (e) {
        print('⚠️ Erreur test connexion ($url): $e');
        continue;
      }
    }

    print('❌ Tous les tests de connexion ont échoué');
    return false;
  }

  /// Notifier tous les listeners
  void _notifyListeners() {
    if (!_connectionController.isClosed) {
      _connectionController.add(getCurrentStatusSync());
    }
  }

  /// Obtenir le statut actuel de la connexion (synchrone)
  Map<String, dynamic> getCurrentStatusSync() {
    return {
      'hasInternetPlan': _hasInternet,
      'isMobileData': _isMobileData,
      'connectionType': _connectionType,
      'lastCheck': _lastCheckTime?.toIso8601String(),
      'isWifi': _hasInternet && !_isMobileData,
      'isOffline': !_hasInternet,
    };
  }

  /// Obtenir le statut actuel de la connexion (asynchrone avec vérification)
  Future<Map<String, dynamic>> getCurrentStatus({bool forceCheck = false}) async {
    if (forceCheck) {
      await _checkConnection();
    }
    return getCurrentStatusSync();
  }

  /// Rafraîchir le statut de connexion
  Future<void> refreshStatus() async {
    await _checkConnection();
  }

  /// Vérifier si on a Internet
  bool get hasInternet => _hasInternet;

  /// Vérifier si on est en données mobiles
  bool get isMobileData => _isMobileData;

  /// Vérifier si on est en WiFi
  bool get isWifi => _hasInternet && !_isMobileData;

  /// Vérifier si on est hors ligne
  bool get isOffline => !_hasInternet;

  /// Type de connexion
  ConnectivityResult get connectionType => _connectionType;

  /// Attendre que la connexion soit disponible
  Future<bool> waitForConnection({
    Duration timeout = const Duration(seconds: 30),
    Duration checkInterval = const Duration(seconds: 2),
  }) async {
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < timeout) {
      await _checkConnection();

      if (_hasInternet) {
        return true;
      }

      await Future.delayed(checkInterval);
    }

    return false;
  }

  /// Obtenir une description textuelle du statut
  String getStatusDescription() {
    if (!_hasInternet) {
      return 'Hors ligne';
    }

    if (_isMobileData) {
      return 'Données mobiles';
    }

    return 'WiFi';
  }

  /// Obtenir une icône appropriée pour le statut
  String getStatusIcon() {
    if (!_hasInternet) {
      return '📵'; // Hors ligne
    }

    if (_isMobileData) {
      return '📱'; // Données mobiles
    }

    return '📶'; // WiFi
  }

  /// Nettoyer les ressources
  void dispose() {
    _periodicCheckTimer?.cancel();
    _connectionController.close();
  }
}