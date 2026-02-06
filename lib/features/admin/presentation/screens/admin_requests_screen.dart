import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../requests/data/request_repository.dart';

/// Provider for all requests stream
final allRequestsStreamProvider = StreamProvider.autoDispose<List<HelpRequest>>((ref) {
  final requestRepo = ref.watch(requestRepositoryProvider);
  return requestRepo.streamAllRequests();
});

/// Admin Requests Screen - View and manage all help requests in the system
class AdminRequestsScreen extends ConsumerStatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  ConsumerState<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends ConsumerState<AdminRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _typeFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Requests'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.adminHome),
        ),
        actions: [
          PopupMenuButton<String?>(
            icon: Badge(
              isLabelVisible: _typeFilter != null,
              child: const Icon(Icons.filter_list),
            ),
            tooltip: 'Filter by type',
            onSelected: (type) => setState(() => _typeFilter = type),
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('All Types')),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: AppConstants.requestMedical,
                child: Row(
                  children: [
                    Icon(Icons.local_hospital, color: Colors.red[400]),
                    const SizedBox(width: 8),
                    const Text('Medical'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: AppConstants.requestFood,
                child: Row(
                  children: [
                    Icon(Icons.restaurant, color: Colors.orange[400]),
                    const SizedBox(width: 8),
                    const Text('Food'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: AppConstants.requestTransport,
                child: Row(
                  children: [
                    Icon(Icons.directions_car, color: Colors.blue[400]),
                    const SizedBox(width: 8),
                    const Text('Transport'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: AppConstants.requestCompanion,
                child: Row(
                  children: [
                    Icon(Icons.people, color: Colors.purple[400]),
                    const SizedBox(width: 8),
                    const Text('Companion'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(allRequestsStreamProvider),
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.all_inbox), text: 'All'),
            Tab(icon: Icon(Icons.pending), text: 'Pending'),
            Tab(icon: Icon(Icons.check_circle), text: 'Accepted'),
            Tab(icon: Icon(Icons.loop), text: 'In Progress'),
            Tab(icon: Icon(Icons.done_all), text: 'Completed'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(isWideScreen),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _RequestsTab(statusFilter: null, searchQuery: _searchQuery, typeFilter: _typeFilter),
                _RequestsTab(statusFilter: AppConstants.statusPending, searchQuery: _searchQuery, typeFilter: _typeFilter),
                _RequestsTab(statusFilter: AppConstants.statusAccepted, searchQuery: _searchQuery, typeFilter: _typeFilter),
                _RequestsTab(statusFilter: AppConstants.statusInProgress, searchQuery: _searchQuery, typeFilter: _typeFilter),
                _RequestsTab(statusFilter: AppConstants.statusCompleted, searchQuery: _searchQuery, typeFilter: _typeFilter),
              ],
            ),
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
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by senior name or description...',
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
    );
  }
}

/// Requests Tab widget for filtered lists
class _RequestsTab extends ConsumerWidget {
  final String? statusFilter;
  final String searchQuery;
  final String? typeFilter;

  const _RequestsTab({
    this.statusFilter,
    required this.searchQuery,
    this.typeFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(allRequestsStreamProvider);
    final isWideScreen = MediaQuery.of(context).size.width > 900;

    return requestsAsync.when(
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
              onPressed: () => ref.invalidate(allRequestsStreamProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (requests) {
        // Apply filters
        final filteredRequests = requests.where((r) {
          if (statusFilter != null && r.status != statusFilter) return false;
          if (typeFilter != null && r.type != typeFilter) return false;
          if (searchQuery.isNotEmpty) {
            final query = searchQuery.toLowerCase();
            return r.seniorName.toLowerCase().contains(query) ||
                r.description.toLowerCase().contains(query);
          }
          return true;
        }).toList();

        // Sort by created date
        filteredRequests.sort((a, b) => 
            (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));

        if (filteredRequests.isEmpty) {
          return _buildEmptyState(context);
        }

        return Column(
          children: [
            // Stats bar
            _buildStatsBar(context, filteredRequests),
            // Requests list
            Expanded(
              child: isWideScreen
                  ? _buildWideLayout(context, filteredRequests)
                  : _buildNarrowLayout(context, filteredRequests),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsBar(BuildContext context, List<HelpRequest> requests) {
    final medical = requests.where((r) => r.type == AppConstants.requestMedical).length;
    final food = requests.where((r) => r.type == AppConstants.requestFood).length;
    final transport = requests.where((r) => r.type == AppConstants.requestTransport).length;
    final companion = requests.where((r) => r.type == AppConstants.requestCompanion).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        border: Border(bottom: BorderSide(color: Colors.blue.withOpacity(0.2))),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _buildStatChip('Total', requests.length.toString(), Icons.assignment, Colors.blue),
          _buildStatChip('Medical', medical.toString(), Icons.local_hospital, Colors.red),
          _buildStatChip('Food', food.toString(), Icons.restaurant, Colors.orange),
          _buildStatChip('Transport', transport.toString(), Icons.directions_car, Colors.blue),
          _buildStatChip('Companion', companion.toString(), Icons.people, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text('$label: ', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'No requests found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty || typeFilter != null
                ? 'Try adjusting your filters'
                : 'Requests will appear here when seniors submit them',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, List<HelpRequest> requests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.blue.withOpacity(0.1)),
            columns: const [
              DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Senior', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Assigned To', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Created', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: requests.map((request) => _buildDataRow(context, request)).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildDataRow(BuildContext context, HelpRequest request) {
    return DataRow(
      cells: [
        DataCell(_buildTypeChip(request.type)),
        DataCell(Text(request.seniorName)),
        DataCell(
          SizedBox(
            width: 200,
            child: Text(
              request.description,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ),
        DataCell(_buildStatusBadge(request.status)),
        DataCell(Text(request.assignedToName ?? '-')),
        DataCell(Text(
          request.createdAt != null
              ? DateFormat('MMM d, h:mm a').format(request.createdAt!)
              : '-',
        )),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context, List<HelpRequest> requests) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: requests.length,
      itemBuilder: (context, index) => _buildRequestCard(context, requests[index]),
    );
  }

  Widget _buildRequestCard(BuildContext context, HelpRequest request) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildTypeIcon(request.type),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${request.type.toUpperCase()} Request',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'From: ${request.seniorName}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(request.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(request.description, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 12),
            Row(
              children: [
                if (request.assignedToName != null) ...[
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    request.assignedToName!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(width: 16),
                ],
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  request.createdAt != null
                      ? DateFormat('MMM d, h:mm a').format(request.createdAt!)
                      : 'Unknown',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
            if (request.address != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      request.address!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIcon(String type) {
    IconData icon;
    Color color;

    switch (type.toLowerCase()) {
      case 'medical':
        icon = Icons.local_hospital;
        color = Colors.red;
        break;
      case 'food':
        icon = Icons.restaurant;
        color = Colors.orange;
        break;
      case 'transport':
        icon = Icons.directions_car;
        color = Colors.blue;
        break;
      case 'companion':
        icon = Icons.people;
        color = Colors.purple;
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildTypeChip(String type) {
    Color color;
    IconData icon;

    switch (type.toLowerCase()) {
      case 'medical':
        color = Colors.red;
        icon = Icons.local_hospital;
        break;
      case 'food':
        color = Colors.orange;
        icon = Icons.restaurant;
        break;
      case 'transport':
        color = Colors.blue;
        icon = Icons.directions_car;
        break;
      case 'companion':
        color = Colors.purple;
        icon = Icons.people;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            type.toUpperCase(),
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'accepted':
        color = Colors.blue;
        label = 'Accepted';
        break;
      case 'in_progress':
        color = Colors.purple;
        label = 'In Progress';
        break;
      case 'completed':
        color = Colors.green;
        label = 'Completed';
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        label = status;
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
}
