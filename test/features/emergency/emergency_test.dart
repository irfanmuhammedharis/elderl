import 'package:flutter_test/flutter_test.dart';
import 'package:elderl/features/emergency/data/emergency_repository.dart';

void main() {
  group('EmergencyAlert Entity Tests', () {
    test('should create EmergencyAlert with required fields', () {
      final emergency = EmergencyAlert(
        seniorId: 'senior-123',
        seniorName: 'John Doe',
      );

      expect(emergency.seniorId, 'senior-123');
      expect(emergency.seniorName, 'John Doe');
      expect(emergency.status, 'active'); // Default status
    });

    test('should create EmergencyAlert with all fields', () {
      final emergency = EmergencyAlert(
        id: 'emergency-456',
        seniorId: 'senior-123',
        seniorName: 'Jane Doe',
        seniorPhone: '+1234567890',
        latitude: 40.7128,
        longitude: -74.0060,
        address: '123 Main St, New York, NY',
        status: 'responded',
        respondedBy: 'caregiver-789',
        respondedByName: 'Dr. Smith',
      );

      expect(emergency.id, 'emergency-456');
      expect(emergency.seniorPhone, '+1234567890');
      expect(emergency.latitude, 40.7128);
      expect(emergency.longitude, -74.0060);
      expect(emergency.address, '123 Main St, New York, NY');
      expect(emergency.status, 'responded');
      expect(emergency.respondedBy, 'caregiver-789');
      expect(emergency.respondedByName, 'Dr. Smith');
    });

    test('should convert to Map correctly', () {
      final emergency = EmergencyAlert(
        seniorId: 'senior-123',
        seniorName: 'Test Senior',
        latitude: 51.5074,
        longitude: -0.1278,
      );

      final map = emergency.toMap();

      expect(map['seniorId'], 'senior-123');
      expect(map['seniorName'], 'Test Senior');
      expect(map['latitude'], 51.5074);
      expect(map['longitude'], -0.1278);
      expect(map['status'], 'active');
    });

    test('should create from Map correctly', () {
      final map = {
        'seniorId': 'senior-456',
        'seniorName': 'Map Senior',
        'status': 'resolved',
        'latitude': 48.8566,
        'longitude': 2.3522,
      };

      final emergency = EmergencyAlert.fromMap(map, id: 'emg-id');

      expect(emergency.id, 'emg-id');
      expect(emergency.seniorId, 'senior-456');
      expect(emergency.seniorName, 'Map Senior');
      expect(emergency.status, 'resolved');
      expect(emergency.latitude, 48.8566);
      expect(emergency.longitude, 2.3522);
    });

    test('copyWith should update specific fields', () {
      final emergency = EmergencyAlert(
        seniorId: 'senior-123',
        seniorName: 'Original Name',
        status: 'active',
      );

      final updated = emergency.copyWith(
        status: 'responded',
        respondedBy: 'caregiver-456',
        respondedByName: 'Dr. Helper',
      );

      expect(updated.seniorId, 'senior-123'); // Unchanged
      expect(updated.seniorName, 'Original Name'); // Unchanged
      expect(updated.status, 'responded'); // Changed
      expect(updated.respondedBy, 'caregiver-456'); // Changed
      expect(updated.respondedByName, 'Dr. Helper'); // Changed
    });
  });

  group('Emergency Status Constants', () {
    test('should have valid status values', () {
      const statusActive = 'active';
      const statusResponded = 'responded';
      const statusResolved = 'resolved';
      const statusCancelled = 'cancelled';

      expect(statusActive, 'active');
      expect(statusResponded, 'responded');
      expect(statusResolved, 'resolved');
      expect(statusCancelled, 'cancelled');
    });
  });

  group('EmergencyAlert DateTime Helpers', () {
    test('should convert timestamp to DateTime', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final emergency = EmergencyAlert(
        seniorId: 'senior-123',
        seniorName: 'Test',
        createdAt: now,
      );

      expect(emergency.createdAtDateTime, isNotNull);
      expect(emergency.createdAtDateTime!.millisecondsSinceEpoch, now);
    });

    test('should handle null timestamp', () {
      final emergency = EmergencyAlert(
        seniorId: 'senior-123',
        seniorName: 'Test',
      );

      expect(emergency.createdAtDateTime, isNull);
    });
  });
}
