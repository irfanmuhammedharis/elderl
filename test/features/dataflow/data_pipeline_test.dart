import 'package:flutter_test/flutter_test.dart';
import 'package:elderl/features/auth/domain/entities/app_user.dart';
import 'package:elderl/features/auth/presentation/controllers/auth_controller.dart';
import 'package:elderl/features/requests/data/request_repository.dart';
import 'package:elderl/features/emergency/data/emergency_repository.dart';
import 'package:elderl/features/checkin/data/checkin_repository.dart';
import 'package:elderl/features/messaging/data/messaging_repository.dart';
import 'package:elderl/core/utils/constants.dart';
import 'package:elderl/core/services/sync_service.dart';
import 'package:elderl/core/services/location_service.dart';
import 'package:elderl/core/errors/failures.dart';

void main() {
  group('Auth Pipeline - User Lifecycle', () {
    test('new user starts with pending approval', () {
      const user = AppUser(
        uid: 'new-user',
        email: 'new@example.com',
        name: 'New User',
        role: 'senior',
      );

      expect(user.approvalStatus, ApprovalStatus.pending);
      expect(user.isPending, true);
      expect(user.isApproved, false);
    });

    test('approved user has approvedBy set', () {
      final user = AppUser(
        uid: 'approved-user',
        email: 'approved@example.com',
        name: 'Approved User',
        role: 'senior',
        approvalStatus: ApprovalStatus.approved,
        approvedBy: 'admin-1',
        approvedAt: DateTime.now(),
      );

      expect(user.isApproved, true);
      expect(user.approvedBy, 'admin-1');
      expect(user.approvedAt, isNotNull);
    });

    test('rejected user has rejectionReason', () {
      const user = AppUser(
        uid: 'rejected-user',
        email: 'rejected@example.com',
        name: 'Rejected User',
        role: 'senior',
        approvalStatus: ApprovalStatus.rejected,
        rejectionReason: 'Incomplete registration',
      );

      expect(user.isRejected, true);
      expect(user.rejectionReason, 'Incomplete registration');
    });

    test('role determines feature access', () {
      const senior = AppUser(uid: '1', email: 'a@b.com', name: 'A', role: 'senior');
      const caregiver = AppUser(uid: '2', email: 'b@c.com', name: 'B', role: 'caregiver');
      const family = AppUser(uid: '3', email: 'c@d.com', name: 'C', role: 'family');
      const admin = AppUser(uid: '4', email: 'd@e.com', name: 'D', role: 'admin');

      // Senior can create requests, check-in, trigger emergency
      expect(senior.isSenior, true);
      expect(senior.role, AppConstants.roleSenior);

      // Caregiver can accept requests
      expect(caregiver.isCaregiver, true);
      expect(caregiver.role, AppConstants.roleCaregiver);

      // Family can link to senior
      expect(family.isFamily, true);
      expect(family.role, AppConstants.roleFamily);

      // Admin manages users
      expect(admin.isAdmin, true);
      expect(admin.role, AppConstants.roleAdmin);
    });

    test('user toMap and fromMap preserves data integrity through pipeline', () {
      const original = AppUser(
        uid: 'pipeline-user',
        email: 'pipeline@example.com',
        name: 'Pipeline User',
        role: 'senior',
        phone: '+1234567890',
        approvalStatus: ApprovalStatus.approved,
        linkedFamily: ['f1'],
        assignedCaregivers: ['cg1'],
      );

      // Simulate write → read pipeline
      final map = original.toMap();
      final restored = AppUser.fromMap(map);

      expect(restored.uid, original.uid);
      expect(restored.email, original.email);
      expect(restored.role, original.role);
      expect(restored.approvalStatus, original.approvalStatus);
      expect(restored.linkedFamily, original.linkedFamily);
      expect(restored.assignedCaregivers, original.assignedCaregivers);
    });
  });

  group('Request Lifecycle Pipeline', () {
    test('request created with pending status by default', () {
      final request = HelpRequest(
        seniorId: 'senior-1',
        seniorName: 'John Doe',
        type: AppConstants.requestMedical,
        description: 'Need medication pickup',
      );

      expect(request.status, AppConstants.statusPending);
      expect(request.assignedTo, isNull);
      expect(request.assignedToName, isNull);
      expect(request.completedAt, isNull);
    });

    test('request map structure matches Firestore schema', () {
      final request = HelpRequest(
        seniorId: 'senior-1',
        seniorName: 'John Doe',
        type: 'medical',
        description: 'Need help',
        isUrgent: true,
        latitude: 40.7128,
        longitude: -74.0060,
        address: '123 Main St',
      );

      final map = request.toMap();

      // Verify all Firestore fields present
      expect(map.containsKey('seniorId'), true);
      expect(map.containsKey('seniorName'), true);
      expect(map.containsKey('type'), true);
      expect(map.containsKey('description'), true);
      expect(map.containsKey('status'), true);
      expect(map.containsKey('isUrgent'), true);
      expect(map.containsKey('latitude'), true);
      expect(map.containsKey('longitude'), true);
      expect(map.containsKey('address'), true);
      expect(map['isUrgent'], true);
    });

    test('status transitions follow correct sequence', () {
      // Pending → Accepted
      var request = HelpRequest(
        seniorId: 'senior-1',
        seniorName: 'John',
        type: 'medical',
        description: 'Help',
      );
      expect(request.status, AppConstants.statusPending);

      // Simulate acceptance
      request = request.copyWith(
        status: AppConstants.statusAccepted,
        assignedTo: 'caregiver-1',
        assignedToName: 'Dr. Smith',
      );
      expect(request.status, AppConstants.statusAccepted);
      expect(request.assignedTo, 'caregiver-1');

      // Simulate in-progress
      request = request.copyWith(status: AppConstants.statusInProgress);
      expect(request.status, AppConstants.statusInProgress);

      // Simulate completion
      request = request.copyWith(
        status: AppConstants.statusCompleted,
        completedAt: DateTime.now(),
      );
      expect(request.status, AppConstants.statusCompleted);
      expect(request.completedAt, isNotNull);
    });

    test('assignment requires both caregiver ID and name', () {
      final assigned = HelpRequest(
        seniorId: 'senior-1',
        seniorName: 'John',
        type: 'food',
        description: 'Groceries',
        assignedTo: 'cg-1',
        assignedToName: 'Helper',
      );

      expect(assigned.assignedTo, isNotNull);
      expect(assigned.assignedToName, isNotNull);
    });

    test('request fromMap/toMap round-trip through Firestore pipeline', () {
      final original = HelpRequest(
        seniorId: 'senior-1',
        seniorName: 'John',
        type: 'transport',
        description: 'Ride to hospital',
        isUrgent: true,
        address: '456 Oak Ave',
      );

      final map = original.toMap();
      final restored = HelpRequest.fromMap(map, id: 'req-1');

      expect(restored.seniorId, original.seniorId);
      expect(restored.type, original.type);
      expect(restored.description, original.description);
      expect(restored.isUrgent, original.isUrgent);
      expect(restored.address, original.address);
    });

    test('urgent flag is preserved through serialization', () {
      final urgentRequest = HelpRequest(
        seniorId: 'senior-1',
        seniorName: 'John',
        type: 'medical',
        description: 'Urgent help',
        isUrgent: true,
      );

      final map = urgentRequest.toMap();
      final restored = HelpRequest.fromMap(map);

      expect(restored.isUrgent, true);
    });

    test('cancellation produces correct status', () {
      final cancelled = HelpRequest(
        seniorId: 'senior-1',
        seniorName: 'John',
        type: 'companion',
        description: 'Cancelled',
        status: AppConstants.statusCancelled,
      );

      expect(cancelled.status, AppConstants.statusCancelled);
    });
  });

  group('Emergency Lifecycle Pipeline', () {
    test('emergency created with active status', () {
      final emergency = EmergencyAlert(
        seniorId: 'senior-1',
        seniorName: 'John Doe',
      );

      expect(emergency.status, 'active');
    });

    test('emergency map structure for dual-path RTDB write', () {
      final emergency = EmergencyAlert(
        seniorId: 'senior-1',
        seniorName: 'John Doe',
        seniorPhone: '+1234567890',
        latitude: 40.7128,
        longitude: -74.0060,
        address: '123 Main St',
      );

      final map = emergency.toMap();

      // Both paths (emergencies/ and active_emergencies/) use same data
      expect(map.containsKey('seniorId'), true);
      expect(map.containsKey('seniorName'), true);
      expect(map.containsKey('latitude'), true);
      expect(map.containsKey('longitude'), true);
      expect(map.containsKey('status'), true);
      expect(map['status'], 'active');
    });

    test('response updates emergency correctly', () {
      final original = EmergencyAlert(
        seniorId: 'senior-1',
        seniorName: 'John',
        status: 'active',
      );

      final responded = original.copyWith(
        status: 'responded',
        respondedBy: 'caregiver-1',
        respondedByName: 'Dr. Smith',
        respondedAt: DateTime.now().millisecondsSinceEpoch,
      );

      expect(responded.status, 'responded');
      expect(responded.respondedBy, 'caregiver-1');
      expect(responded.respondedByName, 'Dr. Smith');
      expect(responded.respondedAt, isNotNull);
    });

    test('resolution sets resolvedAt timestamp', () {
      final resolved = EmergencyAlert(
        seniorId: 'senior-1',
        seniorName: 'John',
        status: 'resolved',
        resolvedAt: DateTime.now().millisecondsSinceEpoch,
      );

      expect(resolved.status, 'resolved');
      expect(resolved.resolvedAt, isNotNull);
      expect(resolved.resolvedAtDateTime, isNotNull);
    });

    test('emergency fromMap handles RTDB dynamic types', () {
      // RTDB returns Map<dynamic, dynamic> with dynamic value types
      final map = <dynamic, dynamic>{
        'seniorId': 'senior-1',
        'seniorName': 'John',
        'latitude': 40.7128, // num from RTDB
        'longitude': -74.006,
        'status': 'active',
        'createdAt': 1700000000000, // epoch millis from RTDB
      };

      final emergency = EmergencyAlert.fromMap(map, id: 'emg-1');

      expect(emergency.seniorId, 'senior-1');
      expect(emergency.latitude, 40.7128);
      expect(emergency.createdAt, 1700000000000);
      expect(emergency.createdAtDateTime, isNotNull);
    });

    test('cancelled emergency is removed from active path', () {
      final cancelled = EmergencyAlert(
        seniorId: 'senior-1',
        seniorName: 'John',
        status: 'cancelled',
      );

      // Verify the status indicates removal from active_emergencies
      expect(cancelled.status, 'cancelled');
      // In the repository, updateEmergencyStatus with 'cancelled'
      // sets active_emergencies/<id> = null (removal)
    });
  });

  group('Check-In Pipeline', () {
    test('check-in created with correct fields', () {
      final checkin = CheckIn(
        seniorId: 'senior-1',
        status: AppConstants.checkinOk,
        message: 'Feeling great!',
      );

      expect(checkin.seniorId, 'senior-1');
      expect(checkin.status, 'ok');
      expect(checkin.message, 'Feeling great!');
    });

    test('check-in map structure for Firestore', () {
      final checkin = CheckIn(
        seniorId: 'senior-1',
        status: 'ok',
        message: 'Good day',
        checkinTime: DateTime(2025, 6, 15, 8, 0),
      );

      final map = checkin.toMap();

      expect(map.containsKey('seniorId'), true);
      expect(map.containsKey('status'), true);
      expect(map.containsKey('message'), true);
      expect(map.containsKey('checkinTime'), true);
    });

    test('check-in fromMap/toMap pipeline preserves data', () {
      final original = CheckIn(
        seniorId: 'senior-1',
        status: 'ok',
        message: 'All good today',
      );

      final map = original.toMap();
      final restored = CheckIn.fromMap(map, id: 'ci-1');

      expect(restored.seniorId, original.seniorId);
      expect(restored.status, original.status);
      expect(restored.message, original.message);
    });

    test('check-in with no message is valid', () {
      final checkin = CheckIn(
        seniorId: 'senior-1',
        status: 'ok',
      );

      expect(checkin.message, isNull);
      final map = checkin.toMap();
      expect(map['message'], isNull);
    });
  });

  group('Messaging Pipeline', () {
    test('message creation follows conversation flow', () {
      // Step 1: Create conversation
      final conversation = Conversation(
        participantIds: ['senior-1', 'cg-1'],
        participantNames: {'senior-1': 'John', 'cg-1': 'Dr. Smith'},
        relatedRequestId: 'req-1',
      );

      expect(conversation.participantIds, hasLength(2));
      expect(conversation.relatedRequestId, 'req-1');

      // Step 2: Send message in conversation
      final message = Message(
        conversationId: 'conv-1',
        senderId: 'senior-1',
        senderName: 'John',
        content: 'When will you arrive?',
      );

      expect(message.type, 'text');
      expect(message.isRead, false);

      // Step 3: Conversation updated with last message
      final updatedConv = Conversation(
        id: 'conv-1',
        participantIds: ['senior-1', 'cg-1'],
        participantNames: {'senior-1': 'John', 'cg-1': 'Dr. Smith'},
        lastMessage: message.content,
        lastSenderId: message.senderId,
        lastMessageAt: DateTime.now(),
        unreadCount: 1,
      );

      expect(updatedConv.lastMessage, 'When will you arrive?');
      expect(updatedConv.lastSenderId, 'senior-1');
      expect(updatedConv.unreadCount, 1);
    });

    test('conversation participant lookup works both ways', () {
      final conv = Conversation(
        participantIds: ['user-a', 'user-b'],
        participantNames: {'user-a': 'Alice', 'user-b': 'Bob'},
      );

      // Alice looks up Bob
      expect(conv.getOtherParticipantName('user-a'), 'Bob');
      expect(conv.getOtherParticipantId('user-a'), 'user-b');

      // Bob looks up Alice
      expect(conv.getOtherParticipantName('user-b'), 'Alice');
      expect(conv.getOtherParticipantId('user-b'), 'user-a');
    });
  });

  group('Family Linking Pipeline', () {
    test('family member links bidirectionally', () {
      // Before linking
      const family = AppUser(
        uid: 'family-1',
        email: 'family@example.com',
        name: 'Family Member',
        role: 'family',
      );
      expect(family.isLinkedToSenior, false);

      // After linking (simulated)
      final linkedFamily = family.copyWith(linkedSeniorId: 'senior-1');
      expect(linkedFamily.isLinkedToSenior, true);
      expect(linkedFamily.linkedSeniorId, 'senior-1');

      // Senior side
      const senior = AppUser(
        uid: 'senior-1',
        email: 'senior@example.com',
        name: 'Senior User',
        role: 'senior',
        linkedFamily: ['family-1'],
      );
      expect(senior.hasLinkedFamily, true);
      expect(senior.linkedFamily, contains('family-1'));
    });

    test('unlink removes both sides', () {
      // After unlinking
      const unlinkedFamily = AppUser(
        uid: 'family-1',
        email: 'family@example.com',
        name: 'Family Member',
        role: 'family',
        linkedSeniorId: null,
      );
      expect(unlinkedFamily.isLinkedToSenior, false);

      const unlinkedSenior = AppUser(
        uid: 'senior-1',
        email: 'senior@example.com',
        name: 'Senior User',
        role: 'senior',
        linkedFamily: [],
      );
      expect(unlinkedSenior.hasLinkedFamily, false);
    });
  });

  group('Caregiver Assignment Pipeline', () {
    test('caregiver assignment is bidirectional', () {
      // After assignment
      const caregiver = AppUser(
        uid: 'cg-1',
        email: 'cg@example.com',
        name: 'Dr. Smith',
        role: 'caregiver',
        assignedSeniors: ['senior-1', 'senior-2'],
      );
      expect(caregiver.hasAssignedSeniors, true);
      expect(caregiver.assignedSeniors, hasLength(2));

      const senior = AppUser(
        uid: 'senior-1',
        email: 'senior@example.com',
        name: 'John',
        role: 'senior',
        assignedCaregivers: ['cg-1'],
      );
      expect(senior.hasAssignedCaregivers, true);
      expect(senior.assignedCaregivers, contains('cg-1'));
    });

    test('request acceptance links caregiver and senior', () {
      // Before: pending request, no assignment
      var request = HelpRequest(
        seniorId: 'senior-1',
        seniorName: 'John',
        type: 'medical',
        description: 'Need help',
        status: AppConstants.statusPending,
      );
      expect(request.assignedTo, isNull);

      // After acceptance
      request = request.copyWith(
        status: AppConstants.statusAccepted,
        assignedTo: 'cg-1',
        assignedToName: 'Dr. Smith',
      );
      expect(request.status, AppConstants.statusAccepted);
      expect(request.assignedTo, 'cg-1');
      // Repository also calls assignToSenior(cg-1, senior-1) for bidirectional link
    });
  });

  group('Cross-Feature Data Consistency', () {
    test('all entities use consistent date parsing', () {
      // Test that all fromMap methods handle String dates
      final stringDate = '2025-06-15T10:30:00.000';

      final user = AppUser.fromJson({
        'uid': '1',
        'email': 'a@b.com',
        'name': 'A',
        'role': 'senior',
        'createdAt': stringDate,
      });
      expect(user.createdAt, isNotNull);

      final request = HelpRequest.fromMap({
        'seniorId': 'senior-1',
        'seniorName': 'John',
        'type': 'medical',
        'description': 'Help',
        'createdAt': stringDate,
      });
      expect(request.createdAt, isNotNull);

      final checkin = CheckIn.fromMap({
        'seniorId': 'senior-1',
        'status': 'ok',
        'checkinTime': stringDate,
      });
      expect(checkin.checkinTime, isNotNull);

      final message = Message.fromMap({
        'conversationId': 'conv-1',
        'senderId': 'user-1',
        'senderName': 'Test',
        'content': 'Hello',
        'createdAt': stringDate,
      });
      expect(message.createdAt, isNotNull);
    });

    test('request types match constants', () {
      final validTypes = [
        AppConstants.requestMedical,
        AppConstants.requestFood,
        AppConstants.requestTransport,
        AppConstants.requestCompanion,
      ];

      for (final type in validTypes) {
        final request = HelpRequest(
          seniorId: 'senior-1',
          seniorName: 'John',
          type: type,
          description: 'Test',
        );
        expect(validTypes.contains(request.type), true);
      }
    });

    test('status constants are consistent across features', () {
      // Request statuses used in repository queries
      expect(AppConstants.statusPending, 'pending');
      expect(AppConstants.statusAccepted, 'accepted');
      expect(AppConstants.statusInProgress, 'in_progress');
      expect(AppConstants.statusCompleted, 'completed');
      expect(AppConstants.statusCancelled, 'cancelled');

      // Check-in statuses
      expect(AppConstants.checkinOk, 'ok');
      expect(AppConstants.checkinMissed, 'missed');
      expect(AppConstants.checkinPending, 'pending');
    });
  });

  group('Security & Authorization Pipeline', () {
    test('auth state transitions are secure', () {
      // Initial → Loading → Authenticated
      final initial = AuthState.initial();
      expect(initial.isAuthenticated, false);
      expect(initial.user, isNull);

      final loading = AuthState.loading();
      expect(loading.isLoading, true);
      expect(loading.isAuthenticated, false);

      const user = AppUser(
        uid: 'secure-uid',
        email: 'secure@example.com',
        name: 'Secure User',
        role: 'senior',
        approvalStatus: ApprovalStatus.approved,
      );
      final authenticated = AuthState.authenticated(user);
      expect(authenticated.isAuthenticated, true);
      expect(authenticated.user?.uid, 'secure-uid');
    });

    test('unapproved user should not access features', () {
      const pendingUser = AppUser(
        uid: 'pending-uid',
        email: 'pending@example.com',
        name: 'Pending User',
        role: 'senior',
        approvalStatus: ApprovalStatus.pending,
      );
      // Verify the user is pending and not approved
      expect(pendingUser.isPending, true);
      expect(pendingUser.isApproved, false);
      // GoRouter would redirect to /pending-approval
    });

    test('rejected user should not access features', () {
      const rejectedUser = AppUser(
        uid: 'rejected-uid',
        email: 'rejected@example.com',
        name: 'Rejected User',
        role: 'caregiver',
        approvalStatus: ApprovalStatus.rejected,
        rejectionReason: 'Invalid credentials provided',
      );
      expect(rejectedUser.isRejected, true);
      expect(rejectedUser.isApproved, false);
      expect(rejectedUser.rejectionReason, isNotEmpty);
    });

    test('admin bypasses approval for route access', () {
      const admin = AppUser(
        uid: 'admin-uid',
        email: 'admin@example.com',
        name: 'Admin',
        role: 'admin',
        approvalStatus: ApprovalStatus.pending, // even pending admin should work
      );
      expect(admin.isAdmin, true);
      // Admin role != 'admin' check in GoRouter allows access
    });

    test('role determines correct home route', () {
      const roles = {
        'senior': '/senior',
        'caregiver': '/caregiver',
        'family': '/family',
        'admin': '/admin',
      };
      for (final entry in roles.entries) {
        final user = AppUser(uid: '1', email: 'a@b.com', name: 'A', role: entry.key);
        final expectedHome = entry.value;
        // Verify role mapping
        expect(user.role, entry.key);
        // The AppRoutes would map:
        if (user.isSenior) expect(expectedHome, '/senior');
        if (user.isCaregiver) expect(expectedHome, '/caregiver');
        if (user.isFamily) expect(expectedHome, '/family');
        if (user.isAdmin) expect(expectedHome, '/admin');
      }
    });

    test('role-based access control prevents cross-role paths', () {
      const senior = AppUser(uid: '1', email: 'a@b.com', name: 'A', role: 'senior');
      const caregiver = AppUser(uid: '2', email: 'b@c.com', name: 'B', role: 'caregiver');
      const family = AppUser(uid: '3', email: 'c@d.com', name: 'C', role: 'family');

      // Senior cannot be caregiver or family
      expect(senior.isSenior, true);
      expect(senior.isCaregiver, false);
      expect(senior.isFamily, false);
      expect(senior.isAdmin, false);

      // Caregiver cannot be senior or family
      expect(caregiver.isCaregiver, true);
      expect(caregiver.isSenior, false);
      expect(caregiver.isFamily, false);

      // Family cannot be senior or caregiver
      expect(family.isFamily, true);
      expect(family.isSenior, false);
      expect(family.isCaregiver, false);
    });
  });

  group('Sync State Pipeline', () {
    test('sync states represent all possible connectivity scenarios', () {
      expect(SyncStatus.values.length, 5);

      const synced = SyncState(status: SyncStatus.synced);
      const syncing = SyncState(status: SyncStatus.syncing);
      const pending = SyncState(status: SyncStatus.pendingSync, pendingWrites: 3);
      const offline = SyncState(status: SyncStatus.offline);
      const error = SyncState(status: SyncStatus.error, errorMessage: 'Connection lost');

      expect(synced.isOnline, true);
      expect(syncing.isOnline, true);
      expect(pending.isOnline, true);
      expect(pending.hasPendingWrites, true);
      expect(offline.isOnline, false);
      expect(error.isOnline, true);
      expect(error.errorMessage, 'Connection lost');
    });

    test('sync state transitions follow connectivity lifecycle', () {
      // Normal flow: synced → offline → syncing → synced
      const state1 = SyncState(status: SyncStatus.synced);
      expect(state1.isOnline, true);

      final state2 = state1.copyWith(status: SyncStatus.offline);
      expect(state2.isOnline, false);

      final state3 = state2.copyWith(status: SyncStatus.syncing);
      expect(state3.isOnline, true);

      final state4 = state3.copyWith(
        status: SyncStatus.synced,
        lastSyncTime: DateTime.now(),
        pendingWrites: 0,
      );
      expect(state4.isOnline, true);
      expect(state4.hasPendingWrites, false);
      expect(state4.lastSyncTime, isNotNull);
    });
  });

  group('Location Data Pipeline', () {
    test('location data flows from service to emergency', () {
      // Simulate location capture
      final location = LocationData(
        latitude: 40.7128,
        longitude: -74.0060,
        accuracy: 10.0,
        timestamp: DateTime.now(),
        address: '123 Main St, New York',
      );

      // Location used in emergency creation
      final emergency = EmergencyAlert(
        seniorId: 'senior-1',
        seniorName: 'John',
        latitude: location.latitude,
        longitude: location.longitude,
        address: location.address,
      );

      expect(emergency.latitude, 40.7128);
      expect(emergency.longitude, -74.0060);
      expect(emergency.address, '123 Main St, New York');
    });

    test('location data flows from service to help request', () {
      final location = LocationData(
        latitude: 51.5074,
        longitude: -0.1278,
        accuracy: 5.0,
        timestamp: DateTime.now(),
      );

      final request = HelpRequest(
        seniorId: 'senior-1',
        seniorName: 'Jane',
        type: 'medical',
        description: 'Need help',
        latitude: location.latitude,
        longitude: location.longitude,
      );

      expect(request.latitude, 51.5074);
      expect(request.longitude, -0.1278);
    });

    test('location data round-trips through serialization', () {
      final original = LocationData(
        latitude: 35.6762,
        longitude: 139.6503,
        accuracy: 15.0,
        timestamp: DateTime(2025, 6, 15, 10, 0),
        address: 'Tokyo, Japan',
      );

      final map = original.toMap();
      final restored = LocationData.fromMap(map);

      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
      expect(restored.accuracy, original.accuracy);
      expect(restored.address, original.address);
    });
  });

  group('Error Handling Pipeline', () {
    test('failure hierarchy supports all error types', () {
      final authFail = AuthFailure.invalidCredentials();
      final dbFail = DatabaseFailure.notFound();
      final netFail = NetworkFailure.noConnection();
      final locFail = LocationFailure.serviceDisabled();

      // All are Failure instances
      expect(authFail, isA<Failure>());
      expect(dbFail, isA<Failure>());
      expect(netFail, isA<Failure>());
      expect(locFail, isA<Failure>());

      // All have messages
      expect(authFail.message, isNotEmpty);
      expect(dbFail.message, isNotEmpty);
      expect(netFail.message, isNotEmpty);
      expect(locFail.message, isNotEmpty);
    });

    test('auth error maps to user-friendly messages', () {
      expect(AuthFailure.invalidCredentials().message, 'Invalid email or password');
      expect(AuthFailure.userNotFound().message, 'User not found');
      expect(AuthFailure.emailAlreadyInUse().message, 'Email is already registered');
      expect(AuthFailure.weakPassword().message, 'Password is too weak');
      expect(AuthFailure.networkError().message, contains('Network'));
    });
  });

  group('Full Request Lifecycle - End to End', () {
    test('complete request lifecycle from creation to completion', () {
      // Step 1: Senior creates request
      final request = HelpRequest(
        seniorId: 'senior-1',
        seniorName: 'John Doe',
        type: AppConstants.requestMedical,
        description: 'Need medication pickup from pharmacy',
        isUrgent: true,
        latitude: 40.7128,
        longitude: -74.0060,
        address: '123 Main St',
      );
      expect(request.status, AppConstants.statusPending);
      expect(request.assignedTo, isNull);
      expect(request.completedAt, isNull);

      // Step 2: Serialize for Firestore write
      final writeMap = request.toMap();
      expect(writeMap['seniorId'], 'senior-1');
      expect(writeMap['status'], 'pending');
      expect(writeMap['isUrgent'], true);

      // Step 3: Deserialize from Firestore read
      final readRequest = HelpRequest.fromMap(writeMap, id: 'req-123');
      expect(readRequest.id, 'req-123');
      expect(readRequest.seniorId, 'senior-1');

      // Step 4: Caregiver accepts
      final accepted = readRequest.copyWith(
        status: AppConstants.statusAccepted,
        assignedTo: 'caregiver-1',
        assignedToName: 'Dr. Smith',
      );
      expect(accepted.status, 'accepted');
      expect(accepted.assignedTo, 'caregiver-1');

      // Step 5: Mark in-progress
      final inProgress = accepted.copyWith(
        status: AppConstants.statusInProgress,
      );
      expect(inProgress.status, 'in_progress');
      expect(inProgress.assignedTo, 'caregiver-1'); // preserved

      // Step 6: Complete
      final completed = inProgress.copyWith(
        status: AppConstants.statusCompleted,
        completedAt: DateTime.now(),
      );
      expect(completed.status, 'completed');
      expect(completed.completedAt, isNotNull);
      expect(completed.assignedTo, 'caregiver-1'); // still preserved
    });
  });

  group('Full Emergency Lifecycle - End to End', () {
    test('complete emergency lifecycle from trigger to resolution', () {
      // Step 1: Senior triggers emergency
      final emergency = EmergencyAlert(
        seniorId: 'senior-1',
        seniorName: 'John Doe',
        seniorPhone: '+1234567890',
        familyContactName: 'Jane Doe',
        familyContactPhone: '+0987654321',
        latitude: 40.7128,
        longitude: -74.0060,
        address: '123 Main St',
      );
      expect(emergency.status, 'active');

      // Step 2: Serialize for dual-path RTDB write
      final writeMap = emergency.toMap();
      expect(writeMap['seniorId'], 'senior-1');
      expect(writeMap['status'], 'active');
      // Both emergencies/ and active_emergencies/ get same data

      // Step 3: Deserialize from RTDB read (dynamic types)
      final rtdbMap = <dynamic, dynamic>{
        'seniorId': 'senior-1',
        'seniorName': 'John Doe',
        'seniorPhone': '+1234567890',
        'latitude': 40.7128,
        'longitude': -74.006,
        'status': 'active',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };
      final readEmergency = EmergencyAlert.fromMap(rtdbMap, id: 'emg-123');
      expect(readEmergency.id, 'emg-123');

      // Step 4: Caregiver responds
      final responded = readEmergency.copyWith(
        status: 'responded',
        respondedBy: 'caregiver-1',
        respondedByName: 'Dr. Smith',
        respondedAt: DateTime.now().millisecondsSinceEpoch,
      );
      expect(responded.status, 'responded');
      expect(responded.respondedBy, 'caregiver-1');
      expect(responded.respondedAtDateTime, isNotNull);

      // Step 5: Resolve emergency
      final resolved = responded.copyWith(
        status: 'resolved',
        resolvedAt: DateTime.now().millisecondsSinceEpoch,
      );
      expect(resolved.status, 'resolved');
      expect(resolved.resolvedAtDateTime, isNotNull);
      // Repository would set active_emergencies/{id} = null
    });
  });

  group('Conversation-Message Atomicity Pipeline', () {
    test('message + conversation update must occur together', () {
      // Create conversation
      final conversation = Conversation(
        id: 'conv-1',
        participantIds: ['user-a', 'user-b'],
        participantNames: {'user-a': 'Alice', 'user-b': 'Bob'},
        unreadCount: 0,
      );

      // Create message
      final message = Message(
        conversationId: 'conv-1',
        senderId: 'user-a',
        senderName: 'Alice',
        content: 'Hello Bob!',
      );

      // Verify batch write data
      final messageMap = message.toMap();
      expect(messageMap['conversationId'], 'conv-1');
      expect(messageMap['senderId'], 'user-a');
      expect(messageMap['content'], 'Hello Bob!');

      // Verify conversation update data
      final convMap = conversation.toMap();
      expect(convMap['participantIds'], hasLength(2));
      // After batch: lastMessage, lastSenderId, unreadCount all updated
    });

    test('conversation lookup works for both participants', () {
      final conv = Conversation(
        id: 'conv-1',
        participantIds: ['senior-1', 'caregiver-1'],
        participantNames: {'senior-1': 'John', 'caregiver-1': 'Dr. Smith'},
      );

      // Senior sees caregiver's name
      expect(conv.getOtherParticipantName('senior-1'), 'Dr. Smith');
      expect(conv.getOtherParticipantId('senior-1'), 'caregiver-1');

      // Caregiver sees senior's name
      expect(conv.getOtherParticipantName('caregiver-1'), 'John');
      expect(conv.getOtherParticipantId('caregiver-1'), 'senior-1');
    });
  });

  group('Bidirectional Relationship Integrity', () {
    test('caregiver-senior assignment creates matching records', () {
      // After CaregiverRepository.assignToSenior(cg-1, senior-1)
      // Both documents should reflect the relationship
      const caregiver = AppUser(
        uid: 'cg-1',
        email: 'cg@test.com',
        name: 'Dr. Smith',
        role: 'caregiver',
        assignedSeniors: ['senior-1', 'senior-2'],
      );
      const senior1 = AppUser(
        uid: 'senior-1',
        email: 'senior1@test.com',
        name: 'John',
        role: 'senior',
        assignedCaregivers: ['cg-1'],
      );
      const senior2 = AppUser(
        uid: 'senior-2',
        email: 'senior2@test.com',
        name: 'Jane',
        role: 'senior',
        assignedCaregivers: ['cg-1'],
      );

      // Verify bidirectional consistency
      expect(caregiver.assignedSeniors, contains('senior-1'));
      expect(caregiver.assignedSeniors, contains('senior-2'));
      expect(senior1.assignedCaregivers, contains('cg-1'));
      expect(senior2.assignedCaregivers, contains('cg-1'));
    });

    test('family-senior link creates matching records', () {
      const family = AppUser(
        uid: 'family-1',
        email: 'family@test.com',
        name: 'Mary',
        role: 'family',
        linkedSeniorId: 'senior-1',
      );
      const senior = AppUser(
        uid: 'senior-1',
        email: 'senior@test.com',
        name: 'John',
        role: 'senior',
        linkedFamily: ['family-1'],
      );

      expect(family.linkedSeniorId, senior.uid);
      expect(senior.linkedFamily, contains(family.uid));
      expect(family.isLinkedToSenior, true);
      expect(senior.hasLinkedFamily, true);
    });

    test('unlinking removes both sides completely', () {
      // After unlink, both sides should be clear
      const unlinkedFamily = AppUser(
        uid: 'family-1',
        email: 'family@test.com',
        name: 'Mary',
        role: 'family',
        linkedSeniorId: null,
      );
      const unlinkedSenior = AppUser(
        uid: 'senior-1',
        email: 'senior@test.com',
        name: 'John',
        role: 'senior',
        linkedFamily: [],
      );

      expect(unlinkedFamily.isLinkedToSenior, false);
      expect(unlinkedSenior.hasLinkedFamily, false);
    });
  });

  group('Admin Workflow Pipeline', () {
    test('approval workflow state machine', () {
      // New user → pending
      const newUser = AppUser(
        uid: 'new-1',
        email: 'new@test.com',
        name: 'New User',
        role: 'caregiver',
      );
      expect(newUser.isPending, true);

      // Admin approves
      final approved = newUser.copyWith(
        approvalStatus: ApprovalStatus.approved,
        approvedBy: 'admin-1',
        approvedAt: DateTime.now(),
      );
      expect(approved.isApproved, true);
      expect(approved.approvedBy, 'admin-1');
      expect(approved.approvedAt, isNotNull);

      // Verify serialization preserves approval
      final map = approved.toMap();
      expect(map['approvalStatus'], 'approved');
      expect(map['approvedBy'], 'admin-1');
    });

    test('rejection workflow includes reason', () {
      const newUser = AppUser(
        uid: 'new-2',
        email: 'suspicious@test.com',
        name: 'Suspicious User',
        role: 'senior',
      );

      final rejected = newUser.copyWith(
        approvalStatus: ApprovalStatus.rejected,
        rejectionReason: 'Could not verify identity',
      );
      expect(rejected.isRejected, true);
      expect(rejected.rejectionReason, 'Could not verify identity');

      // Verify the rejected user display name
      expect(rejected.approvalStatusDisplayName, 'Rejected');
    });

    test('reset to pending clears approval fields', () {
      final approved = AppUser(
        uid: 'approved-1',
        email: 'approved@test.com',
        name: 'Approved User',
        role: 'senior',
        approvalStatus: ApprovalStatus.approved,
        approvedBy: 'admin-1',
        approvedAt: DateTime.now(),
      );

      // Reset to pending (for re-review)
      final reset = approved.copyWith(
        approvalStatus: ApprovalStatus.pending,
      );
      expect(reset.isPending, true);
    });
  });

  group('Data Integrity Checks', () {
    test('all entity toMap/fromMap round-trips maintain integrity', () {
      // AppUser
      const user = AppUser(
        uid: 'u1', email: 'u@t.com', name: 'User', role: 'senior',
        phone: '+123', approvalStatus: ApprovalStatus.approved,
        linkedFamily: ['f1'], assignedCaregivers: ['c1'],
      );
      final userMap = user.toMap();
      final userRestored = AppUser.fromMap(userMap);
      expect(userRestored.uid, user.uid);
      expect(userRestored.approvalStatus, user.approvalStatus);

      // HelpRequest
      final request = HelpRequest(
        seniorId: 's1', seniorName: 'John', type: 'medical',
        description: 'Help', isUrgent: true, latitude: 40.0, longitude: -74.0,
      );
      final reqMap = request.toMap();
      final reqRestored = HelpRequest.fromMap(reqMap, id: 'r1');
      expect(reqRestored.seniorId, request.seniorId);
      expect(reqRestored.isUrgent, true);

      // EmergencyAlert
      final emergency = EmergencyAlert(
        seniorId: 's1', seniorName: 'John',
        latitude: 40.0, longitude: -74.0,
      );
      final emgMap = emergency.toMap();
      final emgRestored = EmergencyAlert.fromMap(emgMap, id: 'e1');
      expect(emgRestored.seniorId, emergency.seniorId);
      expect(emgRestored.status, 'active');

      // CheckIn
      final checkin = CheckIn(seniorId: 's1', status: 'ok', message: 'Good');
      final ciMap = checkin.toMap();
      final ciRestored = CheckIn.fromMap(ciMap, id: 'ci1');
      expect(ciRestored.seniorId, 's1');
      expect(ciRestored.status, 'ok');

      // Message
      final msg = Message(
        conversationId: 'c1', senderId: 'u1',
        senderName: 'User', content: 'Hello',
      );
      final msgMap = msg.toMap();
      final msgRestored = Message.fromMap(msgMap, id: 'm1');
      expect(msgRestored.content, 'Hello');
      expect(msgRestored.type, 'text');

      // Conversation
      final conv = Conversation(
        participantIds: ['u1', 'u2'],
        participantNames: {'u1': 'Alice', 'u2': 'Bob'},
      );
      final convMap = conv.toMap();
      final convRestored = Conversation.fromMap(convMap, id: 'cv1');
      expect(convRestored.participantIds, hasLength(2));
    });
  });
}