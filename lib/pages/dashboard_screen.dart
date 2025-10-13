import 'package:flutter/material.dart';
import 'login_screen.dart';

/// Classe principale représentant le menu latéral et le dashboard
/// C'est un StatefulWidget car l'état du menu (ouvert/fermé) change
class SideMenu extends StatefulWidget {
  const SideMenu({Key? key}) : super(key: key);

  @override
  State<SideMenu> createState() => _SideMenuState();
}

/// Classe d'état pour gérer l'état du menu latéral et du dashboard
/// Gère la sélection des onglets et l'état d'ouverture/fermeture du menu
class _SideMenuState extends State<SideMenu> {
  /// Index de l'onglet actuellement sélectionné dans le menu
  /// 0: Dashboard, 1: Liste des individus, 2: Synchronisation, 3: Historiques
  int _selectedIndex = 0;

  /// État de collapse du menu (true: menu réduit, false: menu étendu)
  bool _isMenuCollapsed = false;

  /// Méthode pour construire les éléments du menu
  /// [icon] : Icône de l'élément du menu
  /// [title] : Texte de l'élément du menu
  /// [index] : Index de l'élément pour la gestion de la sélection
  /// Retourne un Widget représentant un élément de menu
  Widget _buildMenuTile(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;

    // Version réduite du menu (icônes seulement)
    if (_isMenuCollapsed) {
      return InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        child: Container(
          width: 60,
          height: 60,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1AB999) : const Color(0xFF8E99AB),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
        ),
      );
    }

    // Version étendue du menu (icône + texte)
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1AB999)
              : const Color(0xFF8E99AB),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// Méthode pour basculer l'état d'ouverture/fermeture du menu
  void _toggleMenu() {
    setState(() {
      _isMenuCollapsed = !_isMenuCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Dashboard - Largeur fixe de 700px et centré
          // Z-index plus bas que le menu
          Positioned.fill(
            child: Container(
              color: const Color(0xFFF5F7FA),
              child: Center(
                child: Container(
                  width: 700, // Largeur fixe de 700px
                  child: _buildContent(),
                ),
              ),
            ),
          ),

          // Menu - Largeur limitée pour ne pas cacher tout le dashboard
          // Z-index plus élevé que le dashboard (se superpose)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isMenuCollapsed ? 98 : 300,
              decoration: const BoxDecoration(
                color: Color(0xFFB8C5D6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(4, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header avec logo et chevron
                  Container(
                    height: 82,
                    width: double.infinity,
                    child: InkWell(
                      onTap: _toggleMenu,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: const BoxDecoration(
                          color: Color(0xFF8E99AB),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Logo - affiché différemment selon l'état du menu
                            if (!_isMenuCollapsed)
                              Row(
                                children: [
                                  Container(
                                    width: 58,
                                    height: 58,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/image/logo.png',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                            if (_isMenuCollapsed)
                              Container(
                                width: 58,
                                height: 58,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/image/logo.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),

                            // Chevron - seulement visible quand le menu est étendu
                            if (!_isMenuCollapsed)
                              const Icon(
                                Icons.keyboard_double_arrow_left,
                                color: Colors.white,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Section des éléments du menu
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          _buildMenuTile(Icons.dashboard, 'Dashboard', 0),
                          const SizedBox(height: 8),
                          _buildMenuTile(Icons.people, 'Liste des individus', 1),
                          const SizedBox(height: 8),
                          _buildMenuTile(Icons.sync, 'Synchronisation', 2),
                          const SizedBox(height: 8),
                          _buildMenuTile(Icons.history, 'Historiques', 3),
                        ],
                      ),
                    ),
                  ),

                  // Section profil et déconnexion - seulement visible quand le menu est étendu
                  if (!_isMenuCollapsed)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        children: [
                          // Carte de profil de l'agent
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4DCE6),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8E99AB),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Nom de l'agent",
                                        style: TextStyle(
                                          color: Color(0xFF333333),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'Profil paramètres',
                                        style: TextStyle(
                                          color: Color(0xFF8E99AB),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.settings,
                                    color: Color(0xFF8E99AB),
                                    size: 20,
                                  ),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Bouton de déconnexion
                          InkWell(
                            onTap: () {
                              // TODO: Implémenter la logique de déconnexion
                            },
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8E99AB),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons.logout,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Se déconnecter',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Version réduite du profil et déconnexion - seulement icônes
                  if (_isMenuCollapsed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        children: [
                          // Icône profil réduite
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFF8E99AB),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Icône déconnexion réduite
                          InkWell(
                            onTap: () {
                              // TODO: Implémenter la logique de déconnexion
                            },
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFF8E99AB),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.logout,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Méthode pour construire le contenu principal en fonction de l'onglet sélectionné
  /// Retourne le Widget correspondant à l'onglet actif
  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return _buildSurveysContent();
      case 2:
        return _buildParticipantsContent();
      case 3:
        return _buildReportsContent();
      default:
        return _buildDashboardContent();
    }
  }

  /// Construit le contenu du dashboard avec le formulaire d'identité
  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(29.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec date et progression
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF8E99AB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Date de l\'enquête: 24/07/2024',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Progression',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Stack(
                    children: [
                      // Barre de progression de fond
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      // Barre de progression avant
                      FractionallySizedBox(
                        widthFactor: 0.32, // 32% de progression
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
                const Text(
                  '32%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Formulaire IDENTITÉ
          Container(
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
                // En-tête IDENTITÉ
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                // Corps du formulaire
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Identité',
                        style: TextStyle(
                          color: Color(0xFF003D82),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildTextField('Nom'),
                      const SizedBox(height: 20),

                      _buildTextField('Prénom'),
                      const SizedBox(height: 20),

                      _buildTextField('Surnom'),
                      const SizedBox(height: 20),

                      _buildTextField('Sexe'),
                      const SizedBox(height: 20),

                      _buildTextField('Date de naissance'),
                      const SizedBox(height: 20),

                      _buildTextField('Lieu de naissance'),
                      const SizedBox(height: 32),

                      // Section compléments d'information
                      const Text(
                        'Compléments d\'information',
                        style: TextStyle(
                          color: Color(0xFF003D82),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildTextField('Statut matrimonial'),
                      const SizedBox(height: 20),

                      _buildTextField('Nombre d\'enfants'),
                      const SizedBox(height: 20),

                      _buildTextField('Nombre de personnes à charge'),
                      const SizedBox(height: 32),

                      // Boutons d'action
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Bouton historique
                          OutlinedButton.icon(
                            onPressed: () {
                              // TODO: Implémenter la vue historique
                            },
                            icon: const Icon(
                              Icons.history,
                              color: Color(0xFF8E99AB),
                              size: 20,
                            ),
                            label: const Text(
                              'Voir historique de modification',
                              style: TextStyle(
                                color: Color(0xFF8E99AB),
                                fontSize: 14,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              side: const BorderSide(
                                color: Color(0xFF8E99AB),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          // Boutons Annuler et Enregistrer
                          Row(
                            children: [
                              OutlinedButton(
                                onPressed: () {
                                  // TODO: Implémenter l'annulation
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 14,
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFF1AB999),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Annuler',
                                  style: TextStyle(
                                    color: Color(0xFF1AB999),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () {
                                  // TODO: Implémenter l'enregistrement
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1AB999),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Enregistrer',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Méthode utilitaire pour construire un champ de texte du formulaire
  /// [label] : Libellé du champ de texte
  /// Retourne un Widget représentant un champ de texte avec son libellé
  Widget _buildTextField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF333333),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF1AB999),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  /// Construit le contenu de la page "Liste des individus"
  Widget _buildSurveysContent() {
    return const Center(
      child: Text(
        'Liste des individus',
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  /// Construit le contenu de la page "Synchronisation"
  Widget _buildParticipantsContent() {
    return const Center(
      child: Text(
        'Synchronisation',
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  /// Construit le contenu de la page "Historiques"
  Widget _buildReportsContent() {
    return const Center(
      child: Text(
        'Historiques',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}