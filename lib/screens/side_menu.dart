import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
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

class SideMenu extends StatefulWidget {
  const SideMenu({Key? key}) : super(key: key);

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> with ConnectionMixin {
  int _selectedIndex = 0; // 0: Liste d'individus, 1: Dashboard, 2: Synchronisation, 3: Historique
  bool _isMenuCollapsed = false;

  // Services
  final FormControllers _controllers = FormControllers();
  final ImageManager _imageManager = ImageManager();
  final UnifiedStorageService _storageService = UnifiedStorageService();
  final CurlGenerator _curlGenerator = CurlGenerator();
  final AutoSyncService _autoSyncService = AutoSyncService();

  // Configuration
  bool _autoSyncEnabled = true;

  // Variable pour le type de contrat
  String _typeContrat = 'Co-gestion';

  // Liste des formulaires
  List<FormData> _allForms = [];
  bool _isLoadingForms = false;

  // Statistiques pour le dashboard
  Map<String, dynamic> _dashboardStats = {
    'total_forms': 0,
    'today_forms': 0,
    'by_region': {},
    'by_commune': {},
  };

  @override
  void initState() {
    super.initState();
    _loadAllForms();
    _startConnectionListener();
  }

  void _startConnectionListener() {
    // Écoute les changements de connexion pour afficher les popups
    Connectivity().onConnectivityChanged.listen((result) async {
      if (result == ConnectivityResult.none) {
        // Devenu hors ligne
        _showConnectionPopup(false);
      } else {
        // Devenu en ligne - tester l'accès réel
        final hasRealInternet = await _testInternetAccess();
        if (hasRealInternet) {
          _showConnectionPopup(true);
        }
      }
    });
  }

  Future<bool> _testInternetAccess() async {
    try {
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

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
            SizedBox(width: 8),
            Text(isOnline ? 'Connexion rétablie' : 'Hors ligne'),
          ],
        ),
        content: Text(
          isOnline
              ? 'Votre appareil est maintenant connecté à Internet.'
              : 'Votre appareil n\'est pas connecté à Internet. Certaines fonctionnalités peuvent être limitées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void onConnectionStatusChanged(Map<String, dynamic> status) {
    // On n'utilise plus le badge, seulement les popups
  }

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  // =====================================================================
  // CHARGEMENT DES DONNÉES
  // =====================================================================

  Future<void> _loadAllForms() async {
    setState(() => _isLoadingForms = true);
    try {
      final forms = await _storageService.getAllForms();
      setState(() {
        _allForms = forms;
        _isLoadingForms = false;
      });
      _loadDashboardStats();
    } catch (e) {
      setState(() => _isLoadingForms = false);
      _showSnackBar('Erreur chargement: $e', Colors.red);
    }
  }

  Future<void> _loadDashboardStats() async {
    try {
      final today = DateTime.now().toString().split(' ')[0];
      int todayForms = 0;
      Map<String, int> byRegion = {};
      Map<String, int> byCommune = {};

      for (var form in _allForms) {
        // Compter les formulaires d'aujourd'hui
        if (form.metadata['date_enquete'] == today) {
          todayForms++;
        }

        // Statistiques par région
        final region = form.identite['region'] ?? 'Non spécifié';
        byRegion[region] = (byRegion[region] ?? 0) + 1;

        // Statistiques par commune
        final commune = form.identite['commune'] ?? 'Non spécifié';
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
    }
  }

  // =====================================================================
  // MÉTHODES DE SAUVEGARDE
  // =====================================================================

  Future<void> _saveFormDataLocally() async {
    try {
      if (!_controllers.validate()) {
        _showSnackBar(
          'Veuillez remplir les champs obligatoires (Nom, Prénom)',
          Colors.orange,
        );
        return;
      }

      final uuid = _storageService.generateUuid(
        _controllers.nom.text,
        _controllers.prenom.text,
      );

      if (await _storageService.uuidExists(uuid)) {
        _showSnackBar('UUID en conflit, réessayez', Colors.orange);
        return;
      }

      final formData = _collectFormData(uuid);
      final filePath = await _storageService.saveFormData(formData);

      // Synchronisation automatique seulement si connecté
      if (_autoSyncEnabled && hasInternet) {
        await _autoSyncService.autoSyncAfterSave(formData);
      }

      final _ = await _imageManager.saveImagesToAppDirectory(uuid);
      final appDir = await getApplicationDocumentsDirectory();
      await _curlGenerator.generateCurlCommand(uuid, appDir.path, _imageManager);

      await _loadAllForms();
      _showSuccessDialog(filePath, formData);
    } catch (e) {
      _showSnackBar('Erreur sauvegarde: $e', Colors.red);
    }
  }

  FormData _collectFormData(String uuid) {
    return FormData(
      uuid: uuid,
      identite: {
        'nom': _controllers.nom.text,
        'prenom': _controllers.prenom.text,
        'surnom': _controllers.surnom.text,
        'sexe': _controllers.sexe.text,
        'date_naissance': _controllers.dateNaissance.text,
        'lieu_naissance': _controllers.lieuNaissance.text,
        'statut_matrimonial': _controllers.statutMatrimonial.text,
        'nombre_enfants': _controllers.nombreEnfants.text,
        'nombre_personnes_charge': _controllers.nombrePersonnesCharge.text,
        'nom_pere': _controllers.nomPere.text,
        'nom_mere': _controllers.nomMere.text,
        'metier': _controllers.metier.text,
        'activites_complementaires': _controllers.activitesComplementaires.text,
        'adresse': _controllers.adresse.text,
        'region': _controllers.region.text,
        'commune': _controllers.commune.text,
        'fokontany': _controllers.fokontany.text,
        'telephone1': _controllers.telephone1.text,
        'telephone2': _controllers.telephone2.text,
        'cin': {
          'numero': _controllers.numeroCIN.text,
          'date_delivrance': _controllers.dateDelivrance.text,
        }
      },
      parcelle: {
        'latitude': _controllers.latitude.text,
        'longitude': _controllers.longitude.text,
        'altitude': _controllers.altitude.text,
        'precision': _controllers.precision.text,
        'type_contrat': _typeContrat,
      },
      metadata: {
        'date_enquete': DateTime.now().toString().split(' ')[0],
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0',
        'agent': 'Nom de l\'agent'
      },
    );
  }

  void _resetForm() {
    setState(() {
      _controllers.clear();
      _imageManager.clear();
      _typeContrat = 'Co-gestion';
    });
    _showSnackBar('Formulaire réinitialisé', Colors.blue);
  }

  // =====================================================================
  // GESTION DES FORMULAIRES
  // =====================================================================

  Future<void> _loadFormByUuid(String uuid) async {
    try {
      final form = await _storageService.getFormByUuid(uuid);
      if (form == null) {
        _showSnackBar('Formulaire non trouvé', Colors.red);
        return;
      }

      _controllers.nom.text = form.identite['nom'] ?? '';
      _controllers.prenom.text = form.identite['prenom'] ?? '';
      _controllers.surnom.text = form.identite['surnom'] ?? '';
      _controllers.sexe.text = form.identite['sexe'] ?? '';
      _controllers.dateNaissance.text = form.identite['date_naissance'] ?? '';
      _controllers.lieuNaissance.text = form.identite['lieu_naissance'] ?? '';
      _controllers.statutMatrimonial.text = form.identite['statut_matrimonial'] ?? '';
      _controllers.nombreEnfants.text = form.identite['nombre_enfants'] ?? '';
      _controllers.nombrePersonnesCharge.text = form.identite['nombre_personnes_charge'] ?? '';
      _controllers.nomPere.text = form.identite['nom_pere'] ?? '';
      _controllers.nomMere.text = form.identite['nom_mere'] ?? '';
      _controllers.metier.text = form.identite['metier'] ?? '';
      _controllers.activitesComplementaires.text = form.identite['activites_complementaires'] ?? '';
      _controllers.adresse.text = form.identite['adresse'] ?? '';
      _controllers.region.text = form.identite['region'] ?? '';
      _controllers.commune.text = form.identite['commune'] ?? '';
      _controllers.fokontany.text = form.identite['fokontany'] ?? '';
      _controllers.telephone1.text = form.identite['telephone1'] ?? '';
      _controllers.telephone2.text = form.identite['telephone2'] ?? '';

      final cin = form.identite['cin'] as Map<String, dynamic>? ?? {};
      _controllers.numeroCIN.text = cin['numero'] ?? '';
      _controllers.dateDelivrance.text = cin['date_delivrance'] ?? '';

      _controllers.latitude.text = form.parcelle['latitude'] ?? '';
      _controllers.longitude.text = form.parcelle['longitude'] ?? '';
      _controllers.altitude.text = form.parcelle['altitude'] ?? '';
      _controllers.precision.text = form.parcelle['precision'] ?? '';

      setState(() {
        _typeContrat = form.parcelle['type_contrat'] ?? 'Co-gestion';
        _selectedIndex = 1; // Rediriger vers le Dashboard (nouveau formulaire)
      });

      _showSnackBar('Formulaire chargé', Colors.green);
    } catch (e) {
      _showSnackBar('Erreur chargement: $e', Colors.red);
    }
  }

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
        await _loadAllForms();
        _showSnackBar('Formulaire supprimé', Colors.green);
      } else {
        _showSnackBar('Erreur suppression', Colors.red);
      }
    }
  }

  Future<void> _exportAllData() async {
    try {
      final path = await _storageService.exportAllForms();
      if (path != null) {
        _showSnackBar('Export réussi: $path', Colors.green);
      } else {
        _showSnackBar('Erreur export', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Erreur export: $e', Colors.red);
    }
  }

  // =====================================================================
  // DIALOGUES ET UI
  // =====================================================================

  void _showSuccessDialog(String filePath, FormData formData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Succès'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('✅ Formulaire sauvegardé!'),
            const SizedBox(height: 12),
            Text('UUID: ${formData.uuid}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            const SizedBox(height: 8),
            Text('Total: ${_allForms.length}',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            if (!hasInternet)
              const Text(
                '⚠️ Données sauvegardées localement (hors ligne)',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              final jsonData = JsonEncoder.withIndent('  ').convert(formData.toJson());
              Clipboard.setData(ClipboardData(text: jsonData));
              _showSnackBar('JSON copié', Colors.green);
            },
            child: const Text('Copier JSON'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

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

  Future<void> _handleImagePick(String imageType) async {
    try {
      await _imageManager.pickImage(imageType);
      setState(() {});
    } catch (e) {
      _showSnackBar('Erreur sélection: $e', Colors.red);
    }
  }

  void _handleImageRemove(String imageType) {
    setState(() {
      _imageManager.removeImage(imageType);
    });
  }

  // =====================================================================
  // BUILD PRINCIPAL SANS INDICATEUR DE CONNEXION
  // =====================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Menu latéral
          MenuWidget(
            selectedIndex: _selectedIndex,
            isMenuCollapsed: _isMenuCollapsed,
            onMenuItemTap: (index) => setState(() => _selectedIndex = index),
            onToggleMenu: () => setState(() => _isMenuCollapsed = !_isMenuCollapsed),
            onLogout: () {},
          ),
          // Contenu principal - S'ADAPTE À TOUTE LA TAILLE D'ÉCRAN
          Expanded(
            child: Container(
              color: const Color(0xFFF5F7FA),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildFormsListContent(); // Liste d'individus
      case 1:
        return _buildDashboardContent(); // Dashboard
      case 2:
        return _buildSynchronizationContent();
      case 3:
        return _buildHistoryContent();
      default:
        return _buildFormsListContent();
    }
  }

  // =====================================================================
  // PAGE 0 - LISTE D'INDIVIDUS AVEC STATISTIQUES
  // =====================================================================

  Widget _buildFormsListContent() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Liste des individus (${_allForms.length})',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003D82),
            ),
          ),
          const SizedBox(height: 20),

          // GRILLE DE STATISTIQUES
          _buildStatsGrid(),
          const SizedBox(height: 20),

          if (_isLoadingForms)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(50),
                child: CircularProgressIndicator(color: Color(0xFF1AB999)),
              ),
            )
          else if (_allForms.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 50),
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
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _allForms.length,
                itemBuilder: (context, index) {
                  final form = _allForms[index];
                  final nom = form.identite['nom'] ?? 'N/A';
                  final prenom = form.identite['prenom'] ?? 'N/A';
                  final region = form.identite['region'] ?? 'Non spécifié';
                  final commune = form.identite['commune'] ?? 'Non spécifié';
                  final dateEnquete = form.metadata['date_enquete'] ?? 'N/A';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF1AB999),
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
                      title: Text(
                        '$nom $prenom',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF003D82),
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.fingerprint, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'UUID: ${form.uuid}',
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
              ),
            ),
        ],
      ),
    );
  }

  // =====================================================================
  // GRILLE DE STATISTIQUES
  // =====================================================================

  Widget _buildStatsGrid() {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.0,
      ),
      children: [
        _buildStatCard(
          'Total individus',
          _dashboardStats['total_forms'].toString(),
          Icons.people,
          const Color(0xFF1AB999),
        ),
        _buildStatCard(
          "Aujourd'hui",
          _dashboardStats['today_forms'].toString(),
          Icons.today,
          const Color(0xFF003D82),
        ),
        _buildStatCard(
          'Régions',
          _dashboardStats['by_region'].length.toString(),
          Icons.map,
          const Color(0xFF8E99AB),
        ),
        _buildStatCard(
          'Communes',
          _dashboardStats['by_commune'].length.toString(),
          Icons.location_city,
          const Color(0xFF1AB999),
        ),
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

  // =====================================================================
  // PAGE 1 - DASHBOARD (FORMULAIRE SEUL)
  // =====================================================================

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
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
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
          const Text('32%',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // =====================================================================
  // SECTIONS DU FORMULAIRE (IDENTITÉ, PARCELLE, CONTINUE)
  // =====================================================================

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
                const Text('Identité',
                    style: TextStyle(
                        color: Color(0xFF003D82),
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
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
                const Text('Compléments d\'information',
                    style: TextStyle(
                        color: Color(0xFF003D82),
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                FormWidgets.buildTextField('Statut matrimonial', _controllers.statutMatrimonial),
                const SizedBox(height: 20),
                FormWidgets.buildNumberField(
                  'Nombre d\'enfants',
                  _controllers.nombreEnfants,
                  minValue: 0,
                ),
                const SizedBox(height: 20),
                FormWidgets.buildNumberField(
                  'Nombre de personnes à charge',
                  _controllers.nombrePersonnesCharge,
                  minValue: 0,
                ),
                const SizedBox(height: 32),
                FormWidgets.buildTextField('Nom du père', _controllers.nomPere),
                const SizedBox(height: 20),
                FormWidgets.buildTextField('Nom de la mère', _controllers.nomMere),
                const SizedBox(height: 20),
                FormWidgets.buildTextField('Métier', _controllers.metier),
                const SizedBox(height: 20),
                FormWidgets.buildTextField('Activités complémentaires',
                    _controllers.activitesComplementaires),
                const SizedBox(height: 32),
                const Text('Adresse et contact',
                    style: TextStyle(
                        color: Color(0xFF003D82),
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
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
                const Text('Carte d\'identité nationale',
                    style: TextStyle(
                        color: Color(0xFF003D82),
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                FormWidgets.buildTextField('Numéro CIN', _controllers.numeroCIN),
                const SizedBox(height: 20),
                FormWidgets.buildDateField('Date de délivrance', _controllers.dateDelivrance, context),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildImageUploadField(
                        'Photo CIN recto',
                        'cin_recto',
                        _imageManager.cinRectoImagePath,
                        _imageManager.cinRectoImageFile,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildImageUploadField(
                        'Photo CIN verso',
                        'cin_verso',
                        _imageManager.cinVersoImagePath,
                        _imageManager.cinVersoImageFile,
                      ),
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
                const Text('Terrain',
                    style: TextStyle(
                        color: Color(0xFF003D82),
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                FormWidgets.buildDecimalField(
                  'Latitude (x,y°)',
                  _controllers.latitude,
                  hintText: 'Ex: -18.8792',
                ),
                const SizedBox(height: 20),
                FormWidgets.buildDecimalField(
                  'Longitude (x,y°)',
                  _controllers.longitude,
                  hintText: 'Ex: 47.5079',
                ),
                const SizedBox(height: 20),
                FormWidgets.buildNumberField('Altitude (m)', _controllers.altitude),
                const SizedBox(height: 20),
                FormWidgets.buildNumberField('Précision (m)', _controllers.precision),
                const SizedBox(height: 32),
                const Text('Type de contrat',
                    style: TextStyle(
                        color: Color(0xFF003D82),
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FormWidgets.buildRadioButton(
                        'Propriétaire',
                        _typeContrat,
                            (value) => setState(() => _typeContrat = value!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FormWidgets.buildRadioButton(
                        'Locataire',
                        _typeContrat,
                            (value) => setState(() => _typeContrat = value!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FormWidgets.buildRadioButton(
                        'Co-gestion',
                        _typeContrat,
                            (value) => setState(() => _typeContrat = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildImageUploadField(
                  'Photo parcelle',
                  'parcelle',
                  _imageManager.parcelleImagePath,
                  _imageManager.parcelleImageFile,
                ),
                const SizedBox(height: 24),
                _buildImageUploadField(
                  'Photo d\'identité',
                  'portrait',
                  _imageManager.portraitImagePath,
                  _imageManager.portraitImageFile,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadField(
      String label,
      String imageType,
      String? imagePath,
      File? imageFile,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
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
                child: Image.file(
                  imageFile,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.red,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 12, color: Colors.white),
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
                Text(
                  'Ajouter une photo',
                  style: TextStyle(color: Colors.grey[500]),
                ),
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
                const Text('Liste des continues',
                    style: TextStyle(
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.w600,
                        fontSize: 16)),
                const SizedBox(height: 16),
                FormWidgets.buildContinueItem(
                  3,
                  'Riziculture',
                  'Techniques de culture du riz',
                  false,
                  onTap: () => _navigateToContinue('Riziculture', 3),
                ),
                const Divider(height: 1, color: Color(0xFFE0E0E0)),
                FormWidgets.buildContinueItem(
                  4,
                  'Élevage',
                  'Pratiques d\'élevage',
                  false,
                  onTap: () => _navigateToContinue('Élevage', 4),
                ),
                const Divider(height: 1, color: Color(0xFFE0E0E0)),
                FormWidgets.buildContinueItem(
                  5,
                  'Pêche',
                  'Techniques de pêche',
                  false,
                  onTap: () => _navigateToContinue('Pêche', 5),
                ),
                const Divider(height: 1, color: Color(0xFFE0E0E0)),
                FormWidgets.buildContinueItem(
                  6,
                  'Agriculture vivrière',
                  'Cultures alimentaires',
                  true,
                ),
                const Divider(height: 1, color: Color(0xFFE0E0E0)),
                FormWidgets.buildContinueItem(
                  7,
                  'Commerce',
                  'Activités commerciales',
                  false,
                  onTap: () => _navigateToContinue('Commerce', 7),
                ),
                const Divider(height: 1, color: Color(0xFFE0E0E0)),
                FormWidgets.buildContinueItem(
                  8,
                  'Artisanat',
                  'Métiers artisanaux',
                  true,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Color(0xFF8E99AB), size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Voir historique de modification',
                        style: TextStyle(
                          color: Color(0xFF333333),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _resetForm,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        side: const BorderSide(color: Color(0xFF8E99AB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(
                          color: Color(0xFF8E99AB),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _saveFormDataLocally,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1AB999),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Enregistrer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
  // PAGES SYNCHRONISATION ET HISTORIQUE
  // =====================================================================

  Widget _buildSynchronizationContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gestion des données',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003D82),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Stockage local en fichiers JSON',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          SizedBox(height: 24),
          _buildDataActionsCard(),
          SizedBox(height: 24),
          _buildDataStatsCard(),
        ],
      ),
    );
  }

  Widget _buildDataActionsCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003D82),
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _exportAllData,
            icon: Icon(Icons.download),
            label: Text('Exporter tous les formulaires'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1AB999),
              minimumSize: Size(double.infinity, 50),
            ),
          ),
          SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              try {
                final result = await _autoSyncService.syncAllFromLocalToMaster();
                if (result['success'] == true) {
                  _showDialog(
                    'Synchronisation réussie',
                    'Total: ${result['total']}\n'
                        'Insérés: ${result['inserted']}\n'
                        'Mis à jour: ${result['updated']}\n'
                        'Ignorés: ${result['skipped']}\n'
                        'Erreurs: ${result['errors']}',
                  );
                } else {
                  _showSnackBar('Erreur: ${result['error']}', Colors.red);
                }
              } catch (e) {
                _showSnackBar('Erreur: $e', Colors.red);
              }
            },
            icon: Icon(Icons.sync),
            label: Text('Synchroniser vers master'),
            style: OutlinedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
            ),
          ),
          SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loadAllForms,
            icon: Icon(Icons.refresh),
            label: Text('Actualiser la liste'),
            style: OutlinedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataStatsCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Statistiques',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003D82),
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _loadAllForms,
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildStatItem('Total formulaires', _allForms.length.toString()),
          _buildStatItem('Dernier formulaire', _getLastFormDate()),
          _buildStatItem('Stockage', 'Fichiers JSON'),
          _buildStatItem('Statut', '✅ Opérationnel'),
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
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Color(0xFF003D82),
              fontWeight: FontWeight.bold,
            ),
          ),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            'Page Historiques',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003D82),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Fonctionnalité à venir',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(20),
            margin: EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.info_outline, size: 48, color: Color(0xFF1AB999)),
                SizedBox(height: 16),
                Text(
                  'Cette section contiendra :',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003D82),
                  ),
                ),
                SizedBox(height: 12),
                _buildHistoryFeature('Historique des modifications'),
                _buildHistoryFeature('Logs des sauvegardes'),
                _buildHistoryFeature('Activités des utilisateurs'),
                _buildHistoryFeature('Versions des formulaires'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryFeature(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF1AB999)),
          SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}