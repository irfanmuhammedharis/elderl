import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/app_user.dart';
import '../controllers/auth_controller.dart';

class PendingApprovalScreen extends ConsumerStatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  ConsumerState<PendingApprovalScreen> createState() =>
      _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends ConsumerState<PendingApprovalScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isChecking = false;

  static const _accentColor = Color(0xFFF59E0B);
  static const _accentDark = Color(0xFFD97706);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (next.user != null &&
          next.user!.approvalStatus == ApprovalStatus.approved) {
        _navigateToHome(context, next.user!.role);
      }
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _accentColor.withOpacity(0.08),
              AppTheme.backgroundLight,
              AppTheme.backgroundLight,
            ],
            stops: const [0.0, 0.35, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 32),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight - 64),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildHourglassAnimation(),
                        const SizedBox(height: 36),
                        _buildTitle(context),
                        const SizedBox(height: 16),
                        _buildDescription(context),
                        const SizedBox(height: 36),
                        _buildUserInfoCard(context, user),
                        const SizedBox(height: 24),
                        if (user?.approvalStatus ==
                            ApprovalStatus.rejected)
                          _buildRejectionBanner(context, user),
                        if (user?.approvalStatus ==
                            ApprovalStatus.rejected)
                          const SizedBox(height: 24),
                        _buildCheckButton(context, ref),
                        const SizedBox(height: 16),
                        _buildSignOutButton(context, ref),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ───────────── ANIMATED HOURGLASS ─────────────
  Widget _buildHourglassAnimation() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _accentColor.withOpacity(0.15),
                  _accentColor.withOpacity(0.05)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                    color: _accentColor.withOpacity(0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 8))
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer ring
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                        color: _accentColor.withOpacity(0.3), width: 2),
                  ),
                ),
                // Hourglass icon
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _pulseController.value * math.pi * 0.1,
                      child: const Icon(Icons.hourglass_top_rounded,
                          size: 56, color: _accentDark),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ───────────── TITLE ─────────────
  Widget _buildTitle(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [_accentDark, _accentColor],
      ).createShader(bounds),
      child: Text(
        'Waiting for Approval',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ───────────── DESCRIPTION ─────────────
  Widget _buildDescription(BuildContext context) {
    return Text(
      'Your account registration is complete.\nPlease wait while an administrator reviews your account.',
      style: Theme.of(context)
          .textTheme
          .bodyLarge
          ?.copyWith(color: AppTheme.textSecondaryLight, height: 1.5),
      textAlign: TextAlign.center,
    );
  }

  // ───────────── USER INFO CARD ─────────────
  Widget _buildUserInfoCard(BuildContext context, dynamic user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: _accentColor.withOpacity(0.12)),
      ),
      child: Column(children: [
        _infoRow(context, Icons.person_rounded, 'Name',
            user?.name ?? '-', AppTheme.primaryColor),
        _divider(),
        _infoRow(context, Icons.email_rounded, 'Email',
            user?.email ?? '-', AppTheme.infoColor),
        _divider(),
        _infoRow(context, Icons.badge_rounded, 'Role',
            _roleDisplay(user?.role), AppTheme.accentColor),
        _divider(),
        _infoRow(
          context,
          Icons.pending_actions_rounded,
          'Status',
          _statusText(user?.approvalStatus),
          _statusColor(user?.approvalStatus),
          isBold: true,
        ),
      ]),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label,
      String value, Color c,
      {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: c.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: c, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryLight,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isBold ? FontWeight.w700 : FontWeight.w500,
                        color: isBold ? c : AppTheme.textPrimaryLight)),
              ]),
        ),
      ]),
    );
  }

  Widget _divider() {
    return Divider(height: 1, color: Colors.grey.shade200);
  }

  // ───────────── REJECTION ─────────────
  Widget _buildRejectionBanner(BuildContext context, dynamic user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.2)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.error_rounded,
              color: AppTheme.errorColor, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Registration Rejected',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.errorColor)),
                if (user?.rejectionReason != null) ...[
                  const SizedBox(height: 6),
                  Text(user!.rejectionReason!,
                      style: TextStyle(
                          color: AppTheme.errorColor.withOpacity(0.8),
                          fontSize: 14,
                          height: 1.4)),
                ],
              ]),
        ),
      ]),
    );
  }

  // ───────────── CHECK BUTTON ─────────────
  Widget _buildCheckButton(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isChecking
            ? null
            : () async {
                setState(() => _isChecking = true);
                await ref
                    .read(authControllerProvider.notifier)
                    .refreshUser();
                if (context.mounted) {
                  final updated = ref.read(authControllerProvider).user;
                  if (updated?.approvalStatus == ApprovalStatus.approved) {
                    _navigateToHome(context, updated!.role);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Row(children: [
                        Icon(Icons.hourglass_bottom,
                            color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text('Still waiting for approval...'),
                      ]),
                      backgroundColor: _accentDark,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium)),
                    ));
                  }
                }
                setState(() => _isChecking = false);
              },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: _isChecking
                    ? [Colors.grey.shade400, Colors.grey.shade500]
                    : [_accentColor, _accentDark]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (!_isChecking)
                BoxShadow(
                    color: _accentColor.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6))
            ],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _isChecking
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : const Icon(Icons.refresh_rounded,
                    color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(_isChecking ? 'Checking...' : 'Check Status',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16)),
          ]),
        ),
      ),
    );
  }

  // ───────────── SIGN OUT ─────────────
  Widget _buildSignOutButton(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      onPressed: () async {
        await ref.read(authControllerProvider.notifier).signOut();
        if (context.mounted) context.go(AppRoutes.login);
      },
      icon: const Icon(Icons.logout_rounded, size: 20),
      label: const Text('Sign Out'),
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.textSecondaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      ),
    );
  }

  // ───────────── HELPERS ─────────────
  String _roleDisplay(String? role) {
    switch (role) {
      case 'senior':
        return 'Senior Citizen';
      case 'caregiver':
        return 'Caregiver';
      case 'family':
        return 'Family Member';
      case 'admin':
        return 'Administrator';
      default:
        return role ?? '-';
    }
  }

  String _statusText(ApprovalStatus? s) {
    switch (s) {
      case ApprovalStatus.pending:
        return 'Pending Approval';
      case ApprovalStatus.approved:
        return 'Approved';
      case ApprovalStatus.rejected:
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  Color _statusColor(ApprovalStatus? s) {
    switch (s) {
      case ApprovalStatus.pending:
        return _accentColor;
      case ApprovalStatus.approved:
        return AppTheme.successColor;
      case ApprovalStatus.rejected:
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondaryLight;
    }
  }

  void _navigateToHome(BuildContext context, String role) {
    final route = switch (role) {
      'caregiver' => AppRoutes.caregiverHome,
      'family' => AppRoutes.familyHome,
      'admin' => AppRoutes.adminHome,
      _ => AppRoutes.seniorHome,
    };
    context.go(route);
  }
}
