import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/report_service.dart';
import 'services/settings_service.dart';
import 'services/theme_service.dart';
import 'services/recommendation_service.dart';
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
  // Services
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();
  final ReportService _reportService = ReportService();
  final SettingsService _settingsService = SettingsService();
  final ThemeService _themeService = ThemeService();
  final RecommendationService _recommendationService = RecommendationService();

  @override
  void initState() {
    super.initState();
    // Initialiser les notifications
    _initializeNotifications();
  }

  // Initialiser les services
  Future<void> _initializeNotifications() async {
    // Initialiser les notifications
    await _notificationService.initialize();

    // Initialiser le service de thème
    await _themeService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    // Fournir les services à l'application via Provider
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: _authService),
        Provider<DatabaseService>.value(value: _databaseService),
        Provider<StorageService>.value(value: _storageService),
        Provider<NotificationService>.value(value: _notificationService),
        Provider<ReportService>.value(value: _reportService),
        Provider<SettingsService>.value(value: _settingsService),
        ChangeNotifierProvider<ThemeService>.value(value: _themeService),
        Provider<RecommendationService>.value(value: _recommendationService),
        // Écouter les changements d'état d'authentification
        StreamProvider(
          create: (_) => _authService.authStateChanges,
          initialData: null,
        ),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) {
          return MaterialApp.router(
            title: AppConstants.appName,
            theme: themeService.lightTheme,
            darkTheme: themeService.darkTheme,
            themeMode: themeService.themeMode,
            debugShowCheckedModeBanner: false,
            routerConfig: AppRouter.router,
            builder: (context, child) {
              // Appliquer le facteur d'échelle du texte
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(themeService.textScaleFactor),
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
