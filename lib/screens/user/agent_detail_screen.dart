import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/agent_model.dart';
import '../../models/review_model.dart';
import '../../services/database_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/review_card.dart';

// Écran de détail d'un agent
class AgentDetailScreen extends StatefulWidget {
  final String agentId;

  const AgentDetailScreen({super.key, required this.agentId});

  @override
  State<AgentDetailScreen> createState() => _AgentDetailScreenState();
}

class _AgentDetailScreenState extends State<AgentDetailScreen> {
  // État
  AgentModel? _agent;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAgentDetails();
  }

  // Charger les détails de l'agent
  Future<void> _loadAgentDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final databaseService = Provider.of<DatabaseService>(
        context,
        listen: false,
      );
      final agent = await databaseService.getAgent(widget.agentId);

      if (mounted) {
        setState(() {
          _agent = agent;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // Réserver l'agent
  void _bookAgent() {
    if (_agent != null) {
      context.go('/reservation/${_agent!.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const LoadingIndicator(message: 'Chargement du profil...')
              : _errorMessage != null
              ? ErrorMessage(
                message: 'Erreur: $_errorMessage',
                onRetry: _loadAgentDetails,
              )
              : _agent == null
              ? const ErrorMessage(message: 'Agent introuvable')
              : _buildAgentDetails(),
    );
  }

  Widget _buildAgentDetails() {
    final databaseService = Provider.of<DatabaseService>(context);

    return CustomScrollView(
      slivers: [
        // AppBar avec image de profil
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: const FlexibleSpaceBar(
            background: AgentImage(fit: BoxFit.cover),
          ),
          actions: [
            // Bouton de partage
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                // Implémenter le partage
              },
            ),
          ],
        ),

        // Contenu principal
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom et badge certifié
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _agent!.fullName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_agent!.isCertified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.infoColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.infoColor),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              color: AppTheme.infoColor,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Certifié',
                              style: TextStyle(
                                color: AppTheme.infoColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // Profession
                Text(
                  _agent!.profession,
                  style: const TextStyle(
                    color: AppTheme.mediumColor,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 8),

                // Matricule
                Row(
                  children: [
                    const Icon(
                      Icons.badge_outlined,
                      size: 16,
                      color: AppTheme.mediumColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Matricule: ${_agent!.matricule}',
                      style: const TextStyle(
                        color: AppTheme.mediumColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Évaluation
                RatingDisplay(
                  rating: _agent!.averageRating,
                  ratingCount: _agent!.ratingCount,
                  size: 24,
                ),

                const SizedBox(height: 24),

                // Bouton de réservation
                if (_agent!.isAvailable)
                  PrimaryButton(
                    text: AppConstants.bookAgent,
                    onPressed: _bookAgent,
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.errorColor),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: AppTheme.errorColor),
                        SizedBox(width: 8),
                        Text(
                          'Agent non disponible actuellement',
                          style: TextStyle(
                            color: AppTheme.errorColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Section Informations
                const Text(
                  AppConstants.agentInfo,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildInfoCard(),

                const SizedBox(height: 24),

                // Section Antécédents
                const Text(
                  AppConstants.agentBackground,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildBackgroundCard(),

                const SizedBox(height: 24),

                // Section Avis et commentaires
                const Text(
                  AppConstants.agentReviews,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // Liste des avis
        StreamBuilder<List<ReviewModel>>(
          stream: databaseService.getAgentReviews(_agent!.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SliverToBoxAdapter(
                child: LoadingIndicator(message: 'Chargement des avis...'),
              );
            }

            if (snapshot.hasError) {
              return SliverToBoxAdapter(
                child: ErrorMessage(
                  message:
                      'Erreur lors du chargement des avis: ${snapshot.error}',
                ),
              );
            }

            final reviews = snapshot.data ?? [];

            if (reviews.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: EmptyMessage(
                    message: 'Aucun avis pour le moment',
                    icon: Icons.comment_outlined,
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ReviewCard(review: reviews[index]),
                  childCount: reviews.length,
                ),
              ),
            );
          },
        ),

        // Espace en bas
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  // Carte d'informations
  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow('Âge', '${_agent!.age} ans'),
            const Divider(),
            _buildInfoRow('Genre', _agent!.gender == 'M' ? 'Homme' : 'Femme'),
            const Divider(),
            _buildInfoRow('Groupe sanguin', _agent!.bloodType),
            const Divider(),
            _buildInfoRow('Niveau d\'études', _agent!.educationLevel),
            const Divider(),
            _buildInfoRow('Matricule', _agent!.matricule),
          ],
        ),
      ),
    );
  }

  // Carte d'antécédents
  Widget _buildBackgroundCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _agent!.background,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
      ),
    );
  }

  // Ligne d'information
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.mediumColor, fontSize: 14),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
