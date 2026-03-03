import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firebase Realtime Database instance provider
final realtimeDbProvider = Provider<FirebaseDatabase>((ref) {
  return FirebaseDatabase.instance;
});

/// Realtime Database service for real-time operations
/// Used for emergencies where low latency is critical
class RealtimeDbService {
  final FirebaseDatabase _database;

  RealtimeDbService(this._database);

  /// Get a database reference
  DatabaseReference ref(String path) {
    return _database.ref(path);
  }

  /// Get the root reference
  DatabaseReference get root => _database.ref();

  /// Push new data with auto-generated key
  Future<String> push(String path, Map<String, dynamic> data) async {
    final ref = _database.ref(path).push();
    await ref.set({
      ...data,
      'createdAt': ServerValue.timestamp,
      'updatedAt': ServerValue.timestamp,
    });
    return ref.key!;
  }

  /// Set data at a specific path
  Future<void> set(String path, Map<String, dynamic> data) async {
    await _database.ref(path).set({
      ...data,
      'updatedAt': ServerValue.timestamp,
    });
  }

  /// Update data at a specific path
  Future<void> update(String path, Map<String, dynamic> data) async {
    await _database.ref(path).update({
      ...data,
      'updatedAt': ServerValue.timestamp,
    });
  }

  /// Remove data at a specific path
  Future<void> remove(String path) async {
    await _database.ref(path).remove();
  }

  /// Atomic multi-path update — writes to multiple paths in a single operation
  Future<void> multiPathUpdate(Map<String, dynamic> updates) async {
    await _database.ref().update(updates);
  }

  /// Generate a new push key without writing data
  String generateKey(String path) {
    return _database.ref(path).push().key!;
  }

  /// Get data once
  Future<DataSnapshot> get(String path) async {
    return await _database.ref(path).get();
  }

  /// Query data with ordering
  Query query(
    String path, {
    String? orderByChild,
    Object? equalTo,
    Object? startAt,
    Object? endAt,
    int? limitToFirst,
    int? limitToLast,
  }) {
    Query query = _database.ref(path);

    if (orderByChild != null) {
      query = query.orderByChild(orderByChild);
    }

    if (equalTo != null) {
      query = query.equalTo(equalTo);
    }

    if (startAt != null) {
      query = query.startAt(startAt);
    }

    if (endAt != null) {
      query = query.endAt(endAt);
    }

    if (limitToFirst != null) {
      query = query.limitToFirst(limitToFirst);
    }

    if (limitToLast != null) {
      query = query.limitToLast(limitToLast);
    }

    return query;
  }

  /// Stream data changes at a path
  Stream<DatabaseEvent> stream(String path) {
    return _database.ref(path).onValue;
  }

  /// Stream child added events
  Stream<DatabaseEvent> onChildAdded(String path) {
    return _database.ref(path).onChildAdded;
  }

  /// Stream child changed events
  Stream<DatabaseEvent> onChildChanged(String path) {
    return _database.ref(path).onChildChanged;
  }

  /// Stream child removed events
  Stream<DatabaseEvent> onChildRemoved(String path) {
    return _database.ref(path).onChildRemoved;
  }

  /// Enable offline persistence
  void enablePersistence() {
    _database.setPersistenceEnabled(true);
  }

  /// Keep data synced for offline access
  void keepSynced(String path, bool synced) {
    _database.ref(path).keepSynced(synced);
  }

  /// Run a transaction
  Future<TransactionResult> runTransaction(
    String path,
    TransactionHandler transactionHandler,
  ) {
    return _database.ref(path).runTransaction(transactionHandler);
  }

  /// Get server timestamp
  Map<String, dynamic> get serverTimestamp => ServerValue.timestamp;
}

/// Realtime Database service provider
final realtimeDbServiceProvider = Provider<RealtimeDbService>((ref) {
  final database = ref.watch(realtimeDbProvider);
  return RealtimeDbService(database);
});
