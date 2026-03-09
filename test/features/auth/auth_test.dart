import 'package:flutter_test/flutter_test.dart';

// Import the actual AppUser class
import 'package:elderl/features/auth/domain/entities/app_user.dart';
import 'package:elderl/features/auth/presentation/controllers/auth_controller.dart';

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

    test('should create AppUser with all fields', () {
      final now = DateTime.now();
      final user = AppUser(
        uid: 'uid-full',
        email: 'full@example.com',
        name: 'Full User',
        role: 'caregiver',
        phone: '+1234567890',
        address: '123 Main St',
        avatarUrl: 'https://example.com/avatar.png',
        fcmToken: 'fcm-token-123',
        linkedSeniorId: 'senior-1',
        linkedFamily: ['family-1', 'family-2'],
        assignedSeniors: ['senior-1', 'senior-2'],
        assignedCaregivers: ['cg-1'],
        createdAt: now,
        lastActiveAt: now,
        lastLogin: now,
        approvalStatus: ApprovalStatus.approved,
        approvedBy: 'admin-1',
        approvedAt: now,
        rejectionReason: null,
        dateOfBirth: DateTime(1950, 5, 15),
        emergencyContact: 'Jane Doe',
        emergencyPhone: '+0987654321',
        medicalConditions: 'Diabetes',
        bloodType: 'A+',
        allergies: 'Penicillin',
        notes: 'Needs wheelchair',
      );

      expect(user.phone, '+1234567890');
      expect(user.address, '123 Main St');
      expect(user.linkedFamily, hasLength(2));
      expect(user.assignedSeniors, hasLength(2));
      expect(user.approvalStatus, ApprovalStatus.approved);
      expect(user.medicalConditions, 'Diabetes');
      expect(user.bloodType, 'A+');
    });

    test('should correctly identify user roles', () {
      const senior = AppUser(uid: '1', email: 'a@b.com', name: 'A', role: 'senior');
      const caregiver = AppUser(uid: '2', email: 'b@c.com', name: 'B', role: 'caregiver');
      const family = AppUser(uid: '3', email: 'c@d.com', name: 'C', role: 'family');
      const admin = AppUser(uid: '4', email: 'd@e.com', name: 'D', role: 'admin');

      expect(senior.isSenior, true);
      expect(senior.isCaregiver, false);
      expect(senior.isFamily, false);
      expect(senior.isAdmin, false);

      expect(caregiver.isCaregiver, true);
      expect(family.isFamily, true);
      expect(admin.isAdmin, true);
    });

    test('should correctly identify approval status', () {
      const pending = AppUser(
        uid: '1', email: 'a@b.com', name: 'A', role: 'senior',
        approvalStatus: ApprovalStatus.pending,
      );
      const approved = AppUser(
        uid: '2', email: 'b@c.com', name: 'B', role: 'senior',
        approvalStatus: ApprovalStatus.approved,
      );
      const rejected = AppUser(
        uid: '3', email: 'c@d.com', name: 'C', role: 'senior',
        approvalStatus: ApprovalStatus.rejected,
      );

      expect(pending.isPending, true);
      expect(pending.isApproved, false);
      expect(pending.isRejected, false);

      expect(approved.isApproved, true);
      expect(rejected.isRejected, true);
    });

    test('default approvalStatus is pending', () {
      const user = AppUser(uid: '1', email: 'a@b.com', name: 'A', role: 'senior');
      expect(user.approvalStatus, ApprovalStatus.pending);
      expect(user.isPending, true);
    });
  });

  group('AppUser Boolean Helpers', () {
    test('hasLinkedFamily returns true when linkedFamily is non-empty', () {
      const withFamily = AppUser(
        uid: '1', email: 'a@b.com', name: 'A', role: 'senior',
        linkedFamily: ['f1', 'f2'],
      );
      const withoutFamily = AppUser(
        uid: '2', email: 'b@c.com', name: 'B', role: 'senior',
      );
      const emptyFamily = AppUser(
        uid: '3', email: 'c@d.com', name: 'C', role: 'senior',
        linkedFamily: [],
      );

      expect(withFamily.hasLinkedFamily, true);
      expect(withoutFamily.hasLinkedFamily, false);
      expect(emptyFamily.hasLinkedFamily, false);
    });

    test('hasAssignedCaregivers returns true when list is non-empty', () {
      const withCg = AppUser(
        uid: '1', email: 'a@b.com', name: 'A', role: 'senior',
        assignedCaregivers: ['cg1'],
      );
      const withoutCg = AppUser(
        uid: '2', email: 'b@c.com', name: 'B', role: 'senior',
      );

      expect(withCg.hasAssignedCaregivers, true);
      expect(withoutCg.hasAssignedCaregivers, false);
    });

    test('isLinkedToSenior returns true when linkedSeniorId is set', () {
      const linked = AppUser(
        uid: '1', email: 'a@b.com', name: 'A', role: 'family',
        linkedSeniorId: 'senior-1',
      );
      const notLinked = AppUser(
        uid: '2', email: 'b@c.com', name: 'B', role: 'family',
      );
      const emptyLinked = AppUser(
        uid: '3', email: 'c@d.com', name: 'C', role: 'family',
        linkedSeniorId: '',
      );

      expect(linked.isLinkedToSenior, true);
      expect(notLinked.isLinkedToSenior, false);
      expect(emptyLinked.isLinkedToSenior, false);
    });

    test('hasAssignedSeniors returns true when list is non-empty', () {
      const withSeniors = AppUser(
        uid: '1', email: 'a@b.com', name: 'A', role: 'caregiver',
        assignedSeniors: ['s1', 's2'],
      );
      const withoutSeniors = AppUser(
        uid: '2', email: 'b@c.com', name: 'B', role: 'caregiver',
      );

      expect(withSeniors.hasAssignedSeniors, true);
      expect(withoutSeniors.hasAssignedSeniors, false);
    });
  });

  group('AppUser Display Names', () {
    test('roleDisplayName returns correct display name', () {
      const senior = AppUser(uid: '1', email: 'a@b.com', name: 'A', role: 'senior');
      const caregiver = AppUser(uid: '2', email: 'b@c.com', name: 'B', role: 'caregiver');
      const family = AppUser(uid: '3', email: 'c@d.com', name: 'C', role: 'family');
      const admin = AppUser(uid: '4', email: 'd@e.com', name: 'D', role: 'admin');
      const unknown = AppUser(uid: '5', email: 'e@f.com', name: 'E', role: 'unknown_role');

      expect(senior.roleDisplayName, 'Senior/Elderly');
      expect(caregiver.roleDisplayName, 'Caregiver');
      expect(family.roleDisplayName, 'Family Member');
      expect(admin.roleDisplayName, 'Administrator');
      expect(unknown.roleDisplayName, 'unknown_role');
    });

    test('approvalStatusDisplayName returns correct display name', () {
      const pending = AppUser(
        uid: '1', email: 'a@b.com', name: 'A', role: 'senior',
        approvalStatus: ApprovalStatus.pending,
      );
      const approved = AppUser(
        uid: '2', email: 'b@c.com', name: 'B', role: 'senior',
        approvalStatus: ApprovalStatus.approved,
      );
      const rejected = AppUser(
        uid: '3', email: 'c@d.com', name: 'C', role: 'senior',
        approvalStatus: ApprovalStatus.rejected,
      );

      expect(pending.approvalStatusDisplayName, 'Pending Approval');
      expect(approved.approvalStatusDisplayName, 'Approved');
      expect(rejected.approvalStatusDisplayName, 'Rejected');
    });
  });

  group('AppUser Serialization - toMap/fromMap', () {
    test('toMap produces correct structure', () {
      const user = AppUser(
        uid: 'test-uid',
        email: 'test@example.com',
        name: 'Test User',
        role: 'caregiver',
        phone: '+1234567890',
      );

      final map = user.toMap();

      expect(map['uid'], 'test-uid');
      expect(map['email'], 'test@example.com');
      expect(map['name'], 'Test User');
      expect(map['role'], 'caregiver');
      expect(map['phone'], '+1234567890');
      expect(map['approvalStatus'], 'pending');
    });

    test('fromMap handles missing fields gracefully', () {
      final map = <String, dynamic>{
        'uid': 'uid-1',
        'email': 'test@test.com',
        'name': 'Test',
        'role': 'senior',
      };

      final user = AppUser.fromMap(map);

      expect(user.uid, 'uid-1');
      expect(user.phone, isNull);
      expect(user.address, isNull);
      expect(user.linkedFamily, isNull);
      expect(user.assignedSeniors, isNull);
    });

    test('fromMap handles empty map defaults', () {
      final map = <String, dynamic>{};

      final user = AppUser.fromMap(map);

      expect(user.uid, '');
      expect(user.email, '');
      expect(user.name, '');
      expect(user.role, 'senior'); // Default role
    });

    test('fromMap parses approval status correctly', () {
      final pendingMap = {'uid': '1', 'email': 'a@b.com', 'name': 'A', 'role': 'senior', 'approvalStatus': 'pending'};
      final approvedMap = {'uid': '2', 'email': 'b@c.com', 'name': 'B', 'role': 'senior', 'approvalStatus': 'approved'};
      final rejectedMap = {'uid': '3', 'email': 'c@d.com', 'name': 'C', 'role': 'senior', 'approvalStatus': 'rejected'};
      final nullMap = {'uid': '4', 'email': 'd@e.com', 'name': 'D', 'role': 'senior', 'approvalStatus': null};

      expect(AppUser.fromMap(pendingMap).approvalStatus, ApprovalStatus.pending);
      expect(AppUser.fromMap(approvedMap).approvalStatus, ApprovalStatus.approved);
      expect(AppUser.fromMap(rejectedMap).approvalStatus, ApprovalStatus.rejected);
      expect(AppUser.fromMap(nullMap).approvalStatus, ApprovalStatus.pending);
    });

    test('fromMap handles list fields correctly', () {
      final map = {
        'uid': '1',
        'email': 'a@b.com',
        'name': 'A',
        'role': 'senior',
        'linkedFamily': ['f1', 'f2'],
        'assignedCaregivers': ['cg1'],
      };

      final user = AppUser.fromMap(map);

      expect(user.linkedFamily, ['f1', 'f2']);
      expect(user.assignedCaregivers, ['cg1']);
    });

    test('toMap/fromMap round-trip preserves string fields', () {
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
  });

  group('AppUser Serialization - toJson/fromJson', () {
    test('toJson converts dates to ISO strings', () {
      final now = DateTime(2025, 6, 15, 10, 30);
      final user = AppUser(
        uid: 'test-uid',
        email: 'test@example.com',
        name: 'Test User',
        role: 'senior',
        createdAt: now,
      );

      final json = user.toJson();

      expect(json['createdAt'], now.toIso8601String());
    });

    test('fromJson parses ISO date strings', () {
      final json = {
        'uid': 'test-uid',
        'email': 'test@example.com',
        'name': 'Test User',
        'role': 'senior',
        'createdAt': '2025-06-15T10:30:00.000',
      };

      final user = AppUser.fromJson(json);

      expect(user.createdAt, DateTime(2025, 6, 15, 10, 30));
    });

    test('toJson/fromJson round-trip preserves data', () {
      const original = AppUser(
        uid: 'test-uid',
        email: 'test@example.com',
        name: 'Test User',
        role: 'family',
        phone: '+1234567890',
      );

      final json = original.toJson();
      final restored = AppUser.fromJson(json);

      expect(restored.uid, original.uid);
      expect(restored.email, original.email);
      expect(restored.name, original.name);
      expect(restored.role, original.role);
      expect(restored.phone, original.phone);
    });
  });

  group('AppUser copyWith', () {
    test('should create new instance with updated fields', () {
      const user = AppUser(
        uid: 'test-uid',
        email: 'test@example.com',
        name: 'Original Name',
        role: 'senior',
      );

      final updated = user.copyWith(name: 'Updated Name', phone: '+9876543210');

      expect(updated.uid, user.uid);
      expect(updated.email, user.email);
      expect(updated.name, 'Updated Name');
      expect(updated.phone, '+9876543210');
      expect(user.name, 'Original Name'); // Original unchanged
    });

    test('copyWith updates approval status', () {
      const user = AppUser(
        uid: 'test-uid',
        email: 'test@example.com',
        name: 'Test',
        role: 'senior',
        approvalStatus: ApprovalStatus.pending,
      );

      final approved = user.copyWith(
        approvalStatus: ApprovalStatus.approved,
        approvedBy: 'admin-1',
        approvedAt: DateTime.now(),
      );

      expect(approved.approvalStatus, ApprovalStatus.approved);
      expect(approved.approvedBy, 'admin-1');
      expect(approved.approvedAt, isNotNull);
    });

    test('copyWith updates list fields', () {
      const user = AppUser(
        uid: 'test-uid',
        email: 'test@example.com',
        name: 'Test',
        role: 'senior',
      );

      final withFamily = user.copyWith(linkedFamily: ['f1', 'f2']);

      expect(withFamily.linkedFamily, ['f1', 'f2']);
      expect(user.linkedFamily, isNull); // Original unchanged
    });
  });

  group('ApprovalStatus enum', () {
    test('should have 3 values', () {
      expect(ApprovalStatus.values.length, 3);
    });

    test('should contain expected values', () {
      expect(ApprovalStatus.values, contains(ApprovalStatus.pending));
      expect(ApprovalStatus.values, contains(ApprovalStatus.approved));
      expect(ApprovalStatus.values, contains(ApprovalStatus.rejected));
    });
  });

  group('AuthState Tests', () {
    test('AuthState.initial has correct defaults', () {
      final state = AuthState.initial();
      expect(state.isLoading, false);
      expect(state.isAuthenticated, false);
      expect(state.user, isNull);
      expect(state.errorMessage, isNull);
    });

    test('AuthState.loading sets isLoading true', () {
      final state = AuthState.loading();
      expect(state.isLoading, true);
      expect(state.isAuthenticated, false);
      expect(state.user, isNull);
    });

    test('AuthState.authenticated stores user', () {
      const user = AppUser(
        uid: 'test-uid',
        email: 'test@example.com',
        name: 'Test User',
        role: 'senior',
      );
      final state = AuthState.authenticated(user);
      expect(state.isAuthenticated, true);
      expect(state.isLoading, false);
      expect(state.user, user);
      expect(state.user?.uid, 'test-uid');
    });

    test('AuthState.error stores error message', () {
      final state = AuthState.error('Invalid credentials');
      expect(state.errorMessage, 'Invalid credentials');
      expect(state.isAuthenticated, false);
      expect(state.isLoading, false);
    });

    test('AuthState.copyWith updates specified fields', () {
      const user = AppUser(
        uid: 'test-uid',
        email: 'test@example.com',
        name: 'Test User',
        role: 'senior',
      );
      final original = AuthState.authenticated(user);
      final updated = original.copyWith(isLoading: true);
      expect(updated.isLoading, true);
      expect(updated.isAuthenticated, true);
      expect(updated.user?.uid, 'test-uid');
    });

    test('AuthState.copyWith clears errorMessage', () {
      final state = AuthState.error('some error');
      final cleared = state.copyWith(errorMessage: null);
      expect(cleared.errorMessage, isNull);
    });
  });

  group('AppUser Edge Cases', () {
    test('fromMap with completely empty map returns safe defaults', () {
      final user = AppUser.fromMap(<String, dynamic>{});
      expect(user.uid, '');
      expect(user.email, '');
      expect(user.name, '');
      expect(user.role, isNotEmpty); // has a default
      expect(user.approvalStatus, ApprovalStatus.pending);
      expect(user.isSenior || user.isCaregiver || user.isFamily || user.isAdmin, true);
    });

    test('fromMap handles invalid approvalStatus string', () {
      final map = {
        'uid': '1',
        'email': 'a@b.com',
        'name': 'A',
        'role': 'senior',
        'approvalStatus': 'invalid_status',
      };
      final user = AppUser.fromMap(map);
      expect(user.approvalStatus, ApprovalStatus.pending);
    });

    test('toMap includes approvalStatus as string', () {
      const user = AppUser(
        uid: 'u1',
        email: 'a@b.com',
        name: 'Test',
        role: 'senior',
        approvalStatus: ApprovalStatus.rejected,
      );
      final map = user.toMap();
      expect(map['approvalStatus'], 'rejected');
    });

    test('fromMap handles list fields with dynamic types', () {
      final map = {
        'uid': '1',
        'email': 'a@b.com',
        'name': 'A',
        'role': 'senior',
        'linkedFamily': <dynamic>['f1', 'f2'],
        'assignedSeniors': <dynamic>['s1'],
        'assignedCaregivers': <dynamic>['c1', 'c2', 'c3'],
      };
      final user = AppUser.fromMap(map);
      expect(user.linkedFamily, hasLength(2));
      expect(user.assignedSeniors, hasLength(1));
      expect(user.assignedCaregivers, hasLength(3));
    });

    test('copyWith preserves all fields when no args given', () {
      final now = DateTime.now();
      final user = AppUser(
        uid: 'u1',
        email: 'test@test.com',
        name: 'Tester',
        role: 'caregiver',
        phone: '+123',
        address: '456 St',
        createdAt: now,
        approvalStatus: ApprovalStatus.approved,
        assignedSeniors: ['s1'],
      );
      final copy = user.copyWith();
      expect(copy.uid, user.uid);
      expect(copy.email, user.email);
      expect(copy.name, user.name);
      expect(copy.role, user.role);
      expect(copy.phone, user.phone);
      expect(copy.address, user.address);
      expect(copy.approvalStatus, user.approvalStatus);
      expect(copy.assignedSeniors, user.assignedSeniors);
    });

    test('toJson/fromJson round-trip preserves all date fields', () {
      final now = DateTime(2025, 6, 15, 10, 30);
      final user = AppUser(
        uid: 'u1',
        email: 'test@test.com',
        name: 'Tester',
        role: 'senior',
        createdAt: now,
        lastActiveAt: now,
        lastLogin: now,
        approvedAt: now,
      );
      final json = user.toJson();
      final restored = AppUser.fromJson(json);
      expect(restored.createdAt, now);
      expect(restored.lastActiveAt, now);
      expect(restored.lastLogin, now);
      expect(restored.approvedAt, now);
    });

    test('multiple role checks are mutually exclusive', () {
      const roles = ['senior', 'caregiver', 'family', 'admin'];
      for (final role in roles) {
        final user = AppUser(uid: '1', email: 'a@b.com', name: 'A', role: role);
        final checks = [user.isSenior, user.isCaregiver, user.isFamily, user.isAdmin];
        expect(checks.where((v) => v).length, 1, reason: '$role should have exactly one true role check');
      }
    });
  });
}
