import 'package:cloud_firestore/cloud_firestore.dart';

// Modèle pour les avis et commentaires
// Permet de stocker les évaluations des agents par les utilisateurs

class ReviewModel {
  final String id;
  final String userId; // ID de l'utilisateur qui a laissé l'avis
  final String agentId; // ID de l'agent évalué
  final String reservationId; // ID de la réservation associée
  final double rating; // Note (1-5)
  final String comment; // Commentaire textuel
  final DateTime createdAt;
  final String? userFullName; // Nom de l'utilisateur (pour l'affichage)
  final String? userProfileImageUrl; // Photo de profil de l'utilisateur

  ReviewModel({
    required this.id,
    required this.userId,
    required this.agentId,
    required this.reservationId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.userFullName,
    this.userProfileImageUrl,
  });

  // Conversion depuis Firestore
  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel(
      id: id,
      userId: map['userId'] ?? '',
      agentId: map['agentId'] ?? '',
      reservationId: map['reservationId'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      userFullName: map['userFullName'],
      userProfileImageUrl: map['userProfileImageUrl'],
    );
  }

  // Conversion vers Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'agentId': agentId,
      'reservationId': reservationId,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'userFullName': userFullName,
      'userProfileImageUrl': userProfileImageUrl,
    };
  }

  // Copie avec modification
  ReviewModel copyWith({
    String? userId,
    String? agentId,
    String? reservationId,
    double? rating,
    String? comment,
    String? userFullName,
    String? userProfileImageUrl,
  }) {
    return ReviewModel(
      id: id,
      userId: userId ?? this.userId,
      agentId: agentId ?? this.agentId,
      reservationId: reservationId ?? this.reservationId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt,
      userFullName: userFullName ?? this.userFullName,
      userProfileImageUrl: userProfileImageUrl ?? this.userProfileImageUrl,
    );
  }
}
