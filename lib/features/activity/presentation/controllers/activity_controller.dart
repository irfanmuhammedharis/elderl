import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/activity_log.dart';
import '../../data/activity_repository.dart';

/// State for activity operations
class ActivityState {
  final bool isLoading;
  final String? error;
  final ActivityLog? selectedActivity;

  const ActivityState({
    this.isLoading = false,
    this.error,
    this.selectedActivity,
  });

  ActivityState copyWith({
    bool? isLoading,
    String? error,
    ActivityLog? selectedActivity,
  }) {
    return ActivityState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedActivity: selectedActivity ?? this.selectedActivity,
    );
  }
}

/// Controller for managing activity feed
class ActivityController extends StateNotifier<ActivityState> {
  // ignore: unused_field
  final ActivityRepository _repository;
  // ignore: unused_field
  final Ref _ref;

  ActivityController(this._repository, this._ref) : super(const ActivityState());

  /// Select an activity for viewing details
  void selectActivity(ActivityLog activity) {
    state = state.copyWith(selectedActivity: activity);
  }

  /// Clear selected activity
  void clearSelection() {
    state = state.copyWith(selectedActivity: null);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for activity controller
final activityControllerProvider =
    StateNotifierProvider<ActivityController, ActivityState>((ref) {
  final repository = ref.watch(activityRepositoryProvider);
  return ActivityController(repository, ref);
});

/// Stream provider for activities of a specific senior
final activitiesStreamProvider =
    StreamProvider.family<List<ActivityLog>, String>((ref, seniorId) {
  final repository = ref.watch(activityRepositoryProvider);
  return repository.streamActivitiesForSenior(seniorId);
});

/// Provider to get activity by ID
final activityByIdProvider =
    FutureProvider.family<ActivityLog?, String>((ref, activityId) async {
  final repository = ref.watch(activityRepositoryProvider);
  try {
    final activities = await repository.streamActivitiesForSenior('').first;
    return activities.firstWhere(
      (a) => a.id == activityId,
      orElse: () => throw Exception('Activity not found'),
    );
  } catch (e) {
    return null;
  }
});
