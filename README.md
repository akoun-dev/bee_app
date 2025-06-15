# 🐝 ZIBENE SECURITY

> **Application mobile professionnelle de réservation de gardes du corps certifiés**

[![Flutter](https://img.shields.io/badge/Flutter-3.7.2+-02569B?style=flat&logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=flat&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 📱 À propos

**ZIBENE SECURITY** est une application mobile Flutter complète qui permet aux utilisateurs de réserver des agents de sécurité certifiés pour leurs besoins de protection personnelle ou événementielle. L'application offre une interface moderne, un système de gestion avancé et des fonctionnalités d'administration complètes.

### ✨ Fonctionnalités principales

#### 👥 **Pour les utilisateurs**
- 🔍 **Recherche avancée** d'agents par nom, profession, matricule
- 🎯 **Filtres intelligents** (disponibilité, certification, spécialité)
- 📅 **Système de réservation** avec sélection de dates
- 📊 **Tableau de bord** personnalisé avec statistiques
- ⭐ **Évaluations et avis** sur les agents
- 🎯 **Recommandations** basées sur l'historique
- 👤 **Gestion de profil** complète
- 🔔 **Notifications** en temps réel

#### 🛡️ **Pour les administrateurs**
- 📈 **Tableau de bord analytique** avec graphiques interactifs
- 👥 **Gestion complète des agents** (CRUD)
- ✅ **Approbation/rejet** des réservations
- 📊 **Statistiques détaillées** et rapports
- 👤 **Gestion des utilisateurs**
- 🔔 **Système de notifications** avancé
- 📋 **Logs d'audit** pour traçabilité
- ⚙️ **Configuration** de l'application

## 🏗️ Architecture technique

### 📱 Frontend
- **Framework** : Flutter 3.7.2+
- **Langage** : Dart
- **Design** : Material Design 3
- **État** : Provider pattern
- **Navigation** : GoRouter
- **Graphiques** : FL Chart

### ☁️ Backend
- **Authentification** : Firebase Auth
- **Base de données** : Cloud Firestore
- **Stockage** : Firebase Storage
- **Notifications** : Firebase Cloud Messaging
- **Règles de sécurité** : Firestore Security Rules

### 🎨 Design
- **Couleurs** : Jaune (#FFC107), Noir (#000000), Blanc
- **Police** : Poppins
- **Thèmes** : Clair/Sombre avec support système
- **Responsive** : Adaptation multi-écrans

## 🚀 Installation et configuration

### Prérequis

- **Flutter SDK** 3.7.2 ou supérieur
- **Dart SDK** inclus avec Flutter
- **Android Studio** ou **VS Code** avec extensions Flutter
- **Compte Firebase** pour la configuration backend

Vérifiez votre installation :
```bash
flutter doctor
```

### 1. Cloner le projet

```bash
git clone https://github.com/akoun-dev/bee_app.git
cd bee_app
```

### 2. Configuration Firebase

1. **Installer FlutterFire CLI** :
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. **Se connecter à Firebase** :
   ```bash
   firebase login
   ```

3. **Configurer le projet** :
   ```bash
   flutterfire configure
   ```
   
   Cette commande :
   - Génère `lib/firebase_options.dart`
   - Configure `android/app/google-services.json`
   - Configure `ios/Runner/GoogleService-Info.plist`

### 3. Installation des dépendances

```bash
flutter pub get
```

### 4. Configuration des règles Firebase

1. **Firestore Rules** : Déployez les règles depuis `firestore.rules`
2. **Storage Rules** : Déployez les règles depuis `storage.rules`
3. **Indexes** : Créez les index depuis `firestore.indexes.json`

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage
```

## 🏃‍♂️ Lancement de l'application

### Mode développement

```bash
flutter run
```

### Build de production

**Android APK** :
```bash
flutter build apk --release
```

**Android App Bundle** :
```bash
flutter build appbundle --release
```

**iOS** :
```bash
flutter build ios --release
```

## 📁 Structure du projet

```
lib/
├── main.dart                 # Point d'entrée de l'application
├── models/                   # Modèles de données
│   ├── user_model.dart
│   ├── agent_model.dart
│   ├── reservation_model.dart
│   ├── review_model.dart
│   ├── audit_log_model.dart
│   └── user_preferences_model.dart
├── screens/                  # Écrans de l'application
│   ├── admin/               # Écrans administrateur (15)
│   └── user/                # Écrans utilisateur (14)
├── services/                # Services métier
│   ├── auth_service.dart
│   ├── database_service.dart
│   ├── storage_service.dart
│   ├── notification_service.dart
│   └── ...
├── widgets/                 # Composants réutilisables
│   ├── common_widgets.dart
│   ├── agent_card.dart
│   ├── reservation_card.dart
│   └── ...
└── utils/                   # Utilitaires
    ├── constants.dart
    ├── theme.dart
    └── routes.dart
```

## 🧪 Tests

### Lancer les tests

```bash
flutter test
```

### Tests d'intégration

```bash
flutter drive --target=test_driver/app.dart
```

## 📊 Modèles de données

L'application utilise 6 modèles principaux :

1. **UserModel** - Gestion des utilisateurs et administrateurs
2. **AgentModel** - Profils détaillés des gardes du corps
3. **ReservationModel** - Gestion des missions et réservations
4. **ReviewModel** - Système d'évaluations et avis
5. **AuditLogModel** - Logs d'audit pour traçabilité
6. **UserPreferencesModel** - Préférences et personnalisation

## 🔐 Sécurité

- **Authentification** sécurisée via Firebase Auth
- **Vérification email** obligatoire
- **Règles Firestore** granulaires
- **Logs d'audit** complets
- **Validation** côté client et serveur

## 🌍 Internationalisation

L'application est actuellement en **français** avec support pour :
- Formats de date/heure locaux
- Devise (FCFA)
- Messages d'erreur localisés

## 📱 Compatibilité

- **Android** : API 21+ (Android 5.0+)
- **iOS** : iOS 11.0+
- **Web** : Navigateurs modernes (Chrome, Firefox, Safari, Edge)

## 🤝 Contribution

1. Fork le projet
2. Créez une branche feature (`git checkout -b feature/AmazingFeature`)
3. Committez vos changements (`git commit -m 'Add some AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrez une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 👨‍💻 Auteur

**ABOA AKOUN BERNARD**
- GitHub: [@akoun-dev](https://github.com/akoun-dev)
- Email: aboa.akoun40@gmail.com

## 🙏 Remerciements

- [Flutter Team](https://flutter.dev) pour le framework
- [Firebase Team](https://firebase.google.com) pour les services backend
- [Material Design](https://material.io) pour les guidelines de design

---

<div align="center">
  <strong>🐝 ZIBENE SECURITY - Votre sécurité, notre priorité</strong>
</div>
