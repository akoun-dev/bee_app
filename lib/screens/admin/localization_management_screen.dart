import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/localization_model.dart';
import '../../services/auth_service.dart';
import '../../services/localization_service.dart';
import '../../services/authorization_service.dart';
import '../../widgets/admin_app_bar.dart';
import '../../widgets/admin_drawer.dart';
import '../../widgets/common_widgets.dart';

class LocalizationManagementScreen extends StatefulWidget {
  const LocalizationManagementScreen({super.key});

  @override
  State<LocalizationManagementScreen> createState() => _LocalizationManagementScreenState();
}

class _LocalizationManagementScreenState extends State<LocalizationManagementScreen> {
  // Services
  late AuthService _authService;
  late LocalizationService _localizationService;
  late AuthorizationService _authorizationService;

  // État de l'écran
  bool _isLoading = true;
  bool _isLoadingUsers = false;
  List<UserModel> _users = [];
  Map<String, LocalizationModel> _userLocalizations = {};
  Map<String, dynamic> _statistics = {};
  
  // Contrôleurs et filtres
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  AppLanguage? _filterLanguage;
  AppRegion? _filterRegion;
  TimeZone? _filterTimeZone;

  // Options disponibles
  final List<AppLanguage> _languageOptions = AppLanguage.values;
  final List<AppRegion> _regionOptions = AppRegion.values;
  final List<TimeZone> _timeZoneOptions = TimeZone.values;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadData();
  }

  void _initializeServices() {
    _authService = Provider.of<AuthService>(context, listen: false);
    _localizationService = Provider.of<LocalizationService>(context, listen: false);
    _authorizationService = Provider.of<AuthorizationService>(context, listen: false);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _loadUsers(),
        _loadStatistics(),
      ]);
    } catch (e) {
      debugPrint('Erreur lors du chargement des données: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _authService.getAllUsers();
      setState(() {
        _users = users;
      });
      
      // Charger les configurations de localisation pour tous les utilisateurs
      await _loadUserLocalizations(users);
    } catch (e) {
      debugPrint('Erreur lors du chargement des utilisateurs: $e');
    }
  }

  Future<void> _loadUserLocalizations(List<UserModel> users) async {
    setState(() => _isLoadingUsers = true);

    try {
      final localizations = <String, LocalizationModel>{};
      
      for (final user in users) {
        try {
          final localization = await _localizationService.getCurrentConfig();
          if (localization != null) {
            localizations[user.uid] = localization;
          }
        } catch (e) {
          debugPrint('Erreur lors du chargement de la localisation pour ${user.uid}: $e');
        }
      }
      
      setState(() {
        _userLocalizations = localizations;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des localisations: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingUsers = false);
      }
    }
  }

  Future<void> _loadStatistics() async {
    try {
      // Calculer les statistiques manuellement
      final totalUsers = _users.length;
      final languageCounts = <AppLanguage, int>{};
      final regionCounts = <AppRegion, int>{};
      final timeZoneCounts = <TimeZone, int>{};
      final rtlCount = _userLocalizations.values.where((loc) => loc.language.rtl).length;

      // Compter les langues
      for (final localization in _userLocalizations.values) {
        languageCounts[localization.language] = (languageCounts[localization.language] ?? 0) + 1;
        regionCounts[localization.region] = (regionCounts[localization.region] ?? 0) + 1;
        timeZoneCounts[localization.timeZone] = (timeZoneCounts[localization.timeZone] ?? 0) + 1;
      }

      setState(() {
        _statistics = {
          'totalUsers': totalUsers,
          'configuredUsers': _userLocalizations.length,
          'languageDistribution': languageCounts.map((key, value) => 
            MapEntry(key.name, {
              'count': value,
              'percentage': (value / totalUsers * 100).toStringAsFixed(1),
            })
          ),
          'regionDistribution': regionCounts.map((key, value) => 
            MapEntry(key.name, {
              'count': value,
              'percentage': (value / totalUsers * 100).toStringAsFixed(1),
            })
          ),
          'timeZoneDistribution': timeZoneCounts.map((key, value) => 
            MapEntry(key.name, {
              'count': value,
              'percentage': (value / totalUsers * 100).toStringAsFixed(1),
            })
          ),
          'rtlUsers': rtlCount,
          'rtlPercentage': (rtlCount / totalUsers * 100).toStringAsFixed(1),
        };
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des statistiques: $e');
    }
  }

  List<UserModel> get _filteredUsers {
    return _users.where((user) {
      // Filtre de recherche
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!user.fullName.toLowerCase().contains(query) &&
            !user.email.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Filtre par langue
      if (_filterLanguage != null) {
        final localization = _userLocalizations[user.uid];
        if (localization == null || localization.language != _filterLanguage) {
          return false;
        }
      }

      // Filtre par région
      if (_filterRegion != null) {
        final localization = _userLocalizations[user.uid];
        if (localization == null || localization.region != _filterRegion) {
          return false;
        }
      }

      // Filtre par fuseau horaire
      if (_filterTimeZone != null) {
        final localization = _userLocalizations[user.uid];
        if (localization == null || localization.timeZone != _filterTimeZone) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Widget _buildStatisticsCards() {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.8,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          title: 'Total Utilisateurs',
          value: '${_statistics['totalUsers'] ?? 0}',
          icon: Icons.people,
          color: Colors.blue,
        ),
        _buildStatCard(
          title: 'Configurés',
          value: '${_statistics['configuredUsers'] ?? 0}',
          subtitle: '${_statistics['configuredUsersPercentage'] ?? '0'}%',
          icon: Icons.settings,
          color: Colors.green,
        ),
        _buildStatCard(
          title: 'Langues Supportées',
          value: '${_languageOptions.length}',
          icon: Icons.language,
          color: Colors.orange,
        ),
        _buildStatCard(
          title: 'Utilisateurs RTL',
          value: '${_statistics['rtlUsers'] ?? 0}',
          subtitle: '${_statistics['rtlPercentage'] ?? '0'}%',
          icon: Icons.text_format,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionCharts() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribution des Préférences',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Distribution des langues
            _buildDistributionSection(
              'Langues',
              _statistics['languageDistribution'] ?? {},
              Colors.blue,
            ),
            const SizedBox(height: 16),
            
            // Distribution des régions
            _buildDistributionSection(
              'Régions',
              _statistics['regionDistribution'] ?? {},
              Colors.green,
            ),
            const SizedBox(height: 16),
            
            // Distribution des fuseaux horaires
            _buildDistributionSection(
              'Fuseaux Horaires',
              _statistics['timeZoneDistribution'] ?? {},
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionSection(String title, Map<String, dynamic> distribution, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...distribution.entries.map((entry) {
          final percentage = double.tryParse(entry.value['percentage']?.toString() ?? '0') ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    entry.key,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey[200],
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: Text(
                    '${entry.value['count']} (${percentage.toStringAsFixed(1)}%)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildFilters() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtres',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Barre de recherche
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un utilisateur...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
            const SizedBox(height: 12),
            
            // Filtre par langue
            DropdownButtonFormField<AppLanguage?>(
              value: _filterLanguage,
              decoration: const InputDecoration(
                labelText: 'Langue',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Toutes les langues')),
                ..._languageOptions.map((language) => DropdownMenuItem(
                  value: language,
                  child: Text(language.name),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _filterLanguage = value;
                });
              },
            ),
            const SizedBox(height: 12),
            
            // Filtre par région
            DropdownButtonFormField<AppRegion?>(
              value: _filterRegion,
              decoration: const InputDecoration(
                labelText: 'Région',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Toutes les régions')),
                ..._regionOptions.map((region) => DropdownMenuItem(
                  value: region,
                  child: Text(region.name),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _filterRegion = value;
                });
              },
            ),
            const SizedBox(height: 12),
            
            // Filtre par fuseau horaire
            DropdownButtonFormField<TimeZone?>(
              value: _filterTimeZone,
              decoration: const InputDecoration(
                labelText: 'Fuseau horaire',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Tous les fuseaux horaires')),
                ..._timeZoneOptions.map((timeZone) => DropdownMenuItem(
                  value: timeZone,
                  child: Text(timeZone.name),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _filterTimeZone = value;
                });
              },
            ),
            
            const SizedBox(height: 8),
            
            // Bouton de réinitialisation
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                    _filterLanguage = null;
                    _filterRegion = null;
                    _filterTimeZone = null;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Réinitialiser'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    if (_isLoadingUsers) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredUsers = _filteredUsers;
    
    if (filteredUsers.isEmpty) {
      return const Center(
        child: Text('Aucun utilisateur trouvé pour ces critères'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        final localization = _userLocalizations[user.uid];
        return _buildUserCard(user, localization);
      },
    );
  }

  Widget _buildUserCard(UserModel user, LocalizationModel? localization) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec informations utilisateur
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: user.profileImageUrl != null
                      ? NetworkImage(user.profileImageUrl!)
                      : null,
                  child: user.profileImageUrl == null
                      ? const Icon(Icons.person, size: 24)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'edit':
                        await _editUserLocalization(user, localization);
                        break;
                      case 'view_details':
                        _showUserLocalizationDetails(user, localization);
                        break;
                      case 'reset':
                        await _resetUserLocalization(user);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Modifier la configuration'),
                    ),
                    const PopupMenuItem(
                      value: 'view_details',
                      child: Text('Voir les détails'),
                    ),
                    const PopupMenuItem(
                      value: 'reset',
                      child: Text('Réinitialiser'),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Configuration de localisation
            if (localization != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configuration:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildLocalizationChip(
                        'Langue',
                        localization.language.name,
                        localization.language.rtl,
                        Colors.blue,
                      ),
                      _buildLocalizationChip(
                        'Région',
                        localization.region.name,
                        false,
                        Colors.green,
                      ),
                      _buildLocalizationChip(
                        'Fuseau Horaire',
                        localization.timeZone.name,
                        false,
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              )
            else
              const Text(
                'Aucune configuration de localisation',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalizationChip(String label, String value, bool isRTL, Color color) {
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (isRTL) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.text_format,
              size: 12,
              color: color,
            ),
          ],
        ],
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }

  Future<void> _editUserLocalization(UserModel user, LocalizationModel? currentLocalization) async {
    try {
      // Créer une configuration par défaut si nécessaire
      final localization = currentLocalization ?? 
          LocalizationModel.createDefault(user.uid, const Locale('fr', 'FR'));
      
      // Valeurs modifiables
      AppLanguage selectedLanguage = localization.language;
      AppRegion selectedRegion = localization.region;
      TimeZone selectedTimeZone = localization.timeZone;
      
      final shouldUpdate = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Modifier la localisation de ${user.fullName}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Sélectionnez les préférences de localisation:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    
                    // Langue
                    DropdownButtonFormField<AppLanguage>(
                      value: selectedLanguage,
                      decoration: const InputDecoration(
                        labelText: 'Langue',
                        border: OutlineInputBorder(),
                      ),
                      items: _languageOptions.map((language) => DropdownMenuItem(
                        value: language,
                        child: Text(language.name),
                      )).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedLanguage = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // Région
                    DropdownButtonFormField<AppRegion>(
                      value: selectedRegion,
                      decoration: const InputDecoration(
                        labelText: 'Région',
                        border: OutlineInputBorder(),
                      ),
                      items: _regionOptions.map((region) => DropdownMenuItem(
                        value: region,
                        child: Text(region.name),
                      )).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedRegion = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // Fuseau horaire
                    DropdownButtonFormField<TimeZone>(
                      value: selectedTimeZone,
                      decoration: const InputDecoration(
                        labelText: 'Fuseau horaire',
                        border: OutlineInputBorder(),
                      ),
                      items: _timeZoneOptions.map((timeZone) => DropdownMenuItem(
                        value: timeZone,
                        child: Text(timeZone.name),
                      )).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedTimeZone = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Sauvegarder'),
                ),
              ],
            );
          },
        ),
      );

      if (shouldUpdate == true) {
        // Mettre à jour la configuration
        await _localizationService.updateLanguage(selectedLanguage);
        await _localizationService.updateRegion(selectedRegion);
        await _localizationService.updateTimeZone(selectedTimeZone);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Configuration de localisation mise à jour avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData(); // Recharger les données
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUserLocalizationDetails(UserModel user, LocalizationModel? localization) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails de localisation - ${user.fullName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', user.email),
              
              if (localization != null) ...[
                _buildDetailRow('Langue', localization.language.name),
                _buildDetailRow('Code de langue', localization.language.code),
                _buildDetailRow('RTL', localization.language.rtl ? 'Oui' : 'Non'),
                _buildDetailRow('Région', localization.region.name),
                _buildDetailRow('Code de région', localization.region.code),
                _buildDetailRow('Fuseau horaire', localization.timeZone.name),
                _buildDetailRow('Offset UTC', localization.timeZone.utcOffset),
                _buildDetailRow('Format de date', localization.dateFormat.name),
                _buildDetailRow('Format de temps', localization.timeFormat.name),
                _buildDetailRow('Format de nombre', localization.numberFormat.name),
                _buildDetailRow('Format monétaire', localization.currencyFormat.name),
                _buildDetailRow('Symbole monétaire', localization.getCurrencySymbol()),
                _buildDetailRow('Code monétaire', localization.getCurrencyCode()),
                _buildDetailRow('Système de mesure', localization.measurementSystem.name),
                _buildDetailRow('Dernière mise à jour', 
                  _localizationService.formatDate(localization.lastUpdated)),
              ] else
                const Text('Aucune configuration de localisation enregistrée'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetUserLocalization(UserModel user) async {
    try {
      final shouldReset = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Réinitialiser la localisation de ${user.fullName}'),
          content: const Text(
            'Êtes-vous sûr de vouloir réinitialiser la configuration de localisation aux valeurs par défaut?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Réinitialiser'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ),
      );

      if (shouldReset == true) {
        await _localizationService.resetToDefaults();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Configuration de localisation réinitialisée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData(); // Recharger les données
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la réinitialisation: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AdminAppBar(title: 'Gestion de l\'Internationalisation'),
      drawer: const AdminDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statistiques
                    _buildStatisticsCards(),
                    const SizedBox(height: 24),
                    
                    // Graphiques de distribution
                    _buildDistributionCharts(),
                    const SizedBox(height: 24),
                    
                    // Filtres
                    _buildFilters(),
                    const SizedBox(height: 24),
                    
                    // Liste des utilisateurs
                    const Text(
                      'Utilisateurs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildUsersList(),
                  ],
                ),
              ),
      ),
    );
  }
}
