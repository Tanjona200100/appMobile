import 'package:flutter/material.dart';
import 'dashboard_screen.dart'; // Importation de la page de destination après connexion

// Définition du widget principal pour l'écran de connexion
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// Classe d'état du LoginScreen
class _LoginScreenState extends State<LoginScreen> {
  // Contrôleurs pour récupérer le texte saisi dans les champs email et mot de passe
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Booléen pour masquer/afficher le mot de passe
  bool _obscurePassword = true;

  // Booléen pour afficher le loader pendant la connexion
  bool _isLoading = false;

  // Fonction principale pour gérer la tentative de connexion
  void _handleLogin() async {
    // Vérifie si les champs sont remplis
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog('Veuillez remplir tous les champs');
      return;
    }

    // Vérifie le format de l'email (simple vérification)
    if (!_emailController.text.contains('@')) {
      _showErrorDialog('Veuillez entrer une adresse email valide');
      return;
    }

    // Active l’indicateur de chargement
    setState(() {
      _isLoading = true;
    });

    // Simulation d’un appel à une API (attente de 2 secondes)
    await Future.delayed(const Duration(seconds: 2));

    // Désactive le loader
    setState(() {
      _isLoading = false;
    });

    // Vérifie les identifiants (simple condition de démo)
    if (_emailController.text.isNotEmpty && _passwordController.text.length >= 3) {
      // Si tout est correct → redirige vers le Dashboard
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => SideMenu(), // Redirection vers la page principale
        ),
      );
    } else {
      // Sinon, afficher un message d’erreur
      _showErrorDialog('Identifiants incorrects. Le mot de passe doit contenir au moins 3 caractères.');
    }
  }

  // Fonction pour afficher une boîte de dialogue d’erreur
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur de connexion'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Fermer la boîte de dialogue
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Libération des ressources quand l’écran est fermé
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Construction de l’interface graphique
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Couleur de fond blanche
      body: Center(
        child: SingleChildScrollView( // Permet le défilement si le clavier couvre l’écran
          child: Container(
            width: 800, // Largeur fixe pour les écrans larges
            height: 800,
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2), // Espace en haut

                // Affichage du logo
                _buildLogoWidget(),

                const SizedBox(height: 50),

                // Titre principal
                const Text(
                  'Bienvenue sur la plateforme',
                  style: TextStyle(
                    color: Color(0xFF003399),
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'de collecte sur terrain',
                  style: TextStyle(
                    color: Color(0xFF003399),
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // Sous-titre
                const Text(
                  'Connectez-vous pour commencer votre enquête',
                  style: TextStyle(
                    color: Color(0xFF394560),
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 60),

                // Champ email
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Adresse email de l\'agent',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController, // Lien avec le contrôleur email
                      keyboardType: TextInputType.emailAddress, // Type de clavier
                      decoration: InputDecoration(
                        hintText: 'exemple@email.com',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF1B4B8C),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Champ mot de passe
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ligne avec texte et lien "mot de passe oublié"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Mot de passe',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                            _showErrorDialog('Fonctionnalité en cours de développement');
                          },
                          child: const Text(
                            'Mot de passe oublié ?',
                            style: TextStyle(
                              color: Color(0xFF003399),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword, // Masque le texte
                      enabled: !_isLoading, // Désactive pendant chargement
                      decoration: InputDecoration(
                        hintText: 'Entrez votre mot de passe',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF1B4B8C),
                            width: 2,
                          ),
                        ),
                        // Icône pour afficher/masquer le mot de passe
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey[600],
                          ),
                          onPressed: _isLoading
                              ? null
                              : () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 50),

                // Bouton de connexion
                SizedBox(
                  width: 115,
                  height: 44,
                  child: _isLoading
                      ? const Center(
                    // Affiche le loader pendant le traitement
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B4B8C)),
                      strokeWidth: 3,
                    ),
                  )
                      : ElevatedButton(
                    onPressed: _handleLogin, // Appelle la fonction de connexion
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4B8C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text(
                      'Se connecter',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                const Spacer(flex: 3), // Espace en bas de l’écran
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget pour afficher le logo avec gestion d’erreur si l’image est introuvable
  Widget _buildLogoWidget() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(700), // Rend le logo rond
      child: Image.asset(
        'assets/image/logo.png',
        width: 117,
        height: 115,
        fit: BoxFit.cover,
        // Si le logo n'est pas trouvé, affiche une icône de remplacement
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 117,
            height: 115,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(700),
            ),
            child: const Icon(
              Icons.person,
              size: 50,
              color: Colors.grey,
            ),
          );
        },
      ),
    );
  }
}
