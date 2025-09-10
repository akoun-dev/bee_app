import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/agent_model.dart';
import '../models/reservation_model.dart';
import '../models/user_model.dart';
import 'database_service.dart';

// Service pour gérer la disponibilité automatique des agents
// et les permissions selon le type d'utilisateur
class AgentAvailabilityService {
  final DatabaseService? _databaseService;
  final FirebaseFirestore _firestore;
  Timer? _availabilityTimer;

  AgentAvailabilityService(this._databaseService, this._firestore);
  
  // Constructeur pour les cas où le DatabaseService n'est pas disponible
  AgentAvailabilityService.withoutDatabaseService(this._firestore) : _databaseService = null;
  
  // Constructeur de fabrique pour éviter la dépendance circulaire
  factory AgentAvailabilityService.create(DatabaseService? databaseService, FirebaseFirestore firestore) {
    if (databaseService == null) {
      return AgentAvailabilityService.withoutDatabaseService(firestore);
    } else {
      return AgentAvailabilityService(databaseService, firestore);
    }
  }

  // ===== GESTION AUTOMATIQUE DE LA DISPONIBILITÉ =====

  // Mettre à jour automatiquement la disponibilité des agents
  // Cette méthode devrait être appelée périodiquement ou lors d'événements clés
  Future<void> updateAgentsAvailability() async {
    // Vérifier si le DatabaseService est disponible
    if (_databaseService == null) {
      debugPrint('DatabaseService non disponible, mise à jour de disponibilité annulée');
      return;
    }
    
    try {
      debugPrint('Début de la mise à jour automatique de la disponibilité des agents');
      
      // Récupérer toutes les réservations actives (approuvées ou en attente)
      final activeReservationsQuery = await _firestore
          .collection('reservations')
          .where('status', whereIn: [
            ReservationModel.statusPending,
            ReservationModel.statusApproved,
          ])
          .get();

      final activeReservations = activeReservationsQuery.docs
          .map((doc) => ReservationModel.fromMap(doc.data(), doc.id))
          .toList();

      // Récupérer tous les agents
      final agentsQuery = await _firestore.collection('agents').get();
      final agents = agentsQuery.docs
          .map((doc) => AgentModel.fromMap(doc.data(), doc.id))
          .toList();

      final now = DateTime.now();
      final Set<String> agentsWithActiveReservations = {};
      final Set<String> agentsToMakeAvailable = {};

      // Identifier les agents avec des réservations actives
      for (final reservation in activeReservations) {
        // Vérifier si la réservation est actuellement active
        bool isActive = false;
        
        if (reservation.status == ReservationModel.statusApproved) {
          // La réservation est active si elle a commencé et n'est pas terminée
          isActive = reservation.startDate.isBefore(now) && 
                     reservation.endDate.isAfter(now);
        } else if (reservation.status == ReservationModel.statusPending) {
          // Les réservations en attente sont considérées comme futures réservations
          isActive = reservation.startDate.isAfter(now);
        }

        if (isActive) {
          agentsWithActiveReservations.add(reservation.agentId);
        }
      }

      // Mettre à jour la disponibilité des agents
      for (final agent in agents) {
        bool shouldBeAvailable = !agentsWithActiveReservations.contains(agent.id);
        
        // Vérifier si l'agent est manuellement marqué comme indisponible
        // (pour les cas où un admin a manuellement rendu un agent indisponible)
        if (!agent.isAvailable && !agentsWithActiveReservations.contains(agent.id)) {
          // L'agent est actuellement indisponible mais n'a pas de réservation active
          // On le laisse indisponible (changement manuel)
          continue;
        }

        if (agent.isAvailable != shouldBeAvailable) {
          debugPrint('Mise à jour de la disponibilité de l\'agent ${agent.fullName}: ${shouldBeAvailable ? 'Disponible' : 'Indisponible'}');
          
          final updatedAgent = agent.copyWith(isAvailable: shouldBeAvailable);
          await _databaseService!.updateAgent(updatedAgent);
        }
      }

      debugPrint('Mise à jour automatique de la disponibilité terminée');
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour automatique de la disponibilité: $e');
      rethrow;
    }
  }

  // Mettre à jour la disponibilité d'un agent spécifique
  Future<void> updateAgentAvailability(String agentId) async {
    // Vérifier si le DatabaseService est disponible
    if (_databaseService == null) {
      debugPrint('DatabaseService non disponible, mise à jour de disponibilité de l\'agent annulée');
      return;
    }
    
    try {
      final agent = await _databaseService!.getAgent(agentId);
      if (agent == null) {
        throw Exception('Agent non trouvé');
      }

      // Récupérer les réservations actives de cet agent
      final activeReservationsQuery = await _firestore
          .collection('reservations')
          .where('agentId', isEqualTo: agentId)
          .where('status', whereIn: [
            ReservationModel.statusPending,
            ReservationModel.statusApproved,
          ])
          .get();

      final activeReservations = activeReservationsQuery.docs
          .map((doc) => ReservationModel.fromMap(doc.data(), doc.id))
          .toList();

      final now = DateTime.now();
      bool hasActiveReservation = false;

      for (final reservation in activeReservations) {
        bool isActive = false;
        
        if (reservation.status == ReservationModel.statusApproved) {
          isActive = reservation.startDate.isBefore(now) && 
                     reservation.endDate.isAfter(now);
        } else if (reservation.status == ReservationModel.statusPending) {
          isActive = reservation.startDate.isAfter(now);
        }

        if (isActive) {
          hasActiveReservation = true;
          break;
        }
      }

      bool shouldBeAvailable = !hasActiveReservation;
      
      if (agent.isAvailable != shouldBeAvailable) {
        final updatedAgent = agent.copyWith(isAvailable: shouldBeAvailable);
        await _databaseService!.updateAgent(updatedAgent);
        debugPrint('Disponibilité de l\'agent ${agent.fullName} mise à jour: ${shouldBeAvailable ? 'Disponible' : 'Indisponible'}');
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de la disponibilité de l\'agent $agentId: $e');
      rethrow;
    }
  }

  // Obtenir la disponibilité d'un agent
  Future<bool> getAgentAvailability(String agentId) async {
    // Vérifier si le DatabaseService est disponible
    if (_databaseService == null) {
      debugPrint('DatabaseService non disponible, vérification de disponibilité annulée');
      return false;
    }
    
    try {
      final agent = await _databaseService!.getAgent(agentId);
      if (agent == null) {
        return false;
      }

      // Récupérer les réservations actives de cet agent
      final activeReservationsQuery = await _firestore
          .collection('reservations')
          .where('agentId', isEqualTo: agentId)
          .where('status', whereIn: [
            ReservationModel.statusPending,
            ReservationModel.statusApproved,
          ])
          .get();

      final activeReservations = activeReservationsQuery.docs
          .map((doc) => ReservationModel.fromMap(doc.data(), doc.id))
          .toList();

      final now = DateTime.now();
      bool hasActiveReservation = false;

      for (final reservation in activeReservations) {
        bool isActive = false;
        
        if (reservation.status == ReservationModel.statusApproved) {
          isActive = reservation.startDate.isBefore(now) && 
                     reservation.endDate.isAfter(now);
        } else if (reservation.status == ReservationModel.statusPending) {
          isActive = reservation.startDate.isAfter(now);
        }

        if (isActive) {
          hasActiveReservation = true;
          break;
        }
      }

      return !hasActiveReservation;
    } catch (e) {
      debugPrint('Erreur lors de la vérification de la disponibilité de l\'agent $agentId: $e');
      return false;
    }
  }

  // Rendre un agent manuellement indisponible (admin seulement)
  Future<void> setAgentManuallyUnavailable(String agentId, String reason) async {
    // Vérifier si le DatabaseService est disponible
    if (_databaseService == null) {
      debugPrint('DatabaseService non disponible, mise en indisponibilité manuelle annulée');
      return;
    }
    
    try {
      final agent = await _databaseService!.getAgent(agentId);
      if (agent == null) {
        throw Exception('Agent non trouvé');
      }

      if (agent.isAvailable) {
        final updatedAgent = agent.copyWith(isAvailable: false);
        await _databaseService!.updateAgent(updatedAgent);
        
        // Créer un log pour cette action manuelle
        await _logManualAvailabilityChange(agentId, false, reason);
        
        debugPrint('Agent ${agent.fullName} rendu manuellement indisponible: $reason');
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise en indisponibilité manuelle de l\'agent $agentId: $e');
      rethrow;
    }
  }

  // Rendre un agent manuellement disponible (admin seulement)
  Future<void> setAgentManuallyAvailable(String agentId, String reason) async {
    // Vérifier si le DatabaseService est disponible
    if (_databaseService == null) {
      debugPrint('DatabaseService non disponible, mise en disponibilité manuelle annulée');
      return;
    }
    
    try {
      final agent = await _databaseService!.getAgent(agentId);
      if (agent == null) {
        throw Exception('Agent non trouvé');
      }

      if (!agent.isAvailable) {
        final updatedAgent = agent.copyWith(isAvailable: true);
        await _databaseService!.updateAgent(updatedAgent);
        
        // Créer un log pour cette action manuelle
        await _logManualAvailabilityChange(agentId, true, reason);
        
        debugPrint('Agent ${agent.fullName} rendu manuellement disponible: $reason');
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise en disponibilité manuelle de l\'agent $agentId: $e');
      rethrow;
    }
  }

  // Logger les changements manuels de disponibilité
  Future<void> _logManualAvailabilityChange(String agentId, bool isAvailable, String reason) async {
    try {
      await _firestore.collection('availability_logs').add({
        'agentId': agentId,
        'isAvailable': isAvailable,
        'reason': reason,
        'changedBy': 'admin', // Sera remplacé par l'ID de l'admin réel
        'changedAt': FieldValue.serverTimestamp(),
        'isManual': true,
      });
    } catch (e) {
      debugPrint('Erreur lors du logging du changement de disponibilité: $e');
      // Ne pas rethrow pour ne pas bloquer l'opération principale
    }
  }

  // ===== GESTION DES PERMISSIONS PAR TYPE D'UTILISATEUR =====

  // Vérifier si un utilisateur a une permission spécifique
  bool hasPermission(UserModel user, String permission) {
    if (user.isAdmin) {
      return true; // Les admins ont toutes les permissions
    }

    return user.permissions?.contains(permission) ?? false;
  }

  // Vérifier si un utilisateur peut voir les agents indisponibles
  bool canViewUnavailableAgents(UserModel user) {
    return user.isAdmin || hasPermission(user, 'view_unavailable_agents');
  }

  // Vérifier si un utilisateur peut modifier la disponibilité des agents
  bool canModifyAgentAvailability(UserModel user) {
    return user.isAdmin || hasPermission(user, 'modify_agent_availability');
  }

  // Vérifier si un utilisateur peut voir tous les détails des réservations
  bool canViewAllReservationDetails(UserModel user) {
    return user.isAdmin || hasPermission(user, 'view_all_reservation_details');
  }

  // Vérifier si un utilisateur peut approuver des réservations
  bool canApproveReservations(UserModel user) {
    return user.isAdmin || hasPermission(user, 'approve_reservations');
  }

  // Vérifier si un utilisateur peut voir les statistiques
  bool canViewStatistics(UserModel user) {
    return user.isAdmin || hasPermission(user, 'view_statistics');
  }

  // Vérifier si un utilisateur peut gérer les utilisateurs
  bool canManageUsers(UserModel user) {
    return user.isAdmin || hasPermission(user, 'manage_users');
  }

  // ===== MÉTHODES UTILITAIRES =====

  // Obtenir les agents disponibles pour un utilisateur selon ses permissions
  Stream<List<AgentModel>> getAvailableAgentsForUser(UserModel user) {
    // Vérifier si le DatabaseService est disponible
    if (_databaseService == null) {
      debugPrint('DatabaseService non disponible, retour d\'un flux vide');
      return Stream.value([]);
    }
    
    if (canViewUnavailableAgents(user)) {
      // Les utilisateurs avec permission voient tous les agents
      return _databaseService!.getAgents();
    } else {
      // Les autres utilisateurs ne voient que les agents disponibles
      return _databaseService!.getAvailableAgents();
    }
  }

  // Vérifier si un agent peut être réservé par un utilisateur
  Future<bool> canReserveAgent(UserModel user, String agentId) async {
    // Vérifier si le DatabaseService est disponible
    if (_databaseService == null) {
      debugPrint('DatabaseService non disponible, vérification de réservation annulée');
      return false;
    }
    
    try {
      final agent = await _databaseService!.getAgent(agentId);
      if (agent == null) {
        return false;
      }

      // Les admins peuvent réserver n'importe quel agent
      if (user.isAdmin) {
        return true;
      }

      // Les autres utilisateurs peuvent seulement réserver les agents disponibles
      return agent.isAvailable;
    } catch (e) {
      debugPrint('Erreur lors de la vérification de la réservation de l\'agent: $e');
      return false;
    }
  }

  // Démarrer un timer pour la mise à jour automatique de la disponibilité
  void startAvailabilityTimer({Duration interval = const Duration(minutes: 5)}) {
    _availabilityTimer = Timer.periodic(interval, (timer) async {
      try {
        await updateAgentsAvailability();
      } catch (e) {
        debugPrint('Erreur dans le timer de mise à jour de disponibilité: $e');
      }
    });
  }

  void stopAvailabilityTimer() {
    _availabilityTimer?.cancel();
    _availabilityTimer = null;
  }
}
