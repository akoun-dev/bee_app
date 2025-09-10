import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/data_deletion_model.dart';
import '../models/reservation_model.dart';
import '../models/review_model.dart';
import 'auth_service.dart';
import 'audit_service.dart';
import 'consent_service.dart';
import 'database_service.dart';

// Service pour la gestion du droit à l'oubli et la suppression des données
class DataDeletionService {
  final FirebaseFirestore _firestore;
  final AuthService _authService;
  final AuditService _auditService;
  final ConsentService _consentService;
  final DatabaseService _databaseService;

  // Références aux collections Firestore
  final CollectionReference _deletionRequestsCollection;
  final CollectionReference _usersCollection;
  final CollectionReference _reservationsCollection;
  final CollectionReference _reviewsCollection;
  final CollectionReference _consentsCollection;

  DataDeletionService({
    required FirebaseFirestore firestore,
    required AuthService authService,
    required AuditService auditService,
    required ConsentService consentService,
    required DatabaseService databaseService,
  })  : _firestore = firestore,
        _authService = authService,
        _auditService = auditService,
        _consentService = consentService,
        _databaseService = databaseService,
        _deletionRequestsCollection = firestore.collection('data_deletion_requests'),
        _usersCollection = firestore.collection('users'),
        _reservationsCollection = firestore.collection('reservations'),
        _reviewsCollection = firestore.collection('reviews'),
        _consentsCollection = firestore.collection('user_consents');

  // Créer une demande de suppression de données
  Future<DataDeletionRequestModel> createDeletionRequest({
    required DeletionReason reason,
    String? additionalComments,
    Map<String, bool>? dataCategories,
    bool isUrgent = false,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      // Vérifier que l'utilisateur est connecté
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('Vous devez être connecté pour faire une demande de suppression');
      }

      final userModel = await _databaseService.getUser(currentUser.uid);
      if (userModel == null) {
        throw Exception('Utilisateur introuvable');
      }

      // Créer la demande de suppression
      final request = DataDeletionRequestModel.create(
        userId: currentUser.uid,
        userEmail: userModel.email,
        reason: reason,
        additionalComments: additionalComments,
        dataCategories: dataCategories,
        isUrgent: isUrgent,
        ipAddress: ipAddress,
        userAgent: userAgent,
      );

      // Sauvegarder dans Firestore
      final docRef = await _deletionRequestsCollection.add(request.toMap());
      final requestId = docRef.id;

      // Créer l'objet final avec l'ID
      final finalRequest = request.copyWith(id: requestId);

      // Logger la création de la demande
      await _auditService.logAction(
        adminId: currentUser.uid,
        adminEmail: userModel.email,
        action: 'create_deletion_request',
        targetType: 'data_deletion_request',
        targetId: requestId,
        description: 'Création d\'une demande de suppression de données - Raison: ${reason.displayName}',
        newData: finalRequest.toMap(),
        ipAddress: ipAddress,
        userAgent: userAgent,
      );

      return finalRequest;
    } catch (e) {
      debugPrint('Erreur lors de la création de la demande de suppression: $e');
      throw Exception('Impossible de créer la demande de suppression: ${e.toString()}');
    }
  }

  // Obtenir une demande de suppression par son ID
  Future<DataDeletionRequestModel?> getDeletionRequest(String requestId) async {
    try {
      final docSnapshot = await _deletionRequestsCollection.doc(requestId).get();
      
      if (!docSnapshot.exists) {
        return null;
      }

      return DataDeletionRequestModel.fromMap(docSnapshot.data() as Map<String, dynamic>, requestId);
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la demande de suppression: $e');
      return null;
    }
  }

  // Obtenir toutes les demandes de suppression d'un utilisateur
  Future<List<DataDeletionRequestModel>> getUserDeletionRequests(String userId) async {
    try {
      final snapshot = await _deletionRequestsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('requestedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => 
        DataDeletionRequestModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des demandes de suppression: $e');
      return [];
    }
  }

  // Obtenir toutes les demandes de suppression (pour les administrateurs)
  Future<List<DataDeletionRequestModel>> getAllDeletionRequests({
    DeletionStatus? status,
    bool? urgentOnly,
    bool? overdueOnly,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _deletionRequestsCollection.orderBy('requestedAt', descending: true);

      // Appliquer les filtres
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (urgentOnly == true) {
        query = query.where('isUrgent', isEqualTo: true);
      }

      if (startDate != null) {
        query = query.where('requestedAt', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('requestedAt', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();
      var requests = snapshot.docs.map((doc) => 
        DataDeletionRequestModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();

      // Filtrer les demandes en retard si demandé
      if (overdueOnly == true) {
        requests = requests.where((request) => request.isOverdue).toList();
      }

      return requests;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des demandes de suppression: $e');
      return [];
    }
  }

  // Approuver une demande de suppression
  Future<DataDeletionRequestModel> approveDeletionRequest({
    required String requestId,
    required String processedBy,
    DateTime? scheduledFor,
  }) async {
    try {
      // Vérifier que l'utilisateur est un administrateur
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('Vous devez être connecté');
      }

      // Obtenir la demande actuelle
      final currentRequest = await getDeletionRequest(requestId);
      if (currentRequest == null) {
        throw Exception('Demande de suppression introuvable');
      }

      // Vérifier que la demande peut être approuvée
      if (currentRequest.status != DeletionStatus.pending) {
        throw Exception('Cette demande ne peut plus être approuvée');
      }

      // Approuver la demande
      final approvedRequest = currentRequest.approve(
        processedBy: processedBy,
        scheduledFor: scheduledFor,
      );

      // Sauvegarder dans Firestore
      await _deletionRequestsCollection.doc(requestId).set(approvedRequest.toMap());

      // Logger l'approbation
      await _auditService.logAction(
        adminId: currentUser.uid,
        adminEmail: processedBy,
        action: 'approve_deletion_request',
        targetType: 'data_deletion_request',
        targetId: requestId,
        description: 'Approbation de la demande de suppression de données',
        oldData: currentRequest.toMap(),
        newData: approvedRequest.toMap(),
      );

      // Si la date d'exécution est maintenant ou dans le passé, lancer la suppression
      if (approvedRequest.canBeProcessed()) {
        await _processDeletionRequest(approvedRequest);
      }

      return approvedRequest;
    } catch (e) {
      debugPrint('Erreur lors de l\'approbation de la demande de suppression: $e');
      throw Exception('Impossible d\'approuver la demande: ${e.toString()}');
    }
  }

  // Rejeter une demande de suppression
  Future<DataDeletionRequestModel> rejectDeletionRequest({
    required String requestId,
    required String processedBy,
    required String rejectionReason,
  }) async {
    try {
      // Vérifier que l'utilisateur est un administrateur
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('Vous devez être connecté');
      }

      // Obtenir la demande actuelle
      final currentRequest = await getDeletionRequest(requestId);
      if (currentRequest == null) {
        throw Exception('Demande de suppression introuvable');
      }

      // Vérifier que la demande peut être rejetée
      if (currentRequest.status != DeletionStatus.pending) {
        throw Exception('Cette demande ne peut plus être rejetée');
      }

      // Rejeter la demande
      final rejectedRequest = currentRequest.reject(
        processedBy: processedBy,
        rejectionReason: rejectionReason,
      );

      // Sauvegarder dans Firestore
      await _deletionRequestsCollection.doc(requestId).set(rejectedRequest.toMap());

      // Logger le rejet
      await _auditService.logAction(
        adminId: currentUser.uid,
        adminEmail: processedBy,
        action: 'reject_deletion_request',
        targetType: 'data_deletion_request',
        targetId: requestId,
        description: 'Rejet de la demande de suppression de données',
        oldData: currentRequest.toMap(),
        newData: rejectedRequest.toMap(),
      );

      return rejectedRequest;
    } catch (e) {
      debugPrint('Erreur lors du rejet de la demande de suppression: $e');
      throw Exception('Impossible de rejeter la demande: ${e.toString()}');
    }
  }

  // Traiter une demande de suppression (suppression effective des données)
  Future<DataDeletionRequestModel> _processDeletionRequest(DataDeletionRequestModel request) async {
    try {
      // Mettre à jour le statut à "en cours de traitement"
      final processingRequest = request.markAsProcessing(processedBy: 'System');
      await _deletionRequestsCollection.doc(request.id).set(processingRequest.toMap());

      final userId = request.userId;
      final dataCategories = request.dataCategories;
      final processedData = <String, bool>{};

      // Supprimer les données par catégorie
      try {
        if (dataCategories['profile'] == true) {
          await _deleteUserProfile(userId);
          processedData['profile'] = true;
        }

        if (dataCategories['reservations'] == true) {
          await _deleteUserReservations(userId);
          processedData['reservations'] = true;
        }

        if (dataCategories['reviews'] == true) {
          await _deleteUserReviews(userId);
          processedData['reviews'] = true;
        }

        if (dataCategories['payments'] == true) {
          await _deleteUserPayments(userId);
          processedData['payments'] = true;
        }

        if (dataCategories['communications'] == true) {
          await _deleteUserCommunications(userId);
          processedData['communications'] = true;
        }

        if (dataCategories['preferences'] == true) {
          await _deleteUserPreferences(userId);
          processedData['preferences'] = true;
        }

        if (dataCategories['consents'] == true) {
          await _deleteUserConsents(userId);
          processedData['consents'] = true;
        }

        // Si toutes les données personnelles sont supprimées et c'est une fermeture de compte
        if (request.reason == DeletionReason.accountClosure && 
            dataCategories.values.every((v) => v || !dataCategories.keys.contains(v))) {
          await _deleteUserAccount(userId);
          processedData['account'] = true;
        }

        // Marquer comme complété
        final completedRequest = processingRequest.markAsCompleted(processedBy: 'System');
        await _deletionRequestsCollection.doc(request.id).set(completedRequest.toMap());

        // Logger la completion
        await _auditService.logAction(
          adminId: 'System',
          adminEmail: 'System',
          action: 'complete_deletion_request',
          targetType: 'data_deletion_request',
          targetId: request.id,
          description: 'Traitement de la demande de suppression terminé',
          newData: {
            'processedData': processedData,
            'totalCategories': processedData.length,
          },
        );

        return completedRequest;
      } catch (e) {
        // Marquer comme échoué en cas d'erreur
        final failedRequest = processingRequest.markAsFailed(
          processedBy: 'System',
          failureReason: e.toString(),
        );
        await _deletionRequestsCollection.doc(request.id).set(failedRequest.toMap());

        // Logger l'échec
        await _auditService.logAction(
          adminId: 'System',
          adminEmail: 'System',
          action: 'fail_deletion_request',
          targetType: 'data_deletion_request',
          targetId: request.id,
          description: 'Échec du traitement de la demande de suppression',
          newData: {'error': e.toString()},
        );

        rethrow;
      }
    } catch (e) {
      debugPrint('Erreur lors du traitement de la demande de suppression: $e');
      throw Exception('Impossible de traiter la demande: ${e.toString()}');
    }
  }

  // Supprimer le profil utilisateur
  Future<void> _deleteUserProfile(String userId) async {
    try {
      final userDoc = _usersCollection.doc(userId);
      final userSnapshot = await userDoc.get();

      if (userSnapshot.exists) {
        final userData = userSnapshot.data() as Map<String, dynamic>;
        
        // Anonymiser les données au lieu de supprimer complètement (pour les logs légaux)
        await userDoc.update({
          'fullName': 'Utilisateur supprimé',
          'email': 'deleted_$userId@deleted.com',
          'phone': '+0000000000',
          'profileImageUrl': null,
          'address': null,
          'dateOfBirth': null,
          'isDeleted': true,
          'deletedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de la suppression du profil utilisateur: $e');
      throw Exception('Impossible de supprimer le profil: ${e.toString()}');
    }
  }

  // Supprimer les réservations de l'utilisateur
  Future<void> _deleteUserReservations(String userId) async {
    try {
      final snapshot = await _reservationsCollection
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.update({
          'userId': 'deleted_user',
          'description': 'Réservation anonymisée suite à suppression des données',
          'isAnonymized': true,
          'anonymizedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de la suppression des réservations: $e');
      throw Exception('Impossible de supprimer les réservations: ${e.toString()}');
    }
  }

  // Supprimer les avis de l'utilisateur
  Future<void> _deleteUserReviews(String userId) async {
    try {
      final snapshot = await _reviewsCollection
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Erreur lors de la suppression des avis: $e');
      throw Exception('Impossible de supprimer les avis: ${e.toString()}');
    }
  }

  // Supprimer les données de paiement de l'utilisateur
  Future<void> _deleteUserPayments(String userId) async {
    try {
      // Note: Les données de paiement sensibles devraient être gérées par un service externe
      // Ici on marque juste les données comme supprimées
      final snapshot = await _reservationsCollection
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.update({
          'paymentInfo': null,
          'paymentAnonymized': true,
          'paymentAnonymizedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de la suppression des données de paiement: $e');
      throw Exception('Impossible de supprimer les données de paiement: ${e.toString()}');
    }
  }

  // Supprimer les communications de l'utilisateur
  Future<void> _deleteUserCommunications(String userId) async {
    try {
      // Note: Les communications sont généralement stockées dans une collection séparée
      // Pour l'instant, on marque les réservations comme ayant les communications anonymisées
      final snapshot = await _reservationsCollection
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.update({
          'communicationsAnonymized': true,
          'communicationsAnonymizedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de la suppression des communications: $e');
      throw Exception('Impossible de supprimer les communications: ${e.toString()}');
    }
  }

  // Supprimer les préférences de l'utilisateur
  Future<void> _deleteUserPreferences(String userId) async {
    try {
      // Supprimer les préférences utilisateur
      await _databaseService.updateUserPreferences(userId, {});
    } catch (e) {
      debugPrint('Erreur lors de la suppression des préférences: $e');
      throw Exception('Impossible de supprimer les préférences: ${e.toString()}');
    }
  }

  // Supprimer les consentements de l'utilisateur
  Future<void> _deleteUserConsents(String userId) async {
    try {
      await _consentService.deleteUserConsents(
        userId,
        reason: 'Suppression suite à demande de droit à l\'oubli',
      );
    } catch (e) {
      debugPrint('Erreur lors de la suppression des consentements: $e');
      throw Exception('Impossible de supprimer les consentements: ${e.toString()}');
    }
  }

  // Supprimer complètement le compte utilisateur
  Future<void> _deleteUserAccount(String userId) async {
    try {
      // Note: La suppression complète du compte Firebase Authentication nécessite
      // des permissions élevées et devrait être faite via le SDK Admin
      // Pour l'instant, on marque le compte comme supprimé dans Firestore
      
      await _usersCollection.doc(userId).update({
        'accountDeleted': true,
        'accountDeletedAt': FieldValue.serverTimestamp(),
        'isActive': false,
      });
    } catch (e) {
      debugPrint('Erreur lors de la suppression du compte utilisateur: $e');
      throw Exception('Impossible de supprimer le compte: ${e.toString()}');
    }
  }

  // Vérifier les demandes de suppression en attente et les traiter
  Future<void> processPendingDeletionRequests() async {
    try {
      // Pour l'instant, désactiver complètement le traitement des demandes pour éviter les crashes
      // TODO: Réactiver cet appel lorsque la collection data_deletion_requests sera configurée
      debugPrint('Le traitement des demandes de suppression est temporairement désactivé.');
      
      /* Code d'origine commenté - à réactiver plus tard
      final snapshot = await _deletionRequestsCollection
          .where('status', isEqualTo: 'approved')
          .get();

      for (final doc in snapshot.docs) {
        final request = DataDeletionRequestModel.fromMap(
          doc.data() as Map<String, dynamic>, 
          doc.id,
        );

        if (request.canBeProcessed()) {
          await _processDeletionRequest(request);
        }
      }
      */
    } catch (e) {
      debugPrint('Erreur lors du traitement des demandes en attente: $e');
      // Ne pas propager l'erreur pour éviter de bloquer l'initialisation de l'application
    }
  }

  // Obtenir des statistiques sur les demandes de suppression
  Future<Map<String, dynamic>> getDeletionStatistics() async {
    try {
      // Pour l'instant, désactiver complètement l'obtention des statistiques pour éviter les crashes
      // TODO: Réactiver cet appel lorsque la collection data_deletion_requests sera configurée
      debugPrint('L\'obtention des statistiques de suppression est temporairement désactivée.');
      
      return {
        'totalRequests': 0,
        'statistics': {},
        'lastUpdated': DateTime.now().toIso8601String(),
        'note': 'Les statistiques sont temporairement désactivées',
      };
      
      /* Code d'origine commenté - à réactiver plus tard
      // Vérifier que l'utilisateur est un administrateur
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('Vous devez être connecté');
      }

      final snapshot = await _deletionRequestsCollection.get();
      final allRequests = snapshot.docs.map((doc) => 
        DataDeletionRequestModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();

      if (allRequests.isEmpty) {
        return {'totalRequests': 0, 'statistics': {}};
      }

      // Calculer les statistiques
      final statistics = <String, dynamic>{};
      final totalRequests = allRequests.length;

      // Par statut
      for (final status in DeletionStatus.values) {
        final count = allRequests.where((r) => r.status == status).length;
        statistics['status_${status.name}'] = {
          'count': count,
          'percentage': (count / totalRequests * 100).toStringAsFixed(1),
        };
      }

      // Par raison
      for (final reason in DeletionReason.values) {
        final count = allRequests.where((r) => r.reason == reason).length;
        statistics['reason_${reason.name}'] = {
          'count': count,
          'percentage': (count / totalRequests * 100).toStringAsFixed(1),
        };
      }

      // Demandes urgentes
      final urgentCount = allRequests.where((r) => r.isUrgent).length;
      statistics['urgent'] = {
        'count': urgentCount,
        'percentage': (urgentCount / totalRequests * 100).toStringAsFixed(1),
      };

      // Demandes en retard
      final overdueCount = allRequests.where((r) => r.isOverdue).length;
      statistics['overdue'] = {
        'count': overdueCount,
        'percentage': (overdueCount / totalRequests * 100).toStringAsFixed(1),
      };

      // Temps moyen de traitement
      final processedRequests = allRequests.where((r) => r.processedAt != null).toList();
      if (processedRequests.isNotEmpty) {
        final totalProcessingTime = processedRequests.fold(
          0,
          (sum, request) => sum + request.processedAt!.difference(request.requestedAt).inHours,
        );
        statistics['averageProcessingTime'] = {
          'hours': (totalProcessingTime / processedRequests.length).toStringAsFixed(1),
        };
      }

      return {
        'totalRequests': totalRequests,
        'statistics': statistics,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      */
    } catch (e) {
      debugPrint('Erreur lors de l\'obtention des statistiques: $e');
      // Retourner des statistiques vides au lieu de lancer une exception
      return {
        'totalRequests': 0,
        'statistics': {},
        'lastUpdated': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }

  // Exporter les données d'un utilisateur avant suppression (portabilité)
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    try {
      // Vérifier que l'utilisateur est connecté et a les permissions
      final currentUser = _authService.currentUser;
      if (currentUser == null || currentUser.uid != userId) {
        throw Exception('Vous devez être connecté pour exporter vos données');
      }

      final exportData = <String, dynamic>{
        'userId': userId,
        'exportDate': DateTime.now().toIso8601String(),
        'data': {},
      };

      // Exporter le profil utilisateur
      final userProfile = await _databaseService.getUser(userId);
      if (userProfile != null) {
        exportData['data']['profile'] = userProfile.toMap();
      }

      // Exporter les préférences
      final userPreferences = await _databaseService.getUserPreferences(userId);
      if (userPreferences != null) {
        exportData['data']['preferences'] = userPreferences.toMap();
      }

      // Exporter les réservations
      final reservationsSnapshot = await _reservationsCollection
          .where('userId', isEqualTo: userId)
          .get();
      exportData['data']['reservations'] = reservationsSnapshot.docs
          .map((doc) => ReservationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .map((r) => r.toMap())
          .toList();

      // Exporter les avis
      final reviewsSnapshot = await _reviewsCollection
          .where('userId', isEqualTo: userId)
          .get();
      exportData['data']['reviews'] = reviewsSnapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .map((r) => r.toMap())
          .toList();

      // Exporter les consentements
      final consentsExport = await _consentService.exportUserConsents(userId);
      exportData['data']['consents'] = consentsExport;

      // Logger l'export
      await _auditService.logAction(
        adminId: userId,
        adminEmail: currentUser.email ?? 'Unknown',
        action: 'export_user_data',
        targetType: 'user_data',
        targetId: userId,
        description: 'Export des données utilisateur avant suppression',
        metadata: {'exportSize': exportData.toString().length},
      );

      return exportData;
    } catch (e) {
      debugPrint('Erreur lors de l\'export des données utilisateur: $e');
      throw Exception('Impossible d\'exporter les données: ${e.toString()}');
    }
  }
}
