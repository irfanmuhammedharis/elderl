import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firestore instance provider - uses default (unnamed) database
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Firestore service for database operations
class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService(this._firestore);

  /// Get a collection reference
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _firestore.collection(path);
  }

  /// Get a document reference
  DocumentReference<Map<String, dynamic>> document(String path) {
    return _firestore.doc(path);
  }

  /// Create a document with auto-generated ID
  Future<DocumentReference<Map<String, dynamic>>> add(
    String collection,
    Map<String, dynamic> data,
  ) async {
    return await _firestore.collection(collection).add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Create or update a document with specific ID
  Future<void> set(
    String collection,
    String documentId,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    await _firestore.collection(collection).doc(documentId).set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
        if (!merge) 'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: merge),
    );
  }

  /// Update a document
  Future<void> update(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection(collection).doc(documentId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a document
  Future<void> delete(String collection, String documentId) async {
    await _firestore.collection(collection).doc(documentId).delete();
  }

  /// Get a document by ID
  Future<DocumentSnapshot<Map<String, dynamic>>> get(
    String collection,
    String documentId,
  ) async {
    return await _firestore.collection(collection).doc(documentId).get();
  }

  /// Get all documents in a collection
  Future<QuerySnapshot<Map<String, dynamic>>> getAll(String collection) async {
    return await _firestore.collection(collection).get();
  }

  /// Query documents with conditions
  Future<QuerySnapshot<Map<String, dynamic>>> query(
    String collection, {
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection(collection);

    if (filters != null) {
      for (final filter in filters) {
        query = query.where(
          filter.field,
          isEqualTo: filter.isEqualTo,
          isNotEqualTo: filter.isNotEqualTo,
          isLessThan: filter.isLessThan,
          isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
          isGreaterThan: filter.isGreaterThan,
          isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
          arrayContains: filter.arrayContains,
          arrayContainsAny: filter.arrayContainsAny,
          whereIn: filter.whereIn,
          whereNotIn: filter.whereNotIn,
          isNull: filter.isNull,
        );
      }
    }

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return await query.get();
  }

  /// Stream a document
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamDocument(
    String collection,
    String documentId,
  ) {
    return _firestore.collection(collection).doc(documentId).snapshots();
  }

  /// Stream a collection
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection(
    String collection, {
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(collection);

    if (filters != null) {
      for (final filter in filters) {
        query = query.where(
          filter.field,
          isEqualTo: filter.isEqualTo,
          isNotEqualTo: filter.isNotEqualTo,
          isLessThan: filter.isLessThan,
          isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
          isGreaterThan: filter.isGreaterThan,
          isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
          arrayContains: filter.arrayContains,
          arrayContainsAny: filter.arrayContainsAny,
          whereIn: filter.whereIn,
          whereNotIn: filter.whereNotIn,
          isNull: filter.isNull,
        );
      }
    }

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots();
  }

  /// Batch write operations
  WriteBatch batch() {
    return _firestore.batch();
  }

  /// Run a transaction
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) transactionHandler,
  ) {
    return _firestore.runTransaction(transactionHandler);
  }
}

/// Query filter helper class
class QueryFilter {
  final String field;
  final Object? isEqualTo;
  final Object? isNotEqualTo;
  final Object? isLessThan;
  final Object? isLessThanOrEqualTo;
  final Object? isGreaterThan;
  final Object? isGreaterThanOrEqualTo;
  final Object? arrayContains;
  final Iterable<Object?>? arrayContainsAny;
  final Iterable<Object?>? whereIn;
  final Iterable<Object?>? whereNotIn;
  final bool? isNull;

  QueryFilter({
    required this.field,
    this.isEqualTo,
    this.isNotEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.arrayContains,
    this.arrayContainsAny,
    this.whereIn,
    this.whereNotIn,
    this.isNull,
  });
}

/// Firestore service provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirestoreService(firestore);
});
