import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'lib/models/agent_model.dart';
import 'lib/services/database_service.dart';
import 'lib/services/auth_service.dart';
import 'lib/widgets/common_widgets.dart';

// Script de test pour vérifier la mise à jour des profils d'agents
class AgentUpdateTest extends StatefulWidget {
  const AgentUpdateTest({super.key});

  @override
  State<AgentUpdateTest> createState() => _AgentUpdateTestState();
}

class _AgentUpdateTestState extends State<AgentUpdateTest> {
  String _testResult = 'Prêt pour le test...';
  bool _isLoading = false;
  AgentModel? _testAgent;

  // Créer un agent de test
  Future<void> _createTestAgent() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Création d\'un agent de test...';
    });

    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);

      final testAgent = AgentModel(
        id: '', // Sera généré par Firestore
        fullName: 'Agent Test ${DateTime.now().millisecondsSinceEpoch}',
        age: 30,
        gender: 'M',
        bloodType: 'O+',
        profession: 'Garde du corps',
        background: 'Test automatique',
        educationLevel: 'Universitaire',
        isCertified: false,
        matricule: 'TEST${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
        email: 'test@example.com',
        phoneNumber: '+33123456789',
        specialty: 'Protection rapprochée',
        experience: '5',
      );

      final agentId = await databaseService.addAgent(testAgent);
      final createdAgent = await databaseService.getAgent(agentId);

      setState(() {
        _testAgent = createdAgent;
        _testResult = 'Agent de test créé avec succès!\nID: $agentId\nNom: ${createdAgent?.fullName}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResult = 'Erreur lors de la création: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Tester la mise à jour de l'agent
  Future<void> _testUpdateAgent() async {
    if (_testAgent == null) {
      setState(() {
        _testResult = 'Veuillez d\'abord créer un agent de test';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _testResult = 'Test de mise à jour en cours...';
    });

    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);

      // Créer une version mise à jour de l'agent
      final updatedAgent = _testAgent!.copyWith(
        fullName: '${_testAgent!.fullName} - MODIFIÉ',
        age: _testAgent!.age + 1,
        gender: _testAgent!.gender == 'M' ? 'F' : 'M',
        bloodType: _testAgent!.bloodType == 'O+' ? 'A+' : 'O+',
        profession: 'Garde du corps spécialisé',
        isCertified: !_testAgent!.isCertified,
        isAvailable: !_testAgent!.isAvailable,
        email: 'updated_${_testAgent!.email}',
        phoneNumber: '+33987654321',
        specialty: 'Protection VIP',
        experience: '10',
      );

      // Effectuer la mise à jour
      await databaseService.updateAgent(updatedAgent);

      // Récupérer l'agent mis à jour pour vérifier
      final retrievedAgent = await databaseService.getAgent(_testAgent!.id);

      setState(() {
        _testAgent = retrievedAgent;
        _testResult = 'Mise à jour réussie!\n'
            'Nouveau nom: ${retrievedAgent?.fullName}\n'
            'Nouvel âge: ${retrievedAgent?.age}\n'
            'Nouveau genre: ${retrievedAgent?.gender}\n'
            'Nouveau groupe sanguin: ${retrievedAgent?.bloodType}\n'
            'Certifié: ${retrievedAgent?.isCertified}\n'
            'Disponible: ${retrievedAgent?.isAvailable}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResult = 'Erreur lors de la mise à jour: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Nettoyer l'agent de test
  Future<void> _cleanupTestAgent() async {
    if (_testAgent == null) {
      setState(() {
        _testResult = 'Aucun agent de test à supprimer';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _testResult = 'Suppression de l\'agent de test...';
    });

    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);

      await databaseService.deleteAgent(_testAgent!.id);

      setState(() {
        _testAgent = null;
        _testResult = 'Agent de test supprimé avec succès!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResult = 'Erreur lors de la suppression: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Mise à Jour Agents'),
        backgroundColor: Colors.amber,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Résultat du test
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Résultat du test:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _testResult,
                      style: TextStyle(
                        fontSize: 14,
                        color: _testResult.startsWith('Erreur') 
                            ? Colors.red 
                            : _testResult.contains('succès') 
                                ? Colors.green 
                                : Colors.black,
                      ),
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Informations sur l'agent de test
            if (_testAgent != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Agent de test actuel:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const AgentAvatar(size: 50),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _testAgent!.fullName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text('Âge: ${_testAgent!.age} ans'),
                                Text('Genre: ${_testAgent!.gender}'),
                                Text('Groupe sanguin: ${_testAgent!.bloodType}'),
                                Text('Certifié: ${_testAgent!.isCertified ? "Oui" : "Non"}'),
                                Text('Disponible: ${_testAgent!.isAvailable ? "Oui" : "Non"}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Boutons de test
            ElevatedButton(
              onPressed: _isLoading ? null : _createTestAgent,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Créer un agent de test',
                style: TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _isLoading || _testAgent == null ? null : _testUpdateAgent,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Tester la mise à jour',
                style: TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _isLoading || _testAgent == null ? null : _cleanupTestAgent,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Supprimer l\'agent de test',
                style: TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 20),

            // Instructions
            const Card(
              color: Colors.green,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✅ Corrections apportées:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Correction des variables d\'état dans StatefulBuilder\n'
                      '• Ajout de callbacks pour les DropdownButtonFormField\n'
                      '• Correction de la gestion des images\n'
                      '• Amélioration de la gestion des erreurs',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Fonction principale pour tester
void main() {
  runApp(
    MaterialApp(
      title: 'Test Mise à Jour Agents',
      home: const AgentUpdateTest(),
      debugShowCheckedModeBanner: false,
    ),
  );
}
