import 'package:flutter/material.dart';
import 'dashboard_screen.dart'; // Assurez-vous que c'est le bon import

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  void _handleLogin() async {
    // Validation des champs
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog('Veuillez remplir tous les champs');
      return;
    }

    // Vérification du format email simple
    if (!_emailController.text.contains('@')) {
      _showErrorDialog('Veuillez entrer une adresse email valide');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulation d'appel API (2 secondes)
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    // Ici, normalement vous vérifiez avec votre backend
    // Pour l'exemple, on accepte tout email non vide et mot de passe d'au moins 3 caractères
    // Dans la méthode _handleLogin
    if (_emailController.text.isNotEmpty && _passwordController.text.length >= 3) {
      // Navigation vers la page dashboard
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => SideMenu(), // SANS "const"
        ),
      );
    
    } else {
      _showErrorDialog('Identifiants incorrects. Le mot de passe doit contenir au moins 3 caractères.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur de connexion'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 800,
            height: 800,
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Logo avec gestion d'erreur améliorée
                _buildLogoWidget(),

                const SizedBox(height: 50),

                // Titre
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
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
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
                      obscureText: _obscurePassword,
                      enabled: !_isLoading,
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
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B4B8C)),
                      strokeWidth: 3,
                    ),
                  )
                      : ElevatedButton(
                    onPressed: _handleLogin,
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

                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget pour afficher le logo avec gestion d'erreur
  Widget _buildLogoWidget() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(700),
      child: Image.asset(
        'assets/image/logo.png',
        width: 117,
        height: 115,
        fit: BoxFit.cover,
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