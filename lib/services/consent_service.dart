import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/consent_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'audit_service.dart';

// Service pour la gestion des consentements RGPD
class ConsentService {
  final FirebaseFirestore _firestore;
  final AuthService _authService;
  final AuditService _auditService;

  // Références aux collections Firestore
  final CollectionReference _consentsCollection;
  final CollectionReference _auditLogsCollection;

  ConsentService({
    required FirebaseFirestore firestore,
    required AuthService authService,
    required AuditService auditService,
  })  : _firestore = firestore,
        _authService = authService,
        _auditService = auditService,
        _consentsCollection = firestore.collection('user_consents'),
        _auditLogsCollection = firestore.collection('audit_logs');

  // Obtenir les consentements d'un utilisateur
  Future<ConsentModel?> getUserConsents(String userId) async {
    try {
      final docSnapshot = await _consentsCollection.doc(userId).get();
      
      if (!docSnapshot.exists) {
        return null;
      }

      return ConsentModel.fromMap(docSnapshot.data() as Map<String, dynamic>, userId);
    } catch (e) {
      debugPrint('Erreur lors de la récupération des consentements: $e');
      return null;
    }
  }

  // Créer ou obtenir les consentements par défaut pour un utilisateur
  Future<ConsentModel> getOrCreateUserConsents(String userId) async {
    try {
      final existingConsents = await getUserConsents(userId);
      
      if (existingConsents != null) {
        return existingConsents;
      }

      // Créer les consentements par défaut
      final defaultConsents = ConsentModel.createDefault(userId);
      await _consentsCollection.doc(userId).set(defaultConsents.toMap());

      // Logger la création des consentements
      await _auditService.logAction(
        adminId: userId,
        adminEmail: 'System',
        action: 'create_default_consents',
        targetType: 'user_consents',
        targetId: userId,
        description: 'Création des consentements par défaut pour l\'utilisateur',
        newData: defaultConsents.toMap(),
      );

      return defaultConsents;
    } catch (e) {
      debugPrint('Erreur lors de la création des consentements: $e');
      throw Exception('Impossible de créer les consentements: ${e.toString()}');
    }
  }

  // Mettre à jour un consentement
  Future<ConsentModel> updateConsent({
    required String userId,
    required String consentType,
    required bool granted,
    DateTime? expiresAt,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      // Vérifier que l'utilisateur est connecté et a le droit de modifier ses consentements
      final currentUser = _authService.currentUser;
      if (currentUser == null || currentUser.uid != userId) {
        throw Exception('Vous devez être connecté pour modifier vos consentements');
      }

      // Obtenir les consentements actuels
      final currentConsents = await getOrCreateUserConsents(userId);
      
      // Vérifier si le consentement peut être modifié
      final consentData = currentConsents.consents[consentType];
      if (consentData?.required == true && !granted) {
        throw Exception('Ce consentement est obligatoire et ne peut pas être refusé');
      }

      // Mettre à jour le consentement
      final updatedConsents = currentConsents.updateConsent(consentType, granted, expiresAt: expiresAt);
      
      // Ajouter les informations de contexte
      final finalConsents = updatedConsents.copyWith(
        ipAddress: ipAddress,
        userAgent: userAgent,
      );

      // Sauvegarder dans Firestore
      await _consentsCollection.doc(userId).set(finalConsents.toMap());

      // Logger la modification
      await _auditService.logAction(
        adminId: userId,
        adminEmail: currentUser.email ?? 'Unknown',
        action: granted ? 'grant_consent' : 'revoke_consent',
        targetType: 'user_consent',
        targetId: consentType,
        description: '${granted ? "Accord" : "Retrait"} du consentement pour $consentType',
        oldData: {'consentType': consentType, 'granted': currentConsents.hasConsent(consentType)},
        newData: {'consentType': consentType, 'granted': granted, 'expiresAt': expiresAt?.toIso8601String()},
        ipAddress: ipAddress,
        userAgent: userAgent,
      );

      return finalConsents;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du consentement: $e');
      throw Exception('Impossible de mettre à jour le consentement: ${e.toString()}');
    }
  }

  // Mettre à jour plusieurs consentements à la fois
  Future<ConsentModel> updateMultipleConsents({
    required String userId,
    required Map<String, bool> consentUpdates,
    Map<String, DateTime?>? expiryDates,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      // Vérifier que l'utilisateur est connecté
      final currentUser = _authService.currentUser;
      if (currentUser == null || currentUser.uid != userId) {
        throw Exception('Vous devez être connecté pour modifier vos consentements');
      }

      // Obtenir les consentements actuels
      final currentConsents = await getOrCreateUserConsents(userId);
      var updatedConsents = currentConsents;

      // Mettre à jour chaque consentement
      for (final entry in consentUpdates.entries) {
        final consentType = entry.key;
        final granted = entry.value;
        final expiresAt = expiryDates?[consentType];

        // Vérifier si le consentement peut être modifié
        final consentData = currentConsents.consents[consentType];
        if (consentData?.required == true && !granted) {
          debugPrint('Le consentement $consentType est obligatoire et ne peut pas être refusé');
          continue;
        }

        updatedConsents = updatedConsents.updateConsent(consentType, granted, expiresAt: expiresAt);
      }

      // Ajouter les informations de contexte
      final finalConsents = updatedConsents.copyWith(
        ipAddress: ipAddress,
        userAgent: userAgent,
      );

      // Sauvegarder dans Firestore
      await _consentsCollection.doc(userId).set(finalConsents.toMap());

      // Logger la modification groupée
      await _auditService.logAction(
        adminId: userId,
        adminEmail: currentUser.email ?? 'Unknown',
        action: 'update_multiple_consents',
        targetType: 'user_consents',
        targetId: userId,
        description: 'Mise à jour de ${consentUpdates.length} consentements',
        oldData: consentUpdates,
        newData: Map.fromEntries(
          consentUpdates.entries.map((entry) => MapEntry(entry.key, {
            'granted': entry.value,
            'expiresAt': expiryDates?[entry.key]?.toIso8601String(),
          })),
        ),
        ipAddress: ipAddress,
        userAgent: userAgent,
      );

      return finalConsents;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour multiple des consentements: $e');
      throw Exception('Impossible de mettre à jour les consentements: ${e.toString()}');
    }
  }

  // Révoquer tous les consentements non obligatoires
  Future<ConsentModel> revokeAllNonRequiredConsents({
    required String userId,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      // Vérifier que l'utilisateur est connecté
      final currentUser = _authService.currentUser;
      if (currentUser == null || currentUser.uid != userId) {
        throw Exception('Vous devez être connecté pour révoquer vos consentements');
      }

      // Obtenir les consentements actuels
      final currentConsents = await getOrCreateUserConsents(userId);
      
      // Révoquer tous les consentements non obligatoires
      final updatedConsents = currentConsents.revokeAllConsents();
      
      // Ajouter les informations de contexte
      final finalConsents = updatedConsents.copyWith(
        ipAddress: ipAddress,
        userAgent: userAgent,
      );

      // Sauvegarder dans Firestore
      await _consentsCollection.doc(userId).set(finalConsents.toMap());

      // Logger la révocation
      await _auditService.logAction(
        adminId: userId,
        adminEmail: currentUser.email ?? 'Unknown',
        action: 'revoke_all_consents',
        targetType: 'user_consents',
        targetId: userId,
        description: 'Révocation de tous les consentements non obligatoires',
        oldData: currentConsents.consents.map((key, value) => MapEntry(key, value.granted)),
        newData: finalConsents.consents.map((key, value) => MapEntry(key, value.granted)),
        ipAddress: ipAddress,
        userAgent: userAgent,
      );

      return finalConsents;
    } catch (e) {
      debugPrint('Erreur lors de la révocation des consentements: $e');
      throw Exception('Impossible de révoquer les consentements: ${e.toString()}');
    }
  }

  // Vérifier si un utilisateur a donné son consentement pour un type spécifique
  Future<bool> hasConsent(String userId, String consentType) async {
    try {
      final consents = await getUserConsents(userId);
      return consents?.hasConsent(consentType) ?? false;
    } catch (e) {
      debugPrint('Erreur lors de la vérification du consentement: $e');
      return false;
    }
  }

  // Vérifier si un consentement est valide (accordé et non expiré)
  Future<bool> isConsentValid(String userId, String consentType) async {
    try {
      final consents = await getUserConsents(userId);
      if (consents == null) return false;
      
      return consents.hasConsent(consentType) && !consents.isConsentExpired(consentType);
    } catch (e) {
      debugPrint('Erreur lors de la validation du consentement: $e');
      return false;
    }
  }

  // Obtenir tous les consentements valides d'un utilisateur
  Future<Map<String, ConsentData>> getValidConsents(String userId) async {
    try {
      final consents = await getUserConsents(userId);
      return consents?.getGrantedConsents() ?? {};
    } catch (e) {
      debugPrint('Erreur lors de la récupération des consentements valides: $e');
      return {};
    }
  }

  // Vérifier les consentements requis pour une fonctionnalité
  Future<bool> checkRequiredConsents(String userId, List<String> requiredConsentTypes) async {
    try {
      for (final consentType in requiredConsentTypes) {
        if (!await isConsentValid(userId, consentType)) {
          return false;
        }
      }
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la vérification des consentements requis: $e');
      return false;
    }
  }

  // Obtenir les consentements qui vont expirer bientôt
  Future<Map<String, ConsentData>> getExpiringConsents(String userId, {Duration within = const Duration(days: 7)}) async {
    try {
      final consents = await getUserConsents(userId);
      if (consents == null) return {};

      final now = DateTime.now();
      final expiringSoon = <String, ConsentData>{};

      for (final entry in consents.consents.entries) {
        final consentType = entry.key;
        final consentData = entry.value;

        if (consentData.granted && 
            consentData.expiresAt != null && 
            consentData.expiresAt!.difference(now).inDays <= within.inDays) {
          expiringSoon[consentType] = consentData;
        }
      }

      return expiringSoon;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des consentements expirants: $e');
      return {};
    }
  }

  // Mettre à jour la version des consentements (pour les changements de politique)
  Future<ConsentModel> updateConsentVersion({
    required String userId,
    required String newVersion,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      // Vérifier que l'utilisateur est connecté
      final currentUser = _authService.currentUser;
      if (currentUser == null || currentUser.uid != userId) {
        throw Exception('Vous devez être connecté pour mettre à jour vos consentements');
      }

      // Obtenir les consentements actuels
      final currentConsents = await getOrCreateUserConsents(userId);
      
      // Mettre à jour la version
      final updatedConsents = currentConsents.copyWith(
        version: newVersion,
        ipAddress: ipAddress,
        userAgent: userAgent,
      );

      // Sauvegarder dans Firestore
      await _consentsCollection.doc(userId).set(updatedConsents.toMap());

      // Logger la mise à jour de version
      await _auditService.logAction(
        adminId: userId,
        adminEmail: currentUser.email ?? 'Unknown',
        action: 'update_consent_version',
        targetType: 'user_consents',
        targetId: userId,
        description: 'Mise à jour de la version des consentements vers $newVersion',
        oldData: {'version': currentConsents.version},
        newData: {'version': newVersion},
        ipAddress: ipAddress,
        userAgent: userAgent,
      );

      return updatedConsents;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de la version des consentements: $e');
      throw Exception('Impossible de mettre à jour la version des consentements: ${e.toString()}');
    }
  }

  // Supprimer les consentements d'un utilisateur (droit à l'oubli)
  Future<void> deleteUserConsents(String userId, {String? reason}) async {
    try {
      // Vérifier que l'utilisateur est connecté et a les permissions
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('Vous devez être connecté pour supprimer des consentements');
      }

      // Obtenir les consentements avant suppression pour l'audit
      final consents = await getUserConsents(userId);

      // Supprimer les consentements
      await _consentsCollection.doc(userId).delete();

      // Logger la suppression
      await _auditService.logAction(
        adminId: currentUser.uid,
        adminEmail: currentUser.email ?? 'Unknown',
        action: 'delete_user_consents',
        targetType: 'user_consents',
        targetId: userId,
        description: 'Suppression des consentements de l\'utilisateur${reason != null ? ' - Raison: $reason' : ''}',
        oldData: consents?.toMap(),
        metadata: {'reason': reason},
      );
    } catch (e) {
      debugPrint('Erreur lors de la suppression des consentements: $e');
      throw Exception('Impossible de supprimer les consentements: ${e.toString()}');
    }
  }

  // Exporter les consentements d'un utilisateur (portabilité des données)
  Future<Map<String, dynamic> exportUserConsents(String userId) async {
    try {
      // Vérifier que l'utilisateur est connecté et a les permissions
      final currentUser = _authService.currentUser;
      if (currentUser == null || currentUser.uid != userId) {
        throw Exception('Vous devez être connecté pour exporter vos consentements');
      }

      final consents = await getUserConsents(userId);
      if (consents == null) {
        return {'error': 'Aucun consentement trouvé pour cet utilisateur'};
      }

      // Préparer les données pour l'export
      final exportData = {
        'userId': userId,
        'exportDate': DateTime.now().toIso8601String(),
        'version': consents.version,
        'lastUpdated': consents.lastUpdated.toIso8601String(),
        'consents': consents.consents.map((key, value) => MapEntry(key, {
          'granted': value.granted,
          'grantedAt': value.grantedAt?.toIso8601String(),
          'expiresAt': value.expiresAt?.toIso8601String(),
          'description': value.description,
          'purpose': value.purpose,
          'required': value.required,
          'isValid': value.isValid(),
        })),
      };

      // Logger l'export
      await _auditService.logAction(
        adminId: userId,
        adminEmail: currentUser.email ?? 'Unknown',
        action: 'export_user_consents',
        targetType: 'user_consents',
        targetId: userId,
        description: 'Export des consentements de l\'utilisateur',
        metadata: {'exportSize': exportData.toString().length},
      );

      return exportData;
    } catch (e) {
      debugPrint('Erreur lors de l\'export des consentements: $e');
      throw Exception('Impossible d\'exporter les consentements: ${e.toString()}');
    }
  }

  // Obtenir des statistiques sur les consentements (pour les administrateurs)
  Future<Map<String, dynamic>> getConsentStatistics() async {
    try {
      // Vérifier que l'utilisateur est un administrateur
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('Vous devez être connecté');
      }

      final snapshot = await _consentsCollection.get();
      final allConsents = snapshot.docs.map((doc) => 
        ConsentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();

      if (allConsents.isEmpty) {
        return {'totalUsers': 0, 'statistics': {}};
      }

      // Calculer les statistiques
      final statistics = <String, dynamic>{};
      final totalUsers = allConsents.length;

      // Pour chaque type de consentement
      for (final consentType in ConsentType.values) {
        final typeKey = consentType.key;
        final grantedCount = allConsents.where((c) => c.hasConsent(typeKey)).length;
        final expiredCount = allConsents.where((c) => c.isConsentExpired(typeKey)).length;

        statistics[typeKey] = {
          'granted': grantedCount,
          'grantedPercentage': (grantedCount / totalUsers * 100).toStringAsFixed(1),
          'expired': expiredCount,
          'expiredPercentage': (expiredCount / totalUsers * 100).toStringAsFixed(1),
        };
      }

      return {
        'totalUsers': totalUsers,
        'statistics': statistics,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Erreur lors de l\'obtention des statistiques: $e');
      throw Exception('Impossible d\'obtenir les statistiques: ${e.toString()}');
    }
  }
}
