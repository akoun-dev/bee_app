import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/agent_model.dart';
import '../models/reservation_model.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';

// Service pour gérer les opérations de base de données Firestore
class DatabaseService {
  // Nous n'utilisons pas directement _firestore, mais nous utilisons les références de collection

  // Collections
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');
  final CollectionReference _agentsCollection =
      FirebaseFirestore.instance.collection('agents');
  final CollectionReference _reservationsCollection =
      FirebaseFirestore.instance.collection('reservations');
  final CollectionReference _reviewsCollection =
      FirebaseFirestore.instance.collection('reviews');

  // ===== UTILISATEURS =====

  // Récupérer un utilisateur par ID
  Future<UserModel?> getUser(String userId) async {
    try {
      final docSnapshot = await _usersCollection.doc(userId).get();
      if (!docSnapshot.exists) return null;

      return UserModel.fromMap(
        docSnapshot.data() as Map<String, dynamic>,
        docSnapshot.id
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
    return _usersCollection
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());

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
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());

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
      throw Exception('Erreur lors de la mise à jour de l\'utilisateur: ${e.toString()}');
    }
  }

  // Supprimer un utilisateur
  Future<void> deleteUser(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'utilisateur: ${e.toString()}');
    }
  }

  // ===== AGENTS =====

  // Récupérer tous les agents
  Stream<List<AgentModel>> getAgents() {
    return _agentsCollection
        .orderBy('fullName')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AgentModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Récupérer les agents disponibles
  Stream<List<AgentModel>> getAvailableAgents() {
    return _agentsCollection
        .where('isAvailable', isEqualTo: true)
        .orderBy('fullName')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AgentModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Récupérer un agent par ID
  Future<AgentModel?> getAgent(String agentId) async {
    try {
      final docSnapshot = await _agentsCollection.doc(agentId).get();
      if (!docSnapshot.exists) return null;

      return AgentModel.fromMap(
        docSnapshot.data() as Map<String, dynamic>,
        docSnapshot.id
      );
    } catch (e) {
      // Utiliser un logger en production au lieu de print
      // Logger.error('Erreur lors de la récupération de l\'agent: ${e.toString()}');
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
      await _agentsCollection.doc(agent.id).update(agent.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'agent: ${e.toString()}');
    }
  }

  // Supprimer un agent
  Future<void> deleteAgent(String agentId) async {
    try {
      await _agentsCollection.doc(agentId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'agent: ${e.toString()}');
    }
  }

  // ===== RÉSERVATIONS =====

  // Récupérer les réservations d'un utilisateur
  Stream<List<ReservationModel>> getUserReservations(String userId) {
    return _reservationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReservationModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Récupérer toutes les réservations en attente (pour admin)
  Stream<List<ReservationModel>> getPendingReservations() {
    return _reservationsCollection
        .where('status', isEqualTo: ReservationModel.statusPending)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReservationModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Récupérer toutes les réservations (pour admin)
  Stream<List<ReservationModel>> getAllReservations() {
    return _reservationsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReservationModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Récupérer une réservation par ID
  Future<ReservationModel?> getReservation(String reservationId) async {
    try {
      final docSnapshot = await _reservationsCollection.doc(reservationId).get();
      if (!docSnapshot.exists) return null;

      return ReservationModel.fromMap(
        docSnapshot.data() as Map<String, dynamic>,
        docSnapshot.id
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
      throw Exception('Erreur lors de l\'ajout de la réservation: ${e.toString()}');
    }
  }

  // Mettre à jour une réservation
  Future<void> updateReservation(ReservationModel reservation) async {
    try {
      await _reservationsCollection.doc(reservation.id).update(reservation.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la réservation: ${e.toString()}');
    }
  }

  // ===== AVIS ET COMMENTAIRES =====

  // Récupérer les avis pour un agent
  Stream<List<ReviewModel>> getAgentReviews(String agentId) {
    return _reviewsCollection
        .where('agentId', isEqualTo: agentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Ajouter un nouvel avis
  Future<String> addReview(ReviewModel review) async {
    try {
      // Ajouter l'avis
      final docRef = await _reviewsCollection.add(review.toMap());

      // Mettre à jour la note moyenne de l'agent
      final agent = await getAgent(review.agentId);
      if (agent != null) {
        final updatedAgent = agent.updateRating(review.rating);
        await updateAgent(updatedAgent);
      }

      // Mettre à jour la réservation avec la note et le commentaire
      final reservation = await getReservation(review.reservationId);
      if (reservation != null) {
        final updatedReservation = reservation.addRating(
          review.rating,
          review.comment
        );
        await updateReservation(updatedReservation);
      }

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de l\'avis: ${e.toString()}');
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
      final usersSnapshot = await _usersCollection
          .where('isAdmin', isEqualTo: false)
          .get();
      final usersCount = usersSnapshot.size;

      // Nombre total de réservations
      final reservationsSnapshot = await _reservationsCollection.get();
      final reservationsCount = reservationsSnapshot.size;

      // Nombre de réservations par statut
      final pendingSnapshot = await _reservationsCollection
          .where('status', isEqualTo: ReservationModel.statusPending)
          .get();
      final approvedSnapshot = await _reservationsCollection
          .where('status', isEqualTo: ReservationModel.statusApproved)
          .get();
      final completedSnapshot = await _reservationsCollection
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
      throw Exception('Erreur lors de la récupération des statistiques: ${e.toString()}');
    }
  }
}
