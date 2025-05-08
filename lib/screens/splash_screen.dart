import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import 'dart:math' as math;

// Écran de démarrage qui vérifie l'état d'authentification
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // Initialiser l'animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Démarrer l'animation
    _animationController.forward();

    // Vérifier l'état d'authentification après le rendu initial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthState();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
        // Utiliser Future.microtask pour éviter les problèmes de navigation pendant le build
        Future.microtask(() {
          if (mounted) {
            if (userData != null && userData.isAdmin) {
              context.go('/admin/reservations');
            } else {
              context.go('/dashboard');
            }
          }
        });
      } else {
        // Rediriger vers la page d'authentification
        // Utiliser Future.microtask pour éviter les problèmes de navigation pendant le build
        Future.microtask(() {
          if (mounted) {
            context.go('/auth');
          }
        });
      }
    } catch (e) {
      // En cas d'erreur, rediriger vers la page d'authentification
      // Utiliser Future.microtask pour éviter les problèmes de navigation pendant le build
      Future.microtask(() {
        if (mounted) {
          context.go('/auth');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo de l'application avec animation
                Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(50),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Image.asset(
                            'assets/images/bee-logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Nom de l'application avec animation
                Opacity(
                  opacity: _opacityAnimation.value,
                  child: const Text(
                    'ZIBENE SECURITY',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Slogan avec animation
                Opacity(
                  opacity: _opacityAnimation.value,
                  child: const Text(
                    'Votre sécurité, notre priorité',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 50),
                // Indicateur de chargement
                Opacity(
                  opacity: _animationController.value,
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
