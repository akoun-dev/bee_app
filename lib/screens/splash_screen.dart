import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';

// Écran de démarrage qui vérifie l'état d'authentification
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Vérifier l'état d'authentification après le rendu initial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthState();
    });
  }

  // Vérifier l'état d'authentification et rediriger en conséquence
  Future<void> _checkAuthState() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    try {
      // Attendre un court délai pour afficher le splash screen
      await Future.delayed(const Duration(seconds: 2));
      
      // Vérifier si l'utilisateur est déjà connecté
      final isLoggedIn = await authService.isUserLoggedIn();
      
      if (!mounted) return;
      
      if (isLoggedIn) {
        // Récupérer les données de l'utilisateur
        final userData = await authService.getCurrentUserData();
        
        if (!mounted) return;
        
        // Rediriger vers la page appropriée en fonction du statut d'administrateur
        if (userData != null && userData.isAdmin) {
          context.go('/admin/reservations');
        } else {
          context.go('/dashboard');
        }
      } else {
        // Rediriger vers la page d'authentification
        context.go('/auth');
      }
    } catch (e) {
      // En cas d'erreur, rediriger vers la page d'authentification
      if (mounted) {
        context.go('/auth');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo de l'application
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.security,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Nom de l'application
            const Text(
              'Bee App',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            // Slogan
            const Text(
              'Votre sécurité, notre priorité',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 50),
            // Indicateur de chargement
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
