import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

// Service de gestion des permissions granulaires
class PermissionService extends ChangeNotifier {
  // Définition des permissions disponibles
  static const Map<String, String> permissionDescriptions = {
    // Permissions utilisateurs
    'view_users': 'Voir les utilisateurs',
    'create_users': 'Créer des utilisateurs',
    'edit_users': 'Modifier les utilisateurs',
    'delete_users': 'Supprimer des utilisateurs',
    
    // Permissions agents
    'view_agents': 'Voir les agents',
    'create_agents': 'Créer des agents',
    'edit_agents': 'Modifier les agents',
    'delete_agents': 'Supprimer des agents',
    'certify_agents': 'Certifier les agents',
    'toggle_agent_availability': 'Modifier la disponibilité des agents',
    
    // Permissions réservations
    'view_reservations': 'Voir les réservations',
    'create_reservations': 'Créer des réservations',
    'edit_reservations': 'Modifier les réservations',
    'delete_reservations': 'Supprimer les réservations',
    'approve_reservations': 'Approuver les réservations',
    'reject_reservations': 'Rejeter les réservations',
    
    // Permissions système
    'view_audit_logs': 'Voir les logs d\'audit',
    'view_statistics': 'Voir les statistiques',
    'manage_settings': 'Gérer les paramètres',
    'manage_permissions': 'Gérer les permissions',
    'manage_notifications': 'Gérer les notifications',
    'export_data': 'Exporter des données',
    'import_data': 'Importer des données',
    
    // Permissions modération
    'moderate_reviews': 'Modérer les avis',
    'manage_reports': 'Gérer les signalements',
    
    // Permissions de base
    'view_own_data': 'Voir ses propres données',
    'edit_own_profile': 'Modifier son propre profil',
  };

  // Définition des rôles et leurs permissions par défaut
  static const Map<String, List<String>> rolePermissions = {
    'super_admin': [
      'view_users', 'create_users', 'edit_users', 'delete_users',
      'view_agents', 'create_agents', 'edit_agents', 'delete_agents', 'certify_agents', 'toggle_agent_availability',
      'view_reservations', 'create_reservations', 'edit_reservations', 'delete_reservations', 'approve_reservations', 'reject_reservations',
      'view_audit_logs', 'view_statistics', 'manage_settings', 'manage_permissions', 'manage_notifications', 'export_data', 'import_data',
      'moderate_reviews', 'manage_reports',
      'view_own_data', 'edit_own_profile',
    ],
    'admin': [
      'view_users', 'create_users', 'edit_users',
      'view_agents', 'create_agents', 'edit_agents', 'certify_agents', 'toggle_agent_availability',
      'view_reservations', 'create_reservations', 'edit_reservations', 'approve_reservations', 'reject_reservations',
      'view_audit_logs', 'view_statistics', 'manage_notifications', 'export_data',
      'moderate_reviews', 'manage_reports',
      'view_own_data', 'edit_own_profile',
    ],
    'moderator': [
      'view_users',
      'view_agents', 'edit_agents', 'toggle_agent_availability',
      'view_reservations', 'edit_reservations', 'approve_reservations', 'reject_reservations',
      'view_audit_logs', 'view_statistics', 'manage_notifications',
      'moderate_reviews', 'manage_reports',
      'view_own_data', 'edit_own_profile',
    ],
    'user': [
      'view_agents',
      'create_reservations', 'view_reservations', 'edit_own_reservations',
      'view_own_data', 'edit_own_profile',
    ],
  };

  // Cache des permissions utilisateur
  final Map<String, Set<String>> _userPermissionsCache = {};

  // Vérifier si un utilisateur a une permission spécifique
  bool hasPermission(UserModel user, String permission) {
    // Les super-administrateurs ont toutes les permissions
    if (user.isAdmin && (user.permissions == null || user.permissions!.isEmpty)) {
      return true;
    }

    // Vérifier les permissions personnalisées de l'utilisateur
    final userPermissions = _getUserPermissions(user);
    return userPermissions.contains(permission);
  }

  // Vérifier si un utilisateur a toutes les permissions spécifiées
  bool hasAllPermissions(UserModel user, List<String> permissions) {
    return permissions.every((permission) => hasPermission(user, permission));
  }

  // Vérifier si un utilisateur a au moins une des permissions spécifiées
  bool hasAnyPermission(UserModel user, List<String> permissions) {
    return permissions.any((permission) => hasPermission(user, permission));
  }

  // Obtenir les permissions d'un utilisateur
  Set<String> _getUserPermissions(UserModel user) {
    // Vérifier le cache
    if (_userPermissionsCache.containsKey(user.uid)) {
      return _userPermissionsCache[user.uid]!;
    }

    Set<String> permissions = {};

    // Si l'utilisateur est admin mais n'a pas de permissions personnalisées,
    // utiliser les permissions par défaut du rôle admin
    if (user.isAdmin && (user.permissions == null || user.permissions!.isEmpty)) {
      permissions.addAll(rolePermissions['admin']!);
    } else if (user.permissions != null) {
      permissions.addAll(user.permissions!);
    }

    // Ajouter les permissions de base pour tous les utilisateurs
    permissions.addAll(rolePermissions['user']!);

    // Mettre en cache
    _userPermissionsCache[user.uid] = permissions;

    return permissions;
  }

  // Mettre à jour les permissions d'un utilisateur
  void updateUserPermissions(String userId, List<String> permissions) {
    _userPermissionsCache[userId] = permissions.toSet();
    notifyListeners();
  }

  // Effacer le cache des permissions pour un utilisateur
  void clearUserPermissionsCache(String userId) {
    _userPermissionsCache.remove(userId);
    notifyListeners();
  }

  // Effacer tout le cache
  void clearCache() {
    _userPermissionsCache.clear();
    notifyListeners();
  }

  // Obtenir la description d'une permission
  String getPermissionDescription(String permission) {
    return permissionDescriptions[permission] ?? permission;
  }

  // Obtenir toutes les permissions disponibles
  List<String> getAllPermissions() {
    return permissionDescriptions.keys.toList();
  }

  // Obtenir les permissions pour un rôle spécifique
  List<String> getRolePermissions(String role) {
    return rolePermissions[role] ?? [];
  }

  // Valider une liste de permissions
  List<String> validatePermissions(List<String> permissions) {
    return permissions.where((permission) => 
      permissionDescriptions.containsKey(permission)
    ).toList();
  }

  // Obtenir les permissions manquantes pour un rôle
  List<String> getMissingPermissionsForRole(List<String> userPermissions, String requiredRole) {
    final requiredPermissions = rolePermissions[requiredRole] ?? [];
    return requiredPermissions.where((permission) => 
      !userPermissions.contains(permission)
    ).toList();
  }

  // Vérifier si les permissions d'un utilisateur correspondent à un rôle
  bool userHasRolePermissions(UserModel user, String role) {
    final requiredPermissions = rolePermissions[role] ?? [];
    return hasAllPermissions(user, requiredPermissions);
  }

  // Obtenir le rôle effectif d'un utilisateur basé sur ses permissions
  String getUserEffectiveRole(UserModel user) {
    if (user.isAdmin) {
      if (hasAllPermissions(user, rolePermissions['super_admin']!)) {
        return 'super_admin';
      }
      if (hasAllPermissions(user, rolePermissions['admin']!)) {
        return 'admin';
      }
      if (hasAllPermissions(user, rolePermissions['moderator']!)) {
        return 'moderator';
      }
    }
    return 'user';
  }

  // Regrouper les permissions par catégorie
  Map<String, List<String>> getPermissionsByCategory() {
    final Map<String, List<String>> categorized = {
      'Utilisateurs': [
        'view_users', 'create_users', 'edit_users', 'delete_users'
      ],
      'Agents': [
        'view_agents', 'create_agents', 'edit_agents', 'delete_agents', 
        'certify_agents', 'toggle_agent_availability'
      ],
      'Réservations': [
        'view_reservations', 'create_reservations', 'edit_reservations', 
        'delete_reservations', 'approve_reservations', 'reject_reservations'
      ],
      'Système': [
        'view_audit_logs', 'view_statistics', 'manage_settings', 
        'manage_permissions', 'manage_notifications', 'export_data', 'import_data'
      ],
      'Modération': [
        'moderate_reviews', 'manage_reports'
      ],
      'Base': [
        'view_own_data', 'edit_own_profile'
      ],
    };

    return categorized;
  }

  @override
  void dispose() {
    clearCache();
    super.dispose();
  }
}
