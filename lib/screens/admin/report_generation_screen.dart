import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/report_service.dart';
import '../../utils/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/admin_app_bar.dart';
import '../../widgets/admin_drawer.dart';

// Écran de génération de rapports pour les administrateurs
class ReportGenerationScreen extends StatefulWidget {
  const ReportGenerationScreen({super.key});

  @override
  State<ReportGenerationScreen> createState() => _ReportGenerationScreenState();
}

class _ReportGenerationScreenState extends State<ReportGenerationScreen> {
  // Types de rapports disponibles
  final List<String> _reportTypes = [
    'Réservations mensuelles',
    'Performance des agents',
    'Satisfaction client',
    'Revenus',
  ];

  String _selectedReportType = 'Réservations mensuelles';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _exportFormat = 'PDF'; // 'PDF', 'CSV', 'Excel'
  bool _isGenerating = false;

  // Générer un rapport
  Future<void> _generateReport() async {
    setState(() => _isGenerating = true);

    try {
      final reportService = Provider.of<ReportService>(context, listen: false);

      final reportUrl = await reportService.generateReport(
        type: _selectedReportType,
        startDate: _startDate,
        endDate: _endDate,
        format: _exportFormat,
      );

      if (mounted) {
        // Afficher une boîte de dialogue pour télécharger ou partager le rapport
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Rapport généré'),
            content: const Text('Votre rapport a été généré avec succès.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Ouvrir l'URL du rapport
                  launchUrl(Uri.parse(reportUrl));
                  Navigator.pop(context);
                },
                child: const Text('Télécharger'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminAppBar(
        title: 'Génération de rapports',
      ),
      drawer: const AdminDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte de configuration du rapport
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configurer le rapport',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sélection du type de rapport
                    const Text(
                      'Type de rapport:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedReportType,
                      isExpanded: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _reportTypes.map((type) =>
                        DropdownMenuItem(value: type, child: Text(type))
                      ).toList(),
                      onChanged: (value) => setState(() => _selectedReportType = value!),
                    ),

                    const SizedBox(height: 24),

                    // Sélection de la période
                    const Text(
                      'Période:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: AppTheme.mediumColor.withAlpha(100)),
                              ),
                            ),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _startDate,
                                firstDate: DateTime(2020),
                                lastDate: _endDate,
                              );
                              if (date != null) {
                                setState(() => _startDate = date);
                              }
                            },
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('à'),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(DateFormat('dd/MM/yyyy').format(_endDate)),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: AppTheme.mediumColor.withAlpha(100)),
                              ),
                            ),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _endDate,
                                firstDate: _startDate,
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() => _endDate = date);
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Format d'exportation
                    const Text(
                      'Format d\'exportation:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'PDF', label: Text('PDF')),
                        ButtonSegment(value: 'CSV', label: Text('CSV')),
                        ButtonSegment(value: 'Excel', label: Text('Excel')),
                      ],
                      selected: {_exportFormat},
                      onSelectionChanged: (Set<String> selection) {
                        setState(() => _exportFormat = selection.first);
                      },
                    ),

                    const SizedBox(height: 24),

                    // Bouton de génération
                    PrimaryButton(
                      text: 'Générer le rapport',
                      onPressed: _generateReport,
                      isLoading: _isGenerating,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Aperçu du rapport
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aperçu du rapport',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Contenu de l'aperçu selon le type de rapport
                    _buildReportPreview(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Rapports récents
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rapports récents',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Liste des rapports récents
                    _buildRecentReports(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Construire l'aperçu du rapport
  Widget _buildReportPreview() {
    // Simuler un aperçu différent selon le type de rapport
    switch (_selectedReportType) {
      case 'Réservations mensuelles':
        return Column(
          children: [
            const Text(
              'Ce rapport affichera:',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            _buildPreviewItem('Nombre total de réservations par mois'),
            _buildPreviewItem('Répartition par statut (approuvées, rejetées, etc.)'),
            _buildPreviewItem('Tendances et comparaisons avec les périodes précédentes'),
            _buildPreviewItem('Top 5 des lieux les plus réservés'),
          ],
        );

      case 'Performance des agents':
        return Column(
          children: [
            const Text(
              'Ce rapport affichera:',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            _buildPreviewItem('Classement des agents par nombre de réservations'),
            _buildPreviewItem('Évaluations moyennes et commentaires reçus'),
            _buildPreviewItem('Taux de conversion (réservations approuvées/totales)'),
            _buildPreviewItem('Temps de réponse moyen aux demandes'),
          ],
        );

      case 'Satisfaction client':
        return Column(
          children: [
            const Text(
              'Ce rapport affichera:',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            _buildPreviewItem('Note moyenne de satisfaction globale'),
            _buildPreviewItem('Évolution de la satisfaction dans le temps'),
            _buildPreviewItem('Analyse des commentaires (positifs/négatifs)'),
            _buildPreviewItem('Suggestions d\'amélioration basées sur les retours'),
          ],
        );

      case 'Revenus':
        return Column(
          children: [
            const Text(
              'Ce rapport affichera:',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            _buildPreviewItem('Revenus totaux par période'),
            _buildPreviewItem('Répartition des revenus par agent'),
            _buildPreviewItem('Analyse des tendances et prévisions'),
            _buildPreviewItem('Comparaison avec les objectifs financiers'),
          ],
        );

      default:
        return const Text('Sélectionnez un type de rapport pour voir l\'aperçu');
    }
  }

  // Construire un élément d'aperçu
  Widget _buildPreviewItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: AppTheme.accentColor),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  // Construire la liste des rapports récents
  Widget _buildRecentReports() {
    // Simuler des rapports récents
    final recentReports = [
      {
        'title': 'Réservations mensuelles - Mai 2023',
        'date': '01/06/2023',
        'format': 'PDF',
        'url': 'https://example.com/report1.pdf',
      },
      {
        'title': 'Performance des agents - T1 2023',
        'date': '15/04/2023',
        'format': 'Excel',
        'url': 'https://example.com/report2.xlsx',
      },
      {
        'title': 'Revenus - Année 2022',
        'date': '10/01/2023',
        'format': 'PDF',
        'url': 'https://example.com/report3.pdf',
      },
    ];

    if (recentReports.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Aucun rapport récent'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentReports.length,
      itemBuilder: (context, index) {
        final report = recentReports[index];
        return ListTile(
          title: Text(report['title']!),
          subtitle: Text('Généré le ${report['date']}'),
          trailing: IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => launchUrl(Uri.parse(report['url']!)),
            tooltip: 'Télécharger',
          ),
          leading: CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withAlpha(50),
            child: Text(
              report['format']!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        );
      },
    );
  }
}
