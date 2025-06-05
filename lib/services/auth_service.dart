import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

final logger = Logger();

// Service pour gérer l'authentification des utilisateurs
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Constructeur qui configure la persistance de l'authentification
  AuthService() {
    // Configurer la persistance de l'authentification
    _configurePersistence();
  }

  // Configurer la persistance de l'authentification
  Future<void> _configurePersistence() async {
    try {
      // setPersistence uniquement sur le web
      if (kIsWeb) {
        await _auth.setPersistence(Persistence.LOCAL);
        logger.i('Persistance d\'authentification configurée avec succès');
      }
    } catch (e) {
      logger.e(
        'Erreur lors de la configuration de la persistance: \\${e.toString()}',
      );
      // En cas d'erreur, on continue quand même car la persistance par défaut est généralement LOCAL
    }
  }

  // Obtenir l'utilisateur actuel
  User? get currentUser => _auth.currentUser;

  // Stream pour suivre l'état de l'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Vérifier si l'utilisateur est déjà connecté
  Future<bool> isUserLoggedIn() async {
    // Récupérer l'utilisateur actuel
    final user = _auth.currentUser;

    // Si l'utilisateur est null, il n'est pas connecté
    if (user == null) return false;

    try {
      // Vérifier si le token est toujours valide
      await user.getIdToken();
      return true;
    } catch (e) {
      // En cas d'erreur, l'utilisateur n'est pas correctement connecté
      return false;
    }
  }

  // Inscription avec email et mot de passe
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      // Créer l'utilisateur dans Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Envoyer un email de vérification
      if (userCredential.user != null) {
        await userCredential.user!.sendEmailVerification();
      }

      if (userCredential.user == null) {
        throw Exception('Échec de la création du compte');
      }

      // Créer le document utilisateur dans Firestore
      final user = UserModel(
        uid: userCredential.user!.uid,
        email: email,
        fullName: fullName,
        phoneNumber: phoneNumber,
        createdAt: DateTime.now(),
        isAdmin: false,
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(user.toMap());

      // Mettre à jour le nom d'utilisateur
      await userCredential.user?.updateDisplayName(fullName);

      return user;
    } catch (e) {
      // Capturer spécifiquement les erreurs d'authentification Firebase
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            throw Exception(AppConstants.errorEmailAlreadyInUse);
          case 'weak-password':
            throw Exception(AppConstants.errorWeakPassword);
          case 'invalid-email':
            throw Exception(AppConstants.errorInvalidEmail);
          case 'operation-not-allowed':
            throw Exception(AppConstants.errorOperationNotAllowed);
          default:
            throw Exception('${AppConstants.errorGeneric} (${e.code})');
        }
      }

      // Pour les autres erreurs, afficher un message générique
      throw Exception(AppConstants.errorGeneric);
    }
  }

  // Connexion avec email et mot de passe
  Future<UserModel> signIn({
    required String email,
    required String password,
    bool requireEmailVerification = true,
  }) async {
    try {
      // Connecter l'utilisateur avec Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Échec de la connexion');
      }

      // Vérifier si l'email est vérifié (sauf pour les administrateurs)
      if (requireEmailVerification && !userCredential.user!.emailVerified) {
        // Vérifier si l'utilisateur est un administrateur
        final docSnapshot =
            await _firestore
                .collection('users')
                .doc(userCredential.user!.uid)
                .get();

        if (docSnapshot.exists) {
          final userData = docSnapshot.data() as Map<String, dynamic>;
          final isAdmin = userData['isAdmin'] as bool? ?? false;

          // Si l'utilisateur n'est pas un administrateur, exiger la vérification de l'email
          if (!isAdmin) {
            // Déconnecter l'utilisateur car son email n'est pas vérifié
            await _auth.signOut();
            throw Exception(AppConstants.errorEmailNotVerified);
          }
        } else {
          // Déconnecter l'utilisateur car son profil n'existe pas
          await _auth.signOut();
          throw Exception('Profil utilisateur introuvable');
        }
      }

      // Récupérer les données utilisateur depuis Firestore
      final docSnapshot =
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();

      if (!docSnapshot.exists) {
        throw Exception('Profil utilisateur introuvable');
      }

      return UserModel.fromMap(
        docSnapshot.data() as Map<String, dynamic>,
        userCredential.user!.uid,
      );
    } catch (e) {
      // Capturer spécifiquement les erreurs d'authentification Firebase
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            throw Exception(AppConstants.errorUserNotFound);
          case 'wrong-password':
            throw Exception(AppConstants.errorWrongPassword);
          case 'invalid-email':
            throw Exception(AppConstants.errorInvalidEmail);
          case 'user-disabled':
            throw Exception(AppConstants.errorUserDisabled);
          case 'too-many-requests':
            throw Exception(AppConstants.errorTooManyRequests);
          default:
            throw Exception('${AppConstants.errorGeneric} (${e.code})');
        }
      }

      // Pour les autres erreurs, afficher un message générique
      throw Exception(e.toString());
    }
  }

  // Envoyer un email de vérification à l'utilisateur actuel
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      await user.sendEmailVerification();
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'too-many-requests':
            throw Exception(AppConstants.errorTooManyRequests);
          default:
            throw Exception('${AppConstants.errorGeneric} (${e.code})');
        }
      }

      throw Exception(AppConstants.errorGeneric);
    }
  }

  // Vérifier si l'email de l'utilisateur actuel est vérifié
  Future<bool> isEmailVerified() async {
    try {
      // Recharger l'utilisateur pour obtenir les informations les plus récentes
      final user = _auth.currentUser;
      if (user == null) return false;

      await user.reload();
      return _auth.currentUser?.emailVerified ?? false;
    } catch (e) {
      return false;
    }
  }

  // Nous n'avons plus besoin de la méthode adminSignIn car nous utilisons une seule méthode de connexion
  // La redirection sera gérée par le router en fonction du statut d'administrateur

  // Déconnexion
  Future<void> signOut() async {
    try {
      // Déconnecter l'utilisateur de Firebase Auth
      await _auth.signOut();

      // Attendre un court instant pour s'assurer que la déconnexion est traitée
      await Future.delayed(const Duration(milliseconds: 300));

      // Vérifier que l'utilisateur est bien déconnecté
      final user = _auth.currentUser;
      if (user != null) {
        // Si l'utilisateur est toujours connecté, forcer une nouvelle tentative de déconnexion
        await _auth.signOut();
      }
    } catch (e) {
      // Utiliser un logger en production au lieu de print
      // Logger.error('Erreur lors de la déconnexion: ${e.toString()}');

      // Relancer l'exception pour que l'appelant puisse la gérer
      rethrow;
    }
  }

  // Récupérer les données de l'utilisateur actuel
  Future<UserModel?> getCurrentUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final docSnapshot =
          await _firestore.collection('users').doc(user.uid).get();

      if (!docSnapshot.exists) return null;

      return UserModel.fromMap(
        docSnapshot.data() as Map<String, dynamic>,
        user.uid,
      );
    } catch (e) {
      // Utiliser un logger en production au lieu de print
      // Logger.error('Erreur lors de la récupération des données utilisateur: ${e.toString()}');
      return null;
    }
  }

  // Mettre à jour le profil utilisateur
  Future<void> updateUserProfile({
    required String fullName,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      await _firestore.collection('users').doc(user.uid).update({
        'fullName': fullName,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      });
    } catch (e) {
      throw Exception(
        'Erreur lors de la mise à jour du profil: ${e.toString()}',
      );
    }
  }

  // Réinitialiser le mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      // Capturer spécifiquement les erreurs d'authentification Firebase
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            throw Exception(AppConstants.errorUserNotFound);
          case 'invalid-email':
            throw Exception(AppConstants.errorInvalidEmail);
          case 'too-many-requests':
            throw Exception(AppConstants.errorTooManyRequests);
          default:
            throw Exception('${AppConstants.errorGeneric} (${e.code})');
        }
      }

      // Pour les autres erreurs, afficher un message générique
      throw Exception(AppConstants.errorGeneric);
    }
  }

  // Modifier le mot de passe
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Recréer les credentials pour vérifier le mot de passe actuel
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      // Vérifier le mot de passe actuel
      await user.reauthenticateWithCredential(credential);

      // Changer le mot de passe
      await user.updatePassword(newPassword);
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'wrong-password':
            throw Exception('Mot de passe actuel incorrect');
          case 'weak-password':
            throw Exception('Le nouveau mot de passe est trop faible');
          case 'requires-recent-login':
            throw Exception(
              'Veuillez vous reconnecter pour modifier votre mot de passe',
            );
          default:
            throw Exception(
              'Erreur lors du changement de mot de passe: ${e.message}',
            );
        }
      }
      throw Exception('Erreur lors du changement de mot de passe');
    }
  }
}
