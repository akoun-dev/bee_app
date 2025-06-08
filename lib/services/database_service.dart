import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/agent_model.dart';
import '../models/reservation_model.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';

// Service pour gérer les opérations de base de données Firestore
class DatabaseService {
  // Nous n'utilisons pas directement _firestore, mais nous utilisons les références de collection

  // Collections
  final CollectionReference _usersCollection = FirebaseFirestore.instance
      .collection('users');
  final CollectionReference _agentsCollection = FirebaseFirestore.instance
      .collection('agents');
  final CollectionReference _reservationsCollection = FirebaseFirestore.instance
      .collection('reservations');
  final CollectionReference _reviewsCollection = FirebaseFirestore.instance
      .collection('reviews');

  // ===== UTILISATEURS =====

  // Récupérer un utilisateur par ID
  Future<UserModel?> getUser(String userId) async {
    try {
      final docSnapshot = await _usersCollection.doc(userId).get();
      if (!docSnapshot.exists) return null;

      return UserModel.fromMap(
        docSnapshot.data() as Map<String, dynamic>,
        docSnapshot.id,
      );
    } catch (e) {
      // Utiliser un logger en production au lieu de print
      // Logger.error('Erreur lors de la récupération de l\'utilisateur: ${e.toString()}');
      return null;
    }
  }

  // Récupérer tous les utilisateurs (pour admin)
  Stream<List<UserModel>> getAllUsers() {
    // Version simplifiée sans tri par date (en attendant que l'index soit créé)
    return _usersCollection.snapshots().map(
      (snapshot) =>
          snapshot.docs
              .map(
                (doc) => UserModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
    );

    // Décommentez cette version une fois que l'index est créé :
    /*
    return _usersCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
    */
  }

  // Récupérer tous les utilisateurs non-admin (pour admin)
  Stream<List<UserModel>> getNonAdminUsers() {
    // Version simplifiée sans tri par date (en attendant que l'index soit créé)
    return _usersCollection
        .where('isAdmin', isEqualTo: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => UserModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList(),
        );

    // Décommentez cette version une fois que l'index est créé :
    /*
    return _usersCollection
        .where('isAdmin', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
    */
  }

  // Mettre à jour un utilisateur
  Future<void> updateUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).update(user.toMap());
    } catch (e) {
      throw Exception(
        'Erreur lors de la mise à jour de l\'utilisateur: ${e.toString()}',
      );
    }
  }

  // Supprimer un utilisateur
  Future<void> deleteUser(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
    } catch (e) {
      throw Exception(
        'Erreur lors de la suppression de l\'utilisateur: ${e.toString()}',
      );
    }
  }

  // ===== AGENTS =====

  // Récupérer tous les agents
  Stream<List<AgentModel>> getAgents() {
    return _agentsCollection
        .orderBy('fullName')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => AgentModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList(),
        );
  }

  // Récupérer les agents disponibles
  Stream<List<AgentModel>> getAvailableAgents() {
    return _agentsCollection
        .where('isAvailable', isEqualTo: true)
        .orderBy('fullName')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => AgentModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList(),
        );
  }

  // Récupérer les agents certifiés
  Stream<List<AgentModel>> getCertifiedAgents() {
    return _agentsCollection
        .where('isCertified', isEqualTo: true)
        .orderBy('fullName')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => AgentModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList(),
        );
  }

  // Récupérer les agents disponibles et certifiés
  Stream<List<AgentModel>> getAvailableCertifiedAgents() {
    return _agentsCollection
        .where('isAvailable', isEqualTo: true)
        .where('isCertified', isEqualTo: true)
        .orderBy('fullName')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => AgentModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList(),
        );
  }

  // Récupérer les agents par profession
  Stream<List<AgentModel>> getAgentsByProfession(String profession) {
    return _agentsCollection
        .where('profession', isEqualTo: profession)
        .orderBy('fullName')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => AgentModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList(),
        );
  }

  // Récupérer les professions disponibles
  Future<List<String>> getAvailableProfessions() async {
    try {
      final querySnapshot = await _agentsCollection.get();

      // Extraire toutes les professions uniques
      final Set<String> professions = {};
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['profession'] != null &&
            data['profession'].toString().isNotEmpty) {
          professions.add(data['profession'].toString());
        }
      }

      // Convertir en liste et trier
      final result = professions.toList()..sort();
      return result;
    } catch (e) {
      // Logger.error('Erreur lors de la récupération des professions: ${e.toString()}');
      return [];
    }
  }

  // Récupérer un agent par ID
  Future<AgentModel?> getAgent(String agentId) async {
    try {
      final docSnapshot = await _agentsCollection.doc(agentId).get();
      if (!docSnapshot.exists) return null;

      return AgentModel.fromMap(
        docSnapshot.data() as Map<String, dynamic>,
        docSnapshot.id,
      );
    } catch (e) {
      // Utiliser un logger en production au lieu de print
      // Logger.error('Erreur lors de la récupération de l\'agent: ${e.toString()}');
      return null;
    }
  }

  // Récupérer un agent par matricule
  Future<AgentModel?> getAgentByMatricule(String matricule) async {
    try {
      final querySnapshot =
          await _agentsCollection
              .where('matricule', isEqualTo: matricule)
              .limit(1)
              .get();

      if (querySnapshot.docs.isEmpty) return null;

      final doc = querySnapshot.docs.first;
      return AgentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      // Utiliser un logger en production au lieu de print
      // Logger.error('Erreur lors de la récupération de l\'agent par matricule: ${e.toString()}');
      return null;
    }
  }

  // Ajouter un nouvel agent
  Future<String> addAgent(AgentModel agent) async {
    try {
      final docRef = await _agentsCollection.add(agent.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de l\'agent: ${e.toString()}');
    }
  }

  // Mettre à jour un agent
  Future<void> updateAgent(AgentModel agent) async {
    try {
      // Vérifier que l'agent existe avant la mise à jour
      final docSnapshot = await _agentsCollection.doc(agent.id).get();
      if (!docSnapshot.exists) {
        throw Exception('Agent introuvable avec l\'ID: ${agent.id}');
      }

      // Effectuer la mise à jour
      await _agentsCollection.doc(agent.id).update(agent.toMap());
    } catch (e) {
      throw Exception(
        'Erreur lors de la mise à jour de l\'agent: ${e.toString()}',
      );
    }
  }

  // Supprimer un agent
  Future<void> deleteAgent(String agentId) async {
    try {
      await _agentsCollection.doc(agentId).delete();
    } catch (e) {
      throw Exception(
        'Erreur lors de la suppression de l\'agent: ${e.toString()}',
      );
    }
  }

  // ===== RÉSERVATIONS =====

  // Récupérer les réservations d'un utilisateur
  Stream<List<ReservationModel>> getUserReservations(String userId) {
    return _reservationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => ReservationModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList(),
        );
  }

  // Récupérer toutes les réservations en attente (pour admin)
  Stream<List<ReservationModel>> getPendingReservations() {
    return _reservationsCollection
        .where('status', isEqualTo: ReservationModel.statusPending)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => ReservationModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList(),
        );
  }

  // Récupérer toutes les réservations (pour admin)
  Stream<List<ReservationModel>> getAllReservations() {
    return _reservationsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => ReservationModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList(),
        );
  }

  // Récupérer les réservations en cours (approuvées et non terminées)
  Stream<List<ReservationModel>> getActiveReservations() {
    final now = DateTime.now();

    return _reservationsCollection
        .where('status', isEqualTo: ReservationModel.statusApproved)
        .orderBy('startDate')
        .snapshots()
        .map((snapshot) {
          final reservations =
              snapshot.docs
                  .map(
                    (doc) => ReservationModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList();

          // Filtrer pour ne garder que les réservations dont la date de fin est dans le futur
          // et la date de début est passée (réservations en cours)
          return reservations
              .where(
                (reservation) =>
                    reservation.startDate.isBefore(now) &&
                    reservation.endDate.isAfter(now),
              )
              .toList();
        });
  }

  // Vérifier si un agent a des réservations en cours
  Future<bool> hasActiveReservations(String agentId) async {
    try {
      // Rechercher les réservations qui sont en cours ou à venir
      final querySnapshot =
          await _reservationsCollection
              .where('agentId', isEqualTo: agentId)
              .where(
                'status',
                whereIn: [
                  ReservationModel.statusPending,
                  ReservationModel.statusApproved,
                ],
              )
              .get();

      // Vérifier si des réservations existent
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      // Logger.error('Erreur lors de la vérification des réservations: ${e.toString()}');
      return false;
    }
  }

  // Récupérer les agents qui ont des réservations en cours
  Stream<List<AgentModel>> getAgentsWithReservations() async* {
    try {
      // Récupérer tous les agents
      final agents = await _agentsCollection.get();

      // Récupérer toutes les réservations actives
      final activeReservations =
          await _reservationsCollection
              .where(
                'status',
                whereIn: [
                  ReservationModel.statusPending,
                  ReservationModel.statusApproved,
                ],
              )
              .get();

      // Créer un ensemble des IDs d'agents avec des réservations actives
      final Set<String> agentIdsWithReservations = {};
      for (var doc in activeReservations.docs) {
        final reservation = ReservationModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        agentIdsWithReservations.add(reservation.agentId);
      }

      // Filtrer les agents qui ont des réservations actives
      final agentsWithReservations =
          agents.docs
              .where((doc) => agentIdsWithReservations.contains(doc.id))
              .map(
                (doc) => AgentModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();

      yield agentsWithReservations;
    } catch (e) {
      // Logger.error('Erreur lors de la récupération des agents avec réservations: ${e.toString()}');
      yield [];
    }
  }

  // Récupérer une réservation par ID
  Future<ReservationModel?> getReservation(String reservationId) async {
    try {
      final docSnapshot =
          await _reservationsCollection.doc(reservationId).get();
      if (!docSnapshot.exists) return null;

      return ReservationModel.fromMap(
        docSnapshot.data() as Map<String, dynamic>,
        docSnapshot.id,
      );
    } catch (e) {
      // Utiliser un logger en production au lieu de print
      // Logger.error('Erreur lors de la récupération de la réservation: ${e.toString()}');
      return null;
    }
  }

  // Ajouter une nouvelle réservation
  Future<String> addReservation(ReservationModel reservation) async {
    try {
      final docRef = await _reservationsCollection.add(reservation.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception(
        'Erreur lors de l\'ajout de la réservation: ${e.toString()}',
      );
    }
  }

  // Mettre à jour une réservation
  Future<void> updateReservation(ReservationModel reservation) async {
    try {
      await _reservationsCollection
          .doc(reservation.id)
          .update(reservation.toMap());
    } catch (e) {
      throw Exception(
        'Erreur lors de la mise à jour de la réservation: ${e.toString()}',
      );
    }
  }

  // ===== AVIS ET COMMENTAIRES =====

  // Récupérer les avis pour un agent
  Stream<List<ReviewModel>> getAgentReviews(String agentId) {
    return _reviewsCollection
        .where('agentId', isEqualTo: agentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => ReviewModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList(),
        );
  }

  // Ajouter un nouvel avis
  Future<String> addReview(ReviewModel review) async {
    try {
      // Vérifier que l'agent existe
      final agent = await getAgent(review.agentId);
      if (agent == null) {
        throw Exception('Agent introuvable avec l\'ID: ${review.agentId}');
      }

      // Vérifier que la réservation existe
      final reservation = await getReservation(review.reservationId);
      if (reservation == null) {
        throw Exception(
          'Réservation introuvable avec l\'ID: ${review.reservationId}',
        );
      }

      // Ajouter l'avis
      final docRef = await _reviewsCollection.add(review.toMap());

      // Essayer de mettre à jour la note moyenne de l'agent
      try {
        final updatedAgent = agent.updateRating(review.rating);
        await updateAgent(updatedAgent);
      } catch (agentUpdateError) {
        // Si la mise à jour de l'agent échoue, on continue quand même
        // L'avis a été créé avec succès, c'est le plus important
        print(
          'Avertissement: Impossible de mettre à jour la note de l\'agent: $agentUpdateError',
        );
      }

      // Essayer de mettre à jour la réservation avec la note et le commentaire
      try {
        final updatedReservation = reservation.addRating(
          review.rating,
          review.comment,
        );
        await updateReservation(updatedReservation);
      } catch (reservationUpdateError) {
        // Si la mise à jour de la réservation échoue, on continue quand même
        print(
          'Avertissement: Impossible de mettre à jour la réservation: $reservationUpdateError',
        );
      }

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de l\'avis: ${e.toString()}');
    }
  }

  // Recalculer la note moyenne d'un agent basée sur tous ses avis
  Future<void> recalculateAgentRating(String agentId) async {
    try {
      // Récupérer tous les avis pour cet agent
      final reviewsSnapshot =
          await _reviewsCollection.where('agentId', isEqualTo: agentId).get();

      if (reviewsSnapshot.docs.isEmpty) {
        // Aucun avis, remettre à zéro
        final agent = await getAgent(agentId);
        if (agent != null) {
          final updatedAgent = agent.copyWith(
            averageRating: 0.0,
            ratingCount: 0,
          );
          await updateAgent(updatedAgent);
        }
        return;
      }

      // Calculer la nouvelle moyenne
      double totalRating = 0.0;
      int count = 0;

      for (var doc in reviewsSnapshot.docs) {
        final review = ReviewModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        totalRating += review.rating;
        count++;
      }

      final newAverage = totalRating / count;

      // Mettre à jour l'agent
      final agent = await getAgent(agentId);
      if (agent != null) {
        final updatedAgent = agent.copyWith(
          averageRating: newAverage,
          ratingCount: count,
        );
        await updateAgent(updatedAgent);
      }
    } catch (e) {
      throw Exception(
        'Erreur lors du recalcul de la note de l\'agent: ${e.toString()}',
      );
    }
  }

  // ===== STATISTIQUES (POUR ADMIN) =====

  // Obtenir des statistiques générales
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      // Nombre total d'agents
      final agentsSnapshot = await _agentsCollection.get();
      final agentsCount = agentsSnapshot.size;

      // Nombre total d'utilisateurs (non-admin)
      final usersSnapshot =
          await _usersCollection.where('isAdmin', isEqualTo: false).get();
      final usersCount = usersSnapshot.size;

      // Nombre total de réservations
      final reservationsSnapshot = await _reservationsCollection.get();
      final reservationsCount = reservationsSnapshot.size;

      // Nombre de réservations par statut
      final pendingSnapshot =
          await _reservationsCollection
              .where('status', isEqualTo: ReservationModel.statusPending)
              .get();
      final approvedSnapshot =
          await _reservationsCollection
              .where('status', isEqualTo: ReservationModel.statusApproved)
              .get();
      final completedSnapshot =
          await _reservationsCollection
              .where('status', isEqualTo: ReservationModel.statusCompleted)
              .get();

      return {
        'agentsCount': agentsCount,
        'usersCount': usersCount,
        'reservationsCount': reservationsCount,
        'pendingCount': pendingSnapshot.size,
        'approvedCount': approvedSnapshot.size,
        'completedCount': completedSnapshot.size,
      };
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des statistiques: ${e.toString()}',
      );
    }
  }
}
