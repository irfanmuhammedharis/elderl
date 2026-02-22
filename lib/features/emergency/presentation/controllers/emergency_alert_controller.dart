import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/location_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/emergency_repository.dart' as repo;

/// Emergency state for countdown and trigger management
class EmergencyAlertState {
  final bool isCountdownActive;
  final int remainingSeconds;
  final bool isLoading;
  final String? error;
  final String? triggeredAlertId;
  final EmergencyStatus currentStatus;

  const EmergencyAlertState({
    this.isCountdownActive = false,
    this.remainingSeconds = 5,
    this.isLoading = false,
    this.error,
    this.triggeredAlertId,
    this.currentStatus = EmergencyStatus.idle,
  });

  EmergencyAlertState copyWith({
    bool? isCountdownActive,
    int? remainingSeconds,
    bool? isLoading,
    String? error,
    String? triggeredAlertId,
    EmergencyStatus? currentStatus,
  }) {
    return EmergencyAlertState(
      isCountdownActive: isCountdownActive ?? this.isCountdownActive,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      triggeredAlertId: triggeredAlertId ?? this.triggeredAlertId,
      currentStatus: currentStatus ?? this.currentStatus,
    );
  }
}

/// Emergency status enum extension to state
enum EmergencyStatus {
  idle,
  countdown,
  triggered,
  resolved,
}

/// Controller for emergency alert management
class EmergencyAlertController extends StateNotifier<EmergencyAlertState> {
  final repo.EmergencyRepository _repository;
  final LocationService _locationService;
  final Ref _ref;
  Timer? _countdownTimer;

  EmergencyAlertController(this._repository, this._locationService, this._ref)
      : super(const EmergencyAlertState());

  /// Start 5-second countdown
  void startCountdown() {
    if (state.isCountdownActive) return;

    state = state.copyWith(
      isCountdownActive: true,
      remainingSeconds: 5,
      currentStatus: EmergencyStatus.countdown,
      error: null,
    );

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 1) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        timer.cancel();
        _triggerEmergency();
      }
    });
  }

  /// Cancel countdown
  void cancelCountdown() {
    _countdownTimer?.cancel();
    state = state.copyWith(
      isCountdownActive: false,
      remainingSeconds: 5,
      currentStatus: EmergencyStatus.idle,
    );
  }

  /// Trigger emergency (called automatically after countdown or manually)
  Future<void> _triggerEmergency() async {
    state = state.copyWith(
      isLoading: true,
      isCountdownActive: false,
      currentStatus: EmergencyStatus.triggered,
    );

    try {
      // Get current location
      final location = await _locationService.getCurrentLocation();
      final lat = location?.latitude ?? 0.0;
      final lng = location?.longitude ?? 0.0;

      // Get user details from auth
      final authState = _ref.read(authControllerProvider);
      final userId = authState.user?.uid;
      final userName = authState.user?.name ?? 'Unknown';
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Create emergency alert
      final alertId = await _repository.createEmergency(
        repo.EmergencyAlert(
          seniorId: userId,
          seniorName: userName,
          latitude: lat,
          longitude: lng,
        ),
      );

      state = state.copyWith(
        isLoading: false,
        triggeredAlertId: alertId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to trigger emergency: $e',
        currentStatus: EmergencyStatus.idle,
      );
    }
  }

  /// Manually trigger emergency (for testing or direct trigger)
  Future<void> triggerEmergencyNow(String seniorId) async {
    cancelCountdown();
    state = state.copyWith(
      isLoading: true,
      currentStatus: EmergencyStatus.triggered,
    );

    try {
      final location = await _locationService.getCurrentLocation();
      final lat = location?.latitude ?? 0.0;
      final lng = location?.longitude ?? 0.0;

      // Get senior details
      final authState = _ref.read(authControllerProvider);
      final seniorName = authState.user?.name ?? 'Unknown';

      final alertId = await _repository.createEmergency(
        repo.EmergencyAlert(
          seniorId: seniorId,
          seniorName: seniorName,
          latitude: lat,
          longitude: lng,
        ),
      );

      state = state.copyWith(
        isLoading: false,
        triggeredAlertId: alertId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to trigger emergency: $e',
        currentStatus: EmergencyStatus.idle,
      );
    }
  }

  /// Respond to emergency (caregiver/family action)
  Future<void> respondToEmergency(String alertId, String responderId) async {
    state = state.copyWith(isLoading: true);
    try {
      // Get responder name from auth
      final authState = _ref.read(authControllerProvider);
      final responderName = authState.user?.name ?? 'Unknown';
      
      await _repository.respondToEmergency(
        alertId,
        responderId,
        responderName,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to respond: $e',
      );
    }
  }

  /// Resolve emergency
  Future<void> resolveEmergency(String alertId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.resolveEmergency(alertId);
      state = state.copyWith(
        isLoading: false,
        currentStatus: EmergencyStatus.resolved,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to resolve emergency: $e',
      );
    }
  }

  /// Cancel emergency
  Future<void> cancelEmergency(String alertId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.cancelEmergency(alertId);
      state = state.copyWith(
        isLoading: false,
        currentStatus: EmergencyStatus.idle,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to cancel emergency: $e',
      );
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset state
  void reset() {
    _countdownTimer?.cancel();
    state = const EmergencyAlertState();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}

/// Provider for current user ID
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.user?.uid;
});

/// Provider for emergency alert controller
final emergencyAlertControllerProvider =
    StateNotifierProvider<EmergencyAlertController, EmergencyAlertState>((ref) {
  final repository = ref.watch(repo.emergencyRepositoryProvider);
  final locationService = LocationService();
  return EmergencyAlertController(repository, locationService, ref);
});

/// Stream provider for active emergencies for linked seniors
final linkedSeniorsEmergenciesStreamProvider =
    StreamProvider<List<repo.EmergencyAlert>>((ref) {
  final repository = ref.watch(repo.emergencyRepositoryProvider);
  final currentUser = ref.watch(authControllerProvider).user;
  
  // Get linked senior IDs from current user
  final seniorIds = <String>[];
  if (currentUser != null) {
    if (currentUser.role == 'caregiver' && currentUser.assignedSeniors != null) {
      seniorIds.addAll(currentUser.assignedSeniors!);
    } else if (currentUser.role == 'family' && currentUser.linkedSeniorId != null) {
      seniorIds.add(currentUser.linkedSeniorId!);
    }
  }
  
  return repository.streamEmergenciesForLinkedSeniors(seniorIds);
});

/// Stream provider for emergency by ID
final emergencyByIdStreamProvider =
    StreamProvider.family<repo.EmergencyAlert?, String>((ref, alertId) {
  final repository = ref.watch(repo.emergencyRepositoryProvider);
  return repository.streamEmergency(alertId);
});
