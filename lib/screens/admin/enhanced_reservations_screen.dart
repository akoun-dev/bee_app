import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../models/agent_model.dart';
import '../../models/reservation_model.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/admin_app_bar.dart';
import '../../widgets/admin_drawer.dart';

// Écran de gestion avancée des réservations pour les administrateurs
class EnhancedReservationsScreen extends StatefulWidget {
  const EnhancedReservationsScreen({super.key});

  @override
  State<EnhancedReservationsScreen> createState() => _EnhancedReservationsScreenState();
}

class _EnhancedReservationsScreenState extends State<EnhancedReservationsScreen> {
  // État
  final Map<String, AgentModel?> _agentsCache = {};
  final Map<String, UserModel?> _usersCache = {};
  final Set<String> _selectedReservations = {};

  // Filtres
  String _statusFilter = 'all'; // 'all', 'pending', 'approved', etc.
  DateTime? _startDateFilter;
  DateTime? _endDateFilter;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: AdminAppBar(
        title: 'Gestion des réservations',
        actions: [
          // Bouton pour les actions en masse
          if (_selectedReservations.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showBulkActions,
              tooltip: 'Actions en masse',
            ),
          // Bouton pour les filtres
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filtrer',
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher une réservation...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Filtres actifs
          if (_statusFilter != 'all' || _startDateFilter != null || _endDateFilter != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _buildActiveFilters(),
                ),
              ),
            ),

          // Liste des réservations
          Expanded(
            child: StreamBuilder<List<ReservationModel>>(
              stream: databaseService.getAllReservations(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator(message: 'Chargement des réservations...');
                }

                if (snapshot.hasError) {
                  return ErrorMessage(
                    message: 'Erreur: ${snapshot.error}',
                    onRetry: () => setState(() {}),
                  );
                }

                final reservations = snapshot.data ?? [];
                final filteredReservations = _filterReservations(reservations);

                if (filteredReservations.isEmpty) {
                  return const EmptyMessage(
                    message: 'Aucune réservation trouvée',
                    icon: Icons.event_busy,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredReservations.length,
                  itemBuilder: (context, index) {
                    final reservation = filteredReservations[index];
                    return _buildReservationItem(reservation);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Filtrer les réservations en fonction des critères
  List<ReservationModel> _filterReservations(List<ReservationModel> reservations) {
    return reservations.where((reservation) {
      // Filtre par statut
      if (_statusFilter != 'all' && reservation.status != _statusFilter) {
        return false;
      }

      // Filtre par date de début
      if (_startDateFilter != null && reservation.startDate.isBefore(_startDateFilter!)) {
        return false;
      }

      // Filtre par date de fin
      if (_endDateFilter != null && reservation.endDate.isAfter(_endDateFilter!)) {
        return false;
      }

      // Filtre par recherche
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return reservation.id.toLowerCase().contains(query) ||
               reservation.location.toLowerCase().contains(query) ||
               reservation.description.toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  // Construire les filtres actifs
  List<Widget> _buildActiveFilters() {
    final List<Widget> filters = [];
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Filtre de statut
    if (_statusFilter != 'all') {
      filters.add(
        Chip(
          label: Text(_getStatusText(_statusFilter)),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: () => setState(() => _statusFilter = 'all'),
          backgroundColor: AppTheme.primaryColor.withAlpha(50),
        ),
      );
    }

    // Filtre de date de début
    if (_startDateFilter != null) {
      filters.add(
        Chip(
          label: Text('Après ${dateFormat.format(_startDateFilter!)}'),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: () => setState(() => _startDateFilter = null),
          backgroundColor: AppTheme.accentColor.withAlpha(50),
        ),
      );
    }

    // Filtre de date de fin
    if (_endDateFilter != null) {
      filters.add(
        Chip(
          label: Text('Avant ${dateFormat.format(_endDateFilter!)}'),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: () => setState(() => _endDateFilter = null),
          backgroundColor: AppTheme.accentColor.withAlpha(50),
        ),
      );
    }

    return filters;
  }

  // Obtenir le texte du statut
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return AppConstants.pending;
      case 'approved':
        return AppConstants.approved;
      case 'rejected':
        return AppConstants.rejected;
      case 'completed':
        return AppConstants.completed;
      case 'cancelled':
        return AppConstants.cancelled;
      default:
        return status;
    }
  }

  // Construire un élément de réservation
  Widget _buildReservationItem(ReservationModel reservation) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getReservationDetails(reservation),
      builder: (context, snapshot) {
        final details = snapshot.data ?? {};
        final agent = details['agent'] as AgentModel?;
        final user = details['user'] as UserModel?;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: _selectedReservations.contains(reservation.id)
                ? BorderSide(color: AppTheme.primaryColor, width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            onLongPress: () => _toggleReservationSelection(reservation.id),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec statut et sélection
                  Row(
                    children: [
                      Checkbox(
                        value: _selectedReservations.contains(reservation.id),
                        onChanged: (value) => _toggleReservationSelection(reservation.id),
                      ),
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

                  // Informations sur l'utilisateur et l'agent
                  Row(
                    children: [
                      // Utilisateur
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Client:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                UserAvatar(
                                  imageUrl: user?.profileImageUrl,
                                  name: user?.fullName,
                                  size: 30,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    user?.fullName ?? 'Utilisateur inconnu',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Agent
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Agent:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                UserAvatar(
                                  imageUrl: agent?.profileImageUrl,
                                  name: agent?.fullName,
                                  size: 30,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    agent?.fullName ?? 'Agent inconnu',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Détails de la réservation
                  _buildInfoRow(
                    'Dates',
                    '${DateFormat(AppConstants.dateFormat).format(reservation.startDate)} - ${DateFormat(AppConstants.dateFormat).format(reservation.endDate)}',
                    Icons.calendar_today,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Lieu',
                    reservation.location,
                    Icons.location_on_outlined,
                  ),

                  const SizedBox(height: 16),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Bouton de détails
                      OutlinedButton.icon(
                        icon: const Icon(Icons.visibility),
                        label: const Text('Détails'),
                        onPressed: () => _showReservationDetails(reservation),
                      ),
                      const SizedBox(width: 8),

                      // Bouton d'action selon le statut
                      if (reservation.status == ReservationModel.statusPending)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text('Approuver'),
                          onPressed: () => _approveReservation(reservation),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Récupérer les détails d'une réservation (agent et utilisateur)
  Future<Map<String, dynamic>> _getReservationDetails(ReservationModel reservation) async {
    final Map<String, dynamic> details = {};

    // Stocker le service avant les opérations asynchrones
    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    // Récupérer l'agent
    if (_agentsCache.containsKey(reservation.agentId)) {
      details['agent'] = _agentsCache[reservation.agentId];
    } else {
      final agent = await databaseService.getAgent(reservation.agentId);
      if (mounted) {
        _agentsCache[reservation.agentId] = agent;
        details['agent'] = agent;
      }
    }

    // Récupérer l'utilisateur
    if (_usersCache.containsKey(reservation.userId)) {
      details['user'] = _usersCache[reservation.userId];
    } else {
      final user = await databaseService.getUser(reservation.userId);
      if (mounted) {
        _usersCache[reservation.userId] = user;
        details['user'] = user;
      }
    }

    return details;
  }

  // Construire une ligne d'information
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

  // Afficher le dialogue de filtres
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrer les réservations'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filtre par statut
                  const Text(
                    'Statut:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    value: _statusFilter,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(value: 'all', child: Text('Tous')),
                      DropdownMenuItem(
                        value: ReservationModel.statusPending,
                        child: Text(AppConstants.pending),
                      ),
                      DropdownMenuItem(
                        value: ReservationModel.statusApproved,
                        child: Text(AppConstants.approved),
                      ),
                      DropdownMenuItem(
                        value: ReservationModel.statusRejected,
                        child: Text(AppConstants.rejected),
                      ),
                      DropdownMenuItem(
                        value: ReservationModel.statusCompleted,
                        child: Text(AppConstants.completed),
                      ),
                      DropdownMenuItem(
                        value: ReservationModel.statusCancelled,
                        child: Text(AppConstants.cancelled),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _statusFilter = value!);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Filtre par date
                  const Text(
                    'Période:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Date de début
                  Row(
                    children: [
                      const Text('Du:'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            _startDateFilter != null
                                ? DateFormat('dd/MM/yyyy').format(_startDateFilter!)
                                : 'Sélectionner',
                          ),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _startDateFilter ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setState(() => _startDateFilter = date);
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  // Date de fin
                  Row(
                    children: [
                      const Text('Au:'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            _endDateFilter != null
                                ? DateFormat('dd/MM/yyyy').format(_endDateFilter!)
                                : 'Sélectionner',
                          ),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _endDateFilter ?? DateTime.now(),
                              firstDate: _startDateFilter ?? DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setState(() => _endDateFilter = date);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Réinitialiser les filtres
              setState(() {
                _statusFilter = 'all';
                _startDateFilter = null;
                _endDateFilter = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Réinitialiser'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Les filtres sont déjà appliqués via setState
            },
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }

  // Afficher les détails d'une réservation
  void _showReservationDetails(ReservationModel reservation) {
    // Naviguer vers l'écran de détails de la réservation
    context.go('/admin/reservation/${reservation.id}');
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

  // Basculer la sélection d'une réservation
  void _toggleReservationSelection(String reservationId) {
    setState(() {
      if (_selectedReservations.contains(reservationId)) {
        _selectedReservations.remove(reservationId);
      } else {
        _selectedReservations.add(reservationId);
      }
    });
  }

  // Afficher les actions en masse
  void _showBulkActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('Approuver toutes les sélections'),
              onTap: () {
                Navigator.pop(context);
                _bulkApprove();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Rejeter toutes les sélections'),
              onTap: () {
                Navigator.pop(context);
                _bulkReject();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Supprimer toutes les sélections'),
              onTap: () {
                Navigator.pop(context);
                _bulkDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Actions en masse
  Future<void> _bulkApprove() async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    int count = 0;

    try {
      // Pour chaque ID de réservation sélectionné
      for (final reservationId in _selectedReservations) {
        // Récupérer la réservation
        final reservation = await databaseService.getReservation(reservationId);

        // Si la réservation existe et est en attente
        if (reservation != null && reservation.status == ReservationModel.statusPending) {
          // Approuver la réservation
          final updatedReservation = reservation.approve();
          await databaseService.updateReservation(updatedReservation);
          count++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count réservations approuvées avec succès'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
        // Effacer les sélections
        setState(() => _selectedReservations.clear());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'approbation en masse: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _bulkReject() async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    int count = 0;

    try {
      // Pour chaque ID de réservation sélectionné
      for (final reservationId in _selectedReservations) {
        // Récupérer la réservation
        final reservation = await databaseService.getReservation(reservationId);

        // Si la réservation existe et est en attente
        if (reservation != null && reservation.status == ReservationModel.statusPending) {
          // Rejeter la réservation
          final updatedReservation = reservation.reject();
          await databaseService.updateReservation(updatedReservation);
          count++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count réservations rejetées avec succès'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
        // Effacer les sélections
        setState(() => _selectedReservations.clear());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du rejet en masse: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _bulkDelete() async {
    // Afficher une boîte de dialogue de confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${_selectedReservations.length} réservations ?'),
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
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;

    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    int count = 0;

    try {
      // Pour chaque ID de réservation sélectionné
      for (final reservationId in _selectedReservations) {
        // Récupérer la réservation
        final reservation = await databaseService.getReservation(reservationId);

        // Si la réservation existe
        if (reservation != null) {
          // Mettre à jour le statut à "annulé" (nous n'avons pas de méthode de suppression)
          final updatedReservation = reservation.cancel();
          await databaseService.updateReservation(updatedReservation);
          count++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count réservations annulées avec succès'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
        // Effacer les sélections
        setState(() => _selectedReservations.clear());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'annulation en masse: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
