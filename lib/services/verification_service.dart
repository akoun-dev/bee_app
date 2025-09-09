import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../services/auth_service.dart';
import '../services/security_service.dart';
import '../services/audit_service.dart';
import '../utils/theme.dart';

final logger = Logger();

// Service pour les vérifications supplémentaires des opérations critiques
class VerificationService {
  final AuthService _authService;
  final SecurityService _securityService;
  final AuditService _auditService;

  VerificationService({
    required AuthService authService,
    required SecurityService securityService,
    required AuditService auditService,
  }) : _authService = authService,
       _securityService = securityService,
       _auditService = auditService;

  // Clés pour le stockage local
  static const String _verificationAttemptsKey = 'verification_attempts';
  static const String _lastVerificationTimeKey = 'last_verification_time';
  static const String _pendingCriticalActionsKey = 'pending_critical_actions';

  // Configuration
  static const int maxVerificationAttempts = 3;
  static const int verificationLockoutMinutes = 5;
  static const int criticalActionDelaySeconds = 10; // Délai de réflexion

  // Vérifier si une action critique nécessite une confirmation
  bool requiresVerification(String actionType) {
    const criticalActions = {
      'delete_user',
      'delete_agent',
      'delete_reservation',
      'mass_delete',
      'change_admin_status',
      'reset_password',
      'export_sensitive_data',
      'import_data',
      'modify_system_settings',
    };

    return criticalActions.contains(actionType);
  }

  // Demander une confirmation par mot de passe pour une action critique
  Future<bool> requestPasswordVerification(
    BuildContext context, {
    required String action,
    required String targetName,
    String? additionalMessage,
  }) async {
    // Vérifier si l'utilisateur est verrouillé
    if (await _isVerificationLockedOut()) {
      final remainingTime = await _getVerificationLockoutRemainingTime();
      _showLockoutMessage(context, remainingTime);
      return false;
    }

    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: AppTheme.warningColor),
            const SizedBox(width: 8),
            const Text('Vérification de sécurité'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vous êtes sur le point d\'effectuer une action critique :',
                  style: TextStyle(color: AppTheme.warningColor),
                ),
                const SizedBox(height: 8),
                Text(
                  action,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (targetName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Cible : $targetName'),
                ],
                if (additionalMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    additionalMessage,
                    style: TextStyle(color: AppTheme.warningColor),
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe administrateur',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(),
                    errorStyle: TextStyle(color: AppTheme.errorColor),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre mot de passe';
                    }
                    if (value.length < 6) {
                      return 'Mot de passe trop court';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Tentatives restantes : ${maxVerificationAttempts - await _getVerificationAttempts()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.mediumColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final isValid = await _verifyPassword(passwordController.text);
                if (isValid) {
                  await _resetVerificationAttempts();
                  Navigator.pop(context, true);
                } else {
                  await _incrementVerificationAttempts();
                  if (await _getVerificationAttempts() >= maxVerificationAttempts) {
                    await _lockoutVerification();
                    Navigator.pop(context, false);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Mot de passe incorrect'),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningColor,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    passwordController.dispose();
    return result ?? false;
  }

  // Demander une confirmation avec délai de réflexion
  Future<bool> requestDelayedConfirmation(
    BuildContext context, {
    required String action,
    required String targetName,
    int delaySeconds = criticalActionDelaySeconds,
    String? additionalMessage,
  }) async {
    int remainingSeconds = delaySeconds;
    bool isConfirmed = false;

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Démarrer le compte à rebours
          if (remainingSeconds > 0) {
            Future.delayed(const Duration(seconds: 1), () {
              if (remainingSeconds > 0 && mounted) {
                setState(() => remainingSeconds--);
              }
            });
          }

          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.timer, color: AppTheme.warningColor),
                const SizedBox(width: 8),
                const Text('Confirmation requise'),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Action critique :',
                    style: TextStyle(color: AppTheme.warningColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    action,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (targetName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Cible : $targetName'),
                  ],
                  if (additionalMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      additionalMessage,
                      style: TextStyle(color: AppTheme.warningColor),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (remainingSeconds > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Veuillez patienter avant de confirmer',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$remainingSeconds secondes',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.warningColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            'Cette action est irréversible',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.errorColor,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Êtes-vous absolument sûr ?',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: remainingSeconds > 0
                    ? null
                    : () {
                        setState(() => isConfirmed = true);
                        Navigator.pop(context, true);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                ),
                child: const Text('Confirmer l\'action'),
              ),
            ],
          );
        },
      ),
    ) ?? false;
  }

  // Demander une double confirmation (mot de passe + délai)
  Future<bool> requestDoubleVerification(
    BuildContext context, {
    required String action,
    required String targetName,
    String? additionalMessage,
    int delaySeconds = criticalActionDelaySeconds,
  }) async {
    // Première vérification : mot de passe
    final passwordVerified = await requestPasswordVerification(
      context,
      action: action,
      targetName: targetName,
      additionalMessage: additionalMessage,
    );

    if (!passwordVerified) return false;

    // Deuxième vérification : délai de réflexion
    return await requestDelayedConfirmation(
      context,
      action: action,
      targetName: targetName,
      additionalMessage: additionalMessage,
      delaySeconds: delaySeconds,
    );
  }

  // Vérifier le mot de passe
  Future<bool> _verifyPassword(String password) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return false;

      // Recréer les credentials pour vérifier le mot de passe
      final credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: password,
      );

      // Vérifier le mot de passe actuel
      await currentUser.reauthenticateWithCredential(credential);
      
      // Journaliser la vérification réussie
      await _auditService.logAdminAction(
        adminId: currentUser.uid,
        adminEmail: currentUser.email!,
        action: 'password_verification',
        targetType: 'system',
        targetId: 'security_check',
        description: 'Vérification par mot de passe réussie pour une action critique',
      );

      return true;
    } catch (e) {
      logger.w('Échec de la vérification du mot de passe: ${e.toString()}');
      return false;
    }
  }

  // Obtenir le nombre de tentatives de vérification
  Future<int> _getVerificationAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_verificationAttemptsKey) ?? 0;
  }

  // Incrémenter le nombre de tentatives
  Future<void> _incrementVerificationAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = await _getVerificationAttempts();
    await prefs.setInt(_verificationAttemptsKey, attempts + 1);
  }

  // Réinitialiser les tentatives
  Future<void> _resetVerificationAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_verificationAttemptsKey);
    await prefs.remove(_lastVerificationTimeKey);
  }

  // Vérifier si la vérification est verrouillée
  Future<bool> _isVerificationLockedOut() async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutTime = prefs.getString(_lastVerificationTimeKey);
    
    if (lockoutTime == null) return false;
    
    final lockoutDateTime = DateTime.parse(lockoutTime);
    final now = DateTime.now();
    
    return now.difference(lockoutDateTime).inMinutes < verificationLockoutMinutes;
  }

  // Verrouiller la vérification
  Future<void> _lockoutVerification() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastVerificationTimeKey, DateTime.now().toIso8601String());
  }

  // Obtenir le temps de verrouillage restant
  Future<int> _getVerificationLockoutRemainingTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutTime = prefs.getString(_lastVerificationTimeKey);
    
    if (lockoutTime == null) return 0;
    
    final lockoutDateTime = DateTime.parse(lockoutTime);
    final now = DateTime.now();
    final elapsed = now.difference(lockoutDateTime).inMinutes;
    
    return math.max(0, verificationLockoutMinutes - elapsed);
  }

  // Afficher le message de verrouillage
  void _showLockoutMessage(BuildContext context, int remainingMinutes) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Trop de tentatives échouées. Veuillez réessayer dans $remainingMinutes minute(s).',
        ),
        backgroundColor: AppTheme.errorColor,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // Journaliser une action critique vérifiée
  Future<void> logVerifiedAction({
    required String action,
    required String targetType,
    required String targetId,
    required String verificationMethod,
    String? description,
  }) async {
    try {
      final currentUser = await _authService.getCurrentUserData();
      if (currentUser == null) return;

      await _auditService.logAdminAction(
        adminId: currentUser.uid,
        adminEmail: currentUser.email,
        action: action,
        targetType: targetType,
        targetId: targetId,
        description: '${description ?? ""} (Vérifié par: $verificationMethod)',
      );
    } catch (e) {
      logger.e('Erreur lors de la journalisation de l\'action vérifiée: ${e.toString()}');
    }
  }

  // Vérifier si une action est en attente de confirmation
  Future<bool> isActionPending(String actionId) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingActions = prefs.getStringList(_pendingCriticalActionsKey) ?? [];
    return pendingActions.contains(actionId);
  }

  // Marquer une action comme en attente
  Future<void> markActionAsPending(String actionId) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingActions = prefs.getStringList(_pendingCriticalActionsKey) ?? [];
    
    if (!pendingActions.contains(actionId)) {
      pendingActions.add(actionId);
      await prefs.setStringList(_pendingCriticalActionsKey, pendingActions);
    }
  }

  // Marquer une action comme complétée
  Future<void> markActionAsCompleted(String actionId) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingActions = prefs.getStringList(_pendingCriticalActionsKey) ?? [];
    
    pendingActions.remove(actionId);
    await prefs.setStringList(_pendingCriticalActionsKey, pendingActions);
  }

  // Nettoyer les anciennes actions en attente
  Future<void> cleanupPendingActions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingCriticalActionsKey);
  }
}
