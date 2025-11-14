import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kartstat/screens/side_menu.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

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
  bool _hasInternet = true;
  bool _isCheckingConnection = false;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkInternetOnStart();
    _startConnectivityListener();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Démarrer l'écouteur de connexion
  void _startConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
          (ConnectivityResult result) async {
        print('Changement de connexion détecté: $result');

        if (result == ConnectivityResult.none) {
          // Devenu hors ligne
          if (_hasInternet) {
            setState(() {
              _hasInternet = false;
            });
            _showOfflinePopup();
          }
        } else {
          // Devenu en ligne - tester l'accès réel à Internet
          final hasRealInternet = await _testInternetAccess();
          if (!_hasInternet && hasRealInternet) {
            setState(() {
              _hasInternet = true;
            });
            _showOnlineNotification();
          } else if (!hasRealInternet) {
            setState(() {
              _hasInternet = false;
            });
          }
        }
      },
    );
  }

  // Vérifie la connexion Internet au démarrage
  Future<void> _checkInternetOnStart() async {
    setState(() => _isCheckingConnection = true);

    try {
      final connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        setState(() {
          _hasInternet = false;
          _isCheckingConnection = false;
        });

        // Affiche le popup après le rendu initial
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showOfflinePopup();
        });
        return;
      }

      final hasInternet = await _testInternetAccess();
      setState(() {
        _hasInternet = hasInternet;
        _isCheckingConnection = false;
      });

      if (!hasInternet) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showOfflinePopup();
        });
      }
    } catch (_) {
      setState(() {
        _hasInternet = false;
        _isCheckingConnection = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showOfflinePopup();
      });
    }
  }

  // Test accès Internet réel
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

  // Affiche popup hors ligne
  void _showOfflinePopup() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Connexion hors ligne"),
        content: const Text(
            "Une connexion internet est requise pour accéder à l'application. Veuillez vous connecter à internet pour vous authentifier."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // Affiche notification quand la connexion revient
  void _showOnlineNotification() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.wifi, color: Colors.white),
            SizedBox(width: 8),
            Text('Connexion internet rétablie'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // Rafraîchir manuellement la connexion
  Future<void> _refreshConnection() async {
    setState(() => _isCheckingConnection = true);

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      bool hasInternet = connectivityResult != ConnectivityResult.none;

      if (hasInternet) {
        hasInternet = await _testInternetAccess();
      }

      setState(() {
        _hasInternet = hasInternet;
        _isCheckingConnection = false;
      });

      if (hasInternet) {
        _showOnlineNotification();
      } else {
        _showOfflinePopup();
      }
    } catch (_) {
      setState(() {
        _hasInternet = false;
        _isCheckingConnection = false;
      });
    }
  }

  // Gestion login - BLOQUÉ si hors ligne
  void _handleLogin() async {
    // Vérifier d'abord si on est hors ligne
    if (!_hasInternet) {
      _showErrorDialog(
        'Connexion requise',
        'Une connexion internet est nécessaire pour vous connecter. Veuillez vérifier votre connexion et réessayer.',
      );
      return;
    }

    // Validation des champs
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog('Champs manquants', 'Veuillez remplir tous les champs');
      return;
    }

    if (!_emailController.text.contains('@')) {
      _showErrorDialog('Email invalide', 'Veuillez entrer une adresse email valide');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Vérifier à nouveau la connexion Internet avant de procéder
      final connectivityResult = await Connectivity().checkConnectivity();
      bool hasInternet = connectivityResult != ConnectivityResult.none;

      if (hasInternet) {
        hasInternet = await _testInternetAccess();
      }

      // Si perte de connexion pendant le processus
      if (!hasInternet) {
        setState(() {
          _hasInternet = false;
          _isLoading = false;
        });
        _showErrorDialog(
          'Connexion perdue',
          'La connexion internet a été perdue. Veuillez vous reconnecter et réessayer.',
        );
        return;
      }

      // SIMULATION D'AUTHENTIFICATION - À REMPLACER PAR VOTRE LOGIQUE RÉELLE
      // Ici vous devriez appeler votre API d'authentification
      await Future.delayed(const Duration(milliseconds: 1000));

      // Redirection vers Dashboard (SideMenu) UNIQUEMENT si en ligne
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SideMenu()),
        );
      }

    } catch (error) {
      // En cas d'erreur réseau ou serveur
      if (mounted) {
        _showErrorDialog(
            'Erreur de connexion',
            'Impossible de se connecter au serveur. Veuillez vérifier votre connexion internet.'
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK")
          )
        ],
      ),
    );
  }

  // Gestion du mot de passe oublié - BLOQUÉ si hors ligne
  void _handleForgotPassword() {
    if (!_hasInternet) {
      _showErrorDialog(
        'Connexion requise',
        'Une connexion internet est nécessaire pour réinitialiser votre mot de passe.',
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Mot de passe oublié"),
        content: const Text(
            "Veuillez contacter votre administrateur pour réinitialiser votre mot de passe."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // UI
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isCheckingConnection
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Vérification de la connexion...',
              style: TextStyle(
                color: Color(0xFF003399),
                fontSize: 16,
              ),
            ),
          ],
        ),
      )
          : Center(
        child: SingleChildScrollView(
          child: Container(
            width: 800,
            height: 800,
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                _buildLogoWidget(),
                const SizedBox(height: 50),
                _buildWelcomeText(),
                const SizedBox(height: 20),
                _buildSubtitleText(),
                const SizedBox(height: 60),
                _buildLoginForm(),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return const Column(
      children: [
        Text(
          'Bienvenue sur la plateforme',
          style: TextStyle(
            color: Color(0xFF003399),
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'de collecte sur terrain',
          style: TextStyle(
            color: Color(0xFF003399),
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitleText() {
    return const Text(
      'Connectez-vous pour commencer votre enquête',
      style: TextStyle(
        color: Color(0xFF394560),
        fontSize: 15,
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        // Email
        _buildEmailField(),
        const SizedBox(height: 30),

        // Mot de passe
        _buildPasswordField(),
        const SizedBox(height: 50),

        // Bouton connexion
        _buildLoginButton(),

        // Indicateur de statut Internet avec bouton rafraîchir
        const SizedBox(height: 20),
     //   _buildInternetStatus(),

        // Message d'avertissement si hors ligne
        if (!_hasInternet) ...[
          const SizedBox(height: 20),
          _buildOfflineWarning(),
        ],
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Adresse email de l\'agent',
          style: TextStyle(color: Colors.black87, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          enabled: !_isLoading && _hasInternet,
          decoration: InputDecoration(
            hintText: 'exemple@email.com',
            hintStyle: TextStyle(color: Colors.grey[400]),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mot de passe',
              style: TextStyle(color: Colors.black87, fontSize: 14),
            ),
            TextButton(
              onPressed: (_isLoading || !_hasInternet) ? null : _handleForgotPassword,
              child: Text(
                'Mot de passe oublié ?',
                style: TextStyle(
                    color: (_isLoading || !_hasInternet)
                        ? Colors.grey
                        : const Color(0xFF003399),
                    fontSize: 12
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          enabled: !_isLoading && _hasInternet,
          decoration: InputDecoration(
            hintText: 'Entrez votre mot de passe',
            hintStyle: TextStyle(color: Colors.grey[400]),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: (!_isLoading && _hasInternet) ? Colors.grey[600] : Colors.grey[400],
              ),
              onPressed: (_isLoading || !_hasInternet)
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
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
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
        onPressed: _hasInternet ? _handleLogin : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _hasInternet
              ? const Color(0xFF1B4B8C)
              : Colors.grey[400],
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
    );
  }

 /* Widget _buildInternetStatus() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _hasInternet ? Icons.wifi : Icons.wifi_off,
              color: _hasInternet ? Colors.green : Colors.red,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              _hasInternet ? 'Connecté à Internet' : 'Hors ligne',
              style: TextStyle(
                color: _hasInternet ? Colors.green : Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
      ],
    );
  }*/

  Widget _buildOfflineWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.red[600], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Connexion internet requise pour se connecter',
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Logo PNG
  Widget _buildLogoWidget() {
    return ClipOval(
      child: Container(
        width: 115,
        height: 115,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(1000),
        ),
        child: Image.asset(
          "assets/image/logo.png",
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.person,
              size: 50,
              color: Colors.grey,
            );
          },
        ),
      ),
    );
  }
}