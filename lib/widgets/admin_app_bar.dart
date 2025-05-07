import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

/// AppBar personnalisé pour les écrans d'administration
class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Titre de l'AppBar
  final String title;
  
  /// Actions supplémentaires à afficher dans l'AppBar
  final List<Widget>? actions;
  
  /// Hauteur de l'AppBar
  final double height;
  
  /// Constructeur pour AdminAppBar
  const AdminAppBar({
    super.key,
    required this.title,
    this.actions,
    this.height = kToolbarHeight,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      iconTheme: const IconThemeData(color: Colors.black87),
      actions: [
        // Actions personnalisées
        if (actions != null) ...actions!,
        
        // Menu de navigation rapide
        PopupMenuButton<String>(
          icon: const Icon(Icons.apps),
          tooltip: 'Menu de navigation',
          onSelected: (value) {
            context.go(value);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              enabled: false,
              child: Text(
                'Navigation rapide',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const PopupMenuDivider(),
            _buildMenuItem(
              'Tableau de bord',
              Icons.dashboard,
              '/admin/dashboard',
            ),
            _buildMenuItem(
              'Réservations',
              Icons.calendar_today,
              '/admin/reservations',
            ),
            _buildMenuItem(
              'Agents',
              Icons.security,
              '/admin/agents',
            ),
            _buildMenuItem(
              'Statistiques',
              Icons.bar_chart,
              '/admin/statistics',
            ),
            _buildMenuItem(
              'Paramètres',
              Icons.settings,
              '/admin/settings',
            ),
          ],
        ),
        
        // Menu utilisateur
        PopupMenuButton<String>(
          icon: const Icon(Icons.account_circle),
          tooltip: 'Menu utilisateur',
          onSelected: (value) async {
            if (value == 'logout') {
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
                final authService = Provider.of<AuthService>(context, listen: false);
                await authService.signOut();
                
                // Rediriger vers la page d'authentification
                if (context.mounted) {
                  context.go('/auth');
                }
              }
            } else {
              context.go(value);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              enabled: false,
              child: Text(
                'Administrateur',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const PopupMenuDivider(),
            _buildMenuItem(
              'Paramètres',
              Icons.settings,
              '/admin/settings',
            ),
            _buildMenuItem(
              'Vue utilisateur',
              Icons.visibility,
              '/agents',
            ),
            const PopupMenuDivider(),
            _buildMenuItem(
              AppConstants.logout,
              Icons.exit_to_app,
              'logout',
              color: AppTheme.errorColor,
            ),
          ],
        ),
        
        const SizedBox(width: 8),
      ],
    );
  }

  /// Construire un élément de menu
  PopupMenuItem<String> _buildMenuItem(
    String title,
    IconData icon,
    String value, {
    Color? color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: color ?? AppTheme.mediumColor,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: color ?? AppTheme.darkColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
