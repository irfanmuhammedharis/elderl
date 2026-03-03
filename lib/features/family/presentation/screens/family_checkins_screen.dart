import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../checkin/data/checkin_repository.dart';
import '../controllers/family_controller.dart';

/// Family Check-ins Screen - Detailed view of linked senior's check-in history
class FamilyCheckinsScreen extends ConsumerStatefulWidget {
  const FamilyCheckinsScreen({super.key});

  @override
  ConsumerState<FamilyCheckinsScreen> createState() => _FamilyCheckinsScreenState();
}

class _FamilyCheckinsScreenState extends ConsumerState<FamilyCheckinsScreen> {
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final linkedSeniorAsync = ref.watch(linkedSeniorStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-in History'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.familyHome);
            }
          },
        ),
      ),
      body: linkedSeniorAsync.when(
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
                onPressed: () => ref.invalidate(linkedSeniorStreamProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (linkedSenior) {
          if (linkedSenior == null) {
            return _buildNoSeniorLinked(context);
          }
          return _buildCheckinsView(context, ref, linkedSenior);
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 2,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go(AppRoutes.familyHome);
              break;
            case 1:
              context.push(AppRoutes.familyActivity);
              break;
            case 2:
              break;
            case 3:
              context.push(AppRoutes.profile);
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
    );
  }

  Widget _buildNoSeniorLinked(BuildContext context) {
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
              'Link to a senior to view their check-in history.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go(AppRoutes.familyHome),
              icon: const Icon(Icons.home),
              label: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckinsView(BuildContext context, WidgetRef ref, AppUser linkedSenior) {
    final checkInsAsync = ref.watch(seniorCheckInsStreamProvider(linkedSenior.uid));

    return checkInsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (checkIns) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Senior Info Card
              _buildSeniorInfoCard(context, linkedSenior, checkIns),
              
              // Statistics Card
              _buildStatisticsCard(context, checkIns),
              
              // Month Selector
              _buildMonthSelector(context),
              
              // Calendar View
              _buildCalendarView(context, checkIns),
              
              // Recent Check-ins List
              _buildRecentCheckinsList(context, checkIns),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSeniorInfoCard(BuildContext context, AppUser senior, List<CheckIn> checkIns) {
    final todayCheckin = checkIns.firstWhere(
      (c) {
        final today = DateTime.now();
        return c.checkinTime?.year == today.year &&
            c.checkinTime?.month == today.month &&
            c.checkinTime?.day == today.day;
      },
      orElse: () => CheckIn(seniorId: senior.uid, status: 'pending'),
    );

    final hasCheckedInToday = todayCheckin.status == 'ok';

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                hasCheckedInToday ? Colors.green.shade50 : Colors.orange.shade50,
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      senior.name.isNotEmpty ? senior.name[0].toUpperCase() : 'S',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: hasCheckedInToday ? Colors.green : Colors.orange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        hasCheckedInToday ? Icons.check : Icons.schedule,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      senior.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          hasCheckedInToday ? Icons.check_circle : Icons.pending,
                          size: 16,
                          color: hasCheckedInToday ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hasCheckedInToday ? 'Checked in today!' : 'Waiting for check-in',
                          style: TextStyle(
                            color: hasCheckedInToday ? Colors.green[700] : Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (hasCheckedInToday && todayCheckin.checkinTime != null)
                      Text(
                        'at ${DateFormat('h:mm a').format(todayCheckin.checkinTime!)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(BuildContext context, List<CheckIn> checkIns) {
    final now = DateTime.now();
    final last7Days = checkIns.where((c) {
      if (c.checkinTime == null) return false;
      return now.difference(c.checkinTime!).inDays < 7;
    }).length;

    final last30Days = checkIns.where((c) {
      if (c.checkinTime == null) return false;
      return now.difference(c.checkinTime!).inDays < 30;
    }).length;

    final streakCount = _calculateStreak(checkIns);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Check-in Statistics',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Current Streak',
                      '$streakCount days',
                      Icons.local_fire_department,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Last 7 Days',
                      '$last7Days / 7',
                      Icons.calendar_view_week,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Last 30 Days',
                      '$last30Days / 30',
                      Icons.calendar_month,
                      Colors.green,
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

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
              });
            },
          ),
          Text(
            DateFormat('MMMM yyyy').format(_selectedMonth),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _selectedMonth.isBefore(DateTime(DateTime.now().year, DateTime.now().month))
                ? () {
                    setState(() {
                      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView(BuildContext context, List<CheckIn> checkIns) {
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startingWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0

    // Get check-in dates for the selected month
    final checkinDates = <int>{};
    for (final checkin in checkIns) {
      if (checkin.checkinTime != null &&
          checkin.checkinTime!.year == _selectedMonth.year &&
          checkin.checkinTime!.month == _selectedMonth.month &&
          checkin.status == 'ok') {
        checkinDates.add(checkin.checkinTime!.day);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Day headers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                    .map((day) => SizedBox(
                          width: 36,
                          child: Text(day, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600], fontSize: 12)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              // Calendar grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: 42, // 6 weeks
                itemBuilder: (context, index) {
                  final dayNumber = index - startingWeekday + 1;
                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const SizedBox();
                  }

                  final isToday = _selectedMonth.year == DateTime.now().year &&
                      _selectedMonth.month == DateTime.now().month &&
                      dayNumber == DateTime.now().day;
                  final hasCheckin = checkinDates.contains(dayNumber);
                  final isPast = DateTime(_selectedMonth.year, _selectedMonth.month, dayNumber)
                      .isBefore(DateTime.now().subtract(const Duration(days: 1)));

                  return Container(
                    decoration: BoxDecoration(
                      color: hasCheckin
                          ? Colors.green.shade100
                          : (isPast && !hasCheckin ? Colors.red.shade50 : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(8),
                      border: isToday ? Border.all(color: AppTheme.primaryColor, width: 2) : null,
                    ),
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            dayNumber.toString(),
                            style: TextStyle(
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              color: hasCheckin ? Colors.green[800] : Colors.grey[800],
                            ),
                          ),
                          if (hasCheckin)
                            Positioned(
                              bottom: 2,
                              child: Icon(Icons.check_circle, size: 12, color: Colors.green[600]),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('Checked In', Colors.green.shade100),
                  const SizedBox(width: 16),
                  _buildLegendItem('Missed', Colors.red.shade50),
                  const SizedBox(width: 16),
                  _buildLegendItem('Upcoming', Colors.grey.shade100),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildRecentCheckinsList(BuildContext context, List<CheckIn> checkIns) {
    final recentCheckins = checkIns.take(10).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.history, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Recent Check-ins',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (recentCheckins.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No check-ins yet')),
                )
              else
                ...recentCheckins.map((checkin) => _buildCheckinListItem(context, checkin)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckinListItem(BuildContext context, CheckIn checkin) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: checkin.status == 'ok' ? Colors.green.shade100 : Colors.orange.shade100,
        child: Icon(
          checkin.status == 'ok' ? Icons.check : Icons.schedule,
          color: checkin.status == 'ok' ? Colors.green : Colors.orange,
        ),
      ),
      title: Text(
        checkin.status == 'ok' ? "I'm OK" : checkin.status.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: checkin.message != null ? Text(checkin.message!) : null,
      trailing: Text(
        checkin.checkinTime != null
            ? DateFormat('MMM d, h:mm a').format(checkin.checkinTime!)
            : 'Unknown',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
    );
  }

  int _calculateStreak(List<CheckIn> checkIns) {
    if (checkIns.isEmpty) return 0;

    // Sort by date descending
    final sortedCheckins = List<CheckIn>.from(checkIns)
      ..sort((a, b) => (b.checkinTime ?? DateTime(2000)).compareTo(a.checkinTime ?? DateTime(2000)));

    int streak = 0;
    DateTime? lastDate;

    for (final checkin in sortedCheckins) {
      if (checkin.checkinTime == null || checkin.status != 'ok') continue;

      final checkinDate = DateTime(
        checkin.checkinTime!.year,
        checkin.checkinTime!.month,
        checkin.checkinTime!.day,
      );

      if (lastDate == null) {
        // First check-in - must be today or yesterday to count
        final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
        final yesterday = today.subtract(const Duration(days: 1));
        if (checkinDate == today || checkinDate == yesterday) {
          streak = 1;
          lastDate = checkinDate;
        } else {
          break;
        }
      } else {
        final expectedDate = lastDate.subtract(const Duration(days: 1));
        if (checkinDate == expectedDate) {
          streak++;
          lastDate = checkinDate;
        } else {
          break;
        }
      }
    }

    return streak;
  }
}
