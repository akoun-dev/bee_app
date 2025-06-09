import 'package:cloud_firestore/cloud_firestore.dart';

// Modèle pour les réservations d'agents
// Contient les informations sur une mission

class ReservationModel {
  final String id;
  final String userId; // ID de l'utilisateur qui réserve
  final String agentId; // ID de l'agent réservé
  final DateTime startDate; // Date de début de mission
  final DateTime endDate; // Date de fin de mission
  final String location; // Lieu de la mission
  final String description; // Description de la mission
  final String
  status; // 'pending', 'approved', 'rejected', 'completed', 'cancelled'
  final DateTime createdAt;
  final double? rating; // Note donnée par l'utilisateur après la mission
  final String? comment; // Commentaire laissé par l'utilisateur
  final double? totalPrice; // Prix total de la mission

  // Statuts possibles pour une réservation
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  ReservationModel({
    required this.id,
    required this.userId,
    required this.agentId,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.description,
    required this.status,
    required this.createdAt,
    this.rating,
    this.comment,
    this.totalPrice,
  });

  // Conversion depuis Firestore
  factory ReservationModel.fromMap(Map<String, dynamic> map, String id) {
    return ReservationModel(
      id: id,
      userId: map['userId'] ?? '',
      agentId: map['agentId'] ?? '',
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      location: map['location'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? statusPending,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      rating: map['rating']?.toDouble(),
      comment: map['comment'],
      totalPrice: map['totalPrice']?.toDouble(),
    );
  }

  // Conversion vers Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'agentId': agentId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'location': location,
      'description': description,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'rating': rating,
      'comment': comment,
      'totalPrice': totalPrice,
    };
  }

  // Copie avec modification
  ReservationModel copyWith({
    String? userId,
    String? agentId,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    String? description,
    String? status,
    double? rating,
    String? comment,
  }) {
    return ReservationModel(
      id: id,
      userId: userId ?? this.userId,
      agentId: agentId ?? this.agentId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
    );
  }

  // Méthode pour ajouter une évaluation
  ReservationModel addRating(double rating, String comment) {
    return copyWith(rating: rating, comment: comment, status: statusCompleted);
  }

  // Méthode pour approuver une réservation
  ReservationModel approve() {
    return copyWith(status: statusApproved);
  }

  // Méthode pour rejeter une réservation
  ReservationModel reject() {
    return copyWith(status: statusRejected);
  }

  // Méthode pour annuler une réservation
  ReservationModel cancel() {
    return copyWith(status: statusCancelled);
  }

  // Méthode pour marquer une réservation comme terminée
  ReservationModel complete() {
    return copyWith(status: statusCompleted);
  }
}
