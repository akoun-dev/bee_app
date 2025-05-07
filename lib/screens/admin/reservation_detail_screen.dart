import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/agent_model.dart';
import '../../models/reservation_model.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/admin_app_bar.dart';
import '../../widgets/admin_drawer.dart';

// Écran de détails d'une réservation (pour admin)
class ReservationDetailScreen extends StatefulWidget {
  final String reservationId;

  const ReservationDetailScreen({
    super.key,
    required this.reservationId,
  });

  @override
  State<ReservationDetailScreen> createState() => _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  // État
  ReservationModel? _reservation;
  AgentModel? _agent;
  UserModel? _user;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReservationDetails();
  }

  // Charger les détails de la réservation
  Future<void> _loadReservationDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);

      // Récupérer la réservation
      final reservation = await databaseService.getReservation(widget.reservationId);

      if (reservation == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Réservation non trouvée';
        });
        return;
      }

      // Récupérer l'agent
      final agent = await databaseService.getAgent(reservation.agentId);

      // Récupérer l'utilisateur
      final user = await databaseService.getUser(reservation.userId);

      if (mounted) {
        setState(() {
          _reservation = reservation;
          _agent = agent;
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erreur lors du chargement des détails: ${e.toString()}';
        });
      }
    }
  }

  // Approuver une réservation
  Future<void> _approveReservation() async {
    if (_reservation == null) return;

    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);

      // Mettre à jour le statut de la réservation
      final updatedReservation = _reservation!.approve();
      await databaseService.updateReservation(updatedReservation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Réservation approuvée avec succès'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
        // Recharger les détails
        _loadReservationDetails();
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
  Future<void> _rejectReservation() async {
    if (_reservation == null) return;

    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);

      // Mettre à jour le statut de la réservation
      final updatedReservation = _reservation!.reject();
      await databaseService.updateReservation(updatedReservation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Réservation rejetée'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
        // Recharger les détails
        _loadReservationDetails();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminAppBar(
        title: 'Détails de la réservation',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReservationDetails,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: _isLoading
          ? const LoadingIndicator(
              message: 'Chargement des détails de la réservation...',
            )
          : _errorMessage != null
              ? ErrorMessage(
                  message: _errorMessage!,
                  onRetry: _loadReservationDetails,
                )
              : _buildReservationDetails(),
    );
  }

  // Construire les détails de la réservation
  Widget _buildReservationDetails() {
    if (_reservation == null) {
      return const EmptyMessage(
        message: 'Réservation non trouvée',
        icon: Icons.error_outline,
      );
    }

    final dateFormat = DateFormat(AppConstants.dateFormat);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec ID et statut
          Row(
            children: [
              Expanded(
                child: Text(
                  'Réservation #${_reservation!.id.substring(0, 6)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              StatusBadge(status: _reservation!.status),
            ],
          ),

          const Divider(height: 24),

          // Détails de la réservation
          _buildInfoRow(
            'Dates',
            '${dateFormat.format(_reservation!.startDate)} - ${dateFormat.format(_reservation!.endDate)}',
            Icons.calendar_today,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Lieu',
            _reservation!.location,
            Icons.location_on_outlined,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Description',
            _reservation!.description,
            Icons.description_outlined,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Date de création',
            dateFormat.format(_reservation!.createdAt),
            Icons.access_time,
          ),

          const Divider(height: 24),

          // Informations sur l'agent
          if (_agent != null) ...[
            const Text(
              'Agent',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                UserAvatar(
                  imageUrl: _agent!.profileImageUrl,
                  name: _agent!.fullName,
                  size: 50,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _agent!.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _agent!.profession,
                        style: const TextStyle(
                          color: AppTheme.mediumColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RatingDisplay(
                        rating: _agent!.averageRating,
                        ratingCount: _agent!.ratingCount,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else
            const Text('Informations de l\'agent non disponibles'),

          const SizedBox(height: 24),

          // Informations sur l'utilisateur
          if (_user != null) ...[
            const Text(
              'Client',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                UserAvatar(
                  imageUrl: _user!.profileImageUrl,
                  name: _user!.fullName,
                  size: 50,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user!.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _user!.email,
                        style: const TextStyle(
                          color: AppTheme.mediumColor,
                          fontSize: 14,
                        ),
                      ),
                      if (_user!.phoneNumber != null && _user!.phoneNumber!.isNotEmpty)
                        Text(
                          _user!.phoneNumber!,
                          style: const TextStyle(
                            color: AppTheme.mediumColor,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ] else
            const Text('Informations du client non disponibles'),

          const SizedBox(height: 32),

          // Boutons d'action (uniquement pour les réservations en attente)
          if (_reservation!.status == 'pending')
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _rejectReservation,
                  icon: const Icon(Icons.close),
                  label: const Text(AppConstants.rejectReservation),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    side: const BorderSide(color: AppTheme.errorColor),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _approveReservation,
                  icon: const Icon(Icons.check),
                  label: const Text(AppConstants.approveReservation),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
        ],
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
          size: 20,
          color: AppTheme.mediumColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.mediumColor,
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
