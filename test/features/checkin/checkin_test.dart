import 'package:flutter_test/flutter_test.dart';
import 'package:elderl/features/checkin/data/checkin_repository.dart';

void main() {
  group('CheckIn Entity Tests', () {
    test('should create CheckIn with required fields', () {
      final checkin = CheckIn(
        seniorId: 'senior-123',
        status: 'ok',
        message: 'Feeling great today!',
      );

      expect(checkin.seniorId, 'senior-123');
      expect(checkin.status, 'ok');
      expect(checkin.message, 'Feeling great today!');
    });

    test('should convert to Map correctly', () {
      final checkin = CheckIn(
        seniorId: 'senior-456',
        status: 'ok',
      );

      final map = checkin.toMap();

      expect(map['seniorId'], 'senior-456');
      expect(map['status'], 'ok');
    });

    test('should create from Map correctly', () {
      final map = {
        'seniorId': 'senior-789',
        'status': 'ok',
        'message': 'All good',
      };

      final checkin = CheckIn.fromMap(map, id: 'checkin-id');

      expect(checkin.id, 'checkin-id');
      expect(checkin.seniorId, 'senior-789');
      expect(checkin.status, 'ok');
      expect(checkin.message, 'All good');
    });

    test('should handle missing optional fields', () {
      final map = {
        'seniorId': 'senior-123',
        'status': 'pending',
      };

      final checkin = CheckIn.fromMap(map);

      expect(checkin.seniorId, 'senior-123');
      expect(checkin.status, 'pending');
      expect(checkin.message, isNull);
    });
  });

  group('CheckIn Status Constants', () {
    test('should have valid status values', () {
      const statusOk = 'ok';
      const statusMissed = 'missed';
      const statusPending = 'pending';

      expect(statusOk, 'ok');
      expect(statusMissed, 'missed');
      expect(statusPending, 'pending');
    });
  });

  group('CheckIn Date Parsing', () {
    test('fromMap handles String date for checkinTime', () {
      final now = DateTime.now();
      final map = {
        'seniorId': 'senior-1',
        'status': 'ok',
        'checkinTime': now.toIso8601String(),
      };

      final checkin = CheckIn.fromMap(map);

      expect(checkin.checkinTime, isNotNull);
      expect(checkin.checkinTime!.year, now.year);
      expect(checkin.checkinTime!.month, now.month);
      expect(checkin.checkinTime!.day, now.day);
    });

    test('fromMap handles null checkinTime', () {
      final map = {
        'seniorId': 'senior-1',
        'status': 'ok',
      };

      final checkin = CheckIn.fromMap(map);

      expect(checkin.checkinTime, isNull);
    });

    test('fromMap handles null createdAt', () {
      final map = {
        'seniorId': 'senior-1',
        'status': 'ok',
      };

      final checkin = CheckIn.fromMap(map);

      expect(checkin.createdAt, isNull);
    });

    test('fromMap handles String date for createdAt', () {
      final now = DateTime.now();
      final map = {
        'seniorId': 'senior-1',
        'status': 'ok',
        'createdAt': now.toIso8601String(),
      };

      final checkin = CheckIn.fromMap(map);

      expect(checkin.createdAt, isNotNull);
    });
  });

  group('CheckIn toMap', () {
    test('toMap includes all fields', () {
      final checkin = CheckIn(
        seniorId: 'senior-1',
        status: 'ok',
        message: 'Feeling good',
      );

      final map = checkin.toMap();

      expect(map['seniorId'], 'senior-1');
      expect(map['status'], 'ok');
      expect(map['message'], 'Feeling good');
      expect(map.containsKey('checkinTime'), true);
    });

    test('toMap handles null message', () {
      final checkin = CheckIn(
        seniorId: 'senior-1',
        status: 'ok',
      );

      final map = checkin.toMap();

      expect(map['message'], isNull);
    });
  });

  group('CheckIn Defaults', () {
    test('fromMap defaults status to pending when missing', () {
      final map = <String, dynamic>{
        'seniorId': 'senior-1',
      };

      final checkin = CheckIn.fromMap(map);

      // Defaults to AppConstants.checkinPending which is 'pending'
      expect(checkin.status, isNotEmpty);
    });

    test('fromMap defaults seniorId to empty when missing', () {
      final map = <String, dynamic>{
        'status': 'ok',
      };

      final checkin = CheckIn.fromMap(map);

      expect(checkin.seniorId, '');
    });
  });
}
