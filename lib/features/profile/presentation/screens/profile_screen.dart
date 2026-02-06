import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../common_widgets/senior_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 28),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Avatar
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Name
              Text(
                user?.name ?? 'User',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Role badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getRoleLabel(user?.role),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Profile details
              _buildProfileItem(
                context,
                icon: Icons.email,
                label: 'Email',
                value: user?.email ?? '-',
              ),
              _buildProfileItem(
                context,
                icon: Icons.phone,
                label: 'Phone',
                value: user?.phone ?? 'Not set',
              ),
              _buildProfileItem(
                context,
                icon: Icons.calendar_today,
                label: 'Member since',
                value: user?.createdAt != null
                    ? '${user!.createdAt!.day}/${user.createdAt!.month}/${user.createdAt!.year}'
                    : '-',
              ),
              const SizedBox(height: 32),

              // Edit Profile Button
              SeniorButton(
                text: 'Edit Profile',
                icon: Icons.edit,
                onPressed: () {
                  if (user != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(user: user),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),

              // Logout Button
              SeniorButton(
                text: 'Logout',
                icon: Icons.logout,
                backgroundColor: Colors.red,
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go(AppRoutes.login);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 28),
        title: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        subtitle: Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }

  String _getRoleLabel(String? role) {
    switch (role) {
      case 'senior':
        return '👴 Senior Citizen';
      case 'caregiver':
        return '🤝 Caregiver';
      case 'family':
        return '👨‍👩‍👧 Family Member';
      case 'admin':
        return '👑 Administrator';
      default:
        return 'User';
    }
  }
}
