import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/agent_model.dart';
import '../../models/reservation_model.dart';
import '../../models/audit_log_model.dart';
import '../../models/data_deletion_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/audit_service.dart';
import '../../services/consent_service.dart';
import '../../services/data_deletion_service.dart';
import '../../services/localization_service.dart';
import '../../services/authorization_service.dart';
import '../../widgets/admin_app_bar.dart';
import '../../widgets/admin_drawer.dart';

class EnhancedAdminDashboardScreen extends StatefulWidget {
  const EnhancedAdminDashboardScreen({super.key});

  @override
  State<EnhancedAdminDashboardScreen> createState() => _EnhancedAdminDashboardScreenState();
}

class _EnhancedAdminDashboardScreenState extends State<EnhancedAdminDashboardScreen> {
  // Services
  late AuthService _authService;
  late DatabaseService _databaseService;
  late AuditService _auditService;
  late ConsentService _consentService;
  late DataDeletionService _dataDeletionService;
  late LocalizationService _localizationService;
  late AuthorizationService _authorizationService;

  // État de l'écran
  bool _isLoading = true;
  final int _selectedIndex = 0;
  
  // Données du tableau de bord
  Map<String, dynamic> _statistics = {};
  List<UserModel> _recentUsers = [];
  List<AgentModel> _recentAgents = [];
  List<ReservationModel> _recentReservations = [];
  List<AuditLogModel> _recentAuditLogs = [];
  List<DataDeletionRequestModel> _pendingDeletionRequests = [];
  Map<String, dynamic> _consentStatistics = {};
  Map<String, dynamic> _deletionStatistics = {};

  // Contrôleurs de recherche et filtres
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadDashboardData();
  }

  void _initializeServices() {
    _authService = Provider.of<AuthService>(context, listen: false);
    _databaseService = Provider.of<DatabaseService>(context, listen: false);
    _auditService = Provider.of<AuditService>(context, listen: false);
    _consentService = Provider.of<ConsentService>(context, listen: false);
    _dataDeletionService = Provider.of<DataDeletionService>(context, listen: false);
    _localizationService = Provider.of<LocalizationService>(context, listen: false);
    _authorizationService = Provider.of<AuthorizationService>(context, listen: false);
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // Charger les statistiques générales
      await _loadStatistics();
      
      // Charger les données récentes
      await Future.wait([
        _loadRecentUsers(),
        _loadRecentAgents(),
        _loadRecentReservations(),
        _loadRecentAuditLogs(),
        _loadPendingDeletionRequests(),
        _loadConsentStatistics(),
        _loadDeletionStatistics(),
      ]);
    } catch (e) {
      debugPrint('Erreur lors du chargement des données du tableau de bord: $e');
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

  Future<void> _loadStatistics() async {
    try {
      // Obtenir les statistiques des utilisateurs
      final users = _databaseService.getAllUsers();
      final activeUsers = users.where((u) => u.isActive).length;
      final inactiveUsers = users.where((u) => !u.isActive).length;

      // Obtenir les statistiques des agents
      final agents = await _databaseService.getAllAgents();
      final activeAgents = agents.where((a) => a.isAvailable).length;
      final inactiveAgents = agents.where((a) => !a.isAvailable).length;

      // Obtenir les statistiques des réservations
      final reservations = _databaseService.getAllReservations();
      final pendingReservations = reservations.where((r) => r.status == 'pending').length;
      final confirmedReservations = reservations.where((r) => r.status == 'confirmed').length;
      final completedReservations = reservations.where((r) => r.status == 'completed').length;
      final cancelledReservations = reservations.where((r) => r.status == 'cancelled').length;

      setState(() {
        _statistics = {
          'totalUsers': users.length,
          'activeUsers': activeUsers,
          'inactiveUsers': inactiveUsers,
          'totalAgents': agents.length,
          'activeAgents': activeAgents,
          'inactiveAgents': inactiveAgents,
          'totalReservations': reservations.length,
          'pendingReservations': pendingReservations,
          'confirmedReservations': confirmedReservations,
          'completedReservations': completedReservations,
          'cancelledReservations': cancelledReservations,
        };
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des statistiques: $e');
    }
  }

  Future<void> _loadRecentUsers() async {
    try {
      final users = _databaseService.getAllUsers();
      setState(() {
        _recentUsers = users.take(10).toList();
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des utilisateurs récents: $e');
    }
  }

  Future<void> _loadRecentAgents() async {
    try {
      final agents = await _databaseService.getAllAgents();
      setState(() {
        _recentAgents = agents.take(10).toList();
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des agents récents: $e');
    }
  }

  Future<void> _loadRecentReservations() async {
    try {
      final reservations = _databaseService.getAllReservations();
      setState(() {
        _recentReservations = reservations.take(10).toList();
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des réservations récentes: $e');
    }
  }

  Future<void> _loadRecentAuditLogs() async {
    try {
      final logs = await _auditService.getRecentLogs(limit: 10);
      setState(() {
        _recentAuditLogs = logs;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des logs d\'audit récents: $e');
    }
  }

  Future<void> _loadPendingDeletionRequests() async {
    try {
      final requests = await _dataDeletionService.getAllDeletionRequests(
        status: DeletionStatus.pending,
        urgentOnly: true,
      );
      setState(() {
        _pendingDeletionRequests = requests;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des demandes de suppression: $e');
    }
  }

  Future<void> _loadConsentStatistics() async {
    try {
      final stats = await _consentService.getConsentStatistics();
      setState(() {
        _consentStatistics = stats;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des statistiques de consentement: $e');
    }
  }

  Future<void> _loadDeletionStatistics() async {
    try {
      final stats = await _dataDeletionService.getDeletionStatistics();
      setState(() {
        _deletionStatistics = stats;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des statistiques de suppression: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildStatisticsCards() {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          title: 'Utilisateurs',
          value: _statistics['totalUsers']?.toString() ?? '0',
          subtitle: '${_statistics['activeUsers']?.toString() ?? '0'} actifs',
          icon: Icons.people,
          color: Colors.blue,
        ),
        _buildStatCard(
          title: 'Agents',
          value: _statistics['totalAgents']?.toString() ?? '0',
          subtitle: '${_statistics['activeAgents']?.toString() ?? '0'} disponibles',
          icon: Icons.security,
          color: Colors.green,
        ),
        _buildStatCard(
          title: 'Réservations',
          value: _statistics['totalReservations']?.toString() ?? '0',
          subtitle: '${_statistics['pendingReservations']?.toString() ?? '0'} en attente',
          icon: Icons.calendar_today,
          color: Colors.orange,
        ),
        _buildStatCard(
          title: 'Demandes RGPD',
          value: _pendingDeletionRequests.length.toString(),
          subtitle: '${_pendingDeletionRequests.where((r) => r.isUrgent).length} urgentes',
          icon: Icons.privacy_tip,
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activité Récente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_recentAuditLogs.isEmpty)
              const Center(
                child: Text('Aucune activité récente'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentAuditLogs.length,
                itemBuilder: (context, index) {
                  final log = _recentAuditLogs[index];
                  return _buildAuditLogItem(log);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditLogItem(AuditLogModel log) {
    final severity = log.getSeverity();
    return ListTile(
      leading: Icon(
        severity.icon,
        color: severity.color,
        size: 20,
      ),
      title: Text(
        log.getFormattedDescription(),
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        '${log.adminEmail} • ${_localizationService.formatDate(log.timestamp)}',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'details') {
            _showAuditLogDetails(log);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'details',
            child: Text('Voir les détails'),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingDeletionRequests() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Demandes de Suppression en Attente',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_pendingDeletionRequests.isNotEmpty)
                  Text(
                    '${_pendingDeletionRequests.length} demande(s)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_pendingDeletionRequests.isEmpty)
              const Center(
                child: Text('Aucune demande de suppression en attente'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pendingDeletionRequests.length,
                itemBuilder: (context, index) {
                  final request = _pendingDeletionRequests[index];
                  return _buildDeletionRequestItem(request);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeletionRequestItem(DataDeletionRequestModel request) {
    return ListTile(
      leading: Icon(
        request.isUrgent ? Icons.warning : Icons.person_remove,
        color: request.isUrgent ? Colors.red : Colors.orange,
        size: 20,
      ),
      title: Text(
        request.userEmail,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${request.reason.displayName} • ${_localizationService.formatDate(request.requestedAt)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            request.getDataSummary(),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) async {
          switch (value) {
            case 'approve':
              await _approveDeletionRequest(request);
              break;
            case 'reject':
              await _rejectDeletionRequest(request);
              break;
            case 'details':
              _showDeletionRequestDetails(request);
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'approve',
            child: Text('Approuver'),
          ),
          const PopupMenuItem(
            value: 'reject',
            child: Text('Rejeter'),
          ),
          const PopupMenuItem(
            value: 'details',
            child: Text('Voir les détails'),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentCompliance() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Conformité RGPD',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_consentStatistics.isEmpty)
              const Center(
                child: Text('Aucune donnée de consentement disponible'),
              )
            else
              Column(
                children: [
                  _buildConsentStatItem(
                    'Utilisateurs avec consentements',
                    '${_consentStatistics['totalUsers'] ?? 0}',
                    Colors.blue,
                  ),
                  const SizedBox(height: 8),
                  _buildConsentStatItem(
                    'Taux de consentement analytics',
                    '${_consentStatistics['statistics']?['analytics']?['grantedPercentage'] ?? '0'}%',
                    Colors.green,
                  ),
                  const SizedBox(height: 8),
                  _buildConsentStatItem(
                    'Taux de consentement marketing',
                    '${_consentStatistics['statistics']?['marketing']?['grantedPercentage'] ?? '0'}%',
                    Colors.orange,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentStatItem(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions Rapides',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionButton(
                  'Gérer les Utilisateurs',
                  Icons.people,
                  Colors.blue,
                  () => _navigateToUsersManagement(),
                ),
                _buildActionButton(
                  'Gérer les Agents',
                  Icons.security,
                  Colors.green,
                  () => _navigateToAgentsManagement(),
                ),
                _buildActionButton(
                  'Gérer les Réservations',
                  Icons.calendar_today,
                  Colors.orange,
                  () => _navigateToReservationsManagement(),
                ),
                _buildActionButton(
                  'Voir les Logs d\'Audit',
                  Icons.history,
                  Colors.purple,
                  () => _navigateToAuditLogs(),
                ),
                _buildActionButton(
                  'Gérer les Consentements',
                  Icons.privacy_tip,
                  Colors.red,
                  () => _navigateToConsentManagement(),
                ),
                _buildActionButton(
                  'Paramètres RGPD',
                  Icons.gavel,
                  Colors.brown,
                  () => _navigateToGdprSettings(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12),
      ),
    );
  }

  Future<void> _approveDeletionRequest(DataDeletionRequestModel request) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final approvedRequest = await _dataDeletionService.approveDeletionRequest(
        requestId: request.id,
        processedBy: currentUser.email ?? 'Admin',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande de suppression approuvée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        _loadDashboardData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'approbation: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectDeletionRequest(DataDeletionRequestModel request) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      // Afficher une boîte de dialogue pour saisir la raison du rejet
      final reasonController = TextEditingController();
      final shouldReject = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Rejeter la demande de suppression'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Veuillez indiquer la raison du rejet:'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Raison du rejet',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Rejeter'),
            ),
          ],
        ),
      );

      if (shouldReject == true && reasonController.text.isNotEmpty) {
        await _dataDeletionService.rejectDeletionRequest(
          requestId: request.id,
          processedBy: currentUser.email ?? 'Admin',
          rejectionReason: reasonController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Demande de suppression rejetée avec succès'),
              backgroundColor: Colors.orange,
            ),
          );
          _loadDashboardData();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du rejet: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAuditLogDetails(AuditLogModel log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails du log d\'audit'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Action', log.action),
              _buildDetailRow('Type de cible', log.targetType),
              _buildDetailRow('ID de cible', log.targetId),
              _buildDetailRow('Administrateur', log.adminEmail),
              _buildDetailRow('Date', _localizationService.formatDate(log.timestamp)),
              _buildDetailRow('Heure', _localizationService.formatTime(
                TimeOfDay.fromDateTime(log.timestamp),
              )),
              _buildDetailRow('Gravité', log.getSeverity().name),
              if (log.description != null)
                _buildDetailRow('Description', log.description!),
              if (log.ipAddress != null)
                _buildDetailRow('Adresse IP', log.ipAddress!),
              if (log.userAgent != null)
                _buildDetailRow('User Agent', log.userAgent!),
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

  void _showDeletionRequestDetails(DataDeletionRequestModel request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails de la demande de suppression'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Utilisateur', request.userEmail),
              _buildDetailRow('Raison', request.reason.displayName),
              _buildDetailRow('Statut', request.status.displayName),
              _buildDetailRow('Date de demande', _localizationService.formatDate(request.requestedAt)),
              _buildDetailRow('Urgent', request.isUrgent ? 'Oui' : 'Non'),
              if (request.additionalComments != null)
                _buildDetailRow('Commentaires', request.additionalComments!),
              _buildDetailRow('Données à supprimer', request.getDataSummary()),
              if (request.scheduledFor != null)
                _buildDetailRow('Planifié pour', _localizationService.formatDate(request.scheduledFor!)),
              if (request.processedAt != null)
                _buildDetailRow('Traité le', _localizationService.formatDate(request.processedAt!)),
              if (request.rejectionReason != null)
                _buildDetailRow('Raison du rejet', request.rejectionReason!),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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

  void _navigateToUsersManagement() {
    Navigator.pushNamed(context, '/admin/users');
  }

  void _navigateToAgentsManagement() {
    Navigator.pushNamed(context, '/admin/agents');
  }

  void _navigateToReservationsManagement() {
    Navigator.pushNamed(context, '/admin/reservations');
  }

  void _navigateToAuditLogs() {
    Navigator.pushNamed(context, '/admin/audit');
  }

  void _navigateToConsentManagement() {
    Navigator.pushNamed(context, '/admin/consents');
  }

  void _navigateToGdprSettings() {
    Navigator.pushNamed(context, '/admin/gdpr');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AdminAppBar(title: 'Tableau de Bord Administrateur'),
      drawer: const AdminDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barre de recherche
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Rechercher...',
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
                    const SizedBox(height: 24),
                    
                    // Statistiques
                    _buildStatisticsCards(),
                    const SizedBox(height: 24),
                    
                    // Actions rapides
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    
                    // Demandes de suppression en attente
                    _buildPendingDeletionRequests(),
                    const SizedBox(height: 24),
                    
                    // Conformité RGPD
                    _buildConsentCompliance(),
                    const SizedBox(height: 24),
                    
                    // Activité récente
                    _buildRecentActivity(),
                  ],
                ),
              ),
      ),
    );
  }
}
