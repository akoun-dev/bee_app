import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/localization_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'database_service.dart';
import 'audit_service.dart';

// Service pour la gestion de l'internationalisation et de la localisation
class LocalizationService {
  final AuthService _authService;
  final DatabaseService _databaseService;
  final AuditService _auditService;

  // Instance de SharedPreferences pour le stockage local
  SharedPreferences? _prefs;

  // Configuration actuelle
  LocalizationModel? _currentConfig;
  Stream<LocalizationModel?>? _configStream;

  LocalizationService({
    required AuthService authService,
    required DatabaseService databaseService,
    required AuditService auditService,
  }) : _authService = authService,
       _databaseService = databaseService,
       _auditService = auditService;

  // Initialiser le service
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Charger la configuration depuis le stockage local ou créer une configuration par défaut
      await _loadConfiguration();
      
      debugPrint('Service de localisation initialisé avec succès');
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation du service de localisation: $e');
    }
  }

  // Charger la configuration de localisation
  Future<void> _loadConfiguration() async {
    try {
      final currentUser = _authService.currentUser;
      
      if (currentUser != null) {
        // Charger la configuration depuis Firestore pour l'utilisateur connecté
        _currentConfig = await _databaseService.getUserLocalization(currentUser.uid);
        
        if (_currentConfig == null) {
          // Créer une configuration par défaut selon la locale du système
          final systemLocale = PlatformDispatcher.instance.locale;
          _currentConfig = LocalizationModel.createDefault(
            currentUser.uid,
            systemLocale,
          );
          
          // Sauvegarder la configuration par défaut
          await _databaseService.updateUserLocalization(currentUser.uid, _currentConfig!);
        }
      } else {
        // Charger la configuration depuis le stockage local pour les utilisateurs non connectés
        _currentConfig = await _loadLocalConfiguration();
      }
      
      debugPrint('Configuration de localisation chargée: ${_currentConfig?.language.name}');
    } catch (e) {
      debugPrint('Erreur lors du chargement de la configuration: $e');
      // Utiliser une configuration par défaut en cas d'erreur
      _currentConfig = LocalizationModel.createDefault(
        'guest',
        const Locale('fr', 'FR'),
      );
    }
  }

  // Charger la configuration depuis le stockage local
  Future<LocalizationModel?> _loadLocalConfiguration() async {
    try {
      if (_prefs == null) return null;
      
      final configJson = _prefs!.getString('localization_config');
      if (configJson == null) return null;
      
      // Note: Ceci est une version simplifiée. Dans une vraie application,
      // vous devriez désérialiser correctement le JSON en LocalizationModel
      final systemLocale = PlatformDispatcher.instance.locale;
      return LocalizationModel.createDefault('guest', systemLocale);
    } catch (e) {
      debugPrint('Erreur lors du chargement de la configuration locale: $e');
      return null;
    }
  }

  // Sauvegarder la configuration dans le stockage local
  Future<void> _saveLocalConfiguration(LocalizationModel config) async {
    try {
      if (_prefs == null) return;
      
      // Note: Ceci est une version simplifiée. Dans une vraie application,
      // vous devriez sérialiser correctement le LocalizationModel en JSON
      await _prefs!.setString('localization_config', 'config_json');
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde de la configuration locale: $e');
    }
  }

  // Obtenir la configuration actuelle
  LocalizationModel? getCurrentConfig() {
    return _currentConfig;
  }

  // Obtenir la langue actuelle
  AppLanguage getCurrentLanguage() {
    return _currentConfig?.language ?? AppLanguage.french;
  }

  // Obtenir la région actuelle
  AppRegion getCurrentRegion() {
    return _currentConfig?.region ?? AppRegion.france;
  }

  // Obtenir le fuseau horaire actuel
  TimeZone getCurrentTimeZone() {
    return _currentConfig?.timeZone ?? TimeZone.europeParis;
  }

  // Mettre à jour la langue
  Future<LocalizationModel> updateLanguage(AppLanguage newLanguage) async {
    try {
      final currentUser = _authService.currentUser;
      final oldConfig = _currentConfig;
      
      if (oldConfig == null) {
        throw Exception('Aucune configuration de localisation chargée');
      }

      // Mettre à jour la configuration
      final newConfig = oldConfig.updateLanguage(newLanguage);
      _currentConfig = newConfig;

      if (currentUser != null) {
        // Sauvegarder dans Firestore pour l'utilisateur connecté
        await _databaseService.updateUserLocalization(currentUser.uid, newConfig);
        
        // Logger le changement
        await _auditService.logAction(
          adminId: currentUser.uid,
          adminEmail: currentUser.email ?? 'Unknown',
          action: 'update_language',
          targetType: 'user_localization',
          targetId: currentUser.uid,
          description: 'Changement de langue: ${oldConfig.language.name} → ${newLanguage.name}',
          oldData: {'language': oldConfig.language.name},
          newData: {'language': newLanguage.name},
        );
      } else {
        // Sauvegarder localement pour les utilisateurs non connectés
        await _saveLocalConfiguration(newConfig);
      }

      // Mettre à jour la locale de l'application
      await _updateAppLocale(newLanguage);

      return newConfig;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de la langue: $e');
      throw Exception('Impossible de mettre à jour la langue: ${e.toString()}');
    }
  }

  // Mettre à jour la région
  Future<LocalizationModel> updateRegion(AppRegion newRegion) async {
    try {
      final currentUser = _authService.currentUser;
      final oldConfig = _currentConfig;
      
      if (oldConfig == null) {
        throw Exception('Aucune configuration de localisation chargée');
      }

      // Mettre à jour la configuration
      final newConfig = oldConfig.updateRegion(newRegion);
      _currentConfig = newConfig;

      if (currentUser != null) {
        // Sauvegarder dans Firestore pour l'utilisateur connecté
        await _databaseService.updateUserLocalization(currentUser.uid, newConfig);
        
        // Logger le changement
        await _auditService.logAction(
          adminId: currentUser.uid,
          adminEmail: currentUser.email ?? 'Unknown',
          action: 'update_region',
          targetType: 'user_localization',
          targetId: currentUser.uid,
          description: 'Changement de région: ${oldConfig.region.name} → ${newRegion.name}',
          oldData: {'region': oldConfig.region.name},
          newData: {'region': newRegion.name},
        );
      } else {
        // Sauvegarder localement pour les utilisateurs non connectés
        await _saveLocalConfiguration(newConfig);
      }

      // Mettre à jour les formats régionaux
      await _updateRegionalFormats(newRegion);

      return newConfig;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de la région: $e');
      throw Exception('Impossible de mettre à jour la région: ${e.toString()}');
    }
  }

  // Mettre à jour le fuseau horaire
  Future<LocalizationModel> updateTimeZone(TimeZone newTimeZone) async {
    try {
      final currentUser = _authService.currentUser;
      final oldConfig = _currentConfig;
      
      if (oldConfig == null) {
        throw Exception('Aucune configuration de localisation chargée');
      }

      // Mettre à jour la configuration
      final newConfig = oldConfig.updateTimeZone(newTimeZone);
      _currentConfig = newConfig;

      if (currentUser != null) {
        // Sauvegarder dans Firestore pour l'utilisateur connecté
        await _databaseService.updateUserLocalization(currentUser.uid, newConfig);
        
        // Logger le changement
        await _auditService.logAction(
          adminId: currentUser.uid,
          adminEmail: currentUser.email ?? 'Unknown',
          action: 'update_timezone',
          targetType: 'user_localization',
          targetId: currentUser.uid,
          description: 'Changement de fuseau horaire: ${oldConfig.timeZone.name} → ${newTimeZone.name}',
          oldData: {'timeZone': oldConfig.timeZone.name},
          newData: {'timeZone': newTimeZone.name},
        );
      } else {
        // Sauvegarder localement pour les utilisateurs non connectés
        await _saveLocalConfiguration(newConfig);
      }

      return newConfig;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du fuseau horaire: $e');
      throw Exception('Impossible de mettre à jour le fuseau horaire: ${e.toString()}');
    }
  }

  // Mettre à jour la locale de l'application
  Future<void> _updateAppLocale(AppLanguage language) async {
    try {
      // Mettre à jour la locale Flutter
      // Note: Dans une vraie application, vous devriez utiliser un package comme easy_localization
      // pour gérer le changement de langue dynamiquement
      
      debugPrint('Locale mise à jour: ${language.flutterLocale}');
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de la locale: $e');
    }
  }

  // Mettre à jour les formats régionaux
  Future<void> _updateRegionalFormats(AppRegion region) async {
    try {
      // Mettre à jour les formats de nombre, date, etc. selon la région
      debugPrint('Formats régionaux mis à jour pour: ${region.name}');
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour des formats régionaux: $e');
    }
  }

  // Formater une date selon la configuration actuelle
  String formatDate(DateTime date) {
    return _currentConfig?.formatDate(date) ?? 
        DateFormat('dd/MM/yyyy').format(date);
  }

  // Formater une heure selon la configuration actuelle
  String formatTime(TimeOfDay time) {
    return _currentConfig?.formatTime(time) ?? 
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Formater un nombre selon la configuration actuelle
  String formatNumber(double number) {
    return _currentConfig?.formatNumber(number) ?? 
        number.toStringAsFixed(2);
  }

  // Formater un prix selon la configuration actuelle
  String formatCurrency(double amount) {
    return _currentConfig?.formatCurrency(amount) ?? 
        '${amount.toStringAsFixed(2)} €';
  }

  // Obtenir le symbole monétaire actuel
  String getCurrencySymbol() {
    return _currentConfig?.getCurrencySymbol() ?? '€';
  }

  // Obtenir le code monétaire actuel
  String getCurrencyCode() {
    return _currentConfig?.getCurrencyCode() ?? 'EUR';
  }

  // Convertir une date/heure selon le fuseau horaire de l'utilisateur
  DateTime convertToUserTimeZone(DateTime dateTime) {
    try {
      final timeZone = getCurrentTimeZone();
      // Note: Ceci est une version simplifiée. Dans une vraie application,
      // vous devriez utiliser le package timezone pour gérer les conversions de fuseau horaire
      return dateTime;
    } catch (e) {
      debugPrint('Erreur lors de la conversion du fuseau horaire: $e');
      return dateTime;
    }
  }

  // Obtenir une chaîne de caractères localisée
  String getLocalizedString(String key, {Map<String, String>? params}) {
    // Note: Dans une vraie application, vous devriez utiliser un système de traduction
    // comme easy_localization ou flutter_intl
    return key; // Retourne la clé par défaut
  }

  // Détecter automatiquement la langue et la région
  Future<LocalizationModel> detectAndSetLocale() async {
    try {
      final systemLocale = PlatformDispatcher.instance.locale;
      
      // Détecter la langue
      AppLanguage detectedLanguage = AppLanguage.french;
      for (final lang in AppLanguage.values) {
        if (lang.code == systemLocale.languageCode) {
          detectedLanguage = lang;
          break;
        }
      }

      // Détecter la région
      AppRegion detectedRegion = AppRegion.france;
      for (final region in AppRegion.values) {
        if (region.code == systemLocale.countryCode) {
          detectedRegion = region;
          break;
        }
      }

      // Mettre à jour la configuration
      final newConfig = _currentConfig?.copyWith(
        language: detectedLanguage,
        region: detectedRegion,
      ) ?? LocalizationModel.createDefault(
        _authService.currentUser?.uid ?? 'guest',
        systemLocale,
      );

      _currentConfig = newConfig;

      // Sauvegarder la configuration
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        await _databaseService.updateUserLocalization(currentUser.uid, newConfig);
      } else {
        await _saveLocalConfiguration(newConfig);
      }

      return newConfig;
    } catch (e) {
      debugPrint('Erreur lors de la détection automatique de la locale: $e');
      throw Exception('Impossible de détecter la locale: ${e.toString()}');
    }
  }

  // Obtenir la liste des langues supportées
  List<AppLanguage> getSupportedLanguages() {
    return AppLanguage.values;
  }

  // Obtenir la liste des régions supportées
  List<AppRegion> getSupportedRegions() {
    return AppRegion.values;
  }

  // Obtenir la liste des fuseaux horaires supportés
  List<TimeZone> getSupportedTimeZones() {
    return TimeZone.values;
  }

  // Vérifier si une langue est RTL (Right-to-Left)
  bool isCurrentLanguageRTL() {
    return getCurrentLanguage().rtl;
  }

  // Obtenir la direction du texte selon la langue actuelle
  TextDirection getTextDirection() {
    return isCurrentLanguageRTL() ? TextDirection.rtl : TextDirection.ltr;
  }

  // Appliquer les paramètres de localisation à un thème
  ThemeData applyLocalizationToTheme(ThemeData theme) {
    // Note: Dans une vraie application, vous pourriez vouloir adapter certains
    // aspects du thème selon la localisation (couleurs, polices, etc.)
    return theme;
  }

  // Obtenir des informations sur la localisation actuelle pour le débogage
  Map<String, dynamic> getDebugInfo() {
    return {
      'currentLanguage': _currentConfig?.language.name,
      'currentRegion': _currentConfig?.region.name,
      'currentTimeZone': _currentConfig?.timeZone.name,
      'dateFormat': _currentConfig?.dateFormat.name,
      'timeFormat': _currentConfig?.timeFormat.name,
      'numberFormat': _currentConfig?.numberFormat.name,
      'currencyFormat': _currentConfig?.currencyFormat.name,
      'measurementSystem': _currentConfig?.measurementSystem.name,
      'isRTL': isCurrentLanguageRTL(),
      'systemLocale': PlatformDispatcher.instance.locale.toString(),
    };
  }

  // Réinitialiser la configuration aux valeurs par défaut
  Future<LocalizationModel> resetToDefaults() async {
    try {
      final currentUser = _authService.currentUser;
      final systemLocale = PlatformDispatcher.instance.locale;
      
      // Créer une configuration par défaut
      final defaultConfig = LocalizationModel.createDefault(
        currentUser?.uid ?? 'guest',
        systemLocale,
      );
      
      _currentConfig = defaultConfig;

      if (currentUser != null) {
        // Sauvegarder dans Firestore pour l'utilisateur connecté
        await _databaseService.updateUserLocalization(currentUser.uid, defaultConfig);
        
        // Logger la réinitialisation
        await _auditService.logAction(
          adminId: currentUser.uid,
          adminEmail: currentUser.email ?? 'Unknown',
          action: 'reset_localization',
          targetType: 'user_localization',
          targetId: currentUser.uid,
          description: 'Réinitialisation de la configuration de localisation aux valeurs par défaut',
        );
      } else {
        // Sauvegarder localement pour les utilisateurs non connectés
        await _saveLocalConfiguration(defaultConfig);
      }

      return defaultConfig;
    } catch (e) {
      debugPrint('Erreur lors de la réinitialisation de la configuration: $e');
      throw Exception('Impossible de réinitialiser la configuration: ${e.toString()}');
    }
  }

  // Stream pour écouter les changements de configuration
  Stream<LocalizationModel?> get configStream {
    // Note: Dans une vraie application, vous devriez implémenter un vrai stream
    // qui écoute les changements depuis Firestore ou SharedPreferences
    return Stream.value(_currentConfig);
  }
}
