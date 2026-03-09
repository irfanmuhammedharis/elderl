import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/utils/constants.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../emergency/data/emergency_repository.dart';
import '../../../requests/data/request_repository.dart';
import '../controllers/caregiver_controller.dart';

class CaregiverHomeScreen extends ConsumerWidget {
  const CaregiverHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    
    final pendingRequestsAsync = ref.watch(pendingRequestsStreamProvider);
    final myTasksAsync = ref.watch(myAssignedRequestsStreamProvider);
    final emergenciesAsync = ref.watch(activeEmergenciesStreamProvider);

    return PopScope(
      canPop: false,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('ElderL Caregiver'),
        actions: [
          IconButton(
            icon: const Icon(Icons.message_outlined),
            onPressed: () => context.push(AppRoutes.conversations),
            tooltip: 'Messages',
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push(AppRoutes.profile),
            tooltip: 'Profile',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(pendingRequestsStreamProvider);
            ref.invalidate(myAssignedRequestsStreamProvider);
            ref.invalidate(activeEmergenciesStreamProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: Text(
                                (user?.name?.isNotEmpty == true ? user!.name : 'C')[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back,',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                  Text(
                                    user?.name ?? 'Caregiver',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Active Emergencies Section
                _buildSectionHeader(context, 'Active Emergencies', Icons.emergency, Colors.red),
                const SizedBox(height: 12),
                emergenciesAsync.when(
                  loading: () => const Card(child: Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))),
                  error: (e, _) => Card(child: ListTile(leading: const Icon(Icons.error, color: Colors.red), title: Text('Error: $e'))),
                  data: (emergencies) => _buildEmergencySection(context, ref, emergencies),
                ),
                const SizedBox(height: 24),

                // Pending Requests Section
                _buildSectionHeader(context, 'Pending Requests', Icons.pending_actions, Colors.orange),
                const SizedBox(height: 12),
                pendingRequestsAsync.when(
                  loading: () => const Card(child: Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))),
                  error: (e, _) => Card(child: ListTile(leading: const Icon(Icons.error, color: Colors.red), title: Text('Error: $e'))),
                  data: (requests) => _buildPendingRequestsList(context, ref, requests),
                ),
                const SizedBox(height: 24),

                // My Assigned Tasks Section
                _buildSectionHeader(context, 'My Tasks', Icons.assignment, Colors.blue),
                const SizedBox(height: 12),
                myTasksAsync.when(
                  loading: () => const Card(child: Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))),
                  error: (e, _) => Card(child: ListTile(leading: const Icon(Icons.error, color: Colors.red), title: Text('Error: $e'))),
                  data: (tasks) => _buildMyTasksList(context, ref, tasks),
                ),
                const SizedBox(height: 24),

                // Quick Actions
                _buildSectionHeader(context, 'Quick Actions', Icons.flash_on, Colors.amber),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        context,
                        icon: Icons.list_alt,
                        label: 'All Requests',
                        color: Colors.green,
                        onTap: () => context.push(AppRoutes.caregiverRequests),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionCard(
                        context,
                        icon: Icons.history,
                        label: 'History',
                        color: Colors.purple,
                        onTap: () => context.push(AppRoutes.caregiverHistory),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionCard(
                        context,
                        icon: Icons.people,
                        label: 'Seniors',
                        color: Colors.teal,
                        onTap: () => context.push(AppRoutes.caregiverSeniors),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              context.go(AppRoutes.caregiverRequests);
              break;
            case 2:
              context.go(AppRoutes.caregiverSeniors);
              break;
            case 3:
              context.go(AppRoutes.profile);
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
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Seniors',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildEmergencySection(BuildContext context, WidgetRef ref, List<EmergencyAlert> emergencies) {
    if (emergencies.isEmpty) {
      return Card(
        color: Colors.green.shade50,
        child: const ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.green,
            child: Icon(Icons.check, color: Colors.white),
          ),
          title: Text('No Active Emergencies', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('All seniors are safe'),
          trailing: Icon(Icons.check_circle, color: Colors.green, size: 32),
        ),
      );
    }

    return Card(
      color: Colors.red.shade50,
      child: Column(
        children: emergencies.take(3).map((emergency) {
          // Use an explicit Row instead of ListTile + trailing so the button
          // does not consume unbounded width and squeeze the title text into a
          // near-zero-width column (which causes character-by-character
          // vertical rendering of the senior name / timestamp).
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.red,
                  child: Icon(Icons.emergency, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emergency.seniorName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${_formatTimeAgo(emergency.createdAtDateTime)} • ${emergency.status}',
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    try {
                      final authState = ref.read(authControllerProvider);
                      final repo = ref.read(emergencyRepositoryProvider);
                      await repo.respondToEmergency(
                        emergency.id!,
                        authState.user?.uid ?? '',
                        authState.user?.name ?? 'Caregiver',
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Responding to emergency...'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to respond: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: const Text('Respond', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPendingRequestsList(BuildContext context, WidgetRef ref, List<HelpRequest> requests) {
    if (requests.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'No pending requests',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: requests.take(5).map((request) {
          return Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getRequestColor(request.type).withOpacity(0.2),
                  child: Icon(_getRequestIcon(request.type), color: _getRequestColor(request.type)),
                ),
                title: Text(
                  '${request.type.toUpperCase()} Request',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('${request.seniorName} • ${_formatTimeAgo(request.createdAt)}'),
                trailing: ElevatedButton(
                  onPressed: () async {
                    try {
                      await ref.read(caregiverRequestControllerProvider.notifier).acceptRequest(request.id!);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Request accepted!'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to accept: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: const Text('Accept'),
                ),
              ),
              if (requests.indexOf(request) < requests.length - 1) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMyTasksList(BuildContext context, WidgetRef ref, List<HelpRequest> tasks) {
    // Filter to only show active tasks
    final activeTasks = tasks.where((t) =>
        t.status == AppConstants.statusAccepted ||
        t.status == AppConstants.statusInProgress).toList();
    
    if (activeTasks.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.assignment_turned_in, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Text(
                'No active tasks',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                'Accept a request to start helping',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: activeTasks.take(3).map((task) {
          return Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getRequestColor(task.type).withOpacity(0.2),
                  child: Icon(_getRequestIcon(task.type), color: _getRequestColor(task.type)),
                ),
                title: Text(task.seniorName, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${task.type} • ${task.status}'),
                trailing: task.status == AppConstants.statusAccepted
                    ? ElevatedButton(
                        onPressed: () async {
                          try {
                            await ref.read(caregiverRequestControllerProvider.notifier).markInProgress(task.id!);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        child: const Text('Start'),
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: () async {
                          try {
                            await ref.read(caregiverRequestControllerProvider.notifier).completeRequest(task.id!);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Task completed!'), backgroundColor: Colors.green),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        child: const Text('Complete', style: TextStyle(color: Colors.white)),
                      ),
              ),
              if (activeTasks.indexOf(task) < activeTasks.length - 1) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
        return Icons.help;
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

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(dateTime);
  }
}
