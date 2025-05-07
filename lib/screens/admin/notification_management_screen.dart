import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/notification_service.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/admin_app_bar.dart';
import '../../widgets/admin_drawer.dart';

// Écran de gestion des notifications pour les administrateurs
class NotificationManagementScreen extends StatefulWidget {
  const NotificationManagementScreen({super.key});

  @override
  State<NotificationManagementScreen> createState() => _NotificationManagementScreenState();
}

class _NotificationManagementScreenState extends State<NotificationManagementScreen> {
  // Contrôleurs pour les champs de texte
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  // État
  String _selectedType = 'all'; // 'all', 'users', 'agents'
  bool _isSending = false;
  List<Map<String, dynamic>> _sentNotifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSentNotifications();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // Charger l'historique des notifications envoyées
  Future<void> _loadSentNotifications() async {
    setState(() => _isLoading = true);

    try {
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      final notifications = await notificationService.getSentNotifications();

      setState(() {
        _sentNotifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      // Gérer l'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  // Envoyer une nouvelle notification
  Future<void> _sendNotification() async {
    // Valider les entrées
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final notificationService = Provider.of<NotificationService>(context, listen: false);

      await notificationService.sendAdminNotification(
        title: _titleController.text,
        message: _messageController.text,
        targetType: _selectedType,
      );

      // Réinitialiser les champs
      _titleController.clear();
      _messageController.clear();

      // Recharger la liste des notifications envoyées
      await _loadSentNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification envoyée avec succès'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminAppBar(
        title: 'Gestion des notifications',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSentNotifications,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          // Formulaire d'envoi de notification
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Envoyer une nouvelle notification',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Titre de la notification
                    CustomTextField(
                      label: 'Titre de la notification',
                      controller: _titleController,
                    ),
                    const SizedBox(height: 16),

                    // Message de la notification
                    CustomTextField(
                      label: 'Message',
                      controller: _messageController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Sélection du type de destinataire
                    const Text('Destinataires:'),
                    RadioListTile<String>(
                      title: const Text('Tous'),
                      value: 'all',
                      groupValue: _selectedType,
                      onChanged: (value) => setState(() => _selectedType = value!),
                    ),
                    RadioListTile<String>(
                      title: const Text('Utilisateurs uniquement'),
                      value: 'users',
                      groupValue: _selectedType,
                      onChanged: (value) => setState(() => _selectedType = value!),
                    ),
                    RadioListTile<String>(
                      title: const Text('Agents uniquement'),
                      value: 'agents',
                      groupValue: _selectedType,
                      onChanged: (value) => setState(() => _selectedType = value!),
                    ),

                    const SizedBox(height: 16),

                    // Bouton d'envoi
                    PrimaryButton(
                      text: 'Envoyer la notification',
                      onPressed: _sendNotification,
                      isLoading: _isSending,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Historique des notifications envoyées
          Expanded(
            child: _isLoading
              ? const LoadingIndicator(message: 'Chargement des notifications...')
              : _sentNotifications.isEmpty
                ? const EmptyMessage(
                    message: 'Aucune notification envoyée',
                    icon: Icons.notifications_off,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _sentNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = _sentNotifications[index];
                      return _buildNotificationItem(notification);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Construire un élément de notification
  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    // Déterminer l'icône en fonction du type de destinataire
    IconData typeIcon;
    String typeText;

    switch (notification['targetType']) {
      case 'users':
        typeIcon = Icons.person;
        typeText = 'Utilisateurs';
        break;
      case 'agents':
        typeIcon = Icons.security;
        typeText = 'Agents';
        break;
      default:
        typeIcon = Icons.people;
        typeText = 'Tous';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          child: Icon(Icons.notifications, color: Colors.white),
        ),
        title: Text(
          notification['title'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification['message']),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(typeIcon, size: 14, color: AppTheme.mediumColor),
                const SizedBox(width: 4),
                Text(
                  typeText,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.mediumColor,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.access_time, size: 14, color: AppTheme.mediumColor),
                const SizedBox(width: 4),
                Text(
                  notification['sentAt'] ?? 'Date inconnue',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.mediumColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: notification['status'] == 'sent'
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.error, color: AppTheme.errorColor),
      ),
    );
  }
}
