import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../utils/theme.dart';

// Drawer de navigation pour les utilisateurs
class UserDrawer extends StatelessWidget {
  const UserDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Drawer(
      child: Column(
        children: [
          // En-tête du drawer
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo ou icône
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppTheme.primaryColor,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Titre
                const Text(
                  'Bee App',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                // Sous-titre
                const Text(
                  'Votre sécurité, notre priorité',
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
                // Accueil (liste des agents)
                _buildNavItem(
                  context: context,
                  icon: Icons.security,
                  title: 'Agents disponibles',
                  route: '/agents',
                ),
                
                // Recommandations
                _buildNavItem(
                  context: context,
                  icon: Icons.recommend,
                  title: 'Recommandations',
                  route: '/recommendations',
                ),
                
                // Historique des réservations
                _buildNavItem(
                  context: context,
                  icon: Icons.history,
                  title: 'Historique',
                  route: '/history',
                ),
                
                // Profil utilisateur
                _buildNavItem(
                  context: context,
                  icon: Icons.person,
                  title: 'Mon profil',
                  route: '/profile',
                ),
                
                // Paramètres
                _buildNavItem(
                  context: context,
                  icon: Icons.settings,
                  title: 'Paramètres',
                  route: '/settings',
                ),
                
                const Divider(),
                
                // Support
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Support'),
                  onTap: () {
                    // Fermer le drawer
                    Navigator.pop(context);
                    
                    // Afficher une boîte de dialogue d'aide
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Support'),
                        content: const Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Besoin d\'aide ?'),
                            SizedBox(height: 8),
                            Text('Email: support@beeapp.com'),
                            Text('Téléphone: +225 07 07 07 07'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Fermer'),
                          ),
                        ],
                      ),
                    );
                  },
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
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: AppTheme.errorColor),
                  title: const Text(
                    'Déconnexion',
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                  onTap: () async {
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
                      await authService.signOut();
                      
                      // Rediriger vers la page d'authentification
                      if (context.mounted) {
                        context.go('/auth');
                      }
                    }
                  },
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
