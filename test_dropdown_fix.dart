import 'package:flutter/material.dart';
import 'dart:io';

// Test spécifique pour vérifier que les dropdowns fonctionnent
class DropdownTestDialog extends StatefulWidget {
  const DropdownTestDialog({super.key});

  @override
  State<DropdownTestDialog> createState() => _DropdownTestDialogState();
}

class _DropdownTestDialogState extends State<DropdownTestDialog> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Test Dropdown Fix'),
          backgroundColor: Colors.amber,
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () => _showTestDialog(),
            child: const Text('Tester le dialogue avec dropdowns'),
          ),
        ),
      ),
    );
  }

  Future<void> _showTestDialog() async {
    // Variables en dehors du StatefulBuilder pour persister
    String gender = 'M';
    String bloodType = 'O+';
    bool isCertified = false;
    bool isAvailable = true;
    File? imageFile;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 500,
              height: 600,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre
                  const Text(
                    'Test des Dropdowns',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Affichage des valeurs actuelles
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Valeurs actuelles:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('Genre: $gender'),
                          Text('Groupe sanguin: $bloodType'),
                          Text('Certifié: $isCertified'),
                          Text('Disponible: $isAvailable'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Dropdown Genre
                  DropdownButtonFormField<String>(
                    value: gender,
                    decoration: const InputDecoration(
                      labelText: 'Genre',
                      prefixIcon: Icon(Icons.wc),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'M', child: Text('Homme')),
                      DropdownMenuItem(value: 'F', child: Text('Femme')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          gender = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  // Dropdown Groupe sanguin
                  DropdownButtonFormField<String>(
                    value: bloodType,
                    decoration: const InputDecoration(
                      labelText: 'Groupe sanguin',
                      prefixIcon: Icon(Icons.bloodtype),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'A+', child: Text('A+')),
                      DropdownMenuItem(value: 'A-', child: Text('A-')),
                      DropdownMenuItem(value: 'B+', child: Text('B+')),
                      DropdownMenuItem(value: 'B-', child: Text('B-')),
                      DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                      DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                      DropdownMenuItem(value: 'O+', child: Text('O+')),
                      DropdownMenuItem(value: 'O-', child: Text('O-')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          bloodType = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  // Switch Certifié
                  SwitchListTile(
                    title: const Text('Agent certifié'),
                    value: isCertified,
                    onChanged: (value) {
                      setState(() {
                        isCertified = value;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Switch Disponible
                  SwitchListTile(
                    title: const Text('Disponible'),
                    value: isAvailable,
                    onChanged: (value) {
                      setState(() {
                        isAvailable = value;
                      });
                    },
                  ),

                  const Spacer(),

                  // Boutons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop({
                            'gender': gender,
                            'bloodType': bloodType,
                            'isCertified': isCertified,
                            'isAvailable': isAvailable,
                          });
                        },
                        child: const Text('Sauvegarder'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    // Afficher le résultat
    if (result != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Résultat: Genre=${result['gender']}, '
              'Groupe sanguin=${result['bloodType']}, '
              'Certifié=${result['isCertified']}, '
              'Disponible=${result['isAvailable']}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}

void main() {
  runApp(const DropdownTestDialog());
}

// Widget de test pour l'intégration dans l'app principale
class DropdownTestWidget extends StatelessWidget {
  const DropdownTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔧 Test des Dropdowns',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ce test vérifie que les dropdowns (Genre et Groupe sanguin) '
              'se mettent à jour correctement dans le dialogue.',
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DropdownTestDialog(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text(
                'Lancer le test',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Instructions:\n'
              '1. Cliquez sur "Tester le dialogue"\n'
              '2. Modifiez les valeurs dans les dropdowns\n'
              '3. Vérifiez que les "Valeurs actuelles" se mettent à jour\n'
              '4. Cliquez sur "Sauvegarder" pour voir le résultat',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
