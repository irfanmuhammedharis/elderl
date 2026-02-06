import 'package:flutter_test/flutter_test.dart';

// Import the actual AppUser class
import 'package:elderl/features/auth/domain/entities/app_user.dart';

void main() {
  group('AppUser Entity Tests', () {
    test('should create AppUser with required fields', () {
      const user = AppUser(
        uid: 'test-uid-123',
        email: 'test@example.com',
        name: 'Test User',
        role: 'senior',
      );

      expect(user.uid, 'test-uid-123');
      expect(user.email, 'test@example.com');
      expect(user.name, 'Test User');
      expect(user.role, 'senior');
      expect(user.isSenior, true);
      expect(user.isCaregiver, false);
    });

    test('should correctly identify user roles', () {
      const senior = AppUser(uid: '1', email: 'a@b.com', name: 'A', role: 'senior');
      const caregiver = AppUser(uid: '2', email: 'b@c.com', name: 'B', role: 'caregiver');
      const family = AppUser(uid: '3', email: 'c@d.com', name: 'C', role: 'family');
      const admin = AppUser(uid: '4', email: 'd@e.com', name: 'D', role: 'admin');

      expect(senior.isSenior, true);
      expect(caregiver.isCaregiver, true);
      expect(family.isFamily, true);
      expect(admin.isAdmin, true);
    });

    test('should convert to/from Map correctly', () {
      const user = AppUser(
        uid: 'test-uid',
        email: 'test@example.com',
        name: 'Test User',
        role: 'caregiver',
        phone: '+1234567890',
      );

      final map = user.toMap();
      final fromMap = AppUser.fromMap(map);

      expect(fromMap.uid, user.uid);
      expect(fromMap.email, user.email);
      expect(fromMap.name, user.name);
      expect(fromMap.role, user.role);
      expect(fromMap.phone, user.phone);
    });

    test('should convert to/from JSON correctly', () {
      const user = AppUser(
        uid: 'test-uid',
        email: 'test@example.com',
        name: 'Test User',
        role: 'family',
      );

      final json = user.toJson();
      final fromJson = AppUser.fromJson(json);

      expect(fromJson.uid, user.uid);
      expect(fromJson.email, user.email);
      expect(fromJson.name, user.name);
      expect(fromJson.role, user.role);
    });

    test('copyWith should create new instance with updated fields', () {
      const user = AppUser(
        uid: 'test-uid',
        email: 'test@example.com',
        name: 'Original Name',
        role: 'senior',
      );

      final updated = user.copyWith(name: 'Updated Name', phone: '+9876543210');

      expect(updated.uid, user.uid);
      expect(updated.name, 'Updated Name');
      expect(updated.phone, '+9876543210');
      expect(user.name, 'Original Name'); // Original unchanged
    });
  });

  group('Auth Status Tests', () {
    test('AuthStatus should have correct values', () {
      expect(AuthStatus.values.length, 4);
      expect(AuthStatus.initial.name, 'initial');
      expect(AuthStatus.authenticated.name, 'authenticated');
      expect(AuthStatus.unauthenticated.name, 'unauthenticated');
      expect(AuthStatus.loading.name, 'loading');
    });
  });
}

/// Auth status enum for testing
enum AuthStatus { initial, loading, authenticated, unauthenticated }
