import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/agent_model.dart';
import '../../models/reservation_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/admin_app_bar.dart';
import '../../widgets/admin_drawer.dart';

// Écran de gestion des réservations en attente (pour admin)
class PendingReservationsScreen extends StatefulWidget {
  const PendingReservationsScreen({super.key});

  @override
  State<PendingReservationsScreen> createState() => _PendingReservationsScreenState();
}

class _PendingReservationsScreenState extends State<PendingReservationsScreen> {
  // État
  final Map<String, AgentModel?> _agentsCache = {};
  final Map<String, UserModel?> _usersCache = {};

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
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

  // Récupérer les détails d'un agent
  Future<AgentModel?> _getAgentDetails(String agentId) async {
    // Vérifier si l'agent est déjà en cache
    if (_agentsCache.containsKey(agentId)) {
      return _agentsCache[agentId];
    }

    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final agent = await databaseService.getAgent(agentId);

      // Mettre en cache
      if (mounted) {
        setState(() {
          _agentsCache[agentId] = agent;
        });
      }

      return agent;
    } catch (e) {
      // Utiliser un logger en production au lieu de print
      // Logger.error('Erreur lors de la récupération de l\'agent: ${e.toString()}');
      return null;
    }
  }

  // Récupérer les détails d'un utilisateur
  Future<UserModel?> _getUserDetails(String userId) async {
    // Vérifier si l'utilisateur est déjà en cache
    if (_usersCache.containsKey(userId)) {
      return _usersCache[userId];
    }

    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final user = await databaseService.getUser(userId);

      // Mettre en cache
      if (mounted) {
        setState(() {
          _usersCache[userId] = user;
        });
      }

      return user;
    } catch (e) {
      // Utiliser un logger en production au lieu de print
      // Logger.error('Erreur lors de la récupération de l\'utilisateur: ${e.toString()}');
      return null;
    }
  }

  // Approuver une réservation
  Future<void> _approveReservation(ReservationModel reservation) async {
    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);

      // Mettre à jour le statut de la réservation
      final updatedReservation = reservation.approve();
      await databaseService.updateReservation(updatedReservation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Réservation approuvée avec succès'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'approbation: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // Rejeter une réservation
  Future<void> _rejectReservation(ReservationModel reservation) async {
    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);

      // Mettre à jour le statut de la réservation
      final updatedReservation = reservation.reject();
      await databaseService.updateReservation(updatedReservation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Réservation rejetée'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du rejet: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
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
    final databaseService = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: AdminAppBar(
        title: AppConstants.pendingReservations,
        actions: [
          // Navigation vers la gestion des agents
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () => context.go('/admin/agents'),
            tooltip: 'Gestion des agents',
          ),
          // Navigation vers les statistiques
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.go('/admin/statistics'),
            tooltip: 'Statistiques',
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: StreamBuilder<List<ReservationModel>>(
        stream: databaseService.getPendingReservations(),
        builder: (context, snapshot) {
          // Afficher un indicateur de chargement
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator(
              message: 'Chargement des réservations en attente...',
            );
          }

          // Afficher un message d'erreur
          if (snapshot.hasError) {
            return ErrorMessage(
              message: 'Erreur: ${snapshot.error}',
              onRetry: () => setState(() {}),
            );
          }

          // Récupérer les réservations
          final reservations = snapshot.data ?? [];

          // Afficher un message si aucune réservation n'est trouvée
          if (reservations.isEmpty) {
            return const EmptyMessage(
              message: 'Aucune réservation en attente',
              icon: Icons.check_circle_outline,
            );
          }

          // Afficher la liste des réservations
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final reservation = reservations[index];

              return _buildReservationCard(reservation);
            },
          );
        },
      ),
    );
  }

  // Carte de réservation
  Widget _buildReservationCard(ReservationModel reservation) {
    final dateFormat = DateFormat(AppConstants.dateFormat);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec ID et statut
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Réservation #${reservation.id.substring(0, 6)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                StatusBadge(status: reservation.status),
              ],
            ),

            const Divider(height: 24),

            // Détails de la réservation
            _buildInfoRow(
              'Dates',
              '${dateFormat.format(reservation.startDate)} - ${dateFormat.format(reservation.endDate)}',
              Icons.calendar_today,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Lieu',
              reservation.location,
              Icons.location_on_outlined,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Description',
              reservation.description,
              Icons.description_outlined,
            ),

            const Divider(height: 24),

            // Informations sur l'agent
            FutureBuilder<AgentModel?>(
              future: _getAgentDetails(reservation.agentId),
              builder: (context, snapshot) {
                final agent = snapshot.data;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Agent',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    agent == null
                        ? const Text('Chargement des informations de l\'agent...')
                        : Row(
                            children: [
                              UserAvatar(
                                imageUrl: agent.profileImageUrl,
                                name: agent.fullName,
                                size: 40,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      agent.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      agent.profession,
                                      style: const TextStyle(
                                        color: AppTheme.mediumColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            // Informations sur l'utilisateur
            FutureBuilder<UserModel?>(
              future: _getUserDetails(reservation.userId),
              builder: (context, snapshot) {
                final user = snapshot.data;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Client',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    user == null
                        ? const Text('Chargement des informations du client...')
                        : Row(
                            children: [
                              UserAvatar(
                                imageUrl: user.profileImageUrl,
                                name: user.fullName,
                                size: 40,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      user.email,
                                      style: const TextStyle(
                                        color: AppTheme.mediumColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
                                      Text(
                                        user.phoneNumber!,
                                        style: const TextStyle(
                                          color: AppTheme.mediumColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Boutons d'action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Bouton Voir détails
                TextButton.icon(
                  onPressed: () {
                    // Naviguer vers la page de détails de la réservation
                    context.go('/admin/reservation/${reservation.id}');
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('Voir détails'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),

                // Boutons Rejeter/Approuver
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _rejectReservation(reservation),
                      icon: const Icon(Icons.close),
                      label: const Text(AppConstants.rejectReservation),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: const BorderSide(color: AppTheme.errorColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _approveReservation(reservation),
                      icon: const Icon(Icons.check),
                      label: const Text(AppConstants.approveReservation),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Ligne d'information
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: AppTheme.mediumColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.mediumColor,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
