import 'package:bee_app/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/agent_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../utils/constants.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/simple_app_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Écran de liste des agents disponibles
class AgentsListScreen extends StatefulWidget {
  const AgentsListScreen({super.key});

  @override
  State<AgentsListScreen> createState() => _AgentsListScreenState();
}

class _AgentsListScreenState extends State<AgentsListScreen> {
  // État
  bool _showOnlyAvailable = true;
  bool _showOnlyCertified = false;
  String _searchQuery = '';
  String? _selectedProfession;
  late final TextEditingController _searchController;
  bool _isSearchingByMatricule = false;
  bool _isLoading = false;
  List<String> _availableProfessions = [];

  final Query _baseQuery = FirebaseFirestore.instance
      .collection('agents')
      .orderBy('fullName')
      .limit(20);

  DocumentSnapshot? _lastDoc;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadProfessions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Charger les professions disponibles
  Future<void> _loadProfessions() async {
    try {
      final databaseService = Provider.of<DatabaseService>(
        context,
        listen: false,
      );
      final professions = await databaseService.getAvailableProfessions();

      if (mounted) {
        setState(() {
          _availableProfessions = professions;
        });
      }
    } catch (e) {
      // Ignorer les erreurs
    }
  }

  // Filtrer les agents
  List<AgentModel> _filterAgents(List<AgentModel> agents) {
    // Appliquer les filtres de base (certification et profession)
    List<AgentModel> filteredAgents =
        agents.where((agent) {
          // Filtre par certification
          if (_showOnlyCertified && !agent.isCertified) {
            return false;
          }

          // Filtre par profession
          if (_selectedProfession != null &&
              agent.profession != _selectedProfession) {
            return false;
          }

          return true;
        }).toList();

    // Si pas de recherche, retourner les agents filtrés
    if (_searchQuery.isEmpty) {
      return filteredAgents;
    }

    // Si la recherche commence par "MAT:" ou "#", considérer comme une recherche par matricule
    if (_searchQuery.startsWith("MAT:") || _searchQuery.startsWith("#")) {
      final matricule =
          _searchQuery.startsWith("MAT:")
              ? _searchQuery.substring(4).trim().toLowerCase()
              : _searchQuery.substring(1).trim().toLowerCase();

      if (matricule.isEmpty) return filteredAgents;

      _isSearchingByMatricule = true;
      return filteredAgents
          .where(
            (agent) =>
                agent.matricule.toLowerCase() == matricule ||
                agent.matricule.toLowerCase().contains(matricule),
          )
          .toList();
    }

    // Recherche standard
    _isSearchingByMatricule = false;
    final query = _searchQuery.toLowerCase();
    return filteredAgents.where((agent) {
      return agent.fullName.toLowerCase().contains(query) ||
          agent.profession.toLowerCase().contains(query) ||
          agent.matricule.toLowerCase().contains(query);
    }).toList();
  }

  // Rechercher un agent par matricule exact
  Future<void> _searchAgentByExactMatricule(String matricule) async {
    if (matricule.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final databaseService = Provider.of<DatabaseService>(
        context,
        listen: false,
      );
      final agent = await databaseService.getAgentByMatricule(matricule);

      if (agent != null && mounted) {
        // Naviguer directement vers la page de détail de l'agent
        context.go('/agent/${agent.id}');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun agent trouvé avec ce matricule exact'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la recherche: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Se déconnecter
  Future<void> _signOut() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();

      if (mounted) {
        context.go('/auth');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Obtenir le flux d'agents en fonction des filtres
  Stream<List<AgentModel>> _getAgentsStream(DatabaseService databaseService) {
    if (_showOnlyAvailable && _showOnlyCertified) {
      return databaseService.getAvailableCertifiedAgents();
    } else if (_showOnlyAvailable) {
      return databaseService.getAvailableAgents();
    } else if (_showOnlyCertified) {
      return databaseService.getCertifiedAgents();
    } else {
      return databaseService.getAgents();
    }
  }

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: SimpleAppBar(
        title: AppConstants.agentsTitle,
        icon: Icons.security,
        actions: [
          // Bouton de filtre avancé
          IconButton(
            icon: const Icon(Icons.filter_alt, size: 22),
            tooltip: 'Filtres avancés',
            onPressed: () {
              _showFilterDialog();
            },
          ),
          // Menu pour se déconnecter
          PopupMenuButton(
            icon: Icon(Icons.more_vert, color: Colors.grey[700], size: 22),
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'logout',
                    child: const Text(AppConstants.logout),
                  ),
                ],
            onSelected: (value) {
              if (value == 'logout') {
                _signOut();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // En-tête avec barre de recherche et filtre
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withAlpha(13),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Barre de recherche
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText:
                                    'Rechercher par nom, profession ou matricule...',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon:
                                    _searchQuery.isNotEmpty
                                        ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (_searchQuery.startsWith("#") ||
                                                _searchQuery.startsWith("MAT:"))
                                              IconButton(
                                                icon: const Icon(Icons.search),
                                                tooltip:
                                                    'Rechercher par matricule exact',
                                                onPressed: () {
                                                  final matricule =
                                                      _searchQuery.startsWith(
                                                            "MAT:",
                                                          )
                                                          ? _searchQuery
                                                              .substring(4)
                                                              .trim()
                                                          : _searchQuery
                                                              .substring(1)
                                                              .trim();
                                                  _searchAgentByExactMatricule(
                                                    matricule,
                                                  );
                                                },
                                              ),
                                            IconButton(
                                              icon: const Icon(Icons.clear),
                                              onPressed: () {
                                                _searchController.clear();
                                                setState(() {
                                                  _searchQuery = '';
                                                });
                                              },
                                            ),
                                          ],
                                        )
                                        : null,
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).primaryColor,
                                    width: 1,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Astuce: Utilisez "#" ou "MAT:" suivi du matricule pour une recherche précise',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),

                        // Filtre pour afficher uniquement les agents disponibles
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _showOnlyAvailable
                                    ? 'Affichage des agents disponibles uniquement'
                                    : 'Affichage de tous les agents',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Filtres actifs
                  if (_showOnlyCertified || _selectedProfession != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: _buildActiveFilters()),
                      ),
                    ),

                  // Filtres rapides
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Filtre pour les agents disponibles
                          FilterChip(
                            label: const Text('Disponibles'),
                            selected: _showOnlyAvailable,
                            onSelected: (selected) {
                              setState(() {
                                _showOnlyAvailable = selected;
                              });
                            },
                            avatar: Icon(
                              Icons.event_available,
                              color:
                                  _showOnlyAvailable
                                      ? Colors.white
                                      : Colors.grey,
                              size: 18,
                            ),
                            backgroundColor: Colors.grey[200],
                            selectedColor: Colors.green,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color:
                                  _showOnlyAvailable
                                      ? Colors.white
                                      : Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Filtre pour les agents certifiés
                          FilterChip(
                            label: const Text('Certifiés'),
                            selected: _showOnlyCertified,
                            onSelected: (selected) {
                              setState(() {
                                _showOnlyCertified = selected;
                              });
                            },
                            avatar: Icon(
                              Icons.verified,
                              color:
                                  _showOnlyCertified
                                      ? Colors.white
                                      : Colors.grey,
                              size: 18,
                            ),
                            backgroundColor: Colors.grey[200],
                            selectedColor: Theme.of(context).primaryColor,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color:
                                  _showOnlyCertified
                                      ? Colors.white
                                      : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Liste des agents
                  Expanded(
                    child: StreamBuilder<List<AgentModel>>(
                      stream: _getAgentsStream(databaseService),
                      builder: (context, snapshot) {
                        // Afficher un indicateur de chargement
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const LoadingIndicator(
                            message: 'Chargement des agents...',
                          );
                        }

                        // Afficher un message d'erreur
                        if (snapshot.hasError) {
                          return ErrorMessage(
                            message:
                                'Erreur lors du chargement des agents: ${snapshot.error}',
                            onRetry: () => setState(() {}),
                          );
                        }

                        // Récupérer et filtrer les agents
                        final agents = snapshot.data ?? [];
                        final filteredAgents = _filterAgents(agents);

                        // Afficher un message si aucun agent n'est trouvé
                        if (filteredAgents.isEmpty) {
                          return EmptyMessage(
                            message:
                                _searchQuery.isNotEmpty
                                    ? 'Aucun agent ne correspond à votre recherche'
                                    : _showOnlyAvailable
                                    ? 'Aucun agent disponible pour le moment'
                                    : 'Aucun agent trouvé',
                            icon: Icons.person_off,
                          );
                        }

                        // Afficher la liste des agents
                        return _buildAgentsList(filteredAgents);
                      },
                    ),
                  ),
                ],
              ),
    );
  }

  // Construire la liste des agents avec une grille ou une liste selon l'orientation
  Widget _buildAgentsList(List<AgentModel> agents) {
    // Détecter l'orientation de l'écran
    final orientation = MediaQuery.of(context).orientation;

    // Utiliser une grille en mode paysage, une liste en mode portrait
    if (orientation == Orientation.landscape) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: agents.length,
        itemBuilder: (context, index) {
          final agent = agents[index];
          return _buildAgentGridItem(agent);
        },
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: agents.length,
        itemBuilder: (context, index) {
          final agent = agents[index];
          return _buildAgentListItem(agent);
        },
      );
    }
  }

  // Construire un élément de la liste des agents (vue liste)
  Widget _buildAgentListItem(AgentModel agent) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () => context.go('/agent/${agent.id}'),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image de l'agent avec URL Firebase
            SizedBox(
              width: 120,
              height: 140,
              child: AgentImage(
                agentId: agent.id,
                imageUrl: agent.profileImageUrl,
                width: 120,
                height: 140,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            // Informations de l'agent
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom et badge certifié
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            agent.fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (agent.isCertified)
                          Icon(
                            Icons.verified,
                            size: 16,
                            color: AppTheme.infoColor,
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Profession
                    Text(
                      agent.profession,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),

                    const SizedBox(height: 4),

                    // Matricule
                    Row(
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Matricule: ${agent.matricule}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Disponibilité
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            agent.isAvailable
                                ? Colors.green.withAlpha(25)
                                : Colors.red.withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        agent.isAvailable ? 'Disponible' : 'Indisponible',
                        style: TextStyle(
                          color: agent.isAvailable ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Évaluation
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          if (index < agent.averageRating.floor()) {
                            return const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            );
                          } else if (index < agent.averageRating) {
                            return const Icon(
                              Icons.star_half,
                              size: 16,
                              color: Colors.amber,
                            );
                          } else {
                            return const Icon(
                              Icons.star_border,
                              size: 16,
                              color: Colors.amber,
                            );
                          }
                        }),
                        const SizedBox(width: 4),
                        Text(
                          '${agent.averageRating.toStringAsFixed(1)} (${agent.ratingCount})',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Flèche de navigation
            Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Construire un élément de la grille des agents (vue grille)
  Widget _buildAgentGridItem(AgentModel agent) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () => context.go('/agent/${agent.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image de l'agent avec URL Firebase
            Stack(
              children: [
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: AgentImage(
                    agentId: agent.id,
                    imageUrl: agent.profileImageUrl,
                    height: 140,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),

                // Badge de disponibilité
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: agent.isAvailable ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      agent.isAvailable ? 'Disponible' : 'Indisponible',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Badge certifié
                if (agent.isCertified)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.verified,
                        size: 16,
                        color: AppTheme.infoColor,
                      ),
                    ),
                  ),
              ],
            ),

            // Informations de l'agent
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom
                  Text(
                    agent.fullName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Profession
                  Text(
                    agent.profession,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Matricule
                  Row(
                    children: [
                      Icon(
                        Icons.badge_outlined,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Matricule: ${agent.matricule}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Évaluation
                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${agent.averageRating.toStringAsFixed(1)} (${agent.ratingCount})',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Construire les filtres actifs
  List<Widget> _buildActiveFilters() {
    final List<Widget> filters = [];

    // Filtre de profession
    if (_selectedProfession != null) {
      filters.add(
        Chip(
          label: Text(_selectedProfession!),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: () => setState(() => _selectedProfession = null),
          backgroundColor: Colors.blue.withAlpha(50),
        ),
      );
    }

    return filters;
  }

  // Afficher le dialogue de filtres
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Filtres avancés'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filtre par disponibilité
                      SwitchListTile(
                        title: const Text('Agents disponibles'),
                        value: _showOnlyAvailable,
                        onChanged: (value) {
                          setState(() => _showOnlyAvailable = value);
                        },
                      ),

                      // Filtre par certification
                      SwitchListTile(
                        title: const Text('Agents certifiés'),
                        value: _showOnlyCertified,
                        onChanged: (value) {
                          setState(() => _showOnlyCertified = value);
                        },
                      ),

                      const Divider(),

                      // Filtre par profession
                      const Text(
                        'Profession:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      if (_availableProfessions.isEmpty)
                        const Text(
                          'Chargement des professions...',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        )
                      else
                        DropdownButton<String?>(
                          value: _selectedProfession,
                          isExpanded: true,
                          hint: const Text('Toutes les professions'),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Toutes les professions'),
                            ),
                            ..._availableProfessions.map(
                              (profession) => DropdownMenuItem<String?>(
                                value: profession,
                                child: Text(profession),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedProfession = value);
                          },
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      // Réinitialiser les filtres
                      setState(() {
                        _showOnlyAvailable = true;
                        _showOnlyCertified = false;
                        _selectedProfession = null;
                      });
                    },
                    child: const Text('Réinitialiser'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Appliquer les filtres et fermer le dialogue
                      Navigator.pop(context);
                      this.setState(() {});
                    },
                    child: const Text('Appliquer'),
                  ),
                ],
              );
            },
          ),
    );
  }
}
