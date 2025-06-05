import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../firebase_options.dart';

final logger = Logger();

// Service pour initialiser Firebase
class FirebaseService {
  // Initialiser Firebase
  static Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      if (kDebugMode) {
        logger.i('Firebase initialisé avec succès');
      }
    } catch (e) {
      if (kDebugMode) {
        logger.e('Erreur lors de l\'initialisation de Firebase: $e');
      }
      rethrow;
    }
  }
}
