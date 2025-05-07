import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

// Service pour gérer le stockage des fichiers (images)
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Sélectionner une image depuis la galerie
  Future<File?> pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;
      return File(pickedFile.path);
    } catch (e) {
      // Utiliser un logger en production au lieu de print
      // Logger.error('Erreur lors de la sélection de l\'image: ${e.toString()}');
      return null;
    }
  }

  // Sélectionner une image depuis la caméra
  Future<File?> takePhoto() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;
      return File(pickedFile.path);
    } catch (e) {
      // Utiliser un logger en production au lieu de print
      // Logger.error('Erreur lors de la prise de photo: ${e.toString()}');
      return null;
    }
  }

  // Télécharger une image de profil utilisateur
  Future<String?> uploadUserProfileImage(String userId, File imageFile) async {
    try {
      final storageRef = _storage.ref().child('users/$userId/profile.jpg');
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask;

      // Obtenir l'URL de téléchargement
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      // Utiliser un logger en production au lieu de print
      // Logger.error('Erreur lors du téléchargement de l\'image: ${e.toString()}');
      return null;
    }
  }

  // Télécharger une image de profil agent
  Future<String?> uploadAgentProfileImage(String agentId, File imageFile) async {
    try {
      final storageRef = _storage.ref().child('agents/$agentId/profile.jpg');
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask;

      // Obtenir l'URL de téléchargement
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      // Utiliser un logger en production au lieu de print
      // Logger.error('Erreur lors du téléchargement de l\'image: ${e.toString()}');
      return null;
    }
  }

  // Supprimer une image
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Extraire le chemin de l'URL
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Utiliser un logger en production au lieu de print
      // Logger.error('Erreur lors de la suppression de l\'image: ${e.toString()}');
    }
  }
}
