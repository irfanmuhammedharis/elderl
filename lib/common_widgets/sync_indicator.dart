import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/sync_service.dart';

/// Widget to display sync status indicator
/// Shows users whether their data is synced with the cloud
class SyncIndicator extends ConsumerWidget {
  final bool showText;
  final double iconSize;

  const SyncIndicator({
    super.key,
    this.showText = true,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncServiceProvider);

    return GestureDetector(
      onTap: () => _showSyncDialog(context, ref, syncState),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getBackgroundColor(syncState.status).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getBackgroundColor(syncState.status).withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(syncState.status),
            if (showText) ...[
              const SizedBox(width: 6),
              Text(
                _getStatusText(syncState.status),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _getBackgroundColor(syncState.status),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return Icon(
          Icons.cloud_done,
          color: Colors.green,
          size: iconSize,
        );
      case SyncStatus.syncing:
        return SizedBox(
          width: iconSize,
          height: iconSize,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        );
      case SyncStatus.pendingSync:
        return Icon(
          Icons.cloud_upload,
          color: Colors.orange,
          size: iconSize,
        );
      case SyncStatus.offline:
        return Icon(
          Icons.cloud_off,
          color: Colors.grey,
          size: iconSize,
        );
      case SyncStatus.error:
        return Icon(
          Icons.cloud_off,
          color: Colors.red,
          size: iconSize,
        );
    }
  }

  Color _getBackgroundColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return Colors.green;
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.pendingSync:
        return Colors.orange;
      case SyncStatus.offline:
        return Colors.grey;
      case SyncStatus.error:
        return Colors.red;
    }
  }

  String _getStatusText(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.pendingSync:
        return 'Pending';
      case SyncStatus.offline:
        return 'Offline';
      case SyncStatus.error:
        return 'Error';
    }
  }

  void _showSyncDialog(BuildContext context, WidgetRef ref, SyncState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            _buildIcon(state.status),
            const SizedBox(width: 12),
            Text(_getStatusText(state.status)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getStatusDescription(state)),
            if (state.lastSyncTime != null) ...[
              const SizedBox(height: 12),
              Text(
                'Last synced: ${_formatTime(state.lastSyncTime!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
            if (state.hasPendingWrites) ...[
              const SizedBox(height: 8),
              Text(
                'Pending changes: ${state.pendingWrites}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange[700],
                ),
              ),
            ],
            if (state.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error: ${state.errorMessage}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (state.status == SyncStatus.offline)
            TextButton(
              onPressed: () {
                ref.read(syncServiceProvider.notifier).goOnline();
                Navigator.pop(context);
              },
              child: const Text('Reconnect'),
            ),
          if (state.hasPendingWrites && state.status != SyncStatus.offline)
            TextButton(
              onPressed: () {
                ref.read(syncServiceProvider.notifier).forceSync();
                Navigator.pop(context);
              },
              child: const Text('Sync Now'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getStatusDescription(SyncState state) {
    switch (state.status) {
      case SyncStatus.synced:
        return 'All your data is synced with the cloud. Changes made on any device will appear here.';
      case SyncStatus.syncing:
        return 'Synchronizing your data with the cloud...';
      case SyncStatus.pendingSync:
        return 'You have changes waiting to be synced. They will be uploaded when connection is restored.';
      case SyncStatus.offline:
        return 'You are currently offline. Changes will be saved locally and synced when you reconnect.';
      case SyncStatus.error:
        return 'There was an error syncing your data. Please try again.';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    } else {
      return '${diff.inDays} days ago';
    }
  }
}

/// Offline banner widget to show when user is offline
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    if (isOnline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.orange[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 18, color: Colors.orange[800]),
          const SizedBox(width: 8),
          Text(
            'You are offline. Changes will sync when connected.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange[900],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
