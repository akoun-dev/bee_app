import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/agent_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../utils/constants.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/simple_app_bar.dart';


// Écran de liste des agents disponibles
class AgentsListScreen extends StatefulWidget {
  const AgentsListScreen({super.key});

  @override
  State<AgentsListScreen> createState() => _AgentsListScreenState();
}

class _AgentsListScreenState extends State<AgentsListScreen> {
  // État
  bool _showOnlyAvailable = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filtrer les agents
  List<AgentModel> _filterAgents(List<AgentModel> agents) {
    if (_searchQuery.isEmpty) {
      return agents;
    }

    final query = _searchQuery.toLowerCase();
    return agents.where((agent) {
      return agent.fullName.toLowerCase().contains(query) ||
             agent.profession.toLowerCase().contains(query);
    }).toList();
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

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: SimpleAppBar(
        title: AppConstants.agentsTitle,
        icon: Icons.security,
        actions: [
          // Bouton de filtre
          IconButton(
            icon: Icon(
              _showOnlyAvailable ? Icons.filter_list : Icons.filter_list_off,
              color: _showOnlyAvailable ? Theme.of(context).primaryColor : Colors.grey[700],
              size: 22,
            ),
            tooltip: 'Filtrer les agents disponibles',
            onPressed: () {
              setState(() {
                _showOnlyAvailable = !_showOnlyAvailable;
              });
            },
          ),
          // Menu pour se déconnecter
          PopupMenuButton(
            icon: Icon(
              Icons.more_vert,
              color: Colors.grey[700],
              size: 22,
            ),
            itemBuilder: (context) => [
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
      body: Column(
        children: [
          // En-tête avec barre de recherche et filtre
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Barre de recherche
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un agent par nom ou profession...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
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

          // Liste des agents
          Expanded(
            child: StreamBuilder<List<AgentModel>>(
              stream: _showOnlyAvailable
                  ? databaseService.getAvailableAgents()
                  : databaseService.getAgents(),
              builder: (context, snapshot) {
                // Afficher un indicateur de chargement
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator(
                    message: 'Chargement des agents...',
                  );
                }

                // Afficher un message d'erreur
                if (snapshot.hasError) {
                  return ErrorMessage(
                    message: 'Erreur lors du chargement des agents: ${snapshot.error}',
                    onRetry: () => setState(() {}),
                  );
                }

                // Récupérer et filtrer les agents
                final agents = snapshot.data ?? [];
                final filteredAgents = _filterAgents(agents);

                // Afficher un message si aucun agent n'est trouvé
                if (filteredAgents.isEmpty) {
                  return EmptyMessage(
                    message: _searchQuery.isNotEmpty
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () => context.go('/agent/${agent.id}'),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image de l'agent
            SizedBox(
              width: 120,
              height: 140,
              child: agent.profileImageUrl != null
                  ? Image.network(
                      agent.profileImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.grey,
                      ),
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
                            color: Theme.of(context).primaryColor,
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Profession
                    Text(
                      agent.profession,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Disponibilité
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: agent.isAvailable
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
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
                          return Icon(
                            index < agent.averageRating.floor()
                                ? Icons.star
                                : index < agent.averageRating
                                    ? Icons.star_half
                                    : Icons.star_border,
                            size: 16,
                            color: Colors.amber,
                          );
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () => context.go('/agent/${agent.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image de l'agent
            Stack(
              children: [
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: agent.profileImageUrl != null
                      ? Image.network(
                          agent.profileImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.grey,
                          ),
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
                      color: agent.isAvailable
                          ? Colors.green
                          : Colors.red,
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
                        color: Theme.of(context).primaryColor,
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
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Évaluation
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 14,
                        color: Colors.amber,
                      ),
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
          ],
        ),
      ),
    );
  }
}
