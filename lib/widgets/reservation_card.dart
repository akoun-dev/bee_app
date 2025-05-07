import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reservation_model.dart';
import '../models/agent_model.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import 'common_widgets.dart';

// Widget pour afficher une carte de réservation dans l'historique
class ReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  final AgentModel? agent;
  final VoidCallback? onRatePressed;
  final VoidCallback? onCancelPressed;

  const ReservationCard({
    super.key,
    required this.reservation,
    this.agent,
    this.onRatePressed,
    this.onCancelPressed,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat(AppConstants.dateFormat);
    final bool canRate = reservation.status == ReservationModel.statusCompleted &&
                         reservation.rating == null;
    final bool canCancel = reservation.status == ReservationModel.statusPending ||
                           reservation.status == ReservationModel.statusApproved;

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
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête coloré avec statut
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              border: Border(
                left: BorderSide(
                  color: statusColor,
                  width: 4,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Réservation #${reservation.id.substring(0, 6)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Créée le ${DateFormat('dd/MM/yyyy').format(reservation.createdAt)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: reservation.status),
              ],
            ),
          ),

          // Contenu principal
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations sur l'agent
                if (agent != null) ...[
                  Row(
                    children: [
                      UserAvatar(
                        imageUrl: agent!.profileImageUrl,
                        name: agent!.fullName,
                        size: 50,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              agent!.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              agent!.profession,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                ],

                // Détails de la réservation dans une grille
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildInfoCard(
                      'Dates',
                      '${dateFormat.format(reservation.startDate)} - ${dateFormat.format(reservation.endDate)}',
                      Icons.calendar_today,
                      statusColor,
                    ),
                    _buildInfoCard(
                      'Lieu',
                      reservation.location,
                      Icons.location_on_outlined,
                      statusColor,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Description
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 16,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Description',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        reservation.description,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),

                // Afficher la note si disponible
                if (reservation.rating != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.amber.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Votre évaluation',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            RatingDisplay(
                              rating: reservation.rating!,
                              ratingCount: 0,
                              showCount: false,
                            ),
                          ],
                        ),
                        if (reservation.comment != null && reservation.comment!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            reservation.comment!,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // Actions
                if (canRate || canCancel) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (canCancel)
                        OutlinedButton.icon(
                          onPressed: onCancelPressed,
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('Annuler'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.errorColor,
                            side: const BorderSide(color: AppTheme.errorColor),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      if (canCancel && canRate)
                        const SizedBox(width: 12),
                      if (canRate)
                        ElevatedButton.icon(
                          onPressed: onRatePressed,
                          icon: const Icon(Icons.star_outline, size: 18),
                          label: const Text('Évaluer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Construire une carte d'information
  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

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
