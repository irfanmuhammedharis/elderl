import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/messaging_helper.dart';
import '../../../../core/services/notification_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../requests/data/request_repository.dart';
import '../../../emergency/data/emergency_repository.dart';
import '../../../admin/data/admin_repository.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../data/caregiver_repository.dart';

/// Stream provider for pending requests
final pendingRequestsStreamProvider = StreamProvider<List<HelpRequest>>((ref) {
  final repo = ref.watch(caregiverRepositoryProvider);
  return repo.streamPendingRequests();
});

/// Stream provider for my assigned requests
final myAssignedRequestsStreamProvider =
    StreamProvider.family<List<HelpRequest>, String>((ref, caregiverId) {
  final repo = ref.watch(caregiverRepositoryProvider);
  return repo.streamMyAssignedRequests(caregiverId);
});

/// Stream provider for active emergencies
final activeEmergenciesStreamProvider =
    StreamProvider<List<EmergencyAlert>>((ref) {
  final repo = ref.watch(emergencyRepositoryProvider);
  return repo.streamActiveEmergencies();
});

class CaregiverHomeScreen extends ConsumerStatefulWidget {
  const CaregiverHomeScreen({super.key});

  @override
  ConsumerState<CaregiverHomeScreen> createState() =>
      _CaregiverHomeScreenState();
}

class _CaregiverHomeScreenState extends ConsumerState<CaregiverHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  int _currentNavIndex = 0;
  StreamSubscription<InAppAlert>? _alertSubscription;
  InAppAlert? _currentAlert;

  static const _brandColor = AppTheme.caregiverColor;
  static const _brandDark = Color(0xFF00897B);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();

    // Start listening for real-time request alerts via RTDB
    _startAlertListener();
  }

  void _startAlertListener() {
    final notificationService = ref.read(notificationServiceProvider);
    notificationService.startRequestAlertStream();

    _alertSubscription = notificationService.alertStream.listen((alert) {
      if (!mounted) return;
      // Haptic feedback for new request
      HapticFeedback.heavyImpact();
      setState(() => _currentAlert = alert);
      // Auto-dismiss after 6 seconds
      Future.delayed(const Duration(seconds: 6), () {
        if (mounted && _currentAlert?.id == alert.id) {
          setState(() => _currentAlert = null);
        }
      });
    });
  }

  @override
  void dispose() {
    _alertSubscription?.cancel();
    ref.read(notificationServiceProvider).stopRequestAlertStream();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final userId = user?.uid ?? '';

    final pendingAsync = ref.watch(pendingRequestsStreamProvider);
    final myTasksAsync = ref.watch(myAssignedRequestsStreamProvider(userId));
    final emergenciesAsync = ref.watch(activeEmergenciesStreamProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _brandColor.withOpacity(0.08),
              AppTheme.backgroundLight,
              AppTheme.backgroundLight,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, ref),
              // Real-time in-app alert banner
              if (_currentAlert != null) _buildAlertBanner(_currentAlert!),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: RefreshIndicator(
                    color: _brandColor,
                    onRefresh: () async {
                      ref.invalidate(pendingRequestsStreamProvider);
                      ref.invalidate(
                          myAssignedRequestsStreamProvider(userId));
                      ref.invalidate(activeEmergenciesStreamProvider);
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildWelcomeCard(context, user),
                          const SizedBox(height: 24),
                          _buildStatsRow(pendingAsync, myTasksAsync,
                              emergenciesAsync),
                          const SizedBox(height: 28),
                          // Linked Seniors Section
                          if (user?.assignedSeniors != null && user!.assignedSeniors!.isNotEmpty) ...[
                            _buildSection(
                              context,
                              'My Seniors',
                              Icons.elderly,
                              _brandColor,
                            ),
                            const SizedBox(height: 12),
                            _buildLinkedSeniors(context, user.assignedSeniors!),
                            const SizedBox(height: 24),
                          ],
                          _buildSection(
                            context,
                            'Active Emergencies',
                            Icons.emergency,
                            AppTheme.emergencyColor,
                          ),
                          const SizedBox(height: 12),
                          emergenciesAsync.when(
                            loading: () => _shimmer(),
                            error: (e, _) => _errorCard(e.toString()),
                            data: (d) => _buildEmergencies(context, ref, d),
                          ),
                          const SizedBox(height: 24),
                          _buildSection(context, 'Pending Requests',
                              Icons.pending_actions, AppTheme.warningColor),
                          const SizedBox(height: 12),
                          pendingAsync.when(
                            loading: () => _shimmer(),
                            error: (e, _) => _errorCard(e.toString()),
                            data: (d) => _buildPending(
                                context, ref, d, user?.name ?? 'C', userId),
                          ),
                          const SizedBox(height: 24),
                          _buildSection(context, 'My Tasks',
                              Icons.assignment, AppTheme.infoColor),
                          const SizedBox(height: 12),
                          myTasksAsync.when(
                            loading: () => _shimmer(),
                            error: (e, _) => _errorCard(e.toString()),
                            data: (d) => _buildTasks(context, ref, d),
                          ),
                          const SizedBox(height: 24),
                          _buildSection(context, 'Quick Actions',
                              Icons.flash_on, AppTheme.accentColor),
                          const SizedBox(height: 12),
                          _buildQuickActions(context),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ───────────── APP BAR ─────────────
  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2))
      ]),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_brandColor, _brandDark]),
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              const Icon(Icons.volunteer_activism, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 12),
        Text('ElderL',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: _brandColor, fontWeight: FontWeight.w700)),
        const Spacer(),
        _iconBtn(Icons.message, AppTheme.infoColor,
            () => context.push(AppRoutes.conversations)),
        _iconBtn(Icons.person, _brandColor,
            () => context.push(AppRoutes.profile)),
        _iconBtn(Icons.logout, AppTheme.errorColor, () async {
          await ref.read(authControllerProvider.notifier).signOut();
          if (context.mounted) context.go(AppRoutes.login);
        }),
      ]),
    );
  }

  Widget _iconBtn(IconData icon, Color c, VoidCallback onTap) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: c.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 22, color: c),
      ),
      onPressed: onTap,
    );
  }

  // ───────────── REAL-TIME ALERT BANNER ─────────────
  Widget _buildAlertBanner(InAppAlert alert) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade600, Colors.deepOrange.shade500],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.notification_important,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  alert.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alert.body,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => setState(() => _currentAlert = null),
          ),
        ],
      ),
    );
  }

  // ───────────── WELCOME ─────────────
  Widget _buildWelcomeCard(BuildContext context, dynamic user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [_brandColor, _brandDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: [
          BoxShadow(
              color: _brandColor.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Row(children: [
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.wb_sunny, color: Colors.white70, size: 22),
                  const SizedBox(width: 8),
                  Text(_greeting(),
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: Colors.white70)),
                ]),
                const SizedBox(height: 8),
                Text(user?.name ?? 'Caregiver',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Ready to help seniors today',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white70)),
              ]),
        ),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
              child: Text((user?.name ?? 'C')[0].toUpperCase(),
                  style: const TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold))),
        ),
      ]),
    );
  }

  // ───────────── STATS ─────────────
  Widget _buildStatsRow(
    AsyncValue<List<HelpRequest>> pend,
    AsyncValue<List<HelpRequest>> tasks,
    AsyncValue<List<EmergencyAlert>> emerg,
  ) {
    return Row(children: [
      Expanded(
          child: _stat(
              'Pending',
              pend.whenOrNull(data: (d) => '${d.length}') ?? '-',
              Icons.pending_actions,
              AppTheme.warningColor)),
      const SizedBox(width: 12),
      Expanded(
          child: _stat(
              'My Tasks',
              tasks.whenOrNull(
                      data: (d) =>
                          '${d.where((t) => t.status == 'accepted' || t.status == 'in_progress').length}') ??
                  '-',
              Icons.assignment,
              AppTheme.infoColor)),
      const SizedBox(width: 12),
      Expanded(
          child: _stat(
              'Alerts',
              emerg.whenOrNull(data: (d) => '${d.length}') ?? '-',
              Icons.emergency,
              AppTheme.emergencyColor)),
    ]);
  }

  Widget _stat(String label, String val, IconData icon, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: c.withOpacity(0.15)),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: c.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: c, size: 22),
        ),
        const SizedBox(height: 10),
        Text(val,
            style:
                TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: c)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryLight,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }

  // ───────────── SECTION HEADER ─────────────
  Widget _buildSection(
      BuildContext context, String title, IconData icon, Color c) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: c, size: 20),
      ),
      const SizedBox(width: 12),
      Text(title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w600)),
    ]);
  }

  // ───────────── EMERGENCIES ─────────────
  Widget _buildEmergencies(
      BuildContext context, WidgetRef ref, List<EmergencyAlert> list) {
    if (list.isEmpty) {
      return _successBanner('All Clear', 'No active emergencies right now');
    }
    return _card(
      Column(
        children: list.take(3).map((e) {
          final isLast = e == list.take(3).last;
          return Column(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                _iconCircle(Icons.emergency, AppTheme.emergencyColor),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(e.seniorName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(
                          '${_timeAgo(e.createdAtDateTime)} • ${e.status}',
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondaryLight)),
                    ])),
                _gradBtn('Respond', [AppTheme.emergencyColor, const Color(0xFFDC2626)],
                    Icons.bolt, () async {
                  final auth = ref.read(authControllerProvider);
                  await ref.read(emergencyRepositoryProvider).respondToEmergency(
                      e.id!, auth.user?.uid ?? '', auth.user?.name ?? 'Caregiver');
                }),
              ]),
            ),
            if (!isLast)
              Divider(
                  height: 1,
                  color: Colors.grey.shade200,
                  indent: 16,
                  endIndent: 16),
          ]);
        }).toList(),
      ),
      borderColor: AppTheme.emergencyColor,
    );
  }

  // ───────────── PENDING ─────────────
  Widget _buildPending(BuildContext context, WidgetRef ref,
      List<HelpRequest> list, String name, String uid) {
    if (list.isEmpty) {
      return _empty(Icons.inbox_rounded, 'No pending requests',
          'New requests will appear here');
    }
    return _card(Column(
      children: list.take(5).map((r) {
        final isLast = r == list.take(5).last;
        final c = _typeColor(r.type);
        return Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              _iconCircle(_typeIcon(r.type), c),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                        '${r.type[0].toUpperCase()}${r.type.substring(1)} Request',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text('${r.seniorName} • ${_timeAgo(r.createdAt)}',
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textSecondaryLight)),
                  ])),
              _gradBtn('Accept', [_brandColor, _brandDark], Icons.check,
                  () async {
                await ref
                    .read(caregiverRepositoryProvider)
                    .acceptRequest(r.id!, uid, name);
                if (context.mounted) _snack(context, 'Request accepted!');
              }),
            ]),
          ),
          if (!isLast)
            Divider(
                height: 1,
                color: Colors.grey.shade200,
                indent: 16,
                endIndent: 16),
        ]);
      }).toList(),
    ));
  }

  // ───────────── MY TASKS ─────────────
  Widget _buildTasks(
      BuildContext context, WidgetRef ref, List<HelpRequest> list) {
    final active = list
        .where((t) => t.status == 'accepted' || t.status == 'in_progress')
        .toList();
    if (active.isEmpty) {
      return _empty(Icons.assignment_turned_in_rounded, 'No active tasks',
          'Accept a request to start helping');
    }
    return _card(Column(
      children: active.take(3).map((t) {
        final isLast = t == active.take(3).last;
        final c = _typeColor(t.type);
        return Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              _iconCircle(_typeIcon(t.type), c),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(t.seniorName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 4),
                    Row(children: [
                      _chip(t.type[0].toUpperCase() + t.type.substring(1), c),
                      const SizedBox(width: 8),
                      _chip(t.status.replaceAll('_', ' '), AppTheme.infoColor),
                    ]),
                  ])),
              t.status == 'accepted'
                  ? _gradBtn('Start', [AppTheme.infoColor, const Color(0xFF2563EB)],
                      Icons.play_arrow, () async {
                      await ref
                          .read(caregiverRepositoryProvider)
                          .markInProgress(t.id!);
                    })
                  : _gradBtn(
                      'Done',
                      [AppTheme.successColor, const Color(0xFF16A34A)],
                      Icons.check_circle, () async {
                      await ref
                          .read(caregiverRepositoryProvider)
                          .completeRequest(t.id!);
                      if (context.mounted) _snack(context, 'Task completed! 🎉');
                    }),
            ]),
          ),
          if (!isLast)
            Divider(
                height: 1,
                color: Colors.grey.shade200,
                indent: 16,
                endIndent: 16),
        ]);
      }).toList(),
    ));
  }

  // ───────────── QUICK ACTIONS ─────────────
  Widget _buildQuickActions(BuildContext context) {
    return Row(children: [
      Expanded(
          child: _actionCard(context, Icons.list_alt, 'All Requests',
              AppTheme.successColor, () => context.push(AppRoutes.caregiverRequests))),
      const SizedBox(width: 12),
      Expanded(
          child: _actionCard(context, Icons.history, 'History',
              AppTheme.accentColor, () => context.push(AppRoutes.caregiverHistory))),
      const SizedBox(width: 12),
      Expanded(
          child: _actionCard(context, Icons.people, 'Seniors', _brandColor,
              () => context.push(AppRoutes.caregiverSeniors))),
    ]);
  }

  Widget _actionCard(BuildContext ctx, IconData icon, String label, Color c,
      VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: AppTheme.cardShadow,
            border: Border.all(color: c.withOpacity(0.15)),
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: c.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: c, size: 26),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppTheme.textPrimaryLight),
                textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }

  // ───────────── BOTTOM NAV ─────────────
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4))
      ]),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _nav(Icons.home_rounded, 'Home', 0, _brandColor,
                  () => context.go(AppRoutes.caregiverHome)),
              _nav(Icons.assignment_rounded, 'Requests', 1, AppTheme.warningColor,
                  () => context.go(AppRoutes.caregiverRequests)),
              _nav(Icons.people_rounded, 'Seniors', 2, AppTheme.infoColor,
                  () => context.go(AppRoutes.caregiverSeniors)),
              _nav(Icons.person_rounded, 'Profile', 3, AppTheme.accentColor,
                  () => context.go(AppRoutes.profile)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nav(IconData icon, String label, int i, Color c, VoidCallback onTap) {
    final active = _currentNavIndex == i;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (i != _currentNavIndex) {
            setState(() => _currentNavIndex = i);
            onTap();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: AppTheme.animationFast,
          padding: EdgeInsets.symmetric(
              horizontal: active ? 20 : 12, vertical: 10),
          decoration: BoxDecoration(
            color: active ? c.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon,
                color: active ? c : AppTheme.textSecondaryLight, size: 24),
            if (active) ...[
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: c, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ]),
        ),
      ),
    );
  }

  // ───────────── REUSABLE PIECES ─────────────
  Widget _card(Widget child, {Color? borderColor}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
        border: borderColor != null
            ? Border.all(color: borderColor.withOpacity(0.2))
            : null,
      ),
      child: child,
    );
  }

  Widget _iconCircle(IconData icon, Color c) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: c, size: 24),
    );
  }

  Widget _chip(String text, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(text,
          style:
              TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c)),
    );
  }

  Widget _gradBtn(
      String label, List<Color> colors, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                  color: colors.first.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ]),
        ),
      ),
    );
  }

  Widget _successBanner(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.successColor.withOpacity(0.2)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.check_circle,
              color: AppTheme.successColor, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.successColor)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      color: AppTheme.textSecondaryLight, fontSize: 14)),
            ])),
      ]),
    );
  }

  Widget _empty(IconData icon, String title, String sub) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, size: 40, color: AppTheme.textSecondaryLight),
        ),
        const SizedBox(height: 14),
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppTheme.textPrimaryLight)),
        const SizedBox(height: 4),
        Text(sub,
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textSecondaryLight)),
      ]),
    );
  }

  Widget _shimmer() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: const Center(
          child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5))),
    );
  }

  Widget _errorCard(String e) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.2)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: AppTheme.errorColor),
        const SizedBox(width: 12),
        Expanded(
            child:
                Text(e, style: const TextStyle(color: AppTheme.errorColor, fontSize: 13))),
      ]),
    );
  }

  void _snack(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Text(msg),
      ]),
      backgroundColor: AppTheme.successColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
    ));
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // ───────────── LINKED SENIORS ─────────────
  Widget _buildLinkedSeniors(BuildContext context, List<String> seniorIds) {
    final adminRepo = ref.watch(adminRepositoryProvider);
    
    return FutureBuilder<List<AppUser?>>(
      future: Future.wait(
        seniorIds.map((id) => adminRepo.getUserById(id)),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _shimmer();
        }
        
        if (snapshot.hasError) {
          return _errorCard('Failed to load seniors');
        }
        
        final seniors = (snapshot.data ?? []).whereType<AppUser>().toList();
        if (seniors.isEmpty) {
          return _empty(
            Icons.person_off,
            'No seniors assigned',
            'Contact admin to assign seniors',
          );
        }
        
        return _card(
          Column(
            children: seniors.asMap().entries.map((entry) {
              final index = entry.key;
              final senior = entry.value;
              final isLast = index == seniors.length - 1;
              
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: _brandColor.withOpacity(0.1),
                          backgroundImage: senior.avatarUrl != null
                              ? NetworkImage(senior.avatarUrl!)
                              : null,
                          child: senior.avatarUrl == null
                              ? Text(
                                  senior.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: _brandColor,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                senior.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (senior.phone != null)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        senior.phone!,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        // Quick Actions
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Consumer(
                              builder: (context, ref, child) => _iconBtn(
                                Icons.message,
                                _brandColor,
                                () {
                                  // Start conversation with senior
                                  MessagingHelper.startConversation(
                                    context: context,
                                    ref: ref,
                                    otherUserId: senior.uid,
                                    otherUserName: senior.name,
                                  );
                                },
                              ),
                            ),
                            _iconBtn(
                              Icons.arrow_forward_ios,
                              _brandColor,
                              () {
                                // Filter requests by senior
                                context.push('${AppRoutes.caregiverRequests}?seniorId=${senior.uid}');
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      color: Colors.grey.shade200,
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  IconData _typeIcon(String t) {
    switch (t.toLowerCase()) {
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

  Color _typeColor(String t) {
    switch (t.toLowerCase()) {
      case 'medical':
        return AppTheme.errorColor;
      case 'food':
        return AppTheme.warningColor;
      case 'transport':
        return AppTheme.infoColor;
      case 'companion':
        return AppTheme.accentColor;
      default:
        return AppTheme.textSecondaryLight;
    }
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return 'Unknown';
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return DateFormat('MMM d').format(dt);
  }
}
