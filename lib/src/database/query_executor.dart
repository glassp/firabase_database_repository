import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:database_repository/database_repository.dart';
import 'package:uuid/uuid.dart';

/// Mixin that contains the logic on how to execute the query in firestore
mixin QueryExecutor implements DatabaseAdapter {
  /// Tries to store queries payload in firestore
  Future<QueryResult> create(
      Query query, firestore.FirebaseFirestore db) async {
    final id = query.payload['id'] ?? Uuid().v1();
    final ref = db.collection(query.entityName).doc(id);
    final json = JSON.from(query.payload)..putIfAbsent('id', () => id);

    try {
      if ((await ref.get()).exists) {
        return QueryResult.failed(
          query,
          errorMsg: '${query.entityName} with id $id already exists.',
        );
      }
      await ref.set(json);
      return QueryResult.success(query, payload: json);
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      return QueryResult.failed(query, errorMsg: e.toString());
    }
  }

  /// Tries to store queries payload in firestore
  Future<QueryResult> update(
      Query query, firestore.FirebaseFirestore db) async {
    final id = query.payload['id'] ?? Uuid().v1();
    final ref = db.collection(query.entityName).doc(id);
    final json = JSON.from(query.payload)..putIfAbsent('id', () => id);

    try {
      await ref.set(json);
      return QueryResult.success(query, payload: json);
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      return QueryResult.failed(query, errorMsg: e.toString());
    }
  }

  /// Tries to delete payload from firestore
  Future<QueryResult> delete(
      Query query, firestore.FirebaseFirestore db) async {
    final id = query.payload['id'];

    if (null == id) {
      return QueryResult.failed(query, errorMsg: 'No id specified');
    }

    final ref = db.collection(query.entityName).doc(id);

    try {
      await ref.delete();
      return QueryResult.success(query);
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      return QueryResult.failed(query, errorMsg: e.toString());
    }
  }

  /// Tries to fetch payload from firestore
  Future<QueryResult> read(Query query, firestore.FirebaseFirestore db) async {
    if (query.limit == 1 && null != query.payload['id']) {
      final id = query.payload['id'] ?? Uuid().v1();
      final ref = db.collection(query.entityName).doc(id);

      final snapshot = await ref.get();
      if (snapshot.exists && null != snapshot.data()) {
        return QueryResult.success(query, payload: snapshot.data()!);
      }
    } else {
      final ref = db.collection(query.entityName);
      firestore.Query? dbQuery;

      if (query.limit != null && query.limit! > 0) {
        dbQuery = ref.limit(query.limit!);
      }

      for (final constraint in query.where) {
        dbQuery = _applyConstraint(constraint, (dbQuery ?? ref));
      }

      final result = await (dbQuery ?? ref).get();
      final json = <String, dynamic>{};

      if (result.docs.isNotEmpty) {
        for (final snapshot in result.docs) {
          final inListConstraints = query.where
              .whereType<InList>()
              .where((c) => c.value.isNotEmpty && c.value.length >= 10);

          final notInListConstraints = query.where
              .whereType<NotInList>()
              .where((c) => c.value.isNotEmpty && c.value.length >= 10);

          /// Check if InListConstraint needs to be applied here.
          if (inListConstraints.isNotEmpty || notInListConstraints.isNotEmpty) {
            for (final constraint in [
              ...inListConstraints,
              ...notInListConstraints
            ]) {
              if (!constraint.evaluate(snapshot.data() as JSON)) {
                continue;
              }
            }
          }

          json.putIfAbsent(snapshot.id, snapshot.data);
        }
      }

      return QueryResult.success(query, payload: json);
    }

    return QueryResult.failed(
      query,
      errorMsg: 'Could not read data from database',
    );
  }

  firestore.Query _applyConstraint(
    Constraint constraint,
    firestore.Query dbQuery,
  ) {
    if (constraint is Equals) {
      return dbQuery.where(constraint.key, isEqualTo: constraint.value);
    }

    if (constraint is NotEquals) {
      return dbQuery.where(constraint.key, isNotEqualTo: constraint.value);
    }

    if (constraint is GreaterThan) {
      return dbQuery.where(constraint.key, isGreaterThan: constraint.value);
    }

    if (constraint is GreaterThanOrEquals) {
      return dbQuery.where(
        constraint.key,
        isGreaterThanOrEqualTo: constraint.value,
      );
    }

    if (constraint is LessThan) {
      return dbQuery.where(constraint.key, isLessThan: constraint.value);
    }

    if (constraint is LessThanOrEquals) {
      return dbQuery.where(
        constraint.key,
        isLessThanOrEqualTo: constraint.value,
      );
    }

    if (constraint is IsNull) {
      return dbQuery.where(constraint.key, isNull: true);
    }

    if (constraint is IsNotNull) {
      return dbQuery.where(constraint.key, isNull: false);
    }

    if (constraint is IsFalse) {
      return dbQuery.where(constraint.key, isEqualTo: false);
    }

    if (constraint is IsTrue) {
      return dbQuery.where(constraint.key, isEqualTo: true);
    }

    if (constraint is IsFalsey) {
      throw ConstraintUnsupportedException(
        constraint: constraint,
        adapter: this,
      );
    }

    if (constraint is IsTruthy) {
      return dbQuery
          .where(constraint.key, isNotEqualTo: "")
          .where(constraint.key, isNotEqualTo: 0)
          .where(constraint.key, isNotEqualTo: false)
          .where(constraint.key, isNotEqualTo: [])
          .where(constraint.key, isNull: false)
          .where(constraint.key, isNotEqualTo: {});
    }

    if (constraint is IsSet) {
      throw ConstraintUnsupportedException(
        constraint: constraint,
        adapter: this,
      );
    }

    if (constraint is IsUnset) {
      throw ConstraintUnsupportedException(
        constraint: constraint,
        adapter: this,
      );
    }

    if (constraint is InList && constraint.value.isEmpty) {
      throw ArgumentError(
        'InList cannot be evaluated on an empty array. '
        'InList(${constraint.key}, [])',
      );
    }

    if (constraint is InList && constraint.value.length >= 10) {
      /// cannot be applied to firebase. Evaluated after results are in
      return dbQuery;
    }

    if (constraint is InList) {
      return dbQuery.where(constraint.key, whereIn: constraint.value);
    }

    if (constraint is NotInList && constraint.value.isEmpty) {
      /// There can never be something in an empty array.
      /// Therefore will always be true and we can skip evaluating it
      return dbQuery;
    }

    if (constraint is NotInList && constraint.value.length >= 10) {
      /// cannot be applied to firebase. Evaluated after results are in
      return dbQuery;
    }

    if (constraint is NotInList) {
      return dbQuery.where(constraint.key, whereNotIn: constraint.value);
    }

    if (constraint is Contains) {
      if (constraint.value is Iterable) {
        for (final value in constraint.value) {
          dbQuery = dbQuery.where(constraint.key, arrayContains: value);
        }

        return dbQuery;
      }

      return dbQuery.where(constraint.key, arrayContains: constraint.value);
    }

    if (constraint is ContainsNot) {
      throw ConstraintUnsupportedException(
        constraint: constraint,
        adapter: this,
      );
    }

    throw ConstraintUnsupportedException(constraint: constraint, adapter: this);
  }
}
