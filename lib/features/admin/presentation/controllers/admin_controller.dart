import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/admin_repository.dart';

/// Filter state for user management
class UserFilterState {
  final String? roleFilter;
  final ApprovalStatus? statusFilter;
  final String searchQuery;

  const UserFilterState({
    this.roleFilter,
    this.statusFilter,
    this.searchQuery = '',
  });

  UserFilterState copyWith({
    String? roleFilter,
    ApprovalStatus? statusFilter,
    String? searchQuery,
    bool clearRoleFilter = false,
    bool clearStatusFilter = false,
  }) {
    return UserFilterState(
      roleFilter: clearRoleFilter ? null : (roleFilter ?? this.roleFilter),
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Filter state provider
final userFilterProvider = StateProvider<UserFilterState>((ref) {
  return const UserFilterState();
});

/// Provider for all users
final allUsersProvider = FutureProvider.autoDispose<List<AppUser>>((ref) async {
  final adminRepo = ref.watch(adminRepositoryProvider);
  return adminRepo.getAllUsers();
});

/// Stream provider for all users
final allUsersStreamProvider = StreamProvider.autoDispose<List<AppUser>>((ref) {
  final adminRepo = ref.watch(adminRepositoryProvider);
  return adminRepo.streamAllUsers();
});

/// Provider for pending users
final pendingUsersProvider =
    FutureProvider.autoDispose<List<AppUser>>((ref) async {
  final adminRepo = ref.watch(adminRepositoryProvider);
  return adminRepo.getPendingUsers();
});

/// Stream provider for pending users
final pendingUsersStreamProvider =
    StreamProvider.autoDispose<List<AppUser>>((ref) {
  final adminRepo = ref.watch(adminRepositoryProvider);
  return adminRepo.streamPendingUsers();
});

/// Provider for filtered users
final filteredUsersProvider =
    FutureProvider.autoDispose<List<AppUser>>((ref) async {
  final adminRepo = ref.watch(adminRepositoryProvider);
  final filter = ref.watch(userFilterProvider);

  List<AppUser> users;

  if (filter.roleFilter != null || filter.statusFilter != null) {
    users = await adminRepo.getUsersByRoleAndStatus(
        filter.roleFilter, filter.statusFilter);
  } else {
    users = await adminRepo.getAllUsers();
  }

  // Apply search filter
  if (filter.searchQuery.isNotEmpty) {
    final query = filter.searchQuery.toLowerCase();
    users = users.where((user) {
      return user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          (user.phone?.contains(filter.searchQuery) ?? false);
    }).toList();
  }

  return users;
});

/// Provider for users by role
final usersByRoleProvider =
    FutureProvider.autoDispose.family<List<AppUser>, String>((ref, role) async {
  final adminRepo = ref.watch(adminRepositoryProvider);
  return adminRepo.getUsersByRole(role);
});

/// Stream provider for users by role
final usersByRoleStreamProvider =
    StreamProvider.autoDispose.family<List<AppUser>, String>((ref, role) {
  final adminRepo = ref.watch(adminRepositoryProvider);
  return adminRepo.streamUsersByRole(role);
});

/// Provider for single user details
final userDetailProvider =
    FutureProvider.autoDispose.family<AppUser?, String>((ref, uid) async {
  final adminRepo = ref.watch(adminRepositoryProvider);
  return adminRepo.getUserById(uid);
});

/// Stream provider for single user
final userDetailStreamProvider =
    StreamProvider.autoDispose.family<AppUser?, String>((ref, uid) {
  final adminRepo = ref.watch(adminRepositoryProvider);
  return adminRepo.streamUser(uid);
});

/// Provider for user statistics
final userStatisticsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final adminRepo = ref.watch(adminRepositoryProvider);
  return adminRepo.getUserStatistics();
});

/// Controller for admin actions
class AdminUserController extends StateNotifier<AsyncValue<void>> {
  final AdminRepository _repository;
  final String _adminUid;

  AdminUserController(this._repository, this._adminUid)
      : super(const AsyncValue.data(null));

  /// Approve a user
  Future<bool> approveUser(String uid) async {
    state = const AsyncValue.loading();
    try {
      await _repository.approveUser(uid, _adminUid);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Reject a user
  Future<bool> rejectUser(String uid, String reason) async {
    state = const AsyncValue.loading();
    try {
      await _repository.rejectUser(uid, _adminUid, reason);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Reset user to pending
  Future<bool> resetToPending(String uid) async {
    state = const AsyncValue.loading();
    try {
      await _repository.resetToPending(uid);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Delete user
  Future<bool> deleteUser(String uid) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteUser(uid);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateUser(String uid, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateUser(uid, data);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Admin user controller provider
final adminUserControllerProvider =
    StateNotifierProvider.autoDispose<AdminUserController, AsyncValue<void>>(
        (ref) {
  final authState = ref.watch(authControllerProvider);
  final repository = ref.watch(adminRepositoryProvider);
  
  // Keep alive to prevent disposal during async operations
  ref.keepAlive();

  return AdminUserController(
    repository,
    authState.user?.uid ?? '',
  );
});

/// Provider for pending count (for badges)
final pendingCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final adminRepo = ref.watch(adminRepositoryProvider);
  final pending = await adminRepo.getPendingUsers();
  return pending.length;
});
