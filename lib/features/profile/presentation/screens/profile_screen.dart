import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/routing/app_router.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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

  Color _roleColor(String? role) => AppTheme.roleColor(role);

  String _roleLabel(String? role) {
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
        return 'User';
    }
  }

  IconData _roleIcon(String? role) {
    switch (role) {
      case 'senior':
        return Icons.elderly;
      case 'caregiver':
        return Icons.volunteer_activism;
      case 'family':
        return Icons.family_restroom;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final rc = _roleColor(user?.role);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [rc.withOpacity(0.1), AppTheme.backgroundLight],
            stops: const [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: AppTheme.textPrimaryLight, size: 22),
                    ),
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  Text('My Profile',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  const SizedBox(width: 48), // balance
                ]),
              ),
              // Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        _buildAvatarSection(context, user, rc),
                        const SizedBox(height: 28),
                        _buildInfoCard(context, user, rc),
                        const SizedBox(height: 24),
                        _buildEditButton(context, user, rc),
                        const SizedBox(height: 14),
                        _buildLogoutButton(context),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection(
      BuildContext context, AppUser? user, Color rc) {
    return Column(children: [
      Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [rc, rc.withOpacity(0.7)]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
                color: rc.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8))
          ],
        ),
        child: Center(
          child: Text(
            ((user?.name.isNotEmpty ?? false) ? user!.name[0] : 'U').toUpperCase(),
            style: const TextStyle(
                fontSize: 44, color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      const SizedBox(height: 18),
      Text(user?.name ?? 'User',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700, color: AppTheme.textPrimaryLight)),
      const SizedBox(height: 10),
      // Role badge
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: rc.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: rc.withOpacity(0.25)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(_roleIcon(user?.role), size: 18, color: rc),
          const SizedBox(width: 8),
          Text(_roleLabel(user?.role),
              style: TextStyle(
                  color: rc, fontWeight: FontWeight.w600, fontSize: 14)),
        ]),
      ),
    ]);
  }

  Widget _buildInfoCard(BuildContext context, AppUser? user, Color rc) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(children: [
        _infoRow(Icons.email_rounded, 'Email', user?.email ?? '-',
            AppTheme.infoColor),
        _divider(),
        _infoRow(Icons.phone_rounded, 'Phone', user?.phone ?? 'Not set',
            AppTheme.successColor),
        _divider(),
        _infoRow(Icons.home_rounded, 'Address', user?.address ?? 'Not set',
            AppTheme.accentColor),
        _divider(),
        _infoRow(
            Icons.calendar_today_rounded,
            'Member Since',
            user?.createdAt != null
                ? DateFormat('MMMM d, yyyy').format(user!.createdAt!)
                : '-',
            AppTheme.warningColor),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
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
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimaryLight)),
              ]),
        ),
      ]),
    );
  }

  Widget _divider() => Divider(height: 1, color: Colors.grey.shade200);

  Widget _buildEditButton(BuildContext context, AppUser? user, Color rc) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (user != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => EditProfileScreen(user: user)),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [rc, rc.withOpacity(0.8)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: rc.withOpacity(0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 5))
            ],
          ),
          child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Edit Profile',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16)),
              ]),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await ref.read(authControllerProvider.notifier).signOut();
          if (context.mounted) context.go(AppRoutes.login);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.errorColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.errorColor.withOpacity(0.2)),
          ),
          child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded,
                    color: AppTheme.errorColor, size: 20),
                SizedBox(width: 10),
                Text('Sign Out',
                    style: TextStyle(
                        color: AppTheme.errorColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 16)),
              ]),
        ),
      ),
    );
  }
}
