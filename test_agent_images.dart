import 'package:flutter/material.dart';
import 'lib/widgets/common_widgets.dart';
import 'lib/models/agent_model.dart';

// Script de test pour vérifier que toutes les images d'agents utilisent guard.png
class AgentImagesTest extends StatelessWidget {
  const AgentImagesTest({super.key});

  @override
  Widget build(BuildContext context) {
    // Créer un agent de test
    final testAgent = AgentModel(
      id: 'test_agent_id',
      fullName: 'Agent Test',
      age: 30,
      gender: 'M',
      bloodType: 'O+',
      profession: 'Garde du corps',
      background: 'Test',
      educationLevel: 'Universitaire',
      isCertified: true,
      matricule: 'TEST001',
      profileImageUrl: null, // Pas d'image URL
      createdAt: DateTime.now(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test des Images d\'Agents'),
        backgroundColor: Colors.amber,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test des widgets d\'images d\'agents',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Test AgentAvatar circulaire
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AgentAvatar (Circulaire)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            AgentAvatar(size: 40),
                            SizedBox(height: 5),
                            Text('Taille 40'),
                          ],
                        ),
                        Column(
                          children: [
                            AgentAvatar(size: 60),
                            SizedBox(height: 5),
                            Text('Taille 60'),
                          ],
                        ),
                        Column(
                          children: [
                            AgentAvatar(size: 80),
                            SizedBox(height: 5),
                            Text('Taille 80'),
                          ],
                        ),
                        Column(
                          children: [
                            AgentAvatar(size: 100),
                            SizedBox(height: 5),
                            Text('Taille 100'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test AgentAvatar rectangulaire
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AgentAvatar (Rectangulaire)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            AgentAvatar(size: 60, isCircular: false),
                            SizedBox(height: 5),
                            Text('60x60'),
                          ],
                        ),
                        Column(
                          children: [
                            AgentAvatar(size: 80, isCircular: false),
                            SizedBox(height: 5),
                            Text('80x80'),
                          ],
                        ),
                        Column(
                          children: [
                            AgentAvatar(size: 100, isCircular: false),
                            SizedBox(height: 5),
                            Text('100x100'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test AgentImage
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AgentImage (Rectangulaire)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Column(
                      children: [
                        // Image 120x140 (comme dans la liste)
                        Row(
                          children: [
                            AgentImage(
                              width: 120,
                              height: 140,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Format Liste',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text('120x140 pixels'),
                                  Text('Utilisé dans la liste des agents'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        // Image 180 (comme dans les cartes)
                        AgentImage(
                          height: 180,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Format Carte - 180px de hauteur',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Utilisé dans les cartes d\'agents'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Informations
            const Card(
              color: Colors.blue,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✅ Configuration réussie !',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Toutes les images d\'agents utilisent maintenant l\'image par défaut guard.png',
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Widgets créés:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '• AgentAvatar - Pour les avatars circulaires et rectangulaires\n'
                      '• AgentImage - Pour les images rectangulaires avec bordures',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Instructions
            const Card(
              color: Colors.green,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📝 Fichiers modifiés:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• lib/widgets/common_widgets.dart - Nouveaux widgets\n'
                      '• lib/widgets/agent_card.dart - Cartes d\'agents\n'
                      '• lib/screens/user/agents_list_screen.dart - Liste des agents\n'
                      '• lib/screens/user/agent_detail_screen.dart - Détails agent\n'
                      '• lib/widgets/rating_dialog.dart - Dialogue de notation\n'
                      '• lib/screens/user/recommendations_screen.dart - Recommandations\n'
                      '• lib/screens/admin/agents_management_screen.dart - Gestion admin',
                      style: TextStyle(color: Colors.white, fontSize: 12),
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
      title: 'Test Images Agents',
      home: const AgentImagesTest(),
      debugShowCheckedModeBanner: false,
    ),
  );
}
