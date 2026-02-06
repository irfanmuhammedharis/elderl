import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/admin_controller.dart';

/// Role-specific colors for UI
class _RoleColors {
  static const Color senior = Color(0xFF5C6BC0);
  static const Color caregiver = Color(0xFF26A69A);
  static const Color family = Color(0xFF7E57C2);
  static const Color admin = Color(0xFF1565C0);
}

/// Web Admin Dashboard - Simplified admin panel for web platform
/// Only includes user approval functionality
class WebAdminDashboard extends ConsumerStatefulWidget {
  const WebAdminDashboard({super.key});

  @override
  ConsumerState<WebAdminDashboard> createState() => _WebAdminDashboardState();
}

class _WebAdminDashboardState extends ConsumerState<WebAdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _logout() async {
    await ref.read(authControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final statsAsync = ref.watch(userStatisticsProvider);
    final isWideScreen = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings, size: 28),
            const SizedBox(width: 12),
            const Text('ElderL Admin Portal'),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (authState.user != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  authState.user!.email,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(allUsersStreamProvider),
              tooltip: 'Refresh',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
          ],
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.pending_actions),
              text: 'Pending Approval',
              iconMargin: EdgeInsets.only(bottom: 4),
            ),
            Tab(
              icon: Icon(Icons.elderly),
              text: 'Seniors',
              iconMargin: EdgeInsets.only(bottom: 4),
            ),
            Tab(
              icon: Icon(Icons.medical_services),
              text: 'Caregivers',
              iconMargin: EdgeInsets.only(bottom: 4),
            ),
            Tab(
              icon: Icon(Icons.family_restroom),
              text: 'Family Members',
              iconMargin: EdgeInsets.only(bottom: 4),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Statistics Card
          statsAsync.when(
            data: (stats) => _buildStatisticsCard(stats, isWideScreen),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users by name or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserList(ApprovalStatus.pending),
                _buildUserList(null, role: 'senior'),
                _buildUserList(null, role: 'caregiver'),
                _buildUserList(null, role: 'family'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(Map<String, int> stats, bool isWideScreen) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryColor.withOpacity(0.05),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        spacing: 24,
        runSpacing: 16,
        children: [
          _buildStatItem(
            'Pending',
            stats['pending'] ?? 0,
            Icons.pending_actions,
            Colors.orange,
          ),
          _buildStatItem(
            'Seniors',
            stats['seniors'] ?? 0,
            Icons.elderly,
            _RoleColors.senior,
          ),
          _buildStatItem(
            'Caregivers',
            stats['caregivers'] ?? 0,
            Icons.medical_services,
            _RoleColors.caregiver,
          ),
          _buildStatItem(
            'Family',
            stats['family'] ?? 0,
            Icons.family_restroom,
            _RoleColors.family,
          ),
          _buildStatItem(
            'Total Users',
            stats['total'] ?? 0,
            Icons.people,
            AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(ApprovalStatus? status, {String? role}) {
    final usersAsync = ref.watch(allUsersStreamProvider);

    return usersAsync.when(
      data: (users) {
        // Filter users based on status and/or role
        var filteredUsers = users.where((user) {
          if (status != null && user.approvalStatus != status) return false;
          if (role != null && user.role != role) return false;
          return true;
        }).toList();

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          filteredUsers = filteredUsers.where((user) {
            return user.name.toLowerCase().contains(query) ||
                user.email.toLowerCase().contains(query);
          }).toList();
        }

        if (filteredUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == ApprovalStatus.pending
                      ? Icons.check_circle_outline
                      : Icons.people_outline,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  status == ApprovalStatus.pending
                      ? 'No pending approvals'
                      : 'No users found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final user = filteredUsers[index];
            return _buildUserCard(user);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text('Error: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(allUsersStreamProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(AppUser user) {
    final isPending = user.approvalStatus == ApprovalStatus.pending;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isPending ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPending
            ? BorderSide(color: Colors.orange.shade300, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
                  child: Text(
                    user.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _getRoleColor(user.role),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildRoleBadge(user.role),
                          const SizedBox(width: 8),
                          _buildStatusBadge(user.approvalStatus),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                if (isPending) ...[
                  Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _approveUser(user),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _rejectUser(user),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),

            // Additional Info
            if (user.phone != null || user.createdAt != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Wrap(
                spacing: 24,
                runSpacing: 8,
                children: [
                  if (user.phone != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(user.phone!),
                      ],
                    ),
                  if (user.createdAt != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'Joined: ${DateFormat('MMM d, yyyy').format(user.createdAt!)}',
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getRoleColor(role).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getRoleColor(role).withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getRoleIcon(role), size: 14, color: _getRoleColor(role)),
          const SizedBox(width: 4),
          Text(
            role.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _getRoleColor(role),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ApprovalStatus status) {
    Color color;
    IconData icon;
    switch (status) {
      case ApprovalStatus.pending:
        color = Colors.orange;
        icon = Icons.pending;
      case ApprovalStatus.approved:
        color = Colors.green;
        icon = Icons.check_circle;
      case ApprovalStatus.rejected:
        color = Colors.red;
        icon = Icons.cancel;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.name.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'senior':
        return _RoleColors.senior;
      case 'caregiver':
        return _RoleColors.caregiver;
      case 'family':
        return _RoleColors.family;
      case 'admin':
        return _RoleColors.admin;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'senior':
        return Icons.elderly;
      case 'caregiver':
        return Icons.medical_services;
      case 'family':
        return Icons.family_restroom;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  Future<void> _approveUser(AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve User'),
        content: Text('Are you sure you want to approve ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(adminUserControllerProvider.notifier).approveUser(user.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user.name} has been approved'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _rejectUser(AppUser user) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to reject ${user.name}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(adminUserControllerProvider.notifier).rejectUser(
              user.uid,
              reasonController.text.isNotEmpty
                  ? reasonController.text
                  : 'Rejected by admin',
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user.name} has been rejected'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
