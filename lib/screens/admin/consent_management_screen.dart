import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/consent_model.dart';
import '../../services/auth_service.dart';
import '../../services/consent_service.dart';
import '../../services/localization_service.dart';
import '../../services/authorization_service.dart';
import '../../widgets/admin_app_bar.dart';
import '../../widgets/admin_drawer.dart';

class ConsentManagementScreen extends StatefulWidget {
  const ConsentManagementScreen({super.key});

  @override
  State<ConsentManagementScreen> createState() => _ConsentManagementScreenState();
}

class _ConsentManagementScreenState extends State<ConsentManagementScreen> {
  // Services
  late AuthService _authService;
  late ConsentService _consentService;
  late LocalizationService _localizationService;
  late AuthorizationService _authorizationService;

  // État de l'écran
  bool _isLoading = true;
  bool _isLoadingUsers = false;
  List<UserModel> _users = [];
  Map<String, ConsentModel> _consents = {};
  Map<String, dynamic> _statistics = {};
  
  // Contrôleurs et filtres
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'all';
  ConsentType? _filterConsentType;

  // Types de consentement disponibles
  final List<ConsentType> _consentTypes = ConsentType.values;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadData();
  }

  void _initializeServices() {
    _authService = Provider.of<AuthService>(context, listen: false);
    _consentService = Provider.of<ConsentService>(context, listen: false);
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
      
      // Charger les consentements pour tous les utilisateurs
      await _loadConsentsForUsers(users);
    } catch (e) {
      debugPrint('Erreur lors du chargement des utilisateurs: $e');
    }
  }

  Future<void> _loadConsentsForUsers(List<UserModel> users) async {
    setState(() => _isLoadingUsers = true);

    try {
      final consentModels = <ConsentModel>[];
      
      for (final user in users) {
        try {
          final consent = await _consentService.getOrCreateUserConsents(user.uid);
          consentModels.add(consent);
        } catch (e) {
          debugPrint('Erreur lors du chargement des consentements pour ${user.uid}: $e');
        }
      }
      
      setState(() {
        _consents = {for (var consent in consentModels) consent.userId: consent};
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des consentements: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingUsers = false);
      }
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final stats = await _consentService.getConsentStatistics();
      setState(() {
        _statistics = stats;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des statistiques: $e');
    }
  }

  // Méthodes utilitaires pour vérifier les consentements
  bool _hasAllRequiredConsents(ConsentModel consent) {
    return consent.consents.values.every((consentData) => 
        !consentData.required || consentData.granted && consentData.isValid());
  }

  bool _hasExpiredConsents(ConsentModel consent) {
    return consent.consents.values.any((consentData) => 
        consentData.granted && consentData.isExpired());
  }

  bool _hasExpiringConsents(ConsentModel consent) {
    final now = DateTime.now();
    return consent.consents.values.any((consentData) => 
        consentData.granted && 
        consentData.expiresAt != null && 
        consentData.expiresAt!.difference(now).inDays <= 30);
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

      // Filtre de type
      if (_filterType != 'all') {
        final consent = _consents[user.uid];

        switch (_filterType) {
          case 'all_granted':
            if (consent == null || !_hasAllRequiredConsents(consent)) return false;
            break;
          case 'missing_required':
            if (consent == null || _hasAllRequiredConsents(consent)) return false;
            break;
          case 'expired':
            if (consent == null || !_hasExpiredConsents(consent)) return false;
            break;
          case 'expiring_soon':
            if (consent == null || !_hasExpiringConsents(consent)) return false;
            break;
        }
      }

      // Filtre par type de consentement spécifique
      if (_filterConsentType != null) {
        final consent = _consents[user.uid];

        final typeKey = _filterConsentType!.key;
        if (consent == null || !consent.hasConsent(typeKey)) return false;
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
          title: 'Analytics Consentis',
          value: '${_statistics['statistics']?['analytics']?['grantedPercentage'] ?? '0'}%',
          icon: Icons.analytics,
          color: Colors.green,
        ),
        _buildStatCard(
          title: 'Marketing Consentis',
          value: '${_statistics['statistics']?['marketing']?['grantedPercentage'] ?? '0'}%',
          icon: Icons.campaign,
          color: Colors.orange,
        ),
        _buildStatCard(
          title: 'Consentements Expirés',
          value: '${_statistics['statistics']?['analytics']?['expiredPercentage'] ?? '0'}%',
          icon: Icons.warning,
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
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
          ],
        ),
      ),
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
            
            // Filtre de type
            DropdownButtonFormField<String>(
              value: _filterType,
              decoration: const InputDecoration(
                labelText: 'Filtrer par',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: 'all', child: Text('Tous les utilisateurs')),
                const DropdownMenuItem(value: 'all_granted', child: Text('Tous les consentements accordés')),
                const DropdownMenuItem(value: 'missing_required', child: Text('Consentements manquants')),
                const DropdownMenuItem(value: 'expired', child: Text('Consentements expirés')),
                const DropdownMenuItem(value: 'expiring_soon', child: Text('Consentements expirant bientôt')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _filterType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            
            // Filtre par type de consentement
            DropdownButtonFormField<ConsentType?>(
              value: _filterConsentType,
              decoration: const InputDecoration(
                labelText: 'Type de consentement',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Tous les types')),
                ..._consentTypes.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.name),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _filterConsentType = value;
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
                    _filterType = 'all';
                    _filterConsentType = null;
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
        final consent = _consents[user.uid];
        return _buildUserCard(user, consent);
      },
    );
  }

  Widget _buildUserCard(UserModel user, ConsentModel? consent) {
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
                        await _editUserConsents(user);
                        break;
                      case 'view_details':
                        _showUserConsentDetails(user, consent);
                        break;
                      case 'send_reminder':
                        await _sendConsentReminder(user);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Modifier les consentements'),
                    ),
                    const PopupMenuItem(
                      value: 'view_details',
                      child: Text('Voir les détails'),
                    ),
                    const PopupMenuItem(
                      value: 'send_reminder',
                      child: Text('Envoyer un rappel'),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Consentements
            if (consent != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Consentements:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _consentTypes.map((type) {
                      final hasConsent = consent.hasConsent(type.key);
                      final isExpired = consent.isConsentExpired(type.key);
                      final isRequired = consent.consents[type.key]?.required ?? false;
                      
                      return _buildConsentChip(
                        type: type,
                        hasConsent: hasConsent,
                        isExpired: isExpired,
                        isRequired: isRequired,
                      );
                    }).toList(),
                  ),
                ],
              )
            else
              const Text(
                'Aucun consentement enregistré',
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

  Widget _buildConsentChip({
    required ConsentType type,
    required bool hasConsent,
    required bool isExpired,
    required bool isRequired,
  }) {
    Color backgroundColor;
    Color textColor;
    String label;
    
    if (isExpired) {
      backgroundColor = Colors.red[100]!;
      textColor = Colors.red[800]!;
      label = '${type.name} (expiré)';
    } else if (hasConsent) {
      backgroundColor = Colors.green[100]!;
      textColor = Colors.green[800]!;
      label = type.name;
    } else {
      backgroundColor = Colors.grey[100]!;
      textColor = Colors.grey[800]!;
      label = '${type.name} (refusé)';
    }
    
    if (isRequired) {
      label += ' *';
    }
    
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: backgroundColor,
      side: BorderSide(color: backgroundColor),
    );
  }

  Future<void> _editUserConsents(UserModel user) async {
    try {
      final consent = await _consentService.getOrCreateUserConsents(user.uid);
      
      // Créer une copie modifiable des consentements
      final updatedConsents = Map<String, bool>.from(
        consent.consents.map((key, value) => MapEntry(key, value.granted)),
      );
      
      final shouldUpdate = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Modifier les consentements de ${user.fullName}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Sélectionnez les consentements à accorder:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ..._consentTypes.map((type) {
                      final consentData = consent.consents[type.key];
                      final isRequired = consentData?.required ?? false;
                      final currentValue = updatedConsents[type.key] ?? false;
                      
                      return CheckboxListTile(
                        title: Text(type.name),
                        subtitle: Text(consentData?.purpose ?? ''),
                        value: currentValue,
                        onChanged: isRequired ? null : (value) {
                          setState(() {
                            updatedConsents[type.key] = value ?? false;
                          });
                        },
                        secondary: Icon(type.icon),
                        activeColor: Colors.green,
                      );
                    }),
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
        await _consentService.updateMultipleConsents(
          userId: user.uid,
          consentUpdates: updatedConsents,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Consentements mis à jour avec succès'),
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

  void _showUserConsentDetails(UserModel user, ConsentModel? consent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails des consentements - ${user.fullName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', user.email),
              _buildDetailRow('Version des consentements', consent?.version ?? 'N/A'),
              _buildDetailRow('Dernière mise à jour', 
                consent != null ? _localizationService.formatDate(consent.lastUpdated) : 'N/A'),
              
              const SizedBox(height: 16),
              const Text(
                'Consentements détaillés:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              if (consent != null)
                ..._consentTypes.map((type) {
                  final consentData = consent.consents[type.key];
                  if (consentData == null) return const SizedBox();
                  
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(type.icon, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  type.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: consentData.granted 
                                      ? (consentData.isValid() ? Colors.green[100] : Colors.orange[100])
                                      : Colors.red[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  consentData.granted
                                      ? (consentData.isValid() ? 'Accordé' : 'Expiré')
                                      : 'Refusé',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: consentData.granted
                                        ? (consentData.isValid() ? Colors.green[800] : Colors.orange[800])
                                        : Colors.red[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (consentData.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              consentData.description,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                          if (consentData.purpose.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'But: ${consentData.purpose}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                          if (consentData.grantedAt != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Accordé le: ${_localizationService.formatDate(consentData.grantedAt!)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                          if (consentData.expiresAt != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Expire le: ${_localizationService.formatDate(consentData.expiresAt!)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: consentData.isExpired() ? Colors.red[600] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                })
              else
                const Text('Aucun consentement enregistré'),
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

  Future<void> _sendConsentReminder(UserModel user) async {
    try {
      // Simuler l'envoi d'un email de rappel
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rappel envoyé à ${user.email}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi du rappel: ${e.toString()}'),
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
      appBar: const AdminAppBar(title: 'Gestion des Consentements RGPD'),
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
