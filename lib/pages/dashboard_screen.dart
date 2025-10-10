import 'package:flutter/material.dart';
import 'login_screen.dart';

class SideMenu extends StatefulWidget {
  const SideMenu({Key? key}) : super(key: key);

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  int _selectedIndex = 0;
  bool _isMenuCollapsed = false;

  // Méthode pour construire les éléments du menu
  Widget _buildMenuTile(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;

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

  void _toggleMenu() {
    setState(() {
      _isMenuCollapsed = !_isMenuCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Side Menu
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isMenuCollapsed ? 98 : 300,
            height: 800,
            decoration: const BoxDecoration(
              color: Color(0xFFB8C5D6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header avec logo et chevron
                Container(
                  height: 82,
                  width: _isMenuCollapsed ? 98 : 300,
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
                          // Logo
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

                          // Chevron
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

                // Menu Items
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

                // Section profil et déconnexion
                if (!_isMenuCollapsed)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      children: [
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

                        // Déconnexion
                        InkWell(
                          onTap: () {},
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
                          onTap: () {},
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

          // Main Content
          Expanded(
            child: Container(
              color: Colors.grey[50],
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

  Widget _buildDashboardContent() {
    return Container(
      color: const Color(0xFFF5F7FA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
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

                        // Compléments d'information
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
                            OutlinedButton.icon(
                              onPressed: () {},
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
                            Row(
                              children: [
                                OutlinedButton(
                                  onPressed: () {},
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
                                  onPressed: () {},
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
      ),
    );
  }

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

  Widget _buildSurveysContent() {
    return const Center(
      child: Text(
        'Liste des individus',
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  Widget _buildParticipantsContent() {
    return const Center(
      child: Text(
        'Synchronisation',
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  Widget _buildReportsContent() {
    return const Center(
      child: Text(
        'Historiques',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}