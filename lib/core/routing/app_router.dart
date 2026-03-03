import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/pending_approval_screen.dart';
import '../../features/senior/presentation/screens/senior_home_screen.dart';
import '../../features/caregiver/presentation/screens/caregiver_home_screen.dart';
import '../../features/caregiver/presentation/screens/caregiver_requests_screen.dart';
import '../../features/caregiver/presentation/screens/caregiver_seniors_screen.dart';
import '../../features/caregiver/presentation/screens/caregiver_history_screen.dart';
import '../../features/family/presentation/screens/family_home_screen.dart';
import '../../features/family/presentation/screens/family_activity_screen.dart';
import '../../features/family/presentation/screens/family_checkins_screen.dart';
import '../../features/admin/presentation/screens/admin_home_screen.dart';
import '../../features/admin/presentation/screens/admin_seniors_screen.dart';
import '../../features/admin/presentation/screens/admin_caregivers_screen.dart';
import '../../features/admin/presentation/screens/admin_requests_screen.dart';
import '../../features/admin/presentation/screens/admin_emergencies_screen.dart';
import '../../features/admin/presentation/screens/admin_analytics_screen.dart';
import '../../features/admin/presentation/screens/admin_settings_screen.dart';
import '../../features/admin/presentation/screens/user_approval_screen.dart';
import '../../features/admin/presentation/screens/user_detail_screen.dart';
import '../../features/checkin/presentation/screens/daily_checkin_screen.dart';
import '../../features/emergency/presentation/screens/emergency_screen.dart';
import '../../features/requests/presentation/screens/create_request_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/dev/presentation/screens/create_test_users_screen.dart';
import '../../features/messaging/presentation/screens/conversations_screen.dart';
import '../../features/messaging/presentation/screens/chat_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';

/// Route names
class AppRoutes {
  // Auth Routes
  static const String login = '/login';
  static const String signup = '/signup';
  static const String pendingApproval = '/pending-approval';
  static const String createTestUsers = '/dev/create-users';

  // Senior Routes
  static const String seniorHome = '/senior';
  static const String dailyCheckin = '/senior/checkin';
  static const String emergency = '/senior/emergency';
  static const String createRequest = '/senior/request/create';

  // Caregiver Routes
  static const String caregiverHome = '/caregiver';
  static const String caregiverRequests = '/caregiver/requests';
  static const String caregiverSeniors = '/caregiver/seniors';
  static const String caregiverHistory = '/caregiver/history';
  static const String caregiverRequestDetail = '/caregiver/request';

  // Family Routes
  static const String familyHome = '/family';
  static const String familyActivity = '/family/activity';
  static const String familyCheckins = '/family/checkins';
  static const String familySeniorDetail = '/family/senior';

  // Admin Routes
  static const String adminHome = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminUserDetail = '/admin/users/:uid';
  static const String adminSeniors = '/admin/seniors';
  static const String adminCaregivers = '/admin/caregivers';
  static const String adminRequests = '/admin/requests';
  static const String adminEmergencies = '/admin/emergencies';
  static const String adminAnalytics = '/admin/analytics';
  static const String adminSettings = '/admin/settings';

  // Messaging Routes
  static const String conversations = '/messages';
  static const String chat = '/messages/chat';

  // Common Routes
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String forgotPassword = '/forgot-password';
}

/// Helper to resolve the home route for a given role
String _homeForRole(String role) => switch (role) {
      'caregiver' => AppRoutes.caregiverHome,
      'family' => AppRoutes.familyHome,
      'admin' => AppRoutes.adminHome,
      _ => AppRoutes.seniorHome,
    };

/// Listenable that bridges Riverpod auth state to GoRouter refreshes
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(Ref ref) {
    ref.listen<AuthState>(authControllerProvider, (_, __) {
      notifyListeners();
    });
  }
}

/// App router provider
final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthNotifier(ref);
  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final isAuthenticated = authState.isAuthenticated;
      final user = authState.user;
      final path = state.uri.path;

      // Public routes that don't require authentication
      const publicRoutes = [
        AppRoutes.login,
        AppRoutes.signup,
        AppRoutes.forgotPassword,
        AppRoutes.createTestUsers,
      ];
      final isPublicRoute = publicRoutes.contains(path);

      // Redirect unauthenticated users to login
      if (!isAuthenticated && !isPublicRoute) {
        return AppRoutes.login;
      }

      // Redirect authenticated users away from auth screens
      if (isAuthenticated &&
          user != null &&
          isPublicRoute &&
          path != AppRoutes.createTestUsers) {
        if (user.approvalStatus != ApprovalStatus.approved &&
            user.role != 'admin') {
          return AppRoutes.pendingApproval;
        }
        return _homeForRole(user.role);
      }

      // Redirect unapproved users to pending approval screen
      // This prevents them from accessing protected routes (e.g. caregiver requests)
      // which would trigger Firestore permission-denied errors
      if (isAuthenticated &&
          user != null &&
          !isPublicRoute &&
          path != AppRoutes.pendingApproval &&
          user.approvalStatus != ApprovalStatus.approved &&
          user.role != 'admin') {
        return AppRoutes.pendingApproval;
      }

      // Role-based route protection (admins can access all)
      if (isAuthenticated && user != null && !user.isAdmin) {
        if (path.startsWith('/senior') && !user.isSenior) {
          return _homeForRole(user.role);
        }
        if (path.startsWith('/caregiver') && !user.isCaregiver) {
          return _homeForRole(user.role);
        }
        if (path.startsWith('/family') && !user.isFamily) {
          return _homeForRole(user.role);
        }
        if (path.startsWith('/admin')) {
          return _homeForRole(user.role);
        }
      }

      return null; // no redirect
    },
    routes: [
      // Auth Routes
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.pendingApproval,
        name: 'pendingApproval',
        builder: (context, state) => const PendingApprovalScreen(),
      ),

      // Dev Routes (for testing)
      GoRoute(
        path: AppRoutes.createTestUsers,
        name: 'createTestUsers',
        builder: (context, state) => const CreateTestUsersScreen(),
      ),

      // Senior Routes
      GoRoute(
        path: AppRoutes.seniorHome,
        name: 'seniorHome',
        builder: (context, state) => const SeniorHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.dailyCheckin,
        name: 'dailyCheckin',
        builder: (context, state) => const DailyCheckInScreen(),
      ),
      GoRoute(
        path: AppRoutes.emergency,
        name: 'emergency',
        builder: (context, state) => const EmergencyScreen(),
      ),
      GoRoute(
        path: AppRoutes.createRequest,
        name: 'createRequest',
        builder: (context, state) {
          final type = state.uri.queryParameters['type'] ?? 'medical';
          return CreateRequestScreen(requestType: type);
        },
      ),

      // Caregiver Routes
      GoRoute(
        path: AppRoutes.caregiverHome,
        name: 'caregiverHome',
        builder: (context, state) => const CaregiverHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.caregiverRequests,
        name: 'caregiverRequests',
        builder: (context, state) => const CaregiverRequestsScreen(),
      ),
      GoRoute(
        path: AppRoutes.caregiverSeniors,
        name: 'caregiverSeniors',
        builder: (context, state) => const CaregiverSeniorsScreen(),
      ),
      GoRoute(
        path: AppRoutes.caregiverHistory,
        name: 'caregiverHistory',
        builder: (context, state) => const CaregiverHistoryScreen(),
      ),

      // Family Routes
      GoRoute(
        path: AppRoutes.familyHome,
        name: 'familyHome',
        builder: (context, state) => const FamilyHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.familyActivity,
        name: 'familyActivity',
        builder: (context, state) => const FamilyActivityScreen(),
      ),
      GoRoute(
        path: AppRoutes.familyCheckins,
        name: 'familyCheckins',
        builder: (context, state) => const FamilyCheckinsScreen(),
      ),

      // Admin Routes
      GoRoute(
        path: AppRoutes.adminHome,
        name: 'adminHome',
        builder: (context, state) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminUsers,
        name: 'adminUsers',
        builder: (context, state) => const UserApprovalScreen(),
      ),
      GoRoute(
        path: '/admin/users/:uid',
        name: 'adminUserDetail',
        builder: (context, state) {
          final uid = state.pathParameters['uid'] ?? '';
          return UserDetailScreen(userId: uid);
        },
      ),
      GoRoute(
        path: AppRoutes.adminSeniors,
        name: 'adminSeniors',
        builder: (context, state) => const AdminSeniorsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminCaregivers,
        name: 'adminCaregivers',
        builder: (context, state) => const AdminCaregiversScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminRequests,
        name: 'adminRequests',
        builder: (context, state) => const AdminRequestsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminEmergencies,
        name: 'adminEmergencies',
        builder: (context, state) => const AdminEmergenciesScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminAnalytics,
        name: 'adminAnalytics',
        builder: (context, state) => const AdminAnalyticsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminSettings,
        name: 'adminSettings',
        builder: (context, state) => const AdminSettingsScreen(),
      ),

      // Common Routes
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'editProfile',
        builder: (context, state) {
          final user = state.extra as AppUser?;
          if (user == null) {
            return const Scaffold(
              body: Center(child: Text('User data not available')),
            );
          }
          return EditProfileScreen(user: user);
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Messaging Routes
      GoRoute(
        path: AppRoutes.conversations,
        name: 'conversations',
        builder: (context, state) => const ConversationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.chat,
        name: 'chat',
        builder: (context, state) {
          final conversationId = state.uri.queryParameters['conversationId'] ?? '';
          final otherUserName = state.uri.queryParameters['otherUserName'] ?? 'User';
          final otherUserId = state.uri.queryParameters['otherUserId'];
          return ChatScreen(
            conversationId: conversationId,
            otherUserName: otherUserName,
            otherUserId: otherUserId,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${state.uri}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.login),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    ),
  );
});
