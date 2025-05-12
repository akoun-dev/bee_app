import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/agent_model.dart';
import '../../models/reservation_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/reservation_card.dart';
import '../../widgets/rating_dialog.dart';


// Écran d'historique des réservations
class ReservationHistoryScreen extends StatefulWidget {
  const ReservationHistoryScreen({super.key});

  @override
  State<ReservationHistoryScreen> createState() => _ReservationHistoryScreenState();
}

class _ReservationHistoryScreenState extends State<ReservationHistoryScreen> {
  // État
  final Map<String, AgentModel?> _agentsCache = {};

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

  // Annuler une réservation
  Future<void> _cancelReservation(ReservationModel reservation) async {
    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);

      // Mettre à jour le statut de la réservation
      final updatedReservation = reservation.cancel();
      await databaseService.updateReservation(updatedReservation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Réservation annulée avec succès'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'annulation: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // Marquer une réservation comme terminée
  Future<void> _completeReservation(ReservationModel reservation) async {
    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);

      // Mettre à jour le statut de la réservation
      final updatedReservation = reservation.complete();
      await databaseService.updateReservation(updatedReservation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Réservation marquée comme terminée'),
            backgroundColor: AppTheme.accentColor,
          ),
        );

        // Récupérer les détails de l'agent
        final agent = await _getAgentDetails(reservation.agentId);
        if (agent != null && mounted) {
          // Afficher directement le dialogue d'évaluation
          _showRatingDialogWithAgent(updatedReservation, agent);
        } else {
          // Fallback: demander à l'utilisateur s'il souhaite évaluer l'agent maintenant
          _showEvaluationPrompt(updatedReservation);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // Afficher une invite pour évaluer l'agent
  Future<void> _showEvaluationPrompt(ReservationModel reservation) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Évaluer l\'agent'),
        content: const Text('Souhaitez-vous évaluer l\'agent maintenant ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Évaluer maintenant'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      // Naviguer vers l'écran d'évaluation en utilisant GoRouter
      context.go('/review/${reservation.id}');
    }
  }

  // Afficher l'écran d'évaluation
  Future<void> _showRatingDialog(ReservationModel reservation) async {
    // Récupérer les détails de l'agent
    final agent = await _getAgentDetails(reservation.agentId);
    if (agent != null && mounted) {
      // Afficher le dialogue d'évaluation
      _showRatingDialogWithAgent(reservation, agent);
    } else {
      // Fallback: naviguer vers l'écran d'évaluation en utilisant GoRouter
      if (mounted) {
        context.go('/review/${reservation.id}');
      }
    }
  }

  // Afficher le dialogue d'évaluation avec les détails de l'agent
  Future<void> _showRatingDialogWithAgent(ReservationModel reservation, AgentModel agent) async {
    await showDialog(
      context: context,
      builder: (context) => RatingDialog(
        reservation: reservation,
        agent: agent,
        onSuccess: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Merci pour votre évaluation !'),
              backgroundColor: AppTheme.accentColor,
            ),
          );
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final databaseService = Provider.of<DatabaseService>(context);
    final currentUser = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Icône de la page
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.history,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Titre de la page
            const Text(
              AppConstants.reservationHistoryTitle,
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: currentUser == null
          ? const Center(
              child: Text('Vous devez être connecté pour voir votre historique'),
            )
          : Column(
              children: [
                // En-tête avec statistiques
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withAlpha(13),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: StreamBuilder<List<ReservationModel>>(
                    stream: databaseService.getUserReservations(currentUser.uid),
                    builder: (context, snapshot) {
                      // Statistiques par défaut
                      int totalReservations = 0;
                      int pendingReservations = 0;
                      int completedReservations = 0;

                      // Calculer les statistiques si les données sont disponibles
                      if (snapshot.hasData) {
                        final reservations = snapshot.data!;
                        totalReservations = reservations.length;
                        pendingReservations = reservations.where((r) =>
                          r.status == ReservationModel.statusPending ||
                          r.status == ReservationModel.statusApproved
                        ).length;
                        completedReservations = reservations.where((r) =>
                          r.status == ReservationModel.statusCompleted
                        ).length;
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCard(
                            'Total',
                            totalReservations.toString(),
                            Icons.history,
                            Theme.of(context).primaryColor,
                          ),
                          _buildStatCard(
                            'En cours',
                            pendingReservations.toString(),
                            Icons.pending_actions,
                            Colors.orange,
                          ),
                          _buildStatCard(
                            'Terminées',
                            completedReservations.toString(),
                            Icons.check_circle_outline,
                            Colors.green,
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Filtres de réservation
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Toutes', true, () {}),
                        const SizedBox(width: 8),
                        _buildFilterChip('En attente', false, () {}),
                        const SizedBox(width: 8),
                        _buildFilterChip('Approuvées', false, () {}),
                        const SizedBox(width: 8),
                        _buildFilterChip('Terminées', false, () {}),
                        const SizedBox(width: 8),
                        _buildFilterChip('Annulées', false, () {}),
                      ],
                    ),
                  ),
                ),

                // Liste des réservations
                Expanded(
                  child: StreamBuilder<List<ReservationModel>>(
                    stream: databaseService.getUserReservations(currentUser.uid),
                    builder: (context, snapshot) {
                      // Afficher un indicateur de chargement
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const LoadingIndicator(
                          message: 'Chargement de l\'historique...',
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
                          message: 'Vous n\'avez pas encore de réservations',
                          icon: Icons.history,
                        );
                      }

                      // Trier les réservations par date (les plus récentes d'abord)
                      reservations.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                      // Afficher la liste des réservations
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: reservations.length,
                        itemBuilder: (context, index) {
                          final reservation = reservations[index];

                          return FutureBuilder<AgentModel?>(
                            future: _getAgentDetails(reservation.agentId),
                            builder: (context, snapshot) {
                              final agent = snapshot.data;

                              return ReservationCard(
                                reservation: reservation,
                                agent: agent,
                                onRatePressed: reservation.status == ReservationModel.statusCompleted &&
                                              reservation.rating == null
                                    ? () => _showRatingDialog(reservation)
                                    : null,
                                onCancelPressed: reservation.status == ReservationModel.statusPending ||
                                                reservation.status == ReservationModel.statusApproved
                                    ? () => _cancelReservation(reservation)
                                    : null,
                                onCompletePressed: reservation.status == ReservationModel.statusApproved &&
                                                  reservation.endDate.isBefore(DateTime.now())
                                    ? () => _completeReservation(reservation)
                                    : null,
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  // Construire une carte de statistique
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Construire une puce de filtre
  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[800],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
