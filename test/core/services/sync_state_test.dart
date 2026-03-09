import 'package:flutter_test/flutter_test.dart';
import 'package:elderl/core/services/sync_service.dart';

void main() {
  group('SyncStatus enum', () {
    test('should have all expected values', () {
      expect(SyncStatus.values.length, 5);
      expect(SyncStatus.values, contains(SyncStatus.synced));
      expect(SyncStatus.values, contains(SyncStatus.syncing));
      expect(SyncStatus.values, contains(SyncStatus.pendingSync));
      expect(SyncStatus.values, contains(SyncStatus.offline));
      expect(SyncStatus.values, contains(SyncStatus.error));
    });
  });

  group('SyncState', () {
    test('default state has correct values', () {
      const state = SyncState();
      expect(state.status, SyncStatus.synced);
      expect(state.lastSyncTime, isNull);
      expect(state.errorMessage, isNull);
      expect(state.pendingWrites, 0);
    });

    test('isOnline returns true when not offline', () {
      const synced = SyncState(status: SyncStatus.synced);
      const syncing = SyncState(status: SyncStatus.syncing);
      const pending = SyncState(status: SyncStatus.pendingSync);
      const error = SyncState(status: SyncStatus.error);
      const offline = SyncState(status: SyncStatus.offline);

      expect(synced.isOnline, isTrue);
      expect(syncing.isOnline, isTrue);
      expect(pending.isOnline, isTrue);
      expect(error.isOnline, isTrue);
      expect(offline.isOnline, isFalse);
    });

    test('hasPendingWrites returns true when pendingWrites > 0', () {
      const noPending = SyncState(pendingWrites: 0);
      const hasPending = SyncState(pendingWrites: 3);

      expect(noPending.hasPendingWrites, isFalse);
      expect(hasPending.hasPendingWrites, isTrue);
    });

    test('copyWith updates specified fields', () {
      final now = DateTime.now();
      const original = SyncState();
      final updated = original.copyWith(
        status: SyncStatus.offline,
        lastSyncTime: now,
        errorMessage: 'test error',
        pendingWrites: 5,
      );

      expect(updated.status, SyncStatus.offline);
      expect(updated.lastSyncTime, now);
      expect(updated.errorMessage, 'test error');
      expect(updated.pendingWrites, 5);
    });

    test('copyWith preserves unspecified fields', () {
      final now = DateTime.now();
      final original = SyncState(
        status: SyncStatus.syncing,
        lastSyncTime: now,
        pendingWrites: 2,
      );
      final updated = original.copyWith(status: SyncStatus.synced);

      expect(updated.status, SyncStatus.synced);
      expect(updated.lastSyncTime, now);
      expect(updated.pendingWrites, 2);
    });

    test('copyWith clears errorMessage when set to null', () {
      const original = SyncState(
        status: SyncStatus.error,
        errorMessage: 'some error',
      );
      // copyWith always re-assigns errorMessage (no ?? fallback)
      final updated = original.copyWith(
        status: SyncStatus.synced,
        errorMessage: null,
      );

      expect(updated.errorMessage, isNull);
    });
  });
}
