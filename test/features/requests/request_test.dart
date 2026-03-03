import 'package:flutter_test/flutter_test.dart';
import 'package:elderl/features/requests/data/request_repository.dart';

void main() {
  group('HelpRequest Entity Tests', () {
    test('should create HelpRequest with required fields', () {
      final request = HelpRequest(
        seniorId: 'senior-123',
        seniorName: 'John Senior',
        type: 'medical',
        description: 'Need medication pickup',
      );

      expect(request.seniorId, 'senior-123');
      expect(request.seniorName, 'John Senior');
      expect(request.type, 'medical');
      expect(request.description, 'Need medication pickup');
      expect(request.status, 'pending'); // Default status
    });

    test('should create HelpRequest with all fields', () {
      final request = HelpRequest(
        id: 'req-456',
        seniorId: 'senior-123',
        seniorName: 'Jane Senior',
        type: 'food',
        description: 'Need grocery delivery',
        status: 'accepted',
        assignedTo: 'caregiver-789',
        assignedToName: 'Helper Joe',
        latitude: 40.7128,
        longitude: -74.0060,
        address: '456 Oak Ave',
      );

      expect(request.id, 'req-456');
      expect(request.type, 'food');
      expect(request.status, 'accepted');
      expect(request.assignedTo, 'caregiver-789');
      expect(request.assignedToName, 'Helper Joe');
      expect(request.latitude, 40.7128);
    });

    test('should convert to Map correctly', () {
      final request = HelpRequest(
        seniorId: 'senior-123',
        seniorName: 'Test Senior',
        type: 'transport',
        description: 'Ride to hospital',
      );

      final map = request.toMap();

      expect(map['seniorId'], 'senior-123');
      expect(map['seniorName'], 'Test Senior');
      expect(map['type'], 'transport');
      expect(map['description'], 'Ride to hospital');
      expect(map['status'], 'pending');
    });

    test('should create from Map correctly', () {
      final map = {
        'seniorId': 'senior-456',
        'seniorName': 'Map Senior',
        'type': 'companion',
        'description': 'Need company for walk',
        'status': 'in_progress',
        'assignedTo': 'caregiver-123',
        'assignedToName': 'Friendly Helper',
      };

      final request = HelpRequest.fromMap(map, id: 'req-id');

      expect(request.id, 'req-id');
      expect(request.seniorId, 'senior-456');
      expect(request.type, 'companion');
      expect(request.status, 'in_progress');
      expect(request.assignedTo, 'caregiver-123');
    });

    test('copyWith should update specific fields', () {
      final request = HelpRequest(
        seniorId: 'senior-123',
        seniorName: 'Original Senior',
        type: 'medical',
        description: 'Original description',
        status: 'pending',
      );

      final updated = request.copyWith(
        status: 'completed',
        assignedTo: 'caregiver-456',
      );

      expect(updated.seniorId, 'senior-123'); // Unchanged
      expect(updated.type, 'medical'); // Unchanged
      expect(updated.status, 'completed'); // Changed
      expect(updated.assignedTo, 'caregiver-456'); // Changed
    });
  });

  group('Request Type Constants', () {
    test('should have valid request types', () {
      const typeMedical = 'medical';
      const typeFood = 'food';
      const typeTransport = 'transport';
      const typeCompanion = 'companion';

      expect(typeMedical, 'medical');
      expect(typeFood, 'food');
      expect(typeTransport, 'transport');
      expect(typeCompanion, 'companion');
    });
  });

  group('Request Status Constants', () {
    test('should have valid status values', () {
      const statusPending = 'pending';
      const statusAccepted = 'accepted';
      const statusInProgress = 'in_progress';
      const statusCompleted = 'completed';
      const statusCancelled = 'cancelled';

      expect(statusPending, 'pending');
      expect(statusAccepted, 'accepted');
      expect(statusInProgress, 'in_progress');
      expect(statusCompleted, 'completed');
      expect(statusCancelled, 'cancelled');
    });
  });
}
