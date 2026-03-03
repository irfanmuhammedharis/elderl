import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../controllers/admin_controller.dart';

/// Admin Seniors Screen - View and manage all seniors in the system
class AdminSeniorsScreen extends ConsumerStatefulWidget {
  const AdminSeniorsScreen({super.key});

  @override
  ConsumerState<AdminSeniorsScreen> createState() => _AdminSeniorsScreenState();
}

class _AdminSeniorsScreenState extends ConsumerState<AdminSeniorsScreen> {
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
    final seniorsAsync = ref.watch(usersByRoleStreamProvider('senior'));
    final isWideScreen = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Seniors'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.adminHome),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(usersByRoleStreamProvider('senior')),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          _buildSearchBar(isWideScreen),
          
          // Stats Overview
          seniorsAsync.when(
            data: (seniors) => _buildStatsBar(seniors),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          
          // Seniors List
          Expanded(
            child: seniorsAsync.when(
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
                      onPressed: () => ref.invalidate(usersByRoleStreamProvider('senior')),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (seniors) {
                final filteredSeniors = _filterSeniors(seniors);
                if (filteredSeniors.isEmpty) {
                  return _buildEmptyState();
                }
                return isWideScreen
                    ? _buildWideLayout(filteredSeniors)
                    : _buildNarrowLayout(filteredSeniors);
              },
            ),
          ),
        ],
      ),
    );
  }

  List<AppUser> _filterSeniors(List<AppUser> seniors) {
    return seniors.where((senior) {
      // Apply status filter
      if (_statusFilter != null && senior.approvalStatus != _statusFilter) {
        return false;
      }
      
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return senior.name.toLowerCase().contains(query) ||
            senior.email.toLowerCase().contains(query) ||
            (senior.phone?.contains(_searchQuery) ?? false);
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
                hintText: 'Search seniors by name, email, or phone...',
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

  Widget _buildStatsBar(List<AppUser> seniors) {
    final total = seniors.length;
    final approved = seniors.where((s) => s.approvalStatus == ApprovalStatus.approved).length;
    final pending = seniors.where((s) => s.approvalStatus == ApprovalStatus.pending).length;
    final hasFamily = seniors.where((s) => s.linkedFamily?.isNotEmpty ?? false).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: Colors.purple.withOpacity(0.2))),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _buildStatChip('Total', total, Icons.elderly, Colors.purple),
          _buildStatChip('Approved', approved, Icons.check_circle, Colors.green),
          _buildStatChip('Pending', pending, Icons.pending, Colors.orange),
          _buildStatChip('With Family', hasFamily, Icons.family_restroom, Colors.blue),
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
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey[700], fontSize: 14),
        ),
        Text(
          count.toString(),
          style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.elderly, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty || _statusFilter != null
                ? 'No seniors match your criteria'
                : 'No seniors registered yet',
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

  Widget _buildWideLayout(List<AppUser> seniors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.purple.withOpacity(0.1)),
            columns: const [
              DataColumn(label: Text('Senior', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Contact', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Family', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Registered', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: seniors.map((senior) => _buildDataRow(senior)).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildDataRow(AppUser senior) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.purple.withOpacity(0.2),
                child: Text(
                  senior.name.isNotEmpty ? senior.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(senior.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(senior.email, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ),
        DataCell(Text(senior.phone ?? '-')),
        DataCell(_buildStatusBadge(senior.approvalStatus)),
        DataCell(Text('${senior.linkedFamily?.length ?? 0} members')),
        DataCell(Text(
          senior.createdAt != null
              ? DateFormat('MMM d, yyyy').format(senior.createdAt!)
              : '-',
        )),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, size: 20),
                onPressed: () => context.push('/admin/users/${senior.uid}'),
                tooltip: 'View Details',
              ),
              if (senior.approvalStatus == ApprovalStatus.pending)
                IconButton(
                  icon: const Icon(Icons.check_circle, size: 20, color: Colors.green),
                  onPressed: () => _approveUser(senior),
                  tooltip: 'Approve',
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(List<AppUser> seniors) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: seniors.length,
      itemBuilder: (context, index) => _buildSeniorCard(seniors[index]),
    );
  }

  Widget _buildSeniorCard(AppUser senior) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => context.push('/admin/users/${senior.uid}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.purple.withOpacity(0.2),
                    child: Text(
                      senior.name.isNotEmpty ? senior.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple),
                    ),
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
                                senior.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            _buildStatusBadge(senior.approvalStatus),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(senior.email, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        if (senior.phone != null)
                          Text(senior.phone!, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(Icons.family_restroom, '${senior.linkedFamily?.length ?? 0} family'),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.medical_services, '${senior.assignedCaregivers?.length ?? 0} caregivers'),
                  const Spacer(),
                  if (senior.approvalStatus == ApprovalStatus.pending)
                    ElevatedButton.icon(
                      onPressed: () => _approveUser(senior),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
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
        label = 'Approved';
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

  Future<void> _approveUser(AppUser senior) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Senior'),
        content: Text('Are you sure you want to approve ${senior.name}?'),
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
      final success = await ref
          .read(adminUserControllerProvider.notifier)
          .approveUser(senior.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? '${senior.name} has been approved'
                : 'Failed to approve ${senior.name}'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}
