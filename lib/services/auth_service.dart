import '../models/user_model.dart';
import '../utils/logger.dart';
import 'api_service.dart';

/// Authentication service
/// Handles all authentication-related API calls
class AuthService {
  final ApiService _apiService = ApiService();

  /// Login with email and password
  Future<AuthResult?> login(String email, String password) async {
    try {
      // TODO: Replace with actual API endpoint
      // final response = await _apiService.post('/auth/login', body: {
      //   'email': email,
      //   'password': password,
      // });

      // Simulated login for development
      await Future.delayed(const Duration(seconds: 1));

      // For demo purposes - accept any non-empty credentials
      if (email.isNotEmpty && password.isNotEmpty) {
        Logger.info('Login successful for: $email');
        return AuthResult(
          token: 'demo_token_${DateTime.now().millisecondsSinceEpoch}',
          user: UserModel(
            id: 'user_001',
            name: email.split('@').first.replaceAll('.', ' '),
            email: email,
            createdAt: DateTime.now(),
          ),
        );
      }

      return null;
    } catch (e) {
      Logger.error('AuthService login error', e);
      rethrow;
    }
  }

  /// Register new user
  Future<AuthResult?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // TODO: Replace with actual API endpoint
      // final response = await _apiService.post('/auth/register', body: {
      //   'name': name,
      //   'email': email,
      //   'password': password,
      // });

      // Simulated registration for development
      await Future.delayed(const Duration(seconds: 1));

      Logger.info('Registration successful for: $email');
      return AuthResult(
        token: 'demo_token_${DateTime.now().millisecondsSinceEpoch}',
        user: UserModel(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          email: email,
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      Logger.error('AuthService register error', e);
      rethrow;
    }
  }

  /// Get current user from token
  Future<UserModel?> getCurrentUser(String token) async {
    try {
      // TODO: Replace with actual API endpoint
      // final response = await _apiService.get('/auth/me', headers: {
      //   'Authorization': 'Bearer $token',
      // });

      // Simulated user fetch for development
      await Future.delayed(const Duration(milliseconds: 500));

      // Return demo user if token exists
      if (token.isNotEmpty) {
        return UserModel(
          id: 'user_001',
          name: 'Demo User',
          email: 'demo@example.com',
          createdAt: DateTime.now(),
        );
      }

      return null;
    } catch (e) {
      Logger.error('AuthService getCurrentUser error', e);
      return null;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      // TODO: Replace with actual API endpoint if needed
      // await _apiService.post('/auth/logout');

      // Simulated logout
      await Future.delayed(const Duration(milliseconds: 300));
      Logger.info('Logout successful');
    } catch (e) {
      Logger.error('AuthService logout error', e);
      rethrow;
    }
  }

  /// Request password reset
  Future<bool> requestPasswordReset(String email) async {
    try {
      // TODO: Replace with actual API endpoint
      // await _apiService.post('/auth/forgot-password', body: {
      //   'email': email,
      // });

      await Future.delayed(const Duration(seconds: 1));
      Logger.info('Password reset requested for: $email');
      return true;
    } catch (e) {
      Logger.error('AuthService requestPasswordReset error', e);
      return false;
    }
  }
}

/// Authentication result model
class AuthResult {
  final String token;
  final UserModel user;

  AuthResult({
    required this.token,
    required this.user,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      token: json['token'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
