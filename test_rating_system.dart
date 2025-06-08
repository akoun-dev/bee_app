import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'lib/models/agent_model.dart';
import 'lib/models/reservation_model.dart';
import 'lib/models/review_model.dart';
import 'lib/services/database_service.dart';
import 'lib/services/auth_service.dart';
import 'lib/widgets/rating_dialog.dart';

// Script de test pour vérifier le système de notation
class RatingSystemTest extends StatefulWidget {
  const RatingSystemTest({super.key});

  @override
  State<RatingSystemTest> createState() => _RatingSystemTestState();
}

class _RatingSystemTestState extends State<RatingSystemTest> {
  String _testResult = 'Prêt pour le test...';
  bool _isLoading = false;

  // Test de création d'un avis
  Future<void> _testCreateReview() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Test en cours...';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final databaseService = Provider.of<DatabaseService>(context, listen: false);

      final currentUser = authService.currentUser;
      if (currentUser == null) {
        setState(() {
          _testResult = 'Erreur: Utilisateur non connecté';
          _isLoading = false;
        });
        return;
      }

      // Récupérer les données utilisateur
      final userData = await authService.getCurrentUserData();
      if (userData == null) {
        setState(() {
          _testResult = 'Erreur: Impossible de récupérer les données utilisateur';
          _isLoading = false;
        });
        return;
      }

      // Créer un avis de test
      final testReview = ReviewModel(
        id: '', // Sera généré par Firestore
        userId: currentUser.uid,
        agentId: 'test_agent_id', // Remplacez par un ID d'agent réel
        reservationId: 'test_reservation_id', // Remplacez par un ID de réservation réel
        rating: 4.5,
        comment: 'Test automatique du système de notation - ${DateTime.now()}',
        createdAt: DateTime.now(),
        userFullName: userData.fullName,
        userProfileImageUrl: userData.profileImageUrl,
      );

      // Essayer d'ajouter l'avis
      final reviewId = await databaseService.addReview(testReview);

      setState(() {
        _testResult = 'Succès! Avis créé avec l\'ID: $reviewId';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResult = 'Erreur lors du test: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Test de recalcul des notes
  Future<void> _testRecalculateRating() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Recalcul en cours...';
    });

    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);

      // Recalculer pour un agent de test
      await databaseService.recalculateAgentRating('test_agent_id');

      setState(() {
        _testResult = 'Succès! Note de l\'agent recalculée';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResult = 'Erreur lors du recalcul: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Test d'ouverture du dialogue de notation
  void _testRatingDialog() {
    // Créer des données de test
    final testAgent = AgentModel(
      id: 'test_agent_id',
      fullName: 'Agent Test',
      age: 30,
      gender: 'M',
      bloodType: 'O+',
      profession: 'Garde du corps',
      background: 'Test',
      educationLevel: 'Universitaire',
      isCertified: true,
      matricule: 'TEST001',
      createdAt: DateTime.now(),
    );

    final testReservation = ReservationModel(
      id: 'test_reservation_id',
      userId: 'test_user_id',
      agentId: 'test_agent_id',
      startDate: DateTime.now().subtract(const Duration(days: 1)),
      endDate: DateTime.now(),
      location: 'Test Location',
      description: 'Test Description',
      status: ReservationModel.statusCompleted,
      createdAt: DateTime.now(),
    );

    showDialog(
      context: context,
      builder: (context) => RatingDialog(
        reservation: testReservation,
        agent: testAgent,
        onSuccess: () {
          setState(() {
            _testResult = 'Dialogue de notation fermé avec succès!';
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test du Système de Notation'),
        backgroundColor: Colors.amber,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Résultat du test:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _testResult,
                      style: TextStyle(
                        fontSize: 14,
                        color: _testResult.startsWith('Erreur') 
                            ? Colors.red 
                            : _testResult.startsWith('Succès') 
                                ? Colors.green 
                                : Colors.black,
                      ),
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _testCreateReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Tester la création d\'avis',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _testRecalculateRating,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Tester le recalcul des notes',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _testRatingDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Tester le dialogue de notation',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Assurez-vous d\'être connecté\n'
                      '2. Remplacez les IDs de test par de vrais IDs\n'
                      '3. Testez chaque fonctionnalité\n'
                      '4. Vérifiez les permissions Firestore',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
