import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

final logger = Logger();

// Service de sécurité pour les fonctionnalités avancées
class SecurityService extends ChangeNotifier {
  static const String _lastActivityKey = 'last_admin_activity';
  static const String _sessionTokenKey = 'admin_session_token';
  static const String _loginAttemptsKey = 'login_attempts';
  static const String _lockoutTimeKey = 'lockout_time';

  // Configuration de sécurité
  static const int sessionTimeoutMinutes = 30;
  static const int maxLoginAttempts = 5;
  static const int lockoutDurationMinutes = 15;

  Timer? _sessionTimer;
  bool _isSessionActive = false;
  int _loginAttempts = 0;
  DateTime? _lockoutTime;

  // Getters
  bool get isSessionActive => _isSessionActive;
  int get loginAttempts => _loginAttempts;
  bool get isLockedOut =>
      _lockoutTime != null && DateTime.now().isBefore(_lockoutTime!);

  Duration? get lockoutTimeRemaining =>
      _lockoutTime?.difference(DateTime.now());

  // Initialiser le service de sécurité
  Future<void> initialize() async {
    await _loadSecurityData();
    _checkSessionValidity();
  }

  // Charger les données de sécurité depuis le stockage local
  Future<void> _loadSecurityData() async {
    final prefs = await SharedPreferences.getInstance();

    _loginAttempts = prefs.getInt(_loginAttemptsKey) ?? 0;

    final lockoutTimeString = prefs.getString(_lockoutTimeKey);
    if (lockoutTimeString != null) {
      _lockoutTime = DateTime.parse(lockoutTimeString);

      // Vérifier si le lockout a expiré
      if (DateTime.now().isAfter(_lockoutTime!)) {
        await _clearLockout();
      }
    }
  }

  // Démarrer une session admin
  Future<void> startAdminSession(String adminId) async {
    if (isLockedOut) {
      throw Exception(
        'Compte temporairement verrouillé. Réessayez dans ${lockoutTimeRemaining?.inMinutes} minutes.',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final sessionToken = _generateSessionToken();

    await prefs.setString(_sessionTokenKey, sessionToken);
    await prefs.setString(_lastActivityKey, DateTime.now().toIso8601String());

    _isSessionActive = true;
    _startSessionTimer();

    // Réinitialiser les tentatives de connexion en cas de succès
    await _resetLoginAttempts();

    notifyListeners();
  }

  // Enregistrer une tentative de connexion échouée
  Future<void> recordFailedLoginAttempt() async {
    _loginAttempts++;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_loginAttemptsKey, _loginAttempts);

    // Verrouiller le compte si trop de tentatives
    if (_loginAttempts >= maxLoginAttempts) {
      await _lockAccount();
    }

    notifyListeners();
  }

  // Verrouiller le compte
  Future<void> _lockAccount() async {
    _lockoutTime = DateTime.now().add(
      const Duration(minutes: lockoutDurationMinutes),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lockoutTimeKey, _lockoutTime!.toIso8601String());

    notifyListeners();
  }

  // Effacer le verrouillage
  Future<void> _clearLockout() async {
    _lockoutTime = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lockoutTimeKey);
    await _resetLoginAttempts();

    notifyListeners();
  }

  // Réinitialiser les tentatives de connexion
  Future<void> _resetLoginAttempts() async {
    _loginAttempts = 0;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loginAttemptsKey);
  }

  // Mettre à jour l'activité de la session
  Future<void> updateActivity() async {
    if (!_isSessionActive) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastActivityKey, DateTime.now().toIso8601String());

    // Redémarrer le timer de session
    _startSessionTimer();
  }

  // Vérifier la validité de la session
  Future<void> _checkSessionValidity() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActivityString = prefs.getString(_lastActivityKey);
    final sessionToken = prefs.getString(_sessionTokenKey);

    if (lastActivityString == null || sessionToken == null) {
      _isSessionActive = false;
      return;
    }

    final lastActivity = DateTime.parse(lastActivityString);
    final timeSinceLastActivity = DateTime.now().difference(lastActivity);

    if (timeSinceLastActivity.inMinutes > sessionTimeoutMinutes) {
      await endSession();
    } else {
      _isSessionActive = true;
      _startSessionTimer();
    }
  }

  // Démarrer le timer de session
  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(
      const Duration(minutes: sessionTimeoutMinutes),
      () => endSession(),
    );
  }

  // Terminer la session
  Future<void> endSession() async {
    _sessionTimer?.cancel();
    _isSessionActive = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionTokenKey);
    await prefs.remove(_lastActivityKey);

    notifyListeners();
  }

  // Générer un token de session
  String _generateSessionToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 31) % 1000000;
    return 'admin_session_${timestamp}_$random';
  }

  // Valider les permissions pour une action spécifique
  bool hasPermission(String action, {String? targetType}) {
    if (!_isSessionActive) return false;

    // Journaliser la vérification de permission pour l'audit
    logger.i('Vérification de permission: action=$action, targetType=$targetType');

    // Permissions par défaut pour les administrateurs
    // Dans une implémentation réelle, ces permissions seraient chargées depuis la base de données
    final Map<String, bool> defaultAdminPermissions = {
      'view_users': true,
      'create_users': true,
      'edit_users': true,
      'delete_users': true,
      'view_agents': true,
      'create_agents': true,
      'edit_agents': true,
      'delete_agents': true,
      'view_reservations': true,
      'manage_reservations': true,
      'view_audit_logs': true,
      'certify_agents': true,
      'toggle_agent_availability': true,
      'modify_settings': true,
      'view_statistics': true,
      'export_data': true,
    };

    // Vérifier les permissions basées sur l'action
    switch (action) {
      case 'delete_user':
      case 'delete_agent':
        return defaultAdminPermissions['delete_users'] ?? false;
      case 'view_audit_logs':
        return defaultAdminPermissions['view_audit_logs'] ?? false;
      case 'modify_settings':
        return defaultAdminPermissions['modify_settings'] ?? false;
      case 'certify_agents':
        return defaultAdminPermissions['certify_agents'] ?? false;
      case 'toggle_agent_availability':
        return defaultAdminPermissions['toggle_agent_availability'] ?? false;
      case 'export_data':
        return defaultAdminPermissions['export_data'] ?? false;
      default:
        return defaultAdminPermissions[action] ?? true; // Actions de base autorisées
    }
  }

  // Vérifier si l'utilisateur a des permissions étendues
  bool hasExtendedPermissions() {
    if (!_isSessionActive) return false;
    
    // Dans une implémentation réelle, vérifier si l'utilisateur a des permissions étendues
    // Par exemple, un super-administrateur
    return true; // Pour l'instant, tous les admins ont des permissions étendues
  }

  // Vérifier si une action critique nécessite une double vérification
  bool requiresDoubleVerification(String action) {
    const criticalActions = {
      'delete_user',
      'delete_agent',
      'modify_settings',
      'export_data',
      'mass_delete',
    };

    return criticalActions.contains(action);
  }

  // Obtenir le niveau de sécurité requis pour une action
  String getSecurityLevel(String action) {
    const criticalActions = {
      'delete_user': 'high',
      'delete_agent': 'high',
      'modify_settings': 'high',
      'export_data': 'medium',
      'certify_agents': 'medium',
      'toggle_agent_availability': 'low',
    };

    return criticalActions[action] ?? 'low';
  }

  // Journaliser une action de sécurité
  void logSecurityAction(String action, String targetType, String targetId, {
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
    String? description,
  }) {
    final logEntry = {
      'timestamp': DateTime.now().toIso8601String(),
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'oldData': oldData,
      'newData': newData,
      'description': description ?? 'Action de sécurité non spécifiée',
      'sessionActive': _isSessionActive,
    };

    logger.i('Action de sécurité: ${maskSensitiveData(logEntry.toString())}');
  }

  // Vérifier la conformité RGPD pour une action
  bool checkGDPRCompliance(String action, Map<String, dynamic> data) {
    const gdprSensitiveActions = {
      'delete_user',
      'export_user_data',
      'view_user_data',
    };

    if (!gdprSensitiveActions.contains(action)) {
      return true; // L'action n'est pas soumise à la conformité RGPD
    }

    // Vérifier si les données contiennent des informations personnelles
    final personalDataFields = ['email', 'fullName', 'phoneNumber', 'address'];
    final containsPersonalData = personalDataFields.any((field) => data.containsKey(field));

    if (containsPersonalData) {
      logger.w('Action RGPD sensible détectée: $action');
      // Dans une implémentation réelle, vous devriez peut-être demander un consentement supplémentaire
    }

    return true;
  }

  // Valider une action avant exécution
  Future<bool> validateAction(String action, String targetType, String targetId, {
    Map<String, dynamic>? data,
  }) async {
    // 1. Vérifier si la session est active
    if (!_isSessionActive) {
      logger.w('Tentative d\'action avec session inactive: $action');
      return false;
    }

    // 2. Vérifier les permissions
    if (!hasPermission(action, targetType: targetType)) {
      logger.w('Permission refusée pour l\'action: $action sur $targetType');
      return false;
    }

    // 3. Vérifier la conformité RGPD si nécessaire
    if (data != null && !checkGDPRCompliance(action, data)) {
      logger.w('Action non conforme RGPD: $action');
      return false;
    }

    // 4. Mettre à jour l'activité de la session
    await updateActivity();

    // 5. Journaliser la validation réussie
    logSecurityAction(
      'validate_action',
      targetType,
      targetId,
      description: 'Validation réussie pour l\'action: $action',
    );

    return true;
  }

  // Vérifier l'intégrité des données sensibles
  bool validateDataIntegrity(Map<String, dynamic> data, String expectedHash) {
    // Implémentation basique - dans un vrai projet, utilisez une vraie fonction de hachage
    final dataString = data.toString();
    final calculatedHash = dataString.hashCode.toString();
    return calculatedHash == expectedHash;
  }

  // Nettoyer les ressources
  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  // Méthodes utilitaires pour la sécurité

  // Masquer les données sensibles dans les logs
  static String maskSensitiveData(String data, {int visibleChars = 4}) {
    if (data.length <= visibleChars) return '*' * data.length;

    final visible = data.substring(0, visibleChars);
    final masked = '*' * (data.length - visibleChars);
    return visible + masked;
  }

  // Valider la force d'un mot de passe
  static Map<String, dynamic> validatePasswordStrength(String password) {
    final hasMinLength = password.length >= 8;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasNumbers = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChars = password.contains(
      RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
    );

    final score =
        [
          hasMinLength,
          hasUppercase,
          hasLowercase,
          hasNumbers,
          hasSpecialChars,
        ].where((test) => test).length;

    String strength;
    if (score < 2) {
      strength = 'Très faible';
    } else if (score < 3) {
      strength = 'Faible';
    } else if (score < 4) {
      strength = 'Moyen';
    } else if (score < 5) {
      strength = 'Fort';
    } else {
      strength = 'Très fort';
    }

    return {
      'score': score,
      'strength': strength,
      'requirements': {
        'minLength': hasMinLength,
        'uppercase': hasUppercase,
        'lowercase': hasLowercase,
        'numbers': hasNumbers,
        'specialChars': hasSpecialChars,
      },
    };
  }

  // Détecter les tentatives d'injection
  static bool detectSQLInjection(String input) {
    final sqlKeywords = [
      'select',
      'insert',
      'update',
      'delete',
      'drop',
      'create',
      'alter',
      'union',
      'or',
      'and',
      '--',
      ';',
      '/*',
      '*/',
      'xp_',
      'sp_',
    ];

    final lowerInput = input.toLowerCase();
    return sqlKeywords.any((keyword) => lowerInput.contains(keyword));
  }

  // Nettoyer les entrées utilisateur
  static String sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '') // Supprimer les balises HTML
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('"', '')
        .replaceAll("'", '') // Supprimer les caractères dangereux
        .trim();
  }
}
