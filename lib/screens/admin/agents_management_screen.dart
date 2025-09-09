import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/agent_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';
import '../../services/authorization_service.dart';
import '../../services/verification_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/agent_card.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/admin_app_bar.dart';
import '../../widgets/admin_drawer.dart';

// Écran de gestion des agents (pour admin)
class AgentsManagementScreen extends StatefulWidget {
  const AgentsManagementScreen({super.key});

  @override
  State<AgentsManagementScreen> createState() => _AgentsManagementScreenState();
}

class _AgentsManagementScreenState extends State<AgentsManagementScreen> {
  // État
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _showOnlyWithReservations = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Vérifier que l'utilisateur est bien un administrateur
  Future<void> _checkAdminStatus() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userData = await authService.getCurrentUserData();

      if (userData == null || !userData.isAdmin) {
        if (mounted) {
          // Rediriger vers la page de connexion admin
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppConstants.errorPermission),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          context.go('/admin');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        context.go('/admin');
      }
    }
  }

  // Filtrer les agents
  List<AgentModel> _filterAgents(List<AgentModel> agents) {
    if (_searchQuery.isEmpty) {
      return agents;
    }

    final query = _searchQuery.toLowerCase();
    return agents.where((agent) {
      return agent.fullName.toLowerCase().contains(query) ||
          agent.profession.toLowerCase().contains(query) ||
          agent.matricule.toLowerCase().contains(query);
    }).toList();
  }

  // Afficher le dialogue d'ajout/modification d'agent
  Future<void> _showAgentFormDialog({AgentModel? agent}) async {
    // Contrôleurs pour les champs de texte
    final fullNameController = TextEditingController(text: agent?.fullName);
    final ageController = TextEditingController(text: agent?.age.toString());
    final professionController = TextEditingController(text: agent?.profession);
    final backgroundController = TextEditingController(text: agent?.background);
    final educationLevelController = TextEditingController(
      text: agent?.educationLevel,
    );
    final matriculeController = TextEditingController(text: agent?.matricule);
    final emailController = TextEditingController(text: agent?.email);
    final phoneController = TextEditingController(text: agent?.phoneNumber);
    final specialtyController = TextEditingController(text: agent?.specialty);
    final experienceController = TextEditingController(
      text: agent?.experience?.toString() ?? '',
    );

    // Valeurs pour les champs de sélection (en dehors du StatefulBuilder pour persister)
    String gender = agent?.gender ?? 'M';
    String bloodType = agent?.bloodType ?? 'A+';
    bool isCertified = agent?.isCertified ?? false;
    bool isAvailable = agent?.isAvailable ?? true;
    int activeTabIndex = 0;
    File? imageFile;

    // Clé pour le formulaire
    final formKey = GlobalKey<FormState>();

    // Résultat du dialogue
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // En-tête avec titre et bouton de fermeture
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            agent == null
                                ? AppConstants.addAgent
                                : AppConstants.editAgent,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),

                      const Divider(),

                      // Contenu principal avec onglets
                      Flexible(
                        child: Form(
                          key: formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Onglets
                              Row(
                                children: [
                                  _buildTabButton(
                                    context,
                                    'Informations personnelles',
                                    0,
                                    activeTabIndex,
                                    (index) =>
                                        setState(() => activeTabIndex = index),
                                  ),
                                  _buildTabButton(
                                    context,
                                    'Informations professionnelles',
                                    1,
                                    activeTabIndex,
                                    (index) =>
                                        setState(() => activeTabIndex = index),
                                  ),
                                  _buildTabButton(
                                    context,
                                    'Statut',
                                    2,
                                    activeTabIndex,
                                    (index) =>
                                        setState(() => activeTabIndex = index),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Contenu des onglets
                              Flexible(
                                child: SingleChildScrollView(
                                  child:
                                      [
                                        // Onglet 1: Informations personnelles
                                        _buildPersonalInfoTab(
                                          context,
                                          setState,
                                          fullNameController,
                                          ageController,
                                          gender,
                                          bloodType,
                                          emailController,
                                          phoneController,
                                          imageFile,
                                          agent,
                                          (value) =>
                                              setState(() => gender = value),
                                          (value) =>
                                              setState(() => bloodType = value),
                                          (value) =>
                                              setState(() => imageFile = value),
                                        ),

                                        // Onglet 2: Informations professionnelles
                                        _buildProfessionalInfoTab(
                                          professionController,
                                          specialtyController,
                                          experienceController,
                                          backgroundController,
                                          educationLevelController,
                                          matriculeController,
                                        ),

                                        // Onglet 3: Statut
                                        _buildStatusTab(
                                          isCertified,
                                          isAvailable,
                                          (value) => setState(
                                            () => isCertified = value,
                                          ),
                                          (value) => setState(
                                            () => isAvailable = value,
                                          ),
                                        ),
                                      ][activeTabIndex],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Divider(),

                      // Boutons d'action
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Annuler'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: Text(agent == null ? 'Ajouter' : 'Modifier'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                Navigator.of(context).pop({
                                  'fullName': fullNameController.text.trim(),
                                  'age':
                                      int.tryParse(ageController.text.trim()) ??
                                      0,
                                  'gender': gender,
                                  'bloodType': bloodType,
                                  'profession':
                                      professionController.text.trim(),
                                  'specialty': specialtyController.text.trim(),
                                  'experience': int.tryParse(
                                    experienceController.text.trim(),
                                  ),
                                  'background':
                                      backgroundController.text.trim(),
                                  'educationLevel':
                                      educationLevelController.text.trim(),
                                  'matricule': matriculeController.text.trim(),
                                  'email': emailController.text.trim(),
                                  'phoneNumber': phoneController.text.trim(),
                                  'isCertified': isCertified,
                                  'isAvailable': isAvailable,
                                  'imageFile': imageFile,
                                });
                              }
                            },
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

    // Traiter le résultat
    if (result != null) {
      if (agent == null) {
        await _addAgent(result);
      } else {
        await _updateAgent(agent, result);
      }
    }

    // Nettoyer les contrôleurs après le traitement du résultat
    // Cela évite les erreurs "TextEditingController was used after being disposed"
    fullNameController.dispose();
    ageController.dispose();
    professionController.dispose();
    backgroundController.dispose();
    educationLevelController.dispose();
    matriculeController.dispose();
    emailController.dispose();
    phoneController.dispose();
    specialtyController.dispose();
    experienceController.dispose();
  }

  // Ajouter un nouvel agent
  Future<void> _addAgent(Map<String, dynamic> data) async {
    try {
      final databaseService = Provider.of<DatabaseService>(
        context,
        listen: false,
      );
      final storageService = Provider.of<StorageService>(
        context,
        listen: false,
      );

      // Créer un nouvel agent
      final agent = AgentModel(
        id: '', // Sera généré par Firestore
        fullName: data['fullName'],
        age: data['age'],
        gender: data['gender'],
        bloodType: data['bloodType'],
        profession: data['profession'],
        background: data['background'],
        educationLevel: data['educationLevel'],
        isCertified: data['isCertified'],
        matricule: data['matricule'],
        isAvailable: data['isAvailable'],
        createdAt: DateTime.now(),
        email: data['email'],
        phoneNumber: data['phoneNumber'],
        specialty: data['specialty'],
        experience: data['experience'],
      );

      // Ajouter l'agent à la base de données
      final agentId = await databaseService.addAgent(agent);

      // Télécharger l'image de profil si elle existe
      final imageFile = data['imageFile'] as File?;
      if (imageFile != null) {
        final imageUrl = await storageService.uploadAgentProfileImage(
          agentId,
          imageFile,
        );

        // Mettre à jour l'agent avec l'URL de l'image
        if (imageUrl != null) {
          final updatedAgent = AgentModel(
            id: agentId,
            fullName: agent.fullName,
            age: agent.age,
            gender: agent.gender,
            bloodType: agent.bloodType,
            profession: agent.profession,
            background: agent.background,
            educationLevel: agent.educationLevel,
            isCertified: agent.isCertified,
            matricule: agent.matricule,
            profileImageUrl: imageUrl,
            isAvailable: agent.isAvailable,
            createdAt: agent.createdAt,
            email: agent.email,
            phoneNumber: agent.phoneNumber,
            specialty: agent.specialty,
            experience: agent.experience,
          );

          await databaseService.updateAgent(updatedAgent);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agent ajouté avec succès'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de l\'ajout de l\'agent: ${e.toString()}',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // Mettre à jour un agent existant
  Future<void> _updateAgent(AgentModel agent, Map<String, dynamic> data) async {
    try {
      final databaseService = Provider.of<DatabaseService>(
        context,
        listen: false,
      );
      final storageService = Provider.of<StorageService>(
        context,
        listen: false,
      );

      // Télécharger l'image de profil si elle a été modifiée
      String? profileImageUrl = agent.profileImageUrl;
      final imageFile = data['imageFile'] as File?;
      if (imageFile != null) {
        profileImageUrl = await storageService.uploadAgentProfileImage(
          agent.id,
          imageFile,
        );
      }

      // Mettre à jour l'agent
      final updatedAgent = AgentModel(
        id: agent.id,
        fullName: data['fullName'],
        age: data['age'],
        gender: data['gender'],
        bloodType: data['bloodType'],
        profession: data['profession'],
        background: data['background'],
        educationLevel: data['educationLevel'],
        isCertified: data['isCertified'],
        matricule: data['matricule'],
        profileImageUrl: profileImageUrl,
        averageRating: agent.averageRating,
        ratingCount: agent.ratingCount,
        isAvailable: data['isAvailable'],
        createdAt: agent.createdAt,
        email: data['email'],
        phoneNumber: data['phoneNumber'],
        specialty: data['specialty'],
        experience: data['experience'],
      );

      await databaseService.updateAgent(updatedAgent);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agent mis à jour avec succès'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de la mise à jour de l\'agent: ${e.toString()}',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // Basculer le statut de certification d'un agent
  Future<void> _toggleCertification(AgentModel agent) async {
    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final authorizationService = Provider.of<AuthorizationService>(context, listen: false);

      // Vérifier les permissions
      final hasPermission = await authorizationService.currentUserHasPermission('certify_agents');
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vous n\'avez pas les permissions nécessaires pour certifier les agents'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }

      // Sauvegarder les anciennes données pour l'audit
      final oldData = {
        'fullName': agent.fullName,
        'isCertified': agent.isCertified,
      };

      // Créer un nouvel agent avec le statut de certification inversé
      final updatedAgent = agent.copyWith(isCertified: !agent.isCertified);

      // Mettre à jour l'agent dans la base de données
      await databaseService.updateAgent(updatedAgent);

      // Journaliser l'action
      await authorizationService.logAdminAction(
        action: updatedAgent.isCertified ? 'certify_agent' : 'decertify_agent',
        targetType: 'agent',
        targetId: agent.id,
        oldData: oldData,
        newData: {
          'isCertified': updatedAgent.isCertified,
        },
        description: updatedAgent.isCertified 
            ? 'Certification de l\'agent ${agent.fullName}' 
            : 'Retrait de la certification de l\'agent ${agent.fullName}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedAgent.isCertified
                  ? 'Agent certifié avec succès'
                  : 'Certification de l\'agent retirée',
            ),
            backgroundColor:
                updatedAgent.isCertified ? AppTheme.infoColor : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de la mise à jour de la certification: ${e.toString()}',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // Basculer la disponibilité d'un agent
  Future<void> _toggleAvailability(AgentModel agent) async {
    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final authorizationService = Provider.of<AuthorizationService>(context, listen: false);

      // Vérifier les permissions
      final hasPermission = await authorizationService.currentUserHasPermission('toggle_agent_availability');
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vous n\'avez pas les permissions nécessaires pour modifier la disponibilité des agents'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }

      // Si on essaie de rendre l'agent indisponible, vérifier s'il a des réservations en cours
      if (agent.isAvailable) {
        final hasActiveReservations = await databaseService
            .hasActiveReservations(agent.id);

        if (hasActiveReservations) {
          if (mounted) {
            // Afficher une boîte de dialogue pour informer l'administrateur
            final result = await showDialog<bool>(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('Agent avec réservations en cours'),
                    content: const Text(
                      'Cet agent a des réservations en cours ou en attente. '
                      'Voulez-vous quand même le marquer comme indisponible?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Annuler'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text('Marquer indisponible'),
                      ),
                    ],
                  ),
            );

            // Si l'administrateur annule, ne pas continuer
            if (result != true) return;
          }
        }
      }

      // Sauvegarder les anciennes données pour l'audit
      final oldData = {
        'fullName': agent.fullName,
        'isAvailable': agent.isAvailable,
      };

      // Créer un nouvel agent avec le statut de disponibilité inversé
      final updatedAgent = agent.copyWith(isAvailable: !agent.isAvailable);

      // Mettre à jour l'agent dans la base de données
      await databaseService.updateAgent(updatedAgent);

      // Journaliser l'action
      await authorizationService.logAdminAction(
        action: updatedAgent.isAvailable ? 'set_agent_available' : 'set_agent_unavailable',
        targetType: 'agent',
        targetId: agent.id,
        oldData: oldData,
        newData: {
          'isAvailable': updatedAgent.isAvailable,
        },
        description: updatedAgent.isAvailable 
            ? 'Marquage de l\'agent ${agent.fullName} comme disponible' 
            : 'Marquage de l\'agent ${agent.fullName} comme indisponible',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedAgent.isAvailable
                  ? 'Agent marqué comme disponible'
                  : 'Agent marqué comme indisponible',
            ),
            backgroundColor:
                updatedAgent.isAvailable ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de la mise à jour de la disponibilité: ${e.toString()}',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // Supprimer un agent
  Future<void> _deleteAgent(AgentModel agent) async {
    // Stocker les services avant toute opération asynchrone
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);
    final authorizationService = Provider.of<AuthorizationService>(context, listen: false);
    final verificationService = Provider.of<VerificationService>(context, listen: false);

    // Vérifier les permissions
    final hasPermission = await authorizationService.canDeleteEntity('agent', agent.id);
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous n\'avez pas les permissions nécessaires pour supprimer cet agent'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    // Demander une double vérification pour l'action critique
    final verified = await verificationService.requestDoubleVerification(
      context,
      action: 'Supprimer l\'agent',
      targetName: agent.fullName,
      additionalMessage: 'Cette action est irréversible et supprimera toutes les données associées à cet agent, y compris ses réservations et avis.',
    );

    if (!verified) return;

    try {
      // Sauvegarder les anciennes données pour l'audit
      final oldData = {
        'fullName': agent.fullName,
        'profession': agent.profession,
        'matricule': agent.matricule,
        'isCertified': agent.isCertified,
        'isAvailable': agent.isAvailable,
        'createdAt': agent.createdAt.toIso8601String(),
      };

      // Supprimer l'image de profil si elle existe
      if (agent.profileImageUrl != null) {
        await storageService.deleteImage(agent.profileImageUrl!);
      }

      // Supprimer l'agent
      await databaseService.deleteAgent(agent.id);

      // Journaliser l'action
      await authorizationService.logAdminAction(
        action: 'delete_agent',
        targetType: 'agent',
        targetId: agent.id,
        oldData: oldData,
        description: 'Suppression de l\'agent ${agent.fullName}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agent supprimé avec succès'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de la suppression de l\'agent: ${e.toString()}',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // Construire un bouton d'onglet
  Widget _buildTabButton(
    BuildContext context,
    String title,
    int index,
    int activeIndex,
    Function(int) onTap,
  ) {
    final isActive = index == activeIndex;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppTheme.primaryColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? AppTheme.primaryColor : AppTheme.mediumColor,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // Construire l'onglet des informations personnelles
  Widget _buildPersonalInfoTab(
    BuildContext context,
    StateSetter setState,
    TextEditingController fullNameController,
    TextEditingController ageController,
    String gender,
    String bloodType,
    TextEditingController emailController,
    TextEditingController phoneController,
    File? imageFile,
    AgentModel? agent,
    Function(String) onGenderChanged,
    Function(String) onBloodTypeChanged,
    Function(File?) onImageChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Photo de profil
        Center(
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              // Avatar
              imageFile != null
                  ? CircleAvatar(
                    radius: 50,
                    backgroundImage: FileImage(imageFile),
                  )
                  : const AgentAvatar(size: 100),

              // Bouton pour modifier la photo
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  onPressed: () async {
                    final storageService = Provider.of<StorageService>(
                      context,
                      listen: false,
                    );
                    final pickedImage = await storageService.pickImage();
                    if (pickedImage != null) {
                      onImageChanged(pickedImage);
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Section Informations personnelles
        const Text(
          'Informations personnelles',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),

        const SizedBox(height: 8),

        // Nom complet
        TextFormField(
          controller: fullNameController,
          decoration: const InputDecoration(
            labelText: 'Nom complet',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer le nom complet';
            }
            if (value.length < 3) {
              return 'Le nom doit contenir au moins 3 caractères';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Âge
        TextFormField(
          controller: ageController,
          decoration: const InputDecoration(
            labelText: 'Âge',
            prefixIcon: Icon(Icons.calendar_today),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer l\'âge';
            }
            final age = int.tryParse(value);
            if (age == null) {
              return 'Veuillez entrer un nombre valide';
            }
            if (age < 18 || age > 70) {
              return 'L\'âge doit être compris entre 18 et 70 ans';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Genre et Groupe sanguin sur la même ligne
        Row(
          children: [
            // Genre
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: gender,
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
                    onGenderChanged(value);
                  }
                },
              ),
            ),

            const SizedBox(width: 16),

            // Groupe sanguin
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: bloodType,
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
                    onBloodTypeChanged(value);
                  }
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Email
        TextFormField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              // Validation simple de l'email
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(value)) {
                return 'Veuillez entrer un email valide';
              }
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Téléphone
        TextFormField(
          controller: phoneController,
          decoration: const InputDecoration(
            labelText: 'Téléphone',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              // Validation simple du numéro de téléphone
              final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');
              if (!phoneRegex.hasMatch(value)) {
                return 'Veuillez entrer un numéro de téléphone valide';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  // Construire l'onglet des informations professionnelles
  Widget _buildProfessionalInfoTab(
    TextEditingController professionController,
    TextEditingController specialtyController,
    TextEditingController experienceController,
    TextEditingController backgroundController,
    TextEditingController educationLevelController,
    TextEditingController matriculeController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Informations professionnelles
        const Text(
          'Informations professionnelles',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),

        const SizedBox(height: 8),

        // Profession
        TextFormField(
          controller: professionController,
          decoration: const InputDecoration(
            labelText: 'Profession',
            prefixIcon: Icon(Icons.work),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer la profession';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Spécialité
        TextFormField(
          controller: specialtyController,
          decoration: const InputDecoration(
            labelText: 'Spécialité',
            prefixIcon: Icon(Icons.star),
            border: OutlineInputBorder(),
            hintText: 'Ex: Protection rapprochée, Sécurité événementielle...',
          ),
        ),

        const SizedBox(height: 16),

        // Années d'expérience
        TextFormField(
          controller: experienceController,
          decoration: const InputDecoration(
            labelText: 'Années d\'expérience',
            prefixIcon: Icon(Icons.timeline),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final experience = int.tryParse(value);
              if (experience == null) {
                return 'Veuillez entrer un nombre valide';
              }
              if (experience < 0 || experience > 50) {
                return 'L\'expérience doit être comprise entre 0 et 50 ans';
              }
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Antécédents
        TextFormField(
          controller: backgroundController,
          decoration: const InputDecoration(
            labelText: 'Antécédents',
            prefixIcon: Icon(Icons.history),
            border: OutlineInputBorder(),
            hintText: 'Expériences professionnelles précédentes',
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer les antécédents';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Niveau d'études
        TextFormField(
          controller: educationLevelController,
          decoration: const InputDecoration(
            labelText: 'Niveau d\'études',
            prefixIcon: Icon(Icons.school),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer le niveau d\'études';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Matricule
        TextFormField(
          controller: matriculeController,
          decoration: const InputDecoration(
            labelText: 'Matricule',
            prefixIcon: Icon(Icons.badge),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer le matricule';
            }
            return null;
          },
        ),
      ],
    );
  }

  // Construire l'onglet de statut
  Widget _buildStatusTab(
    bool isCertified,
    bool isAvailable,
    Function(bool) onCertifiedChanged,
    Function(bool) onAvailableChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Statut
        const Text(
          'Statut de l\'agent',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),

        const SizedBox(height: 16),

        // Agent certifié
        Card(
          elevation: 2,
          child: SwitchListTile(
            title: const Text(
              'Agent certifié',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              'L\'agent a passé toutes les certifications requises',
              style: TextStyle(fontSize: 12),
            ),
            value: isCertified,
            activeThumbColor: AppTheme.infoColor,
            onChanged: (value) {
              onCertifiedChanged(value);
            },
            secondary: Icon(
              Icons.verified,
              color: isCertified ? AppTheme.infoColor : AppTheme.mediumColor,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Disponibilité
        Card(
          elevation: 2,
          child: SwitchListTile(
            title: const Text(
              'Disponible',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              'L\'agent est disponible pour de nouvelles missions',
              style: TextStyle(fontSize: 12),
            ),
            value: isAvailable,
            activeThumbColor: AppTheme.accentColor,
            onChanged: (value) {
              onAvailableChanged(value);
            },
            secondary: Icon(
              Icons.event_available,
              color: isAvailable ? AppTheme.accentColor : AppTheme.mediumColor,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Informations sur le statut
        const Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informations sur le statut',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 8),
                Text(
                  '• Un agent certifié apparaîtra avec un badge spécial dans l\'application',
                  style: TextStyle(fontSize: 12),
                ),
                SizedBox(height: 4),
                Text(
                  '• Un agent non disponible n\'apparaîtra pas dans les résultats de recherche des utilisateurs',
                  style: TextStyle(fontSize: 12),
                ),
                SizedBox(height: 4),
                Text(
                  '• Vous pouvez modifier le statut d\'un agent à tout moment',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: AdminAppBar(
        title: AppConstants.agentsManagement,
        actions: [
          // Navigation vers les réservations en attente
          IconButton(
            icon: const Icon(Icons.pending_actions),
            onPressed: () => context.go('/admin/reservations'),
            tooltip: 'Réservations',
          ),
          // Navigation vers les statistiques
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.go('/admin/statistics'),
            tooltip: 'Statistiques',
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          // Barre de recherche et filtres
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un agent...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),

                const SizedBox(height: 8),

                // Filtres
                Row(
                  children: [
                    // Filtre pour les agents en réservation
                    FilterChip(
                      label: const Text('Agents en réservation'),
                      selected: _showOnlyWithReservations,
                      onSelected: (selected) {
                        setState(() {
                          _showOnlyWithReservations = selected;
                        });
                      },
                      avatar: Icon(
                        Icons.event_busy,
                        color:
                            _showOnlyWithReservations
                                ? Colors.white
                                : Colors.grey,
                        size: 18,
                      ),
                      backgroundColor: Colors.grey[200],
                      selectedColor: AppTheme.primaryColor,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color:
                            _showOnlyWithReservations
                                ? Colors.white
                                : Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Liste des agents
          Expanded(
            child:
                _showOnlyWithReservations
                    ? StreamBuilder<List<AgentModel>>(
                      stream: databaseService.getAgentsWithReservations(),
                      builder: (context, snapshot) {
                        // Afficher un indicateur de chargement
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const LoadingIndicator(
                            message: 'Chargement des agents en réservation...',
                          );
                        }

                        // Afficher un message d'erreur
                        if (snapshot.hasError) {
                          return ErrorMessage(
                            message: 'Erreur: ${snapshot.error}',
                            onRetry: () => setState(() {}),
                          );
                        }

                        // Récupérer et filtrer les agents
                        final agents = snapshot.data ?? [];
                        final filteredAgents = _filterAgents(agents);

                        // Afficher un message si aucun agent n'est trouvé
                        if (filteredAgents.isEmpty) {
                          return const EmptyMessage(
                            message: 'Aucun agent en réservation trouvé',
                            icon: Icons.event_busy,
                          );
                        }

                        // Afficher la liste des agents
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredAgents.length,
                          itemBuilder: (context, index) {
                            final agent = filteredAgents[index];
                            return _buildAgentCard(agent);
                          },
                        );
                      },
                    )
                    : StreamBuilder<List<AgentModel>>(
                      stream: databaseService.getAgents(),
                      builder: (context, snapshot) {
                        // Afficher un indicateur de chargement
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const LoadingIndicator(
                            message: 'Chargement des agents...',
                          );
                        }

                        // Afficher un message d'erreur
                        if (snapshot.hasError) {
                          return ErrorMessage(
                            message: 'Erreur: ${snapshot.error}',
                            onRetry: () => setState(() {}),
                          );
                        }

                        // Récupérer et filtrer les agents
                        final agents = snapshot.data ?? [];
                        final filteredAgents = _filterAgents(agents);

                        // Afficher un message si aucun agent n'est trouvé
                        if (filteredAgents.isEmpty) {
                          return const EmptyMessage(
                            message: 'Aucun agent trouvé',
                            icon: Icons.person_off,
                          );
                        }

                        // Afficher la liste des agents
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredAgents.length,
                          itemBuilder: (context, index) {
                            final agent = filteredAgents[index];
                            return _buildAgentCard(agent);
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
      // Bouton flottant pour ajouter un agent
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAgentFormDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Construire la carte d'un agent
  Widget _buildAgentCard(AgentModel agent) {
    return Dismissible(
      key: Key(agent.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppTheme.errorColor,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Confirmer la suppression'),
                content: Text(
                  'Êtes-vous sûr de vouloir supprimer l\'agent ${agent.fullName} ?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                    ),
                    child: const Text('Supprimer'),
                  ),
                ],
              ),
        );
      },
      onDismissed: (direction) {
        _deleteAgent(agent);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: [
            // Carte d'agent
            AgentCard(
              agent: agent,
              onTap: () => _showAgentFormDialog(agent: agent),
              trailing: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => context.go('/agent/${agent.id}'),
              ),
            ),

            // Boutons d'action
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Boutons de statut
                  Row(
                    children: [
                      // Bouton de certification
                      TextButton.icon(
                        icon: Icon(
                          Icons.verified,
                          color:
                              agent.isCertified
                                  ? AppTheme.infoColor
                                  : Colors.grey,
                          size: 20,
                        ),
                        label: Text(
                          agent.isCertified ? 'Certifié' : 'Certifier',
                          style: TextStyle(
                            color:
                                agent.isCertified
                                    ? AppTheme.infoColor
                                    : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        onPressed: () => _toggleCertification(agent),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Bouton de disponibilité
                      TextButton.icon(
                        icon: Icon(
                          Icons.event_available,
                          color: agent.isAvailable ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        label: Text(
                          agent.isAvailable ? 'Disponible' : 'Indisponible',
                          style: TextStyle(
                            color:
                                agent.isAvailable ? Colors.green : Colors.red,
                            fontSize: 12,
                          ),
                        ),
                        onPressed: () => _toggleAvailability(agent),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Bouton de modification
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showAgentFormDialog(agent: agent),
                        tooltip: AppConstants.editAgent,
                      ),
                      // Bouton de suppression
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: AppTheme.errorColor,
                        ),
                        onPressed: () => _deleteAgent(agent),
                        tooltip: AppConstants.deleteAgent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
