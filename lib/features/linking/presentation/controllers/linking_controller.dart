import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../data/linking_repository.dart';
import '../../../admin/data/admin_repository.dart';

/// State for linking operations
class LinkingState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const LinkingState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  LinkingState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return LinkingState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

/// Controller for managing senior-caregiver-family linking
class LinkingController extends StateNotifier<LinkingState> {
  final LinkingRepository _repository;
  // ignore: unused_field
  final Ref _ref;

  LinkingController(this._repository, this._ref) : super(const LinkingState());

  /// Link a caregiver to a senior
  Future<void> linkCaregiver(String seniorId, String caregiverId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.linkCaregiver(seniorId, caregiverId);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Caregiver linked successfully',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to link caregiver: $e',
      );
    }
  }

  /// Link a family member to a senior
  Future<void> linkFamilyMember(String seniorId, String familyId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.linkFamilyMember(seniorId, familyId);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Family member linked successfully',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to link family member: $e',
      );
    }
  }

  /// Unlink a caregiver from a senior
  Future<void> unlinkCaregiver(String seniorId, String caregiverId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.unlinkCaregiver(seniorId, caregiverId);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Caregiver unlinked successfully',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to unlink caregiver: $e',
      );
    }
  }

  /// Unlink a family member from a senior
  Future<void> unlinkFamilyMember(String seniorId, String familyId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.unlinkFamilyMember(seniorId, familyId);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Family member unlinked successfully',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to unlink family member: $e',
      );
    }
  }

  /// Validate minimum links (1 caregiver + 2 family members)
  Future<bool> validateMinimumLinks(String seniorId) async {
    try {
      return await _repository.validateMinimumLinks(seniorId);
    } catch (e) {
      state = state.copyWith(error: 'Validation failed: $e');
      return false;
    }
  }

  /// Get all linked users for a senior
  Future<Map<String, List<AppUser>>> getLinkedUsers(String seniorId) async {
    try {
      final linkedUsers = await _repository.getAllLinkedUsers(seniorId);
      return {
        'caregivers': linkedUsers.where((u) => u.role == 'caregiver').toList(),
        'family': linkedUsers.where((u) => u.role == 'family').toList(),
      };
    } catch (e) {
      state = state.copyWith(error: 'Failed to fetch linked users: $e');
      return {'caregivers': [], 'family': []};
    }
  }

  /// Clear success/error messages
  void clearMessages() {
    state = state.copyWith(
      error: null,
      successMessage: null,
    );
  }
}

/// Provider for linking controller
final linkingControllerProvider =
    StateNotifierProvider<LinkingController, LinkingState>((ref) {
  final repository = ref.watch(linkingRepositoryProvider);
  return LinkingController(repository, ref);
});

/// Provider for linked users of a specific senior
final linkedUsersProvider =
    FutureProvider.family<Map<String, List<AppUser>>, String>((ref, seniorId) async {
  final repository = ref.watch(linkingRepositoryProvider);
  final caregivers = await repository.getLinkedCaregivers(seniorId);
  final family = await repository.getLinkedFamily(seniorId);
  return {
    'caregivers': caregivers,
    'family': family,
  };
});

/// Provider for seniors available for caregivers
final availableSeniorsProvider = FutureProvider.autoDispose<List<AppUser>>((ref) async {
  final adminRepo = ref.watch(adminRepositoryProvider);
  final allUsers = await adminRepo.getAllUsers();
  return allUsers.where((u) => u.role == 'senior' && u.approvalStatus == 'approved').toList();
});

/// Provider for caregivers available for linking
final availableCaregiversProvider = 
    FutureProvider.autoDispose.family<List<AppUser>, String>((ref, seniorId) async {
  final repository = ref.watch(linkingRepositoryProvider);
  return repository.getAvailableCaregivers(seniorId);
});

/// Provider for family members available for linking
final availableFamilyProvider = 
    FutureProvider.autoDispose.family<List<AppUser>, String>((ref, seniorId) async {
  final repository = ref.watch(linkingRepositoryProvider);
  return repository.getAvailableFamily(seniorId);
});
