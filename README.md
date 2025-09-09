ZIBENE SECURITY
Application mobile pour la réservation de gardes du corps certifiés

Description
ZIBENE SECURITY est une application mobile Flutter qui permet aux utilisateurs de réserver des gardes du corps certifiés pour leurs besoins de sécurité. L'application offre une interface intuitive pour les clients ainsi qu'un panneau d'administration complet pour la gestion des agents, des réservations et des utilisateurs.

Fonctionnalités
Fonctionnalités Utilisateur
Authentification sécurisée : Inscription et connexion avec email/mot de passe
Vérification d'email : Confirmation de l'adresse email lors de l'inscription
Recherche d'agents : Parcours et filtrage des gardes du corps disponibles
Détails des agents : Consultation des profils détaillés avec compétences et évaluations
Réservation en ligne : Réservation simple et rapide de gardes du corps
Suivi des réservations : Historique complet des réservations et leur statut
Évaluation des services : Système de notation et commentaires après chaque mission
Recommandations personnalisées : Suggestions d'agents basées sur les préférences
Profil utilisateur : Gestion des informations personnelles et des préférences
Fonctionnalités Administrateur
Tableau de bord analytique : Statistiques détaillées sur les utilisateurs, agents et réservations
Gestion des agents : Ajout, modification et suppression des profils des gardes du corps
Gestion des utilisateurs : Administration des comptes clients
Gestion des réservations : Validation, suivi et traitement des demandes
Génération de rapports : Exportation des données et statistiques
Gestion des notifications : Envoi de notifications aux utilisateurs
Surveillance du système : Monitoring des performances et de l'activité
Gestion des permissions : Contrôle d'accès et des rôles
Journal d'audit : Suivi des actions et modifications
Architecture Technique
Structure du Projet
lib/
├── models/           # Modèles de données (Agent, User, Reservation, etc.)
├── screens/          # Écrans de l'application
│   ├── user/        # Écrans pour les utilisateurs
│   └── admin/       # Écrans pour les administrateurs
├── services/        # Services métier (Auth, Database, Notifications, etc.)
├── utils/           # Utilitaires (Routes, Constants, Theme, etc.)
├── widgets/         # Widgets réutilisables
└── main.dart        # Point d'entrée de l'application

txt


Technologies Utilisées
Flutter : Framework de développement multiplateforme
Dart : Langage de programmation
Firebase : Backend as a Service
Firebase Authentication : Gestion de l'authentification
Cloud Firestore : Base de données NoSQL
Firebase Storage : Stockage des fichiers
Firebase Messaging : Notifications push
Provider : Gestion d'état
GoRouter : Navigation et routage
FL Chart : Graphiques et visualisations
Modèles de Données
UserModel : Représente les utilisateurs de l'application
AgentModel : Représente les gardes du corps
ReservationModel : Représente les réservations de missions
ReviewModel : Représente les évaluations laissées par les utilisateurs
Installation et Configuration
Prérequis
Flutter SDK (version 3.7.2 ou supérieure)
Un compte Firebase
Android Studio ou VS Code
Configuration de Firebase
Créer un projet sur la console Firebase
Ajouter une application Android et/ou iOS
Télécharger les fichiers de configuration (google-services.json pour Android, GoogleService-Info.plist pour iOS)
Placer les fichiers dans les répertoires appropriés :
Android : android/app/google-services.json
iOS : ios/Runner/GoogleService-Info.plist
Installation des Dépendances
flutter pub get

bash


Configuration des Règles Firestore
Les règles de sécurité Firestore doivent être configurées dans les fichiers :

firestore.rules
firestore.indexes.json
Lancement de l'Application
flutter run

bash


Déploiement
Android
Générer la clé de signature :
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

bash


Configurer les informations de signature dans android/app/build.gradle

Générer l'APK ou l'AAB :

flutter build apk --release
# ou
flutter build appbundle --release

bash


iOS
Configurer les informations de signature dans Xcode

Générer l'IPA :

flutter build ios --release

bash


Points d'Amélioration et Vigilances
Sécurité & Permissions
Vérification des rôles côté Firestore (rules)
Validation des entrées côté client et serveur
Performance
Utilisation du cache réseau pour les images
Optimisation des requêtes Firestore (pagination, indexation)
Gestion mémoire appropriée
Expérience Utilisateur
Feedbacks visuels lors des opérations
Accessibilité (taille des boutons, contraste, navigation)
Internationalisation (prévue pour le futur)
Tests & Robustesse
Renforcement des tests unitaires et d'intégration
Gestion des cas limites (suppression d'agents avec réservations, etc.)
Backend & Scalabilité
Audit des règles Firestore
Surveillance des quotas Firebase
Contributeurs
Akoun-dev - Développeur principal
Licence
Ce projet est sous licence privée.

Contact
Pour toute question ou suggestion, veuillez contacter :

Email : akoun-dev@example.com