import 'package:flutter/material.dart';
import 'user_bottom_navigation.dart';

// Wrapper pour ajouter la navigation utilisateur à toutes les pages
// Ce wrapper permet de maintenir la barre de navigation inférieure
// tout en permettant la navigation entre les pages
class UserNavigationWrapper extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final bool showBackButton;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;

  const UserNavigationWrapper({
    super.key,
    required this.child,
    required this.currentIndex,
    this.showBackButton = false,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.appBar,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // Vérifier si l'enfant est déjà un Scaffold
    if (child is Scaffold) {
      final scaffoldChild = child as Scaffold;
      return Scaffold(
        // Ne pas ajouter d'AppBar si l'enfant en a déjà un
        appBar: scaffoldChild.appBar,
        body: scaffoldChild.body,
        backgroundColor: backgroundColor ?? scaffoldChild.backgroundColor,
        bottomNavigationBar: UserBottomNavigation(
          currentIndex: currentIndex,
        ),
        floatingActionButton: floatingActionButton ?? scaffoldChild.floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation ?? scaffoldChild.floatingActionButtonLocation,
      );
    } else {
      // Si l'enfant n'est pas un Scaffold, utiliser l'AppBar fourni
      return Scaffold(
        appBar: appBar ?? (title != null
            ? AppBar(
                title: Text(title!),
                leading: showBackButton
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                      )
                    : null,
                actions: actions,
              )
            : null),
        body: child,
        backgroundColor: backgroundColor,
        bottomNavigationBar: UserBottomNavigation(
          currentIndex: currentIndex,
        ),
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
      );
    }
  }
}

// Extension pour faciliter l'utilisation du wrapper
extension UserNavigationExtension on Widget {
  Widget withUserNavigation({
    required int currentIndex,
    bool showBackButton = false,
    String? title,
    List<Widget>? actions,
    Widget? floatingActionButton,
    FloatingActionButtonLocation? floatingActionButtonLocation,
    PreferredSizeWidget? appBar,
    Color? backgroundColor,
  }) {
    return UserNavigationWrapper(
      currentIndex: currentIndex,
      showBackButton: showBackButton,
      title: title,
      actions: actions,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      appBar: appBar,
      backgroundColor: backgroundColor,
      child: this,
    );
  }
}
