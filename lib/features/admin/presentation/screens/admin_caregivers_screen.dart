import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../controllers/admin_controller.dart';

/// Admin Caregivers Screen - View and manage all caregivers in the system
class AdminCaregiversScreen extends ConsumerStatefulWidget {
  const AdminCaregiversScreen({super.key});

  @override
  ConsumerState<AdminCaregiversScreen> createState() => _AdminCaregiversScreenState();
}

class _AdminCaregiversScreenState extends ConsumerState<AdminCaregiversScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ApprovalStatus? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final caregiversAsync = ref.watch(usersByRoleStreamProvider('caregiver'));
    final isWideScreen = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Caregivers'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.adminHome),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(usersByRoleStreamProvider('caregiver')),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          _buildSearchBar(isWideScreen),
          
          // Stats Overview
          caregiversAsync.when(
            data: (caregivers) => _buildStatsBar(caregivers),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          
          // Caregivers List
          Expanded(
            child: caregiversAsync.when(
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
                      onPressed: () => ref.invalidate(usersByRoleStreamProvider('caregiver')),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (caregivers) {
                final filteredCaregivers = _filterCaregivers(caregivers);
                if (filteredCaregivers.isEmpty) {
                  return _buildEmptyState();
                }
                return isWideScreen
                    ? _buildWideLayout(filteredCaregivers)
                    : _buildNarrowLayout(filteredCaregivers);
              },
            ),
          ),
        ],
      ),
    );
  }

  List<AppUser> _filterCaregivers(List<AppUser> caregivers) {
    return caregivers.where((caregiver) {
      // Apply status filter
      if (_statusFilter != null && caregiver.approvalStatus != _statusFilter) {
        return false;
      }
      
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return caregiver.name.toLowerCase().contains(query) ||
            caregiver.email.toLowerCase().contains(query) ||
            (caregiver.phone?.contains(_searchQuery) ?? false);
      }
      
      return true;
    }).toList();
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
                hintText: 'Search caregivers by name, email, or phone...',
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          const SizedBox(width: 12),
          PopupMenuButton<ApprovalStatus?>(
            icon: Badge(
              isLabelVisible: _statusFilter != null,
              child: const Icon(Icons.filter_list),
            ),
            tooltip: 'Filter by status',
            onSelected: (status) => setState(() => _statusFilter = status),
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('All Statuses')),
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
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(List<AppUser> caregivers) {
    final total = caregivers.length;
    final approved = caregivers.where((c) => c.approvalStatus == ApprovalStatus.approved).length;
    final pending = caregivers.where((c) => c.approvalStatus == ApprovalStatus.pending).length;
    final active = caregivers.where((c) => c.assignedSeniors?.isNotEmpty ?? false).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: Colors.teal.withOpacity(0.2))),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _buildStatChip('Total', total, Icons.medical_services, Colors.teal),
          _buildStatChip('Approved', approved, Icons.check_circle, Colors.green),
          _buildStatChip('Pending', pending, Icons.pending, Colors.orange),
          _buildStatChip('Active', active, Icons.work, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Text('$label: ', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
        Text(count.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medical_services, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty || _statusFilter != null
                ? 'No caregivers match your criteria'
                : 'No caregivers registered yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          if (_searchQuery.isNotEmpty || _statusFilter != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _statusFilter = null;
                  });
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Filters'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(List<AppUser> caregivers) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.teal.withOpacity(0.1)),
            columns: const [
              DataColumn(label: Text('Caregiver', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Contact', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Assigned Seniors', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Registered', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: caregivers.map((caregiver) => _buildDataRow(caregiver)).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildDataRow(AppUser caregiver) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.teal.withOpacity(0.2),
                child: Text(
                  caregiver.name.isNotEmpty ? caregiver.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(caregiver.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(caregiver.email, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ),
        DataCell(Text(caregiver.phone ?? '-')),
        DataCell(_buildStatusBadge(caregiver.approvalStatus)),
        DataCell(Text('${caregiver.assignedSeniors?.length ?? 0} seniors')),
        DataCell(Text(
          caregiver.createdAt != null
              ? DateFormat('MMM d, yyyy').format(caregiver.createdAt!)
              : '-',
        )),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, size: 20),
                onPressed: () => context.push('/admin/users/${caregiver.uid}'),
                tooltip: 'View Details',
              ),
              if (caregiver.approvalStatus == ApprovalStatus.pending) ...[
                IconButton(
                  icon: const Icon(Icons.check_circle, size: 20, color: Colors.green),
                  onPressed: () => _approveUser(caregiver),
                  tooltip: 'Approve',
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, size: 20, color: Colors.red),
                  onPressed: () => _rejectUser(caregiver),
                  tooltip: 'Reject',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(List<AppUser> caregivers) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: caregivers.length,
      itemBuilder: (context, index) => _buildCaregiverCard(caregivers[index]),
    );
  }

  Widget _buildCaregiverCard(AppUser caregiver) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => context.push('/admin/users/${caregiver.uid}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.teal.withOpacity(0.2),
                        child: Text(
                          caregiver.name.isNotEmpty ? caregiver.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                      ),
                      if (caregiver.approvalStatus == ApprovalStatus.approved)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.verified, size: 12, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                caregiver.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            _buildStatusBadge(caregiver.approvalStatus),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(caregiver.email, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        if (caregiver.phone != null)
                          Text(caregiver.phone!, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(Icons.elderly, '${caregiver.assignedSeniors?.length ?? 0} seniors'),
                  const SizedBox(width: 8),
                  if (caregiver.lastActiveAt != null)
                    _buildInfoChip(
                      Icons.access_time,
                      'Active ${_formatTimeAgo(caregiver.lastActiveAt!)}',
                    ),
                  const Spacer(),
                  if (caregiver.approvalStatus == ApprovalStatus.pending) ...[
                    ElevatedButton.icon(
                      onPressed: () => _approveUser(caregiver),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _rejectUser(caregiver),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ApprovalStatus status) {
    Color color;
    String label;
    
    switch (status) {
      case ApprovalStatus.approved:
        color = Colors.green;
        label = 'Verified';
        break;
      case ApprovalStatus.pending:
        color = Colors.orange;
        label = 'Pending';
        break;
      case ApprovalStatus.rejected:
        color = Colors.red;
        label = 'Rejected';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(time);
  }

  Future<void> _approveUser(AppUser caregiver) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Caregiver'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to approve ${caregiver.name}?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Approving will allow this caregiver to accept and manage help requests.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${caregiver.name} has been approved'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _rejectUser(AppUser caregiver) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Caregiver'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rejecting ${caregiver.name}. Please provide a reason:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection',
                border: OutlineInputBorder(),
                hintText: 'e.g., Invalid credentials, incomplete profile...',
              ),
              maxLines: 3,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${caregiver.name} has been rejected'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
