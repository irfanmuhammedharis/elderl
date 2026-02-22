import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../requests/data/request_repository.dart';
import '../../../checkin/data/checkin_repository.dart';
import '../controllers/family_controller.dart';

/// Activity item model for unified timeline view
class ActivityItem {
  final String id;
  final String type; // 'request', 'checkin', 'emergency'
  final String title;
  final String description;
  final DateTime timestamp;
  final String status;
  final IconData icon;
  final Color color;

  ActivityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.status,
    required this.icon,
    required this.color,
  });
}

/// Family Activity Screen - Shows timeline of linked senior's activities
class FamilyActivityScreen extends ConsumerStatefulWidget {
  const FamilyActivityScreen({super.key});

  @override
  ConsumerState<FamilyActivityScreen> createState() => _FamilyActivityScreenState();
}

class _FamilyActivityScreenState extends ConsumerState<FamilyActivityScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final linkedSeniorAsync = ref.watch(linkedSeniorStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Timeline'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.familyHome),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter Activities',
            onSelected: (value) => setState(() => _selectedFilter = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Activities')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'request', child: Text('Requests Only')),
              const PopupMenuItem(value: 'checkin', child: Text('Check-ins Only')),
            ],
          ),
        ],
      ),
      body: linkedSeniorAsync.when(
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
                onPressed: () => ref.invalidate(linkedSeniorStreamProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (linkedSenior) {
          if (linkedSenior == null) {
            return _buildNoSeniorLinked(context);
          }
          return _buildActivityTimeline(context, ref, linkedSenior);
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go(AppRoutes.familyHome);
              break;
            case 1:
              break;
            case 2:
              context.push(AppRoutes.familyCheckins);
              break;
            case 3:
              context.push(AppRoutes.profile);
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.timeline_outlined),
            selectedIcon: Icon(Icons.timeline),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'Check-ins',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildNoSeniorLinked(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'No Senior Linked',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Link to a senior to view their activity timeline.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go(AppRoutes.familyHome),
              icon: const Icon(Icons.home),
              label: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTimeline(BuildContext context, WidgetRef ref, AppUser linkedSenior) {
    final requestsAsync = ref.watch(seniorRequestsStreamProvider(linkedSenior.uid));
    final checkInsAsync = ref.watch(seniorCheckInsStreamProvider(linkedSenior.uid));

    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error loading requests: $e')),
      data: (requests) {
        return checkInsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error loading check-ins: $e')),
          data: (checkIns) {
            // Combine and sort activities
            final activities = _combineActivities(requests, checkIns);
            
            // Apply filter
            final filteredActivities = _selectedFilter == 'all'
                ? activities
                : activities.where((a) => a.type == _selectedFilter).toList();

            if (filteredActivities.isEmpty) {
              return _buildEmptyState(context);
            }

            return Column(
              children: [
                // Senior Info Header
                _buildSeniorHeader(context, linkedSenior),
                
                // Activity Stats
                _buildActivityStats(context, activities),
                
                // Timeline
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredActivities.length,
                    itemBuilder: (context, index) {
                      final activity = filteredActivities[index];
                      final isFirst = index == 0;
                      final isLast = index == filteredActivities.length - 1;
                      return _buildTimelineItem(context, activity, isFirst, isLast);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<ActivityItem> _combineActivities(List<HelpRequest> requests, List<CheckIn> checkIns) {
    final activities = <ActivityItem>[];

    // Add requests
    for (final request in requests) {
      activities.add(ActivityItem(
        id: request.id ?? '',
        type: 'request',
        title: '${request.type.toUpperCase()} Request',
        description: request.description,
        timestamp: request.createdAt ?? DateTime.now(),
        status: request.status,
        icon: _getRequestIcon(request.type),
        color: _getRequestColor(request.type),
      ));
    }

    // Add check-ins
    for (final checkIn in checkIns) {
      activities.add(ActivityItem(
        id: checkIn.id ?? '',
        type: 'checkin',
        title: checkIn.status == 'ok' ? "Daily Check-in: I'm OK" : 'Daily Check-in',
        description: checkIn.message ?? 'Status confirmed',
        timestamp: checkIn.checkinTime ?? DateTime.now(),
        status: checkIn.status,
        icon: Icons.fact_check,
        color: checkIn.status == 'ok' ? Colors.green : Colors.orange,
      ));
    }

    // Sort by timestamp (newest first)
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return activities;
  }

  Widget _buildSeniorHeader(BuildContext context, AppUser senior) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryColor.withOpacity(0.1),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primaryColor,
            child: Text(
              senior.name.isNotEmpty ? senior.name[0].toUpperCase() : 'S',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  senior.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Activity Timeline',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityStats(BuildContext context, List<ActivityItem> activities) {
    final requestCount = activities.where((a) => a.type == 'request').length;
    final checkinCount = activities.where((a) => a.type == 'checkin').length;
    final today = DateTime.now();
    final todayCount = activities.where((a) => 
      a.timestamp.year == today.year && 
      a.timestamp.month == today.month && 
      a.timestamp.day == today.day
    ).length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard('Today', todayCount.toString(), Icons.today, Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('Requests', requestCount.toString(), Icons.assignment, Colors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('Check-ins', checkinCount.toString(), Icons.fact_check, Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
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
            value,
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

  Widget _buildTimelineItem(BuildContext context, ActivityItem activity, bool isFirst, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line
          SizedBox(
            width: 40,
            child: Column(
              children: [
                if (!isFirst)
                  Container(width: 2, height: 16, color: Colors.grey[300]),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: activity.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: activity.color, width: 2),
                  ),
                  child: Icon(activity.icon, size: 16, color: activity.color),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: Colors.grey[300])),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content card
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            activity.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        _buildStatusBadge(activity.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      activity.description,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTimestamp(activity.timestamp),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'No Activities Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              _selectedFilter == 'all'
                  ? 'Activities will appear here when your senior uses the app.'
                  : 'No ${_selectedFilter}s found. Try changing the filter.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getRequestIcon(String type) {
    switch (type.toLowerCase()) {
      case 'medical':
        return Icons.local_hospital;
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'companion':
        return Icons.people;
      default:
        return Icons.help_outline;
    }
  }

  Color _getRequestColor(String type) {
    switch (type.toLowerCase()) {
      case 'medical':
        return Colors.red;
      case 'food':
        return Colors.orange;
      case 'transport':
        return Colors.blue;
      case 'companion':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ok':
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'accepted':
      case 'in_progress':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minutes ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy - h:mm a').format(timestamp);
    }
  }
}
