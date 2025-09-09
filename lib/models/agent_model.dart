import 'package:cloud_firestore/cloud_firestore.dart';

// Modèle pour les agents (gardes du corps)
// Contient toutes les informations détaillées sur un agent

class AgentModel {
  final String id;
  final String fullName;
  final int age;
  final String gender; // 'M' ou 'F'
  final String bloodType; // Groupe sanguin
  final String profession;
  final String background; // Antécédents
  final String educationLevel; // Niveau d'études
  final bool isCertified; // Agent certifié
  final String matricule; // Numéro d'identification
  final String? profileImageUrl;
  final double averageRating; // Note moyenne
  final int ratingCount; // Nombre de notes
  final bool isAvailable; // Disponibilité
  final DateTime createdAt;
  final String? email; // Adresse email
  final String? phoneNumber; // Numéro de téléphone
  final String? specialty; // Spécialité
  final int? experience; // Années d'expérience

  AgentModel({
    required this.id,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.bloodType,
    required this.profession,
    required this.background,
    required this.educationLevel,
    required this.isCertified,
    required this.matricule,
    this.profileImageUrl,
    this.averageRating = 0.0,
    this.ratingCount = 0,
    this.isAvailable = true,
    required this.createdAt,
    this.email,
    this.phoneNumber,
    this.specialty,
    this.experience,
  });

  // Conversion depuis Firestore
  factory AgentModel.fromMap(Map<String, dynamic> map, String id) {
    return AgentModel(
      id: id,
      fullName: map['fullName'] ?? '',
      age: map['age'] ?? 0,
      gender: map['gender'] ?? '',
      bloodType: map['bloodType'] ?? '',
      profession: map['profession'] ?? '',
      background: map['background'] ?? '',
      educationLevel: map['educationLevel'] ?? '',
      isCertified: map['isCertified'] ?? false,
      matricule: map['matricule'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,
      isAvailable: map['isAvailable'] ?? true,
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      email: map['email'],
      phoneNumber: map['phoneNumber'],
      specialty: map['specialty'],
      experience: map['experience'],
    );
  }

  // Conversion vers Firestore
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'age': age,
      'gender': gender,
      'bloodType': bloodType,
      'profession': profession,
      'background': background,
      'educationLevel': educationLevel,
      'isCertified': isCertified,
      'matricule': matricule,
      'profileImageUrl': profileImageUrl,
      'averageRating': averageRating,
      'ratingCount': ratingCount,
      'isAvailable': isAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
      'email': email,
      'phoneNumber': phoneNumber,
      'specialty': specialty,
      'experience': experience,
    };
  }

  // Mise à jour de la note moyenne
  AgentModel updateRating(double newRating) {
    final totalRating = (averageRating * ratingCount) + newRating;
    final newCount = ratingCount + 1;
    final newAverage = totalRating / newCount;

    return copyWith(
      averageRating: newAverage,
      ratingCount: newCount,
    );
  }

  // Copie avec modification
  AgentModel copyWith({
    String? fullName,
    int? age,
    String? gender,
    String? bloodType,
    String? profession,
    String? background,
    String? educationLevel,
    bool? isCertified,
    String? matricule,
    String? profileImageUrl,
    double? averageRating,
    int? ratingCount,
    bool? isAvailable,
    String? email,
    String? phoneNumber,
    String? specialty,
    int? experience,
  }) {
    return AgentModel(
      id: id,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      bloodType: bloodType ?? this.bloodType,
      profession: profession ?? this.profession,
      background: background ?? this.background,
      educationLevel: educationLevel ?? this.educationLevel,
      isCertified: isCertified ?? this.isCertified,
      matricule: matricule ?? this.matricule,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      averageRating: averageRating ?? this.averageRating,
      ratingCount: ratingCount ?? this.ratingCount,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      specialty: specialty ?? this.specialty,
      experience: experience ?? this.experience,
    );
  }
}
