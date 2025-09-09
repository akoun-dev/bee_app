import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Modèle pour la gestion du consentement RGPD
class ConsentModel {
  final String userId;
  final Map<String, ConsentData> consents;
  final DateTime lastUpdated;
  final String version;
  final String? ipAddress;
  final String? userAgent;

  ConsentModel({
    required this.userId,
    required this.consents,
    required this.lastUpdated,
    required this.version,
    this.ipAddress,
    this.userAgent,
  });

  // Conversion depuis Firestore
  factory ConsentModel.fromMap(Map<String, dynamic> map, String id) {
    final consentsMap = map['consents'] as Map<String, dynamic>;
    final consents = consentsMap.map(
      (key, value) => MapEntry(key, ConsentData.fromMap(value)),
    );

    return ConsentModel(
      userId: id,
      consents: consents,
      lastUpdated: (map['lastUpdated'] as Timestamp).toDate(),
      version: map['version'] ?? '1.0',
      ipAddress: map['ipAddress'],
      userAgent: map['userAgent'],
    );
  }

  // Conversion vers Firestore
  Map<String, dynamic> toMap() {
    return {
      'consents': consents.map((key, value) => MapEntry(key, value.toMap())),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'version': version,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
    };
  }

  // Créer des consentements par défaut
  factory ConsentModel.createDefault(String userId) {
    return ConsentModel(
      userId: userId,
      consents: {
        'analytics': ConsentData(
          granted: false,
          grantedAt: null,
          expiresAt: null,
          description: 'Collecte de données d\'utilisation pour améliorer l\'application',
          purpose: 'Amélioration de l\'expérience utilisateur',
          required: false,
        ),
        'marketing': ConsentData(
          granted: false,
          grantedAt: null,
          expiresAt: null,
          description: 'Envoi de communications marketing et promotions',
          purpose: 'Marketing et promotion',
          required: false,
        ),
        'location': ConsentData(
          granted: false,
          grantedAt: null,
          expiresAt: null,
          description: 'Accès à votre position pour trouver les agents les plus proches',
          purpose: 'Géolocalisation et recommandation',
          required: false,
        ),
        'notifications': ConsentData(
          granted: true,
          grantedAt: DateTime.now(),
          expiresAt: null,
          description: 'Envoi de notifications pour vos réservations',
          purpose: 'Gestion des réservations',
          required: true,
        ),
        'cookies': ConsentData(
          granted: true,
          grantedAt: DateTime.now(),
          expiresAt: null,
          description: 'Utilisation de cookies pour le fonctionnement de l\'application',
          purpose: 'Fonctionnement technique',
          required: true,
        ),
        'data_sharing': ConsentData(
          granted: false,
          grantedAt: null,
          expiresAt: null,
          description: 'Partage de données avec des partenaires de confiance',
          purpose: 'Amélioration des services',
          required: false,
        ),
        'personalization': ConsentData(
          granted: false,
          grantedAt: null,
          expiresAt: null,
          description: 'Personnalisation de l\'interface et des recommandations',
          purpose: 'Expérience personnalisée',
          required: false,
        ),
      },
      lastUpdated: DateTime.now(),
      version: '1.0',
    );
  }

  // Mettre à jour un consentement
  ConsentModel updateConsent(String consentType, bool granted, {DateTime? expiresAt}) {
    final updatedConsents = Map<String, ConsentData>.from(consents);
    
    updatedConsents[consentType] = (updatedConsents[consentType] ?? ConsentData(
      granted: false,
      grantedAt: null,
      expiresAt: null,
      description: '',
      purpose: '',
      required: false,
    )).copyWith(
      granted: granted,
      grantedAt: granted ? DateTime.now() : null,
      expiresAt: expiresAt,
    );

    return copyWith(
      consents: updatedConsents,
      lastUpdated: DateTime.now(),
    );
  }

  // Révoquer tous les consentements
  ConsentModel revokeAllConsents() {
    final updatedConsents = Map<String, ConsentData>.from(consents);
    
    for (final key in updatedConsents.keys) {
      if (!updatedConsents[key]!.required) {
        updatedConsents[key] = updatedConsents[key]!.copyWith(granted: false);
      }
    }

    return copyWith(
      consents: updatedConsents,
      lastUpdated: DateTime.now(),
    );
  }

  // Vérifier si un consentement est accordé
  bool hasConsent(String consentType) {
    return consents[consentType]?.granted ?? false;
  }

  // Vérifier si un consentement est expiré
  bool isConsentExpired(String consentType) {
    final consent = consents[consentType];
    if (consent == null || consent.expiresAt == null) return false;
    return DateTime.now().isAfter(consent.expiresAt!);
  }

  // Obtenir tous les consentements accordés
  Map<String, ConsentData> getGrantedConsents() {
    return Map.fromEntries(
      consents.entries.where((entry) => entry.value.granted && !isConsentExpired(entry.key)),
    );
  }

  // Copie avec modification
  ConsentModel copyWith({
    Map<String, ConsentData>? consents,
    DateTime? lastUpdated,
    String? version,
    String? ipAddress,
    String? userAgent,
  }) {
    return ConsentModel(
      userId: userId,
      consents: consents ?? this.consents,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      version: version ?? this.version,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
    );
  }
}

// Classe pour les données de consentement
class ConsentData {
  final bool granted;
  final DateTime? grantedAt;
  final DateTime? expiresAt;
  final String description;
  final String purpose;
  final bool required;

  ConsentData({
    required this.granted,
    this.grantedAt,
    this.expiresAt,
    required this.description,
    required this.purpose,
    required this.required,
  });

  // Conversion depuis Map
  factory ConsentData.fromMap(Map<String, dynamic> map) {
    return ConsentData(
      granted: map['granted'] ?? false,
      grantedAt: map['grantedAt'] != null 
          ? (map['grantedAt'] as Timestamp).toDate() 
          : null,
      expiresAt: map['expiresAt'] != null 
          ? (map['expiresAt'] as Timestamp).toDate() 
          : null,
      description: map['description'] ?? '',
      purpose: map['purpose'] ?? '',
      required: map['required'] ?? false,
    );
  }

  // Conversion vers Map
  Map<String, dynamic> toMap() {
    return {
      'granted': granted,
      'grantedAt': grantedAt != null ? Timestamp.fromDate(grantedAt!) : null,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'description': description,
      'purpose': purpose,
      'required': required,
    };
  }

  // Vérifier si le consentement est valide
  bool isValid() {
    if (!granted) return false;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return false;
    return true;
  }

  // Copie avec modification
  ConsentData copyWith({
    bool? granted,
    DateTime? grantedAt,
    DateTime? expiresAt,
    String? description,
    String? purpose,
    bool? required,
  }) {
    return ConsentData(
      granted: granted ?? this.granted,
      grantedAt: grantedAt ?? this.grantedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      description: description ?? this.description,
      purpose: purpose ?? this.purpose,
      required: required ?? this.required,
    );
  }
}

// Énumération pour les types de consentement
enum ConsentType {
  analytics,
  marketing,
  location,
  notifications,
  cookies,
  data_sharing,
  personalization,
}

// Extension pour les types de consentement
extension ConsentTypeExtension on ConsentType {
  String get name {
    switch (this) {
      case ConsentType.analytics:
        return 'Analytics';
      case ConsentType.marketing:
        return 'Marketing';
      case ConsentType.location:
        return 'Localisation';
      case ConsentType.notifications:
        return 'Notifications';
      case ConsentType.cookies:
        return 'Cookies';
      case ConsentType.data_sharing:
        return 'Partage de données';
      case ConsentType.personalization:
        return 'Personnalisation';
    }
  }

  String get key {
    switch (this) {
      case ConsentType.analytics:
        return 'analytics';
      case ConsentType.marketing:
        return 'marketing';
      case ConsentType.location:
        return 'location';
      case ConsentType.notifications:
        return 'notifications';
      case ConsentType.cookies:
        return 'cookies';
      case ConsentType.data_sharing:
        return 'data_sharing';
      case ConsentType.personalization:
        return 'personalization';
    }
  }

  IconData get icon {
    switch (this) {
      case ConsentType.analytics:
        return Icons.analytics;
      case ConsentType.marketing:
        return Icons.campaign;
      case ConsentType.location:
        return Icons.location_on;
      case ConsentType.notifications:
        return Icons.notifications;
      case ConsentType.cookies:
        return Icons.cookie;
      case ConsentType.data_sharing:
        return Icons.share;
      case ConsentType.personalization:
        return Icons.person;
    }
  }
}
