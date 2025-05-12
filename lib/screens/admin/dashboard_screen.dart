import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../models/agent_model.dart';
import '../../services/database_service.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/admin_app_bar.dart';
import '../../widgets/admin_drawer.dart';

// Écran de tableau de bord analytique pour les administrateurs
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Données pour les graphiques et statistiques
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  String _selectedPeriod = 'month'; // 'week', 'month', 'year'

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  // Charger les statistiques depuis la base de données
  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final stats = await databaseService.getStatistics();

      // Simuler des données supplémentaires pour les graphiques
      // Dans une application réelle, ces données viendraient de la base de données
      final Map<String, dynamic> enhancedStats = {
        ...stats,
        'monthlyReservations': _generateMonthlyReservationsData(),
        'monthlyRevenue': _generateMonthlyRevenueData(),
        'topAgents': await _getTopAgents(databaseService),
      };

      setState(() {
        _statistics = enhancedStats;
        _isLoading = false;
      });
    } catch (e) {
      // Gérer l'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des statistiques: ${e.toString()}')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  // Générer des données de réservations mensuelles pour le graphique
  List<Map<String, dynamic>> _generateMonthlyReservationsData() {
    final List<Map<String, dynamic>> data = [];
    final now = DateTime.now();

    for (int i = 5; i >= 0; i--) {
      final month = now.month - i;
      final year = now.year + (month <= 0 ? -1 : 0);
      final adjustedMonth = month <= 0 ? month + 12 : month;

      final monthName = DateFormat('MMM').format(DateTime(year, adjustedMonth));

      // Valeurs aléatoires pour la démonstration
      final pending = 5 + (adjustedMonth % 7);
      final approved = 10 + (adjustedMonth % 5);
      final completed = 8 + (adjustedMonth % 9);

      data.add({
        'month': monthName,
        'pending': pending,
        'approved': approved,
        'completed': completed,
        'total': pending + approved + completed,
      });
    }

    return data;
  }

  // Générer des données de revenus mensuels pour le graphique
  List<Map<String, dynamic>> _generateMonthlyRevenueData() {
    final List<Map<String, dynamic>> data = [];
    final now = DateTime.now();

    for (int i = 5; i >= 0; i--) {
      final month = now.month - i;
      final year = now.year + (month <= 0 ? -1 : 0);
      final adjustedMonth = month <= 0 ? month + 12 : month;

      final monthName = DateFormat('MMM').format(DateTime(year, adjustedMonth));

      // Valeurs aléatoires pour la démonstration
      final revenue = 5000 + (adjustedMonth * 1000) + (adjustedMonth % 3) * 500;

      data.add({
        'month': monthName,
        'revenue': revenue,
      });
    }

    return data;
  }

  // Récupérer les meilleurs agents
  Future<List<Map<String, dynamic>>> _getTopAgents(DatabaseService databaseService) async {
    try {
      final agents = await databaseService.getAgents().first;

      // Trier les agents par note
      agents.sort((a, b) => b.averageRating.compareTo(a.averageRating));

      // Prendre les 5 premiers
      final topAgents = agents.take(5).map((agent) => {
        'agent': agent,
        'reservations': 10 + (agent.id.hashCode % 20), // Simulé pour la démonstration
        'revenue': 2000 + (agent.id.hashCode % 5) * 1000, // Simulé pour la démonstration
      }).toList();

      return topAgents;
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminAppBar(
        title: 'Tableau de bord',
        actions: [
          // Sélecteur de période
          DropdownButton<String>(
            value: _selectedPeriod,
            items: const [
              DropdownMenuItem(value: 'week', child: Text('Semaine')),
              DropdownMenuItem(value: 'month', child: Text('Mois')),
              DropdownMenuItem(value: 'year', child: Text('Année')),
            ],
            onChanged: (value) {
              setState(() => _selectedPeriod = value!);
              _loadStatistics();
            },
            underline: Container(),
            icon: const Icon(Icons.calendar_today),
          ),
          const SizedBox(width: 8),
          // Bouton d'actualisation
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: _isLoading
        ? const LoadingIndicator(message: 'Chargement des statistiques...')
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cartes de statistiques principales
                _buildStatisticsCards(),

                const SizedBox(height: 24),

                // Graphique des réservations par mois
                _buildReservationsChart(),

                const SizedBox(height: 24),

                // Graphique des revenus
                _buildRevenueChart(),

                const SizedBox(height: 24),

                // Top agents
                _buildTopAgentsSection(),
              ],
            ),
          ),
    );
  }

  // Construire les cartes de statistiques principales
  Widget _buildStatisticsCards() {
    final formatter = NumberFormat('#,###');

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          title: 'Utilisateurs',
          value: formatter.format(_statistics['usersCount'] ?? 0),
          icon: Icons.people,
          color: AppTheme.primaryColor,
        ),
        _buildStatCard(
          title: 'Agents',
          value: formatter.format(_statistics['agentsCount'] ?? 0),
          icon: Icons.security,
          color: AppTheme.secondaryColor,
        ),
        _buildStatCard(
          title: 'Réservations',
          value: formatter.format(_statistics['reservationsCount'] ?? 0),
          icon: Icons.calendar_today,
          color: AppTheme.accentColor,
        ),
        _buildStatCard(
          title: 'En attente',
          value: formatter.format(_statistics['pendingCount'] ?? 0),
          icon: Icons.pending_actions,
          color: Colors.orange,
        ),
      ],
    );
  }

  // Construire une carte de statistique
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withAlpha(50), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Construire le graphique des réservations
  Widget _buildReservationsChart() {
    final data = _statistics['monthlyReservations'] as List<Map<String, dynamic>>? ?? [];

    if (data.isEmpty) {
      return const EmptyMessage(
        message: 'Aucune donnée disponible pour les réservations',
        icon: Icons.bar_chart,
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Réservations par mois',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: data.fold(0, (max, item) =>
                    item['total'] > max ? item['total'] : max) * 1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value < 0 || value >= data.length) return const Text('');
                          return Text(
                            data[value.toInt()]['month'],
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(data.length, (index) {
                    final item = data[index];
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: item['total'].toDouble(),
                          color: AppTheme.primaryColor,
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Construire le graphique des revenus
  Widget _buildRevenueChart() {
    final data = _statistics['monthlyRevenue'] as List<Map<String, dynamic>>? ?? [];

    if (data.isEmpty) {
      return const EmptyMessage(
        message: 'Aucune donnée disponible pour les revenus',
        icon: Icons.bar_chart,
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenus par mois (€)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(enabled: false),
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value < 0 || value >= data.length) return const Text('');
                          return Text(
                            data[value.toInt()]['month'],
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${(value / 1000).toInt()}k',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(data.length, (index) {
                        return FlSpot(index.toDouble(), data[index]['revenue'].toDouble());
                      }),
                      isCurved: true,
                      color: AppTheme.accentColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.accentColor.withAlpha(50),
                      ),
                    ),
                  ],
                  minY: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Construire la section des meilleurs agents
  Widget _buildTopAgentsSection() {
    final topAgents = _statistics['topAgents'] as List<Map<String, dynamic>>? ?? [];

    if (topAgents.isEmpty) {
      return const EmptyMessage(
        message: 'Aucune donnée disponible pour les agents',
        icon: Icons.people,
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top 5 des agents',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...topAgents.map((item) {
              final agent = item['agent'] as AgentModel;
              return ListTile(
                leading: UserAvatar(
                  imageUrl: agent.profileImageUrl,
                  name: agent.fullName,
                ),
                title: Text(agent.fullName),
                subtitle: RatingDisplay(
                  rating: agent.averageRating,
                  ratingCount: agent.ratingCount,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${item['reservations']} réservations',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      '${NumberFormat('#,###').format(item['revenue'])} €',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentColor,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
