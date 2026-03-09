import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/routing/app_router.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../checkin/data/checkin_repository.dart';
import '../../../requests/data/request_repository.dart';
import '../controllers/family_controller.dart';

class FamilyHomeScreen extends ConsumerWidget {
  const FamilyHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final linkedSeniorAsync = ref.watch(linkedSeniorStreamProvider);

    return PopScope(
      canPop: false,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('ElderL Family'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.profile),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: linkedSeniorAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
          data: (linkedSenior) {
            if (linkedSenior == null) {
              return _buildNoLinkedSenior(context, ref);
            }
            return _buildLinkedSeniorView(context, ref, linkedSenior, user);
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              context.go(AppRoutes.familyActivity);
              break;
            case 2:
              context.go(AppRoutes.familyCheckins);
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
      ),
    );
  }

  Widget _buildNoLinkedSenior(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text('No Senior Linked', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(
              'Link to a senior to monitor their well-being and receive updates.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showLinkSeniorDialog(context, ref),
              icon: const Icon(Icons.add_link),
              label: const Text('Link to Senior'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkedSeniorView(BuildContext context, WidgetRef ref, AppUser linkedSenior, AppUser? user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Hello, ${user?.name ?? 'Family Member'}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('Monitor your loved ones', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
          const SizedBox(height: 24),
          _buildSeniorStatusCard(context, ref, linkedSenior),
          const SizedBox(height: 20),
          _buildCheckInStatus(context, ref, linkedSenior.uid),
          const SizedBox(height: 20),
          _buildActiveRequests(context, ref, linkedSenior.uid),
          const SizedBox(height: 24),
          Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildQuickActions(context, linkedSenior),
          const SizedBox(height: 24),
          _buildEmergencyContactCard(context),
        ],
      ),
    );
  }

  Widget _buildSeniorStatusCard(BuildContext context, WidgetRef ref, AppUser linkedSenior) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.blue,
                  child: Text((linkedSenior.name.isNotEmpty ? linkedSenior.name : 'S')[0].toUpperCase(), style: const TextStyle(fontSize: 28, color: Colors.white)),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    child: const Icon(Icons.check, size: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(linkedSenior.name.isNotEmpty ? linkedSenior.name : 'Your Senior', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(linkedSenior.email, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                  if (linkedSenior.phone != null) Text(linkedSenior.phone!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                ],
              ),
            ),
            IconButton(onPressed: () {}, icon: const Icon(Icons.arrow_forward_ios)),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInStatus(BuildContext context, WidgetRef ref, String seniorId) {
    final checkInsAsync = ref.watch(seniorCheckInsStreamProvider(seniorId));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [const Icon(Icons.fact_check, color: Colors.green), const SizedBox(width: 8), Text('Recent Check-ins', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))]),
            const SizedBox(height: 12),
            checkInsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('Error: $e'),
              data: (checkIns) {
                if (checkIns.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('No check-ins yet'));
                return Column(children: checkIns.take(3).map((c) => _buildCheckInTile(context, c)).toList());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInTile(BuildContext context, CheckIn checkIn) {
    final timeAgo = _formatTimeAgo(checkIn.checkinTime);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: checkIn.status == 'ok' ? Colors.green.shade100 : Colors.orange.shade100,
        child: Icon(checkIn.status == 'ok' ? Icons.check : Icons.help_outline, color: checkIn.status == 'ok' ? Colors.green : Colors.orange),
      ),
      title: Text(checkIn.status == 'ok' ? "I'm OK" : checkIn.status, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: checkIn.message != null ? Text(checkIn.message!) : null,
      trailing: Text(timeAgo, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
    );
  }

  Widget _buildActiveRequests(BuildContext context, WidgetRef ref, String seniorId) {
    final requestsAsync = ref.watch(seniorRequestsStreamProvider(seniorId));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [const Icon(Icons.assignment, color: Colors.blue), const SizedBox(width: 8), Text('Recent Requests', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))]),
            const SizedBox(height: 12),
            requestsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('Error: $e'),
              data: (requests) {
                if (requests.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('No requests yet'));
                return Column(children: requests.take(3).map((r) => _buildRequestTile(context, r)).toList());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestTile(BuildContext context, HelpRequest request) {
    final statusColor = _getStatusColor(request.status);
    return ListTile(
      leading: CircleAvatar(backgroundColor: _getTypeColor(request.type).withOpacity(0.2), child: Icon(_getTypeIcon(request.type), color: _getTypeColor(request.type))),
      title: Text(request.type.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(request.description),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
        child: Text(request.status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AppUser linkedSenior) {
    return Row(
      children: [
        Expanded(child: _buildActionCard(context, icon: Icons.call, label: 'Call', color: Colors.green, onTap: () => _callSenior(linkedSenior.phone))),
        const SizedBox(width: 12),
        Expanded(child: _buildActionCard(context, icon: Icons.message, label: 'Message', color: Colors.blue, onTap: () => _messageSenior(linkedSenior.phone))),
        const SizedBox(width: 12),
        Expanded(child: _buildActionCard(context, icon: Icons.location_on, label: 'Location', color: Colors.purple, onTap: () {})),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [Icon(icon, color: color, size: 32), const SizedBox(height: 8), Text(label, style: const TextStyle(fontWeight: FontWeight.w500))])),
      ),
    );
  }

  Widget _buildEmergencyContactCard(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(backgroundColor: Colors.red, radius: 24, child: Icon(Icons.emergency, color: Colors.white)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Emergency Alerts Enabled', style: TextStyle(fontWeight: FontWeight.bold)), Text('You will be notified if an emergency is triggered', style: Theme.of(context).textTheme.bodySmall)])),
            Switch(value: true, onChanged: (v) {}, activeThumbColor: Colors.red),
          ],
        ),
      ),
    );
  }

  void _showLinkSeniorDialog(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Link to Senior'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the email of the senior:'),
            const SizedBox(height: 16),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: "Senior's Email", border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) return;
              try {
                final success = await ref
                    .read(familyLinkControllerProvider.notifier)
                    .linkToSenior(email);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (success) {
                  // Refresh the in-memory auth user so LinkedSeniorId is
                  // available immediately without requiring a sign-out/in.
                  await ref
                      .read(authControllerProvider.notifier)
                      .refreshUser();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Linked successfully!'),
                      backgroundColor: Colors.green,
                    ));
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Linking failed. Please try again.'),
                      backgroundColor: Colors.red,
                    ));
                  }
                }
              } catch (e) {
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                final msg = e.toString().replaceFirst('Exception: ', '');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(msg.contains('permission-denied')
                        ? 'Your account may not be approved yet. Please wait for admin approval.'
                        : msg),
                    backgroundColor: Colors.red,
                  ));
                }
              }
            },
            child: const Text('Link'),
          ),
        ],
      ),
    );
  }

  Future<void> _callSenior(String? phone) async {
    if (phone != null) {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    }
  }

  Future<void> _messageSenior(String? phone) async {
    if (phone != null) {
      final uri = Uri.parse('sms:$phone');
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    }
  }

  String _formatTimeAgo(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}/${time.year}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'accepted': return Colors.blue;
      case 'in_progress': return Colors.purple;
      case 'completed': return Colors.green;
      default: return Colors.grey;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'medical': return Colors.red;
      case 'food': return Colors.orange;
      default: return Colors.blue;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'medical': return Icons.local_hospital;
      case 'food': return Icons.restaurant;
      default: return Icons.help_outline;
    }
  }
}
