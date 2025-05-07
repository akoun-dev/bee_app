import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

// Service pour initialiser Firebase
class FirebaseService {
  // Initialiser Firebase
  static Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      if (kDebugMode) {
        print('Firebase initialisé avec succès');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'initialisation de Firebase: $e');
      }
      rethrow;
    }
  }
}
