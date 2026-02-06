import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../checkin/data/checkin_repository.dart';
import '../../../requests/data/request_repository.dart';
import '../controllers/family_controller.dart';

class FamilyHomeScreen extends ConsumerStatefulWidget {
  const FamilyHomeScreen({super.key});

  @override
  ConsumerState<FamilyHomeScreen> createState() => _FamilyHomeScreenState();
}

class _FamilyHomeScreenState extends ConsumerState<FamilyHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  int _currentNavIndex = 0;

  static const _brandColor = Color(0xFF7E57C2);
  static const _brandDark = Color(0xFF5E35B1);

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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final linkedSeniorAsync = ref.watch(linkedSeniorStreamProvider);

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
              _buildAppBar(context),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: linkedSeniorAsync.when(
                    loading: () => const Center(
                        child:
                            CircularProgressIndicator(color: _brandColor)),
                    error: (e, _) => _buildError(e.toString()),
                    data: (senior) {
                      if (senior == null) {
                        return _buildNoLinkedSenior(context, ref);
                      }
                      return _buildLinkedView(context, ref, senior, user);
                    },
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
  Widget _buildAppBar(BuildContext context) {
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
          child: const Icon(Icons.family_restroom, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 12),
        Text('ElderL',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: _brandColor, fontWeight: FontWeight.w700)),
        const Spacer(),
        _iconBtn(Icons.notifications, AppTheme.warningColor, () {}),
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

  // ───────────── NO SENIOR ─────────────
  Widget _buildNoLinkedSenior(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _brandColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(30),
              ),
              child:
                  const Icon(Icons.link_off_rounded, size: 60, color: _brandColor),
            ),
            const SizedBox(height: 28),
            Text('No Senior Linked',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryLight)),
            const SizedBox(height: 12),
            Text(
              'Link to a senior to monitor their well-being\nand receive real-time updates.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondaryLight, height: 1.5),
            ),
            const SizedBox(height: 36),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showLinkSeniorDialog(context, ref),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_brandColor, _brandDark]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: _brandColor.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6))
                    ],
                  ),
                  child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_link, color: Colors.white, size: 22),
                        SizedBox(width: 10),
                        Text('Link to Senior',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16)),
                      ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────── MAIN LINKED VIEW ─────────────
  Widget _buildLinkedView(
      BuildContext context, WidgetRef ref, dynamic senior, dynamic user) {
    return RefreshIndicator(
      color: _brandColor,
      onRefresh: () async {
        ref.invalidate(linkedSeniorStreamProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWelcomeCard(context, user),
            const SizedBox(height: 24),
            _buildSeniorStatusCard(context, senior),
            const SizedBox(height: 24),
            _buildSection(
                context, 'Recent Check-ins', Icons.fact_check, AppTheme.successColor),
            const SizedBox(height: 12),
            _buildCheckIns(context, ref, senior.uid),
            const SizedBox(height: 24),
            _buildSection(
                context, 'Senior\'s Requests', Icons.assignment, AppTheme.infoColor),
            const SizedBox(height: 12),
            _buildRequests(context, ref, senior.uid),
            const SizedBox(height: 24),
            _buildSection(context, 'Quick Actions', Icons.flash_on,
                AppTheme.accentColor),
            const SizedBox(height: 12),
            _buildQuickActions(context, senior),
            const SizedBox(height: 24),
            _buildEmergencyBanner(context),
            const SizedBox(height: 24),
          ],
        ),
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
                Text(user?.name ?? 'Family',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Caring for your loved ones',
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
              child: Text((user?.name ?? 'F')[0].toUpperCase(),
                  style: const TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold))),
        ),
      ]),
    );
  }

  // ───────────── SENIOR STATUS ─────────────
  Widget _buildSeniorStatusCard(BuildContext context, dynamic senior) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: _brandColor.withOpacity(0.15)),
      ),
      child: Row(children: [
        Stack(children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_brandColor, _brandDark]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
                child: Text((senior.name ?? 'S')[0].toUpperCase(),
                    style: const TextStyle(
                        fontSize: 26,
                        color: Colors.white,
                        fontWeight: FontWeight.bold))),
          ),
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.successColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
              child: const Icon(Icons.check, size: 12, color: Colors.white),
            ),
          ),
        ]),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(senior.name ?? 'Your Senior',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.email, size: 15, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(senior.email ?? '',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600)),
                ]),
                if (senior.phone != null) ...[
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(Icons.phone, size: 15, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text(senior.phone!,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600)),
                  ]),
                ],
              ]),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: _brandColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.arrow_forward_ios,
              size: 18, color: _brandColor),
        ),
      ]),
    );
  }

  // ───────────── CHECK-INS ─────────────
  Widget _buildCheckIns(BuildContext context, WidgetRef ref, String seniorId) {
    final async = ref.watch(seniorCheckInsStreamProvider(seniorId));
    return async.when(
      loading: () => _shimmer(),
      error: (e, _) => _errorCard(e.toString()),
      data: (checkIns) {
        if (checkIns.isEmpty) {
          return _empty(
              Icons.fact_check_rounded, 'No check-ins yet', 'Check-ins will appear here');
        }
        return _card(Column(
          children: checkIns.take(3).map((c) {
            final isLast = c == checkIns.take(3).last;
            final ok = c.status == 'ok';
            return Column(children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (ok
                              ? AppTheme.successColor
                              : AppTheme.warningColor)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                        ok ? Icons.check_circle : Icons.help_outline,
                        color: ok
                            ? AppTheme.successColor
                            : AppTheme.warningColor,
                        size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(ok ? "I'm OK" : c.status,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                        if (c.message != null)
                          Text(c.message!,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondaryLight)),
                      ])),
                  Text(_timeAgo(c.checkinTime),
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondaryLight)),
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
      },
    );
  }

  // ───────────── REQUESTS ─────────────
  Widget _buildRequests(BuildContext context, WidgetRef ref, String seniorId) {
    final async = ref.watch(seniorRequestsStreamProvider(seniorId));
    return async.when(
      loading: () => _shimmer(),
      error: (e, _) => _errorCard(e.toString()),
      data: (requests) {
        if (requests.isEmpty) {
          return _empty(Icons.inbox_rounded, 'No requests yet',
              'Help requests will appear here');
        }
        return _card(Column(
          children: requests.take(3).map((r) {
            final isLast = r == requests.take(3).last;
            final c = _typeColor(r.type);
            final sc = _statusColor(r.status);
            return Column(children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: c.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(_typeIcon(r.type), color: c, size: 24),
                  ),
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
                        Text(r.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondaryLight)),
                      ])),
                  _chip(r.status.replaceAll('_', ' '), sc),
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
      },
    );
  }

  // ───────────── QUICK ACTIONS ─────────────
  Widget _buildQuickActions(BuildContext context, dynamic senior) {
    return Row(children: [
      Expanded(
          child: _actionCard(context, Icons.call, 'Call', AppTheme.successColor,
              () => _callSenior(senior.phone))),
      const SizedBox(width: 12),
      Expanded(
          child: _actionCard(context, Icons.message, 'Message',
              AppTheme.infoColor, () => _messageSenior(senior.phone))),
      const SizedBox(width: 12),
      Expanded(
          child: _actionCard(context, Icons.location_on, 'Location',
              _brandColor, () {})),
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
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: AppTheme.cardShadow,
            border: Border.all(color: c.withOpacity(0.15)),
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: c.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: c, size: 28),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textPrimaryLight)),
          ]),
        ),
      ),
    );
  }

  // ───────────── EMERGENCY BANNER ─────────────
  Widget _buildEmergencyBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.emergencyColor.withOpacity(0.06),
            AppTheme.emergencyColor.withOpacity(0.02)
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.emergencyColor.withOpacity(0.2)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: AppTheme.emergencyColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.emergency, color: AppTheme.emergencyColor, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('Emergency Alerts Active',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.emergencyColor)),
              const SizedBox(height: 2),
              const Text('You\'ll be notified if an emergency is triggered',
                  style: TextStyle(
                      color: AppTheme.textSecondaryLight, fontSize: 13)),
            ])),
        Container(
          width: 48,
          height: 28,
          decoration: BoxDecoration(
            color: AppTheme.emergencyColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
              child: Icon(Icons.check, color: Colors.white, size: 16)),
        ),
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
              _nav(Icons.home_rounded, 'Home', 0, _brandColor, () {}),
              _nav(Icons.timeline_rounded, 'Activity', 1, AppTheme.infoColor,
                  () => context.push(AppRoutes.familyActivity)),
              _nav(Icons.fact_check_rounded, 'Check-ins', 2,
                  AppTheme.successColor,
                  () => context.push(AppRoutes.familyCheckins)),
              _nav(Icons.person_rounded, 'Profile', 3, AppTheme.accentColor,
                  () => context.push(AppRoutes.profile)),
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
              horizontal: active ? 18 : 12, vertical: 10),
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

  // ───────────── LINK DIALOG ─────────────
  void _showLinkSeniorDialog(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: _brandColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.add_link, color: _brandColor, size: 36),
            ),
            const SizedBox(height: 20),
            Text('Link to Senior',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Enter the email of the senior you care for',
                style: TextStyle(color: AppTheme.textSecondaryLight),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: "Senior's Email",
                prefixIcon: const Icon(Icons.email, color: _brandColor),
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMedium)),
                focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMedium),
                    borderSide:
                        const BorderSide(color: _brandColor, width: 2)),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final email = emailController.text.trim();
                      if (email.isNotEmpty) {
                        final success = await ref
                            .read(familyLinkControllerProvider.notifier)
                            .linkToSenior(email);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Row(children: [
                              Icon(
                                  success
                                      ? Icons.check_circle
                                      : Icons.error,
                                  color: Colors.white,
                                  size: 20),
                              const SizedBox(width: 10),
                              Text(success
                                  ? 'Linked successfully!'
                                  : 'Senior not found'),
                            ]),
                            backgroundColor: success
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium)),
                          ));
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [_brandColor, _brandDark]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                          child: Text('Link',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15))),
                    ),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  // ───────────── SHARED WIDGETS ─────────────
  Widget _card(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: child,
    );
  }

  Widget _chip(String text, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(text,
          style:
              TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c)),
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
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: _brandColor))),
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
            child: Text(e,
                style: const TextStyle(
                    color: AppTheme.errorColor, fontSize: 13))),
      ]),
    );
  }

  Widget _buildError(String msg) {
    return Center(
        child: Padding(
      padding: const EdgeInsets.all(32),
      child: _errorCard(msg),
    ));
  }

  // ───────────── HELPERS ─────────────
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

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return DateFormat('MMM d').format(dt);
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'pending':
        return AppTheme.warningColor;
      case 'accepted':
        return AppTheme.infoColor;
      case 'in_progress':
        return AppTheme.accentColor;
      case 'completed':
        return AppTheme.successColor;
      default:
        return AppTheme.textSecondaryLight;
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
}
