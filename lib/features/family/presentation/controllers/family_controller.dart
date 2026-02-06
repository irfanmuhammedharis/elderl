import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../checkin/data/checkin_repository.dart';
import '../../../requests/data/request_repository.dart';
import '../../data/family_repository.dart';

/// Provider for linked senior data
final linkedSeniorProvider = FutureProvider.autoDispose<AppUser?>((ref) async {
  final authState = ref.watch(authControllerProvider);
  if (authState.user == null || authState.user!.role != 'family') {
    return null;
  }

  final familyRepo = ref.watch(familyRepositoryProvider);
  return familyRepo.getLinkedSenior(authState.user!.uid);
});

/// Stream provider for real-time linked senior updates
final linkedSeniorStreamProvider = StreamProvider.autoDispose<AppUser?>((ref) {
  final authState = ref.watch(authControllerProvider);
  if (authState.user == null || authState.user!.role != 'family') {
    return Stream.value(null);
  }

  final familyRepo = ref.watch(familyRepositoryProvider);
  return familyRepo.streamLinkedSenior(authState.user!.uid);
});

/// Provider for senior's check-ins (for family to view)
final seniorCheckInsProvider = FutureProvider.autoDispose
    .family<List<CheckIn>, String>((ref, seniorId) async {
  final familyRepo = ref.watch(familyRepositoryProvider);
  return familyRepo.getSeniorCheckIns(seniorId);
});

/// Stream provider for senior's check-ins
final seniorCheckInsStreamProvider =
    StreamProvider.autoDispose.family<List<CheckIn>, String>((ref, seniorId) {
  final familyRepo = ref.watch(familyRepositoryProvider);
  return familyRepo.streamSeniorCheckIns(seniorId);
});

/// Provider for senior's requests (for family to view)
final seniorRequestsProvider = FutureProvider.autoDispose
    .family<List<HelpRequest>, String>((ref, seniorId) async {
  final familyRepo = ref.watch(familyRepositoryProvider);
  return familyRepo.getSeniorRequests(seniorId);
});

/// Stream provider for senior's requests
final seniorRequestsStreamProvider = StreamProvider.autoDispose
    .family<List<HelpRequest>, String>((ref, seniorId) {
  final familyRepo = ref.watch(familyRepositoryProvider);
  return familyRepo.streamSeniorRequests(seniorId);
});

/// Provider for family members of a senior
final familyMembersProvider = FutureProvider.autoDispose
    .family<List<AppUser>, String>((ref, seniorId) async {
  final familyRepo = ref.watch(familyRepositoryProvider);
  return familyRepo.getFamilyMembers(seniorId);
});

/// Controller for family linking actions
class FamilyLinkController extends StateNotifier<AsyncValue<void>> {
  final FamilyRepository _repository;
  final String _familyUserId;

  FamilyLinkController(this._repository, this._familyUserId)
      : super(const AsyncValue.data(null));

  Future<bool> linkToSenior(String seniorEmail) async {
    state = const AsyncValue.loading();
    try {
      final success =
          await _repository.linkToSenior(_familyUserId, seniorEmail);
      state = const AsyncValue.data(null);
      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> unlinkFromSenior(String seniorId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.unlinkFromSenior(_familyUserId, seniorId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider for family link controller
final familyLinkControllerProvider =
    StateNotifierProvider.autoDispose<FamilyLinkController, AsyncValue<void>>(
        (ref) {
  final authState = ref.watch(authControllerProvider);
  final repository = ref.watch(familyRepositoryProvider);

  return FamilyLinkController(
    repository,
    authState.user?.uid ?? '',
  );
});
