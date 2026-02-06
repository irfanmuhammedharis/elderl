import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Sync status enum
enum SyncStatus {
  synced,
  syncing,
  pendingSync,
  offline,
  error,
}

/// Sync state model
class SyncState {
  final SyncStatus status;
  final DateTime? lastSyncTime;
  final String? errorMessage;
  final int pendingWrites;

  const SyncState({
    this.status = SyncStatus.synced,
    this.lastSyncTime,
    this.errorMessage,
    this.pendingWrites = 0,
  });

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncTime,
    String? errorMessage,
    int? pendingWrites,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      errorMessage: errorMessage,
      pendingWrites: pendingWrites ?? this.pendingWrites,
    );
  }

  bool get isOnline => status != SyncStatus.offline;
  bool get hasPendingWrites => pendingWrites > 0;
}

/// Service to manage cross-platform Firebase synchronization
/// Ensures data consistency between Android, iOS, and Web apps
class SyncService extends StateNotifier<SyncState> {
  final FirebaseFirestore _firestore;
  final FirebaseDatabase _realtimeDb;
  
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<DocumentSnapshot>? _syncCheckSubscription;
  Timer? _syncCheckTimer;

  SyncService(this._firestore, this._realtimeDb) : super(const SyncState()) {
    _initializeSync();
  }

  /// Initialize sync monitoring
  void _initializeSync() {
    // Monitor connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _handleConnectivityChange,
    );

    // Initial connectivity check
    _checkConnectivity();

    // Monitor Firestore pending writes
    _monitorPendingWrites();

    // Periodic sync check (every 30 seconds)
    _syncCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _performSyncCheck(),
    );
  }

  /// Handle connectivity changes
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final hasConnection = results.any((r) => 
      r == ConnectivityResult.wifi || 
      r == ConnectivityResult.mobile || 
      r == ConnectivityResult.ethernet
    );

    if (hasConnection) {
      state = state.copyWith(status: SyncStatus.syncing);
      _performSyncCheck();
    } else {
      state = state.copyWith(status: SyncStatus.offline);
    }
  }

  /// Check current connectivity
  Future<void> _checkConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _handleConnectivityChange(results);
    } catch (e) {
      debugPrint('Connectivity check failed: $e');
    }
  }

  /// Monitor Firestore pending writes using snapshots metadata
  void _monitorPendingWrites() {
    // Use a lightweight document to check sync status
    // Create a sync check document path
    _syncCheckSubscription = _firestore
        .collection('_sync_check')
        .doc('status')
        .snapshots(includeMetadataChanges: true)
        .listen(
      (snapshot) {
        final hasPendingWrites = snapshot.metadata.hasPendingWrites;
        final isFromCache = snapshot.metadata.isFromCache;

        if (hasPendingWrites) {
          state = state.copyWith(
            status: SyncStatus.pendingSync,
            pendingWrites: state.pendingWrites + 1,
          );
        } else if (isFromCache && state.status != SyncStatus.offline) {
          state = state.copyWith(status: SyncStatus.syncing);
        } else if (!isFromCache && !hasPendingWrites) {
          state = state.copyWith(
            status: SyncStatus.synced,
            lastSyncTime: DateTime.now(),
            pendingWrites: 0,
          );
        }
      },
      onError: (error) {
        state = state.copyWith(
          status: SyncStatus.error,
          errorMessage: error.toString(),
        );
      },
    );
  }

  /// Perform a sync check by reading from server
  Future<void> _performSyncCheck() async {
    if (state.status == SyncStatus.offline) return;

    try {
      state = state.copyWith(status: SyncStatus.syncing);

      // Force a server read to verify connectivity
      await _firestore
          .collection('_sync_check')
          .doc('status')
          .get(const GetOptions(source: Source.server));

      state = state.copyWith(
        status: SyncStatus.synced,
        lastSyncTime: DateTime.now(),
        errorMessage: null,
      );
    } catch (e) {
      // If server read fails, we're likely offline or have network issues
      if (e.toString().contains('unavailable') || 
          e.toString().contains('network')) {
        state = state.copyWith(status: SyncStatus.offline);
      } else {
        state = state.copyWith(
          status: SyncStatus.error,
          errorMessage: e.toString(),
        );
      }
    }
  }

  /// Force sync all pending writes
  Future<void> forceSync() async {
    if (state.status == SyncStatus.offline) {
      throw Exception('Cannot sync while offline');
    }

    state = state.copyWith(status: SyncStatus.syncing);

    try {
      // Wait for all pending writes to complete
      await _firestore.waitForPendingWrites();
      
      state = state.copyWith(
        status: SyncStatus.synced,
        lastSyncTime: DateTime.now(),
        pendingWrites: 0,
      );
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Clear local cache and resync from server
  /// Use with caution - this will remove all cached data
  Future<void> clearCacheAndResync() async {
    if (state.status == SyncStatus.offline) {
      throw Exception('Cannot clear cache while offline');
    }

    try {
      state = state.copyWith(status: SyncStatus.syncing);
      
      // Clear Firestore cache
      await _firestore.clearPersistence();
      
      // Re-enable network to fetch fresh data
      await _firestore.enableNetwork();
      
      state = state.copyWith(
        status: SyncStatus.synced,
        lastSyncTime: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Disable network (for testing offline mode)
  Future<void> goOffline() async {
    await _firestore.disableNetwork();
    if (!kIsWeb) {
      _realtimeDb.goOffline();
    }
    state = state.copyWith(status: SyncStatus.offline);
  }

  /// Enable network
  Future<void> goOnline() async {
    await _firestore.enableNetwork();
    if (!kIsWeb) {
      _realtimeDb.goOnline();
    }
    state = state.copyWith(status: SyncStatus.syncing);
    await _performSyncCheck();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncCheckSubscription?.cancel();
    _syncCheckTimer?.cancel();
    super.dispose();
  }
}

/// Sync service provider
final syncServiceProvider = StateNotifierProvider<SyncService, SyncState>((ref) {
  return SyncService(
    FirebaseFirestore.instance,
    FirebaseDatabase.instance,
  );
});

/// Provider to check if data is synced
final isSyncedProvider = Provider<bool>((ref) {
  final syncState = ref.watch(syncServiceProvider);
  return syncState.status == SyncStatus.synced;
});

/// Provider to check if app is online
final isOnlineProvider = Provider<bool>((ref) {
  final syncState = ref.watch(syncServiceProvider);
  return syncState.isOnline;
});
