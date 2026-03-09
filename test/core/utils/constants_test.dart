import 'package:flutter_test/flutter_test.dart';
import 'package:elderl/core/utils/constants.dart';

void main() {
  group('AppConstants - App Info', () {
    test('appName is defined', () {
      expect(AppConstants.appName, 'ElderL');
    });

    test('appVersion is defined', () {
      expect(AppConstants.appVersion, isNotEmpty);
    });

    test('appDescription is defined', () {
      expect(AppConstants.appDescription, isNotEmpty);
    });
  });

  group('AppConstants - Firebase Collections', () {
    test('usersCollection is defined', () {
      expect(AppConstants.usersCollection, 'users');
    });

    test('requestsCollection is defined', () {
      expect(AppConstants.requestsCollection, 'requests');
    });

    test('checkinsCollection is defined', () {
      expect(AppConstants.checkinsCollection, 'checkins');
    });

    test('emergenciesCollection is defined', () {
      expect(AppConstants.emergenciesCollection, 'emergencies');
    });

    test('messagesCollection is defined', () {
      expect(AppConstants.messagesCollection, 'messages');
    });

    test('all collection names are non-empty strings', () {
      final collections = [
        AppConstants.usersCollection,
        AppConstants.requestsCollection,
        AppConstants.checkinsCollection,
        AppConstants.emergenciesCollection,
        AppConstants.messagesCollection,
      ];
      for (final c in collections) {
        expect(c, isNotEmpty);
        expect(c, isA<String>());
      }
    });
  });

  group('AppConstants - User Roles', () {
    test('roleSenior', () {
      expect(AppConstants.roleSenior, 'senior');
    });

    test('roleCaregiver', () {
      expect(AppConstants.roleCaregiver, 'caregiver');
    });

    test('roleFamily', () {
      expect(AppConstants.roleFamily, 'family');
    });

    test('roleAdmin', () {
      expect(AppConstants.roleAdmin, 'admin');
    });

    test('all roles are distinct', () {
      final roles = {
        AppConstants.roleSenior,
        AppConstants.roleCaregiver,
        AppConstants.roleFamily,
        AppConstants.roleAdmin,
      };
      expect(roles.length, 4);
    });
  });

  group('AppConstants - Request Types', () {
    test('requestMedical', () {
      expect(AppConstants.requestMedical, 'medical');
    });

    test('requestFood', () {
      expect(AppConstants.requestFood, 'food');
    });

    test('requestTransport', () {
      expect(AppConstants.requestTransport, 'transport');
    });

    test('requestCompanion', () {
      expect(AppConstants.requestCompanion, 'companion');
    });

    test('all request types are distinct', () {
      final types = {
        AppConstants.requestMedical,
        AppConstants.requestFood,
        AppConstants.requestTransport,
        AppConstants.requestCompanion,
      };
      expect(types.length, 4);
    });
  });

  group('AppConstants - Request Status', () {
    test('statusPending', () {
      expect(AppConstants.statusPending, 'pending');
    });

    test('statusAccepted', () {
      expect(AppConstants.statusAccepted, 'accepted');
    });

    test('statusInProgress', () {
      expect(AppConstants.statusInProgress, 'in_progress');
    });

    test('statusCompleted', () {
      expect(AppConstants.statusCompleted, 'completed');
    });

    test('statusCancelled', () {
      expect(AppConstants.statusCancelled, 'cancelled');
    });

    test('all statuses are distinct', () {
      final statuses = {
        AppConstants.statusPending,
        AppConstants.statusAccepted,
        AppConstants.statusInProgress,
        AppConstants.statusCompleted,
        AppConstants.statusCancelled,
      };
      expect(statuses.length, 5);
    });
  });

  group('AppConstants - CheckIn Status', () {
    test('checkinOk', () {
      expect(AppConstants.checkinOk, 'ok');
    });

    test('checkinMissed', () {
      expect(AppConstants.checkinMissed, 'missed');
    });

    test('checkinPending', () {
      expect(AppConstants.checkinPending, 'pending');
    });
  });

  group('AppConstants - Storage Keys', () {
    test('all storage keys are non-empty', () {
      final keys = [
        AppConstants.keyUserId,
        AppConstants.keyUserRole,
        AppConstants.keyFcmToken,
        AppConstants.keyLastCheckin,
        AppConstants.keyThemeMode,
      ];
      for (final k in keys) {
        expect(k, isNotEmpty);
      }
    });

    test('all storage keys are distinct', () {
      final keys = {
        AppConstants.keyUserId,
        AppConstants.keyUserRole,
        AppConstants.keyFcmToken,
        AppConstants.keyLastCheckin,
        AppConstants.keyThemeMode,
      };
      expect(keys.length, 5);
    });
  });

  group('AppConstants - Timeouts', () {
    test('checkInReminder is positive', () {
      expect(AppConstants.checkInReminder.inSeconds, greaterThan(0));
    });

    test('emergencyTimeout is positive', () {
      expect(AppConstants.emergencyTimeout.inSeconds, greaterThan(0));
    });

    test('checkInReminder is 12 hours', () {
      expect(AppConstants.checkInReminder, const Duration(hours: 12));
    });

    test('emergencyTimeout is 5 minutes', () {
      expect(AppConstants.emergencyTimeout, const Duration(minutes: 5));
    });
  });
}
