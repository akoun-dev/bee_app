import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/agent_model.dart';
import '../../services/recommendation_service.dart';
import '../../utils/theme.dart';
import '../../widgets/agent_card.dart';
import '../../widgets/common_widgets.dart';

// Écran de recommandations personnalisées
class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  bool _isLoading = true;
  List<AgentModel> _favoriteAgents = [];
  List<AgentModel> _recommendedAgents = [];
  String? _currentUserId;
  
  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }
  
  // Charger les recommandations
  Future<void> _loadRecommendations() async {
    setState(() => _isLoading = true);
    
    try {
      // Récupérer l'ID de l'utilisateur actuel
      final user = Provider.of<User?>(context, listen: false);
      
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      _currentUserId = user.uid;
      
      // Récupérer les services
      final recommendationService = Provider.of<RecommendationService>(context, listen: false);
      
      // Mettre à jour les préférences de catégorie basées sur l'historique
      await recommendationService.updateCategoryPreferences(_currentUserId!);
      
      // Récupérer les agents favoris
      final favoriteAgents = await recommendationService.getFavoriteAgents(_currentUserId!);
      
      // Récupérer les agents recommandés
      final recommendedAgents = await recommendationService.getRecommendedAgents(_currentUserId!);
      
      if (mounted) {
        setState(() {
          _favoriteAgents = favoriteAgents;
          _recommendedAgents = recommendedAgents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
        setState(() => _isLoading = false);
      }
    }
  }
  
  // Gérer l'ajout/suppression des favoris
  Future<void> _toggleFavorite(String agentId) async {
    if (_currentUserId == null) return;
    
    try {
      final recommendationService = Provider.of<RecommendationService>(context, listen: false);
      
      await recommendationService.toggleFavoriteAgent(_currentUserId!, agentId);
      
      // Recharger les données
      await _loadRecommendations();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommandations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecommendations,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
        ? const LoadingIndicator(message: 'Chargement des recommandations...')
        : RefreshIndicator(
            onRefresh: _loadRecommendations,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section des favoris
                  _buildFavoritesSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Section des recommandations
                  _buildRecommendationsSection(),
                ],
              ),
            ),
          ),
    );
  }
  
  // Construire la section des favoris
  Widget _buildFavoritesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Vos favoris',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_favoriteAgents.isNotEmpty)
              TextButton(
                onPressed: () {
                  // Navigation vers une vue complète des favoris
                },
                child: const Text('Voir tout'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        
        if (_favoriteAgents.isEmpty)
          const EmptyMessage(
            message: 'Vous n\'avez pas encore d\'agents favoris',
            icon: Icons.favorite_border,
          )
        else
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _favoriteAgents.length,
              itemBuilder: (context, index) {
                final agent = _favoriteAgents[index];
                return SizedBox(
                  width: 180,
                  child: Card(
                    margin: const EdgeInsets.only(right: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () => context.go('/agent/${agent.id}'),
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Avatar
                                Center(
                                  child: UserAvatar(
                                    imageUrl: agent.profileImageUrl,
                                    name: agent.fullName,
                                    size: 70,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                
                                // Nom
                                Text(
                                  agent.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                
                                // Profession
                                Text(
                                  agent.profession,
                                  style: TextStyle(
                                    color: AppTheme.mediumColor,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                
                                const SizedBox(height: 8),
                                
                                // Note
                                RatingDisplay(
                                  rating: agent.averageRating,
                                  ratingCount: agent.ratingCount,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                          
                          // Bouton favori
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(
                                Icons.favorite,
                                color: AppTheme.accentColor,
                              ),
                              onPressed: () => _toggleFavorite(agent.id),
                              tooltip: 'Retirer des favoris',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
  
  // Construire la section des recommandations
  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommandés pour vous',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        if (_recommendedAgents.isEmpty)
          const EmptyMessage(
            message: 'Aucune recommandation disponible pour le moment',
            icon: Icons.recommend,
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recommendedAgents.length,
            itemBuilder: (context, index) {
              final agent = _recommendedAgents[index];
              return AgentCard(
                agent: agent,
                onTap: () => context.go('/agent/${agent.id}'),
                trailing: IconButton(
                  icon: Icon(
                    _favoriteAgents.any((a) => a.id == agent.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: _favoriteAgents.any((a) => a.id == agent.id)
                        ? AppTheme.accentColor
                        : AppTheme.mediumColor,
                  ),
                  onPressed: () => _toggleFavorite(agent.id),
                  tooltip: _favoriteAgents.any((a) => a.id == agent.id)
                      ? 'Retirer des favoris'
                      : 'Ajouter aux favoris',
                ),
              );
            },
          ),
      ],
    );
  }
}
