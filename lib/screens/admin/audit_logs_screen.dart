import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/audit_service.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/admin_app_bar.dart';
import '../../widgets/admin_drawer.dart';

// Écran des logs d'audit pour les administrateurs
class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AuditService _auditService = AuditService();
  
  List<AuditLogModel> _logs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'agent', 'user', 'reservation', 'settings'
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Charger les logs d'audit
  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);

    try {
      List<AuditLogModel> logs;
      
      if (_searchQuery.isNotEmpty) {
        logs = await _auditService.searchAuditLogs(searchTerm: _searchQuery);
      } else {
        logs = await _auditService.getAuditLogs(
          targetType: _selectedFilter == 'all' ? null : _selectedFilter,
          startDate: _startDate,
          endDate: _endDate,
        );
      }

      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  // Afficher le dialogue de filtres
  Future<void> _showFiltersDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtres'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Filtre par type
              DropdownButtonFormField<String>(
                value: _selectedFilter,
                decoration: const InputDecoration(labelText: 'Type d\'action'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Tous')),
                  DropdownMenuItem(value: 'agent', child: Text('Agents')),
                  DropdownMenuItem(value: 'user', child: Text('Utilisateurs')),
                  DropdownMenuItem(value: 'reservation', child: Text('Réservations')),
                  DropdownMenuItem(value: 'settings', child: Text('Paramètres')),
                ],
                onChanged: (value) => setDialogState(() => _selectedFilter = value!),
              ),
              const SizedBox(height: 16),
              
              // Période
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_startDate != null 
                          ? DateFormat('dd/MM/yyyy').format(_startDate!)
                          : 'Date début'),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setDialogState(() => _startDate = date);
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_endDate != null 
                          ? DateFormat('dd/MM/yyyy').format(_endDate!)
                          : 'Date fin'),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: _startDate ?? DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setDialogState(() => _endDate = date);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedFilter = 'all';
                _startDate = null;
                _endDate = null;
              });
              Navigator.pop(context);
              _loadLogs();
            },
            child: const Text('Réinitialiser'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadLogs();
            },
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminAppBar(
        title: 'Logs d\'audit',
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFiltersDialog,
            tooltip: 'Filtres',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher dans les logs...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          _loadLogs();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                if (value.isEmpty) {
                  _loadLogs();
                }
              },
              onSubmitted: (value) => _loadLogs(),
            ),
          ),

          // Liste des logs
          Expanded(
            child: _isLoading
                ? const LoadingIndicator(message: 'Chargement des logs...')
                : _logs.isEmpty
                    ? const EmptyMessage(
                        message: 'Aucun log trouvé',
                        icon: Icons.history,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          return _buildLogItem(log);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // Construire un élément de log
  Widget _buildLogItem(AuditLogModel log) {
    // Déterminer l'icône et la couleur selon l'action
    IconData icon;
    Color color;
    
    switch (log.action.toLowerCase()) {
      case 'create':
      case 'add':
        icon = Icons.add_circle;
        color = Colors.green;
        break;
      case 'update':
      case 'modify':
        icon = Icons.edit;
        color = Colors.orange;
        break;
      case 'delete':
      case 'remove':
        icon = Icons.delete;
        color = Colors.red;
        break;
      case 'login':
        icon = Icons.login;
        color = Colors.blue;
        break;
      case 'logout':
        icon = Icons.logout;
        color = Colors.grey;
        break;
      default:
        icon = Icons.info;
        color = AppTheme.primaryColor;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(50),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          '${log.action} - ${log.targetType}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Par: ${log.adminEmail}'),
            Text('Le: ${DateFormat('dd/MM/yyyy à HH:mm').format(log.timestamp)}'),
            if (log.description != null) Text(log.description!),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('ID Cible', log.targetId),
                _buildDetailRow('Admin ID', log.adminId),
                if (log.ipAddress != null) _buildDetailRow('IP', log.ipAddress!),
                
                // Afficher les changements si disponibles
                if (log.oldData != null || log.newData != null) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Changements:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (log.oldData != null) ...[
                    const Text('Avant:', style: TextStyle(color: Colors.red)),
                    Text(log.oldData.toString(), style: const TextStyle(fontSize: 12)),
                  ],
                  if (log.newData != null) ...[
                    const Text('Après:', style: TextStyle(color: Colors.green)),
                    Text(log.newData.toString(), style: const TextStyle(fontSize: 12)),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Construire une ligne de détail
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
