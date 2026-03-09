import 'package:flutter_test/flutter_test.dart';
import 'package:elderl/core/errors/failures.dart';

void main() {
  group('AuthFailure', () {
    test('should store message', () {
      const failure = AuthFailure('test error');
      expect(failure.message, 'test error');
    });

    test('invalidCredentials factory', () {
      final failure = AuthFailure.invalidCredentials();
      expect(failure.message, 'Invalid email or password');
      expect(failure, isA<AuthFailure>());
      expect(failure, isA<Failure>());
    });

    test('userNotFound factory', () {
      final failure = AuthFailure.userNotFound();
      expect(failure.message, 'User not found');
    });

    test('emailAlreadyInUse factory', () {
      final failure = AuthFailure.emailAlreadyInUse();
      expect(failure.message, 'Email is already registered');
    });

    test('weakPassword factory', () {
      final failure = AuthFailure.weakPassword();
      expect(failure.message, 'Password is too weak');
    });

    test('networkError factory', () {
      final failure = AuthFailure.networkError();
      expect(failure.message, 'Network error. Please check your connection');
    });

    test('unknown factory with default message', () {
      final failure = AuthFailure.unknown();
      expect(failure.message, 'An unknown error occurred');
    });

    test('unknown factory with custom message', () {
      final failure = AuthFailure.unknown('Custom error');
      expect(failure.message, 'Custom error');
    });
  });

  group('DatabaseFailure', () {
    test('should store message', () {
      const failure = DatabaseFailure('db error');
      expect(failure.message, 'db error');
    });

    test('notFound factory', () {
      final failure = DatabaseFailure.notFound();
      expect(failure.message, 'Data not found');
      expect(failure, isA<DatabaseFailure>());
      expect(failure, isA<Failure>());
    });

    test('permissionDenied factory', () {
      final failure = DatabaseFailure.permissionDenied();
      expect(failure.message, 'Permission denied');
    });

    test('unknown factory with default message', () {
      final failure = DatabaseFailure.unknown();
      expect(failure.message, 'Database error occurred');
    });

    test('unknown factory with custom message', () {
      final failure = DatabaseFailure.unknown('Specific DB error');
      expect(failure.message, 'Specific DB error');
    });
  });

  group('NetworkFailure', () {
    test('should store message', () {
      const failure = NetworkFailure('network issue');
      expect(failure.message, 'network issue');
    });

    test('noConnection factory', () {
      final failure = NetworkFailure.noConnection();
      expect(failure.message, 'No internet connection');
      expect(failure, isA<NetworkFailure>());
      expect(failure, isA<Failure>());
    });

    test('timeout factory', () {
      final failure = NetworkFailure.timeout();
      expect(failure.message, 'Connection timed out');
    });
  });

  group('LocationFailure', () {
    test('should store message', () {
      const failure = LocationFailure('location error');
      expect(failure.message, 'location error');
    });

    test('serviceDisabled factory', () {
      final failure = LocationFailure.serviceDisabled();
      expect(failure.message, 'Location services are disabled');
      expect(failure, isA<LocationFailure>());
      expect(failure, isA<Failure>());
    });

    test('permissionDenied factory', () {
      final failure = LocationFailure.permissionDenied();
      expect(failure.message, 'Location permission denied');
    });
  });

  group('Failure hierarchy', () {
    test('all failures extend Failure base class', () {
      expect(const AuthFailure('x'), isA<Failure>());
      expect(const DatabaseFailure('x'), isA<Failure>());
      expect(const NetworkFailure('x'), isA<Failure>());
      expect(const LocationFailure('x'), isA<Failure>());
    });
  });
}
