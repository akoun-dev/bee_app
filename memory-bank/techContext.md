# BeeApp - Contexte Technique

## Stack Technique
- **Framework** : Flutter 3.16
- **Langage** : Dart 3.2
- **Backend** : Firebase
  - Authentication
  - Firestore Database
  - Cloud Storage
  - Cloud Functions

## Dépendances Principales
```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.14.0
  firebase_auth: ^4.9.0  
  cloud_firestore: ^4.8.0
  firebase_storage: ^11.5.0
  provider: ^6.1.1
  go_router: ^12.0.0
```

## Structure du Projet
```
lib/
├── models/       # Modèles de données
├── screens/      # Écrans principaux
├── services/     # Services Firebase
├── utils/        # Helpers et constantes
├── widgets/      # Composants UI réutilisables
```

## Configuration Firebase
- **Projet ID** : bee-app-ba993
- **Plateformes** : Android, iOS, Web
- **Règles de sécurité** : Actives pour Firestore/Storage

## Bonnes Pratiques
- Architecture : Provider + Repository Pattern
- État : Géré au niveau des services
- Sécurité : Règles Firebase strictes
- Tests : Unitaires et widget tests
