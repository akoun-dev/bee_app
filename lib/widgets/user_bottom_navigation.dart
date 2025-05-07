import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme.dart';

// Widget de navigation inférieure pour les utilisateurs
class UserBottomNavigation extends StatelessWidget {
  final int currentIndex;

  const UserBottomNavigation({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.mediumColor,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 12,
        ),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.security_outlined),
            activeIcon: Icon(Icons.security),
            label: 'Agents',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Historique',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Paramètres',
          ),
        ],
        onTap: (index) => _onItemTapped(context, index),
      ),
    );
  }

  // Gérer la navigation
  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    // Stocker la route à naviguer
    String route;
    switch (index) {
      case 0:
        route = '/dashboard';
        break;
      case 1:
        route = '/agents';
        break;
      case 2:
        route = '/history';
        break;
      case 3:
        route = '/profile';
        break;
      case 4:
        route = '/settings';
        break;
      default:
        return;
    }

    // Utiliser Future.microtask pour éviter les problèmes de navigation pendant le build
    Future.microtask(() {
      // Utiliser context.go() au lieu de context.push() pour éviter d'empiler les routes
      // et permettre le retour arrière correct
      context.go(route);
    });
  }
}

// Wrapper pour ajouter la navigation inférieure à un écran
class UserBottomNavigationScaffold extends StatelessWidget {
  final int currentIndex;
  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? drawer;

  const UserBottomNavigationScaffold({
    super.key,
    required this.currentIndex,
    required this.body,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.drawer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title != null
          ? AppBar(
              title: Text(title!),
              actions: actions,
            )
          : null,
      drawer: drawer,
      body: body,
      bottomNavigationBar: UserBottomNavigation(
        currentIndex: currentIndex,
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}
