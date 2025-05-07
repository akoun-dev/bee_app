import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../utils/theme.dart';

// Drawer de navigation pour les administrateurs
class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  // Méthode pour se déconnecter
  Future<void> _signOut(BuildContext context) async {
    // Fermer le drawer
    Navigator.pop(context);

    // Confirmer la déconnexion
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    // Si confirmé, déconnecter l'utilisateur
    if (confirmed == true && context.mounted) {
      try {
        // Stocker le service d'authentification avant toute opération asynchrone
        final authService = Provider.of<AuthService>(context, listen: false);

        // Vérifier si le contexte est toujours valide
        if (!context.mounted) return;

        // Afficher un indicateur de chargement
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Déconnexion en cours...'),
              ],
            ),
          ),
        );

        // Déconnecter l'utilisateur
        await authService.signOut();

        // Fermer le dialogue de chargement
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        // Rediriger vers la page d'authentification
        if (context.mounted) {
          // Utiliser go pour naviguer vers la page d'authentification
          // et forcer un rafraîchissement complet de l'application
          context.go('/auth');

          // Forcer un rafraîchissement de l'application après un court délai
          Future.delayed(const Duration(milliseconds: 100), () {
            if (context.mounted) {
              context.go('/auth');
            }
          });
        }
      } catch (e) {
        // Fermer le dialogue de chargement en cas d'erreur
        if (context.mounted) {
          Navigator.of(context).pop();

          // Afficher un message d'erreur
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la déconnexion: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Drawer(
      child: Column(
        children: [
          // En-tête du drawer
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo ou icône
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: AppTheme.secondaryColor,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 12),

                // Titre
                const Text(
                  'Administration',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // Sous-titre
                const Text(
                  'Panneau de contrôle',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Liste des options de navigation
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Tableau de bord
                _buildNavItem(
                  context: context,
                  icon: Icons.dashboard,
                  title: 'Tableau de bord',
                  route: '/admin/dashboard',
                ),

                // Réservations
                _buildNavItem(
                  context: context,
                  icon: Icons.calendar_today,
                  title: 'Réservations',
                  route: '/admin/reservations',
                ),

                // Gestion des agents
                _buildNavItem(
                  context: context,
                  icon: Icons.security,
                  title: 'Gestion des agents',
                  route: '/admin/agents',
                ),

                // Gestion des utilisateurs
                _buildNavItem(
                  context: context,
                  icon: Icons.people,
                  title: 'Gestion des utilisateurs',
                  route: '/admin/users',
                ),

                // Statistiques
                _buildNavItem(
                  context: context,
                  icon: Icons.bar_chart,
                  title: 'Statistiques',
                  route: '/admin/statistics',
                ),

                // Notifications
                _buildNavItem(
                  context: context,
                  icon: Icons.notifications,
                  title: 'Notifications',
                  route: '/admin/notifications',
                ),

                // Rapports
                _buildNavItem(
                  context: context,
                  icon: Icons.description,
                  title: 'Rapports',
                  route: '/admin/reports',
                ),

                // Paramètres
                _buildNavItem(
                  context: context,
                  icon: Icons.settings,
                  title: 'Paramètres',
                  route: '/admin/settings',
                ),

                // Mon profil
                _buildNavItem(
                  context: context,
                  icon: Icons.account_circle,
                  title: 'Mon profil',
                  route: '/admin/profile',
                ),
              ],
            ),
          ),

          // Pied du drawer avec déconnexion
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              children: [
                const Divider(),
                OutlinedButton.icon(
                  onPressed: () => _signOut(context),
                  icon: const Icon(Icons.exit_to_app, color: AppTheme.errorColor),
                  label: const Text(
                    'Déconnexion',
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    side: const BorderSide(color: AppTheme.errorColor),
                    minimumSize: const Size(double.infinity, 0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Construire un élément de navigation
  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
  }) {
    // Vérifier si l'élément est actif (route actuelle)
    final isActive = GoRouterState.of(context).matchedLocation == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? AppTheme.primaryColor : AppTheme.mediumColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? AppTheme.primaryColor : AppTheme.darkColor,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isActive ? AppTheme.primaryColor.withAlpha(20) : null,
      onTap: () {
        // Fermer le drawer
        Navigator.pop(context);

        // Naviguer vers la route
        context.go(route);
      },
    );
  }
}
