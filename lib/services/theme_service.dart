import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/theme.dart';

// Service pour gérer les thèmes et les préférences d'interface
class ThemeService extends ChangeNotifier {
  // Clés pour SharedPreferences
  static const String _themeKey = 'theme_mode';
  static const String _accentColorKey = 'accent_color';
  static const String _cardStyleKey = 'card_style';
  static const String _fontFamilyKey = 'font_family';
  static const String _textSizeKey = 'text_size';
  static const String _highContrastKey = 'high_contrast';
  static const String _reducedMotionKey = 'reduced_motion';

  // Valeurs par défaut
  ThemeMode _themeMode = ThemeMode.system;
  Color _accentColor = AppTheme.primaryColor; // Jaune par défaut
  String _cardStyle = 'default';
  String _fontFamily = 'default';
  double _textScaleFactor = 1.0;
  bool _highContrast = false;
  bool _reducedMotion = false;

  // Getters
  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  String get cardStyle => _cardStyle;
  String get fontFamily => _fontFamily;
  double get textScaleFactor => _textScaleFactor;
  bool get highContrast => _highContrast;
  bool get reducedMotion => _reducedMotion;

  // Thèmes
  ThemeData get lightTheme => _highContrast
      ? _createHighContrastLightTheme()
      : AppTheme.lightTheme;

  ThemeData get darkTheme => _highContrast
      ? _createHighContrastDarkTheme()
      : AppTheme.darkTheme;

  // Initialiser le service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // Charger le thème
    final themeModeString = prefs.getString(_themeKey);
    if (themeModeString != null) {
      _themeMode = _parseThemeMode(themeModeString);
    }

    // Charger la couleur d'accent
    final accentColorString = prefs.getString(_accentColorKey);
    if (accentColorString != null) {
      _accentColor = _parseAccentColor(accentColorString);
    }

    // Charger le style de carte
    final cardStyle = prefs.getString(_cardStyleKey);
    if (cardStyle != null) {
      _cardStyle = cardStyle;
    }

    // Charger la police
    final fontFamily = prefs.getString(_fontFamilyKey);
    if (fontFamily != null) {
      _fontFamily = fontFamily;
    }

    // Charger la taille du texte
    final textSize = prefs.getString(_textSizeKey);
    if (textSize != null) {
      _textScaleFactor = _parseTextSize(textSize);
    }

    // Charger le contraste élevé
    _highContrast = prefs.getBool(_highContrastKey) ?? false;

    // Charger la réduction des animations
    _reducedMotion = prefs.getBool(_reducedMotionKey) ?? false;

    // Appliquer les paramètres système
    _applySystemSettings();

    notifyListeners();
  }

  // Appliquer les paramètres système
  void _applySystemSettings() {
    // Définir la couleur de la barre d'état
    final isDark = _themeMode == ThemeMode.dark ||
                  (_themeMode == ThemeMode.system &&
                   WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);

    SystemChrome.setSystemUIOverlayStyle(
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );
  }

  // Changer le thème
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _themeModeToString(mode));

    _applySystemSettings();
    notifyListeners();
  }

  // Changer la couleur d'accent
  Future<void> setAccentColor(String colorName) async {
    _accentColor = _parseAccentColor(colorName);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accentColorKey, colorName);

    notifyListeners();
  }

  // Changer le style des cartes
  Future<void> setCardStyle(String style) async {
    _cardStyle = style;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cardStyleKey, style);

    notifyListeners();
  }

  // Changer la police
  Future<void> setFontFamily(String font) async {
    _fontFamily = font;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontFamilyKey, font);

    notifyListeners();
  }

  // Changer la taille du texte
  Future<void> setTextSize(String size) async {
    _textScaleFactor = _parseTextSize(size);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_textSizeKey, size);

    notifyListeners();
  }

  // Activer/désactiver le contraste élevé
  Future<void> setHighContrast(bool enabled) async {
    _highContrast = enabled;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highContrastKey, enabled);

    notifyListeners();
  }

  // Activer/désactiver la réduction des animations
  Future<void> setReducedMotion(bool enabled) async {
    _reducedMotion = enabled;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reducedMotionKey, enabled);

    notifyListeners();
  }

  // Convertir le nom de couleur en Color
  Color _parseAccentColor(String colorName) {
    switch (colorName) {
      case 'yellow':
        return const Color(0xFFFFC107); // Jaune
      case 'blue':
        return const Color(0xFF2196F3); // Bleu
      case 'green':
        return const Color(0xFF4CAF50); // Vert
      case 'purple':
        return const Color(0xFF9C27B0); // Violet
      case 'orange':
        return const Color(0xFFFF9800); // Orange
      default:
        return const Color(0xFFFFC107); // Jaune par défaut
    }
  }

  // Convertir ThemeMode en chaîne
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }

  // Convertir chaîne en ThemeMode
  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  // Convertir chaîne en facteur d'échelle de texte
  double _parseTextSize(String size) {
    switch (size) {
      case 'small':
        return 0.85;
      case 'large':
        return 1.15;
      case 'extra_large':
        return 1.3;
      case 'medium':
      default:
        return 1.0;
    }
  }

  // Créer un thème clair à contraste élevé
  ThemeData _createHighContrastLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Colors.black,
        onPrimary: Colors.white,
        secondary: Colors.black,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
        error: Colors.red,
        onError: Colors.white,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black),
        bodyMedium: TextStyle(color: Colors.black),
        bodySmall: TextStyle(color: Colors.black),
        titleLarge: TextStyle(color: Colors.black),
        titleMedium: TextStyle(color: Colors.black),
        titleSmall: TextStyle(color: Colors.black),
      ),
      dividerColor: Colors.black,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: const BorderSide(color: Colors.black, width: 2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.black,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 3),
        ),
      ),
    );
  }

  // Créer un thème sombre à contraste élevé
  ThemeData _createHighContrastDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Colors.yellow,
        onPrimary: Colors.black,
        secondary: Colors.yellow,
        onSecondary: Colors.black,
        surface: Colors.black,
        onSurface: Colors.yellow,
        error: Colors.red,
        onError: Colors.white,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.yellow),
        bodyMedium: TextStyle(color: Colors.yellow),
        bodySmall: TextStyle(color: Colors.yellow),
        titleLarge: TextStyle(color: Colors.yellow),
        titleMedium: TextStyle(color: Colors.yellow),
        titleSmall: TextStyle(color: Colors.yellow),
      ),
      dividerColor: Colors.yellow,
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.black,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.yellow,
          foregroundColor: Colors.black,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.yellow,
          side: const BorderSide(color: Colors.yellow, width: 2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.yellow,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.yellow, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.yellow, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.yellow, width: 3),
        ),
      ),
    );
  }
}
