import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/activity_log.dart';
import '../controllers/activity_controller.dart';

/// Activity Feed Screen for Family Members
/// Shows timeline of senior-caregiver interactions
class FamilyActivityFeedScreen extends ConsumerStatefulWidget {
  const FamilyActivityFeedScreen({super.key});

  @override
  ConsumerState<FamilyActivityFeedScreen> createState() =>
      _FamilyActivityFeedScreenState();
}

class _FamilyActivityFeedScreenState
    extends ConsumerState<FamilyActivityFeedScreen> {
  ActivityType? _filterType;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final linkedSeniorId = user?.linkedSeniorId;

    if (linkedSeniorId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Activity Feed'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.link_off,
                size: 80,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'No Senior Linked',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Contact administrator to link you to a senior',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final activitiesAsync = ref.watch(activitiesStreamProvider(linkedSeniorId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Feed'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Filter Menu
          PopupMenuButton<ActivityType?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter Activities',
            onSelected: (type) {
              setState(() => _filterType = type);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All Activities'),
              ),
              const PopupMenuDivider(),
              ...ActivityType.values.map((type) => PopupMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(
                          _getActivityIcon(type),
                          size: 20,
                          color: _getActivityColor(type),
                        ),
                        const SizedBox(width: 8),
                        Text(_getActivityLabel(type)),
                      ],
                    ),
                  )),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(activitiesStreamProvider(linkedSeniorId));
            },
          ),
        ],
      ),
      body: activitiesAsync.when(
        data: (activities) {
          // Apply filter
          var filteredActivities = activities;
          if (_filterType != null) {
            filteredActivities = activities
                .where((a) => a.activityType == _filterType)
                .toList();
          }

          // Sort by timestamp (newest first)
          filteredActivities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          if (filteredActivities.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _filterType == null ? Icons.history : Icons.filter_alt_off,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _filterType == null
                        ? 'No Activities Yet'
                        : 'No ${_getActivityLabel(_filterType!)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _filterType == null
                        ? 'Activity history will appear here'
                        : 'Try a different filter',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  if (_filterType != null) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _filterType = null),
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear Filter'),
                    ),
                  ],
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(activitiesStreamProvider(linkedSeniorId));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredActivities.length,
              itemBuilder: (context, index) {
                final activity = filteredActivities[index];
                return _buildActivityCard(context, activity, user?.name);
              },
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
              Text('Error loading activities: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(activitiesStreamProvider(linkedSeniorId));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, ActivityLog activity, String? currentUserName) {
    final color = _getActivityColor(activity.activityType);
    final icon = _getActivityIcon(activity.activityType);
    final label = _getActivityLabel(activity.activityType);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showActivityDetails(context, activity),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type Label
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Description
                    Text(
                      activity.description,
                      style: const TextStyle(fontSize: 14),
                    ),

                    // Timestamp
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimestamp(activity.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  void _showActivityDetails(BuildContext context, ActivityLog activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getActivityIcon(activity.activityType),
              color: _getActivityColor(activity.activityType),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_getActivityLabel(activity.activityType)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Description', activity.description),
              _buildDetailRow('Date', DateFormat('MMM dd, yyyy').format(activity.timestamp)),
              _buildDetailRow('Time', DateFormat('hh:mm a').format(activity.timestamp)),
              if (activity.metadata != null && activity.metadata!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(),
                const Text(
                  'Additional Information:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...activity.metadata!.entries.map((entry) =>
                    _buildDetailRow(entry.key, entry.value.toString())),
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
      ),
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(timestamp);
    }
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.requestCreated:
        return Icons.add_circle;
      case ActivityType.requestAccepted:
        return Icons.check_circle;
      case ActivityType.requestCompleted:
        return Icons.done_all;
      case ActivityType.requestCancelled:
        return Icons.cancel;
      case ActivityType.checkinCreated:
        return Icons.favorite;
      case ActivityType.messagesSent:
        return Icons.message;
      case ActivityType.emergencyTriggered:
        return Icons.warning;
      case ActivityType.emergencyResolved:
        return Icons.check;
    }
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.requestCreated:
        return Colors.blue;
      case ActivityType.requestAccepted:
        return Colors.orange;
      case ActivityType.requestCompleted:
        return Colors.green;
      case ActivityType.requestCancelled:
        return Colors.grey;
      case ActivityType.checkinCreated:
        return Colors.pink;
      case ActivityType.messagesSent:
        return Colors.cyan;
      case ActivityType.emergencyTriggered:
        return Colors.red;
      case ActivityType.emergencyResolved:
        return Colors.teal;
    }
  }

  String _getActivityLabel(ActivityType type) {
    switch (type) {
      case ActivityType.requestCreated:
        return 'Request Created';
      case ActivityType.requestAccepted:
        return 'Request Accepted';
      case ActivityType.requestCompleted:
        return 'Request Completed';
      case ActivityType.requestCancelled:
        return 'Request Cancelled';
      case ActivityType.checkinCreated:
        return 'Check-in Submitted';
      case ActivityType.messagesSent:
        return 'Messages Sent';
      case ActivityType.emergencyTriggered:
        return 'Emergency Alert';
      case ActivityType.emergencyResolved:
        return 'Emergency Resolved';
    }
  }
}
