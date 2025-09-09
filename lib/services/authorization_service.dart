import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../services/auth_service.dart';
import '../services/permission_service.dart';
import '../services/security_service.dart';
import '../services/audit_service.dart';
import '../utils/constants.dart';
import '../models/user_model.dart';

final logger = Logger();

// Service centralisé pour la gestion des autorisations
class AuthorizationService extends ChangeNotifier {
  final AuthService _authService;
  final PermissionService _permissionService;
  final SecurityService _securityService;
  final AuditService _auditService;

  AuthorizationService({
    required AuthService authService,
    required PermissionService permissionService,
    required SecurityService securityService,
    required AuditService auditService,
  }) : _authService = authService,
       _permissionService = permissionService,
       _securityService = securityService,
       _auditService = auditService;

  // Vérifier si l'utilisateur actuel est un administrateur
  Future<bool> isCurrentUserAdmin() async {
    final currentUser = await _authService.getCurrentUserData();
    return currentUser?.isAdmin ?? false;
  }

  // Vérifier si l'utilisateur actuel est connecté
  Future<bool> isCurrentUserAuthenticated() async {
    return await _authService.isUserLoggedIn();
  }

  // Vérifier si l'utilisateur actuel a une permission spécifique
  Future<bool> currentUserHasPermission(String permission) async {
    final currentUser = await _authService.getCurrentUserData();
    if (currentUser == null) return false;
    
    return _permissionService.hasPermission(currentUser, permission);
  }

  // Vérifier si l'utilisateur actuel a toutes les permissions spécifiées
  Future<bool> currentUserHasAllPermissions(List<String> permissions) async {
    final currentUser = await _authService.getCurrentUserData();
    if (currentUser == null) return false;
    
    return _permissionService.hasAllPermissions(currentUser, permissions);
  }

  // Vérifier si l'utilisateur actuel a au moins une des permissions spécifiées
  Future<bool> currentUserHasAnyPermission(List<String> permissions) async {
    final currentUser = await _authService.getCurrentUserData();
    if (currentUser == null) return false;
    
    return _permissionService.hasAnyPermission(currentUser, permissions);
  }

  // Vérifier l'accès administrateur avec session active
  Future<bool> verifyAdminAccess() async {
    // Vérifier si l'utilisateur est connecté
    if (!await isCurrentUserAuthenticated()) {
      throw Exception('Utilisateur non connecté');
    }

    // Vérifier si l'utilisateur est administrateur
    if (!await isCurrentUserAdmin()) {
      throw Exception(AppConstants.errorPermission);
    }

    // Vérifier si la session administrative est active
    if (!_securityService.isSessionActive) {
      throw Exception('Session administrative expirée');
    }

    // Mettre à jour l'activité de la session
    await _securityService.updateActivity();

    return true;
  }

  // Vérifier l'accès à une fonctionnalité spécifique
  Future<bool> canAccessFeature(String feature, {String? targetType}) async {
    try {
      await verifyAdminAccess();
      
      // Vérifier les permissions spécifiques
      switch (feature) {
        case 'view_users':
          return await currentUserHasPermission('view_users');
        case 'create_users':
          return await currentUserHasPermission('create_users');
        case 'edit_users':
          return await currentUserHasPermission('edit_users');
        case 'delete_users':
          return await currentUserHasPermission('delete_users');
          
        case 'view_agents':
          return await currentUserHasPermission('view_agents');
        case 'create_agents':
          return await currentUserHasPermission('create_agents');
        case 'edit_agents':
          return await currentUserHasPermission('edit_agents');
        case 'delete_agents':
          return await currentUserHasPermission('delete_agents');
        case 'certify_agents':
          return await currentUserHasPermission('certify_agents');
        case 'toggle_agent_availability':
          return await currentUserHasPermission('toggle_agent_availability');
          
        case 'view_reservations':
          return await currentUserHasPermission('view_reservations');
        case 'create_reservations':
          return await currentUserHasPermission('create_reservations');
        case 'edit_reservations':
          return await currentUserHasPermission('edit_reservations');
        case 'delete_reservations':
          return await currentUserHasPermission('delete_reservations');
        case 'approve_reservations':
          return await currentUserHasPermission('approve_reservations');
        case 'reject_reservations':
          return await currentUserHasPermission('reject_reservations');
          
        case 'view_audit_logs':
          return await currentUserHasPermission('view_audit_logs');
        case 'view_statistics':
          return await currentUserHasPermission('view_statistics');
        case 'manage_settings':
          return await currentUserHasPermission('manage_settings');
        case 'manage_permissions':
          return await currentUserHasPermission('manage_permissions');
        case 'manage_notifications':
          return await currentUserHasPermission('manage_notifications');
        case 'export_data':
          return await currentUserHasPermission('export_data');
        case 'import_data':
          return await currentUserHasPermission('import_data');
          
        case 'moderate_reviews':
          return await currentUserHasPermission('moderate_reviews');
        case 'manage_reports':
          return await currentUserHasPermission('manage_reports');
          
        default:
          return false;
      }
    } catch (e) {
      logger.w('Accès refusé à la fonctionnalité $feature: ${e.toString()}');
      return false;
    }
  }

  // Vérifier si l'utilisateur peut modifier une entité spécifique
  Future<bool> canModifyEntity(String entityType, String entityId) async {
    try {
      await verifyAdminAccess();
      
      final currentUser = await _authService.getCurrentUserData();
      if (currentUser == null) return false;

      // Les super-administrateurs peuvent tout modifier
      if (_permissionService.hasPermission(currentUser, 'manage_settings')) {
        return true;
      }

      // Vérifier les permissions spécifiques
      switch (entityType) {
        case 'user':
          return await currentUserHasPermission('edit_users');
        case 'agent':
          return await currentUserHasPermission('edit_agents');
        case 'reservation':
          return await currentUserHasPermission('edit_reservations');
        default:
          return false;
      }
    } catch (e) {
      logger.w('Accès refusé à la modification de $entityType $entityId: ${e.toString()}');
      return false;
    }
  }

  // Vérifier si l'utilisateur peut supprimer une entité spécifique
  Future<bool> canDeleteEntity(String entityType, String entityId) async {
    try {
      await verifyAdminAccess();
      
      final currentUser = await _authService.getCurrentUserData();
      if (currentUser == null) return false;

      // Les super-administrateurs peuvent tout supprimer
      if (_permissionService.hasPermission(currentUser, 'manage_settings')) {
        return true;
      }

      // Vérifier les permissions spécifiques
      switch (entityType) {
        case 'user':
          return await currentUserHasPermission('delete_users');
        case 'agent':
          return await currentUserHasPermission('delete_agents');
        case 'reservation':
          return await currentUserHasPermission('delete_reservations');
        default:
          return false;
      }
    } catch (e) {
      logger.w('Accès refusé à la suppression de $entityType $entityId: ${e.toString()}');
      return false;
    }
  }

  // Obtenir les permissions de l'utilisateur actuel
  Future<Set<String>> getCurrentUserPermissions() async {
    final currentUser = await _authService.getCurrentUserData();
    if (currentUser == null) return {};
    
    // Calculer les permissions manuellement sans utiliser la réflexion
    return _calculateUserPermissions(currentUser);
  }

  // Méthode pour calculer les permissions d'un utilisateur sans réflexion
  Set<String> _calculateUserPermissions(UserModel user) {
    Set<String> permissions = {};

    // Si l'utilisateur est admin mais n'a pas de permissions personnalisées,
    // utiliser les permissions par défaut du rôle admin
    if (user.isAdmin && (user.permissions == null || user.permissions!.isEmpty)) {
      permissions.addAll(PermissionService.rolePermissions['admin'] ?? []);
    } else if (user.permissions != null) {
      permissions.addAll(user.permissions!);
    }

    // Ajouter les permissions de base pour tous les utilisateurs
    permissions.addAll(PermissionService.rolePermissions['user'] ?? []);

    return permissions;
  }

  // Obtenir le rôle effectif de l'utilisateur actuel
  Future<String> getCurrentUserRole() async {
    final currentUser = await _authService.getCurrentUserData();
    if (currentUser == null) return 'user';
    
    return _permissionService.getUserEffectiveRole(currentUser);
  }

  // Journaliser une action administrative avec vérification des permissions
  Future<void> logAdminAction({
    required String action,
    required String targetType,
    required String targetId,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
    String? description,
  }) async {
    try {
      final currentUser = await _authService.getCurrentUserData();
      if (currentUser == null) {
        logger.w('Tentative de journalisation sans utilisateur connecté');
        return;
      }

      await _auditService.logAdminAction(
        adminId: currentUser.uid,
        adminEmail: currentUser.email,
        action: action,
        targetType: targetType,
        targetId: targetId,
        oldData: oldData,
        newData: newData,
        description: description,
      );
    } catch (e) {
      logger.e('Erreur lors de la journalisation de l\'action: ${e.toString()}');
    }
  }

  // Vérifier et journaliser une action critique
  Future<bool> performCriticalAction({
    required String action,
    required String permission,
    required String targetType,
    required String targetId,
    required Future<bool> Function() actionFunction,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
    String? description,
  }) async {
    try {
      // Vérifier les permissions
      if (!await currentUserHasPermission(permission)) {
        throw Exception('Permission refusée pour l\'action: $action');
      }

      // Vérifier la session administrative
      await verifyAdminAccess();

      // Exécuter l'action
      final result = await actionFunction();

      // Journaliser l'action
      await logAdminAction(
        action: action,
        targetType: targetType,
        targetId: targetId,
        oldData: oldData,
        newData: newData,
        description: description,
      );

      return result;
    } catch (e) {
      logger.e('Échec de l\'action critique $action: ${e.toString()}');
      rethrow;
    }
  }

  // Rafraîchir les permissions de l'utilisateur actuel
  Future<void> refreshCurrentUserPermissions() async {
    final currentUser = await _authService.getCurrentUserData();
    if (currentUser != null) {
      _permissionService.clearUserPermissionsCache(currentUser.uid);
      notifyListeners();
    }
  }

  // Vérifier si l'utilisateur peut accéder à une route spécifique
  Future<bool> canAccessRoute(String route) async {
    try {
      switch (route) {
        case '/admin':
        case '/admin/dashboard':
          return await isCurrentUserAdmin();
          
        case '/admin/users':
          return await currentUserHasPermission('view_users');
          
        case '/admin/agents':
          return await currentUserHasPermission('view_agents');
          
        case '/admin/reservations':
        case '/admin/pending-reservations':
          return await currentUserHasPermission('view_reservations');
          
        case '/admin/statistics':
          return await currentUserHasPermission('view_statistics');
          
        case '/admin/audit-logs':
          return await currentUserHasPermission('view_audit_logs');
          
        case '/admin/permissions':
          return await currentUserHasPermission('manage_permissions');
          
        case '/admin/settings':
          return await currentUserHasPermission('manage_settings');
          
        case '/admin/notifications':
          return await currentUserHasPermission('manage_notifications');
          
        default:
          return false;
      }
    } catch (e) {
      logger.w('Accès refusé à la route $route: ${e.toString()}');
      return false;
    }
  }

  // Obtenir les routes accessibles pour l'utilisateur actuel
  Future<List<String>> getAccessibleRoutes() async {
    final accessibleRoutes = <String>[];
    
    if (await isCurrentUserAdmin()) {
      accessibleRoutes.addAll([
        '/admin',
        '/admin/dashboard',
      ]);
      
      if (await currentUserHasPermission('view_users')) {
        accessibleRoutes.add('/admin/users');
      }
      
      if (await currentUserHasPermission('view_agents')) {
        accessibleRoutes.add('/admin/agents');
      }
      
      if (await currentUserHasPermission('view_reservations')) {
        accessibleRoutes.addAll([
          '/admin/reservations',
          '/admin/pending-reservations',
        ]);
      }
      
      if (await currentUserHasPermission('view_statistics')) {
        accessibleRoutes.add('/admin/statistics');
      }
      
      if (await currentUserHasPermission('view_audit_logs')) {
        accessibleRoutes.add('/admin/audit-logs');
      }
      
      if (await currentUserHasPermission('manage_permissions')) {
        accessibleRoutes.add('/admin/permissions');
      }
      
      if (await currentUserHasPermission('manage_settings')) {
        accessibleRoutes.add('/admin/settings');
      }
      
      if (await currentUserHasPermission('manage_notifications')) {
        accessibleRoutes.add('/admin/notifications');
      }
    }
    
    return accessibleRoutes;
  }
}
