import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/agent_model.dart';
import '../models/reservation_model.dart';
import '../models/user_preferences_model.dart';

// Service pour les recommandations personnalisées
class RecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collections
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');
  final CollectionReference _agentsCollection = FirebaseFirestore.instance.collection('agents');
  final CollectionReference _reservationsCollection = FirebaseFirestore.instance.collection('reservations');
  final CollectionReference _preferencesCollection = FirebaseFirestore.instance.collection('userPreferences');
  
  // Cache pour les préférences utilisateur
  final Map<String, UserPreferencesModel> _preferencesCache = {};
  
  // Récupérer les préférences d'un utilisateur
  Future<UserPreferencesModel> getUserPreferences(String userId) async {
    try {
      // Vérifier le cache
      if (_preferencesCache.containsKey(userId)) {
        return _preferencesCache[userId]!;
      }
      
      // Récupérer depuis Firestore
      final docSnapshot = await _preferencesCollection.doc(userId).get();
      
      if (docSnapshot.exists) {
        final preferences = UserPreferencesModel.fromMap(
          docSnapshot.data() as Map<String, dynamic>,
          userId,
        );
        
        // Mettre en cache
        _preferencesCache[userId] = preferences;
        
        return preferences;
      } else {
        // Créer des préférences par défaut
        final defaultPreferences = UserPreferencesModel.createDefault(userId);
        
        // Sauvegarder dans Firestore
        await _preferencesCollection.doc(userId).set(defaultPreferences.toMap());
        
        // Mettre en cache
        _preferencesCache[userId] = defaultPreferences;
        
        return defaultPreferences;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la récupération des préférences: ${e.toString()}');
      }
      
      // Retourner des préférences par défaut en cas d'erreur
      return UserPreferencesModel.createDefault(userId);
    }
  }
  
  // Mettre à jour les préférences d'un utilisateur
  Future<void> updateUserPreferences(UserPreferencesModel preferences) async {
    try {
      // Mettre à jour dans Firestore
      await _preferencesCollection.doc(preferences.userId).set(preferences.toMap());
      
      // Mettre à jour le cache
      _preferencesCache[preferences.userId] = preferences;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la mise à jour des préférences: ${e.toString()}');
      }
      throw Exception('Erreur lors de la mise à jour des préférences: ${e.toString()}');
    }
  }
  
  // Ajouter/retirer un agent des favoris
  Future<void> toggleFavoriteAgent(String userId, String agentId) async {
    try {
      final preferences = await getUserPreferences(userId);
      
      UserPreferencesModel updatedPreferences;
      
      if (preferences.favoriteAgentIds.contains(agentId)) {
        updatedPreferences = preferences.removeFavoriteAgent(agentId);
      } else {
        updatedPreferences = preferences.addFavoriteAgent(agentId);
      }
      
      await updateUserPreferences(updatedPreferences);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la modification des favoris: ${e.toString()}');
      }
      throw Exception('Erreur lors de la modification des favoris: ${e.toString()}');
    }
  }
  
  // Récupérer les agents favoris d'un utilisateur
  Future<List<AgentModel>> getFavoriteAgents(String userId) async {
    try {
      final preferences = await getUserPreferences(userId);
      
      if (preferences.favoriteAgentIds.isEmpty) {
        return [];
      }
      
      final favoriteAgents = <AgentModel>[];
      
      // Récupérer chaque agent favori
      for (final agentId in preferences.favoriteAgentIds) {
        final docSnapshot = await _agentsCollection.doc(agentId).get();
        
        if (docSnapshot.exists) {
          favoriteAgents.add(AgentModel.fromMap(
            docSnapshot.data() as Map<String, dynamic>,
            docSnapshot.id,
          ));
        }
      }
      
      return favoriteAgents;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la récupération des agents favoris: ${e.toString()}');
      }
      return [];
    }
  }
  
  // Obtenir des recommandations personnalisées pour un utilisateur
  Future<List<AgentModel>> getRecommendedAgents(String userId, {int limit = 5}) async {
    try {
      // Récupérer les préférences de l'utilisateur
      final preferences = await getUserPreferences(userId);
      
      // Récupérer l'historique des réservations
      final reservationsSnapshot = await _reservationsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      final reservations = reservationsSnapshot.docs.map((doc) => 
        ReservationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();
      
      // Récupérer tous les agents
      final agentsSnapshot = await _agentsCollection.get();
      final allAgents = agentsSnapshot.docs.map((doc) => 
        AgentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();
      
      // Calculer un score pour chaque agent
      final scoredAgents = <String, double>{};
      
      for (final agent in allAgents) {
        double score = 0;
        
        // 1. Bonus pour les agents déjà réservés avec une bonne note
        for (final reservation in reservations) {
          if (reservation.agentId == agent.id) {
            // Si la réservation a une note, l'utiliser comme bonus
            if (reservation.rating != null) {
              score += reservation.rating! * 2; // Multiplier par 2 pour donner plus de poids
            } else {
              score += 1; // Bonus minimal pour une réservation sans note
            }
          }
        }
        
        // 2. Bonus pour les agents favoris
        if (preferences.favoriteAgentIds.contains(agent.id)) {
          score += 10; // Bonus important pour les favoris
        }
        
        // 3. Bonus pour les agents bien notés en général
        score += agent.averageRating;
        
        // 4. Bonus pour les agents disponibles
        if (agent.isAvailable) {
          score += 2;
        }
        
        // Enregistrer le score
        scoredAgents[agent.id] = score;
      }
      
      // Trier les agents par score
      allAgents.sort((a, b) => 
        (scoredAgents[b.id] ?? 0).compareTo(scoredAgents[a.id] ?? 0)
      );
      
      // Exclure les agents déjà favoris pour la section "Recommandés pour vous"
      final recommendedAgents = allAgents.where(
        (agent) => !preferences.favoriteAgentIds.contains(agent.id)
      ).take(limit).toList();
      
      return recommendedAgents;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la récupération des recommandations: ${e.toString()}');
      }
      return [];
    }
  }
  
  // Obtenir des agents similaires à un agent donné
  Future<List<AgentModel>> getSimilarAgents(String agentId, {int limit = 3}) async {
    try {
      // Récupérer l'agent de référence
      final docSnapshot = await _agentsCollection.doc(agentId).get();
      
      if (!docSnapshot.exists) {
        return [];
      }
      
      final referenceAgent = AgentModel.fromMap(
        docSnapshot.data() as Map<String, dynamic>,
        docSnapshot.id,
      );
      
      // Récupérer tous les autres agents
      final agentsSnapshot = await _agentsCollection.get();
      final otherAgents = agentsSnapshot.docs
          .where((doc) => doc.id != agentId)
          .map((doc) => AgentModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ))
          .toList();
      
      // Calculer un score de similarité pour chaque agent
      final scoredAgents = <String, double>{};
      
      for (final agent in otherAgents) {
        double similarityScore = 0;
        
        // Similarité basée sur la profession
        if (agent.profession == referenceAgent.profession) {
          similarityScore += 3;
        }
        
        // Similarité basée sur le niveau d'éducation
        if (agent.educationLevel == referenceAgent.educationLevel) {
          similarityScore += 2;
        }
        
        // Similarité basée sur la certification
        if (agent.isCertified == referenceAgent.isCertified) {
          similarityScore += 1;
        }
        
        // Similarité basée sur l'âge (proximité)
        final ageDifference = (agent.age - referenceAgent.age).abs();
        if (ageDifference <= 5) {
          similarityScore += 1;
        }
        
        // Bonus pour les agents bien notés
        similarityScore += agent.averageRating / 2;
        
        // Enregistrer le score
        scoredAgents[agent.id] = similarityScore;
      }
      
      // Trier les agents par score de similarité
      otherAgents.sort((a, b) => 
        (scoredAgents[b.id] ?? 0).compareTo(scoredAgents[a.id] ?? 0)
      );
      
      // Prendre les N agents les plus similaires
      return otherAgents.take(limit).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la récupération des agents similaires: ${e.toString()}');
      }
      return [];
    }
  }
  
  // Mettre à jour les préférences de catégorie basées sur l'historique
  Future<void> updateCategoryPreferences(String userId) async {
    try {
      // Récupérer l'historique des réservations
      final reservationsSnapshot = await _reservationsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      if (reservationsSnapshot.docs.isEmpty) {
        return;
      }
      
      final reservations = reservationsSnapshot.docs.map((doc) => 
        ReservationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();
      
      // Récupérer les agents correspondants
      final agentIds = reservations.map((r) => r.agentId).toSet().toList();
      final agents = <AgentModel>[];
      
      for (final agentId in agentIds) {
        final docSnapshot = await _agentsCollection.doc(agentId).get();
        
        if (docSnapshot.exists) {
          agents.add(AgentModel.fromMap(
            docSnapshot.data() as Map<String, dynamic>,
            docSnapshot.id,
          ));
        }
      }
      
      // Calculer les préférences de catégorie
      final categoryScores = <String, double>{};
      
      for (final reservation in reservations) {
        final agent = agents.firstWhere(
          (a) => a.id == reservation.agentId,
          orElse: () => throw Exception('Agent non trouvé'),
        );
        
        // Utiliser la profession comme catégorie
        final category = agent.profession;
        
        // Ajouter un score basé sur la note (ou 3 par défaut)
        final score = reservation.rating ?? 3.0;
        
        categoryScores[category] = (categoryScores[category] ?? 0) + score;
      }
      
      // Normaliser les scores
      final totalScore = categoryScores.values.fold(0.0, (sum, score) => sum + score);
      
      final normalizedScores = <String, double>{};
      
      if (totalScore > 0) {
        categoryScores.forEach((category, score) {
          normalizedScores[category] = score / totalScore;
        });
      }
      
      // Mettre à jour les préférences
      final preferences = await getUserPreferences(userId);
      final updatedPreferences = preferences.copyWith(
        categoryPreferences: normalizedScores,
        lastUpdated: DateTime.now(),
      );
      
      await updateUserPreferences(updatedPreferences);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la mise à jour des préférences de catégorie: ${e.toString()}');
      }
    }
  }
}
