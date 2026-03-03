import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../domain/entities/app_user.dart';
import '../controllers/auth_controller.dart';

/// Stream provider that watches the current user's Firestore doc in real-time
/// so the screen auto-navigates when an admin approves the account.
final _approvalStreamProvider = StreamProvider.autoDispose<AppUser?>((ref) {
  final uid = ref.watch(authControllerProvider).user?.uid;
  if (uid == null || uid.isEmpty) return const Stream.empty();
  return ref.watch(authRepositoryProvider).getUserStream(uid);
});

/// Screen shown when user account is pending admin approval
class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    // Real-time Firestore stream: auto-navigate when admin approves
    ref.listen<AsyncValue<AppUser?>>(_approvalStreamProvider, (previous, next) {
      next.whenData((streamedUser) {
        if (streamedUser != null &&
            streamedUser.approvalStatus == ApprovalStatus.approved) {
          _navigateToHome(context, streamedUser.role);
        }
      });
    });

    // Also keep the old authController listener as a fallback
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.user != null && next.user!.approvalStatus == ApprovalStatus.approved) {
        // User has been approved, navigate to home
        _navigateToHome(context, next.user!.role);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
              // Waiting animation
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_top,
                  size: 64,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Waiting for Approval',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'Your account registration is complete.\nPlease wait while an administrator reviews and approves your account.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // User info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        context,
                        icon: Icons.person,
                        label: 'Name',
                        value: user?.name ?? '-',
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        context,
                        icon: Icons.email,
                        label: 'Email',
                        value: user?.email ?? '-',
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        context,
                        icon: Icons.badge,
                        label: 'Role',
                        value: _getRoleDisplayName(user?.role),
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        context,
                        icon: Icons.pending_actions,
                        label: 'Status',
                        value: _getStatusText(user?.approvalStatus),
                        valueColor: _getStatusColor(user?.approvalStatus),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Rejection message if rejected
              if (user?.approvalStatus == ApprovalStatus.rejected) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Registration Rejected',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                            if (user?.rejectionReason != null)
                              Text(
                                user!.rejectionReason!,
                                style: TextStyle(color: Colors.red.shade600),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Refresh button
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).refreshUser();
                  if (context.mounted) {
                    final updatedUser = ref.read(authControllerProvider).user;
                    if (updatedUser?.approvalStatus == ApprovalStatus.approved) {
                      _navigateToHome(context, updatedUser!.role);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Still waiting for approval...'),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Check Status'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
              const SizedBox(height: 16),

              // Logout button
              TextButton.icon(
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go(AppRoutes.login);
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey),
              ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: valueColor,
                      fontWeight: valueColor != null ? FontWeight.bold : null,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getRoleDisplayName(String? role) {
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

  String _getStatusText(ApprovalStatus? status) {
    switch (status) {
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

  Color _getStatusColor(ApprovalStatus? status) {
    switch (status) {
      case ApprovalStatus.pending:
        return Colors.orange;
      case ApprovalStatus.approved:
        return Colors.green;
      case ApprovalStatus.rejected:
        return Colors.red;
      default:
        return Colors.grey;
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
