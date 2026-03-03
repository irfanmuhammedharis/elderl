import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/admin_controller.dart';

/// User Approval Screen - Web-friendly admin panel for user management
class UserApprovalScreen extends ConsumerStatefulWidget {
  const UserApprovalScreen({super.key});

  @override
  ConsumerState<UserApprovalScreen> createState() => _UserApprovalScreenState();
}

class _UserApprovalScreenState extends ConsumerState<UserApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    // Watch auth state to ensure admin is logged in
    ref.watch(authControllerProvider);
    final statsAsync = ref.watch(userStatisticsProvider);
    final isWideScreen = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management & Approval'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.adminHome),
          tooltip: 'Back to Home',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(allUsersStreamProvider),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: const Icon(Icons.pending_actions),
              text: 'Pending',
              iconMargin: const EdgeInsets.only(bottom: 4),
            ),
            Tab(
              icon: const Icon(Icons.elderly),
              text: 'Seniors',
              iconMargin: const EdgeInsets.only(bottom: 4),
            ),
            Tab(
              icon: const Icon(Icons.medical_services),
              text: 'Caregivers',
              iconMargin: const EdgeInsets.only(bottom: 4),
            ),
            Tab(
              icon: const Icon(Icons.family_restroom),
              text: 'Family',
              iconMargin: const EdgeInsets.only(bottom: 4),
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
          _buildSearchBar(isWideScreen),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _UserListTab(statusFilter: ApprovalStatus.pending),
                _UserListTab(roleFilter: 'senior'),
                _UserListTab(roleFilter: 'caregiver'),
                _UserListTab(roleFilter: 'family'),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withOpacity(0.1), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          _buildStatChip(
              'Total Users', stats['total'] ?? 0, Icons.people, Colors.blue),
          _buildStatChip(
              'Pending', stats['pending'] ?? 0, Icons.pending, Colors.orange),
          _buildStatChip('Approved', stats['approved'] ?? 0, Icons.check_circle,
              Colors.green),
          _buildStatChip(
              'Rejected', stats['rejected'] ?? 0, Icons.cancel, Colors.red),
          _buildStatChip(
              'Seniors', stats['seniors'] ?? 0, Icons.elderly, Colors.purple),
          _buildStatChip('Caregivers', stats['caregivers'] ?? 0,
              Icons.medical_services, Colors.teal),
          _buildStatChip('Family', stats['family'] ?? 0, Icons.family_restroom,
              Colors.indigo),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isWideScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWideScreen ? 32 : 16,
        vertical: 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, email, or phone...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(userFilterProvider.notifier).state = ref
                              .read(userFilterProvider)
                              .copyWith(searchQuery: '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                ref.read(userFilterProvider.notifier).state =
                    ref.read(userFilterProvider).copyWith(searchQuery: value);
              },
            ),
          ),
          const SizedBox(width: 12),
          _buildFilterButton(),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    final filter = ref.watch(userFilterProvider);
    final hasFilters = filter.statusFilter != null;

    return PopupMenuButton<ApprovalStatus?>(
      icon: Badge(
        isLabelVisible: hasFilters,
        child: const Icon(Icons.filter_list),
      ),
      tooltip: 'Filter by status',
      onSelected: (status) {
        ref.read(userFilterProvider.notifier).state =
            ref.read(userFilterProvider).copyWith(
                  statusFilter: status,
                  clearStatusFilter: status == null,
                );
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: null,
          child: Text('All Statuses'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: ApprovalStatus.pending,
          child: Row(
            children: [
              Icon(Icons.pending, color: Colors.orange),
              SizedBox(width: 8),
              Text('Pending'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: ApprovalStatus.approved,
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Approved'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: ApprovalStatus.rejected,
          child: Row(
            children: [
              Icon(Icons.cancel, color: Colors.red),
              SizedBox(width: 8),
              Text('Rejected'),
            ],
          ),
        ),
      ],
    );
  }
}

/// User list tab widget
class _UserListTab extends ConsumerWidget {
  final String? roleFilter;
  final ApprovalStatus? statusFilter;

  const _UserListTab({
    this.roleFilter,
    this.statusFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(userFilterProvider).searchQuery;
    final globalStatusFilter = ref.watch(userFilterProvider).statusFilter;

    // Use appropriate stream based on filter
    AsyncValue<List<AppUser>> usersAsync;

    if (statusFilter != null) {
      usersAsync = ref.watch(pendingUsersStreamProvider);
    } else if (roleFilter != null) {
      usersAsync = ref.watch(usersByRoleStreamProvider(roleFilter!));
    } else {
      usersAsync = ref.watch(allUsersStreamProvider);
    }

    return usersAsync.when(
      data: (users) {
        // Apply filters
        var filteredUsers = users;

        // Apply global status filter if set
        if (globalStatusFilter != null && statusFilter == null) {
          filteredUsers = filteredUsers
              .where((u) => u.approvalStatus == globalStatusFilter)
              .toList();
        }

        // Apply search
        if (searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          filteredUsers = filteredUsers.where((u) {
            return u.name.toLowerCase().contains(query) ||
                u.email.toLowerCase().contains(query) ||
                (u.phone?.contains(searchQuery) ?? false);
          }).toList();
        }

        if (filteredUsers.isEmpty) {
          return _buildEmptyState(statusFilter);
        }

        return _buildUserList(context, ref, filteredUsers);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Error loading users: $error'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(allUsersStreamProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ApprovalStatus? status) {
    String message;
    IconData icon;
    Color color;

    if (status == ApprovalStatus.pending) {
      message = 'No pending approvals';
      icon = Icons.check_circle_outline;
      color = Colors.green;
    } else if (roleFilter != null) {
      message = 'No ${roleFilter}s found';
      icon = Icons.person_off;
      color = Colors.grey;
    } else {
      message = 'No users found';
      icon = Icons.search_off;
      color = Colors.grey;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: color.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(
      BuildContext context, WidgetRef ref, List<AppUser> users) {
    final isWideScreen = MediaQuery.of(context).size.width > 900;

    if (isWideScreen) {
      return _buildDataTable(context, ref, users);
    } else {
      return _buildCardList(context, ref, users);
    }
  }

  Widget _buildDataTable(
      BuildContext context, WidgetRef ref, List<AppUser> users) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        child: SizedBox(
          width: double.infinity,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
            columns: const [
              DataColumn(
                  label: Text('User',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('Role',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('Status',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('Registered',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('Actions',
                      style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows:
                users.map((user) => _buildDataRow(context, ref, user)).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildDataRow(BuildContext context, WidgetRef ref, AppUser user) {
    return DataRow(
      cells: [
        DataCell(
          InkWell(
            onTap: () => _showUserDetail(context, user),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: _getRoleColor(user.role),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      user.email,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        DataCell(_buildRoleChip(user.role)),
        DataCell(_buildStatusChip(user.approvalStatus)),
        DataCell(
          Text(
            user.createdAt != null
                ? DateFormat('MMM dd, yyyy').format(user.createdAt!)
                : 'N/A',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        DataCell(_buildActionButtons(context, ref, user)),
      ],
    );
  }

  Widget _buildCardList(
      BuildContext context, WidgetRef ref, List<AppUser> users) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: users.length,
      itemBuilder: (context, index) =>
          _buildUserCard(context, ref, users[index]),
    );
  }

  Widget _buildUserCard(BuildContext context, WidgetRef ref, AppUser user) {
    return Semantics(
      label:
          '${user.name}, ${user.roleDisplayName}, ${user.approvalStatusDisplayName}',
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _showUserDetail(context, user),
          borderRadius: BorderRadius.circular(12),
          hoverColor: AppTheme.primaryColor.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          _getRoleColor(user.role).withOpacity(0.2),
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 20,
                          color: _getRoleColor(user.role),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(user.approvalStatus),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildRoleChip(user.role),
                    const Spacer(),
                    if (user.phone != null) ...[
                      Icon(Icons.phone, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        user.phone!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      user.createdAt != null
                          ? 'Registered: ${DateFormat('MMM dd, yyyy').format(user.createdAt!)}'
                          : '',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    _buildActionButtons(context, ref, user, compact: true),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getRoleColor(role).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getRoleColor(role).withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getRoleIcon(role), size: 14, color: _getRoleColor(role)),
          const SizedBox(width: 4),
          Text(
            _getRoleDisplayName(role),
            style: TextStyle(
              fontSize: 12,
              color: _getRoleColor(role),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ApprovalStatus status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case ApprovalStatus.pending:
        color = Colors.orange;
        label = 'Pending';
        icon = Icons.pending;
        break;
      case ApprovalStatus.approved:
        color = Colors.green;
        label = 'Approved';
        icon = Icons.check_circle;
        break;
      case ApprovalStatus.rejected:
        color = Colors.red;
        label = 'Rejected';
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, AppUser user,
      {bool compact = false}) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (user.isPending) ...[
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              tooltip: 'Approve',
              onPressed: () => _handleApprove(context, ref, user),
              iconSize: 22,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              tooltip: 'Reject',
              onPressed: () => _showRejectDialog(context, ref, user),
              iconSize: 22,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.visibility, color: Colors.blue),
            tooltip: 'View Details',
            onPressed: () => _showUserDetail(context, user),
            iconSize: 22,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (user.isPending) ...[
          TextButton.icon(
            onPressed: () => _handleApprove(context, ref, user),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Approve'),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
          ),
          TextButton.icon(
            onPressed: () => _showRejectDialog(context, ref, user),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Reject'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
        if (user.isRejected)
          TextButton.icon(
            onPressed: () => _handleReset(context, ref, user),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Reset'),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
          ),
        IconButton(
          icon: const Icon(Icons.visibility),
          tooltip: 'View Details',
          onPressed: () => _showUserDetail(context, user),
        ),
      ],
    );
  }

  void _handleApprove(BuildContext context, WidgetRef ref, AppUser user) async {
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

    if (confirmed == true) {
      final success = await ref
          .read(adminUserControllerProvider.notifier)
          .approveUser(user.uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'User approved successfully'
                : 'Failed to approve user'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref, AppUser user) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reject ${user.name}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection',
                hintText: 'Enter the reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a reason')),
                );
                return;
              }
              Navigator.pop(context);
              final success = await ref
                  .read(adminUserControllerProvider.notifier)
                  .rejectUser(user.uid, reasonController.text);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        success ? 'User rejected' : 'Failed to reject user'),
                    backgroundColor: success ? Colors.orange : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _handleReset(BuildContext context, WidgetRef ref, AppUser user) async {
    final success = await ref
        .read(adminUserControllerProvider.notifier)
        .resetToPending(user.uid);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(success ? 'User reset to pending' : 'Failed to reset user'),
          backgroundColor: success ? Colors.blue : Colors.red,
        ),
      );
    }
  }

  void _showUserDetail(BuildContext context, AppUser user) {
    context.push('${AppRoutes.adminUsers}/${user.uid}');
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'senior':
        return Colors.purple;
      case 'caregiver':
        return Colors.teal;
      case 'family':
        return Colors.indigo;
      case 'admin':
        return Colors.red;
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

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'senior':
        return 'Senior';
      case 'caregiver':
        return 'Caregiver';
      case 'family':
        return 'Family';
      case 'admin':
        return 'Admin';
      default:
        return role;
    }
  }
}
