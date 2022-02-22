import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:database_repository/database_repository.dart';
import 'package:firebase_core/firebase_core.dart' as firebase;

import '../deps.dart';

/// Adapter for Firebase.
///
/// WARNING: This
class FirebaseDatabaseAdapter extends DatabaseAdapter with QueryExecutor {
  @override
  final String name;

  /// The firebase app that should be used.
  final firebase.FirebaseApp? firebaseApp;
  late final firestore.FirebaseFirestore _db;

  /// TODO
  FirebaseDatabaseAdapter({
    this.name = 'firebase',
    this.firebaseApp,
  }) {
    if (null != firebaseApp) {
      _db = firestore.FirebaseFirestore.instanceFor(app: firebaseApp!);
    } else {
      _db = firestore.FirebaseFirestore.instance;
    }
  }

  @override
  Future<QueryResult> executeQuery(Query query) {
    switch (query.action) {
      case QueryAction.create:
        return create(query, _db);
      case QueryAction.delete:
        return delete(query, _db);
      case QueryAction.update:
        return update(query, _db);
      case QueryAction.read:
        return read(query, _db);
    }
  }
}
