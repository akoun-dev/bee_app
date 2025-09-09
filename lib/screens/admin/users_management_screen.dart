import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';
import '../../services/authorization_service.dart';
import '../../services/verification_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/admin_app_bar.dart';
import '../../widgets/admin_drawer.dart';

// Écran de gestion des utilisateurs (pour admin)
class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  // État
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _showOnlyNonAdmins = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Vérifier que l'utilisateur est bien un administrateur
  Future<void> _checkAdminStatus() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userData = await authService.getCurrentUserData();

      if (userData == null || !userData.isAdmin) {
        if (mounted) {
          // Rediriger vers la page de connexion admin
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppConstants.errorPermission),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          context.go('/admin');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        context.go('/admin');
      }
    }
  }

  // Filtrer les utilisateurs
  List<UserModel> _filterUsers(List<UserModel> users) {
    if (_searchQuery.isEmpty) {
      return users;
    }

    final query = _searchQuery.toLowerCase();
    return users.where((user) {
      return user.fullName.toLowerCase().contains(query) ||
             user.email.toLowerCase().contains(query) ||
             (user.phoneNumber != null && user.phoneNumber!.toLowerCase().contains(query));
    }).toList();
  }

  // Afficher le dialogue de détails utilisateur
  Future<void> _showUserDetailsDialog(UserModel user) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails de ${user.fullName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Center(
                child: UserAvatar(
                  imageUrl: user.profileImageUrl,
                  name: user.fullName,
                  size: 80,
                ),
              ),
              const SizedBox(height: 16),
              
              // Informations utilisateur
              _buildInfoRow('Nom complet', user.fullName),
              _buildInfoRow('Email', user.email),
              _buildInfoRow('Téléphone', user.phoneNumber ?? 'Non renseigné'),
              _buildInfoRow('Statut', user.isAdmin ? 'Administrateur' : 'Utilisateur'),
              _buildInfoRow('Date d\'inscription', 
                DateFormat('dd/MM/yyyy à HH:mm').format(user.createdAt)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  // Construire une ligne d'information
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  // Supprimer un utilisateur
  Future<void> _deleteUser(UserModel user) async {
    // Stocker les services avant toute opération asynchrone
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final authorizationService = Provider.of<AuthorizationService>(context, listen: false);
    final verificationService = Provider.of<VerificationService>(context, listen: false);

    // Vérifier que l'utilisateur n'est pas l'administrateur actuel
    final currentUser = await authService.getCurrentUserData();
    if (currentUser?.uid == user.uid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous ne pouvez pas supprimer votre propre compte'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    // Vérifier les permissions
    final hasPermission = await authorizationService.canDeleteEntity('user', user.uid);
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous n\'avez pas les permissions nécessaires pour supprimer cet utilisateur'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    // Demander une double vérification pour l'action critique
    final verified = await verificationService.requestDoubleVerification(
      context,
      action: 'Supprimer l\'utilisateur',
      targetName: user.fullName,
      additionalMessage: 'Cette action est irréversible et supprimera toutes les données associées à cet utilisateur.',
    );

    if (!verified) return;

    try {
      // Sauvegarder les anciennes données pour l'audit
      final oldData = {
        'fullName': user.fullName,
        'email': user.email,
        'isAdmin': user.isAdmin,
        'createdAt': user.createdAt.toIso8601String(),
      };

      // Supprimer l'image de profil si elle existe
      if (user.profileImageUrl != null) {
        await storageService.deleteImage(user.profileImageUrl!);
      }

      // Supprimer l'utilisateur
      await databaseService.deleteUser(user.uid);

      // Journaliser l'action
      await authorizationService.logAdminAction(
        action: 'delete_user',
        targetType: 'user',
        targetId: user.uid,
        oldData: oldData,
        description: 'Suppression de l\'utilisateur ${user.fullName}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Utilisateur supprimé avec succès'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression de l\'utilisateur: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: AdminAppBar(
        title: 'Gestion des utilisateurs',
        actions: [
          // Navigation vers les réservations en attente
          IconButton(
            icon: const Icon(Icons.pending_actions),
            onPressed: () => context.go('/admin/reservations'),
            tooltip: 'Réservations',
          ),
          // Navigation vers les statistiques
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.go('/admin/statistics'),
            tooltip: 'Statistiques',
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          // Barre de recherche et filtres
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Barre de recherche
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un utilisateur...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                
                const SizedBox(height: 8),
                
                // Filtre administrateurs/utilisateurs
                SwitchListTile(
                  title: const Text('Afficher uniquement les utilisateurs (non-admin)'),
                  value: _showOnlyNonAdmins,
                  onChanged: (value) {
                    setState(() {
                      _showOnlyNonAdmins = value;
                    });
                  },
                  dense: true,
                  activeThumbColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ),

          // Liste des utilisateurs
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _showOnlyNonAdmins 
                  ? databaseService.getNonAdminUsers()
                  : databaseService.getAllUsers(),
              builder: (context, snapshot) {
                // Afficher un indicateur de chargement
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator(
                    message: 'Chargement des utilisateurs...',
                  );
                }

                // Afficher un message d'erreur
                if (snapshot.hasError) {
                  return ErrorMessage(
                    message: 'Erreur: ${snapshot.error}',
                    onRetry: () => setState(() {}),
                  );
                }

                // Récupérer et filtrer les utilisateurs
                final users = snapshot.data ?? [];
                final filteredUsers = _filterUsers(users);

                // Afficher un message si aucun utilisateur n'est trouvé
                if (filteredUsers.isEmpty) {
                  return const EmptyMessage(
                    message: 'Aucun utilisateur trouvé',
                    icon: Icons.person_off,
                  );
                }

                // Afficher la liste des utilisateurs
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: UserAvatar(
                          imageUrl: user.profileImageUrl,
                          name: user.fullName,
                          size: 40,
                        ),
                        title: Text(
                          user.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.email),
                            if (user.phoneNumber != null)
                              Text(user.phoneNumber!),
                            Text(
                              'Inscrit le ${DateFormat('dd/MM/yyyy').format(user.createdAt)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (user.isAdmin)
                              const Chip(
                                label: Text('Admin'),
                                backgroundColor: AppTheme.primaryColor,
                                labelStyle: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            IconButton(
                              icon: const Icon(Icons.info),
                              onPressed: () => _showUserDetailsDialog(user),
                              tooltip: 'Détails',
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: AppTheme.errorColor,
                              ),
                              onPressed: () => _deleteUser(user),
                              tooltip: 'Supprimer',
                            ),
                          ],
                        ),
                        onTap: () => _showUserDetailsDialog(user),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
