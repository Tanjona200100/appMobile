import 'package:flutter/material.dart';

/// Widget du menu latéral
class MenuWidget extends StatelessWidget {
  final int selectedIndex;
  final bool isMenuCollapsed;
  final Function(int) onMenuItemTap;
  final VoidCallback onToggleMenu;
  final VoidCallback onLogout;

  const MenuWidget({
    Key? key,
    required this.selectedIndex,
    required this.isMenuCollapsed,
    required this.onMenuItemTap,
    required this.onToggleMenu,
    required this.onLogout, required int pendingSyncCount, required String userName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isMenuCollapsed ? 98 : 300,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFB8C5D6),
          boxShadow: [
            BoxShadow(
                color: Colors.black26,
                blurRadius: 12,
                offset: Offset(4, 0))
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 30),
            Expanded(
              child: SingleChildScrollView(
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
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 82,
      width: double.infinity,
      child: InkWell(
        onTap: onToggleMenu,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(color: Color(0xFF8E99AB)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: ClipOval(
                  child: Image.asset('assets/image/logo.png', fit: BoxFit.cover),
                ),
              ),
              if (!isMenuCollapsed)
                const Icon(Icons.keyboard_double_arrow_left,
                    color: Colors.white, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, int index) {
    final isSelected = selectedIndex == index;

    if (isMenuCollapsed) {
      return InkWell(
        onTap: () => onMenuItemTap(index),
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

    return InkWell(
      onTap: () => onMenuItemTap(index),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1AB999) : const Color(0xFF8E99AB),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    if (!isMenuCollapsed) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            const SizedBox(height: 12),
            InkWell(
              onTap: onLogout,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF8E99AB),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.logout, color: Colors.white, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Se déconnecter',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          const SizedBox(height: 12),
          InkWell(
            onTap: onLogout,
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFF8E99AB),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}