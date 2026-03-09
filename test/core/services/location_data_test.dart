import 'package:flutter_test/flutter_test.dart';
import 'package:elderl/core/services/location_service.dart';

void main() {
  group('LocationData', () {
    test('should create with required fields', () {
      final now = DateTime.now();
      final data = LocationData(
        latitude: 40.7128,
        longitude: -74.0060,
        accuracy: 10.0,
        timestamp: now,
      );

      expect(data.latitude, 40.7128);
      expect(data.longitude, -74.0060);
      expect(data.accuracy, 10.0);
      expect(data.timestamp, now);
      expect(data.address, isNull);
    });

    test('should create with optional address', () {
      final data = LocationData(
        latitude: 51.5074,
        longitude: -0.1278,
        accuracy: 5.0,
        timestamp: DateTime.now(),
        address: '10 Downing Street, London',
      );

      expect(data.address, '10 Downing Street, London');
    });

    test('toMap should convert all fields', () {
      final now = DateTime(2025, 1, 15, 10, 30);
      final data = LocationData(
        latitude: 48.8566,
        longitude: 2.3522,
        accuracy: 15.5,
        timestamp: now,
        address: 'Paris, France',
      );

      final map = data.toMap();

      expect(map['latitude'], 48.8566);
      expect(map['longitude'], 2.3522);
      expect(map['accuracy'], 15.5);
      expect(map['timestamp'], now.toIso8601String());
      expect(map['address'], 'Paris, France');
    });

    test('fromMap should parse all fields', () {
      final map = {
        'latitude': 35.6762,
        'longitude': 139.6503,
        'accuracy': 20.0,
        'timestamp': '2025-06-15T14:30:00.000',
        'address': 'Tokyo, Japan',
      };

      final data = LocationData.fromMap(map);

      expect(data.latitude, 35.6762);
      expect(data.longitude, 139.6503);
      expect(data.accuracy, 20.0);
      expect(data.address, 'Tokyo, Japan');
    });

    test('fromMap handles missing optional fields', () {
      final map = {
        'latitude': 0.0,
        'longitude': 0.0,
        'accuracy': 0.0,
        'timestamp': '2025-01-01T00:00:00.000',
      };

      final data = LocationData.fromMap(map);
      expect(data.address, isNull);
    });

    test('fromMap handles null numeric values with defaults', () {
      final map = <String, dynamic>{
        'latitude': null,
        'longitude': null,
        'accuracy': null,
        'timestamp': null,
      };

      final data = LocationData.fromMap(map);
      expect(data.latitude, 0.0);
      expect(data.longitude, 0.0);
      expect(data.accuracy, 0.0);
    });

    test('toMap/fromMap round-trip preserves data', () {
      final original = LocationData(
        latitude: 37.7749,
        longitude: -122.4194,
        accuracy: 8.5,
        timestamp: DateTime(2025, 3, 20, 9, 15),
        address: 'San Francisco, CA',
      );

      final map = original.toMap();
      final restored = LocationData.fromMap(map);

      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
      expect(restored.accuracy, original.accuracy);
      expect(restored.address, original.address);
    });

    test('toString returns formatted string', () {
      final data = LocationData(
        latitude: 40.0,
        longitude: -74.0,
        accuracy: 10.0,
        timestamp: DateTime.now(),
      );

      final str = data.toString();
      expect(str, contains('40.0'));
      expect(str, contains('-74.0'));
      expect(str, contains('10.0'));
    });
  });
}
