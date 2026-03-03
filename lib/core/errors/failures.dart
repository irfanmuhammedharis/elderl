/// Base failure class
abstract class Failure {
  final String message;
  const Failure(this.message);
}

/// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure(super.message);
  
  factory AuthFailure.invalidCredentials() => 
      const AuthFailure('Invalid email or password');
  
  factory AuthFailure.userNotFound() => 
      const AuthFailure('User not found');
  
  factory AuthFailure.emailAlreadyInUse() => 
      const AuthFailure('Email is already registered');
  
  factory AuthFailure.weakPassword() => 
      const AuthFailure('Password is too weak');
  
  factory AuthFailure.networkError() => 
      const AuthFailure('Network error. Please check your connection');
  
  factory AuthFailure.unknown([String? message]) => 
      AuthFailure(message ?? 'An unknown error occurred');
}

/// Firestore failures
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
  
  factory DatabaseFailure.notFound() => 
      const DatabaseFailure('Data not found');
  
  factory DatabaseFailure.permissionDenied() => 
      const DatabaseFailure('Permission denied');
  
  factory DatabaseFailure.unknown([String? message]) => 
      DatabaseFailure(message ?? 'Database error occurred');
}

/// Network failures
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
  
  factory NetworkFailure.noConnection() => 
      const NetworkFailure('No internet connection');
  
  factory NetworkFailure.timeout() => 
      const NetworkFailure('Connection timed out');
}

/// Location failures
class LocationFailure extends Failure {
  const LocationFailure(super.message);
  
  factory LocationFailure.serviceDisabled() => 
      const LocationFailure('Location services are disabled');
  
  factory LocationFailure.permissionDenied() => 
      const LocationFailure('Location permission denied');
}
