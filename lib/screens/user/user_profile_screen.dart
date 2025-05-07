import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';


// Écran de profil utilisateur
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  // Contrôleurs pour les champs de texte
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Clé pour le formulaire
  final _formKey = GlobalKey<FormState>();

  // État
  UserModel? _user;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _errorMessage;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Charger le profil utilisateur
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userData = await authService.getCurrentUserData();

      if (mounted) {
        setState(() {
          _user = userData;
          _isLoading = false;

          // Initialiser les contrôleurs
          if (userData != null) {
            _fullNameController.text = userData.fullName;
            _phoneController.text = userData.phoneNumber ?? '';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // Basculer en mode édition
  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;

      // Réinitialiser les contrôleurs si on annule l'édition
      if (!_isEditing && _user != null) {
        _fullNameController.text = _user!.fullName;
        _phoneController.text = _user!.phoneNumber ?? '';
        _imageFile = null;
      }
    });
  }

  // Sélectionner une image de profil
  Future<void> _pickImage() async {
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final imageFile = await storageService.pickImage();

      if (imageFile != null) {
        setState(() {
          _imageFile = imageFile;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection de l\'image: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // Enregistrer les modifications
  Future<void> _saveProfile() async {
    // Valider le formulaire
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storageService = Provider.of<StorageService>(context, listen: false);

      String? profileImageUrl = _user?.profileImageUrl;

      // Télécharger la nouvelle image si elle a été modifiée
      if (_imageFile != null && _user != null) {
        profileImageUrl = await storageService.uploadUserProfileImage(
          _user!.uid,
          _imageFile!,
        );
      }

      // Mettre à jour le profil
      await authService.updateUserProfile(
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        profileImageUrl: profileImageUrl,
      );

      // Recharger les données utilisateur
      await _loadUserProfile();

      if (mounted) {
        // Désactiver le mode édition
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });

        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppConstants.successProfileUpdate),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isSaving = false;
        });
      }
    }
  }

  // Se déconnecter
  Future<void> _signOut() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();

      if (mounted) {
        context.go('/auth');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.profileTitle),
        elevation: 0,
        actions: [
          // Bouton d'édition/annulation
          if (!_isLoading && _user != null)
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              onPressed: _toggleEditMode,
              tooltip: _isEditing ? 'Annuler' : 'Modifier le profil',
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Chargement du profil...')
          : _errorMessage != null
              ? ErrorMessage(
                  message: 'Erreur: $_errorMessage',
                  onRetry: _loadUserProfile,
                )
              : _user == null
                  ? const ErrorMessage(message: 'Utilisateur non connecté')
                  : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // En-tête avec photo de profil
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  // Photo de profil
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        // Avatar
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: _imageFile != null
                              ? CircleAvatar(
                                  radius: 60,
                                  backgroundImage: FileImage(_imageFile!),
                                )
                              : UserAvatar(
                                  imageUrl: _user!.profileImageUrl,
                                  name: _user!.fullName,
                                  size: 120,
                                ),
                        ),

                        // Bouton pour modifier la photo
                        if (_isEditing)
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: _pickImage,
                              tooltip: 'Changer la photo',
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Nom de l'utilisateur
                  Text(
                    _user!.fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Email
                  Text(
                    _user!.email,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Afficher le message d'erreur s'il y en a un
            if (_errorMessage != null) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.errorColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.errorColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppTheme.errorColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Informations du profil
            Padding(
              padding: const EdgeInsets.all(16),
              child: _isEditing
                  ? _buildEditForm()
                  : _buildProfileDetails(),
            ),
          ],
        ),
      ),
    );
  }

  // Formulaire d'édition
  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Modifier vos informations',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: AppConstants.fullNameLabel,
          controller: _fullNameController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer votre nom complet';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: AppConstants.phoneLabel,
          controller: _phoneController,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          text: AppConstants.saveChanges,
          onPressed: _saveProfile,
          isLoading: _isSaving,
        ),
      ],
    );
  }

  // Détails du profil
  Widget _buildProfileDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informations personnelles',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoCard(),
        const SizedBox(height: 24),
        const Text(
          'Paramètres du compte',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildAccountSettings(),
        const SizedBox(height: 24),
        SecondaryButton(
          text: AppConstants.logout,
          onPressed: _signOut,
        ),
      ],
    );
  }

  // Carte d'informations
  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoItem(Icons.person, 'Nom', _user!.fullName),
            const Divider(height: 24),
            _buildInfoItem(Icons.email, 'Email', _user!.email),
            if (_user!.phoneNumber != null && _user!.phoneNumber!.isNotEmpty) ...[
              const Divider(height: 24),
              _buildInfoItem(Icons.phone, 'Téléphone', _user!.phoneNumber!),
            ],
          ],
        ),
      ),
    );
  }

  // Paramètres du compte
  Widget _buildAccountSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Modifier le profil'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _toggleEditMode,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.password),
            title: const Text('Changer le mot de passe'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.go('/settings'),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  // Élément d'information
  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
