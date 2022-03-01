# Firebase Repository for Flutter
[![Pub Version](https://img.shields.io/pub/v/firebase_database_repository)](https://pub.dev/packages/firebase_database_repository)

Use this database adapter for firebase to integrate with database_repository

## Using pure Dart?
Use [firedart_repository](https://pub.dev/packages/firedart_repository) as it does not require the flutter sdk

## How to install
```bash
dart pub add firebase_database_repository
```

## How to use
```dart
void main() async {
    // You can find this in your firebase project settings
    final myFirebaseConfig = {
        "apiKey": "SECRET",
        "authDomain": "[PROJECT].firebaseapp.com",
        "projectId": "[PROJECT]",
        "storageBucket": "[PROJECT].appspot.com",
        "messagingSenderId": "Foo",
        "appId": "Bar"
    };

    // Initialize Firebase
    // The manual configuration is used here for easier understanding
    final myFirebaseApp = await Firebase.initializeApp(
        options: FirebaseOptions.fromMap(myFirebaseConfig),
    );

    final myDatabaseAdapter = FirebaseDatabaseAdapter(firebaseApp: myFirebaseApp)
    
    // Register a Database Adapter that you want to use.
    DatabaseAdapterRegistry.register(myDatabaseAdapter);

    final repository = DatabaseRepository.fromRegistry(serializer: mySerializer, name: 'firebase');
    
    // Now use some methods such as create() etc.
}
```