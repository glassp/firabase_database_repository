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