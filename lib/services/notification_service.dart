import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Service pour gérer les notifications push
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final CollectionReference _notificationsCollection = FirebaseFirestore.instance.collection('notifications');
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');
  final CollectionReference _agentsCollection = FirebaseFirestore.instance.collection('agents');

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
        print('Statut des autorisations de notification: ${settings.authorizationStatus}');
      }

      // Configurer les notifications locales
      final androidSettings = const AndroidInitializationSettings('@mipmap/ic_launcher');
      final iosSettings = const DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      final initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

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
        print('Token FCM: $token');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'initialisation des notifications: $e');
      }
    }
  }

  // Gérer les messages reçus en premier plan
  void _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      print('Message reçu en premier plan: ${message.notification?.title}');
    }

    // Afficher une notification locale
    if (message.notification != null) {
      final androidDetails = AndroidNotificationDetails(
        'bee_app_channel',
        'Notifications Bee App',
        channelDescription: 'Canal pour les notifications de l\'application Bee',
        importance: Importance.max,
        priority: Priority.high,
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

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
      print('Message ouvert depuis la notification: ${message.notification?.title}');
    }

    // Naviguer vers la route spécifiée dans les données
    if (message.data.containsKey('route')) {
      // Implémenter la navigation ici
    }
  }

  // Gérer le message initial (app ouverte depuis une notification)
  void _handleInitialMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('Message initial: ${message.notification?.title}');
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
      // Créer un document de notification dans Firestore
      final notificationData = {
        'title': title,
        'message': message,
        'targetType': targetType,
        'sentAt': DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'sent',
      };

      // Enregistrer la notification dans Firestore
      await _notificationsCollection.add(notificationData);

      // Récupérer les tokens FCM des destinataires
      List<String> tokens = [];

      if (targetType == 'all' || targetType == 'users') {
        final usersSnapshot = await _usersCollection.get();
        for (var doc in usersSnapshot.docs) {
          final userData = doc.data() as Map<String, dynamic>;
          if (userData['fcmToken'] != null) {
            tokens.add(userData['fcmToken']);
          }
        }
      }

      if (targetType == 'all' || targetType == 'agents') {
        final agentsSnapshot = await _agentsCollection.get();
        for (var doc in agentsSnapshot.docs) {
          final agentData = doc.data() as Map<String, dynamic>;
          if (agentData['fcmToken'] != null) {
            tokens.add(agentData['fcmToken']);
          }
        }
      }

      // Envoyer la notification via Firebase Cloud Messaging
      // Note: Dans une application réelle, cela serait fait via une fonction Cloud
      // car les clés FCM ne doivent pas être exposées côté client
      if (kDebugMode) {
        print('Envoi de notification à ${tokens.length} destinataires');
      }

      // Simuler l'envoi pour la démonstration
      await Future.delayed(const Duration(seconds: 1));

    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'envoi de la notification: ${e.toString()}');
      }
      throw Exception('Erreur lors de l\'envoi de la notification: ${e.toString()}');
    }
  }

  // Récupérer l'historique des notifications envoyées
  Future<List<Map<String, dynamic>>> getSentNotifications() async {
    try {
      final snapshot = await _notificationsCollection
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'title': data['title'],
          'message': data['message'],
          'targetType': data['targetType'],
          'sentAt': data['sentAt'],
          'status': data['status'],
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la récupération des notifications: ${e.toString()}');
      }
      return [];
    }
  }
}
