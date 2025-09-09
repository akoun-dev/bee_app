import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/database_service.dart';
import '../../services/audit_service.dart';
import '../../models/user_model.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/admin_app_bar.dart';
import '../../widgets/admin_drawer.dart';

// Écran de gestion des permissions et rôles
class PermissionsManagementScreen extends StatefulWidget {
  const PermissionsManagementScreen({super.key});

  @override
  State<PermissionsManagementScreen> createState() => _PermissionsManagementScreenState();
}

class _PermissionsManagementScreenState extends State<PermissionsManagementScreen> {
  final AuditService _auditService = AuditService();
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  String _selectedRole = 'all'; // 'all', 'admin', 'user'
  bool _isLoading = false;

  // Définition des rôles et permissions
  static const Map<String, Map<String, dynamic>> roles = {
    'super_admin': {
      'name': 'Super Administrateur',
      'description': 'Accès complet à toutes les fonctionnalités',
      'permissions': [
        'manage_users',
        'manage_agents',
        'manage_reservations',
        'view_analytics',
        'manage_settings',
        'view_audit_logs',
        'manage_permissions',
        'delete_data',
      ],
      'color': Colors.red,
    },
    'admin': {
      'name': 'Administrateur',
      'description': 'Gestion des opérations quotidiennes',
      'permissions': [
        'manage_agents',
        'manage_reservations',
        'view_analytics',
        'manage_notifications',
      ],
      'color': AppTheme.primaryColor,
    },
    'moderator': {
      'name': 'Modérateur',
      'description': 'Supervision et modération du contenu',
      'permissions': [
        'view_reservations',
        'moderate_reviews',
        'manage_notifications',
      ],
      'color': Colors.orange,
    },
    'user': {
      'name': 'Utilisateur',
      'description': 'Accès utilisateur standard',
      'permissions': [
        'create_reservations',
        'view_own_data',
        'rate_agents',
      ],
      'color': Colors.green,
    },
  };

  static const Map<String, String> permissionDescriptions = {
    'manage_users': 'Gérer les utilisateurs',
    'manage_agents': 'Gérer les agents',
    'manage_reservations': 'Gérer les réservations',
    'view_analytics': 'Voir les analyses',
    'manage_settings': 'Gérer les paramètres',
    'view_audit_logs': 'Voir les logs d\'audit',
    'manage_permissions': 'Gérer les permissions',
    'delete_data': 'Supprimer des données',
    'manage_notifications': 'Gérer les notifications',
    'view_reservations': 'Voir les réservations',
    'moderate_reviews': 'Modérer les avis',
    'create_reservations': 'Créer des réservations',
    'view_own_data': 'Voir ses propres données',
    'rate_agents': 'Noter les agents',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filtrer les utilisateurs
  List<UserModel> _filterUsers(List<UserModel> users) {
    var filtered = users;

    // Filtre par rôle
    if (_selectedRole != 'all') {
      filtered = filtered.where((user) {
        if (_selectedRole == 'admin') return user.isAdmin;
        if (_selectedRole == 'user') return !user.isAdmin;
        return true;
      }).toList();
    }

    // Filtre par recherche
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((user) {
        return user.fullName.toLowerCase().contains(query) ||
               user.email.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  // Afficher le dialogue de modification des permissions
  Future<void> _showPermissionsDialog(UserModel user) async {
    String selectedRole = user.isAdmin ? 'admin' : 'user';
    List<String> customPermissions = List.from(user.permissions ?? []);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Permissions de ${user.fullName}'),
          content: SizedBox(
            width: 400,
            height: 500,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sélection du rôle
                const Text(
                  'Rôle:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: roles.entries.map((entry) =>
                    DropdownMenuItem(
                      value: entry.key,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: entry.value['color'],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.value['name']),
                              Text(
                                entry.value['description'],
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedRole = value!;
                      customPermissions = List.from(roles[value]!['permissions']);
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Permissions personnalisées
                const Text(
                  'Permissions personnalisées:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                
                Expanded(
                  child: ListView(
                    children: permissionDescriptions.entries.map((entry) {
                      final permission = entry.key;
                      final description = entry.value;
                      final isEnabled = customPermissions.contains(permission);
                      
                      return CheckboxListTile(
                        title: Text(description),
                        subtitle: Text(permission),
                        value: isEnabled,
                        onChanged: (value) {
                          setDialogState(() {
                            if (value == true) {
                              if (!customPermissions.contains(permission)) {
                                customPermissions.add(permission);
                              }
                            } else {
                              customPermissions.remove(permission);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _updateUserPermissions(user, selectedRole, customPermissions);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Sauvegarder'),
            ),
          ],
        ),
      ),
    );
  }

  // Mettre à jour les permissions d'un utilisateur
  Future<void> _updateUserPermissions(
    UserModel user,
    String role,
    List<String> permissions,
  ) async {
    setState(() => _isLoading = true);

    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      
      // Sauvegarder les anciennes données pour l'audit
      final oldData = {
        'role': user.isAdmin ? 'admin' : 'user',
        'permissions': user.permissions ?? [],
      };

      // Mettre à jour l'utilisateur
      final updatedUser = user.copyWith(
        isAdmin: role != 'user',
        permissions: permissions,
      );

      await databaseService.updateUser(updatedUser);

      // Enregistrer dans l'audit
      await _auditService.logAdminAction(
        adminId: 'current_admin_id', // À remplacer par l'ID de l'admin actuel
        adminEmail: 'admin@example.com', // À remplacer par l'email de l'admin actuel
        action: 'update_permissions',
        targetType: 'user',
        targetId: user.id,
        oldData: oldData,
        newData: {
          'role': role,
          'permissions': permissions,
        },
        description: 'Mise à jour des permissions de ${user.fullName}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissions mises à jour avec succès'),
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
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: AdminAppBar(
        title: 'Gestion des permissions',
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showRolesInfoDialog,
            tooltip: 'Informations sur les rôles',
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          // Filtres et recherche
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
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),

                const SizedBox(height: 16),

                // Filtre par rôle
                Row(
                  children: [
                    const Text('Filtrer par rôle: '),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'all', label: Text('Tous')),
                          ButtonSegment(value: 'admin', label: Text('Admins')),
                          ButtonSegment(value: 'user', label: Text('Utilisateurs')),
                        ],
                        selected: {_selectedRole},
                        onSelectionChanged: (Set<String> selection) {
                          setState(() => _selectedRole = selection.first);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Liste des utilisateurs
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: databaseService.getAllUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator(message: 'Chargement des utilisateurs...');
                }

                if (snapshot.hasError) {
                  return ErrorMessage(
                    message: 'Erreur: ${snapshot.error}',
                    onRetry: () => setState(() {}),
                  );
                }

                final users = snapshot.data ?? [];
                final filteredUsers = _filterUsers(users);

                if (filteredUsers.isEmpty) {
                  return const EmptyMessage(
                    message: 'Aucun utilisateur trouvé',
                    icon: Icons.person_off,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return _buildUserCard(user);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Construire la carte d'un utilisateur
  Widget _buildUserCard(UserModel user) {
    final role = user.isAdmin ? 'admin' : 'user';
    final roleInfo = roles[role]!;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: roleInfo['color'].withAlpha(50),
          child: Icon(
            user.isAdmin ? Icons.admin_panel_settings : Icons.person,
            color: roleInfo['color'],
          ),
        ),
        title: Text(
          user.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: roleInfo['color'],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    roleInfo['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${user.permissions?.length ?? 0} permissions',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _showPermissionsDialog(user),
          tooltip: 'Modifier les permissions',
        ),
        isThreeLine: true,
      ),
    );
  }

  // Afficher le dialogue d'informations sur les rôles
  void _showRolesInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informations sur les rôles'),
        content: SizedBox(
          width: 400,
          height: 400,
          child: ListView(
            children: roles.entries.map((entry) {
              final roleKey = entry.key;
              final roleData = entry.value;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: roleData['color'],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            roleData['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(roleData['description']),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: (roleData['permissions'] as List<String>)
                            .map((permission) => Chip(
                                  label: Text(
                                    permissionDescriptions[permission] ?? permission,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
