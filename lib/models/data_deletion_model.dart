import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Modèle pour la gestion des demandes de suppression de données (Droit à l'oubli RGPD)
class DataDeletionRequestModel {
  final String id;
  final String userId;
  final String userEmail;
  final DeletionReason reason;
  final String? additionalComments;
  final DeletionStatus status;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final String? processedBy;
  final String? rejectionReason;
  final Map<String, bool> dataCategories;
  final DateTime? scheduledFor;
  final bool isUrgent;
  final String? ipAddress;
  final String? userAgent;

  DataDeletionRequestModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.reason,
    this.additionalComments,
    required this.status,
    required this.requestedAt,
    this.processedAt,
    this.processedBy,
    this.rejectionReason,
    required this.dataCategories,
    this.scheduledFor,
    this.isUrgent = false,
    this.ipAddress,
    this.userAgent,
  });

  // Conversion depuis Firestore
  factory DataDeletionRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return DataDeletionRequestModel(
      id: id,
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      reason: DeletionReason.values.firstWhere(
        (e) => e.name == (map['reason'] ?? 'account_closure'),
        orElse: () => DeletionReason.account_closure,
      ),
      additionalComments: map['additionalComments'],
      status: DeletionStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'pending'),
        orElse: () => DeletionStatus.pending,
      ),
      requestedAt: (map['requestedAt'] as Timestamp).toDate(),
      processedAt: map['processedAt'] != null 
          ? (map['processedAt'] as Timestamp).toDate() 
          : null,
      processedBy: map['processedBy'],
      rejectionReason: map['rejectionReason'],
      dataCategories: Map<String, bool>.from(map['dataCategories'] ?? {}),
      scheduledFor: map['scheduledFor'] != null 
          ? (map['scheduledFor'] as Timestamp).toDate() 
          : null,
      isUrgent: map['isUrgent'] ?? false,
      ipAddress: map['ipAddress'],
      userAgent: map['userAgent'],
    );
  }

  // Conversion vers Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'reason': reason.name,
      'additionalComments': additionalComments,
      'status': status.name,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'processedBy': processedBy,
      'rejectionReason': rejectionReason,
      'dataCategories': dataCategories,
      'scheduledFor': scheduledFor != null ? Timestamp.fromDate(scheduledFor!) : null,
      'isUrgent': isUrgent,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
    };
  }

  // Créer une nouvelle demande de suppression
  factory DataDeletionRequestModel.create({
    required String userId,
    required String userEmail,
    required DeletionReason reason,
    String? additionalComments,
    Map<String, bool>? dataCategories,
    bool isUrgent = false,
    String? ipAddress,
    String? userAgent,
  }) {
    return DataDeletionRequestModel(
      id: '', // Sera généré par Firestore
      userId: userId,
      userEmail: userEmail,
      reason: reason,
      additionalComments: additionalComments,
      status: DeletionStatus.pending,
      requestedAt: DateTime.now(),
      dataCategories: dataCategories ?? {
        'profile': true,
        'reservations': true,
        'reviews': true,
        'payments': true,
        'communications': true,
        'preferences': true,
        'consents': true,
        'audit_logs': false, // Les logs d'audit sont généralement conservés pour des raisons légales
      },
      isUrgent: isUrgent,
      ipAddress: ipAddress,
      userAgent: userAgent,
    );
  }

  // Approuver la demande de suppression
  DataDeletionRequestModel approve({
    required String processedBy,
    DateTime? scheduledFor,
  }) {
    return copyWith(
      status: DeletionStatus.approved,
      processedAt: DateTime.now(),
      processedBy: processedBy,
      scheduledFor: scheduledFor ?? DateTime.now().add(const Duration(days: 30)),
    );
  }

  // Rejeter la demande de suppression
  DataDeletionRequestModel reject({
    required String processedBy,
    required String rejectionReason,
  }) {
    return copyWith(
      status: DeletionStatus.rejected,
      processedAt: DateTime.now(),
      processedBy: processedBy,
      rejectionReason: rejectionReason,
    );
  }

  // Marquer comme en cours de traitement
  DataDeletionRequestModel markAsProcessing({
    required String processedBy,
  }) {
    return copyWith(
      status: DeletionStatus.processing,
      processedAt: DateTime.now(),
      processedBy: processedBy,
    );
  }

  // Marquer comme complété
  DataDeletionRequestModel markAsCompleted({
    required String processedBy,
  }) {
    return copyWith(
      status: DeletionStatus.completed,
      processedAt: DateTime.now(),
      processedBy: processedBy,
    );
  }

  // Marquer comme échoué
  DataDeletionRequestModel markAsFailed({
    required String processedBy,
    required String failureReason,
  }) {
    return copyWith(
      status: DeletionStatus.failed,
      processedAt: DateTime.now(),
      processedBy: processedBy,
      rejectionReason: failureReason,
    );
  }

  // Reporter la suppression
  DataDeletionRequestModel postpone({
    required String processedBy,
    required DateTime newScheduledDate,
    required String reason,
  }) {
    return copyWith(
      status: DeletionStatus.postponed,
      processedAt: DateTime.now(),
      processedBy: processedBy,
      scheduledFor: newScheduledDate,
      rejectionReason: reason,
    );
  }

  // Vérifier si la demande peut être traitée
  bool canBeProcessed() {
    return status == DeletionStatus.approved && 
           (scheduledFor == null || DateTime.now().isAfter(scheduledFor!));
  }

  // Vérifier si la demande est urgente
  bool get isUrgentRequest {
    return isUrgent || reason == DeletionReason.legal_requirement;
  }

  // Obtenir les délais légaux de traitement
  Duration getLegalDeadline {
    if (isUrgentRequest) {
      return const Duration(days: 7); // 7 jours pour les demandes urgentes
    }
    return const Duration(days: 30); // 30 jours pour les demandes standard
  }

  // Vérifier si la demande est en retard
  bool get isOverdue {
    final deadline = requestedAt.add(legalDeadline);
    return DateTime.now().isAfter(deadline) && status != DeletionStatus.completed;
  }

  // Obtenir un résumé des données à supprimer
  String getDataSummary() {
    final categoriesToDelete = dataCategories.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (categoriesToDelete.isEmpty) return 'Aucune donnée à supprimer';
    
    if (categoriesToDelete.length == dataCategories.length) {
      return 'Toutes les données personnelles';
    }

    return 'Données: ${categoriesToDelete.join(', ')}';
  }

  // Copie avec modification
  DataDeletionRequestModel copyWith({
    String? id,
    String? userId,
    String? userEmail,
    DeletionReason? reason,
    String? additionalComments,
    DeletionStatus? status,
    DateTime? requestedAt,
    DateTime? processedAt,
    String? processedBy,
    String? rejectionReason,
    Map<String, bool>? dataCategories,
    DateTime? scheduledFor,
    bool? isUrgent,
    String? ipAddress,
    String? userAgent,
  }) {
    return DataDeletionRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      reason: reason ?? this.reason,
      additionalComments: additionalComments ?? this.additionalComments,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      processedAt: processedAt ?? this.processedAt,
      processedBy: processedBy ?? this.processedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      dataCategories: dataCategories ?? this.dataCategories,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      isUrgent: isUrgent ?? this.isUrgent,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
    );
  }
}

// Énumération pour les raisons de suppression
enum DeletionReason {
  account_closure,
  data_correction,
  withdrawal_of_consent,
  legal_requirement,
  data_inaccuracy,
  security_breach,
  other,
}

// Extension pour les raisons de suppression
extension DeletionReasonExtension on DeletionReason {
  String get displayName {
    switch (this) {
      case DeletionReason.account_closure:
        return 'Fermeture du compte';
      case DeletionReason.data_correction:
        return 'Correction de données';
      case DeletionReason.withdrawal_of_consent:
        return 'Retrait du consentement';
      case DeletionReason.legal_requirement:
        return 'Exigence légale';
      case DeletionReason.data_inaccuracy:
        return 'Données inexactes';
      case DeletionReason.security_breach:
        return 'Violation de sécurité';
      case DeletionReason.other:
        return 'Autre';
    }
  }

  String get description {
    switch (this) {
      case DeletionReason.account_closure:
        return 'L\'utilisateur souhaite fermer son compte et supprimer toutes ses données';
      case DeletionReason.data_correction:
        return 'Correction d\'informations erronées ou obsolètes';
      case DeletionReason.withdrawal_of_consent:
        return 'Retrait du consentement pour le traitement des données';
      case DeletionReason.legal_requirement:
        return 'Obligation légale de supprimer certaines données';
      case DeletionReason.data_inaccuracy:
        return 'Les données sont inexactes ou incomplètes';
      case DeletionReason.security_breach:
        return 'Mesure de sécurité suite à une violation de données';
      case DeletionReason.other:
        return 'Autre raison non spécifiée';
    }
  }

  IconData get icon {
    switch (this) {
      case DeletionReason.account_closure:
        return Icons.person_remove;
      case DeletionReason.data_correction:
        return Icons.edit;
      case DeletionReason.withdrawal_of_consent:
        return thumbs_down;
      case DeletionReason.legal_requirement:
        return Icons.gavel;
      case DeletionReason.data_inaccuracy:
        return Icons.error_outline;
      case DeletionReason.security_breach:
        return Icons.security;
      case DeletionReason.other:
        return Icons.more_horiz;
    }
  }
}

// Énumération pour les statuts de suppression
enum DeletionStatus {
  pending,
  processing,
  approved,
  rejected,
  postponed,
  completed,
  failed,
}

// Extension pour les statuts de suppression
extension DeletionStatusExtension on DeletionStatus {
  String get displayName {
    switch (this) {
      case DeletionStatus.pending:
        return 'En attente';
      case DeletionStatus.processing:
        return 'En cours de traitement';
      case DeletionStatus.approved:
        return 'Approuvée';
      case DeletionStatus.rejected:
        return 'Rejetée';
      case DeletionStatus.postponed:
        return 'Reportée';
      case DeletionStatus.completed:
        return 'Terminée';
      case DeletionStatus.failed:
        return 'Échouée';
    }
  }

  String get description {
    switch (this) {
      case DeletionStatus.pending:
        return 'La demande est en attente de révision';
      case DeletionStatus.processing:
        return 'La suppression des données est en cours';
      case DeletionStatus.approved:
        return 'La demande a été approuvée';
      case DeletionStatus.rejected:
        return 'La demande a été rejetée';
      case DeletionStatus.postponed:
        return 'La suppression a été reportée';
      case DeletionStatus.completed:
        return 'La suppression des données est terminée';
      case DeletionStatus.failed:
        return 'La suppression des données a échoué';
    }
  }

  Color get color {
    switch (this) {
      case DeletionStatus.pending:
        return const Color(0xFFFF9800); // Orange
      case DeletionStatus.processing:
        return const Color(0xFF2196F3); // Bleu
      case DeletionStatus.approved:
        return const Color(0xFF4CAF50); // Vert
      case DeletionStatus.rejected:
        return const Color(0xFFF44336); // Rouge
      case DeletionStatus.postponed:
        return const Color(0xFF9C27B0); // Violet
      case DeletionStatus.completed:
        return const Color(0xFF009688); // Teal
      case DeletionStatus.failed:
        return const Color(0xFF795548); // Marron
    }
  }

  IconData get icon {
    switch (this) {
      case DeletionStatus.pending:
        return Icons.hourglass_empty;
      case DeletionStatus.processing:
        return Icons.sync;
      case DeletionStatus.approved:
        return Icons.check_circle;
      case DeletionStatus.rejected:
        return Icons.cancel;
      case DeletionStatus.postponed:
        return Icons.schedule;
      case DeletionStatus.completed:
        return Icons.task_alt;
      case DeletionStatus.failed:
        return Icons.error;
    }
  }

  bool get isFinal {
    return this == DeletionStatus.completed || 
           this == DeletionStatus.rejected || 
           this == DeletionStatus.failed;
  }
}

// Classe pour les catégories de données
class DataCategory {
  final String key;
  final String name;
  final String description;
  final IconData icon;
  final bool isRequired;
  final bool isSensitive;

  const DataCategory({
    required this.key,
    required this.name,
    required this.description,
    required this.icon,
    this.isRequired = false,
    this.isSensitive = false,
  });

  // Liste des catégories de données disponibles
  static const List<DataCategory> availableCategories = [
    DataCategory(
      key: 'profile',
      name: 'Profil utilisateur',
      description: 'Informations personnelles, photo de profil, coordonnées',
      icon: Icons.person,
      isSensitive: true,
    ),
    DataCategory(
      key: 'reservations',
      name: 'Réservations',
      description: 'Historique des réservations, détails des missions',
      icon: Icons.calendar_today,
      isSensitive: true,
    ),
    DataCategory(
      key: 'reviews',
      name: 'Avis et évaluations',
      description: 'Notes et commentaires laissés sur les agents',
      icon: Icons.star,
    ),
    DataCategory(
      key: 'payments',
      name: 'Paiements',
      description: 'Historique des transactions, informations de paiement',
      icon: Icons.payment,
      isSensitive: true,
      isRequired: true,
    ),
    DataCategory(
      key: 'communications',
      name: 'Communications',
      description: 'Messages, emails, notifications envoyées',
      icon: Icons.email,
    ),
    DataCategory(
      key: 'preferences',
      name: 'Préférences',
      description: 'Paramètres de l\'application, favoris, historique de recherche',
      icon: Icons.settings,
    ),
    DataCategory(
      key: 'consents',
      name: 'Consentements',
      description: 'Historique des consentements RGPD',
      icon: Icons.privacy_tip,
    ),
    DataCategory(
      key: 'audit_logs',
      name: 'Journaux d\'audit',
      description: 'Logs d\'activité et traces d\'audit',
      icon: Icons.history,
      isRequired: true,
    ),
  ];

  // Obtenir une catégorie par sa clé
  static DataCategory? getByKey(String key) {
    try {
      return availableCategories.firstWhere((category) => category.key == key);
    } catch (e) {
      return null;
    }
  }
}
