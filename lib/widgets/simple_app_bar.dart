import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// Un AppBar simple et élégant qui peut être utilisé dans toute l'application.
/// 
/// Ce widget fournit un design cohérent pour les barres d'application dans
/// toutes les vues de l'application.
class SimpleAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Le titre à afficher dans l'AppBar.
  final String title;
  
  /// L'icône à afficher à côté du titre.
  final IconData icon;
  
  /// Les actions à afficher à droite de l'AppBar.
  final List<Widget>? actions;
  
  /// Indique si un bouton de retour doit être affiché.
  final bool showBackButton;
  
  /// Fonction appelée lorsque le bouton de retour est pressé.
  final VoidCallback? onBackPressed;
  
  /// Hauteur de l'AppBar.
  final double height;
  
  /// Couleur de fond de l'AppBar.
  final Color? backgroundColor;
  
  /// Couleur de l'icône et du texte.
  final Color? foregroundColor;
  
  /// Constructeur pour SimpleAppBar.
  const SimpleAppBar({
    super.key,
    required this.title,
    this.icon = Icons.dashboard_rounded,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
    this.height = kToolbarHeight,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: backgroundColor ?? Colors.white,
      foregroundColor: foregroundColor ?? Colors.black,
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Colors.grey[700],
                size: 22,
              ),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : null,
      title: Row(
        children: [
          // Icône de la page
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Titre de la page
          Text(
            title,
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ],
      ),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.grey[200],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}

/// Version SliverAppBar du SimpleAppBar pour une utilisation dans CustomScrollView.
class SimpleSliverAppBar extends StatelessWidget {
  /// Le titre à afficher dans l'AppBar.
  final String title;
  
  /// L'icône à afficher à côté du titre.
  final IconData icon;
  
  /// Les actions à afficher à droite de l'AppBar.
  final List<Widget>? actions;
  
  /// Indique si l'AppBar doit être épinglé lors du défilement.
  final bool pinned;
  
  /// Indique si l'AppBar doit flotter lors du défilement.
  final bool floating;
  
  /// Couleur de fond de l'AppBar.
  final Color? backgroundColor;
  
  /// Couleur de l'icône et du texte.
  final Color? foregroundColor;
  
  /// Constructeur pour SimpleSliverAppBar.
  const SimpleSliverAppBar({
    super.key,
    required this.title,
    this.icon = Icons.dashboard_rounded,
    this.actions,
    this.pinned = true,
    this.floating = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: floating,
      pinned: pinned,
      elevation: 0,
      backgroundColor: backgroundColor ?? Colors.white,
      foregroundColor: foregroundColor ?? Colors.black,
      title: Row(
        children: [
          // Icône de la page
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Titre de la page
          Text(
            title,
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ],
      ),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.grey[200],
        ),
      ),
    );
  }
}
