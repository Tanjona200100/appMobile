import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/form_data.dart';
import '../controllers/form_controllers.dart';
import '../services/image_manager.dart';
import '../services/unified_storage_service.dart';
import '../services/curl_generator.dart';
import '../services/auto_sync_service.dart';
import '../widgets/menu_widget.dart';
import '../widgets/form_widgets.dart';
import 'continue_screen.dart';
import '../utils/connection_mixin.dart';
import 'login_screen.dart';
import '../services/json_consolidation_service.dart';
/// Classe principale représentant le menu latéral et le dashboard
class SideMenu extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String? authToken;

  const SideMenu({
    Key? key,
    this.userData,
    this.authToken,
  }) : super(key: key);

  @override
  State<SideMenu> createState() => _SideMenuState();
}

/// Classe d'état pour gérer l'interface principale avec menu latéral et contenu
class _SideMenuState extends State<SideMenu> with ConnectionMixin {
  int _selectedIndex = 0;
  bool _isMenuCollapsed = true;
  bool _isMenuOverlay = false;
  final double _menuWidth = 98.0;
  final double _expandedMenuWidth = 250.0;
  final double _dashboardWidth = 702.0;

  // Services et contrôleurs
  final FormControllers _controllers = FormControllers();
  final ImageManager _imageManager = ImageManager();
  final UnifiedStorageService _storageService = UnifiedStorageService();
  final CurlGenerator _curlGenerator = CurlGenerator();
  final AutoSyncService _autoSyncService = AutoSyncService();
  final JsonConsolidationService _consolidationService = JsonConsolidationService();

  // Configuration
  bool _autoSyncEnabled = true;
  String _typeContrat = 'Co-gestion';

  // Données des formulaires
  List<FormData> _allForms = [];
  bool _isLoadingForms = false;

  // File d'attente pour la synchronisation hors ligne
  List<FormData> _pendingSyncForms = [];
  bool _isSyncing = false;
  int _currentSyncProgress = 0;
  int _totalSyncItems = 0;

  String? _authToken;
  Map<String, dynamic>? _userData;
  String _agentName = 'Agent';

Map<String, dynamic> _masterStats = {};

  // Statistiques pour le dashboard
  Map<String, dynamic> _dashboardStats = {
    'total_forms': 0,
    'today_forms': 0,
    'by_region': {},
    'by_commune': {},
  };

  // Overlay entry pour le menu superposé
  OverlayEntry? _menuOverlayEntry;

@override
void initState() {
  super.initState();
  
  // Initialiser les listes pour éviter les null
  _allForms = [];
  _pendingSyncForms = [];
  
  _loadUserData();
  _initializeApp();
}

  /// Initialise l'application
 void _initializeApp() async {
    await _loadAllForms();
    await _loadPendingSyncForms();
    await _loadMasterStats();
    _startConnectionListener();
    _startAutoSyncListener();
  }


Future<void> _loadMasterStats() async {
    try {
      final stats = await _consolidationService.getMasterStats();
      setState(() {
        _masterStats = stats;
      });
    } catch (e) {
      print('Erreur chargement stats master: $e');
    }
  }

Future<void> _consolidateAllJsonFiles() async {
    try {
      _showSnackBar('🔄 Consolidation en cours...', Colors.blue);
      
      final result = await _consolidationService.consolidateAllJsonFiles();
      
      if (result['success'] == true) {
        await _loadMasterStats();
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                const Text('Consolidation réussie'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✅ Fichier master créé avec succès'),
                  const SizedBox(height: 12),
                  _buildResultRow('Formulaires uniques', '${result['total_forms']}'),
                  _buildResultRow('Fichiers source', '${result['source_files']}'),
                  _buildResultRow('Doublons supprimés', '${result['duplicates_removed']}'),
                  if (result['errors'] > 0)
                    _buildResultRow('Erreurs', '${result['errors']}', Colors.orange),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 20, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Fichier: ${result['file_path']}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final exportPath = await _consolidationService.exportMasterFile();
                  if (exportPath != null) {
                    _showSnackBar('✅ Export réussi: $exportPath', Colors.green);
                  }
                },
                child: const Text('Exporter'),
              ),
            ],
          ),
        );
      } else {
        _showSnackBar('❌ Erreur: ${result['error']}', Colors.red);
      }
    } catch (e) {
      _showSnackBar('❌ Erreur consolidation: $e', Colors.red);
    }
  }

Widget _buildResultRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor ?? const Color(0xFF003D82),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _checkDuplicatesInMaster(String uuid, String numeroCIN) async {
    try {
      // Vérifier UUID
      final uuidExists = await _consolidationService.uuidExistsInMaster(uuid);
      if (uuidExists) {
        _showSnackBar('⚠️ Cet UUID existe déjà dans le fichier master', Colors.orange);
        return true;
      }

      // Vérifier CIN
      if (numeroCIN.isNotEmpty) {
        final cinExists = await _consolidationService.cinExistsInMaster(numeroCIN);
        if (cinExists) {
          _showSnackBar('⚠️ Ce numéro CIN existe déjà dans le fichier master', Colors.orange);
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Erreur vérification doublons: $e');
      return false;
    }
  }

  /// Charge les données utilisateur
  Future<void> _loadUserData() async {
    try {
      _authToken = widget.authToken;
      _userData = widget.userData;

      if (_userData != null) {
        _agentName = _userData!['name'] ??
            _userData!['email']?.split('@')[0] ??
            'Agent';
      }

      // Sauvegarder dans SharedPreferences
      if (_authToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _authToken!);
        if (_userData != null) {
          await prefs.setString('user_data', jsonEncode(_userData));
        }
      }

      setState(() {});
    } catch (e) {
      print('Erreur chargement données utilisateur: $e');
    }
  }

  /// Démarre l'écoute des changements de connectivité
  void _startConnectionListener() {
    _checkInitialConnection();

    Connectivity().onConnectivityChanged.listen((result) async {
      final wasOnline = hasInternet;

      if (result == ConnectivityResult.none) {
        if (mounted) setState(() {});
        _showConnectionPopup(false);
        return;
      }

      await Future.delayed(const Duration(seconds: 1));

      final hasRealInternet = await _testInternetAccess();
      if (mounted) setState(() {});

      if (hasRealInternet) {
        _showConnectionPopup(true);

        if (!wasOnline && _pendingSyncForms.isNotEmpty) {
          await Future.delayed(const Duration(seconds: 2));
          if (hasInternet && mounted && !_isSyncing) {
            await _syncPendingForms();
          }
        }
      } else {
        _showConnectionPopup(false);
      }
    });
  }

  /// Démarre l'écoute pour la synchronisation automatique
  void _startAutoSyncListener() {
    Future.delayed(const Duration(minutes: 5), () async {
      if (!mounted) return;

      if (_pendingSyncForms.isNotEmpty && hasInternet && !_isSyncing) {
        print('⏰ Synchronisation périodique automatique...');
        await _syncPendingForms();
      }

      if (mounted) {
        _startAutoSyncListener();
      }
    });
  }

  /// Teste l'accès réel à Internet
  Future<bool> _testInternetAccess() async {
    print('🔍 Test connexion...');

    // Test DNS
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('✅ DNS OK');
        return true;
      }
    } catch (e) {
      print('⚠️ DNS échoué');
    }

    // Test HTTP
    for (final url in ['https://www.google.com', 'https://dns.google']) {
      try {
        final response = await http.head(Uri.parse(url))
            .timeout(const Duration(seconds: 5));
        if (response.statusCode >= 200 && response.statusCode < 500) {
          print('✅ HTTP OK');
          return true;
        }
      } catch (e) {
        continue;
      }
    }

    // Test Socket
    try {
      final socket = await Socket.connect('8.8.8.8', 53,
          timeout: const Duration(seconds: 3));
      socket.destroy();
      print('✅ Socket OK');
      return true;
    } catch (e) {
      print('⚠️ Socket échoué');
    }

    return false;
  }

  /// Vérifie la connexion initiale
  Future<void> _checkInitialConnection() async {
    print('🚀 Vérification initiale...');
    final result = await Connectivity().checkConnectivity();
    if (result != ConnectivityResult.none) {
      await _testInternetAccess();
      if (mounted) setState(() {});
    }
  }

  /// Affiche une popup d'information sur le statut de connexion
  void _showConnectionPopup(bool isOnline) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isOnline ? Icons.wifi : Icons.wifi_off,
              color: isOnline ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(isOnline ? 'Connexion rétablie' : 'Hors ligne'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isOnline
                  ? 'Votre appareil est maintenant connecté à Internet.'
                  : 'Votre appareil n\'est pas connecté à Internet. Les données seront sauvegardées localement.',
            ),
            if (isOnline && _pendingSyncForms.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_pendingSyncForms.length} formulaire(s) en attente de synchronisation',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          if (isOnline && _pendingSyncForms.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _syncPendingForms();
              },
              icon: const Icon(Icons.sync, size: 16),
              label: const Text('Synchroniser maintenant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1AB999),
              ),
            ),
        ],
      ),
    );
  }

  /// Gère le toggle du menu
  void _toggleMenu() {
    setState(() {
      if (_isMenuCollapsed) {
        _isMenuOverlay = true;
        _isMenuCollapsed = false;
        _showMenuOverlay();
      } else {
        _isMenuOverlay = false;
        _isMenuCollapsed = true;
        _hideMenuOverlay();
      }
    });
  }

  /// Affiche le menu en overlay
  void _showMenuOverlay() {
    if (_menuOverlayEntry != null) {
      _menuOverlayEntry!.remove();
    }

    _menuOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 0,
        top: 0,
        bottom: 0,
        child: GestureDetector(
          onTap: _toggleMenu,
          child: Container(
            color: Colors.transparent,
            width: MediaQuery.of(context).size.width,
            child: Row(
              children: [
                Material(
                  color: Colors.white,
                  elevation: 8,
                  child: Container(
                    width: _expandedMenuWidth,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(2, 0),
                        ),
                      ],
                    ),
                    child: MenuWidget(
                      selectedIndex: _selectedIndex,
                      isMenuCollapsed: false,
                      onMenuItemTap: (index) {
                        setState(() => _selectedIndex = index);
                        _hideMenuOverlay();
                        _isMenuCollapsed = true;
                        _isMenuOverlay = false;
                      },
                      onToggleMenu: _toggleMenu,
                      onLogout: _handleLogout,
                      pendingSyncCount: _pendingSyncForms.length,
                      userName: _agentName,
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _toggleMenu,
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_menuOverlayEntry!);
  }

  /// Cache le menu overlay
  void _hideMenuOverlay() {
    if (_menuOverlayEntry != null) {
      _menuOverlayEntry!.remove();
      _menuOverlayEntry = null;
    }
  }

  @override
  void onConnectionStatusChanged(Map<String, dynamic> status) {}

  @override
  void dispose() {
    _controllers.dispose();
    _hideMenuOverlay();
    super.dispose();
  }

  /// Charge tous les formulaires depuis le stockage local
  Future<void> _loadAllForms() async {
  setState(() => _isLoadingForms = true);
  try {
    final forms = await _storageService.getAllForms();

    // Vérifier si forms est null
    if (forms == null) {
      setState(() {
        _allForms = [];
        _isLoadingForms = false;
      });
      return;
    }

    final uniqueForms = <String, FormData>{};
    final seenCINs = <String>{};
    final seenUUIDs = <String>{};

    for (var form in forms) {
      // Vérifier si form.identite est null
      final identite = form.identite ?? {};
      final cin = identite['cin'] as Map<String, dynamic>? ?? {};
      final numeroCIN = cin['numero']?.toString().trim() ?? '';
      final uuid = form.uuid;

      bool isDuplicate = false;

      if (numeroCIN.isNotEmpty && seenCINs.contains(numeroCIN)) {
        isDuplicate = true;
      } else if (numeroCIN.isNotEmpty) {
        seenCINs.add(numeroCIN);
      }

      if (seenUUIDs.contains(uuid)) {
        isDuplicate = true;
      } else {
        seenUUIDs.add(uuid);
      }

      if (!isDuplicate) {
        uniqueForms[uuid] = form;
      }
    }

    setState(() {
      _allForms = uniqueForms.values.toList();
      _isLoadingForms = false;
    });
    _loadDashboardStats();
  } catch (e) {
    print('Erreur chargement formulaires: $e');
    setState(() {
      _allForms = [];
      _isLoadingForms = false;
    });
    _showSnackBar('Erreur chargement: $e', Colors.red);
  }
}

  /// Charge les formulaires en attente de synchronisation
Future<void> _loadPendingSyncForms() async {
  try {
    final pendingForms = await _storageService.getPendingSyncForms();
    setState(() {
      _pendingSyncForms = pendingForms ?? []; // Utiliser liste vide si null
    });
  } catch (e) {
    print('Erreur chargement formulaires en attente: $e');
    setState(() {
      _pendingSyncForms = [];
    });
  }
}

  /// Synchronise les formulaires en attente
  Future<void> _syncPendingForms() async {
    if (_pendingSyncForms.isEmpty) {
      _showSnackBar('Aucun formulaire en attente', Colors.blue);
      return;
    }

    if (!hasInternet) {
      _showSnackBar('Pas de connexion Internet. Synchronisation impossible.', Colors.orange);
      return;
    }

    if (_isSyncing) {
      _showSnackBar('Synchronisation déjà en cours...', Colors.orange);
      return;
    }

    setState(() {
      _isSyncing = true;
      _currentSyncProgress = 0;
      _totalSyncItems = _pendingSyncForms.length;
    });

    _showSnackBar('Synchronisation de ${_pendingSyncForms.length} formulaire(s) en cours...', Colors.blue);

    try {
      final result = await _autoSyncService.syncMultipleForms(
        List.from(_pendingSyncForms),
        onProgress: (current, total) {
          if (mounted) {
            setState(() {
              _currentSyncProgress = current;
              _totalSyncItems = total;
            });
          }
        },
      );

      setState(() {
        _isSyncing = false;
      });

      if (result['success'] == true) {
        final successCount = result['success_count'] ?? 0;
        final failureCount = result['failure_count'] ?? 0;
        final duplicateCount = result['duplicate_count'] ?? 0;
        final failedUuids = result['failed_uuids'] as List<String>? ?? [];
        final errors = result['errors'] as Map<String, String>? ?? {};

        _showSyncResultDialog(
          successCount: successCount,
          failureCount: failureCount,
          duplicateCount: duplicateCount,
          errors: errors,
        );

        await _updateFormSyncStatus(failedUuids, errors);

      } else {
        _showSnackBar('❌ Erreur de synchronisation générale', Colors.red);
      }
    } catch (e) {
      setState(() {
        _isSyncing = false;
      });
      _showSnackBar('❌ Erreur synchronisation: $e', Colors.red);
      print('Erreur globale de synchronisation: $e');
    }
  }

  /// Met à jour les statuts de synchronisation des formulaires
  Future<void> _updateFormSyncStatus(List<String> failedUuids, Map<String, String> errors) async {
    for (var form in List.from(_pendingSyncForms)) {
      if (!failedUuids.contains(form.uuid)) {
        form.metadata['sync_status'] = 'synced';
        form.metadata['synced_at'] = DateTime.now().toIso8601String();
        form.metadata.remove('pending_since');
        form.metadata.remove('sync_error');

        await _storageService.saveFormData(form);
        await _storageService.removeFromPendingSync(form.uuid);

        setState(() {
          _pendingSyncForms.removeWhere((f) => f.uuid == form.uuid);
        });
      } else {
        form.metadata['sync_status'] = 'failed';
        form.metadata['last_attempt'] = DateTime.now().toIso8601String();
        form.metadata['attempt_count'] = (form.metadata['attempt_count'] ?? 0) + 1;
        form.metadata['sync_error'] = errors[form.uuid] ?? 'Erreur inconnue';

        await _storageService.saveFormData(form);
      }
    }

    await _loadAllForms();
  }

  /// Affiche le résultat détaillé de la synchronisation
  void _showSyncResultDialog({
    required int successCount,
    required int failureCount,
    required int duplicateCount,
    required Map<String, String> errors,
  }) {
    showDialog(
      context: context,
      barrierDismissible: failureCount == 0,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              failureCount == 0 ? Icons.check_circle : Icons.warning,
              color: failureCount == 0 ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(failureCount == 0 ? 'Synchronisation réussie' : 'Synchronisation partielle'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (successCount > 0) ...[
                _buildSyncResultItem('✅ Synchronisés avec succès', successCount),
                const SizedBox(height: 8),
              ],
              if (duplicateCount > 0) ...[
                _buildSyncResultItem('ℹ️ Déjà sur le serveur', duplicateCount),
                const SizedBox(height: 8),
              ],
              if (failureCount > 0) ...[
                _buildSyncResultItem('❌ Échecs de synchronisation', failureCount),
                const SizedBox(height: 12),
                const Text(
                  'Détails des erreurs:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...errors.entries.map((error) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '• ${error.key}: ${error.value}',
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                )).toList(),
              ],
            ],
          ),
        ),
        actions: [
          if (failureCount > 0)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ignorer'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (failureCount > 0) {
                _showFailedFormsDetails(errors);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: failureCount > 0 ? Colors.orange : const Color(0xFF1AB999),
            ),
            child: Text(failureCount > 0 ? 'Voir les détails' : 'Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncResultItem(String text, int count) {
    return Row(
      children: [
        Expanded(child: Text(text)),
        Text(
          count.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// Affiche les détails des formulaires qui ont échoué
 void _showFailedFormsDetails(Map<String, String> errors) {
  // Vérifier si _pendingSyncForms est null
  final pendingForms = _pendingSyncForms ?? [];
  
  final failedForms = pendingForms.where(
    (form) => errors.containsKey(form.uuid)
  ).toList();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Formulaires en échec'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: failedForms.length,
          itemBuilder: (context, index) {
            final form = failedForms[index];
            final error = errors[form.uuid] ?? 'Erreur inconnue';
            
            // Vérifier si form.identite est null
            final identite = form.identite ?? {};
            final nom = identite['nom'] ?? 'N/A';
            final prenom = identite['prenom'] ?? 'N/A';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text('$nom $prenom'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('UUID: ${form.uuid.substring(0, 8)}...'),
                    const SizedBox(height: 4),
                    Text(
                      'Erreur: $error',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.blue),
                      onPressed: () => _retrySingleForm(form),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info, color: Colors.orange),
                      onPressed: () => _showFormDetails(form, error),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
        ElevatedButton(
          onPressed: () => _syncPendingForms(),
          child: const Text('Réessayer tout'),
        ),
      ],
    ),
  );
}

  /// Réessaye un formulaire individuellement
  Future<void> _retrySingleForm(FormData form) async {
    if (!hasInternet) {
      _showSnackBar('Pas de connexion Internet', Colors.orange);
      return;
    }

    _showSnackBar('Nouvelle tentative pour ${form.identite['nom']}...', Colors.blue);

    try {
      final success = await _autoSyncService.syncFormToServer(form);

      if (success == true) {
        form.metadata['sync_status'] = 'synced';
        form.metadata['synced_at'] = DateTime.now().toIso8601String();
        form.metadata.remove('pending_since');
        form.metadata.remove('sync_error');

        await _storageService.saveFormData(form);
        await _storageService.removeFromPendingSync(form.uuid);

        setState(() {
          _pendingSyncForms.removeWhere((f) => f.uuid == form.uuid);
        });

        _showSnackBar('✅ Formulaire synchronisé avec succès!', Colors.green);
      } else {
        _showSnackBar('❌ Nouvel échec pour ce formulaire', Colors.red);
      }
    } catch (e) {
      _showSnackBar('❌ Erreur: $e', Colors.red);
    }
  }

  /// Affiche les détails d'un formulaire spécifique
  void _showFormDetails(FormData form, String error) {
    final nom = form.identite['nom'] ?? 'N/A';
    final prenom = form.identite['prenom'] ?? 'N/A';
    final region = form.identite['region'] ?? 'Non spécifié';
    final commune = form.identite['commune'] ?? 'Non spécifié';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails du formulaire'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nom: $nom $prenom', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Région: $region'),
            Text('Commune: $commune'),
            const SizedBox(height: 16),
            const Text('Erreur:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(error, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            const Text('UUID:', style: TextStyle(fontWeight: FontWeight.bold)),
            SelectableText(form.uuid, style: const TextStyle(fontSize: 10)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadFormByUuid(form.uuid);
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  /// Calcule les statistiques pour le dashboard
  Future<void> _loadDashboardStats() async {
  try {
    final today = DateTime.now().toString().split(' ')[0];
    int todayForms = 0;
    Map<String, int> byRegion = {};
    Map<String, int> byCommune = {};

    // Vérifier si _allForms est null
    final allForms = _allForms ?? [];

    for (var form in allForms) {
      // Vérifier si form.metadata et form.identite sont null
      final metadata = form.metadata ?? {};
      final identite = form.identite ?? {};
      
      if (metadata['date_enquete'] == today) {
        todayForms++;
      }
      final region = identite['region'] ?? 'Non spécifié';
      byRegion[region] = (byRegion[region] ?? 0) + 1;
      final commune = identite['commune'] ?? 'Non spécifié';
      byCommune[commune] = (byCommune[commune] ?? 0) + 1;
    }

    setState(() {
      _dashboardStats = {
        'total_forms': allForms.length,
        'today_forms': todayForms,
        'by_region': byRegion,
        'by_commune': byCommune,
      };
    });
  } catch (e) {
    print('Erreur statistiques dashboard: $e');
    setState(() {
      _dashboardStats = {
        'total_forms': 0,
        'today_forms': 0,
        'by_region': {},
        'by_commune': {},
      };
    });
  }
}

  /// Collecte les données du formulaire dans un objet FormData
  FormData _collectFormData(String uuid) {
    final questionnaireData = _getQuestionnaireData();

    return FormData(
      uuid: uuid,
      identite: {
        'nom': _controllers.nom.text.trim(),
        'prenom': _controllers.prenom.text.trim(),
        'surnom': _controllers.surnom.text.trim(),
        'sexe': _controllers.sexe.text.trim(),
        'date_naissance': _controllers.dateNaissance.text.trim(),
        'lieu_naissance': _controllers.lieuNaissance.text.trim(),
        'statut_matrimonial': _controllers.statutMatrimonial.text.trim(),
        'nombre_enfants': _controllers.nombreEnfants.text.trim(),
        'nombre_personnes_charge': _controllers.nombrePersonnesCharge.text.trim(),
        'nom_pere': _controllers.nomPere.text.trim(),
        'nom_mere': _controllers.nomMere.text.trim(),
        'metier': _controllers.metier.text.trim(),
        'activites_complementaires': _controllers.activitesComplementaires.text.trim(),
        'adresse': _controllers.adresse.text.trim(),
        'region': _controllers.region.text.trim(),
        'commune': _controllers.commune.text.trim(),
        'fokontany': _controllers.fokontany.text.trim(),
        'telephone1': _controllers.telephone1.text.trim(),
        'telephone2': _controllers.telephone2.text.trim(),
        'cin': {
          'numero': _controllers.numeroCIN.text.trim(),
          'date_delivrance': _controllers.dateDelivrance.text.trim(),
          'commune_delivrance': _controllers.commune.text.trim(),
        }
      },
      parcelle: {
        'nom': 'Parcelle ${_controllers.nom.text} ${_controllers.prenom.text}',
        'superficie': 1500.0,
        'latitude': _controllers.latitude.text.trim(),
        'longitude': _controllers.longitude.text.trim(),
        'altitude': _controllers.altitude.text.trim(),
        'precision': _controllers.precision.text.trim(),
        'type_contrat': _typeContrat,
        'description': 'Rizière en terrasse',
        'geom': _generateGeomData(),
        'gps': {
          'latitude': double.tryParse(_controllers.latitude.text) ?? -18.879,
          'longitude': double.tryParse(_controllers.longitude.text) ?? 47.5078,
          'altitude': double.tryParse(_controllers.altitude.text) ?? 1280,
        },
      },
      questionnaire_parcelles: questionnaireData,
      metadata: {
        'date_enquete': DateTime.now().toString().split(' ')[0],
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0',
        'agent': _agentName,
        'agent_email': _userData?['email'] ?? '',
        'agent_id': _userData?['id'] ?? '',
        'sync_status': hasInternet ? 'pending' : 'offline',
        'commune_nom': _controllers.commune.text.trim(),
        'fokontany_nom': _controllers.fokontany.text.trim(),
      },
    );
  }

  /// Génère les données géométriques pour la parcelle
  List<Map<String, double>> _generateGeomData() {
    final lat = double.tryParse(_controllers.latitude.text) ?? -18.879;
    final lng = double.tryParse(_controllers.longitude.text) ?? 47.5078;

    return [
      {'latitude': lat, 'longitude': lng},
      {'latitude': lat - 0.00005, 'longitude': lng + 0.00005},
      {'latitude': lat - 0.0001, 'longitude': lng - 0.00005},
      {'latitude': lat, 'longitude': lng},
    ];
  }

  /// Récupère les données des questionnaires (continues)
  List<Map<String, dynamic>> _getQuestionnaireData() {
    return [
      {
        'exploitation': {
          'type_contrat': _typeContrat,
          'technique_riziculture': 'Irriguée',
          'surface_totale_m2': 1500,
          'nombre_parcelles': 1,
          'surface_moyenne_parcelle_m2': 1500,
          'objectif_production': ['Autoconsommation', 'Vente locale'],
        },
        'semences': {
          'varietes_semences': ['X123', 'Y456'],
          'provenance_semences': ['Production propre', 'Achat local'],
          'quantite_semences_kg': 30,
          'pratique_semis': 'Direct',
        },
        'engrais_et_amendements': {
          'utilisation_engrais': true,
          'type_engrais': ['Chimique', 'Organique'],
          'quantite_engrais_chimique_kg': 25,
          'quantite_engrais_organique_kg': 100,
          'frequence_engrais': '1 par mois',
          'utilisation_amendements': true,
          'amendements': ['Fumier', 'Cendre'],
        },
        'eau_et_irrigation': {
          'source_eau_principale': ['Canal', 'Pluie'],
          'systeme_irrigation': 'Par gravité',
          'problemes_eau': ['Sécheresse'],
        },
        'protection_culture_et_recolte': {
          'ravageurs': ['Insectes', 'Rongeurs'],
          'utilisation_pesticides': true,
          'type_pesticides': ['Chimique'],
          'techniques_naturelles': ['Rotation des cultures'],
          'mode_recolte': 'Manuel',
        },
        'production_et_stockage': {
          'rendement_kg': 200,
          'duree_stockage_mois': 4,
          'perte_post_recolte_pourcent': 10,
          'mode_stockage': ['Grenier'],
          'pratique_post_recolte': ['Nouvelle culture'],
        },
        'commercialisation': {
          'vente_riz': true,
          'quantite_vendue_kg': 120,
          'prix_vente_ar_kg': 1800,
          'lieu_vente': ['Marché local'],
          'sait_cultiver_riz_hybride': true,
        },
        'diversification_activites': {
          'autres_cultures': ['Haricot', 'Maïs'],
          'elevage': true,
          'nombre_poules': 20,
          'nombre_volailles': 5,
          'nombre_boeufs': 2,
          'nombre_porc': 0,
          'nombre_moutons': 1,
          'nombre_chevres': 3,
          'nombre_lapins': 0,
          'pisciculture': false,
        },
        'competences_et_formation': {
          'competences_maitrisees': ['Agroécologie', 'Agriculture durable'],
          'mode_formation': ['Formation en groupement'],
          'competences_interet_formation': ['Gestion de ferme'],
        },
        'appui_et_besoins': {
          'appui_social': true,
          'appui_recu': ['Carte producteur', 'Subvention engrais'],
          'besoins_supplementaires': ['Matériel', 'Financement'],
        }
      }
    ];
  }

  /// Sauvegarde les données du formulaire localement
   Future<void> _saveFormDataLocally() async {
    try {
      if (!_controllers.validate()) {
        _showSnackBar(
          'Veuillez remplir les champs obligatoires (Nom, Prénom)',
          Colors.orange,
        );
        return;
      }

      final numeroCIN = _controllers.numeroCIN.text.trim();
      if (numeroCIN.isNotEmpty) {
        final isCINUnique = await _validateCINUnicity(numeroCIN, '');
        if (!isCINUnique) {
          _showSnackBar('⚠️ Ce numéro CIN existe déjà', Colors.orange);
          return;
        }
      }

      final uuid = _storageService.generateUuid(
        _controllers.nom.text,
        _controllers.prenom.text,
      );

      if (await _storageService.uuidExists(uuid)) {
        _showSnackBar('UUID en conflit, réessayez', Colors.orange);
        return;
      }

      // Vérifier les doublons dans le master
      final isDuplicate = await _checkDuplicatesInMaster(uuid, numeroCIN);
      if (isDuplicate) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Doublon détecté'),
            content: const Text(
              'Ce formulaire semble déjà exister dans le fichier master. '
              'Voulez-vous quand même l\'enregistrer ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Enregistrer quand même'),
              ),
            ],
          ),
        );

        if (confirm != true) return;
      }

      final formData = _collectFormData(uuid);

      // Sauvegarde locale individuelle
      await _storageService.saveFormData(formData);

      // Sauvegarde des images
      await _imageManager.saveImagesToAppDirectory(uuid);
      final appDir = await getApplicationDocumentsDirectory();
      await _curlGenerator.generateCurlCommand(uuid, appDir.path, _imageManager);

      // Ajouter au fichier master
      final masterResult = await _consolidationService.addToMaster(formData);
      if (masterResult['success'] == true) {
        print('✅ Formulaire ajouté au master');
        await _loadMasterStats();
      } else if (masterResult['duplicate'] == true) {
        print('⚠️ Doublon détecté dans le master');
      }

      // Synchronisation avec authentification
      if (hasInternet && _autoSyncEnabled) {
        _showSnackBar('📡 Synchronisation en cours...', Colors.blue);

        try {
          final syncResult = await _syncFormWithAuth(formData);

          if (syncResult == true) {
            formData.metadata['sync_status'] = 'synced';
            formData.metadata['synced_at'] = DateTime.now().toIso8601String();
            await _storageService.saveFormData(formData);

            _showSnackBar('✅ Formulaire sauvegardé et synchronisé!', Colors.green);
          } else {
            formData.metadata['sync_status'] = 'pending';
            formData.metadata['pending_since'] = DateTime.now().toIso8601String();
            await _storageService.addToPendingSync(formData);

            setState(() {
              _pendingSyncForms.add(formData);
            });

            _showSnackBar('⏳ Formulaire sauvegardé, synchronisation en attente', Colors.orange);
          }
        } catch (syncError) {
          print('Erreur de synchronisation: $syncError');

          formData.metadata['sync_status'] = 'pending';
          formData.metadata['pending_since'] = DateTime.now().toIso8601String();
          formData.metadata['sync_error'] = syncError.toString();

          await _storageService.addToPendingSync(formData);

          setState(() {
            _pendingSyncForms.add(formData);
          });

          _showSnackBar('⏳ Formulaire sauvegardé, synchronisation en attente', Colors.orange);
        }
      } else {
        formData.metadata['sync_status'] = 'offline';
        formData.metadata['pending_since'] = DateTime.now().toIso8601String();

        await _storageService.addToPendingSync(formData);

        setState(() {
          _pendingSyncForms.add(formData);
        });

        _showSnackBar('💾 Formulaire sauvegardé localement (hors ligne)', Colors.orange);
      }

      await _loadAllForms();
      _showSuccessDialog(formData.uuid, formData);

      _resetForm();

    } catch (e) {
      _showSnackBar('❌ Erreur sauvegarde: $e', Colors.red);
      print('Erreur complète de sauvegarde: $e');
    }
  }

  /// Valide l'unicité du CIN
Future<bool> _validateCINUnicity(String numeroCIN, String currentUuid) async {
  if (numeroCIN.isEmpty) return true;
  
  try {
    final existingForms = await _storageService.getFormsByCIN(numeroCIN);
    
    // Vérifier si existingForms est null
    if (existingForms == null) return true;
    
    final otherForms = existingForms.where((form) => form.uuid != currentUuid);
    return otherForms.isEmpty;
  } catch (e) {
    print('Erreur validation CIN: $e');
    return true; // En cas d'erreur, on autorise la sauvegarde
  }
}

  Future<bool> _syncFormWithAuth(FormData formData) async {
    if (_authToken == null) {
      print('❌ Pas de token d\'authentification');
      return false;
    }

    try {
      final url = Uri.parse('http://13.246.182.15:3001/import_massif');

      // Convertir en format JSON complet
      final jsonData = _convertToCompleteJson(formData);

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode(jsonData),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Formulaire synchronisé avec succès');
        return true;
      } else if (response.statusCode == 401) {
        print('❌ Token expiré ou invalide');
        _handleAuthError();
        return false;
      } else {
        print('❌ Erreur serveur: ${response.statusCode}');
        print('Réponse: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Erreur sync: $e');
      return false;
    }
  }

  /// Convertit FormData en format JSON complet pour l'API
  Map<String, dynamic> _convertToCompleteJson(FormData formData) {
    return {
      'individu': {
        'uuid': formData.uuid,
        'nom': formData.identite['nom'],
        'prenom': formData.identite['prenom'],
        'surnom': formData.identite['surnom'],
        'sexe': formData.identite['sexe'],
        'date_naissance': formData.identite['date_naissance'],
        'lieu_naissance': formData.identite['lieu_naissance'],
        'adresse': formData.identite['adresse'],
        'gps_point': '${formData.parcelle['latitude']},${formData.parcelle['longitude']}',
        'photo': _imageManager.portraitImagePath ?? '',
        'user_id': formData.metadata['agent_id'],
        'commune_id': 2,
        'nom_pere': formData.identite['nom_pere'],
        'nom_mere': formData.identite['nom_mere'],
        'profession': formData.identite['metier'],
        'activites_complementaires': formData.identite['activites_complementaires'],
        'statut_matrimonial': formData.identite['statut_matrimonial'],
        'nombre_personnes_a_charge': formData.identite['nombre_personnes_charge'],
        'telephone': formData.identite['telephone1'],
        'cin': formData.identite['cin'],
        'commune_nom': formData.identite['commune'],
        'fokontany_nom': formData.identite['fokontany'],
        'nombre_enfants': formData.identite['nombre_enfants'],
        'telephone2': formData.identite['telephone2'],
      },
      'parcelles': [
        {
          'nom': formData.parcelle['nom'],
          'superficie': formData.parcelle['superficie'],
          'gps': formData.parcelle['gps'],
          'geom': formData.parcelle['geom'],
          'description': formData.parcelle['description'],
        }
      ],
      'questionnaire_parcelles': formData.questionnaire_parcelles,
    };
  }

  Future<void> _handleAuthError() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session expirée'),
        content: const Text(
          'Votre session a expiré. Veuillez vous reconnecter.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
              );
            },
            child: const Text('Se reconnecter'),
          ),
        ],
      ),
    );
  }

  /// Réinitialise le formulaire
  void _resetForm() {
    setState(() {
      _controllers.clear();
      _imageManager.clear();
      _typeContrat = 'Co-gestion';
    });
    _showSnackBar('🔄 Formulaire réinitialisé', Colors.blue);
  }

  /// Charge un formulaire par son UUID
  Future<void> _loadFormByUuid(String uuid) async {
  try {
    final form = await _storageService.getFormByUuid(uuid);
    if (form == null) {
      _showSnackBar('Formulaire non trouvé', Colors.red);
      return;
    }

    // Vérifier si form.identite est null
    final identite = form.identite ?? {};
    final parcelle = form.parcelle ?? {};

    _controllers.nom.text = identite['nom'] ?? '';
    _controllers.prenom.text = identite['prenom'] ?? '';
    _controllers.surnom.text = identite['surnom'] ?? '';
    _controllers.sexe.text = identite['sexe'] ?? '';
    _controllers.dateNaissance.text = identite['date_naissance'] ?? '';
    _controllers.lieuNaissance.text = identite['lieu_naissance'] ?? '';
    _controllers.statutMatrimonial.text = identite['statut_matrimonial'] ?? '';
    _controllers.nombreEnfants.text = identite['nombre_enfants'] ?? '';
    _controllers.nombrePersonnesCharge.text = identite['nombre_personnes_charge'] ?? '';
    _controllers.nomPere.text = identite['nom_pere'] ?? '';
    _controllers.nomMere.text = identite['nom_mere'] ?? '';
    _controllers.metier.text = identite['metier'] ?? '';
    _controllers.activitesComplementaires.text = identite['activites_complementaires'] ?? '';
    _controllers.adresse.text = identite['adresse'] ?? '';
    _controllers.region.text = identite['region'] ?? '';
    _controllers.commune.text = identite['commune'] ?? '';
    _controllers.fokontany.text = identite['fokontany'] ?? '';
    _controllers.telephone1.text = identite['telephone1'] ?? '';
    _controllers.telephone2.text = identite['telephone2'] ?? '';

    final cin = identite['cin'] as Map<String, dynamic>? ?? {};
    _controllers.numeroCIN.text = cin['numero'] ?? '';
    _controllers.dateDelivrance.text = cin['date_delivrance'] ?? '';

    _controllers.latitude.text = parcelle['latitude'] ?? '';
    _controllers.longitude.text = parcelle['longitude'] ?? '';
    _controllers.altitude.text = parcelle['altitude'] ?? '';
    _controllers.precision.text = parcelle['precision'] ?? '';

    setState(() {
      _typeContrat = parcelle['type_contrat'] ?? 'Co-gestion';
      _selectedIndex = 1;
    });

    _showSnackBar('✅ Formulaire chargé', Colors.green);
  } catch (e) {
    _showSnackBar('❌ Erreur chargement: $e', Colors.red);
  }
}

  /// Supprime un formulaire par son UUID
  Future<void> _deleteForm(String uuid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer ce formulaire ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _storageService.deleteFormByUuid(uuid);
      if (success) {
        setState(() {
          _pendingSyncForms.removeWhere((form) => form.uuid == uuid);
        });
        await _storageService.removeFromPendingSync(uuid);
        await _loadAllForms();
        _showSnackBar('✅ Formulaire supprimé', Colors.green);
      } else {
        _showSnackBar('❌ Erreur suppression', Colors.red);
      }
    }
  }

  /// Exporte toutes les données
  Future<void> _exportAllData() async {
    try {
      final path = await _storageService.exportAllForms();
      await _exportCompleteJson();

      if (path != null) {
        _showSnackBar('✅ Exports réussis', Colors.green);
      } else {
        _showSnackBar('❌ Erreur export', Colors.red);
      }
    } catch (e) {
      _showSnackBar('❌ Erreur export: $e', Colors.red);
    }
  }

  /// Exporte les données au format JSON complet
  Future<void> _exportCompleteJson() async {
    try {
      final allData = [];

      for (var form in _allForms) {
        final completeData = _convertToCompleteJson(form);
        allData.add(completeData);
      }

      final jsonString = JsonEncoder.withIndent('  ').convert(allData);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/export_complet_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);

      _showSnackBar('✅ Export JSON complet réussi: ${file.path}', Colors.green);
    } catch (e) {
      _showSnackBar('❌ Erreur export JSON: $e', Colors.red);
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (_pendingSyncForms.isNotEmpty) {
        final confirmLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Attention'),
            content: Text(
              'Vous avez ${_pendingSyncForms.length} formulaire(s) en attente de synchronisation. '
                  'Si vous vous déconnectez maintenant, ces données seront conservées localement '
                  'mais vous devrez vous reconnecter pour les synchroniser.\n\n'
                  'Voulez-vous vraiment vous déconnecter ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Déconnexion quand même'),
              ),
            ],
          ),
        );

        if (confirmLogout != true) return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_data');

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
        );
      }
    }
  }

  /// Affiche une dialog de succès après sauvegarde
  void _showSuccessDialog(String filePath, FormData formData) {
    final isPendingSync = _pendingSyncForms.any((form) => form.uuid == formData.uuid);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(isPendingSync ? Icons.schedule : Icons.check_circle,
                color: isPendingSync ? Colors.orange : Colors.green),
            const SizedBox(width: 8),
            Flexible(child: Text(isPendingSync ? 'En attente' : 'Succès')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isPendingSync
                  ? '⏳ Formulaire en attente de synchronisation'
                  : '✅ Formulaire sauvegardé et synchronisé!'),
              const SizedBox(height: 12),
              Text('UUID: ${formData.uuid}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              const SizedBox(height: 8),
              Text('Total: ${_allForms.length}',
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              if (isPendingSync)
                const Text(
                  '📡 Données sauvegardées localement. Synchronisation automatique dès que la connexion sera disponible.',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
              if (!hasInternet && !isPendingSync)
                const Text(
                  '⚠️ Données sauvegardées localement (hors ligne)',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              final jsonData = JsonEncoder.withIndent('  ').convert(_convertToCompleteJson(formData));
              Clipboard.setData(ClipboardData(text: jsonData));
              _showSnackBar('📋 JSON copié', Colors.green);
            },
            child: const Text('Copier JSON'),
          ),
        ],
      ),
    );
  }

  /// Affiche un snackbar avec un message et une couleur
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Navigue vers l'écran Continue
  void _navigateToContinue(String title, int continueNumber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContinueScreen(
          title: title,
          continueNumber: continueNumber,
        ),
      ),
    );
  }

  /// Gère la sélection d'image
  Future<void> _handleImagePick(String imageType) async {
    try {
      await _imageManager.pickImage(imageType);
      setState(() {});
    } catch (e) {
      _showSnackBar('❌ Erreur sélection: $e', Colors.red);
    }
  }

  /// Supprime une image sélectionnée
  void _handleImageRemove(String imageType) {
    setState(() {
      _imageManager.removeImage(imageType);
    });
  }

  // =====================================================================
  // BUILD METHODS
  // =====================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // CONTENU PRINCIPAL
          Positioned(
            left: _isMenuCollapsed && !_isMenuOverlay ? _menuWidth : 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(
              color: const Color(0xFFF5F7FA),
              child: _buildContent(),
            ),
          ),

          // MENU RÉDUIT
          if (_isMenuCollapsed && !_isMenuOverlay)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: _menuWidth,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(2, 0),
                    ),
                  ],
                ),
                child: MenuWidget(
                  selectedIndex: _selectedIndex,
                  isMenuCollapsed: _isMenuCollapsed,
                  onMenuItemTap: (index) => setState(() => _selectedIndex = index),
                  onToggleMenu: _toggleMenu,
                  onLogout: _handleLogout,
                  pendingSyncCount: _pendingSyncForms.length,
                  userName: _agentName,
                ),
              ),
            ),

          // OVERLAY DE SYNCHRONISATION
          if (_isSyncing)
            Positioned(
              top: 0,
              left: _isMenuCollapsed && !_isMenuOverlay ? _menuWidth : 0,
              right: 0,
              child: _buildSyncProgressOverlay(),
            ),
        ],
      ),
    );
  }

  /// Construit l'overlay de progression de synchronisation
  Widget _buildSyncProgressOverlay() {
    return Material(
      color: Colors.blue.shade50,
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.sync, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Synchronisation en cours... ($_currentSyncProgress/$_totalSyncItems)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                if (_totalSyncItems > 0)
                  Text(
                    '${((_currentSyncProgress / _totalSyncItems) * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _totalSyncItems > 0 ? _currentSyncProgress / _totalSyncItems : 0,
              backgroundColor: Colors.blue.shade100,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit le contenu principal
  Widget _buildContent() {
    return Center(
      child: Container(
        width: _dashboardWidth,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: _buildCurrentPageContent(),
      ),
    );
  }

  /// Construit le contenu de la page actuelle
  Widget _buildCurrentPageContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildFormsListContent();
      case 1:
        return _buildDashboardContent();
      case 2:
        return _buildSynchronizationContent();
      case 3:
        return _buildHistoryContent();
      default:
        return _buildFormsListContent();
    }
  }

  // =====================================================================
  // PAGE 0 - LISTE DES INDIVIDUS
  // =====================================================================

  Widget _buildFormsListContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Liste des individus (${_allForms.length})',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003D82),
                ),
              ),
              if (_pendingSyncForms.isNotEmpty) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '${_pendingSyncForms.length} en attente',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: hasInternet ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasInternet ? Icons.wifi : Icons.wifi_off,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hasInternet ? 'En ligne' : 'Hors ligne',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStatsGrid(),
          const SizedBox(height: 20),
          if (_isLoadingForms)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF1AB999)),
            )
          else if (_allForms.isEmpty)
            _buildEmptyState()
          else
            _buildFormsList(),
        ],
      ),
    );
  }

  /// Construit la grille de statistiques
  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (constraints.maxWidth > 1200) crossAxisCount = 4;
        else if (constraints.maxWidth > 800) crossAxisCount = 3;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.0,
          children: [
            _buildStatCard('Total individus', _dashboardStats['total_forms'].toString(), Icons.people, const Color(0xFF1AB999)),
            _buildStatCard("Aujourd'hui", _dashboardStats['today_forms'].toString(), Icons.today, const Color(0xFF003D82)),
            _buildStatCard('Régions', _dashboardStats['by_region'].length.toString(), Icons.map, const Color(0xFF8E99AB)),
            _buildStatCard('Communes', _dashboardStats['by_commune'].length.toString(), Icons.location_city, const Color(0xFF1AB999)),
          ],
        );
      },
    );
  }

  /// Construit une carte de statistique
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003D82),
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'Aucun formulaire enregistré',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Créez votre premier formulaire dans le Dashboard',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedIndex = 1;
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Créer un formulaire'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1AB999),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _allForms.length,
      itemBuilder: (context, index) {
        final form = _allForms[index];
        final isPendingSync = _pendingSyncForms.any((f) => f.uuid == form.uuid);
        final nom = form.identite['nom'] ?? 'N/A';
        final prenom = form.identite['prenom'] ?? 'N/A';
        final region = form.identite['region'] ?? 'Non spécifié';
        final commune = form.identite['commune'] ?? 'Non spécifié';
        final dateEnquete = form.metadata['date_enquete'] ?? 'N/A';
        final cin = form.identite['cin'] as Map<String, dynamic>? ?? {};
        final numeroCIN = cin['numero'] ?? 'Non renseigné';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: isPendingSync ? Colors.orange : const Color(0xFF1AB999),
                  radius: 28,
                  child: Text(
                    nom.isNotEmpty ? nom[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isPendingSync)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.schedule, size: 12, color: Colors.white),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Text(
                  '$nom $prenom',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF003D82),
                  ),
                ),
                if (isPendingSync) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.schedule, size: 16, color: Colors.orange),
                ],
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.credit_card, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'CIN: $numeroCIN',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '$region | $commune',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Ajouté: $dateEnquete',
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (isPendingSync) ...[
                        const SizedBox(width: 8),
                        const Text(
                          '• En attente',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      if (form.metadata['sync_status'] == 'failed') ...[
                        const SizedBox(width: 8),
                        const Text(
                          '• Échec sync',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF1AB999)),
                  tooltip: 'Modifier',
                  onPressed: () => _loadFormByUuid(form.uuid),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Supprimer',
                  onPressed: () => _deleteForm(form.uuid),
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  // =====================================================================
  // PAGE 1 - DASHBOARD (FORMULAIRE)
  // =====================================================================

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDashboardHeader(),
          const SizedBox(height: 20),
          _buildIdentitySection(),
          const SizedBox(height: 20),
          _buildParcelleSection(),
          const SizedBox(height: 20),
          _buildContinueSection(),
        ],
      ),
    );
  }

  Widget _buildDashboardHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF8E99AB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.dashboard, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          const Text(
            'Dashboard - Nouveau formulaire',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          const Text('Progression', style: TextStyle(color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: 0.32,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1AB999),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Text('32%', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildIdentitySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1AB999),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Text(
              'IDENTITÉ',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Identité', style: TextStyle(color: Color(0xFF003D82), fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                FormWidgets.buildTextField('Nom', _controllers.nom),
                const SizedBox(height: 20),
                FormWidgets.buildTextField('Prénom', _controllers.prenom),
                const SizedBox(height: 20),
                FormWidgets.buildTextField('Surnom', _controllers.surnom),
                const SizedBox(height: 20),
                FormWidgets.buildSexeField('Sexe', _controllers.sexe),
                const SizedBox(height: 20),
                FormWidgets.buildDateField('Date de naissance', _controllers.dateNaissance, context),
                const SizedBox(height: 20),
                FormWidgets.buildTextField('Lieu de naissance', _controllers.lieuNaissance),
                const SizedBox(height: 32),
                const Text('Compléments d\'information', style: TextStyle(color: Color(0xFF003D82), fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                FormWidgets.buildTextField('Statut matrimonial', _controllers.statutMatrimonial),
                const SizedBox(height: 20),
                FormWidgets.buildNumberField('Nombre d\'enfants', _controllers.nombreEnfants, minValue: 0),
                const SizedBox(height: 20),
                FormWidgets.buildNumberField('Nombre de personnes à charge', _controllers.nombrePersonnesCharge, minValue: 0),
                const SizedBox(height: 32),
                FormWidgets.buildTextField('Nom du père', _controllers.nomPere),
                const SizedBox(height: 20),
                FormWidgets.buildTextField('Nom de la mère', _controllers.nomMere),
                const SizedBox(height: 20),
                FormWidgets.buildTextField('Métier', _controllers.metier),
                const SizedBox(height: 20),
                FormWidgets.buildTextField('Activités complémentaires', _controllers.activitesComplementaires),
                const SizedBox(height: 32),
                const Text('Adresse et contact', style: TextStyle(color: Color(0xFF003D82), fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                FormWidgets.buildTextField('Adresse', _controllers.adresse),
                const SizedBox(height: 20),
                FormWidgets.buildTextField('Région', _controllers.region),
                const SizedBox(height: 20),
                FormWidgets.buildTextField('Commune', _controllers.commune),
                const SizedBox(height: 20),
                FormWidgets.buildTextField('Fokontany', _controllers.fokontany),
                const SizedBox(height: 20),
                FormWidgets.buildPhoneField('Numéro téléphone 1', _controllers.telephone1),
                const SizedBox(height: 20),
                FormWidgets.buildPhoneField('Numéro téléphone 2', _controllers.telephone2),
                const SizedBox(height: 32),
                const Text('Carte d\'identité nationale', style: TextStyle(color: Color(0xFF003D82), fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                FormWidgets.buildTextField('Numéro CIN', _controllers.numeroCIN),
                const SizedBox(height: 20),
                FormWidgets.buildDateField('Date de délivrance', _controllers.dateDelivrance, context),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildImageUploadField('Photo CIN recto', 'cin_recto', _imageManager.cinRectoImagePath, _imageManager.cinRectoImageFile),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildImageUploadField('Photo CIN verso', 'cin_verso', _imageManager.cinVersoImagePath, _imageManager.cinVersoImageFile),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParcelleSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1AB999),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Text(
              'PARCELLE',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Terrain', style: TextStyle(color: Color(0xFF003D82), fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                FormWidgets.buildDecimalField('Latitude (x,y°)', _controllers.latitude, hintText: 'Ex: -18.8792'),
                const SizedBox(height: 20),
                FormWidgets.buildDecimalField('Longitude (x,y°)', _controllers.longitude, hintText: 'Ex: 47.5079'),
                const SizedBox(height: 20),
                FormWidgets.buildNumberField('Altitude (m)', _controllers.altitude),
                const SizedBox(height: 20),
                FormWidgets.buildNumberField('Précision (m)', _controllers.precision),
                const SizedBox(height: 32),
                const Text('Type de contrat', style: TextStyle(color: Color(0xFF003D82), fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: FormWidgets.buildRadioButton('Propriétaire', _typeContrat, (value) => setState(() => _typeContrat = value!))),
                    const SizedBox(width: 12),
                    Expanded(child: FormWidgets.buildRadioButton('Locataire', _typeContrat, (value) => setState(() => _typeContrat = value!))),
                    const SizedBox(width: 12),
                    Expanded(child: FormWidgets.buildRadioButton('Co-gestion', _typeContrat, (value) => setState(() => _typeContrat = value!))),
                  ],
                ),
                const SizedBox(height: 24),
                _buildImageUploadField('Photo parcelle', 'parcelle', _imageManager.parcelleImagePath, _imageManager.parcelleImageFile),
                const SizedBox(height: 24),
                _buildImageUploadField('Photo d\'identité', 'portrait', _imageManager.portraitImagePath, _imageManager.portraitImageFile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadField(String label, String imageType, String? imagePath, File? imageFile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700])),
        const SizedBox(height: 8),
        Container(
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: imageFile != null
              ? Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(imageFile, width: double.infinity, height: double.infinity, fit: BoxFit.cover),
              ),
              Positioned(
                top: 4, right: 4,
                child: CircleAvatar(
                  radius: 14, backgroundColor: Colors.red,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 12, color: Colors.white),
                    padding: EdgeInsets.zero,
                    onPressed: () => _handleImageRemove(imageType),
                  ),
                ),
              ),
            ],
          )
              : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt, color: Colors.grey[400]),
                const SizedBox(height: 4),
                Text('Ajouter une photo', style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _handleImagePick(imageType),
            child: const Text('Sélectionner une image'),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1AB999),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Text(
              'CONTINUE',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Liste des continues', style: TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 16),
                FormWidgets.buildContinueItem(3, 'Riziculture', 'Techniques de culture du riz', false, onTap: () => _navigateToContinue('Riziculture', 3)),
                const Divider(height: 1, color: Color(0xFFE0E0E0)),
                FormWidgets.buildContinueItem(4, 'Élevage', 'Pratiques d\'élevage', false, onTap: () => _navigateToContinue('Élevage', 4)),
                const Divider(height: 1, color: Color(0xFFE0E0E0)),
                FormWidgets.buildContinueItem(5, 'Pêche', 'Techniques de pêche', false, onTap: () => _navigateToContinue('Pêche', 5)),
                const Divider(height: 1, color: Color(0xFFE0E0E0)),
                FormWidgets.buildContinueItem(6, 'Agriculture vivrière', 'Cultures alimentaires', true),
                const Divider(height: 1, color: Color(0xFFE0E0E0)),
                FormWidgets.buildContinueItem(7, 'Commerce', 'Activités commerciales', false, onTap: () => _navigateToContinue('Commerce', 7)),
                const Divider(height: 1, color: Color(0xFFE0E0E0)),
                FormWidgets.buildContinueItem(8, 'Artisanat', 'Métiers artisanaux', true),
                const SizedBox(height: 32),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Color(0xFF8E99AB), size: 20),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Voir historique de modification', style: TextStyle(color: Color(0xFF333333), fontSize: 14, fontWeight: FontWeight.w500))),
                    OutlinedButton(
                      onPressed: _resetForm,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        side: const BorderSide(color: Color(0xFF8E99AB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Annuler', style: TextStyle(color: Color(0xFF8E99AB), fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _saveFormDataLocally,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1AB999),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Enregistrer', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // PAGE 2 - SYNCHRONISATION
  // =====================================================================

  Widget _buildSynchronizationContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gestion des données', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF003D82))),
          const SizedBox(height: 8),
          const Text('Stockage local en fichiers JSON - Synchronisation automatique', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 24),
          _buildDataActionsCard(),
          const SizedBox(height: 24),
          _buildPendingSyncCard(),
          const SizedBox(height: 24),
          _buildDataStatsCard(),
        ],
      ),
    );
  }

   Widget _buildDataActionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Actions de synchronisation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF003D82))),
          const SizedBox(height: 16),
          
          // NOUVEAU : Bouton de consolidation
          ElevatedButton.icon(
            onPressed: _consolidateAllJsonFiles,
            icon: const Icon(Icons.merge_type),
            label: const Text('Consolider tous les JSON'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          const SizedBox(height: 12),
          
          ElevatedButton.icon(
            onPressed: _exportAllData,
            icon: const Icon(Icons.download),
            label: const Text('Exporter tous les formulaires'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1AB999), minimumSize: const Size(double.infinity, 50)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              try {
                final result = await _autoSyncService.syncAllFromLocalToMaster();
                if (result['success'] == true) {
                  _showDialog('Synchronisation réussie', 'Total: ${result['total']}\nInsérés: ${result['inserted']}\nMis à jour: ${result['updated']}\nIgnorés: ${result['skipped']}\nErreurs: ${result['errors']}');
                  await _loadAllForms();
                  await _loadPendingSyncForms();
                  await _loadMasterStats();
                } else {
                  _showSnackBar('Erreur: ${result['error']}', Colors.red);
                }
              } catch (e) {
                _showSnackBar('Erreur: $e', Colors.red);
              }
            },
            icon: const Icon(Icons.sync),
            label: const Text('Synchroniser vers master'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isSyncing ? null : _syncPendingForms,
            icon: _isSyncing
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            label: Text('Synchroniser les en attente (${_pendingSyncForms.length})'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              await _loadAllForms();
              await _loadMasterStats();
            },
            icon: const Icon(Icons.update),
            label: const Text('Actualiser la liste'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingSyncCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: Colors.orange),
              const SizedBox(width: 8),
              const Text('Formulaires en attente de synchronisation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF003D82))),
              const Spacer(),
              if (_pendingSyncForms.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(16)),
                  child: Text('${_pendingSyncForms.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_pendingSyncForms.isEmpty)
            const Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle, size: 48, color: Colors.green),
                  SizedBox(height: 12),
                  Text('Aucun formulaire en attente', style: TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Toutes les données sont synchronisées', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          else
            Column(
              children: [
                for (var form in _pendingSyncForms.take(5))
                  ListTile(
                    leading: const Icon(Icons.pending, color: Colors.orange),
                    title: Text('${form.identite['nom']} ${form.identite['prenom']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('UUID: ${form.uuid}', style: const TextStyle(fontSize: 12)),
                    trailing: Text(form.metadata['date_enquete'] ?? 'Date inconnue', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                if (_pendingSyncForms.length > 5)
                  Text('... et ${_pendingSyncForms.length - 5} autres formulaires', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
              ],
            ),
        ],
      ),
    );
  }

   Widget _buildDataStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Statistiques', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF003D82))),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  await _loadAllForms();
                  await _loadMasterStats();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Stats locales
          const Text('📁 Stockage local', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1AB999))),
          const SizedBox(height: 8),
          _buildStatItem('Total formulaires', _allForms.length.toString()),
          _buildStatItem('Formulaires synchronisés', (_allForms.length - _pendingSyncForms.length).toString()),
          _buildStatItem('En attente de sync', _pendingSyncForms.length.toString()),
          _buildStatItem('Dernier formulaire', _getLastFormDate()),
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          
          // Stats du master
          Row(
            children: [
              const Text('📊 Fichier Master consolidé', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
              const SizedBox(width: 8),
              if (_masterStats['exists'] == true)
                const Icon(Icons.check_circle, size: 16, color: Colors.green)
              else
                const Icon(Icons.cancel, size: 16, color: Colors.orange),
            ],
          ),
          const SizedBox(height: 8),
          
          if (_masterStats['exists'] == true) ...[
            _buildStatItem('Formulaires dans le master', '${_masterStats['total_forms']}'),
            _buildStatItem('Doublons supprimés', '${_masterStats['duplicates_removed'] ?? 0}'),
            _buildStatItem('Taille du fichier', '${(_masterStats['file_size'] / 1024).toStringAsFixed(2)} KB'),
            if (_masterStats['created_at'] != null)
              _buildStatItem('Créé le', DateTime.parse(_masterStats['created_at']).toString().split('.')[0]),
            if (_masterStats['last_updated'] != null)
              _buildStatItem('Dernière mise à jour', DateTime.parse(_masterStats['last_updated']).toString().split('.')[0]),
          ] else ...[
            const Text(
              'Aucun fichier master. Cliquez sur "Consolider tous les JSON".',
              style: TextStyle(color: Colors.orange, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          
          _buildStatItem('Statut connexion', hasInternet ? '✅ En ligne' : '⚠️ Hors ligne'),
          if (_isSyncing)
            _buildStatItem('Progression sync', '$_currentSyncProgress/$_totalSyncItems (${((_currentSyncProgress / _totalSyncItems) * 100).toStringAsFixed(0)}%)'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500))),
          Flexible(child: Text(value, style: const TextStyle(color: Color(0xFF003D82), fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  String _getLastFormDate() {
    if (_allForms.isEmpty) return 'Aucun';
    final lastForm = _allForms.last;
    return lastForm.metadata['date_enquete'] ?? 'Inconnue';
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  // =====================================================================
  // PAGE 3 - HISTORIQUE
  // =====================================================================

  Widget _buildHistoryContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('Page Historiques', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF003D82))),
            const SizedBox(height: 8),
            const Text('Fonctionnalité à venir', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 24),
            Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: [
                  const Icon(Icons.info_outline, size: 48, color: Color(0xFF1AB999)),
                  const SizedBox(height: 16),
                  const Text('Cette section contiendra :', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003D82))),
                  const SizedBox(height: 12),
                  _buildHistoryFeature('Historique des modifications'),
                  _buildHistoryFeature('Logs des sauvegardes'),
                  _buildHistoryFeature('Activités des utilisateurs'),
                  _buildHistoryFeature('Versions des formulaires'),
                  _buildHistoryFeature('Journal de synchronisation'),
                  _buildHistoryFeature('Statistiques d\'utilisation'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryFeature(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF1AB999)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: Colors.grey[700]))),
        ],
      ),
    );
  }
}