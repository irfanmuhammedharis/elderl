import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// Location data model
class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final String? address;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    this.address,
  });

  Map<String, dynamic> toMap() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'timestamp': timestamp.toIso8601String(),
        'address': address,
      };

  factory LocationData.fromMap(Map<String, dynamic> map) => LocationData(
        latitude: map['latitude']?.toDouble() ?? 0.0,
        longitude: map['longitude']?.toDouble() ?? 0.0,
        accuracy: map['accuracy']?.toDouble() ?? 0.0,
        timestamp: map['timestamp'] != null
            ? DateTime.parse(map['timestamp'])
            : DateTime.now(),
        address: map['address'],
      );

  @override
  String toString() =>
      'LocationData(lat: $latitude, lng: $longitude, accuracy: $accuracy)';
}

/// Service for handling location operations
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionSubscription;
  final _locationController = StreamController<LocationData>.broadcast();

  /// Stream of location updates
  Stream<LocationData> get locationStream => _locationController.stream;

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check and request location permission
  Future<LocationPermission> checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  /// Request location permission with user-friendly handling
  Future<bool> requestPermission() async {
    final permission = await checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Get current location once
  Future<LocationData?> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      // Check if service is enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return null;
      }

      // Check permission
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        debugPrint('Location permission denied');
        return null;
      }

      // Get position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: timeout,
      );

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  /// Start continuous location updates
  Future<void> startLocationUpdates({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) async {
    // Stop any existing subscription
    await stopLocationUpdates();

    // Check permissions first
    final hasPermission = await requestPermission();
    if (!hasPermission) {
      debugPrint('Cannot start location updates - permission denied');
      return;
    }

    // Start listening
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    ).listen(
      (Position position) {
        final locationData = LocationData(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          timestamp: position.timestamp,
        );
        _locationController.add(locationData);
      },
      onError: (error) {
        debugPrint('Location stream error: $error');
      },
    );
  }

  /// Stop location updates
  Future<void> stopLocationUpdates() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Calculate distance between two points in meters
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Check if a location is within a radius of another location
  bool isWithinRadius(
    double centerLat,
    double centerLng,
    double pointLat,
    double pointLng,
    double radiusInMeters,
  ) {
    final distance = calculateDistance(centerLat, centerLng, pointLat, pointLng);
    return distance <= radiusInMeters;
  }

  /// Open device location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings (for permissions)
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Get last known location (faster than getCurrentLocation)
  Future<LocationData?> getLastKnownLocation() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position == null) return null;

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      );
    } catch (e) {
      debugPrint('Error getting last known location: $e');
      return null;
    }
  }

  /// Dispose of resources
  void dispose() {
    _positionSubscription?.cancel();
    _locationController.close();
  }
}

/// Widget to handle location permission requests with UI
class LocationPermissionHandler extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPermissionGranted;
  final VoidCallback? onPermissionDenied;

  const LocationPermissionHandler({
    super.key,
    required this.child,
    this.onPermissionGranted,
    this.onPermissionDenied,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: LocationService().requestPermission(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data == true) {
          onPermissionGranted?.call();
          return child;
        }

        // Permission denied
        onPermissionDenied?.call();
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Location Permission Required',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'This feature requires location access to function properly.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    await LocationService().openAppSettings();
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Open Settings'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
