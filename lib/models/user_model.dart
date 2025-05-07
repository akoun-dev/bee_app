import 'package:cloud_firestore/cloud_firestore.dart';

// Modèle pour les utilisateurs de l'application
// Représente les clients qui réservent des gardes du corps

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String? profileImageUrl;
  final DateTime createdAt;
  final bool isAdmin;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.profileImageUrl,
    required this.createdAt,
    this.isAdmin = false,
  });

  // Conversion depuis Firestore
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'],
      profileImageUrl: map['profileImageUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isAdmin: map['isAdmin'] ?? false,
    );
  }

  // Conversion vers Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'isAdmin': isAdmin,
    };
  }

  // Copie avec modification
  UserModel copyWith({
    String? fullName,
    String? phoneNumber,
    String? profileImageUrl,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt,
      isAdmin: isAdmin,
    );
  }
}
