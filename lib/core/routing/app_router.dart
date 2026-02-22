import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/pending_approval_screen.dart';
import '../../features/admin/presentation/screens/web_admin_dashboard.dart';
import '../../features/senior/presentation/screens/senior_home_screen.dart';
import '../../features/caregiver/presentation/screens/caregiver_home_screen.dart';
import '../../features/caregiver/presentation/screens/caregiver_requests_screen.dart';
import '../../features/caregiver/presentation/screens/caregiver_seniors_screen.dart';
import '../../features/caregiver/presentation/screens/caregiver_history_screen.dart';
import '../../features/family/presentation/screens/family_home_screen.dart';
import '../../features/family/presentation/screens/family_activity_screen.dart';
import '../../features/family/presentation/screens/family_checkins_screen.dart';
import '../../features/activity/presentation/screens/family_activity_feed_screen.dart';
import '../../features/emergency/presentation/screens/emergency_alerts_list_screen.dart';
import '../../features/admin/presentation/screens/admin_home_screen.dart';
import '../../features/admin/presentation/screens/admin_seniors_screen.dart';
import '../../features/admin/presentation/screens/admin_caregivers_screen.dart';
import '../../features/admin/presentation/screens/admin_requests_screen.dart';
import '../../features/admin/presentation/screens/admin_emergencies_screen.dart';
import '../../features/admin/presentation/screens/admin_analytics_screen.dart';
import '../../features/admin/presentation/screens/admin_settings_screen.dart';
import '../../features/admin/presentation/screens/user_approval_screen.dart';
import '../../features/admin/presentation/screens/user_detail_screen.dart';
import '../../features/admin/presentation/screens/admin_link_management_screen.dart';
import '../../features/checkin/presentation/screens/daily_checkin_screen.dart';
import '../../features/emergency/presentation/screens/emergency_screen.dart';
import '../../features/requests/presentation/screens/create_request_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/dev/presentation/screens/create_test_users_screen.dart';
import '../../features/messaging/presentation/screens/conversations_screen.dart';
import '../../features/messaging/presentation/screens/chat_screen.dart';

/// Route names
class AppRoutes {
  // Auth Routes
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String pendingApproval = '/pending-approval';
  static const String createTestUsers = '/dev/create-users';

  // Web-only Routes
  static const String webAdmin = '/web-admin';

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
  static const String caregiverEmergencyAlerts = '/caregiver/emergency-alerts';

  // Family Routes
  static const String familyHome = '/family';
  static const String familyActivity = '/family/activity';
  static const String familyCheckins = '/family/checkins';
  static const String familyActivityFeed = '/family/activity-feed';

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
  static const String adminLinkManagement = '/admin/link-management';

  // Messaging Routes
  static const String conversations = '/messages';
  static const String chat = '/messages/chat';

  // Common Routes
  static const String profile = '/profile';
}

/// Routes available on web platform
/// Only login and webAdmin are allowed - signup is Android-only
const _webAllowedRoutes = [
  AppRoutes.login,
  AppRoutes.webAdmin,
];

/// Admin routes that should be blocked on Android (admin uses web portal only)
const _adminOnlyRoutes = [
  AppRoutes.adminHome,
  AppRoutes.webAdmin,
];

/// Routes that should redirect to webAdmin on web platform
bool _isAndroidOnlyRoute(String location) {
  if (!kIsWeb) return false;
  
  // Allow web-specific routes
  for (final route in _webAllowedRoutes) {
    if (location.startsWith(route)) return false;
  }
  
  // Everything else is Android-only
  return true;
}

/// Check if route is admin-only (should be blocked on Android)
bool _isAdminOnlyRoute(String location) {
  for (final route in _adminOnlyRoutes) {
    if (location.startsWith(route)) return true;
  }
  return false;
}

/// App router provider
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.login,
    redirect: (context, state) {
      final location = state.uri.path;
      
      // On web, redirect Android-only routes to web admin
      if (kIsWeb && _isAndroidOnlyRoute(location)) {
        return AppRoutes.webAdmin;
      }
      
      // On Android, redirect admin routes to login (admin is web-only)
      if (!kIsWeb && _isAdminOnlyRoute(location)) {
        return AppRoutes.login;
      }
      
      return null; // No redirect
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
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
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

      // Web-only Routes
      GoRoute(
        path: AppRoutes.webAdmin,
        name: 'webAdmin',
        builder: (context, state) => const WebAdminDashboard(),
      ),

      // Senior Routes (Android only - web will redirect to webAdmin)
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
      GoRoute(
        path: AppRoutes.caregiverEmergencyAlerts,
        name: 'caregiverEmergencyAlerts',
        builder: (context, state) => const EmergencyAlertsListScreen(),
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
      GoRoute(
        path: AppRoutes.familyActivityFeed,
        name: 'familyActivityFeed',
        builder: (context, state) => const FamilyActivityFeedScreen(),
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
      GoRoute(
        path: AppRoutes.adminLinkManagement,
        name: 'adminLinkManagement',
        builder: (context, state) => const AdminLinkManagementScreen(),
      ),

      // Common Routes
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
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
