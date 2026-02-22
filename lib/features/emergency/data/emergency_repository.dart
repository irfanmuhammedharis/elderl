import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/realtime_db_service.dart';

/// Emergency alert model - optimized for Realtime Database
class EmergencyAlert {
  final String? id;
  final String seniorId;
  final String seniorName;
  final String? seniorPhone;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String status; // active, responded, resolved, cancelled
  final String? respondedBy;
  final String? respondedByName;
  final int? createdAt;
  final int? respondedAt;
  final int? resolvedAt;

  EmergencyAlert({
    this.id,
    required this.seniorId,
    required this.seniorName,
    this.seniorPhone,
    this.latitude,
    this.longitude,
    this.address,
    this.status = 'active',
    this.respondedBy,
    this.respondedByName,
    this.createdAt,
    this.respondedAt,
    this.resolvedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'seniorId': seniorId,
      'seniorName': seniorName,
      'seniorPhone': seniorPhone,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'status': status,
      'respondedBy': respondedBy,
      'respondedByName': respondedByName,
      'respondedAt': respondedAt,
      'resolvedAt': resolvedAt,
    };
  }

  factory EmergencyAlert.fromMap(Map<dynamic, dynamic> map, {String? id}) {
    return EmergencyAlert(
      id: id,
      seniorId: map['seniorId']?.toString() ?? '',
      seniorName: map['seniorName']?.toString() ?? '',
      seniorPhone: map['seniorPhone']?.toString(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      address: map['address']?.toString(),
      status: map['status']?.toString() ?? 'active',
      respondedBy: map['respondedBy']?.toString(),
      respondedByName: map['respondedByName']?.toString(),
      createdAt: map['createdAt'] as int?,
      respondedAt: map['respondedAt'] as int?,
      resolvedAt: map['resolvedAt'] as int?,
    );
  }

  EmergencyAlert copyWith({
    String? id,
    String? seniorId,
    String? seniorName,
    String? seniorPhone,
    double? latitude,
    double? longitude,
    String? address,
    String? status,
    String? respondedBy,
    String? respondedByName,
    int? createdAt,
    int? respondedAt,
    int? resolvedAt,
  }) {
    return EmergencyAlert(
      id: id ?? this.id,
      seniorId: seniorId ?? this.seniorId,
      seniorName: seniorName ?? this.seniorName,
      seniorPhone: seniorPhone ?? this.seniorPhone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      status: status ?? this.status,
      respondedBy: respondedBy ?? this.respondedBy,
      respondedByName: respondedByName ?? this.respondedByName,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  /// Get DateTime from timestamp
  DateTime? get createdAtDateTime => 
      createdAt != null ? DateTime.fromMillisecondsSinceEpoch(createdAt!) : null;
  
  DateTime? get respondedAtDateTime => 
      respondedAt != null ? DateTime.fromMillisecondsSinceEpoch(respondedAt!) : null;
  
  DateTime? get resolvedAtDateTime => 
      resolvedAt != null ? DateTime.fromMillisecondsSinceEpoch(resolvedAt!) : null;
}

/// Emergency repository using Firebase Realtime Database
/// Realtime DB provides lower latency which is critical for emergencies
class EmergencyRepository {
  final RealtimeDbService _realtimeDb;
  
  static const String _emergenciesPath = 'emergencies';
  static const String _activeEmergenciesPath = 'active_emergencies';

  EmergencyRepository(this._realtimeDb);

  /// Create a new emergency alert
  /// Stores in both main collection and active_emergencies for quick access
  Future<String> createEmergency(EmergencyAlert emergency) async {
    final data = emergency.toMap();
    
    // Push to main emergencies collection
    final emergencyId = await _realtimeDb.push(_emergenciesPath, data);
    
    // Also add to active_emergencies for quick querying
    await _realtimeDb.set(
      '$_activeEmergenciesPath/$emergencyId',
      {
        ...data,
        'createdAt': ServerValue.timestamp,
      },
    );
    
    return emergencyId;
  }

  /// Convenience method to trigger emergency with individual parameters
  Future<String> triggerEmergency({
    required String seniorId,
    required String seniorName,
    String? seniorPhone,
    String? emergencyType,
    Map<String, dynamic>? location,
  }) async {
    final emergency = EmergencyAlert(
      seniorId: seniorId,
      seniorName: seniorName,
      seniorPhone: seniorPhone,
      latitude: location?['latitude'],
      longitude: location?['longitude'],
      address: location?['address'],
    );
    return createEmergency(emergency);
  }

  /// Get emergency by ID
  Future<EmergencyAlert?> getEmergency(String emergencyId) async {
    final snapshot = await _realtimeDb.get('$_emergenciesPath/$emergencyId');
    if (!snapshot.exists || snapshot.value == null) {
      return null;
    }
    return EmergencyAlert.fromMap(
      snapshot.value as Map<dynamic, dynamic>,
      id: emergencyId,
    );
  }

  /// Update emergency status
  Future<void> updateEmergencyStatus(String emergencyId, String status) async {
    final updateData = <String, dynamic>{'status': status};
    
    if (status == 'resolved') {
      updateData['resolvedAt'] = ServerValue.timestamp;
      // Remove from active emergencies when resolved
      await _realtimeDb.remove('$_activeEmergenciesPath/$emergencyId');
    } else if (status == 'cancelled') {
      // Remove from active emergencies when cancelled
      await _realtimeDb.remove('$_activeEmergenciesPath/$emergencyId');
    }
    
    await _realtimeDb.update('$_emergenciesPath/$emergencyId', updateData);
  }

  /// Respond to emergency
  Future<void> respondToEmergency(
    String emergencyId, 
    String responderId, 
    String responderName,
  ) async {
    final updateData = {
      'respondedBy': responderId,
      'respondedByName': responderName,
      'status': 'responded',
      'respondedAt': ServerValue.timestamp,
    };
    
    // [FIX] Use multi-path update on the root reference for atomicity.
    // This ensures both paths are updated simultaneously.
    final updates = <String, dynamic>{
      '$_emergenciesPath/$emergencyId': updateData,
      '$_activeEmergenciesPath/$emergencyId': updateData,
    };
    
    await _realtimeDb.root.update(updates);
  }

  /// Get active emergencies
  Future<List<EmergencyAlert>> getActiveEmergencies() async {
    final snapshot = await _realtimeDb.get(_activeEmergenciesPath);
    if (!snapshot.exists || snapshot.value == null) {
      return [];
    }
    
    final data = snapshot.value as Map<dynamic, dynamic>;
    return data.entries
        .map((e) => EmergencyAlert.fromMap(
              e.value as Map<dynamic, dynamic>,
              id: e.key.toString(),
            ))
        .where((e) => e.status == 'active' || e.status == 'responded')
        .toList()
      ..sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));
  }

  /// Get emergencies for a senior
  Future<List<EmergencyAlert>> getEmergenciesForSenior(String seniorId) async {
    final snapshot = await _realtimeDb.query(
      _emergenciesPath,
      orderByChild: 'seniorId',
      equalTo: seniorId,
    ).get();
    
    if (!snapshot.exists || snapshot.value == null) {
      return [];
    }
    
    final data = snapshot.value as Map<dynamic, dynamic>;
    return data.entries
        .map((e) => EmergencyAlert.fromMap(
              e.value as Map<dynamic, dynamic>,
              id: e.key.toString(),
            ))
        .toList()
      ..sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));
  }

  /// Stream active emergencies in real-time
  /// This is critical for caregivers to receive immediate notifications
  Stream<List<EmergencyAlert>> streamActiveEmergencies() {
    return _realtimeDb.stream(_activeEmergenciesPath).map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return <EmergencyAlert>[];
      }
      
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return data.entries
          .map((e) => EmergencyAlert.fromMap(
                e.value as Map<dynamic, dynamic>,
                id: e.key.toString(),
              ))
          .where((e) => e.status == 'active' || e.status == 'responded')
          .toList()
        ..sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));
    });
  }

  /// Stream emergencies for a specific senior
  Stream<List<EmergencyAlert>> streamEmergenciesForSenior(String seniorId) {
    return _realtimeDb.stream(_emergenciesPath).map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return <EmergencyAlert>[];
      }
      
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return data.entries
          .map((e) => EmergencyAlert.fromMap(
                e.value as Map<dynamic, dynamic>,
                id: e.key.toString(),
              ))
          .where((e) => e.seniorId == seniorId)
          .toList()
        ..sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));
    });
  }

  /// Stream a single emergency
  Stream<EmergencyAlert?> streamEmergency(String emergencyId) {
    return _realtimeDb.stream('$_emergenciesPath/$emergencyId').map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return null;
      }
      return EmergencyAlert.fromMap(
        event.snapshot.value as Map<dynamic, dynamic>,
        id: emergencyId,
      );
    });
  }

  /// Stream all emergencies (for admin) - includes resolved and cancelled
  Stream<List<EmergencyAlert>> streamAllEmergencies() {
    return _realtimeDb.stream(_emergenciesPath).map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return <EmergencyAlert>[];
      }
      
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return data.entries
          .map((e) => EmergencyAlert.fromMap(
                e.value as Map<dynamic, dynamic>,
                id: e.key.toString(),
              ))
          .toList()
        ..sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));
    });
  }

  /// Resolve emergency
  Future<void> resolveEmergency(String emergencyId) async {
    await updateEmergencyStatus(emergencyId, 'resolved');
  }

  /// Cancel emergency (false alarm)
  Future<void> cancelEmergency(String emergencyId) async {
    await updateEmergencyStatus(emergencyId, 'cancelled');
  }

  /// Stream emergencies for linked seniors (for caregivers/family)
  Stream<List<EmergencyAlert>> streamEmergenciesForLinkedSeniors(List<String> seniorIds) {
    if (seniorIds.isEmpty) {
      return Stream.value([]);
    }

    return _realtimeDb.stream(_activeEmergenciesPath).map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return <EmergencyAlert>[];
      }
      
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return data.entries
          .map((e) => EmergencyAlert.fromMap(
                e.value as Map<dynamic, dynamic>,
                id: e.key.toString(),
              ))
          .where((e) => seniorIds.contains(e.seniorId) && 
                       (e.status == 'active' || e.status == 'responded'))
          .toList()
        ..sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));
    });
  }

  /// Enable offline persistence for emergencies
  void enableOfflineSupport() {
    _realtimeDb.enablePersistence();
    _realtimeDb.keepSynced(_activeEmergenciesPath, true);
  }
}

/// Emergency repository provider
final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  final realtimeDb = ref.watch(realtimeDbServiceProvider);
  return EmergencyRepository(realtimeDb);
});
