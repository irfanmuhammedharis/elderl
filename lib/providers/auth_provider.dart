import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

/// Authentication state provider
/// Manages user authentication state and operations
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _errorMessage;
  UserModel? _currentUser;

  // Getters
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;

  /// Initialize auth state from storage
  Future<void> initAuth() async {
    try {
      _setLoading(true);
      await _storageService.init();

      final token = _storageService.getString(AppConstants.keyAuthToken);
      if (token != null && token.isNotEmpty) {
        // Validate token and get user
        final user = await _authService.getCurrentUser(token);
        if (user != null) {
          _currentUser = user;
          _isAuthenticated = true;
        } else {
          // Token invalid, clear it
          await _storageService.remove(AppConstants.keyAuthToken);
        }
      }
    } catch (e) {
      Logger.error('Auth init error', e);
      _setError('Failed to initialize authentication');
    } finally {
      _setLoading(false);
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await _authService.login(email, password);

      if (result != null) {
        _currentUser = result.user;
        _isAuthenticated = true;

        // Save token
        await _storageService.setString(
          AppConstants.keyAuthToken,
          result.token,
        );
        await _storageService.setString(
          AppConstants.keyUserId,
          result.user.id,
        );

        Logger.info('User logged in: ${result.user.email}');
        notifyListeners();
        return true;
      } else {
        _setError('Invalid email or password');
        return false;
      }
    } catch (e) {
      Logger.error('Login error', e);
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      _setLoading(true);

      await _authService.logout();
      await _storageService.remove(AppConstants.keyAuthToken);
      await _storageService.remove(AppConstants.keyUserId);

      _currentUser = null;
      _isAuthenticated = false;

      Logger.info('User logged out');
      notifyListeners();
    } catch (e) {
      Logger.error('Logout error', e);
    } finally {
      _setLoading(false);
    }
  }

  /// Register new user
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await _authService.register(
        name: name,
        email: email,
        password: password,
      );

      if (result != null) {
        _currentUser = result.user;
        _isAuthenticated = true;

        // Save token
        await _storageService.setString(
          AppConstants.keyAuthToken,
          result.token,
        );
        await _storageService.setString(
          AppConstants.keyUserId,
          result.user.id,
        );

        Logger.info('User registered: ${result.user.email}');
        notifyListeners();
        return true;
      } else {
        _setError('Registration failed');
        return false;
      }
    } catch (e) {
      Logger.error('Register error', e);
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update current user
  void updateUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
