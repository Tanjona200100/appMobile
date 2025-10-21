import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'questionnaire_screen.dart'; // Import du nouvel écran de questionnaire

/// ------------------------------
/// Classe principale du menu latéral
/// ------------------------------
///
/// Ce widget représente tout le menu latéral (side menu) de l'application.
/// Il contient un panneau de navigation (rétractable ou étendu)
/// et une zone principale qui affiche le contenu correspondant à la page sélectionnée.
///
class SideMenu extends StatefulWidget {
  const SideMenu({Key? key}) : super(key: key);

  @override
  State<SideMenu> createState() => _SideMenuState();
}

/// -----------------------------------------------------------
/// Classe d'état (_SideMenuState)
/// -----------------------------------------------------------
///
/// Cette classe gère :
/// - L'état actuel du menu (ouvert ou réduit)
/// - L'index de la page actuellement sélectionnée
/// - L'affichage du contenu correspondant à la page choisie
///
class _SideMenuState extends State<SideMenu> {
  // Index du menu sélectionné (0 = Dashboard, 1 = Liste, etc.)
  int _selectedIndex = 0;

  // Booléen indiquant si le menu est réduit (true) ou étendu (false)
  bool _isMenuCollapsed = false;

  /// -----------------------------------------------------------
  /// Méthode _buildMenuTile :
  /// -----------------------------------------------------------
  /// Construit chaque élément du menu (icône + texte ou juste icône).
  /// - Si le menu est réduit : affiche uniquement une icône circulaire.
  /// - Si le menu est étendu : affiche une ligne complète avec icône et texte.
  ///
  Widget _buildMenuTile(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;

    // ---- Version réduite (icônes seules) ----
    if (_isMenuCollapsed) {
      return InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        child: Container(
          width: 50,
          height: 50,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1AB999) : const Color(0xFF8E99AB),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      );
    }

    // ---- Version étendue (icône + texte + flèche) ----
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
          color: isSelected ? const Color(0xFF1AB999) : const Color(0xFF8E99AB),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  /// -----------------------------------------------------------
  /// Méthode _toggleMenu :
  /// -----------------------------------------------------------
  /// Bascule l'état du menu (ouvert ↔ fermé) en inversant la valeur de [_isMenuCollapsed].
  ///
  void _toggleMenu() {
    setState(() {
      _isMenuCollapsed = !_isMenuCollapsed;
    });
  }

  /// -----------------------------------------------------------
  /// Méthode _navigateToQuestionnaire :
  /// -----------------------------------------------------------
  /// Navigue vers l'écran de questionnaire
  ///
  void _navigateToQuestionnaire(String title, int questionnaireNumber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionnaireScreen(
          title: title,
          questionnaireNumber: questionnaireNumber,
        ),
      ),
    );
  }

  /// -----------------------------------------------------------
  /// Méthode build :
  /// -----------------------------------------------------------
  /// Construit la structure générale de la page :
  /// - Le contenu principal (dashboard ou autres pages)
  /// - Le menu latéral (avec animation d'ouverture/fermeture)
  ///
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // -----------------------
          // Zone principale (contenu)
          // -----------------------
          // On ajuste la position et la largeur du contenu selon
          // l'état du menu (réduit ou étendu) et la page sélectionnée.
          if (_selectedIndex == 0 && _isMenuCollapsed)
          // Dashboard avec menu réduit : contenu décalé
            Positioned(
              left: 98,
              top: 0,
              bottom: 0,
              right: 0,
              child: Container(
                color: const Color(0xFFF5F7FA),
                child: Center(
                  child: Container(width: 702, child: _buildContent()),
                ),
              ),
            )
          else if (_selectedIndex == 0 && !_isMenuCollapsed)
          // Dashboard avec menu étendu : contenu centré
            Positioned.fill(
              child: Container(
                color: const Color(0xFFF5F7FA),
                child: Center(
                  child: Container(width: 700, child: _buildContent()),
                ),
              ),
            )
          else
          // Autres pages : affichage normal
            Positioned.fill(
              left: _isMenuCollapsed ? 98 : 700,
              child: Container(color: const Color(0xFFF5F7FA), child: _buildContent()),
            ),

          // -----------------------
          // Menu latéral
          // -----------------------
          Positioned(
            left: 0,
            top: 28.5,
            bottom: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isMenuCollapsed ? 98 : 300,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFB8C5D6),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(4, 0))],
                ),
                child: Column(
                  children: [
                    // ------------------------------------------------
                    // En-tête du menu (logo + flèche de repli)
                    // ------------------------------------------------
                    Container(
                      height: 82,
                      width: double.infinity,
                      child: InkWell(
                        onTap: _toggleMenu,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(color: Color(0xFF8E99AB)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Logo (affiché dans les deux états)
                              Container(
                                width: 58,
                                height: 58,
                                decoration: const BoxDecoration(shape: BoxShape.circle),
                                child: ClipOval(
                                  child: Image.asset('assets/image/logo.png', fit: BoxFit.cover),
                                ),
                              ),

                              // Icône flèche (visible uniquement quand le menu est étendu)
                              if (!_isMenuCollapsed)
                                const Icon(Icons.keyboard_double_arrow_left, color: Colors.white, size: 24),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ------------------------------------------------
                    // Liste des éléments du menu (Dashboard, Liste, etc.)
                    // ------------------------------------------------
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

                    // ------------------------------------------------
                    // Section Profil + Déconnexion (affichage complet)
                    // ------------------------------------------------
                    if (!_isMenuCollapsed)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          children: [
                            // Carte de profil
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
                                    child: const Icon(Icons.person, color: Colors.white, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Nom de l'agent",
                                            style: TextStyle(
                                                color: Color(0xFF333333),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600)),
                                        Text('Profil paramètres',
                                            style: TextStyle(
                                              color: Color(0xFF8E99AB),
                                              fontSize: 11,
                                            )),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.settings,
                                        color: Color(0xFF8E99AB), size: 20),
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Bouton déconnexion
                            InkWell(
                              onTap: () {
                                // TODO: Ajout de la logique de déconnexion
                              },
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8E99AB),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.logout,
                                        color: Colors.white, size: 24),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Se déconnecter',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    Icon(Icons.chevron_right,
                                        color: Colors.white, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ------------------------------------------------
                    // Version réduite (profil + logout sous forme d'icônes)
                    // ------------------------------------------------
                    if (_isMenuCollapsed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                  color: const Color(0xFF8E99AB),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.person,
                                  color: Colors.white, size: 28),
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () {
                                // TODO: Ajout logique de déconnexion
                              },
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8E99AB),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.logout,
                                    color: Colors.white, size: 28),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// -----------------------------------------------------------
  /// Méthode _buildContent :
  /// -----------------------------------------------------------
  /// Retourne le widget correspondant à la page sélectionnée selon [_selectedIndex].
  ///
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

  /// -----------------------------------------------------------
  /// Méthode _buildDashboardContent :
  /// -----------------------------------------------------------
  /// Construit le contenu principal du tableau de bord (Dashboard),
  /// avec une en-tête (date, progression) et un formulaire "IDENTITÉ".
  ///
  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(29.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ----- En-tête avec date et progression -----
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF8E99AB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Text('Date de l\'enquête: 24/07/2024',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
                const Spacer(),
                const Text('Progression', style: TextStyle(color: Colors.white)),
                const SizedBox(width: 12),
                // Barre de progression
                Expanded(
                  flex: 2,
                  child: Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4)),
                      ),
                      FractionallySizedBox(
                        widthFactor: 0.32, // 32%
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                              color: const Color(0xFF1AB999),
                              borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Text('32%',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ----- Formulaire d'identité -----
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre de section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1AB999),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12)),
                  ),
                  child: const Text('IDENTITÉ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2)),
                ),

                // Champs du formulaire
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

                      // Section complémentaire
                      const Text('Compléments d\'information',
                          style: TextStyle(
                              color: Color(0xFF003D82),
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),

                      _buildTextField('Statut matrimonial'),
                      const SizedBox(height: 20),
                      _buildTextField('Nombre d\'enfants'),
                      const SizedBox(height: 20),
                      _buildTextField('Nombre de personnes à charge'),

                      const SizedBox(height: 32),

                      _buildTextField('Nom du père'),
                      const SizedBox(height: 20),
                      _buildTextField('Nom de la mère'),
                      const SizedBox(height: 20),
                      _buildTextField('Métier'),
                      const SizedBox(height: 20),
                      _buildTextField('Activités complémentaires'),

                      const SizedBox(height: 32),

                      // Section Adresse et contact
                      const Text('Adresse et contact',
                          style: TextStyle(
                              color: Color(0xFF003D82),
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),

                      _buildTextField('Adresse'),
                      const SizedBox(height: 20),
                      _buildTextField('Région'),
                      const SizedBox(height: 20),
                      _buildTextField('Commune'),
                      const SizedBox(height: 20),
                      _buildTextField('Fokontany'),
                      const SizedBox(height: 20),
                      _buildTextField('Numéro téléphone 1'),
                      const SizedBox(height: 20),
                      _buildTextField('Numéro téléphone 2'),

                      const SizedBox(height: 32),

                      // Section Carte d'identité nationale
                      const Text('Carte d\'identité nationale',
                          style: TextStyle(
                              color: Color(0xFF003D82),
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),

                      _buildTextField('Numéro CIN'),
                      const SizedBox(height: 20),
                      _buildDateField('Date de délivrance'),
                      const SizedBox(height: 24),

                      // Section upload de photos
                      Row(
                        children: [
                          // Photo CIN recto
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Photo CIN recto',
                                    style: TextStyle(
                                        color: Color(0xFF333333),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14)),
                                const SizedBox(height: 8),
                                Container(
                                  height: 150,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F3F1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: const Color(0xFFD0D5DD)),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.cloud_upload_outlined,
                                            color: Color(0xFF1AB999),
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text('uploader une photo',
                                            style: TextStyle(
                                                color: Color(0xFF8E99AB),
                                                fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Photo CIN verso
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Photo CIN verso',
                                    style: TextStyle(
                                        color: Color(0xFF333333),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14)),
                                const SizedBox(height: 8),
                                Container(
                                  height: 150,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F3F1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: const Color(0xFFD0D5DD)),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.cloud_upload_outlined,
                                            color: Color(0xFF1AB999),
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text('uploader une photo',
                                            style: TextStyle(
                                                color: Color(0xFF8E99AB),
                                                fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Bouton PARCELLE
                      SizedBox(
                        width: double.infinity,

                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ----- Section Terrain -----
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre de section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1AB999),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12)),
                  ),
                  child: const Text('PARCELLE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2)),
                ),

                // Champs du formulaire
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sous-titre Terrain
                      const Text('Terrain',
                          style: TextStyle(
                              color: Color(0xFF003D82),
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),

                      _buildTextField('Latitude (x,y°)'),
                      const SizedBox(height: 20),
                      _buildTextField('Longitude (x,y°)'),
                      const SizedBox(height: 20),
                      _buildTextField('Altitude (m)'),
                      const SizedBox(height: 20),
                      _buildTextField('Précision (m)'),
                      const SizedBox(height: 32),

                      // Section Type de contrat DÉPLACÉE ICI
                      const Text('Type de contrat',
                          style: TextStyle(
                              color: Color(0xFF003D82),
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildRadioButton('Propriétaire', false),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildRadioButton('Locataire', false),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildRadioButton('Co-gestion', true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Photo parcelle
                      const Text('Photo parcelle',
                          style: TextStyle(
                              color: Color(0xFF333333),
                              fontWeight: FontWeight.w500,
                              fontSize: 14)),
                      const SizedBox(height: 12),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFD0D5DD)),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/image/parcelle.jpg',
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: const Color(0xFFE8F3F1),
                                    child: const Center(
                                      child: Icon(Icons.image,
                                          color: Color(0xFF8E99AB), size: 40),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: InkWell(
                                onTap: () {
                                  // TODO: Supprimer l'image
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.red, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('pictures2345.jpg',
                          style: TextStyle(color: Color(0xFF8E99AB), fontSize: 12)),
                      const Text('50kbs',
                          style: TextStyle(color: Color(0xFF8E99AB), fontSize: 11)),

                      const SizedBox(height: 32),

                      // Photo d'indentité
                      const Text('Photo d\'indentité',
                          style: TextStyle(
                              color: Color(0xFF333333),
                              fontWeight: FontWeight.w500,
                              fontSize: 14)),
                      const SizedBox(height: 12),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFD0D5DD)),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/image/portrait.jpg',
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: const Color(0xFFE8F3F1),
                                    child: const Center(
                                      child: Icon(Icons.person,
                                          color: Color(0xFF8E99AB), size: 40),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: InkWell(
                                onTap: () {
                                  // TODO: Supprimer l'image
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.red, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('pictures2345.jpg',
                          style: TextStyle(color: Color(0xFF8E99AB), fontSize: 12)),
                      const Text('50kbs',
                          style: TextStyle(color: Color(0xFF8E99AB), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ----- Section QUESTIONNAIRE -----
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre de section QUESTIONNAIRE
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1AB999),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12)),
                  ),
                  child: const Text('QUESTIONNAIRE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2)),
                ),

                // Contenu de la section questionnaire
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Liste questionnaire',
                          style: TextStyle(
                              color: Color(0xFF333333),
                              fontWeight: FontWeight.w600,
                              fontSize: 16)),
                      const SizedBox(height: 16),

                      // Liste des items de questionnaire - REMPLACÉE PAR LES NOUVEAUX ITEMS
                      _buildQuestionnaireItem(
                        3,
                        'Riziculture',
                        'Techniques de culture du riz',
                        false,
                        onTap: () => _navigateToQuestionnaire('Riziculture', 3),
                      ),
                      const Divider(height: 1, color: Color(0xFFE0E0E0)),

                      _buildQuestionnaireItem(
                        4,
                        'Élevage',
                        'Pratiques d\'élevage',
                        false,
                        onTap: () => _navigateToQuestionnaire('Élevage', 4),
                      ),
                      const Divider(height: 1, color: Color(0xFFE0E0E0)),

                      _buildQuestionnaireItem(
                        5,
                        'Pêche',
                        'Techniques de pêche',
                        false,
                        onTap: () => _navigateToQuestionnaire('Pêche', 5),
                      ),
                      const Divider(height: 1, color: Color(0xFFE0E0E0)),

                      _buildQuestionnaireItem(
                        6,
                        'Agriculture vivrière',
                        'Cultures alimentaires',
                        true,
                      ),
                      const Divider(height: 1, color: Color(0xFFE0E0E0)),

                      _buildQuestionnaireItem(
                        7,
                        'Commerce',
                        'Activités commerciales',
                        false,
                        onTap: () => _navigateToQuestionnaire('Commerce', 7),
                      ),
                      const Divider(height: 1, color: Color(0xFFE0E0E0)),

                      _buildQuestionnaireItem(
                        8,
                        'Artisanat',
                        'Métiers artisanaux',
                        true,
                      ),

                      const SizedBox(height: 32),

                      // Message historique et boutons
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              color: Color(0xFF8E99AB), size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Voir historique de modification',
                              style: TextStyle(
                                  color: Color(0xFF333333),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              // TODO: Logique d'annulation
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
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
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              // TODO: Logique d'enregistrement
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1AB999),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Enregistrer',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500),
                            ),
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

  /// -----------------------------------------------------------
  /// Méthode _buildTextField :
  /// -----------------------------------------------------------
  /// Construit un champ de texte avec label et style.
  /// Utilisée dans le formulaire "IDENTITÉ".
  ///
  Widget _buildTextField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFF333333),
                fontWeight: FontWeight.w500,
                fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF8E99AB))),
            focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF1AB999), width: 1.5)),
          ),
        ),
      ],
    );
  }

  /// -----------------------------------------------------------
  /// Méthode _buildDateField :
  /// -----------------------------------------------------------
  /// Construit un champ de date avec un sélecteur de date
  ///
  Widget _buildDateField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFF333333),
                fontWeight: FontWeight.w500,
                fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF8E99AB)),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF8E99AB))),
            focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF1AB999), width: 1.5)),
          ),
        ),
      ],
    );
  }

  /// -----------------------------------------------------------
  /// Méthode _buildRadioButton :
  /// -----------------------------------------------------------
  /// Construit un bouton radio avec label
  ///
  Widget _buildRadioButton(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1AB999) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? const Color(0xFF1AB999) : const Color(0xFFD0D5DD),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : const Color(0xFFD0D5DD),
                width: 2,
              ),
            ),
            child: isSelected
                ? Container(
              margin: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            )
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF333333),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// -----------------------------------------------------------
  /// Méthode _buildQuestionnaireItem :
  /// -----------------------------------------------------------
  /// Construit un item de la liste de questionnaire - VERSION MODIFIÉE
  ///
  Widget _buildQuestionnaireItem(int number, String title, String description, bool isLocked, {VoidCallback? onTap}) {
    return InkWell(
      onTap: isLocked ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isLocked ? const Color(0xFF8E99AB) : const Color(0xFF1AB999),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isLocked
                    ? const Icon(Icons.lock, color: Colors.white, size: 16)
                    : Text(
                  number.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF333333),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF8E99AB),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (!isLocked)
              const Icon(Icons.chevron_right, color: Color(0xFF8E99AB)),
          ],
        ),
      ),
    );
  }

  /// -----------------------------------------------------------
  /// Méthodes placeholders :
  /// -----------------------------------------------------------
  /// Pour les pages secondaires (à compléter plus tard)
  ///
  Widget _buildSurveysContent() => const Center(child: Text('Page Liste des individus'));
  Widget _buildParticipantsContent() => const Center(child: Text('Page Synchronisation'));
  Widget _buildReportsContent() => const Center(child: Text('Page Historiques'));
}