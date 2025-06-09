import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Modèle pour les logs d'audit
class AuditLogModel {
  final String id;
  final String adminId;
  final String adminEmail;
  final String action;
  final String targetType;
  final String targetId;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final String? description;
  final DateTime timestamp;
  final String? ipAddress;
  final String? userAgent;
  final String? sessionId;
  final Map<String, dynamic>? metadata;

  AuditLogModel({
    required this.id,
    required this.adminId,
    required this.adminEmail,
    required this.action,
    required this.targetType,
    required this.targetId,
    this.oldData,
    this.newData,
    this.description,
    required this.timestamp,
    this.ipAddress,
    this.userAgent,
    this.sessionId,
    this.metadata,
  });

  // Créer une instance depuis une Map (Firestore)
  factory AuditLogModel.fromMap(Map<String, dynamic> map, String id) {
    return AuditLogModel(
      id: id,
      adminId: map['adminId'] ?? '',
      adminEmail: map['adminEmail'] ?? '',
      action: map['action'] ?? '',
      targetType: map['targetType'] ?? '',
      targetId: map['targetId'] ?? '',
      oldData:
          map['oldData'] != null
              ? Map<String, dynamic>.from(map['oldData'])
              : null,
      newData:
          map['newData'] != null
              ? Map<String, dynamic>.from(map['newData'])
              : null,
      description: map['description'],
      timestamp:
          map['timestamp'] is Timestamp
              ? (map['timestamp'] as Timestamp).toDate()
              : DateTime.parse(map['timestamp']),
      ipAddress: map['ipAddress'],
      userAgent: map['userAgent'],
      sessionId: map['sessionId'],
      metadata:
          map['metadata'] != null
              ? Map<String, dynamic>.from(map['metadata'])
              : null,
    );
  }

  // Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'adminId': adminId,
      'adminEmail': adminEmail,
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'oldData': oldData,
      'newData': newData,
      'description': description,
      'timestamp': timestamp,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'sessionId': sessionId,
      'metadata': metadata,
    };
  }

  // Créer une copie avec des modifications
  AuditLogModel copyWith({
    String? id,
    String? adminId,
    String? adminEmail,
    String? action,
    String? targetType,
    String? targetId,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
    String? description,
    DateTime? timestamp,
    String? ipAddress,
    String? userAgent,
    String? sessionId,
    Map<String, dynamic>? metadata,
  }) {
    return AuditLogModel(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      adminEmail: adminEmail ?? this.adminEmail,
      action: action ?? this.action,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      oldData: oldData ?? this.oldData,
      newData: newData ?? this.newData,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      sessionId: sessionId ?? this.sessionId,
      metadata: metadata ?? this.metadata,
    );
  }

  // Obtenir un résumé des changements
  String getChangesSummary() {
    if (oldData == null && newData == null) {
      return 'Aucun changement de données';
    }

    final changes = <String>[];

    if (oldData != null && newData != null) {
      // Comparer les anciennes et nouvelles données
      final allKeys = {...oldData!.keys, ...newData!.keys};

      for (final key in allKeys) {
        final oldValue = oldData![key];
        final newValue = newData![key];

        if (oldValue != newValue) {
          if (oldValue == null) {
            changes.add('$key: ajouté ($newValue)');
          } else if (newValue == null) {
            changes.add('$key: supprimé ($oldValue)');
          } else {
            changes.add('$key: $oldValue → $newValue');
          }
        }
      }
    } else if (newData != null) {
      changes.add('Données créées: ${newData!.keys.join(', ')}');
    } else if (oldData != null) {
      changes.add('Données supprimées: ${oldData!.keys.join(', ')}');
    }

    return changes.isEmpty ? 'Aucun changement détecté' : changes.join(', ');
  }

  // Obtenir la gravité de l'action
  AuditSeverity getSeverity() {
    switch (action.toLowerCase()) {
      case 'delete':
      case 'remove':
      case 'ban':
      case 'suspend':
        return AuditSeverity.critical;

      case 'update':
      case 'modify':
      case 'change_permissions':
      case 'approve':
      case 'reject':
        return AuditSeverity.high;

      case 'create':
      case 'add':
      case 'login':
        return AuditSeverity.medium;

      case 'view':
      case 'read':
      case 'search':
        return AuditSeverity.low;

      default:
        return AuditSeverity.medium;
    }
  }

  // Vérifier si l'action est sensible
  bool get isSensitiveAction {
    const sensitiveActions = [
      'delete',
      'remove',
      'ban',
      'suspend',
      'change_permissions',
      'update_settings',
      'export_data',
    ];

    return sensitiveActions.contains(action.toLowerCase());
  }

  // Obtenir une description formatée
  String getFormattedDescription() {
    if (description != null && description!.isNotEmpty) {
      return description!;
    }

    // Générer une description automatique
    switch (action.toLowerCase()) {
      case 'create':
        return 'Création de $targetType (ID: $targetId)';
      case 'update':
        return 'Modification de $targetType (ID: $targetId)';
      case 'delete':
        return 'Suppression de $targetType (ID: $targetId)';
      case 'login':
        return 'Connexion administrateur';
      case 'logout':
        return 'Déconnexion administrateur';
      default:
        return 'Action $action sur $targetType (ID: $targetId)';
    }
  }

  @override
  String toString() {
    return 'AuditLogModel(id: $id, action: $action, targetType: $targetType, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AuditLogModel &&
        other.id == id &&
        other.adminId == adminId &&
        other.action == action &&
        other.targetType == targetType &&
        other.targetId == targetId &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        adminId.hashCode ^
        action.hashCode ^
        targetType.hashCode ^
        targetId.hashCode ^
        timestamp.hashCode;
  }
}

// Énumération pour la gravité des actions d'audit
enum AuditSeverity { low, medium, high, critical }

// Extension pour obtenir des informations sur la gravité
extension AuditSeverityExtension on AuditSeverity {
  String get name {
    switch (this) {
      case AuditSeverity.low:
        return 'Faible';
      case AuditSeverity.medium:
        return 'Moyenne';
      case AuditSeverity.high:
        return 'Élevée';
      case AuditSeverity.critical:
        return 'Critique';
    }
  }

  Color get color {
    switch (this) {
      case AuditSeverity.low:
        return const Color(0xFF4CAF50); // Vert
      case AuditSeverity.medium:
        return const Color(0xFF2196F3); // Bleu
      case AuditSeverity.high:
        return const Color(0xFFFF9800); // Orange
      case AuditSeverity.critical:
        return const Color(0xFFF44336); // Rouge
    }
  }

  IconData get icon {
    switch (this) {
      case AuditSeverity.low:
        return Icons.info;
      case AuditSeverity.medium:
        return Icons.notifications;
      case AuditSeverity.high:
        return Icons.warning;
      case AuditSeverity.critical:
        return Icons.error;
    }
  }
}

// Classe utilitaire pour les filtres d'audit
class AuditFilter {
  final String? adminId;
  final String? targetType;
  final String? action;
  final DateTime? startDate;
  final DateTime? endDate;
  final AuditSeverity? severity;
  final bool? sensitiveOnly;

  const AuditFilter({
    this.adminId,
    this.targetType,
    this.action,
    this.startDate,
    this.endDate,
    this.severity,
    this.sensitiveOnly,
  });

  // Vérifier si un log correspond aux filtres
  bool matches(AuditLogModel log) {
    if (adminId != null && log.adminId != adminId) return false;
    if (targetType != null && log.targetType != targetType) return false;
    if (action != null && log.action != action) return false;
    if (startDate != null && log.timestamp.isBefore(startDate!)) return false;
    if (endDate != null && log.timestamp.isAfter(endDate!)) return false;
    if (severity != null && log.getSeverity() != severity) return false;
    if (sensitiveOnly == true && !log.isSensitiveAction) return false;

    return true;
  }

  // Créer une copie avec des modifications
  AuditFilter copyWith({
    String? adminId,
    String? targetType,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
    AuditSeverity? severity,
    bool? sensitiveOnly,
  }) {
    return AuditFilter(
      adminId: adminId ?? this.adminId,
      targetType: targetType ?? this.targetType,
      action: action ?? this.action,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      severity: severity ?? this.severity,
      sensitiveOnly: sensitiveOnly ?? this.sensitiveOnly,
    );
  }
}
