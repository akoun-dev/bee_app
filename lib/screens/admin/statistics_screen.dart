import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/admin_app_bar.dart';
import '../../widgets/admin_drawer.dart';

// Écran de statistiques (pour admin)
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  // État
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _loadStatistics();
  }

  // Vérifier que l'utilisateur est bien un administrateur
  Future<void> _checkAdminStatus() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userData = await authService.getCurrentUserData();

      if (userData == null || !userData.isAdmin) {
        if (mounted) {
          // Rediriger vers la page de connexion admin
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppConstants.errorPermission),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          context.go('/admin');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        context.go('/admin');
      }
    }
  }

  // Charger les statistiques
  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final statistics = await databaseService.getStatistics();

      if (mounted) {
        setState(() {
          _statistics = statistics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // Se déconnecter
  Future<void> _signOut() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();

      if (mounted) {
        context.go('/auth'); // Redirection vers la page de connexion
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminAppBar(
        title: AppConstants.statistics,
        actions: [
          // Navigation vers les réservations en attente
          IconButton(
            icon: const Icon(Icons.pending_actions),
            onPressed: () => context.go('/admin/reservations'),
            tooltip: 'Réservations',
          ),
          // Navigation vers la gestion des agents
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () => context.go('/admin/agents'),
            tooltip: 'Gestion des agents',
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: _isLoading
          ? const LoadingIndicator(message: 'Chargement des statistiques...')
          : _errorMessage != null
              ? ErrorMessage(
                  message: 'Erreur: $_errorMessage',
                  onRetry: _loadStatistics,
                )
              : RefreshIndicator(
                  onRefresh: _loadStatistics,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titre
                        const Text(
                          'Tableau de bord',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Cartes de statistiques
                        Row(
                          children: [
                            // Nombre d'agents
                            Expanded(
                              child: _buildStatCard(
                                title: 'Agents',
                                value: _statistics['agentsCount'] ?? 0,
                                icon: Icons.people,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Nombre d'utilisateurs
                            Expanded(
                              child: _buildStatCard(
                                title: 'Utilisateurs',
                                value: _statistics['usersCount'] ?? 0,
                                icon: Icons.person,
                                color: AppTheme.accentColor,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Nombre total de réservations
                        _buildStatCard(
                          title: 'Réservations totales',
                          value: _statistics['reservationsCount'] ?? 0,
                          icon: Icons.calendar_today,
                          color: AppTheme.secondaryColor,
                          isWide: true,
                        ),

                        const SizedBox(height: 24),

                        // Titre de la section réservations
                        const Text(
                          'Réservations par statut',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Réservations par statut
                        Row(
                          children: [
                            // En attente
                            Expanded(
                              child: _buildStatCard(
                                title: 'En attente',
                                value: _statistics['pendingCount'] ?? 0,
                                icon: Icons.hourglass_empty,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Approuvées
                            Expanded(
                              child: _buildStatCard(
                                title: 'Approuvées',
                                value: _statistics['approvedCount'] ?? 0,
                                icon: Icons.check_circle_outline,
                                color: AppTheme.accentColor,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Terminées
                        _buildStatCard(
                          title: 'Terminées',
                          value: _statistics['completedCount'] ?? 0,
                          icon: Icons.done_all,
                          color: AppTheme.primaryColor,
                          isWide: true,
                        ),

                        const SizedBox(height: 24),

                        // Graphique (à implémenter)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Répartition des réservations',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Graphique simplifié (à remplacer par un vrai graphique)
                                SizedBox(
                                  height: 200,
                                  child: _buildSimpleChart(),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Bouton pour voir les réservations en attente
                            ElevatedButton.icon(
                              onPressed: () => context.go('/admin/reservations'),
                              icon: const Icon(Icons.pending_actions),
                              label: const Text('Réservations en attente'),
                            ),
                            // Bouton pour gérer les agents
                            ElevatedButton.icon(
                              onPressed: () => context.go('/admin/agents'),
                              icon: const Icon(Icons.people),
                              label: const Text('Gérer les agents'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  // Carte de statistique
  Widget _buildStatCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
    bool isWide = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.mediumColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: isWide ? 32 : 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Graphique simplifié
  Widget _buildSimpleChart() {
    // Récupérer les données
    final pendingCount = _statistics['pendingCount'] ?? 0;
    final approvedCount = _statistics['approvedCount'] ?? 0;
    final completedCount = _statistics['completedCount'] ?? 0;
    final total = pendingCount + approvedCount + completedCount;

    // Calculer les pourcentages
    final pendingPercentage = total > 0 ? pendingCount / total : 0.0;
    final approvedPercentage = total > 0 ? approvedCount / total : 0.0;
    final completedPercentage = total > 0 ? completedCount / total : 0.0;

    return Column(
      children: [
        // Barres de progression
        _buildProgressBar(
          label: 'En attente',
          percentage: pendingPercentage,
          color: Colors.orange,
          count: pendingCount,
        ),
        const SizedBox(height: 16),
        _buildProgressBar(
          label: 'Approuvées',
          percentage: approvedPercentage,
          color: AppTheme.accentColor,
          count: approvedCount,
        ),
        const SizedBox(height: 16),
        _buildProgressBar(
          label: 'Terminées',
          percentage: completedPercentage,
          color: AppTheme.primaryColor,
          count: completedCount,
        ),
      ],
    );
  }

  // Barre de progression
  Widget _buildProgressBar({
    required String label,
    required double percentage,
    required Color color,
    required int count,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              '$count (${(percentage * 100).toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: AppTheme.lightColor,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
