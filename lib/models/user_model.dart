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
  final List<String>? permissions;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.profileImageUrl,
    required this.createdAt,
    this.isAdmin = false,
    this.permissions,
  });

  // Getter pour l'ID (alias pour uid)
  String get id => uid;

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
      permissions:
          map['permissions'] != null
              ? List<String>.from(map['permissions'])
              : null,
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
      'permissions': permissions,
    };
  }

  // Copie avec modification
  UserModel copyWith({
    String? fullName,
    String? phoneNumber,
    String? profileImageUrl,
    bool? isAdmin,
    List<String>? permissions,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt,
      isAdmin: isAdmin ?? this.isAdmin,
      permissions: permissions ?? this.permissions,
    );
  }
}
