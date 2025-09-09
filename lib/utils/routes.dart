import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../widgets/user_navigation_wrapper.dart';

// Écrans utilisateur
import '../screens/splash_screen.dart';
import '../screens/user/enhanced_auth_screen.dart';
import '../screens/user/user_dashboard_screen.dart';
import '../screens/user/agents_list_screen.dart';
import '../screens/user/agent_detail_screen.dart';
import '../screens/user/reservation_screen.dart';
import '../screens/user/reservation_history_screen.dart';
import '../screens/user/user_profile_screen.dart';
import '../screens/user/recommendations_screen.dart';
import '../screens/user/user_settings_screen.dart';
import '../screens/user/password_reset_screen.dart';
import '../screens/user/password_change_screen.dart';
import '../screens/user/email_verification_screen.dart';
import '../screens/user/review_submission_screen.dart';

// Écrans administrateur
import '../screens/admin/agents_management_screen.dart';
import '../screens/admin/statistics_screen.dart';
import '../screens/admin/dashboard_screen.dart';
import '../screens/admin/enhanced_reservations_screen.dart';
import '../screens/admin/notification_management_screen.dart';
import '../screens/admin/report_generation_screen.dart';
import '../screens/admin/app_settings_screen.dart';
import '../screens/admin/reservation_detail_screen.dart';
import '../screens/admin/users_management_screen.dart';
import '../screens/admin/admin_profile_screen.dart';

// Nouveaux écrans admin RGPD et conformité
import '../screens/admin/enhanced_admin_dashboard_screen.dart';
import '../screens/admin/consent_management_screen.dart';
import '../screens/admin/data_deletion_management_screen.dart';
import '../screens/admin/localization_management_screen.dart';
import '../screens/admin/audit_logs_screen.dart';
import '../screens/admin/permissions_management_screen.dart';
import '../screens/admin/system_monitoring_screen.dart';

// Configuration des routes de l'application
class AppRouter {
  // Router avec redirection basée sur l'authentification
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      // Écran de démarrage
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Routes utilisateur
      GoRoute(
        path: '/auth',
        builder: (context, state) => const EnhancedAuthScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const PasswordResetScreen(),
      ),
      GoRoute(
        path: '/change-password',
        builder:
            (context, state) => const PasswordChangeScreen().withUserNavigation(
              currentIndex: 3, // Index du profil
              showBackButton: true,
              title: 'Modifier le mot de passe',
            ),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return EmailVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: '/dashboard',
        builder:
            (context, state) => const UserDashboardScreen().withUserNavigation(
              currentIndex: 0,
              title: 'Tableau de bord',
            ),
      ),
      GoRoute(
        path: '/agents',
        builder:
            (context, state) => const AgentsListScreen().withUserNavigation(
              currentIndex: 1,
              // Ne pas définir de titre ici car l'écran a déjà un AppBar avec un titre
            ),
      ),
      GoRoute(
        path: '/agent/:id',
        builder: (context, state) {
          final agentId = state.pathParameters['id']!;
          return AgentDetailScreen(agentId: agentId).withUserNavigation(
            currentIndex: 1,
            showBackButton: true,
            title: 'Détails de l\'agent',
          );
        },
      ),
      GoRoute(
        path: '/reservation/:agentId',
        builder: (context, state) {
          final agentId = state.pathParameters['agentId']!;
          return ReservationScreen(agentId: agentId).withUserNavigation(
            currentIndex: 1,
            showBackButton: true,
            title: 'Réservation',
          );
        },
      ),
      GoRoute(
        path: '/history',
        builder:
            (
              context,
              state,
            ) => const ReservationHistoryScreen().withUserNavigation(
              currentIndex: 2,
              // Ne pas définir de titre ici car l'écran a déjà un AppBar avec un titre
            ),
      ),
      GoRoute(
        path: '/profile',
        builder:
            (context, state) => const UserProfileScreen().withUserNavigation(
              currentIndex: 3,
              // Ne pas définir de titre ici car l'écran a déjà un AppBar avec un titre
            ),
      ),
      GoRoute(
        path: '/recommendations',
        builder:
            (context, state) =>
                const RecommendationsScreen().withUserNavigation(
                  currentIndex: 0,
                  showBackButton: true,
                  title: 'Recommandations',
                ),
      ),
      GoRoute(
        path: '/settings',
        builder:
            (context, state) => const UserSettingsScreen().withUserNavigation(
              currentIndex:
                  4, // Mettre à jour l'index pour correspondre à l'onglet Paramètres
              showBackButton:
                  false, // Pas besoin de bouton retour pour un onglet principal
              // Ne pas définir de titre ici car l'écran a déjà un AppBar avec un titre
            ),
      ),
      GoRoute(
        path: '/review/:reservationId',
        builder: (context, state) {
          final reservationId = state.pathParameters['reservationId']!;
          return ReviewSubmissionScreen(
            reservationId: reservationId,
          ).withUserNavigation(
            currentIndex: 2, // Correspond à l'onglet Historique
            showBackButton: true,
            title: 'Évaluer votre expérience',
          );
        },
      ),

      // Routes administrateur
      GoRoute(path: '/admin', redirect: (_, __) => '/admin/enhanced-dashboard'),
      
      // Tableau de bord principal (amélioré)
      GoRoute(
        path: '/admin/enhanced-dashboard',
        builder: (context, state) => const EnhancedAdminDashboardScreen(),
      ),
      
      // Ancien tableau de bord (pour compatibilité)
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      
      // Gestion des réservations
      GoRoute(
        path: '/admin/reservations',
        builder: (context, state) => const EnhancedReservationsScreen(),
      ),
      GoRoute(
        path: '/admin/reservation/:id',
        builder: (context, state) {
          final reservationId = state.pathParameters['id']!;
          return ReservationDetailScreen(reservationId: reservationId);
        },
      ),
      
      // Gestion des agents
      GoRoute(
        path: '/admin/agents',
        builder: (context, state) => const AgentsManagementScreen(),
      ),
      
      // Gestion des utilisateurs
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const UsersManagementScreen(),
      ),
      
      // Statistiques et rapports
      GoRoute(
        path: '/admin/statistics',
        builder: (context, state) => const StatisticsScreen(),
      ),
      GoRoute(
        path: '/admin/reports',
        builder: (context, state) => const ReportGenerationScreen(),
      ),
      
      // Notifications et communication
      GoRoute(
        path: '/admin/notifications',
        builder: (context, state) => const NotificationManagementScreen(),
      ),
      
      // RGPD et conformité
      GoRoute(
        path: '/admin/consents',
        builder: (context, state) => const ConsentManagementScreen(),
      ),
      GoRoute(
        path: '/admin/gdpr',
        builder: (context, state) => const DataDeletionManagementScreen(),
      ),
      
      // Internationalisation
      GoRoute(
        path: '/admin/localization',
        builder: (context, state) => const LocalizationManagementScreen(),
      ),
      
      // Sécurité et audit
      GoRoute(
        path: '/admin/audit',
        builder: (context, state) => const AuditLogsScreen(),
      ),
      GoRoute(
        path: '/admin/permissions',
        builder: (context, state) => const PermissionsManagementScreen(),
      ),
      
      // Surveillance système
      GoRoute(
        path: '/admin/monitoring',
        builder: (context, state) => const SystemMonitoringScreen(),
      ),
      
      // Paramètres et profil
      GoRoute(
        path: '/admin/settings',
        builder: (context, state) => const AppSettingsScreen(),
      ),
      GoRoute(
        path: '/admin/profile',
        builder: (context, state) => const AdminProfileScreen(),
      ),
    ],
    errorBuilder:
        (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Page non trouvée')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Oups! Cette page n\'existe pas.',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.go('/agents'),
                  child: const Text('Retour à l\'accueil'),
                ),
              ],
            ),
          ),
        ),
    redirect: (BuildContext context, GoRouterState state) async {
      // Récupérer l'utilisateur actuel
      final user = Provider.of<User?>(context, listen: false);

      // Routes publiques (accessibles sans connexion)
      final publicRoutes = [
        '/auth',
        '/splash',
        '/reset-password',
        '/verify-email',
      ];

      // Permettre l'accès à l'écran de démarrage sans redirection
      if (state.matchedLocation == '/splash') {
        return null;
      }

      // Si l'utilisateur n'est pas connecté et essaie d'accéder à une route protégée
      if (user == null) {
        // Si la route actuelle n'est pas une route publique, rediriger vers la page d'authentification
        if (!publicRoutes.contains(state.matchedLocation) &&
            !state.matchedLocation.startsWith('/auth')) {
          // Logger.info('Redirection: Utilisateur non connecté, redirection vers /auth');
          return '/auth';
        }
      } else {
        // L'utilisateur est connecté

        // Vérifier si l'utilisateur est réellement connecté (double vérification)
        final authService = Provider.of<AuthService>(context, listen: false);
        final isLoggedIn = await authService.isUserLoggedIn();

        // Si l'utilisateur n'est pas réellement connecté, rediriger vers la page d'authentification
        if (!isLoggedIn) {
          // Logger.info('Redirection: Token invalide, redirection vers /auth');
          return '/auth';
        }

        // Si l'utilisateur essaie d'accéder à la page d'authentification
        if (state.matchedLocation == '/auth') {
          // Vérifier si l'utilisateur est un administrateur
          final userData = await authService.getCurrentUserData();

          // Rediriger vers la page appropriée en fonction du statut d'administrateur
          if (userData != null && userData.isAdmin) {
            // Logger.info('Redirection: Admin connecté, redirection vers /admin/enhanced-dashboard');
            return '/admin/enhanced-dashboard';
          } else {
            // Logger.info('Redirection: Utilisateur connecté, redirection vers /dashboard');
            return '/dashboard';
          }
        }

        // Vérifier les routes administrateur
        if (state.matchedLocation.startsWith('/admin/')) {
          final userData = await authService.getCurrentUserData();

          // Rediriger vers la liste des agents si l'utilisateur n'est pas administrateur
          if (userData == null || !userData.isAdmin) {
            // Logger.info('Redirection: Non-admin essayant d\'accéder à une route admin, redirection vers /agents');
            return '/agents';
          }
        }
      }

      // Pas de redirection
      return null;
    },
  );
}
