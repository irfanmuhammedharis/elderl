import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/admin_controller.dart';

/// Admin Home Screen - Dashboard with navigation to all admin features
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final statsAsync = ref.watch(userStatisticsProvider);
    final isWide = MediaQuery.of(context).size.width > 800;

    return PopScope(
      canPop: false,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('ElderL Admin Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(userStatisticsProvider),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor:
                              AppTheme.primaryColor.withOpacity(0.1),
                          child: Icon(
                            Icons.admin_panel_settings,
                            size: 45,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Welcome, ${user?.name ?? 'Admin'}!',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Manage users, assignments, and system settings',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Statistics Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.analytics, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'System Overview',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        statsAsync.when(
                          data: (stats) => _buildStats(context, stats, isWide),
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (e, _) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Colors.red, size: 48),
                                  const SizedBox(height: 8),
                                  Text('Error loading stats: $e'),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () =>
                                        ref.invalidate(userStatisticsProvider),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Actions Grid
                Text(
                  'Quick Actions',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: isWide ? 3 : 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: isWide ? 1.6 : 1.3,
                  children: [
                    _buildActionCard(
                      context,
                      icon: Icons.how_to_reg,
                      title: 'User Approvals',
                      subtitle: 'Approve or reject users',
                      color: Colors.orange,
                      onTap: () => context.push(AppRoutes.adminUsers),
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.link,
                      title: 'Link Management',
                      subtitle: 'Assign caregivers & family',
                      color: Colors.teal,
                      onTap: () => context.push(AppRoutes.adminLinkManagement),
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.elderly,
                      title: 'Seniors',
                      subtitle: 'Manage senior users',
                      color: Colors.purple,
                      onTap: () => context.push(AppRoutes.adminSeniors),
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.medical_services,
                      title: 'Caregivers',
                      subtitle: 'Manage caregivers',
                      color: Colors.teal.shade700,
                      onTap: () => context.push(AppRoutes.adminCaregivers),
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.list_alt,
                      title: 'Requests',
                      subtitle: 'View help requests',
                      color: Colors.blue,
                      onTap: () => context.push(AppRoutes.adminRequests),
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.emergency,
                      title: 'Emergencies',
                      subtitle: 'Monitor emergencies',
                      color: Colors.red,
                      onTap: () => context.push(AppRoutes.adminEmergencies),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildStats(BuildContext context, Map<String, int> stats, bool isWide) {
    final pending = stats['pending'] ?? 0;
    final approved = stats['approved'] ?? 0;
    final seniors = stats['seniors'] ?? 0;
    final caregivers = stats['caregivers'] ?? 0;
    final family = stats['family'] ?? 0;
    final total = stats['total'] ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatTile(context, 'Pending', pending.toString(), Colors.orange, Icons.pending_actions)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatTile(context, 'Approved', approved.toString(), Colors.green, Icons.check_circle)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatTile(context, 'Total', total.toString(), AppTheme.primaryColor, Icons.people)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatTile(context, 'Seniors', seniors.toString(), Colors.purple, Icons.elderly)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatTile(context, 'Caregivers', caregivers.toString(), Colors.teal, Icons.medical_services)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatTile(context, 'Family', family.toString(), Colors.indigo, Icons.family_restroom)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatTile(BuildContext context, String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
