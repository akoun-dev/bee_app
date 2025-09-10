import 'package:flutter/material.dart';

// Thème de l'application
class AppTheme {
  // Couleurs principales - Jaune, Noir et Blanc
  static const Color primaryColor = Color(0xFFFFC107); // Jaune vif
  static const Color secondaryColor = Color(0xFF000000); // Noir
  static const Color accentColor = Color(0xFFFFD740); // Jaune accent
  static const Color errorColor = Color(
    0xFFE53935,
  ); // Rouge (conservé pour les erreurs)
  static const Color successColor = Color(0xFF4CAF50); // Vert (pour les succès)
  static const Color warningColor = Color(
    0xFFFF9800,
  ); // Orange (pour les avertissements)
  static const Color infoColor = Color(
    0xFF2196F3,
  ); // Bleu (pour les informations)

  // Couleurs neutres
  static const Color darkColor = Color(0xFF000000); // Noir
  static const Color mediumColor = Color(0xFF424242); // Gris foncé
  static const Color lightColor = Color(0xFFE0E0E0); // Gris clair
  static const Color backgroundColor = Color(0xFFFFFFFF); // Blanc

  // Thème clair
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    // Schéma de couleurs - Jaune, Noir et Blanc
    colorScheme: ColorScheme.light(
      primary: primaryColor, // Jaune
      secondary: secondaryColor, // Noir
      tertiary: accentColor, // Jaune accent
      error: errorColor, // Rouge pour les erreurs
      // Utilisation de surface au lieu de background (déprécié)
      surface: backgroundColor, // Blanc
      surfaceTint: Colors.white, // Blanc
      onPrimary: secondaryColor, // Texte noir sur fond jaune
      onSecondary: Colors.white, // Texte blanc sur fond noir
      onTertiary: secondaryColor, // Texte noir sur jaune accent
      onError: Colors.white, // Texte blanc sur fond rouge
      // Utilisation de onSurface au lieu de onBackground (déprécié)
      onSurface: secondaryColor, // Texte noir sur surface blanche
      brightness: Brightness.light,
    ),

    // AppBar - Design professionnel noir avec texte blanc
    appBarTheme: const AppBarTheme(
      backgroundColor: secondaryColor, // Noir pour un look professionnel
      foregroundColor: Colors.white, // Texte blanc pour contraste
      elevation: 2, // Légère élévation pour un effet professionnel
      centerTitle: true,
      shadowColor: Color(0x29000000), // Ombre subtile
    ),

    // Boutons - Jaune avec texte noir pour un contraste optimal
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor, // Jaune
        foregroundColor: secondaryColor, // Texte noir
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            6,
          ), // Coins moins arrondis pour un look professionnel
        ),
        elevation: 1, // Légère élévation
        shadowColor: Color(0x29000000), // Ombre subtile
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: secondaryColor, // Texte noir
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w500, // Semi-bold pour meilleure lisibilité
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: secondaryColor, // Texte noir
        side: const BorderSide(
          color: primaryColor,
          width: 1.5,
        ), // Bordure jaune plus visible
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            6,
          ), // Coins moins arrondis pour un look professionnel
        ),
      ),
    ),

    // Champs de texte - Design épuré avec bordures noires et focus jaune
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          6,
        ), // Coins moins arrondis pour un look professionnel
        borderSide: const BorderSide(color: mediumColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: mediumColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(
          color: primaryColor,
          width: 2,
        ), // Bordure jaune en focus
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(
        color: mediumColor,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: const TextStyle(
        color: secondaryColor,
        fontWeight: FontWeight.w600,
      ),
      // Ombre subtile pour les champs de texte
      isDense: true,
    ),

    // Cartes - Design élégant avec bordure fine et ombre subtile
    cardTheme: const CardTheme(
      color: Colors.white,
      elevation: 1, // Élévation subtile
      shadowColor: Color(0x29000000), // Ombre légère
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        side: BorderSide(
          color: Color(0xFFE0E0E0),
          width: 0.5,
        ), // Bordure très fine
      ),
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),

    // Typographie - Style moderne et professionnel
    fontFamily: 'Poppins',
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: secondaryColor, // Noir
        letterSpacing: -0.5, // Espacement négatif pour un look moderne
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: secondaryColor,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: secondaryColor,
        letterSpacing: -0.25,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: secondaryColor,
        letterSpacing: -0.25,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: secondaryColor,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: mediumColor, // Gris foncé pour le texte courant
        height: 1.5, // Hauteur de ligne pour une meilleure lisibilité
      ),
      bodyMedium: TextStyle(fontSize: 14, color: mediumColor, height: 1.5),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
        letterSpacing: 0.25, // Léger espacement pour les étiquettes
      ),
    ),

    // Divers
    scaffoldBackgroundColor: backgroundColor, // Fond blanc
    dividerTheme: const DividerThemeData(
      color: Color(0xFFEEEEEE), // Gris très clair pour les séparateurs
      thickness: 1,
      space: 32,
    ),
    // Éléments d'interface - Utilisation du jaune et noir pour les contrôles
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor; // Jaune quand sélectionné
        }
        return Colors.white;
      }),
      checkColor: WidgetStateProperty.all(secondaryColor), // Coche noire
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3), // Coins légèrement arrondis
      ),
      side: const BorderSide(color: mediumColor, width: 1.5),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor; // Jaune quand sélectionné
        }
        return mediumColor;
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor; // Jaune quand activé
        }
        return Colors.white;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor.withAlpha(128); // Jaune semi-transparent
        }
        return mediumColor.withAlpha(128); // Gris semi-transparent
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
  );

  // Thème sombre
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    // Schéma de couleurs - Jaune, Noir et Blanc inversés
    colorScheme: ColorScheme.dark(
      primary: primaryColor, // Jaune
      secondary: Colors.white, // Blanc
      tertiary: accentColor, // Jaune accent
      error: errorColor, // Rouge pour les erreurs
      surface: secondaryColor, // Noir
      surfaceTint: secondaryColor, // Noir
      onPrimary: secondaryColor, // Texte noir sur fond jaune
      onSecondary: secondaryColor, // Texte noir sur fond blanc
      onTertiary: secondaryColor, // Texte noir sur jaune accent
      onError: Colors.white, // Texte blanc sur fond rouge
      onSurface: Colors.white, // Texte blanc sur surface noire
      brightness: Brightness.dark,
    ),

    // AppBar - Design professionnel jaune avec texte noir
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor, // Jaune pour un look distinctif
      foregroundColor: secondaryColor, // Texte noir pour contraste
      elevation: 2, // Légère élévation pour un effet professionnel
      centerTitle: true,
      shadowColor: Color(0x29000000), // Ombre subtile
    ),

    // Boutons - Jaune avec texte noir pour un contraste optimal
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor, // Jaune
        foregroundColor: secondaryColor, // Texte noir
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            6,
          ), // Coins moins arrondis pour un look professionnel
        ),
        elevation: 1, // Légère élévation
        shadowColor: Color(0x29000000), // Ombre subtile
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor, // Texte jaune
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w500, // Semi-bold pour meilleure lisibilité
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor, // Texte jaune
        side: const BorderSide(
          color: primaryColor,
          width: 1.5,
        ), // Bordure jaune plus visible
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            6,
          ), // Coins moins arrondis pour un look professionnel
        ),
      ),
    ),

    // Champs de texte - Design épuré avec bordures jaunes
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF121212), // Gris très foncé
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          6,
        ), // Coins moins arrondis pour un look professionnel
        borderSide: const BorderSide(color: mediumColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: mediumColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(
          color: primaryColor,
          width: 2,
        ), // Bordure jaune en focus
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(
        color: lightColor,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: const TextStyle(
        color: primaryColor,
        fontWeight: FontWeight.w600,
      ),
      isDense: true,
    ),

    // Cartes - Design élégant avec bordure fine et ombre subtile
    cardTheme: const CardTheme(
      color: Color(0xFF1E1E1E), // Gris foncé
      elevation: 1, // Élévation subtile
      shadowColor: Color(0x29000000), // Ombre légère
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        side: BorderSide(
          color: Color(0xFF2C2C2C),
          width: 0.5,
        ), // Bordure très fine
      ),
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),

    // Typographie - Style moderne et professionnel
    fontFamily: 'Poppins',
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white, // Blanc
        letterSpacing: -0.5, // Espacement négatif pour un look moderne
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: -0.25,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: -0.25,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: lightColor, // Gris clair pour le texte courant
        height: 1.5, // Hauteur de ligne pour une meilleure lisibilité
      ),
      bodyMedium: TextStyle(fontSize: 14, color: lightColor, height: 1.5),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: primaryColor, // Jaune pour les étiquettes
        letterSpacing: 0.25, // Léger espacement pour les étiquettes
      ),
    ),

    // Divers
    scaffoldBackgroundColor: Color(0xFF121212), // Fond noir
    dividerTheme: const DividerThemeData(
      color: Color(0xFF2C2C2C), // Gris foncé pour les séparateurs
      thickness: 1,
      space: 32,
    ),
    // Éléments d'interface - Utilisation du jaune et noir pour les contrôles
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor; // Jaune quand sélectionné
        }
        return Color(0xFF2C2C2C);
      }),
      checkColor: WidgetStateProperty.all(secondaryColor), // Coche noire
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3), // Coins légèrement arrondis
      ),
      side: const BorderSide(color: lightColor, width: 1.5),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor; // Jaune quand sélectionné
        }
        return lightColor;
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor; // Jaune quand activé
        }
        return Colors.white;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor.withAlpha(128); // Jaune semi-transparent
        }
        return lightColor.withAlpha(128); // Gris semi-transparent
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
  );
}
