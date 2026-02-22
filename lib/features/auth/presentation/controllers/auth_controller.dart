import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/user_repository.dart';
import '../../domain/entities/app_user.dart';

/// Auth state
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final AppUser? user;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    AppUser? user,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }

  factory AuthState.initial() => const AuthState();
  factory AuthState.loading() => const AuthState(isLoading: true);
  factory AuthState.authenticated(AppUser user) => AuthState(
        isAuthenticated: true,
        user: user,
      );
  factory AuthState.error(String message) => AuthState(errorMessage: message);
}

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Auth controller provider
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    ref.watch(authRepositoryProvider),
    ref.watch(notificationServiceProvider),
    ref.watch(userRepositoryProvider),
  );
});

/// Auth controller
class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final NotificationService _notificationService;
  final UserRepository _userRepository;

  AuthController(this._repository, this._notificationService, this._userRepository)
      : super(AuthState.initial());

  /// Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    state = AuthState.loading();
    try {
      final user = await _repository.signIn(email, password);
      if (user != null) {
        state = AuthState.authenticated(user);
        // Save FCM token for push notifications
        _notificationService.getAndSaveToken(user.uid, _userRepository);
        return true;
      } else {
        state = AuthState.error('Invalid credentials');
        return false;
      }
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  /// Sign up with user details
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
    String? linkedSeniorId,
  }) async {
    state = AuthState.loading();
    try {
      final user = await _repository.signUp(
        email: email,
        password: password,
        name: name,
        role: role,
        phone: phone,
        linkedSeniorId: linkedSeniorId,
      );
      if (user != null) {
        state = AuthState.authenticated(user);
        return true;
      } else {
        state = AuthState.error('Registration failed');
        return false;
      }
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  /// Find a registered senior by their email
  Future<Map<String, String>?> findSeniorByEmail(String email) async {
    try {
      return await _repository.findSeniorByEmail(email);
    } catch (e) {
      throw Exception('Could not verify senior email. Please check your internet connection and try again.');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _repository.signOut();
    state = AuthState.initial();
  }

  /// Refresh current user data from server
  Future<void> refreshUser() async {
    if (state.user == null) return;
    
    try {
      final refreshedUser = await _repository.getCurrentUser();
      if (refreshedUser != null) {
        state = AuthState.authenticated(refreshedUser);
      }
    } catch (e) {
      // Keep current state on error
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
