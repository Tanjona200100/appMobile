import 'dart:convert';
import 'dart:io';
import 'dart:math';
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
import 'questionnaire_screen.dart';
import '../utils/connection_mixin.dart';
import 'login_screen.dart';
import '../services/json_consolidation_service.dart';

Map<String, dynamic>? _questionnaireData;

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

  // File d'attente pour la synchronisation
  List<FormData> _pendingSyncForms = [];
  bool _isSyncing = false;
  int _currentSyncProgress = 0;
  int _totalSyncItems = 0;

  String? _authToken;
  Map<String, dynamic>? _userData;
  String _agentName = 'Agent';

  // Statistiques
  Map<String, dynamic> _dashboardStats = {
    'total_forms': 0,
    'today_forms': 0,
    'by_region': <String, int>{},
    'by_commune': <String, int>{},
  };

  // Overlay entry pour le menu superposé
  OverlayEntry? _menuOverlayEntry;

  // Chemin du fichier JSON consolidé
  String? _consolidatedJsonPath;

  @override
  void initState() {
    super.initState();
    print('🚀 Initialisation SideMenu...');

    _allForms = [];
    _pendingSyncForms = [];

    _loadUserData();
    _initializeApp();
  }

  void _initializeApp() async {
    print('🔄 Initialisation de l\'application...');
    await _loadAllForms();
    await _loadPendingSyncForms();
    await _loadConsolidatedJson();
    _startConnectionListener();
    _startAutoSyncListener();
  }

  /// Charge les données utilisateur
  Future<void> _loadUserData() async {
    try {
      _authToken = widget.authToken;
      _userData = widget.userData;

      if (_userData != null) {
        _agentName = _userData!['name'] ??
            (_userData!['email']?.toString().split('@')[0] ?? 'Agent');
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
            await _createOrUpdateConsolidatedJson();
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
        await _createOrUpdateConsolidatedJson();
      }

      if (mounted) {
        _startAutoSyncListener();
      }
    });
  }

  /// Teste l'accès réel à Internet
  Future<bool> _testInternetAccess() async {
    try {
      final response = await http.get(
        Uri.parse('http://13.246.182.15:3001/'),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode < 400;
    } catch (e) {
      return false;
    }
  }

  /// Vérifie la connexion initiale
  Future<void> _checkInitialConnection() async {
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
                  : 'Votre appareil n\'est pas connecté à Internet.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
        _pendingSyncForms = pendingForms ?? [];
      });
    } catch (e) {
      print('Erreur chargement formulaires en attente: $e');
      setState(() {
        _pendingSyncForms = [];
      });
    }
  }

  /// Calcule les statistiques pour le dashboard
  Future<void> _loadDashboardStats() async {
    try {
      final today = DateTime.now().toString().split(' ')[0];
      int todayForms = 0;
      Map<String, int> byRegion = <String, int>{};
      Map<String, int> byCommune = <String, int>{};

      for (var form in _allForms) {
        final metadata = form.metadata ?? {};
        final identite = form.identite ?? {};

        if (metadata['date_enquete'] == today) {
          todayForms++;
        }
        final region = identite['region']?.toString() ?? 'Non spécifié';
        byRegion[region] = (byRegion[region] ?? 0) + 1;
        final commune = identite['commune']?.toString() ?? 'Non spécifié';
        byCommune[commune] = (byCommune[commune] ?? 0) + 1;
      }

      setState(() {
        _dashboardStats = {
          'total_forms': _allForms.length,
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
          'by_region': <String, int>{},
          'by_commune': <String, int>{},
        };
      });
    }
  }

  /// Charge le fichier JSON consolidé
  Future<void> _loadConsolidatedJson() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/consolidated_data.json');

      if (await file.exists()) {
        setState(() {
          _consolidatedJsonPath = file.path;
        });
        print('✅ Fichier JSON consolidé trouvé: ${file.path}');
      } else {
        print('ℹ️ Aucun fichier JSON consolidé trouvé');
      }
    } catch (e) {
      print('❌ Erreur chargement JSON consolidé: $e');
    }
  }

  /// Crée ou met à jour le fichier JSON consolidé
  Future<void> _createOrUpdateConsolidatedJson() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/consolidated_data.json');

      // Préparer les données pour le JSON selon le format attendu par Ruby
      List<Map<String, dynamic>> allData = [];

      // Ajouter les formulaires locaux
      for (var form in _allForms) {
        final jsonData = _convertToCompleteJsonForRuby(form);
        allData.add(jsonData);
      }

      // Ajouter les formulaires en attente de sync
      for (var form in _pendingSyncForms) {
        if (!_allForms.any((f) => f.uuid == form.uuid)) {
          final jsonData = _convertToCompleteJsonForRuby(form);
          allData.add(jsonData);
        }
      }

      // IMPORTANT: Le format doit être exactement celui attendu par Ruby
      // C'est-à-dire une LISTE d'objets, pas un objet avec metadata et data
      final jsonString = JsonEncoder.withIndent('  ').convert(allData);

      await file.writeAsString(jsonString);

      setState(() {
        _consolidatedJsonPath = file.path;
      });

      print('✅ Fichier JSON créé pour serveur Ruby: ${file.path}');
      print('📊 Nombre d\'enregistrements: ${allData.length}');

    } catch (e) {
      print('❌ Erreur création JSON pour Ruby: $e');
      _showSnackBar('Erreur création JSON: $e', Colors.red);
    }
  }

  /// Synchronise TOUS les formulaires via le fichier JSON consolidé - VERSION RUBY
  Future<void> _syncAllFormsViaJsonForRuby() async {
    print('\n🔄 === SYNCHRONISATION VIA JSON POUR RUBY ===');

    if (_isSyncing) {
      _showSnackBar('Synchronisation déjà en cours', Colors.orange);
      return;
    }

    // Créer/mettre à jour le fichier JSON d'abord
    await _createOrUpdateConsolidatedJson();

    if (_consolidatedJsonPath == null) {
      _showSnackBar('Aucune donnée à synchroniser', Colors.orange);
      return;
    }

    final file = File(_consolidatedJsonPath!);
    if (!await file.exists()) {
      _showSnackBar('Fichier JSON non trouvé', Colors.red);
      return;
    }

    // Lire le contenu du fichier JSON
    try {
      final jsonString = await file.readAsString();

      // Vérifier que le fichier n'est pas vide
      if (jsonString.trim().isEmpty) {
        _showSnackBar('Fichier JSON vide', Colors.red);
        return;
      }

      // IMPORTANT: Le fichier contient directement la liste
      final List<dynamic> dataList = jsonDecode(jsonString);

      if (dataList.isEmpty) {
        _showSnackBar('Aucune donnée à synchroniser', Colors.blue);
        return;
      }

      print('📊 Synchronisation de ${dataList.length} enregistrements...');

      setState(() {
        _isSyncing = true;
        _currentSyncProgress = 0;
        _totalSyncItems = dataList.length;
      });

      _showSnackBar('Début de la synchronisation de ${dataList.length} enregistrements...', Colors.blue);

      // Envoyer la LISTE COMPLÈTE au serveur Ruby
      final url = Uri.parse('http://13.246.182.15:3001/import_massif');

      print('📤 Envoi du tableau complet au serveur Ruby...');

      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': _authToken != null ? 'Bearer $_authToken' : '',
          },
          body: jsonString, // Envoyer directement le contenu du fichier
        ).timeout(const Duration(seconds: 60));

        print('📥 Réponse serveur Ruby:');
        print('   Status: ${response.statusCode}');
        print('   Body: ${response.body.length > 200 ? '${response.body.substring(0, 200)}...' : response.body}');

        int successCount = 0;
        int failureCount = 0;
        final errors = <Map<String, dynamic>>[];

        if (response.statusCode == 200 || response.statusCode == 201) {
          successCount = dataList.length;
          print('✅ Tous les enregistrements synchronisés avec succès');

          // Si tout a été synchronisé avec succès
          await _markAllFormsAsSynced();
          await _loadAllForms();
          await _loadPendingSyncForms();
        } else {
          failureCount = dataList.length;
          errors.add({
            'status': response.statusCode,
            'error': response.body,
          });
          print('❌ Échec de la synchronisation globale');
        }

        setState(() {
          _isSyncing = false;
          _currentSyncProgress = dataList.length;
        });

        // Afficher les résultats
        _showSyncResultDialog(successCount, failureCount, errors);

      } catch (e) {
        setState(() {
          _isSyncing = false;
        });
        _showSnackBar('❌ Erreur lors de l\'envoi: $e', Colors.red);
        print('💥 Exception lors de l\'envoi: $e');
      }

    } catch (e) {
      setState(() {
        _isSyncing = false;
      });
      _showSnackBar('❌ Erreur de lecture JSON: $e', Colors.red);
      print('💥 Erreur critique: $e');
    }

    print('🔚 === FIN SYNCHRONISATION ===\n');
  }

  /// Marque tous les formulaires comme synchronisés
  Future<void> _markAllFormsAsSynced() async {
    for (int i = 0; i < _allForms.length; i++) {
      final form = _allForms[i];
      final metadata = {...(form.metadata ?? {})};
      metadata['sync_status'] = 'synced';
      metadata['synced_at'] = DateTime.now().toIso8601String();

      // Créez un nouveau FormData avec les métadonnées mises à jour
      final updatedForm = FormData(
        uuid: form.uuid,
        identite: form.identite ?? {},
        parcelle: form.parcelle ?? {},
        questionnaire_parcelles: form.questionnaire_parcelles,
        metadata: metadata,
      );

      _allForms[i] = updatedForm;
      await _storageService.saveFormData(updatedForm);
    }

    for (int i = 0; i < _pendingSyncForms.length; i++) {
      final form = _pendingSyncForms[i];
      final metadata = {...(form.metadata ?? {})};
      metadata['sync_status'] = 'synced';
      metadata['synced_at'] = DateTime.now().toIso8601String();

      // Créez un nouveau FormData avec les métadonnées mises à jour
      final updatedForm = FormData(
        uuid: form.uuid,
        identite: form.identite ?? {},
        parcelle: form.parcelle ?? {},
        questionnaire_parcelles: form.questionnaire_parcelles,
        metadata: metadata,
      );

      await _storageService.saveFormData(updatedForm);
      await _storageService.removeFromPendingSync(form.uuid);
    }

    setState(() {
      _pendingSyncForms.clear();
    });
  }

  /// Affiche le résultat de la synchronisation
  void _showSyncResultDialog(int successCount, int failureCount, List<Map<String, dynamic>> errors) {
    showDialog(
      context: context,
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
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Résumé de la synchronisation:', style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: failureCount == 0 ? Colors.green : Colors.orange,
                )),
                const SizedBox(height: 12),
                _buildResultRow('Total enregistrements:', '${successCount + failureCount}'),
                _buildResultRow('Synchronisés avec succès:', '$successCount', Colors.green),
                _buildResultRow('Échecs:', '$failureCount', failureCount > 0 ? Colors.red : Colors.grey),

                if (failureCount > 0) ...[
                  const SizedBox(height: 16),
                  const Text('Détails des échecs:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...errors.take(3).map((error) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• Enregistrement ${(error['index'] as int?) != null ? (error['index'] as int) + 1 : 'N/A'}: ${error['error']}',
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  )).toList(),

                  if (errors.length > 3)
                    Text('... et ${errors.length - 3} autres erreurs', style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    )),
                ],

                const SizedBox(height: 16),
                const Text('Fichier JSON:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  _consolidatedJsonPath ?? 'Non disponible',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Synchronisation terminée', Colors.green);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: failureCount == 0 ? const Color(0xFF1AB999) : Colors.orange,
            ),
            child: Text(failureCount == 0 ? 'OK' : 'Compris'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, [Color? color]) {
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
              color: color ?? const Color(0xFF003D82),
            ),
          ),
        ],
      ),
    );
  }

  /// Collecte les données du formulaire
  FormData _collectFormData(String uuid) {
    List<Map<String, dynamic>> questionnaireData = [];

    if (_questionnaireData != null) {
      if (_questionnaireData is Map<String, dynamic>) {
        questionnaireData = [_questionnaireData!];
      } else if (_questionnaireData is List) {
        final list = _questionnaireData as List<dynamic>;
        questionnaireData = list.whereType<Map<String, dynamic>>().toList();
      }
    }

    final metadata = <String, dynamic>{
      'date_enquete': DateTime.now().toString().split(' ')[0],
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0',
      'agent': _agentName,
      'agent_email': _userData?['email']?.toString() ?? '',
      'agent_id': _userData?['id']?.toString() ?? '',
      'sync_status': hasInternet ? 'pending' : 'offline',
      'commune_nom': _controllers.commune.text.trim(),
      'fokontany_nom': _controllers.fokontany.text.trim(),
      'has_questionnaire': questionnaireData.isNotEmpty,
    };

    final identite = <String, dynamic>{
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
    };

    final parcelle = <String, dynamic>{
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
    };

    return FormData(
      uuid: uuid,
      identite: identite,
      parcelle: parcelle,
      questionnaire_parcelles: questionnaireData,
      metadata: metadata,
    );
  }

  /// Helper pour créer un FormData avec des métadonnées mises à jour
  FormData _createFormDataWithUpdatedMetadata(
      FormData originalForm,
      Map<String, dynamic> metadataUpdates,
      ) {
    final updatedMetadata = {...(originalForm.metadata ?? {}), ...metadataUpdates};

    return FormData(
      uuid: originalForm.uuid,
      identite: originalForm.identite ?? {},
      parcelle: originalForm.parcelle ?? {},
      questionnaire_parcelles: originalForm.questionnaire_parcelles,
      metadata: updatedMetadata,
    );
  }

  /// Génère les données géométriques
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

  /// Méthodes utilitaires pour la conversion sécurisée
  String safeString(dynamic value, [String defaultValue = '']) {
    if (value == null) return defaultValue;
    if (value is String) return value.trim();
    return value.toString().trim();
  }

  int safeInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) {
      final cleaned = value.trim().replaceAll(RegExp(r'[^0-9-]'), '');
      return int.tryParse(cleaned) ?? defaultValue;
    }
    if (value is double) return value.toInt();
    return defaultValue;
  }

  double safeDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleaned = value.trim().replaceAll(RegExp(r'[^0-9.-]'), '');
      return double.tryParse(cleaned) ?? defaultValue;
    }
    return defaultValue;
  }

  Map<String, dynamic> _safeCin(dynamic cinData) {
    try {
      if (cinData == null) return {};
      if (cinData is! Map<String, dynamic>) return {};

      final cinMap = cinData;
      final cleanedCin = <String, dynamic>{};

      if (cinMap['numero'] != null) {
        cleanedCin['numero'] = safeString(cinMap['numero']);
      }
      if (cinMap['date_delivrance'] != null) {
        cleanedCin['date_delivrance'] = safeString(cinMap['date_delivrance']);
      }
      if (cinMap['commune_delivrance'] != null) {
        cleanedCin['commune_delivrance'] = safeString(cinMap['commune_delivrance']);
      }

      return cleanedCin;
    } catch (e) {
      return {};
    }
  }

  List<Map<String, double>> _safeGeomData(Map<String, dynamic> parcelle) {
    try {
      final lat = safeDouble(parcelle['latitude'], -18.879);
      final lng = safeDouble(parcelle['longitude'], 47.5078);

      return [
        {'latitude': lat, 'longitude': lng},
        {'latitude': lat - 0.00005, 'longitude': lng + 0.00005},
        {'latitude': lat - 0.0001, 'longitude': lng - 0.00005},
        {'latitude': lat, 'longitude': lng},
      ];
    } catch (e) {
      return [
        {'latitude': -18.879, 'longitude': 47.5078},
        {'latitude': -18.87905, 'longitude': 47.50785},
        {'latitude': -18.8791, 'longitude': 47.50775},
        {'latitude': -18.879, 'longitude': 47.5078},
      ];
    }
  }

  Map<String, dynamic> _ensureMap(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }

  /// Convertit une valeur en int (sécurisé pour Ruby on Rails)
  int _convertToInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      // Nettoyer la chaîne (enlever tout sauf les chiffres)
      final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleaned.isEmpty) return 0;
      return int.tryParse(cleaned) ?? 0;
    }
    if (value is bool) return value ? 1 : 0;

    try {
      return int.parse(value.toString());
    } catch (e) {
      return 0;
    }
  }

  /// Convertit une valeur en double (sécurisé pour Ruby on Rails)
  double _convertToDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // Remplacer les virgules par des points et nettoyer
      final cleaned = value.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.-]'), '');
      if (cleaned.isEmpty) return 0.0;
      return double.tryParse(cleaned) ?? 0.0;
    }

    try {
      return double.parse(value.toString());
    } catch (e) {
      return 0.0;
    }
  }

  /// Nettoie les données du questionnaire pour Ruby
  Map<String, dynamic> _cleanQuestionnaireDataForRuby(Map<String, dynamic> data) {
    final cleaned = <String, dynamic>{};

    data.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        cleaned[key] = _cleanNestedQuestionnaireDataForRuby(value);
      } else if (value is List) {
        cleaned[key] = _cleanQuestionnaireList(value);
      } else {
        cleaned[key] = _cleanQuestionnaireValueForRuby(value);
      }
    });

    return cleaned;
  }

  Map<String, dynamic> _cleanNestedQuestionnaireDataForRuby(Map<String, dynamic> data) {
    final cleaned = <String, dynamic>{};

    data.forEach((key, value) {
      cleaned[key] = _cleanQuestionnaireValueForRuby(value);
    });

    return cleaned;
  }

  List<dynamic> _cleanQuestionnaireList(List<dynamic> list) {
    return list.map((item) {
      if (item is Map<String, dynamic>) {
        return _cleanNestedQuestionnaireDataForRuby(item);
      } else {
        return _cleanQuestionnaireValueForRuby(item);
      }
    }).toList();
  }

  dynamic _cleanQuestionnaireValueForRuby(dynamic value) {
    if (value == null) return null;

    if (value is String) {
      // Vérifier si c'est un nombre
      final trimmedValue = value.trim();
      if (RegExp(r'^-?\d+$').hasMatch(trimmedValue)) {
        return _convertToInt(trimmedValue);
      } else if (RegExp(r'^-?\d*\.?\d+$').hasMatch(trimmedValue)) {
        return _convertToDouble(trimmedValue);
      } else if (trimmedValue.toLowerCase() == 'true') {
        return true;
      } else if (trimmedValue.toLowerCase() == 'false') {
        return false;
      }
      return value;
    }

    if (value is List) {
      return value.map((item) => _cleanQuestionnaireValueForRuby(item)).toList();
    }

    return value;
  }

  /// Convertit FormData en format JSON complet pour l'API Ruby
  Map<String, dynamic> _convertToCompleteJsonForRuby(FormData formData) {
    print('🔧 CONVERSION JSON pour Ruby - ${formData.uuid}');

    final identite = _ensureMap(formData.identite);
    final parcelle = _ensureMap(formData.parcelle);
    final metadata = _ensureMap(formData.metadata);

    // Gestion du questionnaire
    List<Map<String, dynamic>> questionnaireData = [];

    if (formData.questionnaire_parcelles != null) {
      if (formData.questionnaire_parcelles is List) {
        final list = formData.questionnaire_parcelles as List<dynamic>;
        for (var item in list) {
          if (item is Map<String, dynamic>) {
            questionnaireData.add(_cleanQuestionnaireDataForRuby(item));
          }
        }
      } else if (formData.questionnaire_parcelles is Map<String, dynamic>) {
        questionnaireData.add(_cleanQuestionnaireDataForRuby(formData.questionnaire_parcelles! as Map<String, dynamic>));
      }
    }

    // CONSTRUCTION SELON LE FORMAT EXACT DU SERVEUR RUBY
    final jsonData = {
      'individu': {
        'uuid': safeString(formData.uuid),
        'nom': safeString(identite['nom'], 'Inconnu'),
        'prenom': safeString(identite['prenom'], 'Inconnu'),
        'surnom': safeString(identite['surnom']),
        'sexe': safeString(identite['sexe']),
        'date_naissance': safeString(identite['date_naissance']),
        'lieu_naissance': safeString(identite['lieu_naissance'], safeString(identite['lieu_naissance'])),
        'adresse': safeString(identite['adresse']),
        'gps_point': '${_convertToDouble(parcelle['latitude'] ?? -18.879)},${_convertToDouble(parcelle['longitude'] ?? 47.5078)}',
        'photo': '',

        // CORRECTION CRITIQUE: Les champs numériques doivent être des int
        'user_id': _convertToInt(metadata['agent_id'] ?? 1),
        'commune_id': 2, // Valeur fixe comme dans l'exemple

        'nom_pere': safeString(identite['nom_pere']),
        'nom_mere': safeString(identite['nom_mere']),
        'profession': safeString(identite['metier']),
        'activites_complementaires': safeString(identite['activites_complementaires']),
        'statut_matrimonial': safeString(identite['statut_matrimonial']),

        'nombre_personnes_a_charge': _convertToInt(identite['nombre_personnes_charge'] ?? 0),

        'telephone': safeString(identite['telephone1']),
        'cin': _safeCin(identite['cin']),
        'commune_nom': safeString(identite['commune'], 'Non spécifié'),
        'fokontany_nom': safeString(identite['fokontany'], 'Non spécifié'),

        'nombre_enfants': _convertToInt(identite['nombre_enfants'] ?? 0),

        'telephone2': safeString(identite['telephone2']),
      },
      'parcelles': [
        {
          'nom': safeString(parcelle['nom'], 'Parcelle ${identite['nom']} ${identite['prenom']}'),

          'superficie': _convertToDouble(parcelle['superficie'] ?? 1500.0),

          'gps': {
            'latitude': _convertToDouble(parcelle['latitude'] ?? -18.879),
            'longitude': _convertToDouble(parcelle['longitude'] ?? 47.5078),
            'altitude': _convertToDouble(parcelle['altitude'] ?? 1280.0),
          },
          'geom': _safeGeomData(parcelle),
          'description': safeString(parcelle['description'], 'Rizière en terrasse'),
        }
      ],
      'questionnaire_parcelles': questionnaireData,
    };


    final parcelleList = jsonData['parcelles'] as List;
    if (parcelleList.isNotEmpty) {
      final firstParcelle = parcelleList[0] as Map<String, dynamic>;
      print('   - superficie: ${firstParcelle['superficie']} (${firstParcelle['superficie'].runtimeType})');
    }

    return jsonData;
  }

  /// Nettoie et convertit une valeur en int (renommée pour éviter les conflits)
  int _cleanIntForRuby(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;

    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      // Enlever tous les caractères non numériques sauf le signe négatif
      final cleaned = value.trim().replaceAll(RegExp(r'[^0-9\-]'), '');
      if (cleaned.isEmpty) return defaultValue;
      return int.tryParse(cleaned) ?? defaultValue;
    }
    return defaultValue;
  }

  /// Met à jour les métadonnées d'un FormData
  FormData _updateFormDataMetadata(FormData formData, Map<String, dynamic> newMetadata) {
    return FormData(
      uuid: formData.uuid,
      identite: formData.identite ?? {},
      parcelle: formData.parcelle ?? {},
      questionnaire_parcelles: formData.questionnaire_parcelles,
      metadata: newMetadata,
    );
  }

  /// Sauvegarde les données du formulaire
  Future<void> _saveFormDataLocally() async {
    try {
      if (!_controllers.validate()) {
        _showSnackBar('Veuillez remplir les champs obligatoires', Colors.orange);
        return;
      }

      final numeroCIN = _controllers.numeroCIN.text.trim();
      final uuid = _storageService.generateUuid(
        _controllers.nom.text,
        _controllers.prenom.text,
      );

      if (await _storageService.uuidExists(uuid)) {
        _showSnackBar('Formulaire déjà existant', Colors.orange);
        return;
      }

      final formData = _collectFormData(uuid);
      await _storageService.saveFormData(formData);

      // Sauvegarde des images
      await _imageManager.saveImagesToAppDirectory(uuid);
      final appDir = await getApplicationDocumentsDirectory();
      await _curlGenerator.generateCurlCommand(uuid, appDir.path, _imageManager);

      // Mettre à jour le fichier JSON consolidé
      await _createOrUpdateConsolidatedJson();

      // Gestion de la synchronisation
      if (hasInternet && _autoSyncEnabled) {
        _showSnackBar('📡 Synchronisation en cours...', Colors.blue);

        try {
          final success = await _syncSingleFormDirectForRuby(formData);

          if (success) {
            // Créez une nouvelle instance avec métadonnées mises à jour
            final updatedMetadata = {...(formData.metadata ?? {})};
            updatedMetadata['sync_status'] = 'synced';
            updatedMetadata['synced_at'] = DateTime.now().toIso8601String();

            final updatedFormData = FormData(
              uuid: formData.uuid,
              identite: formData.identite ?? {},
              parcelle: formData.parcelle ?? {},
              questionnaire_parcelles: formData.questionnaire_parcelles,
              metadata: updatedMetadata,
            );

            await _storageService.saveFormData(updatedFormData);
            _showSnackBar('✅ Formulaire synchronisé!', Colors.green);
          } else {
            // Créez une nouvelle instance avec métadonnées mises à jour
            final updatedMetadata = {...(formData.metadata ?? {})};
            updatedMetadata['sync_status'] = 'pending';
            updatedMetadata['pending_since'] = DateTime.now().toIso8601String();

            final updatedFormData = FormData(
              uuid: formData.uuid,
              identite: formData.identite ?? {},
              parcelle: formData.parcelle ?? {},
              questionnaire_parcelles: formData.questionnaire_parcelles,
              metadata: updatedMetadata,
            );

            await _storageService.addToPendingSync(updatedFormData);
            setState(() { _pendingSyncForms.add(updatedFormData); });
            _showSnackBar('⏳ Formulaire en attente de sync', Colors.orange);
          }
        } catch (e) {
          // Créez une nouvelle instance avec métadonnées mises à jour
          final updatedMetadata = {...(formData.metadata ?? {})};
          updatedMetadata['sync_status'] = 'pending';
          updatedMetadata['pending_since'] = DateTime.now().toIso8601String();

          final updatedFormData = FormData(
            uuid: formData.uuid,
            identite: formData.identite ?? {},
            parcelle: formData.parcelle ?? {},
            questionnaire_parcelles: formData.questionnaire_parcelles,
            metadata: updatedMetadata,
          );

          await _storageService.addToPendingSync(updatedFormData);
          setState(() { _pendingSyncForms.add(updatedFormData); });
          _showSnackBar('💾 Formulaire sauvegardé localement', Colors.orange);
        }
      } else {
        // Créez une nouvelle instance avec métadonnées mises à jour
        final updatedMetadata = {...(formData.metadata ?? {})};
        updatedMetadata['sync_status'] = 'offline';
        updatedMetadata['pending_since'] = DateTime.now().toIso8601String();

        final updatedFormData = FormData(
          uuid: formData.uuid,
          identite: formData.identite ?? {},
          parcelle: formData.parcelle ?? {},
          questionnaire_parcelles: formData.questionnaire_parcelles,
          metadata: updatedMetadata,
        );

        await _storageService.addToPendingSync(updatedFormData);
        setState(() { _pendingSyncForms.add(updatedFormData); });
        _showSnackBar('💾 Formulaire sauvegardé (hors ligne)', Colors.orange);
      }

      await _loadAllForms();
      _showSuccessDialog(formData.uuid, formData);
      _resetForm();

    } catch (e) {
      _showSnackBar('❌ Erreur sauvegarde: $e', Colors.red);
      print('Erreur sauvegarde: $e');
    }
  }

  /// Synchronise un formulaire directement avec le serveur - VERSION RUBY
  Future<bool> _syncSingleFormDirectForRuby(FormData formData) async {
    try {
      final url = Uri.parse('http://13.246.182.15:3001/import_massif');

      // Créer une liste avec un seul élément pour Ruby
      final List<Map<String, dynamic>> dataList = [_convertToCompleteJsonForRuby(formData)];
      final jsonString = JsonEncoder.withIndent('  ').convert(dataList);

      // AFFICHER LE JSON POUR DEBUG
      print('📤 JSON envoyé au serveur Ruby (format liste):');
      print(jsonString);

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': _authToken != null ? 'Bearer $_authToken' : '',
        },
        body: jsonString,
      ).timeout(const Duration(seconds: 30));

      print('📥 Réponse serveur Ruby:');
      print('   Statut: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Succès - Statut ${response.statusCode}');
        return true;
      } else {
        print('❌ Erreur - Statut ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Exception sync direct: $e');
      return false;
    }
  }

  /// Teste la connexion au serveur
  Future<void> _testServerConnection() async {
    _showSnackBar('Test de connexion serveur...', Colors.blue);

    final result = await _autoSyncService.testServerConnection();

    if (result['success'] == true) {
      _showSnackBar('✅ Serveur accessible', Colors.green);
    } else {
      _showSnackBar('❌ Serveur inaccessible: ${result['error']}', Colors.red);
    }
  }

  /// Exporte toutes les données
  Future<void> _exportAllData() async {
    try {
      await _createOrUpdateConsolidatedJson();

      if (_consolidatedJsonPath != null) {
        final file = File(_consolidatedJsonPath!);
        if (await file.exists()) {
          final content = await file.readAsString();
          final directory = await getExternalStorageDirectory();
          final exportFile = File('${directory?.path}/export_${DateTime.now().millisecondsSinceEpoch}.json');
          await exportFile.writeAsString(content);

          _showSnackBar('✅ Export réussi: ${exportFile.path}', Colors.green);
        }
      }
    } catch (e) {
      _showSnackBar('❌ Erreur export: $e', Colors.red);
    }
  }

  /// Gère la déconnexion
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

  /// Réinitialise le formulaire
  void _resetForm() {
    setState(() {
      _controllers.clear();
      _imageManager.clear();
      _typeContrat = 'Co-gestion';
      _questionnaireData = null;
    });
    _showSnackBar('🔄 Formulaire réinitialisé', Colors.blue);
  }

  /// Affiche une dialog de succès
  void _showSuccessDialog(String uuid, FormData formData) {
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isPendingSync
                ? '⏳ Formulaire en attente de synchronisation'
                : '✅ Formulaire sauvegardé et synchronisé!'),
            const SizedBox(height: 12),
            Text('UUID: $uuid',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            const SizedBox(height: 8),
            Text('Total: ${_allForms.length}',
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              final jsonData = JsonEncoder.withIndent('  ').convert(_convertToCompleteJsonForRuby(formData));
              Clipboard.setData(ClipboardData(text: jsonData));
              _showSnackBar('📋 JSON copié', Colors.green);
            },
            child: const Text('Copier JSON'),
          ),
        ],
      ),
    );
  }

  /// Affiche un snackbar
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

  /// Navigue vers l'écran Questionnaire
  void _navigateToQuestionnaire(String title, int questionnaireNumber) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionnaireScreen(
          title: title,
          questionnaireNumber: questionnaireNumber,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      _handleQuestionnaireResult(result);
    }
  }

  /// Traite le résultat du questionnaire
  void _handleQuestionnaireResult(Map<String, dynamic> questionnaireData) {
    final questionnaireParcelles = questionnaireData['questionnaire_parcelles'];

    if (questionnaireParcelles != null) {
      if (questionnaireParcelles is List && questionnaireParcelles.isNotEmpty) {
        if (questionnaireParcelles.first is Map<String, dynamic>) {
          setState(() {
            _questionnaireData = questionnaireParcelles.first as Map<String, dynamic>;
          });
          _showSnackBar('✅ Questionnaire sauvegardé', Colors.green);
        } else {
          _showSnackBar('❌ Format de questionnaire invalide', Colors.red);
        }
      } else {
        _showSnackBar('❌ Questionnaire vide', Colors.orange);
      }
    } else {
      _showSnackBar('❌ Données du questionnaire manquantes', Colors.red);
    }
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

  /// Charge un formulaire par son UUID
  Future<void> _loadFormByUuid(String uuid) async {
    try {
      final form = await _storageService.getFormByUuid(uuid);
      if (form == null) {
        _showSnackBar('Formulaire non trouvé', Colors.red);
        return;
      }

      final identite = form.identite ?? {};
      final parcelle = form.parcelle ?? {};

      _controllers.nom.text = identite['nom']?.toString() ?? '';
      _controllers.prenom.text = identite['prenom']?.toString() ?? '';
      _controllers.surnom.text = identite['surnom']?.toString() ?? '';
      _controllers.sexe.text = identite['sexe']?.toString() ?? '';
      _controllers.dateNaissance.text = identite['date_naissance']?.toString() ?? '';
      _controllers.lieuNaissance.text = identite['lieu_naissance']?.toString() ?? '';
      _controllers.statutMatrimonial.text = identite['statut_matrimonial']?.toString() ?? '';
      _controllers.nombreEnfants.text = identite['nombre_enfants']?.toString() ?? '';
      _controllers.nombrePersonnesCharge.text = identite['nombre_personnes_charge']?.toString() ?? '';
      _controllers.nomPere.text = identite['nom_pere']?.toString() ?? '';
      _controllers.nomMere.text = identite['nom_mere']?.toString() ?? '';
      _controllers.metier.text = identite['metier']?.toString() ?? '';
      _controllers.activitesComplementaires.text = identite['activites_complementaires']?.toString() ?? '';
      _controllers.adresse.text = identite['adresse']?.toString() ?? '';
      _controllers.region.text = identite['region']?.toString() ?? '';
      _controllers.commune.text = identite['commune']?.toString() ?? '';
      _controllers.fokontany.text = identite['fokontany']?.toString() ?? '';
      _controllers.telephone1.text = identite['telephone1']?.toString() ?? '';
      _controllers.telephone2.text = identite['telephone2']?.toString() ?? '';

      final cin = identite['cin'] as Map<String, dynamic>? ?? {};
      _controllers.numeroCIN.text = cin['numero']?.toString() ?? '';
      _controllers.dateDelivrance.text = cin['date_delivrance']?.toString() ?? '';

      _controllers.latitude.text = parcelle['latitude']?.toString() ?? '';
      _controllers.longitude.text = parcelle['longitude']?.toString() ?? '';
      _controllers.altitude.text = parcelle['altitude']?.toString() ?? '';
      _controllers.precision.text = parcelle['precision']?.toString() ?? '';

      setState(() {
        _typeContrat = parcelle['type_contrat']?.toString() ?? 'Co-gestion';
        _selectedIndex = 1;
      });

      _showSnackBar('✅ Formulaire chargé', Colors.green);
    } catch (e) {
      _showSnackBar('❌ Erreur chargement: $e', Colors.red);
    }
  }

  /// Supprime un formulaire
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
        await _createOrUpdateConsolidatedJson();
        _showSnackBar('✅ Formulaire supprimé', Colors.green);
      } else {
        _showSnackBar('❌ Erreur suppression', Colors.red);
      }
    }
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
    final double progress = _totalSyncItems > 0 ? _currentSyncProgress / _totalSyncItems : 0.0;

    return Material(
      color: Colors.blue.shade50,
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.sync, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Synchronisation en cours...',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        '$_currentSyncProgress/$_totalSyncItems formulaires (${(progress * 100).toStringAsFixed(0)}%)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
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
      padding: const EdgeInsets.symmetric(vertical: 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Dashboard (${_allForms.length})',
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
            const Center(child: CircularProgressIndicator(color: Color(0xFF1AB999)))
          else if (_allForms.isEmpty)
            _buildEmptyState()
          else
            _buildFormsList(),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
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
  }

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
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003D82),
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
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
        final nom = form.identite?['nom']?.toString() ?? 'N/A';
        final prenom = form.identite?['prenom']?.toString() ?? 'N/A';
        final region = form.identite?['region']?.toString() ?? 'Non spécifié';
        final commune = form.identite?['commune']?.toString() ?? 'Non spécifié';
        final dateEnquete = form.metadata?['date_enquete']?.toString() ?? 'N/A';

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
      padding: const EdgeInsets.symmetric(vertical: 30.0),
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
    final hasQuestionnaireData = _questionnaireData != null;

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
                if (hasQuestionnaireData)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Questionnaire Riziculture rempli',
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                const Text('Liste des continues', style: TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 16),

                Container(
                  decoration: hasQuestionnaireData ? BoxDecoration(
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ) : null,
                  child: _buildContinueItemWithIndicator(
                    3,
                    'Riziculture',
                    'Techniques de culture du riz',
                    false,
                    onTap: () => _navigateToQuestionnaire('Riziculture', 3),
                    hasData: hasQuestionnaireData,
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE0E0E0)),
                FormWidgets.buildContinueItem(4, 'Élevage', 'Pratiques d\'élevage', false, onTap: () => _navigateToContinue('Élevage', 4)),
                const Divider(height: 1, color: Color(0xFFE0E0E0)),
                FormWidgets.buildContinueItem(5, 'Pêche', 'Techniques de pêche', false, onTap: () => _navigateToContinue('Pêche', 5)),
                const Divider(height: 1, color: Color(0xFFE0E0E0)),
                FormWidgets.buildContinueItem(6, 'Agriculture vivrière', 'Cultures alimentaires', false),
                const Divider(height: 1, color: Color(0xFFE0E0E0)),
                FormWidgets.buildContinueItem(7, 'Commerce', 'Activités commerciales', false, onTap: () => _navigateToContinue('Commerce', 7)),
                const Divider(height: 1, color: Color(0xFFE0E0E0)),
                FormWidgets.buildContinueItem(8, 'Artisanat', 'Métiers artisanaux', false),
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

  Widget _buildContinueItemWithIndicator(int number, String title, String subtitle, bool isDisabled,
      {VoidCallback? onTap, bool hasData = false}) {
    return ListTile(
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isDisabled ? const Color(0xFF8E99AB) : const Color(0xFF1AB999),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: hasData
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Text(
            number.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDisabled ? const Color(0xFF8E99AB) : const Color(0xFF333333),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDisabled ? const Color(0xFF8E99AB) : const Color(0xFF8E99AB),
          fontSize: 12,
        ),
      ),
      trailing: isDisabled
          ? const Icon(Icons.lock, color: Color(0xFF8E99AB), size: 16)
          : const Icon(Icons.arrow_forward_ios, color: Color(0xFF8E99AB), size: 16),
      onTap: isDisabled ? null : onTap,
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
          const Text(
            'Synchronisation des données',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF003D82)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gestion centralisée via fichier JSON unique',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // CARTE FICHIER JSON CONSOLIDÉ
          _buildConsolidatedJsonCard(),
          const SizedBox(height: 24),

          // CARTE ACTIONS DE SYNCHRONISATION
          _buildSyncActionsCard(),
          const SizedBox(height: 24),

          // CARTE STATISTIQUES
          _buildStatsCard(),
        ],
      ),
    );
  }

  Widget _buildConsolidatedJsonCard() {
    final hasJsonFile = _consolidatedJsonPath != null && File(_consolidatedJsonPath!).existsSync();

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insert_drive_file, color: Color(0xFF1AB999)),
              const SizedBox(width: 8),
              const Text(
                'Fichier JSON consolidé',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003D82),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: hasJsonFile ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  hasJsonFile ? 'Disponible' : 'Non disponible',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (hasJsonFile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Chemin:', _consolidatedJsonPath!, copyable: true),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          if (_consolidatedJsonPath != null) {
                            final file = File(_consolidatedJsonPath!);
                            if (await file.exists()) {
                              final content = await file.readAsString();
                              _showJsonPreview(content);
                            }
                          }
                        },
                        icon: const Icon(Icons.preview, size: 16),
                        label: const Text('Aperçu'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          if (_consolidatedJsonPath != null) {
                            final file = File(_consolidatedJsonPath!);
                            if (await file.exists()) {
                              final content = await file.readAsString();
                              Clipboard.setData(ClipboardData(text: content));
                              _showSnackBar('📋 JSON copié', Colors.green);
                            }
                          }
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copier'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                ElevatedButton.icon(
                  onPressed: _createOrUpdateConsolidatedJson,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Regénérer le fichier JSON'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1AB999),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                const Icon(Icons.folder_open, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                const Text(
                  'Aucun fichier JSON consolidé',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _createOrUpdateConsolidatedJson,
                  icon: const Icon(Icons.add),
                  label: const Text('Créer le fichier JSON'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1AB999),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSyncActionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Synchronisation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003D82),
            ),
          ),
          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton.icon(
              onPressed: _isSyncing ? null : _syncAllFormsViaJsonForRuby,
              icon: _isSyncing
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Icon(Icons.cloud_upload, size: 24),
              label: _isSyncing
                  ? Text(
                'Synchronisation... ($_currentSyncProgress/$_totalSyncItems)',
                style: const TextStyle(fontSize: 16),
              )
                  : const Text(
                'SYNCHRONISER TOUTES LES DONNÉES',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1AB999),
                minimumSize: const Size(double.infinity, 60),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _testServerConnection,
                  icon: const Icon(Icons.cloud, size: 16),
                  label: const Text('Tester serveur'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _exportAllData,
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Exporter'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: () async {
              _showSnackBar('Actualisation...', Colors.blue);
              await _loadAllForms();
              await _loadPendingSyncForms();
              await _createOrUpdateConsolidatedJson();
              _showSnackBar('✅ Données actualisées', Colors.green);
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Actualiser les données'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Statistiques', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF003D82))),
          const SizedBox(height: 16),

          const Text('Données locales', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1AB999))),
          const SizedBox(height: 8),
          _buildStatItem('Total formulaires', _allForms.length.toString()),
          _buildStatItem('Formulaires synchronisés', (_allForms.length - _pendingSyncForms.length).toString()),
          _buildStatItem('En attente de sync', _pendingSyncForms.length.toString()),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          const Text('Fichier JSON', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
          const SizedBox(height: 8),

          if (_consolidatedJsonPath != null && File(_consolidatedJsonPath!).existsSync())
            FutureBuilder<File>(
              future: Future.value(File(_consolidatedJsonPath!)),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final file = snapshot.data!;
                  return Column(
                    children: [
                      _buildStatItem('Taille du fichier', '${file.lengthSync() / 1024} KB'),
                      _buildStatItem('Dernière modification', File(_consolidatedJsonPath!).lastModifiedSync().toString().split('.')[0]),
                    ],
                  );
                }
                return const CircularProgressIndicator();
              },
            )
          else
            const Text(
              'Fichier JSON non disponible',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),

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

  Widget _buildInfoRow(String label, String value, {bool copyable = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (copyable)
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  _showSnackBar('Copié', Colors.green);
                },
              ),
          ],
        ),
      ],
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

  void _showJsonPreview(String jsonContent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aperçu du JSON consolidé'),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: SingleChildScrollView(
            child: SelectableText(
              jsonContent,
              style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonContent));
              _showSnackBar('📋 JSON copié', Colors.green);
            },
            child: const Text('Copier tout'),
          ),
        ],
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