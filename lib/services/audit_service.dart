import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

import '../models/audit_log_model.dart';

// Service pour l'audit et les logs des actions administratives
final logger = Logger();
class AuditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference _auditCollection;

  AuditService() {
    _auditCollection = _firestore.collection('audit_logs');
  }

  // Enregistrer une action administrative
  Future<void> logAdminAction({
    required String adminId,
    required String adminEmail,
    required String action,
    required String targetType, // 'agent', 'user', 'reservation', 'settings'
    required String targetId,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
    String? description,
  }) async {
    try {
      final auditLog = AuditLogModel(
        id: '', // Sera généré par Firestore
        adminId: adminId,
        adminEmail: adminEmail,
        action: action,
        targetType: targetType,
        targetId: targetId,
        oldData: oldData,
        newData: newData,
        description: description,
        timestamp: DateTime.now(),
        ipAddress: await _getClientIP(),
        userAgent: await _getUserAgent(),
      );

      await _auditCollection.add(auditLog.toMap());
    } catch (e) {
      // En cas d'erreur, on ne veut pas bloquer l'action principale
      logger.w('Erreur lors de l\'enregistrement du log d\'audit: $e');
    }
  }

  // Récupérer les logs d'audit avec pagination
  Future<List<AuditLogModel>> getAuditLogs({
    int limit = 50,
    DocumentSnapshot? startAfter,
    String? adminId,
    String? targetType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query query = _auditCollection.orderBy('timestamp', descending: true);

    // Filtres optionnels
    if (adminId != null) {
      query = query.where('adminId', isEqualTo: adminId);
    }
    if (targetType != null) {
      query = query.where('targetType', isEqualTo: targetType);
    }
    if (startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
    }
    if (endDate != null) {
      query = query.where('timestamp', isLessThanOrEqualTo: endDate);
    }

    // Pagination
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => AuditLogModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ))
        .toList();
  }

  // Rechercher dans les logs
  Future<List<AuditLogModel>> searchAuditLogs({
    required String searchTerm,
    int limit = 50,
  }) async {
    // Note: Firestore ne supporte pas la recherche full-text native
    // Cette implémentation est basique et pourrait être améliorée avec Algolia
    final snapshot = await _auditCollection
        .orderBy('timestamp', descending: true)
        .limit(limit * 3) // Récupérer plus pour filtrer ensuite
        .get();

    final logs = snapshot.docs
        .map((doc) => AuditLogModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ))
        .where((log) =>
            log.action.toLowerCase().contains(searchTerm.toLowerCase()) ||
            log.adminEmail.toLowerCase().contains(searchTerm.toLowerCase()) ||
            log.targetId.toLowerCase().contains(searchTerm.toLowerCase()) ||
            (log.description?.toLowerCase().contains(searchTerm.toLowerCase()) ?? false))
        .take(limit)
        .toList();

    return logs;
  }

  // Obtenir des statistiques d'audit
  Future<Map<String, dynamic>> getAuditStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query query = _auditCollection;

    if (startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
    }
    if (endDate != null) {
      query = query.where('timestamp', isLessThanOrEqualTo: endDate);
    }

    final snapshot = await query.get();
    final logs = snapshot.docs
        .map((doc) => AuditLogModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ))
        .toList();

    // Calculer les statistiques
    final Map<String, int> actionCounts = {};
    final Map<String, int> adminCounts = {};
    final Map<String, int> targetTypeCounts = {};

    for (final log in logs) {
      actionCounts[log.action] = (actionCounts[log.action] ?? 0) + 1;
      adminCounts[log.adminEmail] = (adminCounts[log.adminEmail] ?? 0) + 1;
      targetTypeCounts[log.targetType] = (targetTypeCounts[log.targetType] ?? 0) + 1;
    }

    return {
      'totalLogs': logs.length,
      'actionCounts': actionCounts,
      'adminCounts': adminCounts,
      'targetTypeCounts': targetTypeCounts,
      'period': {
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
      },
    };
  }

  // Nettoyer les anciens logs (à exécuter périodiquement)
  Future<void> cleanupOldLogs({int retentionDays = 365}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
    
    final snapshot = await _auditCollection
        .where('timestamp', isLessThan: cutoffDate)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Méthodes utilitaires (à implémenter selon la plateforme)
  Future<String?> _getClientIP() async {
    // Implémentation dépendante de la plateforme
    return null;
  }

  Future<String?> _getUserAgent() async {
    // Implémentation dépendante de la plateforme
    return null;
  }
}

