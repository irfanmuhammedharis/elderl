import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/utils/constants.dart';
import '../../../requests/data/request_repository.dart';
import '../controllers/caregiver_controller.dart';

/// Screen displaying all available pending requests for caregivers
class CaregiverRequestsScreen extends ConsumerWidget {
  const CaregiverRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingRequestsAsync = ref.watch(pendingRequestsStreamProvider);
    final myRequestsAsync = ref.watch(myAssignedRequestsStreamProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Requests'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.caregiverHome);
              }
            },
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Available', icon: Icon(Icons.pending_actions)),
              Tab(text: 'My Tasks', icon: Icon(Icons.assignment)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Available/Pending Requests Tab
            _buildRequestsList(
              context,
              ref,
              pendingRequestsAsync,
              isPending: true,
            ),
            // My Assigned Requests Tab
            _buildRequestsList(
              context,
              ref,
              myRequestsAsync,
              isPending: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<HelpRequest>> requestsAsync, {
    required bool isPending,
  }) {
    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $e'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (isPending) {
                  ref.invalidate(pendingRequestsStreamProvider);
                } else {
                  ref.invalidate(myAssignedRequestsStreamProvider);
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPending ? Icons.inbox : Icons.assignment_turned_in,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  isPending ? 'No pending requests' : 'No active tasks',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  isPending
                      ? 'Check back later for new requests'
                      : 'Accept a request to start helping',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            if (isPending) {
              ref.invalidate(pendingRequestsStreamProvider);
            } else {
              ref.invalidate(myAssignedRequestsStreamProvider);
            }
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _RequestCard(
                request: request,
                isPending: isPending,
              );
            },
          ),
        );
      },
    );
  }
}

class _RequestCard extends ConsumerWidget {
  final HelpRequest request;
  final bool isPending;

  const _RequestCard({
    required this.request,
    required this.isPending,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(caregiverRequestControllerProvider.notifier);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showRequestDetails(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  _buildTypeIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${request.type.toUpperCase()} Request',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          request.seniorName,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(context),
                ],
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                request.description,
                style: Theme.of(context).textTheme.bodyLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Location if available
              if (request.address != null) ...[
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        request.address!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Time
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimeAgo(request.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isPending) ...[
                    ElevatedButton.icon(
                      onPressed: () async {
                        await controller.acceptRequest(request.id!);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Request accepted!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ] else ...[
                    if (request.status == AppConstants.statusAccepted)
                      ElevatedButton.icon(
                        onPressed: () async {
                          await controller.markInProgress(request.id!);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Marked as in progress'),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    if (request.status == AppConstants.statusInProgress)
                      ElevatedButton.icon(
                        onPressed: () async {
                          await controller.completeRequest(request.id!);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Request completed!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Complete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon() {
    final color = _getTypeColor();
    final icon = _getTypeIcon();
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      radius: 24,
      child: Icon(icon, color: color, size: 28),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final color = _getStatusColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _formatStatus(request.status),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getTypeColor() {
    switch (request.type.toLowerCase()) {
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

  IconData _getTypeIcon() {
    switch (request.type.toLowerCase()) {
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

  Color _getStatusColor() {
    switch (request.status) {
      case AppConstants.statusPending:
        return Colors.orange;
      case AppConstants.statusAccepted:
        return Colors.blue;
      case AppConstants.statusInProgress:
        return Colors.purple;
      case AppConstants.statusCompleted:
        return Colors.green;
      case AppConstants.statusCancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case AppConstants.statusPending:
        return 'Pending';
      case AppConstants.statusAccepted:
        return 'Accepted';
      case AppConstants.statusInProgress:
        return 'In Progress';
      case AppConstants.statusCompleted:
        return 'Completed';
      case AppConstants.statusCancelled:
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _formatTimeAgo(DateTime? time) {
    if (time == null) return 'Unknown';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}/${time.year}';
  }

  void _showRequestDetails(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _RequestDetailsSheet(
          request: request,
          scrollController: scrollController,
          isPending: isPending,
        ),
      ),
    );
  }
}

class _RequestDetailsSheet extends ConsumerWidget {
  final HelpRequest request;
  final ScrollController scrollController;
  final bool isPending;

  const _RequestDetailsSheet({
    required this.request,
    required this.scrollController,
    required this.isPending,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(caregiverRequestControllerProvider.notifier);

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            '${request.type.toUpperCase()} Request',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'From ${request.seniorName}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),

          // Description
          Text(
            'Description',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            request.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),

          // Location
          if (request.address != null) ...[
            Text(
              'Location',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on, color: Colors.red),
                title: Text(request.address!),
                trailing: IconButton(
                  icon: const Icon(Icons.map),
                  onPressed: () async {
                    final lat = request.latitude;
                    final lng = request.longitude;
                    final Uri mapUrl;
                    
                    if (lat != null && lng != null) {
                      mapUrl = Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                      );
                    } else {
                      // Use address for search if no coordinates
                      final encodedAddress = Uri.encodeComponent(request.address!);
                      mapUrl = Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=$encodedAddress',
                      );
                    }
                    
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
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Status
          Text(
            'Status',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          _buildStatusTimeline(context),
          const SizedBox(height: 32),

          // Actions
          if (isPending)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await controller.acceptRequest(request.id!);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Request accepted!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to accept: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.check),
                label: const Text('Accept Request'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            )
          else ...[
            if (request.status == AppConstants.statusAccepted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await controller.markInProgress(request.id!);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Task'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            if (request.status == AppConstants.statusInProgress)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await controller.completeRequest(request.id!);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Mark as Complete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(BuildContext context) {
    final steps = [
      _TimelineStep(
        title: 'Created',
        subtitle: request.createdAt != null
            ? '${request.createdAt!.day}/${request.createdAt!.month} at ${request.createdAt!.hour}:${request.createdAt!.minute.toString().padLeft(2, '0')}'
            : null,
        isCompleted: true,
        isActive: request.status == AppConstants.statusPending,
      ),
      _TimelineStep(
        title: 'Accepted',
        subtitle: request.assignedToName,
        isCompleted: request.status != AppConstants.statusPending,
        isActive: request.status == AppConstants.statusAccepted,
      ),
      _TimelineStep(
        title: 'In Progress',
        isCompleted: request.status == AppConstants.statusInProgress ||
            request.status == AppConstants.statusCompleted,
        isActive: request.status == AppConstants.statusInProgress,
      ),
      _TimelineStep(
        title: 'Completed',
        subtitle: request.completedAt != null
            ? '${request.completedAt!.day}/${request.completedAt!.month}'
            : null,
        isCompleted: request.status == AppConstants.statusCompleted,
        isActive: request.status == AppConstants.statusCompleted,
      ),
    ];

    return Column(
      children: steps.map((step) => _buildTimelineItem(context, step)).toList(),
    );
  }

  Widget _buildTimelineItem(BuildContext context, _TimelineStep step) {
    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: step.isCompleted
                    ? Colors.green
                    : step.isActive
                        ? Colors.blue
                        : Colors.grey[300],
              ),
              child: step.isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            Container(
              width: 2,
              height: 32,
              color: step.isCompleted ? Colors.green : Colors.grey[300],
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: TextStyle(
                  fontWeight:
                      step.isActive ? FontWeight.bold : FontWeight.normal,
                  color: step.isActive ? Colors.blue : null,
                ),
              ),
              if (step.subtitle != null)
                Text(
                  step.subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineStep {
  final String title;
  final String? subtitle;
  final bool isCompleted;
  final bool isActive;

  _TimelineStep({
    required this.title,
    this.subtitle,
    this.isCompleted = false,
    this.isActive = false,
  });
}
