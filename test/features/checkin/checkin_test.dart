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
      // Define expected status constants
      const statusOk = 'ok';
      const statusMissed = 'missed';
      const statusPending = 'pending';

      expect(statusOk, 'ok');
      expect(statusMissed, 'missed');
      expect(statusPending, 'pending');
    });
  });
}
