# bee_app

Application mobile de réservation de gardes du corps certifiés construite avec Flutter.

## Prérequis

- **Flutter** et **Dart** doivent être installés sur votre machine. Consultez la documentation officielle pour l'installation :
  <https://docs.flutter.dev/get-started/install>
  
  Vérifiez l'installation avec :
  ```bash
  flutter --version
  ```

- **Firebase** et l'outil **FlutterFire CLI** pour générer les fichiers de configuration.
  ```bash
  dart pub global activate flutterfire_cli
  ```

## Configuration Firebase

1. Connectez-vous à votre compte Firebase :
   ```bash
   firebase login
   ```
2. Depuis la racine du projet, exécutez :
   ```bash
   flutterfire configure
   ```
   Cette commande met à jour `firebase.json` et génère `lib/firebase_options.dart` ainsi que les fichiers `google-services.json`/`GoogleService-Info.plist` nécessaires.

## Installation des dépendances

Dans la racine du projet, installez les packages :

```bash
flutter pub get
```

## Build et exécution

Pour lancer l'application sur un appareil ou un émulateur :

```bash
flutter run
```

Pour générer un APK de production :

```bash
flutter build apk --release
```

## Tests

Lorsque des tests seront disponibles, vous pourrez les exécuter avec :

```bash
flutter test
```
