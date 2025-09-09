import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/report_service.dart';
import 'services/settings_service.dart';
import 'services/theme_service.dart';
import 'services/recommendation_service.dart';
import 'services/agent_availability_service.dart';
import 'services/audit_service.dart';
import 'services/consent_service.dart';
import 'services/data_deletion_service.dart';
import 'services/localization_service.dart';
import 'services/authorization_service.dart';
import 'services/security_service.dart';
import 'services/verification_service.dart';
import 'services/permission_service.dart';
import 'utils/routes.dart';
import 'utils/constants.dart';

void main() async {
  // Assurer que les widgets Flutter sont initialisés
  WidgetsFlutterBinding.ensureInitialized();

  // Définir l'orientation de l'application (portrait uniquement)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialiser Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Lancer l'application
  runApp(const BeeApp());
}

class BeeApp extends StatefulWidget {
  const BeeApp({super.key});

  @override
  State<BeeApp> createState() => _BeeAppState();
}

class _BeeAppState extends State<BeeApp> {
  // Services de base
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();
  final ReportService _reportService = ReportService();
  final SettingsService _settingsService = SettingsService();
  final ThemeService _themeService = ThemeService();
  final RecommendationService _recommendationService = RecommendationService();
  
  // Instance de Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Services avec dépendances
  late final DatabaseService _databaseService;
  late final AgentAvailabilityService _availabilityService;
  late final AuditService _auditService;
  late final ConsentService _consentService;
  late final DataDeletionService _dataDeletionService;
  late final LocalizationService _localizationService;
  late final AuthorizationService _authorizationService;
  late final SecurityService _securityService;
  late final VerificationService _verificationService;

  @override
  void initState() {
    super.initState();
    
    // Initialiser les services avec dépendances
    // D'abord créer le DatabaseService avec un AgentAvailabilityService temporaire
    _databaseService = DatabaseService.withoutAvailability();
    
    // Puis créer l'AgentAvailabilityService avec le DatabaseService
    _availabilityService = AgentAvailabilityService(
      _databaseService,
      _firestore,
    );
    
    // Mettre à jour le DatabaseService avec le bon AgentAvailabilityService
    _databaseService = DatabaseService(_availabilityService);
    
    // Initialiser les autres services
    _auditService = AuditService();
    _authorizationService = AuthorizationService(
      authService: _authService,
      permissionService: PermissionService(), // Créer une instance
      securityService: SecurityService(), // Créer une instance
      auditService: _auditService,
    );
    _securityService = SecurityService();
    _verificationService = VerificationService(
      authService: _authService,
      securityService: _securityService,
      auditService: _auditService,
    );
    _consentService = ConsentService(
      firestore: _firestore,
      authService: _authService,
      auditService: _auditService,
    );
    _dataDeletionService = DataDeletionService(
      firestore: _firestore,
      authService: _authService,
      auditService: _auditService,
      consentService: _consentService,
      databaseService: _databaseService,
    );
    _localizationService = LocalizationService(
      authService: _authService,
      databaseService: _databaseService,
      auditService: _auditService,
    );
    
    // Initialiser les services
    _initializeServices();
    
    // Démarrer les timers et services en arrière-plan
    _startBackgroundServices();
  }

  // Initialiser tous les services
  Future<void> _initializeServices() async {
    try {
      // Initialiser les notifications
      await _notificationService.initialize();

      // Initialiser le service de thème
      await _themeService.initialize();

      // Initialiser le service de sécurité
      await _securityService.initialize();

      // Initialiser le service de localisation
      await _localizationService.initialize();

      // Effectuer une première mise à jour de la disponibilité des agents
      try {
        await _availabilityService.updateAgentsAvailability();
        debugPrint('Mise à jour initiale de la disponibilité des agents effectuée');
      } catch (e) {
        debugPrint('Erreur lors de la mise à jour initiale de la disponibilité: $e');
      }

      // Vérifier les demandes de suppression en attente
      try {
        await _dataDeletionService.processPendingDeletionRequests();
        debugPrint('Vérification des demandes de suppression en attente effectuée');
      } catch (e) {
        debugPrint('Erreur lors de la vérification des demandes de suppression: $e');
      }

      debugPrint('Tous les services ont été initialisés avec succès');
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation des services: $e');
    }
  }

  // Démarrer les services en arrière-plan
  void _startBackgroundServices() {
    // Démarrer le timer de mise à jour de la disponibilité
    _availabilityService.startAvailabilityTimer();

    // Démarrer le timer de vérification des demandes de suppression (toutes les heures)
    _startDeletionRequestTimer();

    // Démarrer le timer de nettoyage des données expirées (tous les jours)
    _startDataCleanupTimer();

    debugPrint('Services en arrière-plan démarrés');
  }

  // Timer pour vérifier les demandes de suppression
  void _startDeletionRequestTimer() {
    // Vérifier toutes les heures
    Future.delayed(const Duration(hours: 1), () async {
      if (mounted) {
        try {
          await _dataDeletionService.processPendingDeletionRequests();
          _startDeletionRequestTimer(); // Relancer le timer
        } catch (e) {
          debugPrint('Erreur lors de la vérification des demandes de suppression: $e');
          _startDeletionRequestTimer(); // Relancer même en cas d'erreur
        }
      }
    });
  }

  // Timer pour le nettoyage des données expirées
  void _startDataCleanupTimer() {
    // Nettoyer tous les jours à minuit
    Future.delayed(const Duration(days: 1), () async {
      if (mounted) {
        try {
          await _performDataCleanup();
          _startDataCleanupTimer(); // Relancer le timer
        } catch (e) {
          debugPrint('Erreur lors du nettoyage des données: $e');
          _startDataCleanupTimer(); // Relancer même en cas d'erreur
        }
      }
    });
  }

  // Nettoyer les données expirées
  Future<void> _performDataCleanup() async {
    try {
      // Nettoyer les logs d'audit anciens (plus de 2 ans)
      final twoYearsAgo = DateTime.now().subtract(const Duration(days: 730));
      final oldAuditLogs = await _firestore
          .collection('audit_logs')
          .where('timestamp', isLessThan: twoYearsAgo)
          .limit(1000)
          .get();

      for (final doc in oldAuditLogs.docs) {
        await doc.reference.delete();
      }

      // Nettoyer les notifications anciennes (plus de 6 mois)
      final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
      final oldNotifications = await _firestore
          .collection('notifications')
          .where('createdAt', isLessThan: sixMonthsAgo)
          .limit(1000)
          .get();

      for (final doc in oldNotifications.docs) {
        await doc.reference.delete();
      }

      debugPrint('Nettoyage des données expirées terminé');
    } catch (e) {
      debugPrint('Erreur lors du nettoyage des données: $e');
    }
  }

  @override
  void dispose() {
    // Arrêter les timers et services en arrière-plan
    _availabilityService.stopAvailabilityTimer();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fournir les services à l'application via Provider
    return MultiProvider(
      providers: [
        // Services d'authentification et base de données
        Provider<AuthService>.value(value: _authService),
        Provider<DatabaseService>.value(value: _databaseService),
        Provider<StorageService>.value(value: _storageService),
        
        // Services de notification et reporting
        Provider<NotificationService>.value(value: _notificationService),
        Provider<ReportService>.value(value: _reportService),
        
        // Services de configuration et thème
        Provider<SettingsService>.value(value: _settingsService),
        ChangeNotifierProvider<ThemeService>.value(value: _themeService),
        
        // Services de recommandation et disponibilité
        Provider<RecommendationService>.value(value: _recommendationService),
        Provider<AgentAvailabilityService>.value(value: _availabilityService),
        
        // Services de sécurité et audit
        Provider<AuditService>.value(value: _auditService),
        Provider<AuthorizationService>.value(value: _authorizationService),
        Provider<SecurityService>.value(value: _securityService),
        Provider<VerificationService>.value(value: _verificationService),
        
        // Services RGPD et conformité
        Provider<ConsentService>.value(value: _consentService),
        Provider<DataDeletionService>.value(value: _dataDeletionService),
        
        // Service d'internationalisation
        Provider<LocalizationService>.value(value: _localizationService),
        
        // Écouter les changements d'état d'authentification
        StreamProvider(
          create: (_) => _authService.authStateChanges,
          initialData: null,
        ),
      ],
      child: Consumer2<ThemeService, LocalizationService>(
        builder: (context, themeService, localizationService, _) {
          return MaterialApp.router(
            title: AppConstants.appName,
            theme: themeService.lightTheme,
            darkTheme: themeService.darkTheme,
            themeMode: themeService.themeMode,
            debugShowCheckedModeBanner: false,
            routerConfig: AppRouter.router,
            locale: localizationService.getCurrentLanguage().flutterLocale,
            supportedLocales: localizationService.getSupportedLanguages()
                .map((lang) => lang.flutterLocale)
                .toSet(),
            localizationsDelegates: const [
              // Ajouter ici les délégués de localisation si vous utilisez un package comme easy_localization
            ],
            builder: (context, child) {
              // Appliquer le facteur d'échelle du texte
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(themeService.textScaleFactor),
                ),
                child: Directionality(
                  textDirection: localizationService.isCurrentLanguageRTL() 
                    ? TextDirection.rtl 
                    : TextDirection.ltr,
                  child: child!,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
