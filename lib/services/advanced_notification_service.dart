import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Service avancé pour la gestion des notifications
class AdvancedNotificationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _fcmToken;

  // Getters
  bool get isInitialized => _isInitialized;
  String? get fcmToken => _fcmToken;

  // Initialiser le service de notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialiser les notifications locales
      await _initializeLocalNotifications();

      // Initialiser Firebase Messaging
      await _initializeFirebaseMessaging();

      // Configurer les handlers de messages
      _setupMessageHandlers();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'initialisation des notifications: $e');
      }
    }
  }

  // Initialiser les notifications locales
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // Initialiser Firebase Messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Demander les permissions
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Obtenir le token FCM
      _fcmToken = await _messaging.getToken();
      if (kDebugMode) {
        print('Token FCM: $_fcmToken');
      }

      // Écouter les changements de token
      _messaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        _updateUserToken(token);
      });
    }
  }

  // Configurer les handlers de messages
  void _setupMessageHandlers() {
    // Messages reçus quand l'app est en foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Messages reçus quand l'app est en background mais pas fermée
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Messages reçus quand l'app est complètement fermée
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleBackgroundMessage(message);
      }
    });
  }

  // Gérer les messages en foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      print('Message reçu en foreground: ${message.messageId}');
    }

    // Afficher une notification locale
    await _showLocalNotification(
      title: message.notification?.title ?? 'Nouvelle notification',
      body: message.notification?.body ?? '',
      payload: jsonEncode(message.data),
    );

    // Sauvegarder la notification
    await _saveNotificationToFirestore(message);
  }

  // Gérer les messages en background
  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      print('Message reçu en background: ${message.messageId}');
    }

    // Traiter l'action selon le type de notification
    final notificationType = message.data['type'];
    switch (notificationType) {
      case 'reservation_update':
        // Naviguer vers les détails de la réservation
        break;
      case 'new_message':
        // Naviguer vers le chat
        break;
      case 'agent_approved':
        // Naviguer vers le profil agent
        break;
      default:
        // Action par défaut
        break;
    }
  }

  // Callback quand une notification locale est tapée
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      _handleNotificationAction(data);
    }
  }

  // Gérer les actions de notification
  void _handleNotificationAction(Map<String, dynamic> data) {
    // Implémenter la navigation selon le type de notification
    final type = data['type'];
    final targetId = data['targetId'];

    // Ici, vous pouvez utiliser votre système de navigation
    // Par exemple, avec GoRouter ou Navigator
  }

  // Afficher une notification locale
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'bee_app_channel',
      'Bee App Notifications',
      channelDescription: 'Notifications de l\'application Bee App',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Envoyer une notification admin à tous les utilisateurs
  Future<void> sendAdminNotification({
    required String title,
    required String message,
    required String targetType, // 'all', 'users', 'agents'
    Map<String, dynamic>? data,
  }) async {
    try {
      // Créer le document de notification
      final notificationDoc = await _firestore.collection('admin_notifications').add({
        'title': title,
        'message': message,
        'targetType': targetType,
        'data': data ?? {},
        'sentAt': FieldValue.serverTimestamp(),
        'status': 'sending',
      });

      // Obtenir les tokens des utilisateurs cibles
      List<String> tokens = [];
      
      if (targetType == 'all' || targetType == 'users') {
        final usersSnapshot = await _firestore
            .collection('users')
            .where('fcmToken', isNotEqualTo: null)
            .get();
        
        tokens.addAll(usersSnapshot.docs
            .map((doc) => doc.data()['fcmToken'] as String?)
            .where((token) => token != null)
            .cast<String>());
      }

      if (targetType == 'all' || targetType == 'agents') {
        final agentsSnapshot = await _firestore
            .collection('agents')
            .where('fcmToken', isNotEqualTo: null)
            .get();
        
        tokens.addAll(agentsSnapshot.docs
            .map((doc) => doc.data()['fcmToken'] as String?)
            .where((token) => token != null)
            .cast<String>());
      }

      // Envoyer les notifications par batch
      await _sendBatchNotifications(tokens, title, message, data ?? {});

      // Mettre à jour le statut
      await notificationDoc.update({
        'status': 'sent',
        'recipientCount': tokens.length,
        'completedAt': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'envoi de la notification admin: $e');
      }
      rethrow;
    }
  }

  // Envoyer des notifications par batch
  Future<void> _sendBatchNotifications(
    List<String> tokens,
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    const batchSize = 500; // Limite FCM
    
    for (int i = 0; i < tokens.length; i += batchSize) {
      final batch = tokens.skip(i).take(batchSize).toList();
      
      try {
        await _sendMulticastMessage(batch, title, body, data);
      } catch (e) {
        if (kDebugMode) {
          print('Erreur lors de l\'envoi du batch $i: $e');
        }
      }
    }
  }

  // Envoyer un message multicast via FCM
  Future<void> _sendMulticastMessage(
    List<String> tokens,
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    // Note: Cette méthode nécessite une clé serveur FCM
    // Dans un vrai projet, cela devrait être fait côté serveur
    
    const serverKey = 'YOUR_FCM_SERVER_KEY'; // À configurer
    const fcmUrl = 'https://fcm.googleapis.com/fcm/send';

    final payload = {
      'registration_ids': tokens,
      'notification': {
        'title': title,
        'body': body,
        'sound': 'default',
      },
      'data': data,
      'priority': 'high',
    };

    try {
      final response = await http.post(
        Uri.parse(fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur FCM: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'envoi FCM: $e');
      }
      rethrow;
    }
  }

  // Envoyer une notification personnalisée
  Future<void> sendPersonalizedNotification({
    required String userId,
    required String title,
    required String message,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Récupérer le token de l'utilisateur
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null) {
        throw Exception('Token FCM non trouvé pour l\'utilisateur');
      }

      // Envoyer la notification
      await _sendMulticastMessage(
        [fcmToken],
        title,
        message,
        {
          'type': type ?? 'general',
          'userId': userId,
          ...?data,
        },
      );

      // Sauvegarder dans l'historique
      await _firestore.collection('user_notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'data': data,
        'sentAt': FieldValue.serverTimestamp(),
        'read': false,
      });

    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'envoi de la notification personnalisée: $e');
      }
      rethrow;
    }
  }

  // Sauvegarder une notification dans Firestore
  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    try {
      await _firestore.collection('received_notifications').add({
        'messageId': message.messageId,
        'title': message.notification?.title,
        'body': message.notification?.body,
        'data': message.data,
        'receivedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la sauvegarde de la notification: $e');
      }
    }
  }

  // Mettre à jour le token de l'utilisateur
  Future<void> _updateUserToken(String token) async {
    // Cette méthode devrait être appelée avec l'ID de l'utilisateur actuel
    // Pour l'instant, c'est un placeholder
  }

  // Obtenir l'historique des notifications envoyées
  Future<List<Map<String, dynamic>>> getSentNotifications({
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('admin_notifications')
          .orderBy('sentAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la récupération des notifications: $e');
      }
      return [];
    }
  }

  // Planifier une notification
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    Map<String, dynamic>? data,
  }) async {
    // Calculer le délai
    final delay = scheduledTime.difference(DateTime.now());
    
    if (delay.isNegative) {
      throw ArgumentError('La date de planification doit être dans le futur');
    }

    // Sauvegarder la notification planifiée
    await _firestore.collection('scheduled_notifications').add({
      'title': title,
      'body': body,
      'data': data ?? {},
      'scheduledTime': scheduledTime,
      'status': 'scheduled',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Note: Dans un vrai projet, vous utiliseriez un service de tâches planifiées
    // comme Cloud Functions ou un service de queue
  }

  // Annuler une notification planifiée
  Future<void> cancelScheduledNotification(String notificationId) async {
    await _firestore
        .collection('scheduled_notifications')
        .doc(notificationId)
        .update({
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
    });
  }
}
