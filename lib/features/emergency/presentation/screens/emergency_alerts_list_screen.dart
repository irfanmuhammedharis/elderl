import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/emergency_repository.dart';
import '../controllers/emergency_alert_controller.dart';

/// Emergency Alerts List Screen for Caregivers and Family
/// Shows all emergency alerts from linked seniors
class EmergencyAlertsListScreen extends ConsumerWidget {
  const EmergencyAlertsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final emergenciesAsync = ref.watch(linkedSeniorsEmergenciesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Alerts'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(linkedSeniorsEmergenciesStreamProvider);
            },
          ),
        ],
      ),
      body: emergenciesAsync.when(
        data: (emergencies) {
          // Filter out nulls and separate active and resolved
          final validEmergencies = emergencies.whereType<EmergencyAlert>();
          
          final activeEmergencies = validEmergencies
              .where((e) => e.status == 'active' || e.status == 'responded')
              .toList()
            ..sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));

          final resolvedEmergencies = validEmergencies
              .where((e) => e.status == 'resolved' || e.status == 'cancelled')
              .toList()
            ..sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));

          if (emergencies.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shield,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Emergency Alerts',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All clear! No emergencies reported.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(linkedSeniorsEmergenciesStreamProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Active Emergencies Section
                if (activeEmergencies.isNotEmpty) ...[
                  Text(
                    'ACTIVE EMERGENCIES (${activeEmergencies.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...activeEmergencies.map((emergency) =>
                      _buildEmergencyCard(context, ref, emergency, user?.uid, true)),
                  const SizedBox(height: 24),
                ],

                // Resolved Emergencies Section
                if (resolvedEmergencies.isNotEmpty) ...[
                  Text(
                    'RECENT HISTORY (${resolvedEmergencies.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...resolvedEmergencies.take(10).map((emergency) =>
                      _buildEmergencyCard(context, ref, emergency, user?.uid, false)),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(linkedSeniorsEmergenciesStreamProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyCard(
    BuildContext context,
    WidgetRef ref,
    EmergencyAlert emergency,
    String? currentUserId,
    bool isActive,
  ) {
    final hasResponded = currentUserId != null &&
        emergency.respondedBy == currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isActive ? 4 : 2,
      color: isActive ? Colors.red[50] : null,
      child: InkWell(
        onTap: () => _showEmergencyDetails(context, ref, emergency, currentUserId),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Status Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(emergency.status).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStatusIcon(emergency.status),
                      color: _getStatusColor(emergency.status),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Senior Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emergency.seniorName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTimestamp(emergency.createdAtDateTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status Badge
                  Chip(
                    label: Text(
                      emergency.status.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: _getStatusColor(emergency.status),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),

              if (emergency.latitude != null && emergency.longitude != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Location: ${emergency.latitude!.toStringAsFixed(6)}, '
                        '${emergency.longitude!.toStringAsFixed(6)}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ],

              if (isActive) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: hasResponded || emergency.id == null
                            ? null
                            : () => _respondToEmergency(context, ref, emergency.id!, currentUserId!),
                        icon: Icon(hasResponded ? Icons.check : Icons.person),
                        label: Text(hasResponded ? 'You Responded' : 'Respond'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasResponded ? Colors.grey : Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: emergency.id == null
                            ? null
                            : () => _resolveEmergency(context, ref, emergency.id!),
                        icon: const Icon(Icons.done_all),
                        label: const Text('Resolve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (emergency.respondedBy != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Responded by: ${emergency.respondedByName ?? 'Unknown'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showEmergencyDetails(
    BuildContext context,
    WidgetRef ref,
    EmergencyAlert emergency,
    String? currentUserId,
  ) {
    showDialog(
      context: context,
      builder: (context) => EmergencyAlertDetailDialog(
        emergency: emergency,
        currentUserId: currentUserId,
      ),
    );
  }

  Future<void> _respondToEmergency(
    BuildContext context,
    WidgetRef ref,
    String alertId,
    String? currentUserId,
  ) async {
    if (currentUserId == null) return;

    await ref
        .read(emergencyAlertControllerProvider.notifier)
        .respondToEmergency(alertId, currentUserId);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Response recorded'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _resolveEmergency(
    BuildContext context,
    WidgetRef ref,
    String alertId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Emergency'),
        content: const Text(
          'Mark this emergency as resolved? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref
          .read(emergencyAlertControllerProvider.notifier)
          .resolveEmergency(alertId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency resolved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.red;
      case 'resolved':
        return Colors.green;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.warning;
      case 'resolved':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'Unknown';
    
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM dd, yyyy hh:mm a').format(timestamp);
    }
  }
}

/// Emergency Alert Detail Dialog
class EmergencyAlertDetailDialog extends StatelessWidget {
  final EmergencyAlert emergency;
  final String? currentUserId;

  const EmergencyAlertDetailDialog({
    super.key,
    required this.emergency,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning,
            color: Colors.red[700],
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('Emergency Details')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Senior', emergency.seniorName),
            _buildDetailRow('Status', emergency.status.toUpperCase()),
            _buildDetailRow(
              'Triggered',
              emergency.createdAtDateTime != null
                  ? DateFormat('MMM dd, yyyy hh:mm a').format(emergency.createdAtDateTime!)
                  : 'Unknown',
            ),
            if (emergency.latitude != null && emergency.longitude != null) ...[
              const SizedBox(height: 8),
              const Divider(),
              const Text(
                'Location:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('Lat: ${emergency.latitude!.toStringAsFixed(6)}'),
              Text('Lng: ${emergency.longitude!.toStringAsFixed(6)}'),
            ],
            if (emergency.respondedBy != null) ...[
              const SizedBox(height: 8),
              const Divider(),
              const Text(
                'Response:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('Responded by: ${emergency.respondedByName ?? "Unknown"}'),
              if (emergency.respondedAtDateTime != null)
                Text('Response time: ${DateFormat('MMM dd, yyyy hh:mm a').format(emergency.respondedAtDateTime!)}'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
