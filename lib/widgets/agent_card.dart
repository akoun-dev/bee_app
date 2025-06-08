import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/agent_model.dart';
import '../utils/theme.dart';
import 'common_widgets.dart';

// Widget pour afficher une carte d'agent dans la liste
class AgentCard extends StatelessWidget {
  final AgentModel agent;
  final VoidCallback? onTap;
  final bool isCompact;

  const AgentCard({
    super.key,
    required this.agent,
    this.onTap,
    Widget? trailing,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return isCompact ? _buildCompactCard(context) : _buildFullCard(context);
  }

  // Version complète de la carte d'agent
  Widget _buildFullCard(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => context.go('/agent/${agent.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image de l'agent
            const SizedBox(
              height: 180,
              width: double.infinity,
              child: AgentImage(height: 180, fit: BoxFit.cover),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (agent.isCertified)
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
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Certifié',
                                style: TextStyle(
                                  color: AppTheme.infoColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
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
                    agent.profession,
                    style: const TextStyle(
                      color: AppTheme.mediumColor,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Informations de base
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          Icons.person_outline,
                          '${agent.age} ans',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoItem(
                          Icons.bloodtype_outlined,
                          agent.bloodType,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoItem(
                          agent.gender == 'M'
                              ? Icons.male_outlined
                              : Icons.female_outlined,
                          agent.gender == 'M' ? 'Homme' : 'Femme',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Évaluation
                  RatingDisplay(
                    rating: agent.averageRating,
                    ratingCount: agent.ratingCount,
                  ),

                  const SizedBox(height: 16),

                  // Bouton Voir le profil
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          onTap ?? () => context.go('/agent/${agent.id}'),
                      child: const Text('Voir le profil'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Version compacte de la carte d'agent pour le tableau de bord
  Widget _buildCompactCard(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap ?? () => context.go('/agent/${agent.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image de l'agent (encore plus petite)
            const SizedBox(
              height: 100,
              width: double.infinity,
              child: AgentImage(height: 100, fit: BoxFit.cover),
            ),

            // Informations de l'agent
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nom
                  Text(
                    agent.fullName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 2),

                  // Profession
                  Text(
                    agent.profession,
                    style: const TextStyle(
                      color: AppTheme.mediumColor,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Évaluation (encore plus petite)
                  RatingDisplay(
                    rating: agent.averageRating,
                    ratingCount: agent.ratingCount,
                    size: 12,
                    showCount: false,
                  ),

                  const SizedBox(height: 4),

                  // Bouton Voir le profil (encore plus petit)
                  SizedBox(
                    width: double.infinity,
                    height: 24,
                    child: ElevatedButton(
                      onPressed:
                          onTap ?? () => context.go('/agent/${agent.id}'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 0,
                        ),
                        textStyle: const TextStyle(fontSize: 10),
                        minimumSize: const Size(0, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Voir le profil'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.mediumColor),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppTheme.mediumColor),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
