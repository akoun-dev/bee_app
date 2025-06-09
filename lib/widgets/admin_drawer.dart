import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../models/user_model.dart';
import '../widgets/common_widgets.dart';

// Peintre personnalisé pour créer un motif de grille
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white
          ..strokeWidth = 0.5
          ..style = PaintingStyle.stroke;

    // Dessiner des lignes horizontales
    final horizontalLineCount = 10;
    final horizontalSpacing = size.height / horizontalLineCount;
    for (int i = 0; i <= horizontalLineCount; i++) {
      final y = i * horizontalSpacing;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Dessiner des lignes verticales
    final verticalLineCount = 10;
    final verticalSpacing = size.width / verticalLineCount;
    for (int i = 0; i <= verticalLineCount; i++) {
      final x = i * verticalSpacing;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Drawer de navigation pour les administrateurs
class AdminDrawer extends StatefulWidget {
  const AdminDrawer({super.key});

  @override
  State<AdminDrawer> createState() => _AdminDrawerState();
}

class _AdminDrawerState extends State<AdminDrawer> {
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Charger les données de l'utilisateur
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userData = await authService.getCurrentUserData();

      if (mounted) {
        setState(() {
          _currentUser = userData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Méthode pour se déconnecter
  Future<void> _signOut(BuildContext context) async {
    // Fermer le drawer
    Navigator.pop(context);

    // Confirmer la déconnexion
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
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
          builder:
              (dialogContext) => const AlertDialog(
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
          Container(
            padding: EdgeInsets.zero,
            child: Stack(
              children: [
                // Fond avec dégradé
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.secondaryColor,
                        AppTheme.secondaryColor.withAlpha(220),
                        AppTheme.primaryColor,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(50),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                ),

                // Motif décoratif
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.1,
                    child: CustomPaint(painter: GridPainter()),
                  ),
                ),

                // Contenu
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar et informations utilisateur
                      _isLoading
                          ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Row(
                            children: [
                              // Avatar
                              UserAvatar(
                                imageUrl: _currentUser?.profileImageUrl,
                                name: _currentUser?.fullName,
                                size: 60,
                              ),
                              const SizedBox(width: 12),

                              // Informations utilisateur
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentUser?.fullName ??
                                          'Administrateur',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _currentUser?.email ?? '',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                      const SizedBox(height: 20),

                      // Titre et sous-titre
                      const Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Administration',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      const Text(
                        'Panneau de contrôle',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),

                // Bouton de déconnexion
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    tooltip: 'Déconnexion',
                    onPressed: () => _signOut(context),
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

                // Divider pour séparer les sections
                const Divider(),

                // Section Sécurité et Monitoring
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    'Sécurité & Monitoring',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),

                // Logs d'audit
                _buildNavItem(
                  context: context,
                  icon: Icons.history,
                  title: 'Logs d\'audit',
                  route: '/admin/audit-logs',
                ),

                // Gestion des permissions
                _buildNavItem(
                  context: context,
                  icon: Icons.admin_panel_settings,
                  title: 'Permissions',
                  route: '/admin/permissions',
                ),

                // Monitoring système
                _buildNavItem(
                  context: context,
                  icon: Icons.monitor_heart,
                  title: 'Monitoring',
                  route: '/admin/monitoring',
                ),

                const Divider(),

                // Section Configuration
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    'Configuration',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
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
