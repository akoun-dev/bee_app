import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';

import '../models/reservation_model.dart';
import '../models/agent_model.dart';
import '../models/review_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../utils/theme.dart';
import 'common_widgets.dart';

// Dialogue pour évaluer un agent à la fin d'une réservation
class RatingDialog extends StatefulWidget {
  final ReservationModel reservation;
  final AgentModel agent;
  final Function() onSuccess;

  const RatingDialog({
    super.key,
    required this.reservation,
    required this.agent,
    required this.onSuccess,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  final _commentController = TextEditingController();
  double _rating = 5.0;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // Obtenir le texte correspondant à la note
  String _getRatingText() {
    if (_rating >= 5) return 'Excellent';
    if (_rating >= 4) return 'Très bien';
    if (_rating >= 3) return 'Bien';
    if (_rating >= 2) return 'Moyen';
    return 'À améliorer';
  }

  // Soumettre l'évaluation
  Future<void> _submitRating() async {
    // Vérifier que le commentaire n'est pas vide
    if (_commentController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer un commentaire';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final databaseService = Provider.of<DatabaseService>(
        context,
        listen: false,
      );

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
        agentId: widget.reservation.agentId,
        reservationId: widget.reservation.id,
        rating: _rating,
        comment: _commentController.text.trim(),
        createdAt: DateTime.now(),
        userFullName: userData?.fullName,
        userProfileImageUrl: userData?.profileImageUrl,
      );

      // Ajouter l'avis à la base de données
      await databaseService.addReview(review);

      // Fermer le dialogue et appeler le callback de succès
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Améliorer le message d'erreur pour l'utilisateur
          String errorMessage =
              'Une erreur est survenue lors de la soumission de votre avis.';

          if (e.toString().contains('permission-denied') ||
              e.toString().contains('PERMISSION_DENIED')) {
            errorMessage =
                'Vous n\'avez pas les permissions nécessaires pour soumettre cet avis. Veuillez vous reconnecter.';
          } else if (e.toString().contains('network')) {
            errorMessage =
                'Problème de connexion réseau. Vérifiez votre connexion internet.';
          } else if (e.toString().contains('not-found')) {
            errorMessage =
                'Les données de la réservation ou de l\'agent sont introuvables.';
          }

          _errorMessage = errorMessage;
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre
              const Text(
                'Évaluer votre expérience',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Informations sur l'agent
              Row(
                children: [
                  // Avatar de l'agent
                  const AgentAvatar(size: 50),
                  const SizedBox(width: 12),

                  // Nom et profession de l'agent
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.agent.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          widget.agent.profession,
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
              const SizedBox(height: 20),

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
                      itemBuilder:
                          (context, _) =>
                              const Icon(Icons.star, color: Colors.amber),
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
              const SizedBox(height: 20),

              // Champ de commentaire
              TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  labelText: 'Commentaire',
                  hintText: 'Partagez votre expérience avec cet agent...',
                  border: const OutlineInputBorder(),
                  errorText: _errorMessage,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // Boutons d'action
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Bouton d'annulation
                  TextButton(
                    onPressed:
                        _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 8),
                  // Bouton de soumission
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitRating,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child:
                        _isSubmitting
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text('Soumettre'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
