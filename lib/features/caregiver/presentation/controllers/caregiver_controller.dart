import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../requests/data/request_repository.dart';
import '../../data/caregiver_repository.dart';

/// Provider for assigned seniors (for caregiver)
final assignedSeniorsProvider =
    FutureProvider.autoDispose<List<AppUser>>((ref) async {
  final authState = ref.watch(authControllerProvider);
  if (authState.user == null || authState.user!.role != 'caregiver') {
    return [];
  }

  final caregiverRepo = ref.watch(caregiverRepositoryProvider);
  return caregiverRepo.getAssignedSeniors(authState.user!.uid);
});

/// Stream provider for assigned seniors
final assignedSeniorsStreamProvider =
    StreamProvider.autoDispose<List<AppUser>>((ref) {
  final authState = ref.watch(authControllerProvider);
  if (authState.user == null || authState.user!.role != 'caregiver') {
    return Stream.value([]);
  }

  final caregiverRepo = ref.watch(caregiverRepositoryProvider);
  return caregiverRepo.streamAssignedSeniors(authState.user!.uid);
});

/// Provider for pending requests (all available requests)
final pendingRequestsProvider =
    FutureProvider.autoDispose<List<HelpRequest>>((ref) async {
  final authState = ref.watch(authControllerProvider);
  if (authState.user == null) return [];

  final caregiverRepo = ref.watch(caregiverRepositoryProvider);
  return caregiverRepo.getPendingRequests(authState.user!.uid);
});

/// Stream provider for pending requests
final pendingRequestsStreamProvider =
    StreamProvider.autoDispose<List<HelpRequest>>((ref) {
  final caregiverRepo = ref.watch(caregiverRepositoryProvider);
  return caregiverRepo.streamPendingRequests();
});

/// Provider for my assigned requests
final myAssignedRequestsProvider =
    FutureProvider.autoDispose<List<HelpRequest>>((ref) async {
  final authState = ref.watch(authControllerProvider);
  if (authState.user == null) return [];

  final caregiverRepo = ref.watch(caregiverRepositoryProvider);
  return caregiverRepo.getMyAssignedRequests(authState.user!.uid);
});

/// Stream provider for my assigned requests
final myAssignedRequestsStreamProvider =
    StreamProvider.autoDispose<List<HelpRequest>>((ref) {
  final authState = ref.watch(authControllerProvider);
  if (authState.user == null) return Stream.value([]);

  final caregiverRepo = ref.watch(caregiverRepositoryProvider);
  return caregiverRepo.streamMyAssignedRequests(authState.user!.uid);
});

/// Provider for completed requests history
final completedRequestsProvider =
    FutureProvider.autoDispose<List<HelpRequest>>((ref) async {
  final authState = ref.watch(authControllerProvider);
  if (authState.user == null) return [];

  final caregiverRepo = ref.watch(caregiverRepositoryProvider);
  return caregiverRepo.getCompletedRequests(authState.user!.uid);
});

/// Provider for seniors with missed check-ins
final missedCheckInsProvider =
    FutureProvider.autoDispose<List<AppUser>>((ref) async {
  final authState = ref.watch(authControllerProvider);
  if (authState.user == null) return [];

  final caregiverRepo = ref.watch(caregiverRepositoryProvider);
  return caregiverRepo.getSeniorsWithMissedCheckIn(authState.user!.uid);
});

/// Provider for caregivers assigned to a specific senior
final seniorCaregiversProvider = FutureProvider.autoDispose
    .family<List<AppUser>, String>((ref, seniorId) async {
  final caregiverRepo = ref.watch(caregiverRepositoryProvider);
  return caregiverRepo.getCaregivers(seniorId);
});

/// Controller for caregiver request actions
class CaregiverRequestController extends StateNotifier<AsyncValue<void>> {
  final CaregiverRepository _repository;
  final String _caregiverId;
  final String _caregiverName;

  CaregiverRequestController(
      this._repository, this._caregiverId, this._caregiverName)
      : super(const AsyncValue.data(null));

  Future<void> acceptRequest(String requestId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.acceptRequest(requestId, _caregiverId, _caregiverName);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markInProgress(String requestId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.markInProgress(requestId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> completeRequest(String requestId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.completeRequest(requestId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider for caregiver request controller
final caregiverRequestControllerProvider = StateNotifierProvider.autoDispose<
    CaregiverRequestController, AsyncValue<void>>((ref) {
  final authState = ref.watch(authControllerProvider);
  final repository = ref.watch(caregiverRepositoryProvider);

  return CaregiverRequestController(
    repository,
    authState.user?.uid ?? '',
    authState.user?.name ?? '',
  );
});
