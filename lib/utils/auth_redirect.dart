import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

// Widget pour gérer la redirection automatique en fonction du statut d'authentification
class AuthRedirect extends StatefulWidget {
  final Widget child;

  const AuthRedirect({
    super.key,
    required this.child,
  });

  @override
  State<AuthRedirect> createState() => _AuthRedirectState();
}

class _AuthRedirectState extends State<AuthRedirect> {
  // État
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Vérifier l'état d'authentification
    if (!_isInitialized) {
      _checkAuthStatus();
      _isInitialized = true;
    }
  }

  // Vérifier l'état d'authentification et rediriger si nécessaire
  Future<void> _checkAuthStatus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = Provider.of<User?>(context, listen: false);

    // Si l'utilisateur est connecté
    if (user != null) {
      try {
        // Récupérer les données utilisateur
        final userData = await authService.getCurrentUserData();

        if (userData != null && mounted) {
          // Rediriger en fonction du statut d'administrateur
          if (userData.isAdmin) {
            // Rediriger vers le tableau de bord administrateur
            context.go('/admin/dashboard');
          } else {
            // Rediriger vers le tableau de bord
            context.go('/dashboard');
          }
        }
      } catch (e) {
        // Utiliser un logger en production au lieu de print
        // Logger.error('Erreur lors de la vérification du statut d\'authentification: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Écouter les changements d'état d'authentification
    final user = Provider.of<User?>(context);

    // Si l'utilisateur se déconnecte, vérifier à nouveau l'état d'authentification
    if (user == null && _isInitialized) {
      _isInitialized = false;
    }

    return widget.child;
  }
}

// Fonction pour créer un GoRouter avec redirection basée sur l'authentification
GoRouter createAuthRouter({
  required String initialLocation,
  required List<RouteBase> routes,
  required Widget Function(BuildContext, GoRouterState) errorBuilder,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: routes,
    errorBuilder: errorBuilder,
    redirect: (context, state) async {
      // Récupérer l'utilisateur actuel
      final user = Provider.of<User?>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      // Si l'utilisateur n'est pas connecté et essaie d'accéder à une route protégée
      if (user == null) {
        // Routes publiques (accessibles sans connexion)
        final publicRoutes = ['/auth', '/admin'];

        // Si la route actuelle n'est pas une route publique, rediriger vers la page d'authentification
        if (!publicRoutes.contains(state.matchedLocation) &&
            !state.matchedLocation.startsWith('/auth') &&
            !state.matchedLocation.startsWith('/admin')) {
          return '/auth';
        }
      } else {
        // L'utilisateur est connecté

        // Si l'utilisateur essaie d'accéder à la page d'authentification, le rediriger
        if (state.matchedLocation == '/auth' || state.matchedLocation == '/admin') {
          // Vérifier si l'utilisateur est un administrateur
          final userData = await authService.getCurrentUserData();
          if (userData != null) {
            if (userData.isAdmin) {
              // Rediriger vers le tableau de bord administrateur
              return '/admin/dashboard';
            } else {
              // Rediriger vers la liste des agents
              return '/agents';
            }
          }
        }

        // Vérifier les routes administrateur
        if (state.matchedLocation.startsWith('/admin/')) {
          // Vérifier si l'utilisateur est un administrateur
          final userData = await authService.getCurrentUserData();
          if (userData != null && !userData.isAdmin) {
            // Rediriger vers la liste des agents si l'utilisateur n'est pas administrateur
            return '/agents';
          }
        }
      }

      // Pas de redirection
      return null;
    },
  );
}
