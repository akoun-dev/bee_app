import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:logger/logger.dart';

// Service pour gérer les notifications push
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final CollectionReference _notificationsCollection = FirebaseFirestore.instance.collection('notifications');

  final Logger logger = Logger();

  // Initialiser les notifications
  Future<void> initialize() async {
    try {
      // Demander la permission pour les notifications
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (kDebugMode) {
        logger.i('Statut des autorisations de notification: ${settings.authorizationStatus}');
      }

      // Configurer les notifications locales
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

      await _localNotifications.initialize(initSettings);

      // Configurer les gestionnaires de notification
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Vérifier les notifications initiales
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleInitialMessage(initialMessage);
      }

      // Obtenir le token FCM
      final token = await _messaging.getToken();
      if (kDebugMode) {
        logger.d('Token FCM: $token');
      }

      // Enregistrer le token côté serveur via une fonction Cloud
      if (token != null) {
        try {
          await FirebaseFunctions.instance
              .httpsCallable('registerToken')
              .call({'token': token});
        } catch (e) {
          if (kDebugMode) {
            logger.e("Erreur lors de l'enregistrement du token: $e");
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        logger.e('Erreur lors de l\'initialisation des notifications: $e');
      }
    }
  }

  // Gérer les messages reçus en premier plan
  void _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      logger.d('Message reçu en premier plan: ${message.notification?.title}');
    }

    // Afficher une notification locale
    if (message.notification != null) {
      const androidDetails = AndroidNotificationDetails(
        'bee_app_channel',
        'Notifications ZIBENE SECURITY',
        channelDescription: 'Canal pour les notifications de l\'application Bee',
        importance: Importance.max,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _localNotifications.show(
        message.hashCode,
        message.notification!.title,
        message.notification!.body,
        details,
        payload: message.data['route'],
      );
    }
  }

  // Gérer les messages ouverts depuis la notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) {
      logger.d('Message ouvert depuis la notification: ${message.notification?.title}');
    }

    // Naviguer vers la route spécifiée dans les données
    if (message.data.containsKey('route')) {
      // Implémenter la navigation ici
    }
  }

  // Gérer le message initial (app ouverte depuis une notification)
  void _handleInitialMessage(RemoteMessage message) {
    if (kDebugMode) {
      logger.d('Message initial: ${message.notification?.title}');
    }

    // Naviguer vers la route spécifiée dans les données
    if (message.data.containsKey('route')) {
      // Implémenter la navigation ici
    }
  }

  // S'abonner à un sujet
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  // Se désabonner d'un sujet
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  // Envoyer une notification administrative
  Future<void> sendAdminNotification({
    required String title,
    required String message,
    required String targetType, // 'all', 'users', 'agents'
  }) async {
    try {
      // Appeler la fonction Cloud pour envoyer la notification
      await FirebaseFunctions.instance
          .httpsCallable('sendAdminNotification')
          .call({
        'title': title,
        'message': message,
        'targetType': targetType,
      });

    } catch (e) {
      if (kDebugMode) {
        logger.e('Erreur lors de l\'envoi de la notification: ${e.toString()}');
      }
      throw Exception('Erreur lors de l\'envoi de la notification: ${e.toString()}');
    }
  }

  // Récupérer l'historique des notifications envoyées
  Future<List<Map<String, dynamic>>> getSentNotifications() async {
    try {
      // Utiliser une requête simple sans tri complexe pour éviter les problèmes d'index
      final snapshot = await _notificationsCollection
          .limit(20)
          .get();

      // Trier les résultats côté client
      final notifications = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'message': data['message'] ?? '',
          'targetType': data['targetType'] ?? 'all',
          'sentAt': data['sentAt'] ?? '',
          'status': data['status'] ?? '',
          // Stocker le timestamp pour le tri côté client
          'timestamp': data['timestamp'] != null
              ? (data['timestamp'] as Timestamp).toDate().millisecondsSinceEpoch
              : DateTime.now().millisecondsSinceEpoch,
        };
      }).toList();

      // Trier par timestamp décroissant
      notifications.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));

      return notifications;
    } catch (e) {
      if (kDebugMode) {
        logger.e('Erreur lors de la récupération des notifications: ${e.toString()}');
      }
      return [];
    }
  }
}
