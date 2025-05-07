import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Service pour gérer les paramètres de l'application
class SettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _settingsDocId = 'app_settings';
  
  // Paramètres par défaut
  final Map<String, dynamic> _defaultSettings = {
    'commissionRate': 15.0,
    'maxBookingDays': 30,
    'cancellationPolicy': 'Les annulations sont gratuites jusqu\'à 24 heures avant la date de réservation. Après ce délai, des frais peuvent s\'appliquer.',
    'termsAndConditions': 'Conditions d\'utilisation par défaut...',
    'privacyPolicy': 'Politique de confidentialité par défaut...',
    'enableNotifications': true,
    'enableRatings': true,
    'enableChat': true,
    'lastUpdated': null,
  };
  
  // Cache des paramètres
  Map<String, dynamic>? _cachedSettings;
  DateTime? _lastFetched;
  
  // Récupérer les paramètres de l'application
  Future<Map<String, dynamic>> getAppSettings() async {
    try {
      // Vérifier si les paramètres sont en cache et récents (moins de 5 minutes)
      final now = DateTime.now();
      if (_cachedSettings != null && _lastFetched != null && 
          now.difference(_lastFetched!).inMinutes < 5) {
        return _cachedSettings!;
      }
      
      // Récupérer les paramètres depuis Firestore
      final doc = await _firestore.collection('settings').doc(_settingsDocId).get();
      
      if (doc.exists) {
        // Fusionner avec les paramètres par défaut pour s'assurer que tous les champs sont présents
        final settings = {..._defaultSettings, ...doc.data() ?? {}};
        
        // Mettre à jour le cache
        _cachedSettings = settings;
        _lastFetched = now;
        
        // Sauvegarder localement pour un accès hors ligne
        await _saveSettingsLocally(settings);
        
        return settings;
      } else {
        // Si le document n'existe pas, créer avec les paramètres par défaut
        await _firestore.collection('settings').doc(_settingsDocId).set(_defaultSettings);
        
        // Mettre à jour le cache
        _cachedSettings = _defaultSettings;
        _lastFetched = now;
        
        // Sauvegarder localement
        await _saveSettingsLocally(_defaultSettings);
        
        return _defaultSettings;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la récupération des paramètres: ${e.toString()}');
      }
      
      // En cas d'erreur, essayer de récupérer les paramètres locaux
      final localSettings = await _getLocalSettings();
      if (localSettings != null) {
        return localSettings;
      }
      
      // Si tout échoue, retourner les paramètres par défaut
      return _defaultSettings;
    }
  }
  
  // Mettre à jour les paramètres de l'application
  Future<void> updateAppSettings(Map<String, dynamic> newSettings) async {
    try {
      // Fusionner avec les paramètres existants
      final currentSettings = await getAppSettings();
      final updatedSettings = {...currentSettings, ...newSettings};
      
      // Mettre à jour dans Firestore
      await _firestore.collection('settings').doc(_settingsDocId).set(updatedSettings);
      
      // Mettre à jour le cache
      _cachedSettings = updatedSettings;
      _lastFetched = DateTime.now();
      
      // Sauvegarder localement
      await _saveSettingsLocally(updatedSettings);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la mise à jour des paramètres: ${e.toString()}');
      }
      throw Exception('Erreur lors de la mise à jour des paramètres: ${e.toString()}');
    }
  }
  
  // Sauvegarder les paramètres localement
  Future<void> _saveSettingsLocally(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convertir les valeurs en chaînes pour SharedPreferences
      final Map<String, String> stringSettings = {};
      settings.forEach((key, value) {
        if (value != null) {
          stringSettings[key] = value.toString();
        }
      });
      
      // Sauvegarder chaque paramètre individuellement
      for (final entry in stringSettings.entries) {
        await prefs.setString('settings_${entry.key}', entry.value);
      }
      
      // Sauvegarder la date de mise à jour
      await prefs.setString('settings_lastSaved', DateTime.now().toIso8601String());
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la sauvegarde locale des paramètres: ${e.toString()}');
      }
    }
  }
  
  // Récupérer les paramètres locaux
  Future<Map<String, dynamic>?> _getLocalSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Vérifier si des paramètres sont sauvegardés
      if (!prefs.containsKey('settings_lastSaved')) {
        return null;
      }
      
      // Récupérer tous les paramètres
      final Map<String, dynamic> settings = {};
      
      for (final key in _defaultSettings.keys) {
        final value = prefs.getString('settings_$key');
        if (value != null) {
          // Convertir les valeurs au bon type
          if (_defaultSettings[key] is double) {
            settings[key] = double.tryParse(value) ?? _defaultSettings[key];
          } else if (_defaultSettings[key] is int) {
            settings[key] = int.tryParse(value) ?? _defaultSettings[key];
          } else if (_defaultSettings[key] is bool) {
            settings[key] = value.toLowerCase() == 'true';
          } else {
            settings[key] = value;
          }
        } else {
          settings[key] = _defaultSettings[key];
        }
      }
      
      return settings;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la récupération locale des paramètres: ${e.toString()}');
      }
      return null;
    }
  }
  
  // Récupérer un paramètre spécifique
  Future<T?> getSetting<T>(String key) async {
    final settings = await getAppSettings();
    return settings[key] as T?;
  }
  
  // Mettre à jour un paramètre spécifique
  Future<void> updateSetting(String key, dynamic value) async {
    await updateAppSettings({key: value});
  }
  
  // Réinitialiser tous les paramètres aux valeurs par défaut
  Future<void> resetSettings() async {
    await updateAppSettings(_defaultSettings);
  }
}
