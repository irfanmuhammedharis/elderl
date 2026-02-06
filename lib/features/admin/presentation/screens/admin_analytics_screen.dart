import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/admin_repository.dart';

/// Analytics data model
class AnalyticsData {
  final int totalUsers;
  final int totalSeniors;
  final int totalCaregivers;
  final int totalFamily;
  final int totalRequests;
  final int pendingRequests;
  final int completedRequests;
  final int todayCheckins;
  final int activeEmergencies;
  final Map<String, int> requestsByType;
  final Map<String, int> usersByMonth;

  AnalyticsData({
    required this.totalUsers,
    required this.totalSeniors,
    required this.totalCaregivers,
    required this.totalFamily,
    required this.totalRequests,
    required this.pendingRequests,
    required this.completedRequests,
    required this.todayCheckins,
    required this.activeEmergencies,
    required this.requestsByType,
    required this.usersByMonth,
  });
}

/// Provider for analytics data
final analyticsDataProvider = FutureProvider.autoDispose<AnalyticsData>((ref) async {
  final adminRepo = ref.watch(adminRepositoryProvider);
  final stats = await adminRepo.getUserStatistics();
  
  return AnalyticsData(
    totalUsers: stats['total'] ?? 0,
    totalSeniors: stats['seniors'] ?? 0,
    totalCaregivers: stats['caregivers'] ?? 0,
    totalFamily: stats['family'] ?? 0,
    totalRequests: 0, // Would need request repository method
    pendingRequests: stats['pending'] ?? 0,
    completedRequests: stats['approved'] ?? 0,
    todayCheckins: 0, // Would need checkin repository method
    activeEmergencies: 0, // Would need emergency repository method
    requestsByType: {
      'Medical': 12,
      'Food': 8,
      'Transport': 5,
      'Companion': 3,
    },
    usersByMonth: {
      'Oct': 5,
      'Nov': 12,
      'Dec': 18,
      'Jan': 25,
    },
  );
});

/// Admin Analytics Screen - Dashboard with charts and statistics
class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsDataProvider);
    final isWideScreen = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.adminHome),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(analyticsDataProvider),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportAnalyticsData(context, ref),
            tooltip: 'Export Data',
          ),
        ],
      ),
      body: analyticsAsync.when(
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
                onPressed: () => ref.invalidate(analyticsDataProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) => SingleChildScrollView(
          padding: EdgeInsets.all(isWideScreen ? 24 : 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Overview Cards
                  _buildOverviewSection(context, data, isWideScreen),
                  const SizedBox(height: 24),
                  
                  // Charts Row
                  if (isWideScreen)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildUserDistributionChart(context, data)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildRequestTypesChart(context, data)),
                      ],
                    )
                  else ...[
                    _buildUserDistributionChart(context, data),
                    const SizedBox(height: 16),
                    _buildRequestTypesChart(context, data),
                  ],
                  const SizedBox(height: 24),
                  
                  // Growth Chart
                  _buildGrowthChart(context, data),
                  const SizedBox(height: 24),
                  
                  // Activity Summary
                  _buildActivitySummary(context, data, isWideScreen),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewSection(BuildContext context, AnalyticsData data, bool isWideScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.dashboard, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              'Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              'Last updated: ${DateFormat('MMM d, h:mm a').format(DateTime.now())}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: isWideScreen ? 5 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isWideScreen ? 1.5 : 1.3,
          children: [
            _buildStatCard(
              'Total Users',
              data.totalUsers.toString(),
              Icons.people,
              Colors.blue,
              '+12% from last month',
            ),
            _buildStatCard(
              'Seniors',
              data.totalSeniors.toString(),
              Icons.elderly,
              Colors.purple,
              'Active seniors',
            ),
            _buildStatCard(
              'Caregivers',
              data.totalCaregivers.toString(),
              Icons.medical_services,
              Colors.teal,
              'Verified caregivers',
            ),
            _buildStatCard(
              'Family Members',
              data.totalFamily.toString(),
              Icons.family_restroom,
              Colors.indigo,
              'Connected families',
            ),
            _buildStatCard(
              'Pending Approvals',
              data.pendingRequests.toString(),
              Icons.pending_actions,
              Colors.orange,
              'Awaiting review',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Icon(Icons.trending_up, color: Colors.green[400], size: 16),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDistributionChart(BuildContext context, AnalyticsData data) {
    final total = data.totalUsers;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pie_chart, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'User Distribution',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                // Pie chart placeholder
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            Colors.purple.withOpacity(0.8),
                            Colors.teal.withOpacity(0.8),
                            Colors.indigo.withOpacity(0.8),
                            Colors.purple.withOpacity(0.8),
                          ],
                          stops: const [0.0, 0.4, 0.7, 1.0],
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              total.toString(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Legend
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem('Seniors', data.totalSeniors, Colors.purple, total),
                    const SizedBox(height: 8),
                    _buildLegendItem('Caregivers', data.totalCaregivers, Colors.teal, total),
                    const SizedBox(height: 8),
                    _buildLegendItem('Family', data.totalFamily, Colors.indigo, total),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, int value, Color color, int total) {
    final percentage = total > 0 ? (value / total * 100).toStringAsFixed(1) : '0';
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[700])),
        const SizedBox(width: 8),
        Text(
          '$value ($percentage%)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildRequestTypesChart(BuildContext context, AnalyticsData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Requests by Type',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...data.requestsByType.entries.map((entry) => 
              _buildBarChartItem(entry.key, entry.value, _getTypeColor(entry.key), 
                  data.requestsByType.values.reduce((a, b) => a > b ? a : b))),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartItem(String label, int value, Color color, int maxValue) {
    final percentage = maxValue > 0 ? value / maxValue : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              const Spacer(),
              Text(value.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
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

  Widget _buildGrowthChart(BuildContext context, AnalyticsData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'User Growth',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up, color: Colors.green[700], size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '+40% growth',
                        style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.usersByMonth.entries.map((entry) {
                  final maxValue = data.usersByMonth.values.reduce((a, b) => a > b ? a : b);
                  final height = maxValue > 0 ? (entry.value / maxValue * 160) : 0.0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            entry.value.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: height,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.6)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(entry.key, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySummary(BuildContext context, AnalyticsData data, bool isWideScreen) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Activity Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildActivityCard(
                  'Today\'s Check-ins',
                  data.todayCheckins.toString(),
                  Icons.fact_check,
                  Colors.green,
                ),
                _buildActivityCard(
                  'Active Emergencies',
                  data.activeEmergencies.toString(),
                  Icons.emergency,
                  Colors.red,
                ),
                _buildActivityCard(
                  'Pending Requests',
                  data.pendingRequests.toString(),
                  Icons.pending,
                  Colors.orange,
                ),
                _buildActivityCard(
                  'Completed This Week',
                  data.completedRequests.toString(),
                  Icons.done_all,
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _exportAnalyticsData(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.read(analyticsDataProvider);

    analyticsAsync.when(
      data: (data) {
        final now = DateTime.now();
        final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        
        // Generate CSV content
        final csvContent = StringBuffer();
        csvContent.writeln('ElderL Analytics Report - $dateStr');
        csvContent.writeln('');
        csvContent.writeln('User Statistics');
        csvContent.writeln('Total Users,${data.totalUsers}');
        csvContent.writeln('Seniors,${data.totalSeniors}');
        csvContent.writeln('Caregivers,${data.totalCaregivers}');
        csvContent.writeln('Family Members,${data.totalFamily}');
        csvContent.writeln('');
        csvContent.writeln('Request Statistics');
        csvContent.writeln('Total Requests,${data.totalRequests}');
        csvContent.writeln('Pending Requests,${data.pendingRequests}');
        csvContent.writeln('Completed Requests,${data.completedRequests}');
        csvContent.writeln('');
        csvContent.writeln('Activity Statistics');
        csvContent.writeln('Today Check-ins,${data.todayCheckins}');
        csvContent.writeln('Active Emergencies,${data.activeEmergencies}');
        csvContent.writeln('');
        csvContent.writeln('Requests by Type');
        data.requestsByType.forEach((type, count) {
          csvContent.writeln('$type,$count');
        });
        csvContent.writeln('');
        csvContent.writeln('User Growth by Month');
        data.usersByMonth.forEach((month, count) {
          csvContent.writeln('$month,$count');
        });

        // Show export dialog with options
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Analytics'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Analytics report generated successfully!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 300,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        csvContent.toString(),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You can select and copy the data above.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Copy to clipboard
                  // Note: For web, this uses the browser's clipboard API
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Select the text above and copy it (Ctrl+C)'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy Instructions'),
              ),
            ],
          ),
        );
      },
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loading analytics data...')),
        );
      },
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting data: $error'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }
}
