import 'package:cloud_firestore/cloud_firestore.dart';

// Modèle pour les préférences utilisateur
class UserPreferencesModel {
  final String userId;
  final List<String> favoriteAgentIds;
  final Map<String, double> categoryPreferences;
  final List<String> recentSearches;
  final Map<String, dynamic> interfaceSettings;
  final DateTime lastUpdated;

  UserPreferencesModel({
    required this.userId,
    this.favoriteAgentIds = const [],
    this.categoryPreferences = const {},
    this.recentSearches = const [],
    this.interfaceSettings = const {},
    required this.lastUpdated,
  });

  // Conversion depuis Firestore
  factory UserPreferencesModel.fromMap(Map<String, dynamic> map, String id) {
    return UserPreferencesModel(
      userId: id,
      favoriteAgentIds: List<String>.from(map['favoriteAgentIds'] ?? []),
      categoryPreferences: Map<String, double>.from(map['categoryPreferences'] ?? {}),
      recentSearches: List<String>.from(map['recentSearches'] ?? []),
      interfaceSettings: Map<String, dynamic>.from(map['interfaceSettings'] ?? {}),
      lastUpdated: (map['lastUpdated'] as Timestamp).toDate(),
    );
  }

  // Conversion vers Firestore
  Map<String, dynamic> toMap() {
    return {
      'favoriteAgentIds': favoriteAgentIds,
      'categoryPreferences': categoryPreferences,
      'recentSearches': recentSearches,
      'interfaceSettings': interfaceSettings,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  // Créer des préférences par défaut pour un utilisateur
  factory UserPreferencesModel.createDefault(String userId) {
    return UserPreferencesModel(
      userId: userId,
      favoriteAgentIds: [],
      categoryPreferences: {},
      recentSearches: [],
      interfaceSettings: {
        // Thème
        'themeMode': 'system', // 'light', 'dark', 'system'

        // Apparence
        'accentColor': 'yellow', // 'yellow', 'blue', 'green', 'purple', 'orange'
        'cardStyle': 'default', // 'default', 'flat', 'elevated'
        'fontFamily': 'default', // 'default', 'poppins', 'roboto', 'lato'

        // Accessibilité
        'textSize': 'medium', // 'small', 'medium', 'large', 'extra_large'
        'highContrast': false,
        'reducedMotion': false,

        // Notifications
        'enableNotifications': true,
        'enableReservationReminders': true,
        'enablePromotions': false,

        // Confidentialité
        'shareUsageData': false,
        'shareLocation': true,

        // Préférences personnelles
        'preferredCategories': ['Sécurité', 'Transport', 'Événementiel'], // Catégories préférées
        'preferredDistance': 20, // Distance maximale en km
        'autoSuggestAgents': true, // Suggérer automatiquement des agents
        'showRatings': true, // Afficher les évaluations
        'sortAgentsBy': 'rating', // 'rating', 'distance', 'price', 'availability'
      },
      lastUpdated: DateTime.now(),
    );
  }

  // Ajouter un agent aux favoris
  UserPreferencesModel addFavoriteAgent(String agentId) {
    if (favoriteAgentIds.contains(agentId)) {
      return this;
    }

    final updatedFavorites = List<String>.from(favoriteAgentIds)..add(agentId);

    return copyWith(
      favoriteAgentIds: updatedFavorites,
      lastUpdated: DateTime.now(),
    );
  }

  // Retirer un agent des favoris
  UserPreferencesModel removeFavoriteAgent(String agentId) {
    if (!favoriteAgentIds.contains(agentId)) {
      return this;
    }

    final updatedFavorites = List<String>.from(favoriteAgentIds)..remove(agentId);

    return copyWith(
      favoriteAgentIds: updatedFavorites,
      lastUpdated: DateTime.now(),
    );
  }

  // Mettre à jour les préférences de catégorie
  UserPreferencesModel updateCategoryPreference(String category, double weight) {
    final updatedPreferences = Map<String, double>.from(categoryPreferences);
    updatedPreferences[category] = weight;

    return copyWith(
      categoryPreferences: updatedPreferences,
      lastUpdated: DateTime.now(),
    );
  }

  // Ajouter une recherche récente
  UserPreferencesModel addRecentSearch(String search) {
    // Limiter à 10 recherches récentes
    final updatedSearches = List<String>.from(recentSearches);

    // Supprimer si déjà présent (pour le déplacer en haut)
    updatedSearches.remove(search);

    // Ajouter au début de la liste
    updatedSearches.insert(0, search);

    // Limiter à 10 éléments
    if (updatedSearches.length > 10) {
      updatedSearches.removeLast();
    }

    return copyWith(
      recentSearches: updatedSearches,
      lastUpdated: DateTime.now(),
    );
  }

  // Mettre à jour les paramètres d'interface
  UserPreferencesModel updateInterfaceSettings(Map<String, dynamic> newSettings) {
    final updatedSettings = Map<String, dynamic>.from(interfaceSettings)
      ..addAll(newSettings);

    return copyWith(
      interfaceSettings: updatedSettings,
      lastUpdated: DateTime.now(),
    );
  }

  // Copie avec modification
  UserPreferencesModel copyWith({
    List<String>? favoriteAgentIds,
    Map<String, double>? categoryPreferences,
    List<String>? recentSearches,
    Map<String, dynamic>? interfaceSettings,
    DateTime? lastUpdated,
  }) {
    return UserPreferencesModel(
      userId: userId,
      favoriteAgentIds: favoriteAgentIds ?? this.favoriteAgentIds,
      categoryPreferences: categoryPreferences ?? this.categoryPreferences,
      recentSearches: recentSearches ?? this.recentSearches,
      interfaceSettings: interfaceSettings ?? this.interfaceSettings,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
