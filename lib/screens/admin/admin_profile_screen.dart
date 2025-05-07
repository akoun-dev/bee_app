import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/admin_app_bar.dart';
import '../../widgets/admin_drawer.dart';

// Écran de profil administrateur
class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  // État
  bool _isLoading = true;
  bool _isSaving = false;
  UserModel? _user;
  String? _errorMessage;

  // Contrôleurs pour les champs de texte
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  // Clé pour le formulaire
  final _formKey = GlobalKey<FormState>();

  // Image de profil
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Charger les données de l'utilisateur
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.getCurrentUserData();

      if (user == null) {
        setState(() {
          _errorMessage = 'Impossible de récupérer les données utilisateur';
          _isLoading = false;
        });
        return;
      }

      // Vérifier que l'utilisateur est bien un administrateur
      if (!user.isAdmin) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppConstants.errorPermission),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          context.go('/admin');
        }
        return;
      }

      // Mettre à jour l'état
      setState(() {
        _user = user;
        _fullNameController.text = user.fullName;
        _phoneController.text = user.phoneNumber ?? '';
        _emailController.text = user.email;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Sélectionner une image de profil
  Future<void> _pickImage() async {
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final pickedImage = await storageService.pickImage();

      if (pickedImage != null) {
        setState(() {
          _imageFile = pickedImage;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection de l\'image: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  // Enregistrer les modifications
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storageService = Provider.of<StorageService>(context, listen: false);
      final databaseService = Provider.of<DatabaseService>(context, listen: false);

      // Télécharger l'image de profil si elle a été modifiée
      String? profileImageUrl = _user?.profileImageUrl;
      if (_imageFile != null) {
        profileImageUrl = await storageService.uploadUserProfileImage(
          _user!.uid,
          _imageFile!,
        );
      }

      // Mettre à jour l'utilisateur
      final updatedUser = UserModel(
        uid: _user!.uid,
        email: _user!.email,
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        profileImageUrl: profileImageUrl,
        createdAt: _user!.createdAt,
        isAdmin: _user!.isAdmin,
      );

      await databaseService.updateUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès'),
            backgroundColor: AppTheme.accentColor,
          ),
        );

        // Mettre à jour l'état
        setState(() {
          _user = updatedUser;
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour du profil: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // Se déconnecter
  Future<void> _signOut() async {
    // Confirmer la déconnexion
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Stocker le service d'authentification avant toute opération asynchrone
      final authService = Provider.of<AuthService>(context, listen: false);

      // Vérifier si le contexte est toujours valide
      if (!mounted) return;

      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Déconnexion en cours...'),
            ],
          ),
        ),
      );

      // Déconnecter l'utilisateur
      await authService.signOut();

      // Fermer le dialogue de chargement
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Rediriger vers la page d'authentification
      if (mounted) {
        // Utiliser go pour naviguer vers la page d'authentification
        context.go('/auth');

        // Forcer un rafraîchissement de l'application après un court délai
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            context.go('/auth');
          }
        });
      }
    } catch (e) {
      // Fermer le dialogue de chargement en cas d'erreur
      if (mounted) {
        Navigator.of(context).pop();

        // Afficher un message d'erreur
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
      appBar: AdminAppBar(
        title: 'Mon profil',
        actions: [
          // Bouton de déconnexion
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: _isLoading
          ? const LoadingIndicator(message: 'Chargement du profil...')
          : _errorMessage != null
              ? ErrorMessage(
                  message: 'Erreur: $_errorMessage',
                  onRetry: _loadUserData,
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête du profil
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Avatar
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  // Avatar
                                  _imageFile != null
                                      ? CircleAvatar(
                                          radius: 50,
                                          backgroundImage: FileImage(_imageFile!),
                                        )
                                      : UserAvatar(
                                          imageUrl: _user?.profileImageUrl,
                                          name: _user?.fullName ?? '',
                                          size: 100,
                                        ),

                                  // Bouton pour modifier la photo
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      onPressed: _pickImage,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(width: 16),

                              // Informations de base
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _user?.fullName ?? '',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _user?.email ?? '',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Chip(
                                      label: Text('Administrateur'),
                                      backgroundColor: AppTheme.primaryColor,
                                      labelStyle: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Inscrit le ${DateFormat('dd/MM/yyyy').format(_user?.createdAt ?? DateTime.now())}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Formulaire de modification du profil
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Modifier mon profil',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Nom complet
                                TextFormField(
                                  controller: _fullNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nom complet',
                                    prefixIcon: Icon(Icons.person),
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez entrer votre nom complet';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 16),

                                // Téléphone
                                TextFormField(
                                  controller: _phoneController,
                                  decoration: const InputDecoration(
                                    labelText: 'Téléphone',
                                    prefixIcon: Icon(Icons.phone),
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.phone,
                                ),

                                const SizedBox(height: 16),

                                // Email (non modifiable)
                                TextFormField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(Icons.email),
                                    border: OutlineInputBorder(),
                                    filled: true,
                                    fillColor: Color(0xFFEEEEEE),
                                  ),
                                  enabled: false,
                                ),

                                const SizedBox(height: 24),

                                // Bouton d'enregistrement
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _isSaving ? null : _saveProfile,
                                    icon: _isSaving
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.save),
                                    label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Bouton de déconnexion
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _signOut,
                          icon: const Icon(Icons.logout, color: AppTheme.errorColor),
                          label: const Text(
                            'Déconnexion',
                            style: TextStyle(color: AppTheme.errorColor),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: AppTheme.errorColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
