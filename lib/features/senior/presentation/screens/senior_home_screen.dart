import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../common_widgets/senior_button.dart';
import '../../../../common_widgets/sync_indicator.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class SeniorHomeScreen extends ConsumerWidget {
  const SeniorHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    return PopScope(
      canPop: false,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('ElderL'),
        actions: [
          // Sync status indicator
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: SyncIndicator(showText: false),
          ),
          IconButton(
            icon: const Icon(Icons.person, size: 28),
            onPressed: () => context.push(AppRoutes.profile),
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 28),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Offline banner when not connected
            const OfflineBanner(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Greeting
                    Text(
                      'Hello, ${user?.name ?? 'Friend'}!',
                      style: Theme.of(context).textTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'How can we help you today?',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Main Action Buttons - Large for seniors
              _buildMainButton(
                context,
                icon: Icons.local_hospital,
                label: 'Medical Help',
                description: 'Request medical assistance',
                color: Colors.red.shade400,
                onPressed: () => context.push(
                  '${AppRoutes.createRequest}?type=medical',
                ),
              ),
              const SizedBox(height: 16),

              _buildMainButton(
                context,
                icon: Icons.restaurant,
                label: 'Food Help',
                description: 'Request food delivery',
                color: Colors.orange.shade400,
                onPressed: () => context.push(
                  '${AppRoutes.createRequest}?type=food',
                ),
              ),
              const SizedBox(height: 16),

              _buildMainButton(
                context,
                icon: Icons.check_circle,
                label: "I'm OK",
                description: 'Daily check-in',
                color: AppTheme.successColor,
                onPressed: () => context.push(AppRoutes.dailyCheckin),
              ),
              const SizedBox(height: 32),

              // Emergency Button - Most prominent
              SeniorButton(
                text: 'EMERGENCY',
                icon: Icons.emergency,
                backgroundColor: AppTheme.emergencyColor,
                onPressed: () => context.push(AppRoutes.emergency),
                padding: const EdgeInsets.symmetric(vertical: 24),
              ),
              const SizedBox(height: 16),

              Text(
                'Press for immediate emergency assistance',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildMainButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 24,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
