import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../services/theme_service.dart';
import '../../services/recommendation_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_preferences_model.dart';
import '../../models/user_model.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';

// Écran de paramètres utilisateur
class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  bool _isLoading = true;
  UserPreferencesModel? _preferences;
  UserModel? _currentUser;

  // Contrôleurs pour la modification du mot de passe
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Charger toutes les données nécessaires
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Récupérer l'ID de l'utilisateur actuel
      final user = Provider.of<User?>(context, listen: false);

      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Récupérer les services
      final recommendationService = Provider.of<RecommendationService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      // Récupérer les données
      final preferences = await recommendationService.getUserPreferences(user.uid);
      final userData = await authService.getCurrentUserData();

      if (mounted) {
        setState(() {
          _preferences = preferences;
          _currentUser = userData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  // Mettre à jour les paramètres d'interface
  Future<void> _updateInterfaceSettings(Map<String, dynamic> newSettings) async {
    if (_preferences == null) return;

    try {
      final recommendationService = Provider.of<RecommendationService>(context, listen: false);

      final updatedPreferences = _preferences!.updateInterfaceSettings(newSettings);
      await recommendationService.updateUserPreferences(updatedPreferences);

      setState(() => _preferences = updatedPreferences);

      // Afficher un message de confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paramètres enregistrés'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  // Changer le mot de passe
  Future<void> _changePassword() async {
    // Valider les entrées
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les nouveaux mots de passe ne correspondent pas'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le nouveau mot de passe doit contenir au moins 6 caractères'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Récupérer l'utilisateur actuel
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Récupérer les informations d'identification
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      // Réauthentifier l'utilisateur
      await user.reauthenticateWithCredential(credential);

      // Changer le mot de passe
      await user.updatePassword(_newPasswordController.text);

      // Fermer la boîte de dialogue de chargement
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Réinitialiser les champs
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mot de passe modifié avec succès'),
            backgroundColor: AppTheme.accentColor,
          ),
        );

        // Fermer la boîte de dialogue
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Fermer la boîte de dialogue de chargement
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Afficher un message d'erreur
      String errorMessage = 'Une erreur est survenue';

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'wrong-password':
            errorMessage = 'Mot de passe actuel incorrect';
            break;
          case 'too-many-requests':
            errorMessage = 'Trop de tentatives, veuillez réessayer plus tard';
            break;
          default:
            errorMessage = 'Erreur: ${e.message}';
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // Afficher la boîte de dialogue de changement de mot de passe
  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer le mot de passe'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _currentPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe actuel',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  border: OutlineInputBorder(),
                  helperText: 'Au moins 6 caractères',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirmer le nouveau mot de passe',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: _changePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Changer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: _isLoading
        ? const LoadingIndicator(message: 'Chargement des paramètres...')
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profil et sécurité
                _buildProfileSection(),

                const SizedBox(height: 24),

                // Préférences personnelles
                _buildPersonalPreferencesSection(),

                const SizedBox(height: 24),

                // Apparence
                _buildAppearanceSection(themeService),

                const SizedBox(height: 24),

                // Accessibilité
                _buildAccessibilitySection(themeService),

                const SizedBox(height: 24),

                // Notifications
                _buildNotificationsSection(),

                const SizedBox(height: 24),

                // Confidentialité
                _buildPrivacySection(),
              ],
            ),
          ),
    );
  }

  // Construire la section de profil
  Widget _buildProfileSection() {
    final user = FirebaseAuth.instance.currentUser;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profil et sécurité',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Informations de l'utilisateur
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primaryColor.withAlpha(30),
                  child: Text(
                    _currentUser != null && _currentUser!.fullName.isNotEmpty
                        ? _currentUser!.fullName.substring(0, 1).toUpperCase()
                        : user?.email != null ? user!.email!.substring(0, 1).toUpperCase() : 'U',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Informations
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentUser?.fullName ?? 'Utilisateur',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'Email non disponible',
                        style: TextStyle(
                          color: AppTheme.mediumColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Bouton pour voir le profil complet
            OutlinedButton.icon(
              onPressed: () => context.go('/profile'),
              icon: const Icon(Icons.person),
              label: const Text('Voir mon profil complet'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),

            const Divider(height: 32),

            // Sécurité
            const Text(
              'Sécurité',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Changer le mot de passe
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Changer le mot de passe'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              contentPadding: EdgeInsets.zero,
              onTap: _showChangePasswordDialog,
            ),

            // Déconnexion
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.errorColor),
              title: const Text(
                'Déconnexion',
                style: TextStyle(color: AppTheme.errorColor),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.errorColor),
              contentPadding: EdgeInsets.zero,
              onTap: () async {
                // Afficher une boîte de dialogue de confirmation
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Déconnexion'),
                    content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Annuler'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorColor,
                        ),
                        child: const Text('Déconnexion'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  // Déconnecter l'utilisateur
                  await FirebaseAuth.instance.signOut();

                  // Rediriger vers la page d'authentification
                  if (mounted) {
                    context.go('/auth');
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Construire la section d'apparence
  Widget _buildAppearanceSection(ThemeService themeService) {
    // Récupérer les paramètres actuels
    final String accentColor = _preferences?.interfaceSettings['accentColor'] ?? 'yellow';
    final String cardStyle = _preferences?.interfaceSettings['cardStyle'] ?? 'default';
    final String fontFamily = _preferences?.interfaceSettings['fontFamily'] ?? 'default';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Apparence',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Thème
            const Text(
              'Thème',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Clair'),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Sombre'),
                  icon: Icon(Icons.dark_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('Système'),
                  icon: Icon(Icons.settings_suggest),
                ),
              ],
              selected: {themeService.themeMode},
              onSelectionChanged: (Set<ThemeMode> selection) {
                themeService.setThemeMode(selection.first);

                // Mettre à jour les préférences utilisateur
                if (_preferences != null) {
                  String themeModeString;
                  switch (selection.first) {
                    case ThemeMode.light:
                      themeModeString = 'light';
                      break;
                    case ThemeMode.dark:
                      themeModeString = 'dark';
                      break;
                    case ThemeMode.system:
                      themeModeString = 'system';
                      break;
                  }

                  _updateInterfaceSettings({'themeMode': themeModeString});
                }
              },
            ),

            const SizedBox(height: 24),

            // Couleur d'accent
            const Text(
              'Couleur d\'accent',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: [
                _buildColorOption('yellow', 'Jaune', const Color(0xFFFFC107), accentColor == 'yellow', themeService),
                _buildColorOption('blue', 'Bleu', const Color(0xFF2196F3), accentColor == 'blue', themeService),
                _buildColorOption('green', 'Vert', const Color(0xFF4CAF50), accentColor == 'green', themeService),
                _buildColorOption('purple', 'Violet', const Color(0xFF9C27B0), accentColor == 'purple', themeService),
                _buildColorOption('orange', 'Orange', const Color(0xFFFF9800), accentColor == 'orange', themeService),
              ],
            ),

            const SizedBox(height: 24),

            // Style des cartes
            const Text(
              'Style des cartes',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'default',
                  label: Text('Standard'),
                  icon: Icon(Icons.crop_square),
                ),
                ButtonSegment(
                  value: 'flat',
                  label: Text('Plat'),
                  icon: Icon(Icons.crop_square_outlined),
                ),
                ButtonSegment(
                  value: 'elevated',
                  label: Text('Élevé'),
                  icon: Icon(Icons.layers),
                ),
              ],
              selected: {cardStyle},
              onSelectionChanged: (Set<String> selection) {
                final selectedStyle = selection.first;

                // Mettre à jour le service de thème
                themeService.setCardStyle(selectedStyle);

                // Mettre à jour les préférences utilisateur
                _updateInterfaceSettings({'cardStyle': selectedStyle});
              },
            ),

            const SizedBox(height: 24),

            // Police de caractères
            const Text(
              'Police de caractères',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: fontFamily,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'default',
                  child: Text('Par défaut'),
                ),
                DropdownMenuItem(
                  value: 'poppins',
                  child: Text('Poppins'),
                ),
                DropdownMenuItem(
                  value: 'roboto',
                  child: Text('Roboto'),
                ),
                DropdownMenuItem(
                  value: 'lato',
                  child: Text('Lato'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  // Mettre à jour le service de thème
                  themeService.setFontFamily(value);

                  // Mettre à jour les préférences utilisateur
                  _updateInterfaceSettings({'fontFamily': value});
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Construire une option de couleur
  Widget _buildColorOption(String colorName, String label, Color color, bool isSelected, ThemeService themeService) {
    return GestureDetector(
      onTap: () {
        // Mettre à jour le service de thème
        themeService.setAccentColor(colorName);

        // Mettre à jour les préférences utilisateur
        _updateInterfaceSettings({'accentColor': colorName});
      },
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected ? color.withOpacity(0.5) : Colors.transparent,
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: isSelected
              ? const Icon(Icons.check, color: Colors.white)
              : null,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Construire la section d'accessibilité
  Widget _buildAccessibilitySection(ThemeService themeService) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Accessibilité',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Taille du texte
            const Text(
              'Taille du texte',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Slider(
              value: themeService.textScaleFactor,
              min: 0.8,
              max: 1.3,
              divisions: 4,
              label: _getTextSizeLabel(themeService.textScaleFactor),
              onChanged: (value) {
                String textSize;
                if (value <= 0.85) {
                  textSize = 'small';
                } else if (value <= 1.0) {
                  textSize = 'medium';
                } else if (value <= 1.15) {
                  textSize = 'large';
                } else {
                  textSize = 'extra_large';
                }

                themeService.setTextSize(textSize);
                _updateInterfaceSettings({'textSize': textSize});
              },
            ),

            const SizedBox(height: 16),

            // Contraste élevé
            SwitchListTile(
              title: const Text('Contraste élevé'),
              subtitle: const Text('Améliore la lisibilité avec des contrastes plus forts'),
              value: themeService.highContrast,
              onChanged: (value) {
                themeService.setHighContrast(value);
                _updateInterfaceSettings({'highContrast': value});
              },
              secondary: const Icon(Icons.contrast),
            ),

            // Réduction des animations
            SwitchListTile(
              title: const Text('Réduire les animations'),
              subtitle: const Text('Diminue ou désactive les effets visuels'),
              value: themeService.reducedMotion,
              onChanged: (value) {
                themeService.setReducedMotion(value);
                _updateInterfaceSettings({'reducedMotion': value});
              },
              secondary: const Icon(Icons.animation),
            ),
          ],
        ),
      ),
    );
  }

  // Construire la section des notifications
  Widget _buildNotificationsSection() {
    // Récupérer les paramètres actuels
    final bool enableNotifications = _preferences?.interfaceSettings['enableNotifications'] ?? true;
    final bool enableReservationReminders = _preferences?.interfaceSettings['enableReservationReminders'] ?? true;
    final bool enablePromotions = _preferences?.interfaceSettings['enablePromotions'] ?? false;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Activer les notifications
            SwitchListTile(
              title: const Text('Activer les notifications'),
              value: enableNotifications,
              onChanged: (value) {
                _updateInterfaceSettings({'enableNotifications': value});
              },
              secondary: const Icon(Icons.notifications),
            ),

            // Rappels de réservation
            SwitchListTile(
              title: const Text('Rappels de réservation'),
              subtitle: const Text('Recevoir des rappels pour vos réservations à venir'),
              value: enableReservationReminders,
              onChanged: enableNotifications ? (value) {
                _updateInterfaceSettings({'enableReservationReminders': value});
              } : null,
              secondary: const Icon(Icons.calendar_today),
            ),

            // Promotions et offres
            SwitchListTile(
              title: const Text('Promotions et offres'),
              subtitle: const Text('Recevoir des notifications sur les offres spéciales'),
              value: enablePromotions,
              onChanged: enableNotifications ? (value) {
                _updateInterfaceSettings({'enablePromotions': value});
              } : null,
              secondary: const Icon(Icons.local_offer),
            ),
          ],
        ),
      ),
    );
  }

  // Construire la section de confidentialité
  Widget _buildPrivacySection() {
    // Récupérer les paramètres actuels
    final bool shareUsageData = _preferences?.interfaceSettings['shareUsageData'] ?? false;
    final bool shareLocation = _preferences?.interfaceSettings['shareLocation'] ?? true;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confidentialité',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Partage des données d'utilisation
            SwitchListTile(
              title: const Text('Partager les données d\'utilisation'),
              subtitle: const Text('Aide à améliorer l\'application'),
              value: shareUsageData,
              onChanged: (value) {
                _updateInterfaceSettings({'shareUsageData': value});
              },
              secondary: const Icon(Icons.analytics),
            ),

            // Partage de la localisation
            SwitchListTile(
              title: const Text('Partager ma localisation'),
              subtitle: const Text('Pour des recommandations basées sur votre position'),
              value: shareLocation,
              onChanged: (value) {
                _updateInterfaceSettings({'shareLocation': value});
              },
              secondary: const Icon(Icons.location_on),
            ),

            const SizedBox(height: 16),

            // Bouton pour effacer les données
            OutlinedButton.icon(
              icon: const Icon(Icons.delete),
              label: const Text('Effacer mes données de navigation'),
              onPressed: () {
                // Afficher une boîte de dialogue de confirmation
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Effacer les données'),
                    content: const Text(
                      'Êtes-vous sûr de vouloir effacer votre historique de navigation et vos recherches récentes ?'
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);

                          // Effacer les recherches récentes
                          if (_preferences != null) {
                            final updatedPreferences = _preferences!.copyWith(
                              recentSearches: [],
                              lastUpdated: DateTime.now(),
                            );

                            final recommendationService = Provider.of<RecommendationService>(
                              context,
                              listen: false,
                            );

                            recommendationService.updateUserPreferences(updatedPreferences);

                            setState(() => _preferences = updatedPreferences);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Données de navigation effacées'),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorColor,
                        ),
                        child: const Text('Effacer'),
                      ),
                    ],
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Construire la section des préférences personnelles
  Widget _buildPersonalPreferencesSection() {
    // Récupérer les paramètres actuels
    final List<String> preferredCategories =
        _preferences?.interfaceSettings['preferredCategories']?.cast<String>() ??
        ['Sécurité', 'Transport', 'Événementiel'];
    final int preferredDistance = _preferences?.interfaceSettings['preferredDistance'] ?? 20;
    final bool autoSuggestAgents = _preferences?.interfaceSettings['autoSuggestAgents'] ?? true;
    final bool showRatings = _preferences?.interfaceSettings['showRatings'] ?? true;
    final String sortAgentsBy = _preferences?.interfaceSettings['sortAgentsBy'] ?? 'rating';

    // Liste des catégories disponibles
    final List<String> availableCategories = [
      'Sécurité',
      'Transport',
      'Événementiel',
      'Protection rapprochée',
      'Surveillance',
      'Escorte',
      'Garde du corps',
      'Chauffeur',
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Préférences personnelles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Catégories préférées
            const Text(
              'Catégories préférées',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableCategories.map((category) {
                final isSelected = preferredCategories.contains(category);
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    List<String> updatedCategories = List.from(preferredCategories);

                    if (selected) {
                      if (!updatedCategories.contains(category)) {
                        updatedCategories.add(category);
                      }
                    } else {
                      updatedCategories.remove(category);
                    }

                    _updateInterfaceSettings({'preferredCategories': updatedCategories});
                  },
                  selectedColor: AppTheme.primaryColor.withAlpha(100),
                  checkmarkColor: AppTheme.primaryColor,
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Distance préférée
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Distance maximale',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text('$preferredDistance km'),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: preferredDistance.toDouble(),
              min: 5,
              max: 100,
              divisions: 19,
              label: '$preferredDistance km',
              onChanged: (value) {
                final distance = value.round();
                _updateInterfaceSettings({'preferredDistance': distance});
              },
            ),

            const SizedBox(height: 16),

            // Suggestions automatiques
            SwitchListTile(
              title: const Text('Suggestions automatiques'),
              subtitle: const Text('Recevoir des suggestions d\'agents basées sur vos préférences'),
              value: autoSuggestAgents,
              onChanged: (value) {
                _updateInterfaceSettings({'autoSuggestAgents': value});
              },
              secondary: const Icon(Icons.recommend),
            ),

            // Afficher les évaluations
            SwitchListTile(
              title: const Text('Afficher les évaluations'),
              subtitle: const Text('Voir les notes et commentaires des autres utilisateurs'),
              value: showRatings,
              onChanged: (value) {
                _updateInterfaceSettings({'showRatings': value});
              },
              secondary: const Icon(Icons.star_outline),
            ),

            const SizedBox(height: 16),

            // Tri des agents
            const Text(
              'Trier les agents par',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'rating',
                  label: Text('Évaluation'),
                  icon: Icon(Icons.star),
                ),
                ButtonSegment(
                  value: 'distance',
                  label: Text('Distance'),
                  icon: Icon(Icons.place),
                ),
                ButtonSegment(
                  value: 'price',
                  label: Text('Prix'),
                  icon: Icon(Icons.euro),
                ),
              ],
              selected: {sortAgentsBy},
              onSelectionChanged: (Set<String> selection) {
                final selectedSort = selection.first;
                _updateInterfaceSettings({'sortAgentsBy': selectedSort});
              },
            ),
          ],
        ),
      ),
    );
  }

  // Obtenir le libellé de la taille du texte
  String _getTextSizeLabel(double value) {
    if (value <= 0.85) {
      return 'Petit';
    } else if (value <= 1.0) {
      return 'Moyen';
    } else if (value <= 1.15) {
      return 'Grand';
    } else {
      return 'Très grand';
    }
  }
}
