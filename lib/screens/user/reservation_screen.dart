import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/agent_model.dart';
import '../../models/reservation_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/agent_availability_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

// Écran de réservation d'un agent
class ReservationScreen extends StatefulWidget {
  final String agentId;

  const ReservationScreen({
    super.key,
    required this.agentId,
  });

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  // Contrôleurs pour les champs de texte
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Clé pour le formulaire
  final _formKey = GlobalKey<FormState>();

  // État
  AgentModel? _agent;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 2));

  // Protection contre les soumissions multiples
  DateTime? _lastSubmissionTime;

  @override
  void initState() {
    super.initState();
    _loadAgentDetails();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Charger les détails de l'agent avec vérification des permissions
  Future<void> _loadAgentDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final availabilityService = Provider.of<AgentAvailabilityService>(context, listen: false);

      final currentUser = authService.currentUser;
      if (currentUser == null) {
        throw Exception('Vous devez être connecté pour effectuer une réservation');
      }

      // Récupérer le profil utilisateur complet
      final userProfile = await databaseService.getUser(currentUser.uid);
      if (userProfile == null) {
        throw Exception('Profil utilisateur introuvable. Veuillez vous reconnecter.');
      }

      // Récupérer l'agent
      final agent = await databaseService.getAgent(widget.agentId);
      if (agent == null) {
        throw Exception('Agent introuvable');
      }

      // Vérifier les permissions de réservation
      final canReserve = await availabilityService.canReserveAgent(userProfile, widget.agentId);
      if (!canReserve) {
        throw Exception('Cet agent n\'est pas disponible pour le moment ou vous n\'avez pas la permission de le réserver.');
      }

      if (mounted) {
        setState(() {
          _agent = agent;
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

  // Sélectionner la date de début
  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // Si la date de fin est avant la date de début, ajuster la date de fin
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 1));
        }
      });
    }
  }

  // Sélectionner la date de fin
  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isAfter(_startDate) ? _endDate : _startDate.add(const Duration(days: 1)),
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  // Soumettre la réservation avec protection contre les soumissions multiples
  Future<void> _submitReservation() async {
    // Vérifier si le widget est encore monté
    if (!mounted) return;

    // Protection contre les soumissions multiples
    final now = DateTime.now();
    if (_lastSubmissionTime != null && 
        now.difference(_lastSubmissionTime!) < const Duration(seconds: 2)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez patienter avant de soumettre à nouveau...'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Valider le formulaire
    if (!_formKey.currentState!.validate()) return;

    // Vérifier que toutes les informations nécessaires sont présentes
    if (_agent == null) {
      setState(() {
        _errorMessage = 'Agent introuvable';
      });
      return;
    }

    // Vérifier que l'agent est disponible
    if (!_agent!.isAvailable) {
      setState(() {
        _errorMessage = 'Cet agent n\'est pas disponible pour le moment';
      });
      return;
    }

    // Vérifier que les dates sont valides
    if (_startDate.isAfter(_endDate)) {
      setState(() {
        _errorMessage = 'La date de début doit être avant la date de fin';
      });
      return;
    }

    // Vérifier que la durée minimale est respectée (1 jour)
    if (_endDate.difference(_startDate).inDays < 1) {
      setState(() {
        _errorMessage = 'La réservation doit durer au moins 1 jour';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _lastSubmissionTime = now;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final databaseService = Provider.of<DatabaseService>(context, listen: false);

      final currentUser = authService.currentUser;
      if (currentUser == null) {
        throw Exception('Vous devez être connecté pour effectuer une réservation');
      }

      // Vérifier que l'utilisateur a un profil complet
      final userProfile = await databaseService.getUser(currentUser.uid);
      if (userProfile == null) {
        throw Exception('Profil utilisateur incomplet. Veuillez compléter votre profil.');
      }

      // Créer la réservation
      final reservation = ReservationModel(
        id: '', // Sera généré par Firestore
        userId: currentUser.uid,
        agentId: widget.agentId,
        startDate: _startDate,
        endDate: _endDate,
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        status: ReservationModel.statusPending,
        createdAt: DateTime.now(),
      );

      // Ajouter un délai pour simuler le traitement et éviter les doubles soumissions
      await Future.delayed(const Duration(milliseconds: 500));

      // Ajouter la réservation à la base de données
      final reservationId = await databaseService.addReservation(reservation);

      if (mounted) {
        // Afficher un message de succès et rediriger
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppConstants.successReservation),
            backgroundColor: AppTheme.accentColor,
            duration: const Duration(seconds: 3),
          ),
        );

        // Rediriger vers l'historique avec un petit délai pour laisser le temps à l'utilisateur de voir le message
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            context.go('/history');
          }
        });
      }
    } catch (e) {
      // Extraire le message d'erreur plus proprement
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring('Exception: '.length);
      }

      if (mounted) {
        setState(() {
          _errorMessage = errorMessage;
        });

        // Afficher un message d'erreur plus visible
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $errorMessage'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // Vérifier si l'utilisateur peut soumettre une réservation
  Future<bool> _canSubmitReservation() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final availabilityService = Provider.of<AgentAvailabilityService>(context, listen: false);

      final currentUser = authService.currentUser;
      if (currentUser == null) {
        return false;
      }

      final userProfile = await Provider.of<DatabaseService>(context, listen: false)
          .getUser(currentUser.uid);
      if (userProfile == null) {
        return false;
      }

      // Les admins peuvent toujours soumettre
      if (userProfile.isAdmin) {
        return true;
      }

      // Les autres utilisateurs doivent vérifier la disponibilité
      return await availabilityService.canReserveAgent(userProfile, widget.agentId);
    } catch (e) {
      debugPrint('Erreur lors de la vérification de la soumission: $e');
      return false;
    }
  }

  // Gérer les actions administrateur
  void _handleAdminAction(String action) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final availabilityService = Provider.of<AgentAvailabilityService>(context, listen: false);

    final currentUser = authService.currentUser;
    if (currentUser == null) return;

    final userProfile = await Provider.of<DatabaseService>(context, listen: false)
        .getUser(currentUser.uid);
    if (userProfile == null || !availabilityService.canModifyAgentAvailability(userProfile)) {
      return;
    }

    switch (action) {
      case 'toggle_availability':
        _showToggleAvailabilityDialog();
        break;
      case 'view_logs':
        _showAvailabilityLogs();
        break;
    }
  }

  // Afficher le dialogue de basculement de disponibilité
  void _showToggleAvailabilityDialog() {
    if (_agent == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la disponibilité'),
        content: Text(
          'Voulez-vous ${_agent!.isAvailable ? 'rendre indisponible' : 'rendre disponible'} l\'agent ${_agent!.fullName} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final availabilityService = Provider.of<AgentAvailabilityService>(context, listen: false);
                
                if (_agent!.isAvailable) {
                  await availabilityService.setAgentManuallyUnavailable(
                    _agent!.id,
                    'Modification manuelle par administrateur',
                  );
                } else {
                  await availabilityService.setAgentManuallyAvailable(
                    _agent!.id,
                    'Modification manuelle par administrateur',
                  );
                }

                // Recharger les détails de l'agent
                _loadAgentDetails();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Disponibilité de l\'agent mise à jour avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur lors de la mise à jour: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  // Afficher les logs de disponibilité
  void _showAvailabilityLogs() {
    if (_agent == null) return;

    // Naviguer vers un écran de logs (à implémenter)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité des logs à implémenter'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final availabilityService = Provider.of<AgentAvailabilityService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.reservationTitle),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Afficher les actions admin si l'utilisateur est admin
          if (authService.currentUser != null) ...[
            FutureBuilder<UserModel?>(
              future: Provider.of<DatabaseService>(context, listen: false)
                  .getUser(authService.currentUser!.uid),
              builder: (context, snapshot) {
                final user = snapshot.data;
                if (user != null && availabilityService.canModifyAgentAvailability(user)) {
                  return PopupMenuButton<String>(
                    onSelected: (value) {
                      _handleAdminAction(value);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'toggle_availability',
                        child: Row(
                          children: [
                            Icon(Icons.sync),
                            SizedBox(width: 8),
                            Text('Forcer disponibilité'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'view_logs',
                        child: Row(
                          children: [
                            Icon(Icons.history),
                            SizedBox(width: 8),
                            Text('Voir les logs'),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des informations...'),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur: $_errorMessage',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAgentDetails,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _agent == null
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Agent introuvable',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    )
                  : _buildReservationForm(),
    );
  }

  Widget _buildReservationForm() {
    final dateFormat = DateFormat(AppConstants.dateFormat);
    final duration = _endDate.difference(_startDate).inDays + 1;
    final authService = Provider.of<AuthService>(context, listen: false);
    final availabilityService = Provider.of<AgentAvailabilityService>(context, listen: false);

    return FutureBuilder<UserModel?>(
      future: Provider.of<DatabaseService>(context, listen: false)
          .getUser(authService.currentUser!.uid),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        final canViewUnavailable = user != null && availabilityService.canViewUnavailableAgents(user);

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec informations sur l'agent
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(15),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // Avatar et informations de l'agent
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(40),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 35,
                            backgroundImage: _agent!.profileImageUrl != null
                                ? NetworkImage(_agent!.profileImageUrl!)
                                : null,
                            child: _agent!.profileImageUrl == null
                                ? Text(
                                    _agent!.fullName.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _agent!.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _agent!.profession,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Row(
                                    children: [
                                      Row(
                                        children: List.generate(5, (index) {
                                          return Icon(
                                            index < _agent!.averageRating.floor()
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: Colors.amber,
                                            size: 16,
                                          );
                                        }),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '(${_agent!.ratingCount})',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _agent!.isAvailable
                                          ? Colors.green.withAlpha(30)
                                          : Colors.red.withAlpha(30),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _agent!.isAvailable ? Icons.check_circle : Icons.cancel,
                                          size: 12,
                                          color: _agent!.isAvailable ? Colors.green : Colors.red,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _agent!.isAvailable ? 'Disponible' : 'Indisponible',
                                          style: TextStyle(
                                            color: _agent!.isAvailable ? Colors.green : Colors.red,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Afficher un avertissement si l'agent est indisponible et l'utilisateur n'est pas admin
                    if (!_agent!.isAvailable && !canViewUnavailable) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.warning,
                              color: Colors.orange,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Cet agent est actuellement indisponible à la réservation.',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Afficher les informations admin si l'utilisateur a les permissions
                    if (user != null && availabilityService.canModifyAgentAvailability(user)) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.admin_panel_settings,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Mode administrateur: Vous pouvez modifier la disponibilité de cet agent.',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Formulaire de réservation
              Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre du formulaire
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.edit_calendar,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Détails de la réservation',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Afficher le message d'erreur s'il y en a un
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.errorColor),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppTheme.errorColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: AppTheme.errorColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Sélection de dates
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(10),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Période de la mission',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Dates et durée
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: _selectStartDate,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey[300]!),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Début',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_today,
                                                size: 16,
                                                color: AppTheme.primaryColor,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                dateFormat.format(_startDate),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: _selectEndDate,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey[300]!),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Fin',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_today,
                                                size: 16,
                                                color: AppTheme.primaryColor,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                dateFormat.format(_endDate),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Durée de la mission
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withAlpha(15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.timelapse,
                                    size: 16,
                                    color: AppTheme.primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Durée: $duration ${duration > 1 ? 'jours' : 'jour'}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Lieu et description
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(10),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Informations de la mission',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Lieu
                            TextFormField(
                              controller: _locationController,
                              decoration: InputDecoration(
                                labelText: AppConstants.location,
                                prefixIcon: const Icon(Icons.location_on),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer le lieu de la mission';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Description
                            TextFormField(
                              controller: _descriptionController,
                              decoration: InputDecoration(
                                labelText: AppConstants.description,
                                prefixIcon: const Icon(Icons.description),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              maxLines: 5,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer une description de la mission';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Bouton de soumission avec vérification des permissions
                      FutureBuilder<bool>(
                        future: _canSubmitReservation(),
                        builder: (context, snapshot) {
                          final canSubmit = snapshot.data ?? false;
                          
                          return ElevatedButton(
                            onPressed: canSubmit ? () {
                              _submitReservation();
                            } : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(AppConstants.submitReservation),
                          );
                        },
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  },
);
}
}
