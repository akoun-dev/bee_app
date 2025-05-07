import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/settings_service.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/admin_app_bar.dart';
import '../../widgets/admin_drawer.dart';

// Écran de gestion des paramètres de l'application pour les administrateurs
class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  // Contrôleurs pour les champs de texte
  final _commissionRateController = TextEditingController();
  final _maxBookingDaysController = TextEditingController();
  final _cancellationPolicyController = TextEditingController();
  final _termsAndConditionsController = TextEditingController();
  final _privacyPolicyController = TextEditingController();

  // État
  bool _isLoading = true;
  bool _isSaving = false;
  bool _enableNotifications = true;
  bool _enableRatings = true;
  bool _enableChat = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _commissionRateController.dispose();
    _maxBookingDaysController.dispose();
    _cancellationPolicyController.dispose();
    _termsAndConditionsController.dispose();
    _privacyPolicyController.dispose();
    super.dispose();
  }

  // Charger les paramètres depuis la base de données
  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final settingsService = Provider.of<SettingsService>(context, listen: false);
      final settings = await settingsService.getAppSettings();

      setState(() {
        _commissionRateController.text = settings['commissionRate'].toString();
        _maxBookingDaysController.text = settings['maxBookingDays'].toString();
        _cancellationPolicyController.text = settings['cancellationPolicy'] ?? '';
        _termsAndConditionsController.text = settings['termsAndConditions'] ?? '';
        _privacyPolicyController.text = settings['privacyPolicy'] ?? '';
        _enableNotifications = settings['enableNotifications'] ?? true;
        _enableRatings = settings['enableRatings'] ?? true;
        _enableChat = settings['enableChat'] ?? true;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des paramètres: ${e.toString()}')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  // Enregistrer les paramètres
  Future<void> _saveSettings() async {
    // Valider les entrées
    if (_commissionRateController.text.isEmpty ||
        _maxBookingDaysController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
      );
      return;
    }

    // Valider que les valeurs numériques sont correctes
    double? commissionRate;
    int? maxBookingDays;

    try {
      commissionRate = double.parse(_commissionRateController.text);
      if (commissionRate < 0 || commissionRate > 100) {
        throw Exception('Le taux de commission doit être entre 0 et 100');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un taux de commission valide')),
      );
      return;
    }

    try {
      maxBookingDays = int.parse(_maxBookingDaysController.text);
      if (maxBookingDays <= 0) {
        throw Exception('Le nombre de jours doit être positif');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un nombre de jours valide')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final settingsService = Provider.of<SettingsService>(context, listen: false);

      await settingsService.updateAppSettings({
        'commissionRate': commissionRate,
        'maxBookingDays': maxBookingDays,
        'cancellationPolicy': _cancellationPolicyController.text,
        'termsAndConditions': _termsAndConditionsController.text,
        'privacyPolicy': _privacyPolicyController.text,
        'enableNotifications': _enableNotifications,
        'enableRatings': _enableRatings,
        'enableChat': _enableChat,
        'lastUpdated': DateTime.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paramètres enregistrés avec succès'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminAppBar(
        title: 'Paramètres de l\'application',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSettings,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: _isLoading
        ? const LoadingIndicator(message: 'Chargement des paramètres...')
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Paramètres généraux
                _buildGeneralSettings(),

                const SizedBox(height: 24),

                // Paramètres de réservation
                _buildReservationSettings(),

                const SizedBox(height: 24),

                // Paramètres des fonctionnalités
                _buildFeatureSettings(),

                const SizedBox(height: 24),

                // Politiques et conditions
                _buildPoliciesSettings(),

                const SizedBox(height: 32),

                // Bouton de sauvegarde
                PrimaryButton(
                  text: 'Enregistrer les paramètres',
                  onPressed: _saveSettings,
                  isLoading: _isSaving,
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
    );
  }

  // Construire la section des paramètres généraux
  Widget _buildGeneralSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paramètres généraux',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Taux de commission
            const Text(
              'Taux de commission (%)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commissionRateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Ex: 15',
                suffixText: '%',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Construire la section des paramètres de réservation
  Widget _buildReservationSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paramètres de réservation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Nombre maximum de jours de réservation
            const Text(
              'Nombre maximum de jours de réservation',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _maxBookingDaysController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Ex: 30',
                suffixText: 'jours',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Politique d'annulation
            const Text(
              'Politique d\'annulation',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _cancellationPolicyController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Décrivez la politique d\'annulation...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Construire la section des paramètres de fonctionnalités
  Widget _buildFeatureSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fonctionnalités',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Activer/désactiver les notifications
            SwitchListTile(
              title: const Text('Notifications'),
              subtitle: const Text('Permettre l\'envoi de notifications aux utilisateurs'),
              value: _enableNotifications,
              onChanged: (value) => setState(() => _enableNotifications = value),
              activeColor: AppTheme.primaryColor,
            ),

            // Activer/désactiver les évaluations
            SwitchListTile(
              title: const Text('Évaluations'),
              subtitle: const Text('Permettre aux utilisateurs de noter les agents'),
              value: _enableRatings,
              onChanged: (value) => setState(() => _enableRatings = value),
              activeColor: AppTheme.primaryColor,
            ),

            // Activer/désactiver le chat
            SwitchListTile(
              title: const Text('Chat'),
              subtitle: const Text('Permettre la communication entre utilisateurs et agents'),
              value: _enableChat,
              onChanged: (value) => setState(() => _enableChat = value),
              activeColor: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  // Construire la section des politiques et conditions
  Widget _buildPoliciesSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Politiques et conditions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Conditions d'utilisation
            const Text(
              'Conditions d\'utilisation',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _termsAndConditionsController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Entrez les conditions d\'utilisation...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Politique de confidentialité
            const Text(
              'Politique de confidentialité',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _privacyPolicyController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Entrez la politique de confidentialité...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
