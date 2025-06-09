import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../services/database_service.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/admin_app_bar.dart';
import '../../widgets/admin_drawer.dart';

// Écran de monitoring système en temps réel
class SystemMonitoringScreen extends StatefulWidget {
  const SystemMonitoringScreen({super.key});

  @override
  State<SystemMonitoringScreen> createState() => _SystemMonitoringScreenState();
}

class _SystemMonitoringScreenState extends State<SystemMonitoringScreen> {
  Timer? _refreshTimer;
  bool _isLoading = true;
  Map<String, dynamic> _systemMetrics = {};
  final List<Map<String, dynamic>> _realtimeData = [];
  List<Map<String, dynamic>> _alerts = [];

  @override
  void initState() {
    super.initState();
    _loadSystemMetrics();
    _startRealTimeMonitoring();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Démarrer le monitoring en temps réel
  void _startRealTimeMonitoring() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadSystemMetrics();
    });
  }

  // Charger les métriques système
  Future<void> _loadSystemMetrics() async {
    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      
      // Simuler la récupération de métriques système
      final metrics = await _getSystemMetrics(databaseService);
      
      setState(() {
        _systemMetrics = metrics;
        _isLoading = false;
      });

      // Vérifier les alertes
      _checkForAlerts(metrics);
      
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  // Obtenir les métriques système
  Future<Map<String, dynamic>> _getSystemMetrics(DatabaseService databaseService) async {
    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));
    
    // Métriques de base de données
    final stats = await databaseService.getStatistics();
    
    // Simuler des métriques système supplémentaires
    final cpuUsage = 45.0 + (now.millisecond % 30); // Simulation
    final memoryUsage = 60.0 + (now.second % 25); // Simulation
    final diskUsage = 35.0 + (now.minute % 20); // Simulation
    
    // Métriques de performance
    final responseTime = 120 + (now.millisecond % 80); // ms
    final throughput = 150 + (now.second % 50); // requêtes/min
    
    // Métriques d'erreur
    final errorRate = (now.millisecond % 10) / 10.0; // %
    
    return {
      'timestamp': now,
      'database': stats,
      'system': {
        'cpuUsage': cpuUsage,
        'memoryUsage': memoryUsage,
        'diskUsage': diskUsage,
      },
      'performance': {
        'responseTime': responseTime,
        'throughput': throughput,
        'errorRate': errorRate,
      },
      'connectivity': {
        'activeConnections': 45 + (now.second % 20),
        'queuedRequests': now.second % 5,
      },
    };
  }

  // Vérifier les alertes
  void _checkForAlerts(Map<String, dynamic> metrics) {
    final newAlerts = <Map<String, dynamic>>[];
    
    // Vérifier l'utilisation CPU
    final cpuUsage = metrics['system']['cpuUsage'];
    if (cpuUsage > 80) {
      newAlerts.add({
        'type': 'warning',
        'title': 'Utilisation CPU élevée',
        'message': 'CPU à ${cpuUsage.toStringAsFixed(1)}%',
        'timestamp': DateTime.now(),
      });
    }
    
    // Vérifier l'utilisation mémoire
    final memoryUsage = metrics['system']['memoryUsage'];
    if (memoryUsage > 85) {
      newAlerts.add({
        'type': 'critical',
        'title': 'Mémoire critique',
        'message': 'Mémoire à ${memoryUsage.toStringAsFixed(1)}%',
        'timestamp': DateTime.now(),
      });
    }
    
    // Vérifier le taux d'erreur
    final errorRate = metrics['performance']['errorRate'];
    if (errorRate > 0.05) {
      newAlerts.add({
        'type': 'error',
        'title': 'Taux d\'erreur élevé',
        'message': 'Erreurs à ${(errorRate * 100).toStringAsFixed(1)}%',
        'timestamp': DateTime.now(),
      });
    }

    if (newAlerts.isNotEmpty) {
      setState(() {
        _alerts.insertAll(0, newAlerts);
        // Garder seulement les 50 dernières alertes
        if (_alerts.length > 50) {
          _alerts = _alerts.take(50).toList();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminAppBar(
        title: 'Monitoring Système',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSystemMetrics,
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: Icon(
              _refreshTimer?.isActive == true ? Icons.pause : Icons.play_arrow,
            ),
            onPressed: () {
              if (_refreshTimer?.isActive == true) {
                _refreshTimer?.cancel();
              } else {
                _startRealTimeMonitoring();
              }
              setState(() {});
            },
            tooltip: _refreshTimer?.isActive == true ? 'Pause' : 'Reprendre',
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: _isLoading
          ? const LoadingIndicator(message: 'Chargement des métriques...')
          : RefreshIndicator(
              onRefresh: _loadSystemMetrics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statut général
                    _buildSystemStatus(),
                    
                    const SizedBox(height: 24),
                    
                    // Métriques système
                    _buildSystemMetrics(),
                    
                    const SizedBox(height: 24),
                    
                    // Métriques de performance
                    _buildPerformanceMetrics(),
                    
                    const SizedBox(height: 24),
                    
                    // Alertes récentes
                    _buildAlertsSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Graphiques en temps réel
                    _buildRealTimeCharts(),
                  ],
                ),
              ),
            ),
    );
  }

  // Construire le statut général du système
  Widget _buildSystemStatus() {
    final systemHealth = _calculateSystemHealth();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  systemHealth['icon'],
                  color: systemHealth['color'],
                  size: 32,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statut Système',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: systemHealth['color'],
                      ),
                    ),
                    Text(
                      systemHealth['status'],
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  'Dernière mise à jour: ${DateFormat('HH:mm:ss').format(_systemMetrics['timestamp'] ?? DateTime.now())}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Indicateurs rapides
            Row(
              children: [
                _buildQuickIndicator(
                  'Uptime',
                  '99.9%',
                  Colors.green,
                ),
                _buildQuickIndicator(
                  'Utilisateurs actifs',
                  '${_systemMetrics['connectivity']?['activeConnections'] ?? 0}',
                  AppTheme.primaryColor,
                ),
                _buildQuickIndicator(
                  'Requêtes/min',
                  '${_systemMetrics['performance']?['throughput'] ?? 0}',
                  AppTheme.accentColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Calculer la santé générale du système
  Map<String, dynamic> _calculateSystemHealth() {
    if (_systemMetrics.isEmpty) {
      return {
        'status': 'Chargement...',
        'color': Colors.grey,
        'icon': Icons.hourglass_empty,
      };
    }

    final cpuUsage = _systemMetrics['system']?['cpuUsage'] ?? 0.0;
    final memoryUsage = _systemMetrics['system']?['memoryUsage'] ?? 0.0;
    final errorRate = _systemMetrics['performance']?['errorRate'] ?? 0.0;

    if (cpuUsage > 90 || memoryUsage > 95 || errorRate > 0.1) {
      return {
        'status': 'Critique',
        'color': Colors.red,
        'icon': Icons.error,
      };
    } else if (cpuUsage > 75 || memoryUsage > 80 || errorRate > 0.05) {
      return {
        'status': 'Attention',
        'color': Colors.orange,
        'icon': Icons.warning,
      };
    } else {
      return {
        'status': 'Optimal',
        'color': Colors.green,
        'icon': Icons.check_circle,
      };
    }
  }

  // Construire un indicateur rapide
  Widget _buildQuickIndicator(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Construire les métriques système
  Widget _buildSystemMetrics() {
    final systemData = _systemMetrics['system'] ?? {};
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ressources Système',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            _buildProgressIndicator(
              'CPU',
              systemData['cpuUsage'] ?? 0.0,
              '%',
              _getUsageColor(systemData['cpuUsage'] ?? 0.0),
            ),
            const SizedBox(height: 12),
            
            _buildProgressIndicator(
              'Mémoire',
              systemData['memoryUsage'] ?? 0.0,
              '%',
              _getUsageColor(systemData['memoryUsage'] ?? 0.0),
            ),
            const SizedBox(height: 12),
            
            _buildProgressIndicator(
              'Disque',
              systemData['diskUsage'] ?? 0.0,
              '%',
              _getUsageColor(systemData['diskUsage'] ?? 0.0),
            ),
          ],
        ),
      ),
    );
  }

  // Construire un indicateur de progression
  Widget _buildProgressIndicator(String label, double value, String unit, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('${value.toStringAsFixed(1)}$unit'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  // Obtenir la couleur selon l'utilisation
  Color _getUsageColor(double usage) {
    if (usage > 85) return Colors.red;
    if (usage > 70) return Colors.orange;
    return Colors.green;
  }

  // Construire les métriques de performance
  Widget _buildPerformanceMetrics() {
    final performanceData = _systemMetrics['performance'] ?? {};
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                _buildMetricCard(
                  'Temps de réponse',
                  '${performanceData['responseTime']?.toStringAsFixed(0) ?? '0'} ms',
                  Icons.speed,
                  AppTheme.primaryColor,
                ),
                _buildMetricCard(
                  'Débit',
                  '${performanceData['throughput']?.toStringAsFixed(0) ?? '0'}/min',
                  Icons.trending_up,
                  AppTheme.accentColor,
                ),
                _buildMetricCard(
                  'Taux d\'erreur',
                  '${((performanceData['errorRate'] ?? 0.0) * 100).toStringAsFixed(2)}%',
                  Icons.error_outline,
                  Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Construire une carte de métrique
  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          border: Border.all(color: color.withAlpha(50)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Construire la section des alertes
  Widget _buildAlertsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Alertes Récentes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_alerts.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _alerts.clear()),
                    child: const Text('Effacer tout'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_alerts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Aucune alerte récente',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _alerts.take(5).length,
                itemBuilder: (context, index) {
                  final alert = _alerts[index];
                  return _buildAlertItem(alert);
                },
              ),
          ],
        ),
      ),
    );
  }

  // Construire un élément d'alerte
  Widget _buildAlertItem(Map<String, dynamic> alert) {
    Color alertColor;
    IconData alertIcon;
    
    switch (alert['type']) {
      case 'critical':
        alertColor = Colors.red;
        alertIcon = Icons.error;
        break;
      case 'warning':
        alertColor = Colors.orange;
        alertIcon = Icons.warning;
        break;
      case 'error':
        alertColor = Colors.red;
        alertIcon = Icons.error_outline;
        break;
      default:
        alertColor = Colors.blue;
        alertIcon = Icons.info;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: alertColor.withAlpha(20),
        border: Border(left: BorderSide(color: alertColor, width: 4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(alertIcon, color: alertColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['title'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: alertColor,
                  ),
                ),
                Text(alert['message']),
              ],
            ),
          ),
          Text(
            DateFormat('HH:mm').format(alert['timestamp']),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Construire les graphiques en temps réel
  Widget _buildRealTimeCharts() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Graphiques Temps Réel',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Placeholder pour les graphiques
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Graphiques en temps réel\n(À implémenter avec fl_chart)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
