import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/routing/app_router.dart';
import '../../../emergency/data/emergency_repository.dart';

/// Provider for all emergencies stream (admin view)
final adminEmergenciesStreamProvider = StreamProvider.autoDispose<List<EmergencyAlert>>((ref) {
  final emergencyRepo = ref.watch(emergencyRepositoryProvider);
  return emergencyRepo.streamAllEmergencies();
});

/// Admin Emergencies Screen - View and manage emergency alerts
class AdminEmergenciesScreen extends ConsumerStatefulWidget {
  const AdminEmergenciesScreen({super.key});

  @override
  ConsumerState<AdminEmergenciesScreen> createState() => _AdminEmergenciesScreenState();
}

class _AdminEmergenciesScreenState extends ConsumerState<AdminEmergenciesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emergenciesAsync = ref.watch(adminEmergenciesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Alerts'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.adminHome),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminEmergenciesStreamProvider),
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.warning), text: 'Active'),
            Tab(icon: Icon(Icons.check_circle), text: 'Responded'),
            Tab(icon: Icon(Icons.history), text: 'Resolved'),
          ],
        ),
      ),
      body: emergenciesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Error: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(adminEmergenciesStreamProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (emergencies) {
          return Column(
            children: [
              // Alert Banner for Active Emergencies
              if (emergencies.where((e) => e.status == 'active').isNotEmpty)
                _buildAlertBanner(emergencies.where((e) => e.status == 'active').length),
              
              // Stats Overview
              _buildStatsOverview(emergencies),
              
              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _EmergencyListView(
                      emergencies: emergencies.where((e) => e.status == 'active').toList(),
                      emptyMessage: 'No active emergencies',
                      emptyIcon: Icons.check_circle,
                      emptyIconColor: Colors.green,
                    ),
                    _EmergencyListView(
                      emergencies: emergencies.where((e) => e.status == 'responded').toList(),
                      emptyMessage: 'No responded emergencies',
                      emptyIcon: Icons.hourglass_empty,
                      emptyIconColor: Colors.blue,
                    ),
                    _EmergencyListView(
                      emergencies: emergencies.where((e) => e.status == 'resolved' || e.status == 'cancelled').toList(),
                      emptyMessage: 'No resolved emergencies',
                      emptyIcon: Icons.history,
                      emptyIconColor: Colors.grey,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAlertBanner(int activeCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade700, Colors.red.shade500],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$activeCount ACTIVE EMERGENCY${activeCount > 1 ? 'IES' : ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Text(
                  'Immediate attention required',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(List<EmergencyAlert> emergencies) {
    final active = emergencies.where((e) => e.status == 'active').length;
    final responded = emergencies.where((e) => e.status == 'responded').length;
    final resolved = emergencies.where((e) => e.status == 'resolved' || e.status == 'cancelled').length;
    final total = emergencies.length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('Active', active, Colors.red, Icons.warning)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatCard('Responded', responded, Colors.blue, Icons.person)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatCard('Resolved', resolved, Colors.green, Icons.check_circle)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatCard('Total', total, Colors.grey, Icons.emergency)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _EmergencyListView extends StatelessWidget {
  final List<EmergencyAlert> emergencies;
  final String emptyMessage;
  final IconData emptyIcon;
  final Color emptyIconColor;

  const _EmergencyListView({
    required this.emergencies,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.emptyIconColor,
  });

  @override
  Widget build(BuildContext context) {
    if (emergencies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 80, color: emptyIconColor.withOpacity(0.5)),
            const SizedBox(height: 24),
            Text(
              emptyMessage,
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: emergencies.length,
      itemBuilder: (context, index) => _EmergencyCard(emergency: emergencies[index]),
    );
  }
}

class _EmergencyCard extends ConsumerWidget {
  final EmergencyAlert emergency;

  const _EmergencyCard({required this.emergency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = emergency.status == 'active';
    final isResponded = emergency.status == 'responded';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive
            ? const BorderSide(color: Colors.red, width: 2)
            : BorderSide.none,
      ),
      child: Column(
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _getStatusColor(emergency.status).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(emergency.status),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(emergency.status),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'EMERGENCY ALERT',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _getStatusColor(emergency.status),
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        'ID: ${emergency.id?.substring(0, 8) ?? 'Unknown'}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(emergency.status),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Senior Info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.red.shade100,
                      child: Text(
                        emergency.seniorName.isNotEmpty
                            ? emergency.seniorName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            emergency.seniorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          if (emergency.seniorPhone != null)
                            Row(
                              children: [
                                Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  emergency.seniorPhone!,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    if (emergency.seniorPhone != null)
                      IconButton(
                        icon: const Icon(Icons.call, color: Colors.green),
                        onPressed: () async {
                          final phoneUri = Uri(scheme: 'tel', path: emergency.seniorPhone);
                          if (await canLaunchUrl(phoneUri)) {
                            await launchUrl(phoneUri);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not launch phone dialer')),
                              );
                            }
                          }
                        },
                        tooltip: 'Call Senior',
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Location
                if (emergency.address != null || emergency.latitude != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            emergency.address ??
                                'Lat: ${emergency.latitude?.toStringAsFixed(4)}, '
                                    'Lng: ${emergency.longitude?.toStringAsFixed(4)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        if (emergency.latitude != null)
                          IconButton(
                            icon: const Icon(Icons.map),
                            onPressed: () async {
                              final lat = emergency.latitude!;
                              final lng = emergency.longitude!;
                              final mapUrl = Uri.parse(
                                'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                              );
                              if (await canLaunchUrl(mapUrl)) {
                                await launchUrl(mapUrl, mode: LaunchMode.externalApplication);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Could not open maps')),
                                  );
                                }
                              }
                            },
                            tooltip: 'View on Map',
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                
                // Timestamps
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildTimeInfo(
                      'Triggered',
                      emergency.createdAtDateTime,
                      Icons.access_time,
                    ),
                    if (emergency.respondedAt != null)
                      _buildTimeInfo(
                        'Responded',
                        emergency.respondedAtDateTime,
                        Icons.person,
                      ),
                    if (emergency.resolvedAt != null)
                      _buildTimeInfo(
                        'Resolved',
                        emergency.resolvedAtDateTime,
                        Icons.check_circle,
                      ),
                  ],
                ),
                
                // Responder Info
                if (emergency.respondedByName != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Responded by: ${emergency.respondedByName}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Actions
                if (isActive || isResponded) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (isActive)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _respondToEmergency(context, ref),
                            icon: const Icon(Icons.person),
                            label: const Text('Respond'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      if (isActive) const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _resolveEmergency(context, ref),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Resolve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _cancelEmergency(context, ref),
                            icon: const Icon(Icons.cancel),
                            label: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                              side: const BorderSide(color: Colors.orange),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo(String label, DateTime? time, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          '$label: ${time != null ? DateFormat('MMM d, h:mm a').format(time) : 'Unknown'}',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: _getStatusColor(status),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.red;
      case 'responded':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'cancelled':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.warning;
      case 'responded':
        return Icons.person;
      case 'resolved':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Future<void> _respondToEmergency(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Respond to Emergency'),
        content: const Text('Mark this emergency as being responded to?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Respond'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(emergencyRepositoryProvider);
        await repo.respondToEmergency(emergency.id!, 'admin', 'Admin');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Marked as responded'), backgroundColor: Colors.blue),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _resolveEmergency(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Emergency'),
        content: const Text('Mark this emergency as resolved?'),
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

    if (confirmed == true) {
      try {
        final repo = ref.read(emergencyRepositoryProvider);
        await repo.resolveEmergency(emergency.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Emergency resolved'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _cancelEmergency(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Emergency'),
        content: const Text('Cancel this emergency as a false alarm?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Cancel Emergency'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(emergencyRepositoryProvider);
        await repo.cancelEmergency(emergency.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Emergency cancelled'), backgroundColor: Colors.orange),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
