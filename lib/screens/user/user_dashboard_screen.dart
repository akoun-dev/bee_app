import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/user_model.dart';
import '../../models/agent_model.dart';
import '../../models/reservation_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/recommendation_service.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/agent_card.dart';
import '../../widgets/simple_app_bar.dart';

// Écran de tableau de bord utilisateur
class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  // État
  bool _isLoading = true;
  UserModel? _currentUser;
  List<AgentModel> _recommendedAgents = [];
  List<ReservationModel> _recentReservations = [];
  Map<String, dynamic> _userStats = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // Récupérer les statistiques utilisateur
  Future<Map<String, dynamic>> _getUserStatistics(String userId) async {
    try {
      final databaseService = Provider.of<DatabaseService>(
        context,
        listen: false,
      );

      // Récupérer toutes les réservations de l'utilisateur
      final reservations =
          await databaseService.getUserReservations(userId).first;

      // Calculer les statistiques
      int totalReservations = reservations.length;
      int pendingReservations =
          reservations
              .where((r) => r.status == ReservationModel.statusPending)
              .length;
      int approvedReservations =
          reservations
              .where((r) => r.status == ReservationModel.statusApproved)
              .length;
      int completedReservations =
          reservations
              .where((r) => r.status == ReservationModel.statusCompleted)
              .length;
      int cancelledReservations =
          reservations
              .where((r) => r.status == ReservationModel.statusCancelled)
              .length;

      // Calculer le nombre d'agents différents réservés
      final uniqueAgentIds = reservations.map((r) => r.agentId).toSet();
      int uniqueAgentsCount = uniqueAgentIds.length;

      // Calculer la durée totale des missions (en jours)
      int totalDurationDays = 0;
      for (var reservation in reservations) {
        final duration =
            reservation.endDate.difference(reservation.startDate).inDays;
        totalDurationDays += duration;
      }

      return {
        'totalReservations': totalReservations,
        'pendingReservations': pendingReservations,
        'approvedReservations': approvedReservations,
        'completedReservations': completedReservations,
        'cancelledReservations': cancelledReservations,
        'uniqueAgentsCount': uniqueAgentsCount,
        'totalDurationDays': totalDurationDays,
      };
    } catch (e) {
      return {
        'totalReservations': 0,
        'pendingReservations': 0,
        'approvedReservations': 0,
        'completedReservations': 0,
        'cancelledReservations': 0,
        'uniqueAgentsCount': 0,
        'totalDurationDays': 0,
      };
    }
  }

  // Charger les données du tableau de bord
  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final databaseService = Provider.of<DatabaseService>(
        context,
        listen: false,
      );
      final recommendationService = Provider.of<RecommendationService>(
        context,
        listen: false,
      );

      // Récupérer les données de l'utilisateur actuel
      final userData = await authService.getCurrentUserData();
      if (userData == null) {
        throw Exception('Impossible de récupérer les données utilisateur');
      }

      // Récupérer les réservations récentes
      final reservations =
          await databaseService.getUserReservations(userData.uid).first;
      final recentReservations = reservations.take(3).toList();

      // Récupérer les agents recommandés
      final recommendedAgents = await recommendationService
          .getRecommendedAgents(userData.uid);

      // Récupérer les statistiques utilisateur
      final userStats = await _getUserStatistics(userData.uid);

      if (mounted) {
        setState(() {
          _currentUser = userData;
          _recentReservations = recentReservations;
          _recommendedAgents = recommendedAgents;
          _userStats = userStats;
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

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const LoadingIndicator(message: 'Chargement du tableau de bord...')
        : _errorMessage != null
        ? ErrorMessage(
          message: 'Erreur: $_errorMessage',
          onRetry: _loadDashboardData,
        )
        : _buildDashboard();
  }

  // Construire le tableau de bord
  Widget _buildDashboard() {
    return CustomScrollView(
      slivers: [
        // En-tête avec profil utilisateur
        _buildAppBar(),

        // Contenu du tableau de bord
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Carte de bienvenue
                _buildWelcomeCard(),

                const SizedBox(height: 24),

                // Statistiques utilisateur
                _buildUserStats(),

                const SizedBox(height: 24),

                // Réservations récentes
                _buildRecentReservations(),

                const SizedBox(height: 24),

                // Agents recommandés
                _buildRecommendedAgents(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Construire l'AppBar
  Widget _buildAppBar() {
    return SimpleSliverAppBar(
      title: 'Tableau de bord',
      icon: Icons.dashboard_rounded,
      actions: [
        // Bouton de notifications
        IconButton(
          icon: Icon(
            Icons.notifications_outlined,
            color: Colors.grey[700],
            size: 22,
          ),
          onPressed: () {
            // Afficher un message temporaire
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications à venir')),
            );
          },
        ),
        // Bouton de profil
        IconButton(
          icon: Icon(Icons.person_outline, color: Colors.grey[700], size: 22),
          onPressed: () => context.go('/profile'),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // Construire la carte de bienvenue
  Widget _buildWelcomeCard() {
    final now = DateTime.now();
    final hour = now.hour;

    String greeting;
    if (hour < 12) {
      greeting = 'Bonjour';
    } else if (hour < 18) {
      greeting = 'Bon après-midi';
    } else {
      greeting = 'Bonsoir';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(
                  imageUrl: _currentUser?.profileImageUrl,
                  name: _currentUser?.fullName,
                  size: 60,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$greeting, ${_currentUser?.fullName != null ? _currentUser!.fullName.split(' ').first : 'Utilisateur'}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bienvenue sur votre tableau de bord',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Votre sécurité est notre priorité',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Construire les statistiques utilisateur
  Widget _buildUserStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Vos statistiques',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton.icon(
              onPressed: () => context.go('/history'),
              icon: const Icon(Icons.analytics_outlined, size: 18),
              label: const Text('Voir tout'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryColor.withAlpha(30), Colors.white],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryColor.withAlpha(50),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Réservations',
                      value: _userStats['totalReservations']?.toString() ?? '0',
                      icon: Icons.calendar_today,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'En attente',
                      value:
                          _userStats['pendingReservations']?.toString() ?? '0',
                      icon: Icons.hourglass_empty,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Complétées',
                      value:
                          _userStats['completedReservations']?.toString() ??
                          '0',
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Agents utilisés',
                      value: _userStats['uniqueAgentsCount']?.toString() ?? '0',
                      icon: Icons.people_outline,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Construire une carte de statistique
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(40),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.mediumColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Récupérer les détails d'un agent
  Future<AgentModel?> _getAgentDetails(String agentId) async {
    try {
      final databaseService = Provider.of<DatabaseService>(
        context,
        listen: false,
      );
      return await databaseService.getAgent(agentId);
    } catch (e) {
      // Utiliser un logger en production au lieu de print
      // Logger.error('Erreur lors de la récupération des détails de l\'agent: ${e.toString()}');
      return null;
    }
  }

  // Construire les réservations récentes
  Widget _buildRecentReservations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Réservations récentes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton.icon(
              onPressed: () => context.go('/history'),
              icon: const Icon(Icons.history, size: 18),
              label: const Text('Voir tout'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.lightColor, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child:
              _recentReservations.isEmpty
                  ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: EmptyMessage(
                      message: 'Aucune réservation récente',
                      icon: Icons.event_busy,
                    ),
                  )
                  : Column(
                    children:
                        _recentReservations.map((reservation) {
                          return FutureBuilder<AgentModel?>(
                            future: _getAgentDetails(reservation.agentId),
                            builder: (context, snapshot) {
                              final agent = snapshot.data;
                              return Column(
                                children: [
                                  _buildReservationCard(reservation, agent),
                                  if (_recentReservations.last != reservation)
                                    const Divider(height: 1, thickness: 1),
                                ],
                              );
                            },
                          );
                        }).toList(),
                  ),
        ),
      ],
    );
  }

  // Construire une carte de réservation
  Widget _buildReservationCard(
    ReservationModel reservation,
    AgentModel? agent,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Déterminer la couleur en fonction du statut
    Color statusColor;
    switch (reservation.status) {
      case ReservationModel.statusPending:
        statusColor = Colors.orange;
        break;
      case ReservationModel.statusApproved:
        statusColor = Colors.blue;
        break;
      case ReservationModel.statusCompleted:
        statusColor = Colors.green;
        break;
      case ReservationModel.statusCancelled:
        statusColor = Colors.red;
        break;
      case ReservationModel.statusRejected:
        statusColor = Colors.red;
        break;
      default:
        statusColor = AppTheme.mediumColor;
    }

    return InkWell(
      onTap: () => context.go('/history'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Photo de l'agent avec Firebase Storage
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withAlpha(100), width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AgentImage(
                  agentId: agent?.id,
                  imageUrl: agent?.profileImageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Informations de la réservation
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          agent?.fullName ?? 'Agent',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      StatusBadge(status: reservation.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Du ${dateFormat.format(reservation.startDate)} au ${dateFormat.format(reservation.endDate)}',
                    style: TextStyle(color: AppTheme.mediumColor, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reservation.location,
                    style: TextStyle(color: AppTheme.mediumColor, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Flèche de navigation
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.mediumColor,
            ),
          ],
        ),
      ),
    );
  }

  // Construire les agents recommandés
  Widget _buildRecommendedAgents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Agents recommandés',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton.icon(
              onPressed: () => context.go('/recommendations'),
              icon: const Icon(Icons.recommend, size: 18),
              label: const Text('Voir tout'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _recommendedAgents.isEmpty
            ? Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.lightColor, width: 1),
              ),
              child: const EmptyMessage(
                message: 'Aucun agent recommandé pour le moment',
                icon: Icons.person_search,
              ),
            )
            : Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white,
                    AppTheme.primaryColor.withAlpha(20),
                    Colors.white,
                  ],
                ),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _recommendedAgents.length,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                itemBuilder: (context, index) {
                  final agent = _recommendedAgents[index];
                  return Container(
                    width: 150,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    child: AgentCard(
                      agent: agent,
                      onTap: () => context.go('/agent/${agent.id}'),
                      isCompact: true,
                    ),
                  );
                },
              ),
            ),
      ],
    );
  }
}
