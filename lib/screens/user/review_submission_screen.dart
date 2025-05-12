import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../models/reservation_model.dart';
import '../../models/agent_model.dart';
import '../../models/review_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/common_widgets.dart';

// Écran de soumission d'avis pour une réservation terminée
class ReviewSubmissionScreen extends StatefulWidget {
  final String reservationId;

  const ReviewSubmissionScreen({
    super.key,
    required this.reservationId,
  });

  @override
  State<ReviewSubmissionScreen> createState() => _ReviewSubmissionScreenState();
}

class _ReviewSubmissionScreenState extends State<ReviewSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  double _rating = 5.0;

  ReservationModel? _reservation;
  AgentModel? _agent;

  @override
  void initState() {
    super.initState();
    _loadReservationDetails();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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
        throw Exception('Réservation introuvable');
      }

      // Vérifier si la réservation est terminée
      if (reservation.status != ReservationModel.statusCompleted) {
        throw Exception('Cette réservation n\'est pas encore terminée');
      }

      // Vérifier si la réservation a déjà été évaluée
      if (reservation.rating != null) {
        throw Exception('Cette réservation a déjà été évaluée');
      }

      // Récupérer les détails de l'agent
      final agent = await databaseService.getAgent(reservation.agentId);
      if (agent == null) {
        throw Exception('Agent introuvable');
      }

      if (mounted) {
        setState(() {
          _reservation = reservation;
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

  // Soumettre l'avis
  Future<void> _submitReview() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_reservation == null || _agent == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final databaseService = Provider.of<DatabaseService>(context, listen: false);

      final currentUser = authService.currentUser;
      if (currentUser == null) {
        throw Exception('Vous devez être connecté pour soumettre un avis');
      }

      // Récupérer les données de l'utilisateur
      final userData = await authService.getCurrentUserData();

      // Créer l'avis
      final review = ReviewModel(
        id: '', // Sera généré par Firestore
        userId: currentUser.uid,
        agentId: _reservation!.agentId,
        reservationId: _reservation!.id,
        rating: _rating,
        comment: _commentController.text.trim().isEmpty
            ? 'Aucun commentaire'
            : _commentController.text.trim(),
        createdAt: DateTime.now(),
        userFullName: userData?.fullName,
        userProfileImageUrl: userData?.profileImageUrl,
      );

      // Ajouter l'avis à la base de données
      await databaseService.addReview(review);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppConstants.successReview),
            backgroundColor: AppTheme.accentColor,
          ),
        );

        // Retourner à l'écran précédent
        context.go('/history');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Évaluer votre expérience'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Chargement des informations...')
          : _errorMessage != null
              ? ErrorMessage(
                  message: _errorMessage!,
                  onRetry: _loadReservationDetails,
                )
              : _buildReviewForm(),
    );
  }

  Widget _buildReviewForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec informations sur l'agent
            if (_agent != null) _buildAgentHeader(),

            const SizedBox(height: 24),

            // Section d'évaluation
            const Text(
              'Votre évaluation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Étoiles pour la notation
            Center(
              child: Column(
                children: [
                  RatingBar.builder(
                    initialRating: _rating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) => const Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    onRatingUpdate: (rating) {
                      setState(() {
                        _rating = rating;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getRatingText(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Champ de commentaire
            TextFormField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Commentaire',
                hintText: 'Partagez votre expérience avec cet agent...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer un commentaire';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Bouton de soumission
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Soumettre mon évaluation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Construire l'en-tête avec les informations de l'agent
  Widget _buildAgentHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Avatar de l'agent
          UserAvatar(
            imageUrl: _agent!.profileImageUrl,
            name: _agent!.fullName,
            size: 60,
          ),
          const SizedBox(width: 16),

          // Informations sur l'agent
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _agent!.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _agent!.profession,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                if (_agent!.averageRating > 0) ...[
                  const SizedBox(height: 4),
                  RatingDisplay(
                    rating: _agent!.averageRating,
                    ratingCount: _agent!.ratingCount,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Obtenir le texte correspondant à la note
  String _getRatingText() {
    if (_rating >= 5) return 'Excellent';
    if (_rating >= 4) return 'Très bien';
    if (_rating >= 3) return 'Bien';
    if (_rating >= 2) return 'Moyen';
    return 'À améliorer';
  }
}
